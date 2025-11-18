#!/usr/bin/env bash

#get date
date=$(date --utc +%FT%T.%3NZ)

rm -rf ida_fir_temp.txt ida_fir_result.txt ida_pubkey.pem ida_cert.pem

echo -e "\n Generating JWKS for IDA-FIR certificates (RAW OUTPUT MODE)\n"
echo "AUTHMANAGER URL : $AUTHMANAGER_URL"
echo "IDA INTERNAL URL : $IDA_INTERNAL_URL"

# Authenticate
curl -s -D - -o /dev/null -X "POST" \
  "$AUTHMANAGER_URL/authenticate/clientidsecretkey" \
  -H "accept: */*" \
  -H "Content-Type: application/json" \
  -d '{
  "id": "string",
  "version": "string",
  "requesttime": "'$date'",
  "metadata": {},
  "request": {
    "clientId": "'$KEYCLOAK_CLIENT_ID'",
    "secretKey": "'$KEYCLOAK_CLIENT_SECRET'",
    "appId": "'$AUTH_APP_ID'"
  }
}' > ida_fir_temp.txt 2>&1 &

sleep 10

# Extract token
TOKEN=$( cat ida_fir_temp.txt | awk '/[aA]uthorization:/{print $2}' | sed -z 's/\n//g' | sed -z 's/\r//g' )

if [[ -z $TOKEN ]]; then
  echo "Unable to authenticate with Authmanager. \"TOKEN\" is empty; EXITING"
  exit 1
fi

echo -e "\nGot authorization token from Authmanager"

# Get certificate JSON
curl -s -X "GET" \
  -H "Accept: application/json" \
  --cookie "Authorization=$TOKEN" \
  "$IDA_INTERNAL_URL/getAllCertificates?applicationId=IDA&referenceId=IDA-FIR" > ida_fir_result.txt

# Validate JSON structure (just checks if JSON, not formatting)
if ! jq empty ida_fir_result.txt 2>/dev/null; then
  echo "Invalid JSON received from server; EXITING"
  exit 1
fi

echo -e "\n**************** RAW CERTIFICATE JSON (wrapped) ****************\n"

# PRINT EXACT RESPONSE, UNCHANGED, WITH [] AS WRAPPER
echo "["
cat ida_fir_result.txt
echo "]"

echo -e "\n***************************************************************\n"
echo "Displayed raw certificate JSON successfully"

# cleanup env var as in original script
echo "MOSIP_REGPROC_CLIENT_SECRET=''" >> ~/.bashrc
source ~/.bashrc
