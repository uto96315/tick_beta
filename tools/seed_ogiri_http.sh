#!/usr/bin/env bash
# Deploy functions (if needed) then POST seedLabOgiriHttp.
set -euo pipefail
cd "$(dirname "$0")/.."
PROJECT="${FIREBASE_PROJECT:-tick-beta}"
REGION="asia-northeast1"

echo "Deploying functions to ${PROJECT}..."
firebase deploy --only functions --project "$PROJECT"

URL=$(firebase functions:list --project "$PROJECT" --json 2>/dev/null | node -e "
const chunks=[]; process.stdin.on('data',d=>chunks.push(d));
process.stdin.on('end',()=>{
  const raw=JSON.parse(Buffer.concat(chunks).toString());
  const list=raw.result||raw;
  const fn=list.find(x=>x.id&&x.id.includes('seedLabOgiriHttp'));
  if(!fn){ console.error('seedLabOgiriHttp not found'); process.exit(1); }
  console.log(fn.httpsTrigger?.url || fn.uri || '');
});
" 2>/dev/null || true)

if [[ -z "${URL}" ]]; then
  URL="https://${REGION}-${PROJECT}.cloudfunctions.net/seedLabOgiriHttp"
fi

echo "Seeding via ${URL}"
curl -sfS -X POST -H "X-Lab-Seed: ozio-lab-seed-beta" "$URL"
echo
