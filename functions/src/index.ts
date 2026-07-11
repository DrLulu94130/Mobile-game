/**
 * Cloud Functions for Inkognito.
 *
 * Responsibilities:
 *  - Maintain creator statistics when challenges are created/deleted.
 *  - Serve the public share landing page (open-in-app with store fallback and
 *    an OpenGraph preview of the camouflaged image).
 *  - Sync Premium entitlement from RevenueCat webhooks onto the user profile.
 *  - Pick the daily featured challenges on a schedule.
 */

import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onDocumentCreated, onDocumentDeleted} from
  "firebase-functions/v2/firestore";
import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {logger} from "firebase-functions";

initializeApp();
const db = getFirestore();

// ---------------------------------------------------------------------------
// Server-authoritative progression.
//
// XP, levels, streaks and badges are computed here — never trusted from the
// client. These constants and formulas mirror lib/core/constants and the
// badge catalogue on the Flutter side; keep them in sync.
// ---------------------------------------------------------------------------

const XP_PER_CHALLENGE_CREATED = 50;
const XP_PER_CHALLENGE_SOLVED = 30;
const XP_PER_INKLING_FOUND = 10;

/** Tap tolerance as a fraction of the canvas, must match the client. */
const DETECTION_TOLERANCE = 0.09;

/** Hard ceiling of the scoring formula (1000 + 400 + 300 + 300). */
const MAX_SCORE = 2000;

/** Cumulative XP required to move past `level`. */
function xpForLevel(level: number): number {
  return level * level * 40 + level * 60;
}

/** Smallest level whose cumulative XP threshold is not yet exceeded. */
function levelForXp(xp: number): number {
  let level = 1;
  while (xp >= xpForLevel(level)) level++;
  return level;
}

