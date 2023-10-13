#!/usr/bin/env bash

#get date
date=$(date --utc +%FT%T.%3NZ)

rm -rf ida_temp.txt ida_result.txt ida_pubkey.pem ida_cert.pem

echo -e "\n GET IDA PUBLIC PARTNER CERTIFICATE \n";
echo "AUTHMANAGER URL : $AUTHMANAGER_URL"
echo "IDA INTERNALURL URL : $IDA_INTERNAL_URL"

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
}' > ida_temp.txt 2>&1 &

sleep 10
#TOKEN=$(cat -n temp.txt | sed -n '/Authorization:/,/\;.*/pI' |  sed 's/.*Authorization://i; s/$\n.*//I' | awk 'NR==1{print $1}')
#TOKEN=$(cat -n temp.txt | grep -i Authorization: |  sed 's/.*Authorization://i; s/$\n.*//' | awk 'NR==1{print $1}')
TOKEN=$( cat ida_temp.txt | awk '/[aA]uthorization:/{print $2}' | sed -z 's/\n//g' | sed -z 's/\r//g')

if [[ -z $TOKEN ]]; then
  echo "Unable to Authenticate with authmanager. \"TOKEN\" is empty; EXITING";
  exit 1;
fi

echo -e "\nGot Authorization token from authmanager"

curl -X "GET" \
  -H "Accept: application/json" \
  --cookie "Authorization=$TOKEN" \
  "$IDA_INTERNAL_URL/getCertificate?applicationId=IDA&referenceId=PARTNER" > ida_result.txt

RESPONSE_COUNT=$( cat ida_result.txt | jq .response )
if [[ -z $RESPONSE_COUNT ]]; then
  echo "Unable to \"response\" read result.txt file; EXITING";
  exit 1;
fi

if [[ $RESPONSE_COUNT == null || -z $RESPONSE_COUNT ]]; then
  echo "No response from keymanager server; EXITING";
  exit 1;
fi

RESULT=$(cat ida_result.txt)
CERT=$(echo $RESULT | sed 's/.*certificate\":\"//gi' | sed 's/\".*//gI')

if [[ -z $CERT ]]; then
  echo "Unable to read certificate from ida_result.txt; EXITING";
  exit 1;
fi

echo "$CERT" | sed -e 's/\\n/\n/g' > "$base_path_mosip_certs/ida-partner.cer";

echo -e "\n ******************* IDA certificate ************************************** \n $( cat $base_path_mosip_certs/ida-partner.cer )"

echo "IDA partner certificate downloaded successfully";
echo "MOSIP_REGPROC_CLIENT_SECRET=''" >> ~/.bashrc
source ~/.bashrc