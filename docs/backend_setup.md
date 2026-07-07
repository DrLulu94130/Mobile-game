# Backend setup

## 1. Firebase project

```bash
firebase login
firebase use --add        # select your project, alias it "default"
```

Enable in the console:
- **Authentication** → Email/Password + Anonymous
- **Firestore** (production mode)
- **Storage**
- **Crashlytics** & **Analytics**

## 2. Deploy rules, indexes and functions

```bash
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

## 3. Cloud Functions overview

| Function | Trigger | Purpose |
| --- | --- | --- |
| `onChallengeCreated` / `onChallengeDeleted` | Firestore | Keep `users.challengesCreated` accurate |
| `onLikeWritten` | Firestore | Aggregate `users.totalLikes` for the Crowd Favourite badge |
| `openChallenge` | HTTPS | Public share landing page: deep-link into the app, fall back to the store, OpenGraph preview of the camouflaged image |
| `revenueCatWebhook` | HTTPS | Sync Premium entitlement onto `users.isPremium` |
| `rotateDailyChallenges` | Schedule (00:05) | Flag the day's featured challenges |

Set the webhook secret:

```bash
firebase functions:secrets:set RC_WEBHOOK_SECRET
```

Point your hosting/rewrite (or the `page.link` domain) `/c/**` at the
`openChallenge` function so shared links resolve.

## 4. RevenueCat

1. Create products and an **Offering** with an entitlement id `premium`.
2. Add the public SDK keys via `--dart-define=RC_ANDROID_KEY=… RC_IOS_KEY=…`.
3. Configure the RevenueCat → Firebase webhook to call `revenueCatWebhook`
   with header `Authorization: Bearer <RC_WEBHOOK_SECRET>`.

## Data model

```
users/{uid}                       profile + progression (xp, level, streak, badges)
challenges/{id}                   camouflaged + revealed URLs, inkling placements
challenges/{id}/likes/{uid}       one doc per like
challenges/{id}/comments/{id}     comment thread
attempts/{id}                     play results (score, time, taps) for leaderboards
```