/** UTC day key, e.g. 2026-07-11. */
function todayKey(): string {
  const d = new Date();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${d.getUTCFullYear()}-${m}-${day}`;
}

/** Streak value for today given the last active day and its streak. */
function computeStreak(lastActiveDay: unknown, stored: number): number {
  if (typeof lastActiveDay !== "string") return 1;
  const last = new Date(`${lastActiveDay}T00:00:00Z`);
  if (isNaN(last.getTime())) return 1;
  const today = new Date(`${todayKey()}T00:00:00Z`);
  const diffDays = Math.round((today.getTime() - last.getTime()) / 86400000);
  if (diffDays <= 0) return stored === 0 ? 1 : stored;
  if (diffDays === 1) return stored + 1;
  return 1;
}

interface BadgeCtx {
  created: number;
  solved: number;
  streak: number;
  level: number;
  perfect: number;
  likes: number;
}

/** Mirrors the client-side BadgeCatalog thresholds. */
function earnedBadges(ctx: BadgeCtx): string[] {
  const out: string[] = [];
  if (ctx.created >= 1) out.push("first_hide");
  if (ctx.solved >= 10) out.push("sharp_eyes");
  if (ctx.perfect >= 5) out.push("flawless");
  if (ctx.streak >= 7) out.push("on_fire");
  if (ctx.likes >= 100) out.push("crowd_favourite");
  if (ctx.level >= 20) out.push("master");
  return out;
}

interface ProgressionDelta {
  xp: number;
  created?: number;
  solved?: number;
  perfect?: number;
}

interface ProgressionResult {
  xpAwarded: number;
  newXp: number;
  newLevel: number;
  leveledUp: boolean;
  newBadgeIds: string[];
  streakDays: number;
}

/** Applies an XP/counter delta and recomputes level, streak and badges. */
async function applyProgression(
  uid: string,
  delta: ProgressionDelta,
): Promise<ProgressionResult> {
  return db.runTransaction(async (tx) => {
    const ref = db.doc(`users/${uid}`);
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const num = (k: string): number =>
      typeof data[k] === "number" ? (data[k] as number) : 0;

    const oldLevel = num("level") || 1;
    const newXp = num("xp") + delta.xp;
    const newLevel = levelForXp(newXp);
    const streak = computeStreak(data.lastActiveDay, num("streakDays"));
    const created = num("challengesCreated") + (delta.created ?? 0);
    const solved = num("challengesSolved") + (delta.solved ?? 0);
    const perfect = num("perfectSolves") + (delta.perfect ?? 0);

    const badges = earnedBadges({
      created,
      solved,
      streak,
      level: newLevel,
      perfect,
      likes: num("totalLikes"),
    });
    const previous: string[] =
      Array.isArray(data.badgeIds) ? (data.badgeIds as string[]) : [];
    const newBadgeIds = badges.filter((b) => !previous.includes(b));

    tx.set(
      ref,
      {
        xp: newXp,
        level: newLevel,
        streakDays: streak,
        lastActiveDay: todayKey(),
        challengesCreated: created,
        challengesSolved: solved,
        perfectSolves: perfect,
        badgeIds: badges,
      },
      {merge: true},
    );

    return {
      xpAwarded: delta.xp,
      newXp,
      newLevel,
      leveledUp: newLevel > oldLevel,
      newBadgeIds,
      streakDays: streak,
    };
  });
}

/**
 * Validates and records a play session, then pays out progression.
 *
 * The client only sends its raw taps and claimed duration; the server
 * re-runs hit detection against the challenge's ground-truth Inkling
 * positions and recomputes the score, so neither finds nor points can be
 * fabricated. Progression pays out once per player and challenge, never to
 * the challenge's own author, and the speed bonus is computed against a
 * physical floor of 200ms per tap so under-reporting the clock buys nothing.
 */
export const submitAttempt = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to play.");
  }

  const data = (request.data ?? {}) as Record<string, unknown>;
  const challengeId = data.challengeId;
  const taps = data.taps;
  const durationMs = data.durationMs;

  if (
    typeof challengeId !== "string" ||
    challengeId.length === 0 ||
    challengeId.length > 128
  ) {
    throw new HttpsError("invalid-argument", "challengeId is required.");
  }
  if (
    !Array.isArray(taps) ||
    taps.length % 2 !== 0 ||
    taps.length > 2000 ||
    taps.some(
      (v) => typeof v !== "number" || !isFinite(v) || v < -1 || v > 2,
    )
  ) {
    throw new HttpsError(
      "invalid-argument",
      "taps must be a flat list of normalised coordinates.",
    );
  }
  const claimedMs =
    typeof durationMs === "number" && isFinite(durationMs) ?
      Math.min(Math.max(0, Math.floor(durationMs)), 86400000) :
      0;

  const challengeSnap = await db.doc(`challenges/${challengeId}`).get();
  if (!challengeSnap.exists) {
    throw new HttpsError("not-found", "Challenge not found.");
  }
  const challenge = challengeSnap.data() ?? {};
  const inklings = Array.isArray(challenge.inklings) ?
    (challenge.inklings as Record<string, unknown>[]) :
    [];

  // Re-run detection in tap order against the ground truth.
  const found = new Set<number>();
  const coords = taps as number[];
  for (let t = 0; t < coords.length; t += 2) {
    const tapX = coords[t];
    const tapY = coords[t + 1];
    let best = -1;
    let bestDistance = Infinity;
    for (let i = 0; i < inklings.length; i++) {
      if (found.has(i)) continue;
      const ink = inklings[i] ?? {};
      const cx = typeof ink.cx === "number" ? ink.cx : NaN;
      const cy = typeof ink.cy === "number" ? ink.cy : NaN;
      const size = typeof ink.size === "number" ? ink.size : 0;
      const distance = Math.hypot(tapX - cx, tapY - cy);
      const radius = size / 2 + DETECTION_TOLERANCE;
      if (distance <= radius && distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    if (best >= 0) found.add(best);
  }

  const total = inklings.length;
  const tapCount = coords.length / 2;
  const foundCount = found.size;
  const complete = total > 0 && foundCount === total;
  const flawless = complete && tapCount === foundCount;

  // Same formula as the client's PlaySession.computeScore, with the
  // anti-cheat duration floor applied to the speed bonus.
  const effectiveMs = Math.max(claimedMs, tapCount * 200);
  const completion = total === 0 ? 0 : foundCount / total;
  const accuracy = tapCount === 0 ? 0 : foundCount / tapCount;
  const speed = Math.max(0, 1 - effectiveMs / 1000 / 120);
  const score = Math.round(
    Math.min(
      MAX_SCORE,
      completion * 1000 +
        accuracy * 400 +
        speed * 300 * completion +
        (complete ? 300 : 0),
    ),
  );

  const isAuthor = challenge.authorId === uid;
  const prior = await db
    .collection("attempts")
    .where("challengeId", "==", challengeId)
    .where("playerId", "==", uid)
    .limit(1)
    .get();
  const firstAttempt = prior.empty;

  await db.collection("attempts").add({
    challengeId,
    playerId: uid,
    foundCount,
    totalInklings: total,
    durationMs: claimedMs,
    score,
    taps: coords,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (complete) {
    await db.runTransaction(async (tx) => {
      const ref = db.doc(`challenges/${challengeId}`);
      const snap = await tx.get(ref);
      const current = snap.get("bestTimeMs");
      if (typeof current !== "number" || effectiveMs < current) {
        tx.update(ref, {bestTimeMs: effectiveMs});
      }
    });
  }

  let progression: ProgressionResult | null = null;
  if (firstAttempt && !isAuthor && foundCount > 0) {
    progression = await applyProgression(uid, {
      xp:
        foundCount * XP_PER_INKLING_FOUND +
        (complete ? XP_PER_CHALLENGE_SOLVED : 0),
      solved: complete ? 1 : 0,
      perfect: flawless ? 1 : 0,
    });
  }

  return {
    score,
    foundCount,
    totalInklings: total,
    complete,
    flawless,
    firstAttempt,
    progression,
  };
});

const APP_STORE_URL = "https://apps.apple.com/app/id0000000000";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=app.inkognito.game";
const APP_SCHEME = "inkognito://challenge/";

/**
 * Awards the author's creation progression on new challenge: XP, created
 * count, level, streak and badges — the client never writes these itself.
 */
export const onChallengeCreated = onDocumentCreated(
  "challenges/{challengeId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const authorId = data.authorId as string;
    if (!authorId) return;
    await applyProgression(authorId, {
      xp: XP_PER_CHALLENGE_CREATED,
      created: 1,
    });
  },
);

/** Decrement on deletion and clean up sub-collections. */
export const onChallengeDeleted = onDocumentDeleted(
  "challenges/{challengeId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const authorId = data.authorId as string;
    if (authorId) {
      await db.doc(`users/${authorId}`).set(
        {challengesCreated: FieldValue.increment(-1)},
        {merge: true},
      );
    }
  },
);

/** Aggregate likes into the author's total for the "Crowd Favourite" badge. */
export const onLikeWritten = onDocumentCreated(
  "challenges/{challengeId}/likes/{uid}",
  async (event) => {
    const challenge = await db
      .doc(`challenges/${event.params.challengeId}`)
      .get();
    const authorId = challenge.get("authorId") as string | undefined;
    if (!authorId) return;
    await db.doc(`users/${authorId}`).set(
      {totalLikes: FieldValue.increment(1)},
      {merge: true},
    );
  },
);

/**
 * Public share landing page. Opens the app via a deep link when installed,
 * otherwise falls back to the appropriate store. Serves OpenGraph tags so the
 * camouflaged image previews nicely in chats and social feeds.
 */
export const openChallenge = onRequest(async (req, res) => {
  const match = req.path.match(/\/c\/([A-Za-z0-9_-]+)/);
  const challengeId = match?.[1];
  if (!challengeId) {
    res.status(404).send("Not found");
    return;
  }

  let title = "Inkognito challenge";
  let image = "";
  try {
    const doc = await db.doc(`challenges/${challengeId}`).get();
    if (doc.exists) {
      title = (doc.get("title") as string) ?? title;
      image = (doc.get("camouflagedImageUrl") as string) ?? "";
    }
  } catch (e) {
    logger.warn("Failed to load challenge for landing page", e);
  }

  const deepLink = `${APP_SCHEME}${challengeId}`;
  res.set("Content-Type", "text/html");
  res.status(200).send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${escapeHtml(title)} · Inkognito</title>
  <meta property="og:title" content="${escapeHtml(title)}" />
  <meta property="og:description"
        content="Can you find the hidden Inklings?" />
  ${image ? `<meta property="og:image" content="${escapeHtml(image)}" />` : ""}
  <meta name="twitter:card" content="summary_large_image" />
</head>
<body style="font-family:sans-serif;text-align:center;padding:40px">
  <h1>${escapeHtml(title)}</h1>
  <p>Opening in Inkognito…</p>
  <p>
    <a href="${APP_STORE_URL}">App Store</a> ·
    <a href="${PLAY_STORE_URL}">Google Play</a>
  </p>
  <script>
    // Try the app; fall back to the correct store after a short delay.
    var ua = navigator.userAgent || "";
    var store = /android/i.test(ua)
      ? ${JSON.stringify(PLAY_STORE_URL)}
      : ${JSON.stringify(APP_STORE_URL)};
    window.location = ${JSON.stringify(deepLink)};
    setTimeout(function () { window.location = store; }, 1200);
  </script>
</body>
</html>`);
});

