#!/usr/bin/env bash

set -euo pipefail

date=$(date --utc +%FT%T.%3NZ)

# cleanup
rm -f auth_headers.txt response.json "$base_path_mosip_certs/ida-fir.cer"

echo -e "\n=== Generating IDA-FIR .cer (PEM text) ===\n"

# auth
curl -s -D auth_headers.txt -o /dev/null -X POST \
  "$AUTHMANAGER_URL/authenticate/clientidsecretkey" \
  -H "Content-Type: application/json" \
  -d '{
    "id":"string","version":"string","requesttime":"'$date'",
    "metadata":{},"request":{
      "clientId":"'$KEYCLOAK_CLIENT_ID'",
      "secretKey":"'$KEYCLOAK_CLIENT_SECRET'",
      "appId":"'$AUTH_APP_ID'"
    }
  }'

TOKEN=$(grep -i '^Authorization:' auth_headers.txt | awk '{print $2}' | tr -d '\r\n')
[[ -z "$TOKEN" ]] && { echo "No token"; exit 1; }

# download certs
curl -s --cookie "Authorization=$TOKEN" \
  -H "Accept: application/json" \
  "$IDA_INTERNAL_URL/getAllCertificates?applicationId=IDA&referenceId=IDA-FIR" \
  -o response.json

# save as .cer (PEM text)
jq -r '.response.allCertificates[].certificate' response.json > "$base_path_mosip_certs/ida-fir.cer"

# check result
if ! grep -q "BEGIN CERTIFICATE" "$base_path_mosip_certs/ida-fir.cer"; then
  echo "No cert found"
  jq . response.json
  exit 1
fi

echo -e "Done → $base_path_mosip_certs/ida-fir.cer\n"

# cleanup
rm -f auth_headers.txt response.json
