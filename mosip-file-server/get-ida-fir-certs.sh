#!/usr/bin/env bash

# Get current UTC time in required format
date=$(date --utc +%FT%T.%3NZ)

# Cleanup old files
rm -rf ida_fir_temp.txt ida_fir_certs.pem

echo -e "\n=== Fetching IDA-FIR Certificates (PEM only) ===\n"
echo "AUTHMANAGER URL      : $AUTHMANAGER_URL"
echo "IDA INTERNAL URL     : $IDA_INTERNAL_URL"
echo "Target PEM file      : $base_path_mosip_certs/ida-fir-certs.pem"
echo


echo " Authenticating with Authmanager..."
curl -s -D - -o /dev/null -X POST \
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
}' > ida_fir_temp.txt 2>&1


TOKEN=$(grep -i '^Authorization:' ida_fir_temp.txt | awk '{print $2}' | tr -d '\r')

if [[ -z "$TOKEN" ]]; then
  echo "Failed: Unable to authenticate with Authmanager. Token is empty."
  echo "Response headers were:"
  cat ida_fir_temp.txt
  exit 1
fi

echo "Authentication successful"


echo " Downloading certificates from Keymanager..."
curl -s -f -X GET \
  -H "Accept: application/json" \
  --cookie "Authorization=$TOKEN" \
  "$IDA_INTERNAL_URL/getAllCertificates?applicationId=IDA&referenceId=IDA-FIR" \
  -o ida_fir_raw_response.json

if [[ $? -ne 0 ]] || [[ ! -s ida_fir_raw_response.json ]]; then
  echo "Failed: Could not download certificates from Keymanager"
  exit 1
fi


echo " Extracting PEM certificates..."



jq -r '.response.allCertificates[].certificate' ida_fir_raw_response.json > "$base_path_mosip_certs/ida-fir-certs.pem"

if [[ ! -s "$base_path_mosip_certs/ida-fir-certs.pem" ]]; then
  echo "Failed: No PEM certificates were extracted."
  echo "Raw response:"
  cat ida_fir_raw_response.json
  exit 1
fi


echo -e "\nSuccess: IDA-FIR certificates saved as PEM file"
echo "File: $base_path_mosip_certs/ida-fir-certs.pem"
echo "Total certificates: $(grep -c "BEGIN CERTIFICATE" "$base_path_mosip_certs/ida-fir-certs.pem")"
echo
echo "----- First certificate preview -----"
openssl x509 -in "$base_path_mosip_certs/ida-fir-certs.pem" -text -noout | head -20
echo "-------------------------------------"

# Cleanup temporary files
rm -f ida_fir_temp.txt ida_fir_raw_response.json

echo -e "\n PEM file generated .\n"