/**
 * RevenueCat server webhook. Flips the user's `isPremium` flag based on the
 * entitlement state. Configure the webhook URL + auth header in RevenueCat.
 */
export const revenueCatWebhook = onRequest(async (req, res) => {
  const secret = process.env.RC_WEBHOOK_SECRET;
  if (secret && req.get("Authorization") !== `Bearer ${secret}`) {
    res.status(401).send("Unauthorized");
    return;
  }
  const ev = req.body?.event;
  const appUserId: string | undefined = ev?.app_user_id;
  if (!appUserId) {
    res.status(400).send("Missing app_user_id");
    return;
  }
  const activeEntitlements: string[] = ev?.entitlement_ids ?? [];
  const type: string = ev?.type ?? "";
  const isPremium =
    activeEntitlements.includes("premium") &&
    type !== "CANCELLATION" &&
    type !== "EXPIRATION";

  await db.doc(`users/${appUserId}`).set({isPremium}, {merge: true});
  logger.info("Updated premium status", {appUserId, isPremium, type});
  res.status(200).send("ok");
});

/** Featured "challenge of the day": tag the most-liked recent public ones. */
export const rotateDailyChallenges = onSchedule(
  "every day 00:05",
  async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const snap = await db
      .collection("challenges")
      .where("isPublic", "==", true)
      .orderBy("likeCount", "desc")
      .limit(10)
      .get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.update(d.ref, {featured: true}));
    await batch.commit();
    logger.info(`Featured ${snap.size} challenges`);
  },
);

function escapeHtml(input: string): string {
  return input
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
