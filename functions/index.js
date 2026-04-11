'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onMessagePublished }  = require('firebase-functions/v2/pubsub');
const { onDocumentCreated }   = require('firebase-functions/v2/firestore');
const { initializeApp }       = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging }        = require('firebase-admin/messaging');
const { google }              = require('googleapis');
const OpenAI                  = require('openai');
const pdfParse                = require('pdf-parse');

initializeApp();
const db          = getFirestore();
const messaging   = getMessaging();

// ── Env vars (set via .env in functions/ for local dev, or firebase functions:secrets:set for prod) ──
const OPENAI_API_KEY  = process.env.OPENAI_API_KEY;
const AUTHORITY_EMAIL = process.env.AUTHORITY_EMAIL  || 'transport@kuet.ac.bd';
const GMAIL_USER      = process.env.GMAIL_USER       || 'me';
const PUBSUB_TOPIC    = process.env.PUBSUB_TOPIC     || 'gmail-kuet-watch';

// ── OpenAI client ─────────────────────────────────────────────────────────────
const openai = new OpenAI({ apiKey: OPENAI_API_KEY });

// ── Gmail OAuth2 client ───────────────────────────────────────────────────────
function buildGmailClient() {
  const auth = new google.auth.OAuth2(
    process.env.GMAIL_CLIENT_ID,
    process.env.GMAIL_CLIENT_SECRET,
  );
  auth.setCredentials({ refresh_token: process.env.GMAIL_REFRESH_TOKEN });
  return google.gmail({ version: 'v1', auth });
}

// ═════════════════════════════════════════════════════════════════════════════
// FUNCTION 1 — setupGmailWatch
// Call this once manually via Firebase Console or CLI to activate inbox watching.
// ═════════════════════════════════════════════════════════════════════════════
exports.setupGmailWatch = onCall({ region: 'us-central1' }, async (request) => {
  const gmail     = buildGmailClient();
  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;

  const topicName = `projects/${projectId}/topics/${PUBSUB_TOPIC}`;

  const response = await gmail.users.watch({
    userId: GMAIL_USER,
    requestBody: {
      labelIds: ['INBOX'],
      topicName,
    },
  });

  console.log('Gmail watch set up:', response.data);
  return { success: true, data: response.data };
});

// ═════════════════════════════════════════════════════════════════════════════
// FUNCTION 2 — handleGmailPubSub
// Triggered by Google Pub/Sub whenever a new email arrives in the watched inbox.
// ═════════════════════════════════════════════════════════════════════════════
exports.handleGmailPubSub = onMessagePublished(
  { topic: PUBSUB_TOPIC, region: 'us-central1' },
  async (event) => {
    // ── 1. Decode Pub/Sub message ───────────────────────────────────────────
    const rawData = event.data.message.data;
    if (!rawData) { console.log('Empty Pub/Sub message, skipping.'); return; }

    let parsed;
    try {
      parsed = JSON.parse(Buffer.from(rawData, 'base64').toString('utf8'));
    } catch {
      console.error('Could not parse Pub/Sub message.');
      return;
    }

    const historyId = parsed.historyId;
    if (!historyId) { console.log('No historyId, skipping.'); return; }

    // ── 2. Fetch new messages via Gmail history ─────────────────────────────
    const gmail = buildGmailClient();
    let messages = [];
    try {
      const historyRes = await gmail.users.history.list({
        userId: GMAIL_USER,
        startHistoryId: historyId,
        historyTypes: ['messageAdded'],
      });
      const records = historyRes.data.history || [];
      messages = records.flatMap(r => r.messagesAdded || []).map(m => m.message);
    } catch (err) {
      console.error('Failed to fetch history:', err.message);
      return;
    }

    if (messages.length === 0) { console.log('No new messages.'); return; }

    // ── 3. Process each new message ─────────────────────────────────────────
    for (const msg of messages) {
      try {
        await processEmail(gmail, msg.id);
      } catch (err) {
        console.error(`Error processing message ${msg.id}:`, err.message);
      }
    }
  },
);

