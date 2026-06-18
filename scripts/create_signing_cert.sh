#!/bin/bash
set -e

# Creates a stable, self-signed code-signing certificate in the login keychain.
# Signing every AlfredMini build with the same cert keeps the macOS Accessibility
# permission across rebuilds, so it only has to be granted once. Run this once
# per machine; build_dmg.sh then signs with it automatically.

SIGN_ID="AlfredMini Local Signing"

if security find-identity -p codesigning | grep -q "${SIGN_ID}"; then
  echo "✅ Signing identity '${SIGN_ID}' already exists. Nothing to do."
  exit 0
fi

echo "🔐 Creating self-signed code-signing certificate '${SIGN_ID}'..."
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

cat > "${WORK}/cert.cnf" <<'EOF'
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = AlfredMini Local Signing
[v3]
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
basicConstraints = critical, CA:false
EOF

openssl req -x509 -newkey rsa:2048 -keyout "${WORK}/key.pem" -out "${WORK}/cert.pem" \
  -days 3650 -nodes -config "${WORK}/cert.cnf" >/dev/null 2>&1

# -legacy: macOS `security` can't verify OpenSSL 3's default PKCS12 MAC.
openssl pkcs12 -export -legacy -inkey "${WORK}/key.pem" -in "${WORK}/cert.pem" \
  -out "${WORK}/cert.p12" -passout pass:alfred -name "${SIGN_ID}" >/dev/null 2>&1

# -A: let codesign use the private key without a keychain password prompt.
security import "${WORK}/cert.p12" -k ~/Library/Keychains/login.keychain-db -P "alfred" -A

echo "✅ Created. Codesigning identity:"
security find-identity -p codesigning | grep "${SIGN_ID}"
