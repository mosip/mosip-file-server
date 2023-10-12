#!/bin/bash

cp /mnt/mosip-file-server/.well-known/mosipvc/*  /home/mosip/mosip-file-server/.well-known/mosipvc/;

/home/mosip/get-cert.sh;

if [[ $? -gt 0 ]]; then
  echo "MOSIP's VC PUBLIC KEY Generation failed; EXITING";
  exit 1;
fi

/home/mosip/get-ida-vc-certs.sh

if [[ $? -gt 0 ]]; then
  echo "IDA's VC PUBLIC KEY Generation failed; EXITING";
  exit 1;
fi

/home/mosip/get-ida-partner-certs.sh;

if [[ $? -gt 0 ]]; then
  echo "Fetch IDA partner certificate failed; EXITING";
  exit 1;
fi

/home/mosip/get-ida-sign-certs.sh;

if [[ $? -gt 0 ]]; then
  echo "jwks generation for IDA sign certificates failed; EXITING";
  exit 1;
fi

echo 'starting nginx'&& nginx;
sleep infinity;