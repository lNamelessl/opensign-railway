#!/usr/bin/env bash
# Generates the shared self-signed signing certificate shipped with this template.
# Reproduces cert/opensign-default.p12.b64 (PFX_BASE64 default, passphrase: opensign).
# Regenerate at any time; users can also upload their own PFX per organization
# inside OpenSign (Organisation settings) for production use.
set -euo pipefail

openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 3650 -nodes \
  -subj "//CN=OpenSign\O=OpenSign SelfHosted"
openssl pkcs12 -export -in cert.pem -inkey key.pem -out opensign-default.p12 \
  -passout pass:opensign
base64 -w0 opensign-default.p12 > opensign-default.p12.b64
rm -f key.pem cert.pem
echo "Wrote opensign-default.p12.b64"
