ogiri_prompts.json — master list for lab ogiri seeds.
Copied to functions/ogiri_prompts.json for Cloud Functions (requires Blaze plan).

Without Functions: operator (yuto.mabe@gmail.com) app auto-seeds on launch if seed-ogiri-* docs are missing.

Manual HTTP after Functions deploy:
  curl -X POST -H "X-Lab-Seed: ozio-lab-seed-beta" \
    https://asia-northeast1-tick-beta.cloudfunctions.net/seedLabOgiriHttp
