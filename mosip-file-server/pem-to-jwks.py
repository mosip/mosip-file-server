from jwcrypto import jwk
import json
import cryptography
import sys

if __name__ == "__main__":
    
    arg_len = len(sys.argv)
    print(f"Arguments count: {arg_len}")
    if arg_len < 2:
        print ('both input and output files required.')
        sys.exit()

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    PEM_BEGIN_MARKER = "-----BEGIN CERTIFICATE-----"
    PEM_END_MARKER = "-----END CERTIFICATE-----"
    print ('Started Conversion..')
    with open(input_file) as f:
        json_data = f.read()

    resp_json_obj = json.loads(json_data)
    cert_data_arr = resp_json_obj['response']['allCertificates']
    jwk_list = []
    for cert_data in cert_data_arr:
        cert_data_encode = cert_data['certificateData'].encode()
        key_obj = jwk.JWK.from_pem(cert_data_encode)

        jwk_dict = json.loads(key_obj.export())
        jwk_dict['kid'] = cert_data['keyId']
        jwk_dict['exp'] = cert_data['expiryAt']
        jwk_dict['x5t#256'] = key_obj.thumbprint(hashalg=cryptography.hazmat.primitives.hashes.SHA256())

        cert_data_str = cert_data['certificateData']
        begin_ind = cert_data_str.index(PEM_BEGIN_MARKER)
        cert_data_substr = cert_data_str[begin_ind + len(PEM_BEGIN_MARKER):]
        end_ind = cert_data_substr.index(PEM_END_MARKER)
        cert_data_substr2 = cert_data_substr[0:end_ind]
        jwk_dict['x5c'] = str(cert_data_substr2).replace('\n', '')
        jwk_dict['use'] = 'sig'

        jwk_list.append(jwk_dict)

    final_json = json.loads(str(jwk_list).replace('\'', '"'))
    with open(output_file, 'w+') as f:
        f.write(json.dumps(final_json, indent=4))
        f.flush()

    print ('Conversion Completed!!')
