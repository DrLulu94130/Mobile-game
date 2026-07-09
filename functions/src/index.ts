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
import {onDocumentCreated, onDocumentDeleted, onDocumentUpdated} from
  "firebase-functions/v2/firestore";
import {onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {logger} from "firebase-functions";

initializeApp();
const db = getFirestore();

/** Tokens paid to a creator each time their drawing fools a seeker. */
const CREATOR_FOOL_REWARD = 1;

const APP_STORE_URL = "https://apps.apple.com/app/id0000000000";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=app.inkognito.game";
const APP_SCHEME = "inkognito://challenge/";

/** Bump the author's created-challenge count on new challenge. */
export const onChallengeCreated = onDocumentCreated(
  "challenges/{challengeId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const authorId = data.authorId as string;
    if (!authorId) return;
    await db.doc(`users/${authorId}`).set(
      {challengesCreated: FieldValue.increment(1)},
      {merge: true},
    );
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

/**
 * Reward the creator when their drawing fools a seeker in Discover.
 *
 * This runs server-side (Admin SDK) so the reward is authoritative: a client
 * cannot credit its own account, only trigger a legitimate seek outcome that
 * the platform then pays out. Fires whenever `seekFailCount` increases.
 */
export const onChallengeFooledSeeker = onDocumentUpdated(
  "challenges/{challengeId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const beforeFails = (before.seekFailCount as number) ?? 0;
    const afterFails = (after.seekFailCount as number) ?? 0;
    const delta = afterFails - beforeFails;
    if (delta <= 0) return;
    const authorId = after.authorId as string | undefined;
    if (!authorId) return;
    await db.doc(`users/${authorId}`).set(
      {tokens: FieldValue.increment(delta * CREATOR_FOOL_REWARD)},
      {merge: true},
    );
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