// ── Process a single email ────────────────────────────────────────────────────
async function processEmail(gmail, messageId) {
  const fullMsg = await gmail.users.messages.get({
    userId: GMAIL_USER,
    id: messageId,
    format: 'full',
  });

  const payload = fullMsg.data.payload;
  const headers = payload.headers || [];

  // ── Check sender ────────────────────────────────────────────────────────
  const fromHeader = headers.find(h => h.name.toLowerCase() === 'from')?.value || '';
  if (!fromHeader.toLowerCase().includes(AUTHORITY_EMAIL.toLowerCase())) {
    console.log(`Skipping email from: ${fromHeader}`);
    return;
  }

  console.log(`Processing authority email from: ${fromHeader}`);

  // ── Extract body and attachment ─────────────────────────────────────────
  const emailBody    = extractTextBody(payload);
  const pdfAttachment = await findPdfAttachment(gmail, messageId, payload);

  // ── Call GPT-4o ─────────────────────────────────────────────────────────
  const extracted = await extractScheduleWithAI(emailBody, pdfAttachment);
  if (!extracted) {
    console.log('GPT-4o found no schedule info in this email.');
    return;
  }

  const date = extracted.date;
  if (!date) { console.log('No date in extracted schedule, skipping.'); return; }

  // ── Write pending schedule to Firestore ────────────────────────────────
  await db.collection('pending_schedules').doc(date).set({
    ...extracted,
    status: 'pending_approval',
    receivedAt: Timestamp.now(),
    extractedFrom: extracted.extracted_from || 'email_body',
  });
  console.log(`Pending schedule written for date: ${date}`);

  // ── Send FCM notification ───────────────────────────────────────────────
  const title = 'Bus Schedule Update';
  const body  = `A new schedule update has been received for ${date}. Tap to review.`;

  await messaging.send({
    topic: 'all_users',
    notification: { title, body },
    data: { type: 'schedule_update', date },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  });

  // ── Write notification document ─────────────────────────────────────────
  await db.collection('notifications').add({
    title,
    body,
    date,
    type: 'schedule_update',
    status: 'pending',
    createdAt: Timestamp.now(),
  });

  console.log(`FCM notification sent and Firestore notification doc written for ${date}.`);
}

// ═════════════════════════════════════════════════════════════════════════════
// FUNCTION 3 — watchApprovedSchedules
// Firestore trigger: when a live_schedules document is created, send FCM push.
// This fires when the Flutter admin approves a pending schedule.
// ═════════════════════════════════════════════════════════════════════════════
exports.watchApprovedSchedules = onDocumentCreated(
  { document: 'live_schedules/{date}', region: 'us-central1' },
  async (event) => {
    const date = event.params.date;
    const title = '✅ Schedule Updated';
    const body  = `The bus schedule for ${date} is now live.`;

    await messaging.send({
      topic: 'all_users',
      notification: { title, body },
      data: { type: 'schedule_live', date },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });

    console.log(`Live schedule FCM sent for date: ${date}`);
  },
);

// ═════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═════════════════════════════════════════════════════════════════════════════

/** Recursively find plain-text body parts in a Gmail message payload. */
function extractTextBody(payload) {
  if (payload.mimeType === 'text/plain' && payload.body?.data) {
    return Buffer.from(payload.body.data, 'base64').toString('utf8');
  }
  if (payload.parts) {
    for (const part of payload.parts) {
      const result = extractTextBody(part);
      if (result) return result;
    }
  }
  return '';
}

/** Find the first PDF attachment and return its decoded Buffer, or null. */
async function findPdfAttachment(gmail, messageId, payload) {
  const parts = payload.parts || [];
  for (const part of parts) {
    if (
      part.mimeType === 'application/pdf' ||
      (part.filename && part.filename.toLowerCase().endsWith('.pdf'))
    ) {
      const attachmentId = part.body?.attachmentId;
      if (!attachmentId) continue;

      const att = await gmail.users.messages.attachments.get({
        userId: GMAIL_USER,
        messageId,
        id: attachmentId,
      });

      if (att.data?.data) {
        return Buffer.from(att.data.data, 'base64');
      }
    }
  }
  return null;
}

/** Send email body or PDF text to GPT-4o and return structured JSON, or null. */
async function extractScheduleWithAI(emailBody, pdfBuffer) {
  let userContent = '';
  let extractedFrom = 'email_body';

  if (pdfBuffer) {
    try {
      const parsed = await pdfParse(pdfBuffer);
      userContent   = parsed.text;
      extractedFrom = 'pdf_attachment';
    } catch (err) {
      console.warn('PDF parse failed, falling back to email body:', err.message);
      userContent = emailBody;
    }
  } else {
    userContent = emailBody;
  }

  if (!userContent.trim()) {
    console.log('No text content to extract from.');
    return null;
  }

  const systemPrompt = `You are an AI that extracts bus schedule information from university authority emails.
Return ONLY valid JSON — no markdown, no code fences, no preamble.
If no schedule information is found, return the single word: null

The JSON schema must be exactly:
{
  "date": "YYYY-MM-DD",
  "is_override": true,
  "extracted_from": "email_body" | "pdf_attachment",
  "routes": [
    {
      "route_name": "string",
      "stops": [
        { "stop_name": "string", "time": "HH:mm" }
      ]
    }
  ]
}`;

  const userPrompt = `Extract bus schedule information from the following text. The university is KUET (Khulna University of Engineering & Technology).

extracted_from: ${extractedFrom}

---
${userContent.slice(0, 12000)}
---`;

  let raw;
  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      temperature: 0,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user',   content: userPrompt },
      ],
    });
    raw = completion.choices[0].message.content.trim();
  } catch (err) {
    console.error('OpenAI API error:', err.message);
    return null;
  }

  if (raw === 'null' || raw === '') return null;

  try {
    const result = JSON.parse(raw);
    result.extracted_from = extractedFrom;
    return result;
  } catch (err) {
    console.error('GPT-4o returned invalid JSON:', err.message, '\nRaw:', raw);
    return null;
  }
}
