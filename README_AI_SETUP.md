# AI Features Setup Guide

This guide covers the complete setup for the two AI-powered features:
1. **Gmail Watch → AI Schedule Extraction → FCM Push** (Cloud Functions)
2. **In-App Chatbot** (GPT-4o, Flutter)

---

## Section 1 — Enable Gmail API & Create OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and open your Firebase project.
2. Navigate to **APIs & Services → Library** and enable **Gmail API**.
3. Go to **APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID**.
   - Application type: **Web application**
   - Add `https://developers.google.com/oauthplayground` as an Authorized redirect URI.
4. Copy the **Client ID** and **Client Secret** — you'll need them next.

### Get a Refresh Token
1. Go to [OAuth 2.0 Playground](https://developers.google.com/oauthplayground).
2. Click the gear icon (top-right) → check **Use your own OAuth credentials** → paste your Client ID and Secret.
3. In Step 1, find **Gmail API v1** and select `https://mail.google.com/`.
4. Click **Authorize APIs**, sign in with the KUET inbox account.
5. In Step 2, click **Exchange authorization code for tokens**.
6. Copy the **Refresh token** — this is your `GMAIL_REFRESH_TOKEN`.

---

## Section 2 — Set Up Google Pub/Sub Topic

1. In Google Cloud Console, go to **Pub/Sub → Topics → Create Topic**.
2. Name it exactly what you put in `PUBSUB_TOPIC` (e.g. `gmail-kuet-watch`).
3. Grant Gmail permission to publish to this topic:
   ```
   gcloud pubsub topics add-iam-policy-binding gmail-kuet-watch \
     --member="serviceAccount:gmail-api-push@system.gserviceaccount.com" \
     --role="roles/pubsub.publisher"
   ```

---

## Section 3 — Deploy Cloud Functions

```bash
# Install dependencies
cd functions
npm install

# Copy .env.example → .env and fill in all values
cp .env.example .env
# Edit .env with your real keys

# Deploy
firebase deploy --only functions
```

> **Node version:** Functions require Node 20. Install via `nvm use 20`.

---

## Section 4 — Set Environment Variables

For production, set secrets via Firebase:

```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set GMAIL_CLIENT_ID
firebase functions:secrets:set GMAIL_CLIENT_SECRET
firebase functions:secrets:set GMAIL_REFRESH_TOKEN
firebase functions:secrets:set GMAIL_USER
firebase functions:secrets:set AUTHORITY_EMAIL
firebase functions:secrets:set PUBSUB_TOPIC
```

Or use the `.env` file in `functions/` for local development with the Firebase Emulator.

---

## Section 5 — Activate Gmail Watch (Run Once)

After deploying, trigger `setupGmailWatch` once to register the push notification:

**Option A — Firebase Console:**
1. Go to Firebase Console → Functions → `setupGmailWatch`.
2. Click **Run** (or use the test tab).

**Option B — CLI:**
```bash
curl -X POST https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/setupGmailWatch \
  -H "Content-Type: application/json" \
  -d '{}'
```

Gmail watch expires after **7 days**. Set a Cloud Scheduler job to re-run `setupGmailWatch` every 6 days:
```bash
gcloud scheduler jobs create http renew-gmail-watch \
  --schedule="0 0 */6 * *" \
  --uri="https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/setupGmailWatch" \
  --message-body="{}" \
  --headers="Content-Type=application/json"
```

---

## Section 6 — Flutter OpenAI Key

1. Copy the example constants file:
   ```bash
   cp lib/core/constants/api_constants.example.dart lib/core/constants/api_constants.dart
   ```
2. Open `lib/core/constants/api_constants.dart` and replace the placeholder:
   ```dart
   static const String openAiKey = 'sk-...your-real-key...';
   ```
3. `api_constants.dart` is in `.gitignore` — it will never be committed.

---

## How It All Works (End-to-End Flow)

```
University authority sends email to KUET inbox
        ↓
Gmail API pushes notification to Google Pub/Sub
        ↓
handleGmailPubSub Cloud Function fires
        ↓
Checks sender == AUTHORITY_EMAIL
        ↓
Downloads email body / PDF attachment
        ↓
Sends text to GPT-4o → gets structured JSON schedule
        ↓
Writes to Firestore: pending_schedules/{date}
        ↓
Sends FCM push to topic "all_users"
        ↓
App receives FCM → shows local notification
        ↓
User taps notification → opens PendingScheduleScreen
        ↓
Admin reviews → taps "Approve & Apply"
        ↓
Firestore: pending_schedules/{date} copied to live_schedules/{date}
        ↓
watchApprovedSchedules Cloud Function fires
        ↓
Sends FCM push: "Schedule is now live"
        ↓
Chatbot reads live_schedules/{today} for context
```

---

## Manual Testing Checklist

### Test FCM Notifications
1. Run the app on a real device (FCM doesn't work on emulator).
2. Check Flutter console — you should see the FCM token logged on first launch.
3. Send a test FCM message from Firebase Console → Cloud Messaging → Send test message.
   - Add data: `{ "type": "schedule_update", "date": "2026-04-07" }`
   - Verify the app navigates to `PendingScheduleScreen` on tap.

### Test Pending Schedule Screen
1. Manually write a test document to Firestore:
   - Collection: `pending_schedules`
   - Document ID: `2026-04-07`
   - Fields: `date`, `status: "pending_approval"`, `routes: [...]`
2. In the app, tap a schedule_update notification (or navigate directly in debug).
3. Verify the pending banner appears and routes display correctly.
4. Log in as admin → verify Approve / Reject buttons appear.
5. Tap Approve → verify document moves to `live_schedules/2026-04-07`.

### Test Chatbot
1. Put your real OpenAI API key in `api_constants.dart`.
2. Run the app → tap the chat bubble FAB (bottom-right, above nav bar).
3. Type "What buses run on Sunday morning?" — GPT-4o should respond.
4. Write a live schedule to `live_schedules/{today}` in Firestore — the chatbot will use it as context.

### Test Gmail Watch (full end-to-end)
1. Deploy functions and run `setupGmailWatch`.
2. Send an email to the watched inbox **from** `AUTHORITY_EMAIL` with bus schedule info.
3. Wait ~10 seconds → check Firebase Functions logs for extraction output.
4. Check Firestore `pending_schedules` collection for the new document.
5. Check the app — a push notification should arrive.
