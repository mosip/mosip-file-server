#!/usr/bin/env bash

#get date
date=$(date --utc +%FT%T.%3NZ)

rm -rf ida_fir_temp.txt ida_fir_result.txt ida_pubkey.pem ida_cert.pem

echo -e "\n Generating JWKS for IDA-FIR certificates\n";
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
}' > ida_fir_temp.txt 2>&1 &

sleep 10
#TOKEN=$(cat -n temp.txt | sed -n '/Authorization:/,/\;.*/pI' |  sed 's/.*Authorization://i; s/$\n.*//I' | awk 'NR==1{print $1}')
#TOKEN=$(cat -n temp.txt | grep -i Authorization: |  sed 's/.*Authorization://i; s/$\n.*//' | awk 'NR==1{print $1}')
TOKEN=$( cat ida_fir_temp.txt | awk '/[aA]uthorization:/{print $2}' | sed -z 's/\n//g' | sed -z 's/\r//g')

if [[ -z $TOKEN ]]; then
  echo "Unable to authenticate with Authmanager. \"TOKEN\" is empty; EXITING";
  exit 1;
fi

echo -e "\nGot authorization token from Authmanager"

curl -X "GET" \
  -H "Accept: application/json" \
  --cookie "Authorization=$TOKEN" \
  "$IDA_INTERNAL_URL/getAllCertificates?applicationId=IDA&referenceId=IDA-FIR" > ida_fir_result.txt

RESPONSE_COUNT=$( cat ida_fir_result.txt | jq .response.allCertificates )
if [[ -z $RESPONSE_COUNT ]]; then
  echo "Unable to read result.txt file; EXITING";
  exit 1;
fi

if [[ $RESPONSE_COUNT == null || -z $RESPONSE_COUNT ]]; then
  echo "No response from Keymanager server; EXITING";
  exit 1;
fi

python3 pem-to-jwks.py ./ida_fir_result.txt "$base_path_mosip_certs/ida-fir.json";

if [[ $? -gt 0 ]]; then
  echo "Conversion from pem to JWKS failed; EXITING";
  exit 1;
fi

echo -e "\n ******************* IDA-FIR certificate ************************************** \n $( cat $base_path_mosip_certs/ida-fir.json )"

echo "jwks generation for IDA-FIR certificates generated successfully";
echo "MOSIP_REGPROC_CLIENT_SECRET=''" >> ~/.bashrc
source ~/.bashrc
