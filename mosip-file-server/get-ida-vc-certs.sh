#!/usr/bin/env bash

#get date
date=$(date --utc +%FT%T.%3NZ)

rm -rf temp.txt result.txt pubkey.pem cert.pem

echo -e "\n Generate IDA's VC PUBLIC KEY CERTIFICATE \n";
echo "AUTHMANAGER URL : $AUTHMANAGER_URL"
echo "IDA INTERNAL URL : $IDA_INTERNAL_URL"

echo "* Request for authorization"
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
}' > temp.txt 2>&1 &

sleep 10

TOKEN=$( cat temp.txt | awk '/[aA]uthorization:/{print $2}' | sed -z 's/\n//g' | sed -z 's/\r//g')

if [[ -z $TOKEN ]]; then
  echo "Unable to Authenticate with authmanager. \"TOKEN\" is empty; EXITING";
  exit 1;
fi

echo -e "\nGot Authorization token from authmanager"

curl -X "GET" \
  -H "Accept: application/json" \
  --cookie "Authorization=$TOKEN" \
  "$IDA_INTERNAL_URL/getCertificate?applicationId=IDA_VCI_EXCHANGE&referenceId=" > result.txt

RESPONSE_COUNT=$( cat result.txt | jq .response )
if [[ -z $RESPONSE_COUNT ]]; then
  echo "Unable to \"response\" read result.txt file; EXITING";
  exit 1;
fi

if [[ $RESPONSE_COUNT == null || -z $RESPONSE_COUNT ]]; then
  echo "No response from IDA internal server; EXITING";
  exit 1;
fi

RESULT=$(cat result.txt)
CERT=$(echo $RESULT | sed 's/.*certificate\":\"//gi' | sed 's/\".*//gI')

if [[ -z $CERT ]]; then
  echo "Unable to read certificate from result.txt; EXITING";
  exit 1;
fi

echo $CERT | sed -e 's/\\n/\n/g' > cert.pem
openssl x509 -pubkey -noout -in cert.pem  > pubkey.pem
echo -e "\n ******************* Signed certificate ************************************** \n $( cat pubkey.pem )"
sed -i "s&replace-public-key&$(cat pubkey.pem | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\\\r\\\\n/g')&g" $base_path_mosipvc/ida-public-key.json

echo "public key creation complete"

for file in ida-controller.json mosip-ida-context.json; do
  curl $spring_config_url_env/*/$active_profile_env/$spring_config_label_env/$file > $base_path_mosipvc/$file;
  if ! [[ -s $base_path_mosipvc/$file ]]; then
    echo "Unable to download \"$base_path_mosipvc/$file\" file from config-server;";
    echo "FILE \"$base_path_mosipvc/$file\" is empty; EXITING";
    exit 1;
  fi
  echo "Downloaded $file from config-server to $base_path_mosipvc/$file !!!";
done


exec "$@"