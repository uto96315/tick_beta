const fs = require("fs");
const path = require("path");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const ADMIN_EMAIL = "yuto.mabe@gmail.com";
const BODY = "自由に答えて。";

function loadPrompts() {
  const file = path.join(__dirname, "ogiri_prompts.json");
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

async function upsertOgiriBatch() {
  const db = getFirestore();
  const prompts = loadPrompts();
  const batch = db.batch();
  for (const item of prompts) {
    const ref = db.collection("labPrompts").doc(item.id);
    batch.set(
      ref,
      {
        title: item.title,
        body: BODY,
        category: "stand",
        format: "ogiri",
        phase: "open",
        featured: item.featured === true,
        choices: [],
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await batch.commit();
  return prompts.length;
}

/** Callable: 運営メールでログインした Firebase Auth から実行 */
exports.seedLabOgiri = onCall({ region: "asia-northeast1" }, async (request) => {
  const email = request.auth?.token?.email;
  if (!email || email.toLowerCase() !== ADMIN_EMAIL) {
    throw new HttpsError("permission-denied", "admin only");
  }
  const count = await upsertOgiriBatch();
  return { count };
});

/**
 * HTTP: デプロイ後に一度叩く用（tick-beta 専用キー）。
 * curl -X POST -H "X-Lab-Seed: ozio-lab-seed-beta" URL
 */
exports.seedLabOgiriHttp = onRequest(
  { region: "asia-northeast1", invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("POST only");
      return;
    }
    if (req.get("X-Lab-Seed") !== "ozio-lab-seed-beta") {
      res.status(403).send("forbidden");
      return;
    }
    try {
      const count = await upsertOgiriBatch();
      res.json({ ok: true, count });
    } catch (error) {
      console.error(error);
      res.status(500).json({ ok: false, error: String(error) });
    }
  },
);
