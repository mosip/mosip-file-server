#!/usr/bin/env bash

#get date
date=$(date --utc +%FT%T.%3NZ)

rm -rf ida_sign_temp.txt ida_sign_result.txt ida_pubkey.pem ida_cert.pem

echo -e "\n Generate jwks for IDA SIGN certificates\n";
echo "AUTHMANAGER URL : $AUTHMANAGER_URL"
echo "IDA INTERNAL URL : $IDA_INTERNAL_URL"

#echo "* Request for authorization"
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
}' > ida_sign_temp.txt 2>&1 &

sleep 10
#TOKEN=$(cat -n temp.txt | sed -n '/Authorization:/,/\;.*/pI' |  sed 's/.*Authorization://i; s/$\n.*//I' | awk 'NR==1{print $1}')
#TOKEN=$(cat -n temp.txt | grep -i Authorization: |  sed 's/.*Authorization://i; s/$\n.*//' | awk 'NR==1{print $1}')
TOKEN=$( cat ida_sign_temp.txt | awk '/[aA]uthorization:/{print $2}' | sed -z 's/\n//g' | sed -z 's/\r//g')

if [[ -z $TOKEN ]]; then
  echo "Unable to Authenticate with authmanager. \"TOKEN\" is empty; EXITING";
  exit 1;
fi

echo -e "\nGot Authorization token from authmanager"

curl -X "GET" \
  -H "Accept: application/json" \
  --cookie "Authorization=$TOKEN" \
  "$IDA_INTERNAL_URL/getAllCertificates?applicationId=IDA&referenceId=SIGN" > ida_sign_result.txt

RESPONSE_COUNT=$( cat ida_sign_result.txt | jq .response.allCertificates )
if [[ -z $RESPONSE_COUNT ]]; then
  echo "Unable to \"response\" read result.txt file; EXITING";
  exit 1;
fi

if [[ $RESPONSE_COUNT == null || -z $RESPONSE_COUNT ]]; then
  echo "No response from keymanager server; EXITING";
  exit 1;
fi

python3 pem-to-jwks.py ./ida_sign_result.txt "$base_path_mosip_certs/ida-sign.json";

if [[ $? -gt 0 ]]; then
  echo "Conversion from pem to jwks failed; EXITING";
  exit 1;
fi

echo -e "\n ******************* IDA sign certificate ************************************** \n $( cat $base_path_mosip_certs/ida-sign.json )"

echo "jwks generation for IDA sign certificates generated successfully";
echo "MOSIP_REGPROC_CLIENT_SECRET=''" >> ~/.bashrc
source ~/.bashrc