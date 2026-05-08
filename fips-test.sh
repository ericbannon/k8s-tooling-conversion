#!/usr/bin/env bash
set -euo pipefail

echo "=== Image-local FIPS Validation Checks ==="

fail=0

pass() { echo "PASS: $1"; }
failf() { echo "FAIL: $1"; fail=1; }
skip() { echo "SKIP: $1"; }

echo
echo "--- Go FIPS binary checks ---"

check_gofips() {
  local bin="$1"

  if command -v "$bin" >/dev/null 2>&1; then
    local path
    path="$(command -v "$bin")"

    if strings "$path" 2>/dev/null | grep -q "GOFIPS140"; then
      pass "$bin contains GOFIPS140 marker"
    elif strings "$path" 2>/dev/null | grep -qi "boringcrypto\|boring"; then
      pass "$bin contains BoringCrypto marker"
    else
      echo "INFO: $bin does not expose GOFIPS140/BoringCrypto marker via strings"
    fi
  else
    failf "$bin missing"
  fi
}

check_gofips vault
check_gofips terraform
check_gofips terragrunt
check_gofips kubectl
check_gofips helm
check_gofips argocd
check_gofips aws

echo
echo "--- Runtime command checks ---"

vault version || failf "vault failed"
aws --version || failf "aws failed"
terraform version || failf "terraform failed"
terragrunt --version || failf "terragrunt failed"
kubectl version --client=true || failf "kubectl failed"
helm version --short || failf "helm failed"
argocd version --client || failf "argocd failed"

echo
echo "--- OpenSSL FIPS provider details ---"

if command -v openssl >/dev/null 2>&1; then
  openssl version -a || true

  echo
  echo "OpenSSL providers:"
  openssl list -providers -verbose || true

  if openssl list -providers 2>/dev/null | grep -qi fips; then
    pass "OpenSSL FIPS provider is available in image"
  else
    failf "OpenSSL FIPS provider not detected"
  fi
else
  failf "openssl not installed"
fi

echo
echo "--- Go FIPS build marker checks ---"

check_go_fips_markers() {
  local bin="$1"

  if [ -f "$bin" ]; then
    echo
    echo "Inspecting Go FIPS markers: $bin"

    if strings "$bin" 2>/dev/null | grep -Eiq \
      'GOFIPS140|GODEBUG=fips140|fips140=on|boringcrypto|BoringCrypto|goexperiment\.boringcrypto|GOEXPERIMENT=boringcrypto'
    then
      pass "$(basename "$bin") exposes Go FIPS/BoringCrypto marker"
    else
      echo "INFO: $(basename "$bin") does not expose readable Go FIPS/BoringCrypto markers"
    fi
  fi
}

check_go_fips_markers /usr/local/bin/op
check_go_fips_markers /usr/local/bin/credhub
check_go_fips_markers /usr/local/bin/pack

echo
echo "--- OpenSSL FIPS self-test / CMVP details ---"

if command -v openssl-fips-test >/dev/null 2>&1; then
  fips_test_output="/tmp/openssl-fips-test.out"

  if openssl-fips-test | tee "${fips_test_output}"; then
    pass "openssl-fips-test completed"
  else
    failf "openssl-fips-test failed"
  fi

  echo
  echo "Extracted CMVP/FIPS details:"
  awk '
    /Public OpenSSL API/ { print; show=1; next }
    /FIPS cryptographic module provider details/ { print; show=1; next }
    /Locate applicable certificate/ { print; show=1; next }
    /Lifecycle assurance satisfied/ { print; show=1; next }
    /self-tests passed/ { print; show=1; next }
    /approved only mode/ { print; show=1; next }
    /non-approved algorithm blocked/ { print; show=1; next }
    show && /^[[:space:]]*(name|version|build):/ { print; next }
  ' "${fips_test_output}" || true
else
  failf "openssl-fips-test not installed"
fi

echo
echo "--- TLS checks using OpenSSL ---"

if command -v openssl >/dev/null 2>&1; then
  echo | openssl s_client \
    -connect google.com:443 \
    -servername google.com \
    -tls1_2 \
    -brief >/tmp/tls12.out 2>&1 \
    && pass "TLS 1.2 handshake works" \
    || { cat /tmp/tls12.out; failf "TLS 1.2 handshake failed"; }

  echo | openssl s_client \
    -connect google.com:443 \
    -servername google.com \
    -tls1_3 \
    -brief >/tmp/tls13.out 2>&1 \
    && pass "TLS 1.3 handshake works" \
    || { cat /tmp/tls13.out; failf "TLS 1.3 handshake failed"; }
else
  skip "TLS checks skipped because openssl is missing"
fi

echo
echo "--- TLS block checks using OpenSSL ---"

if command -v openssl >/dev/null 2>&1; then
  if echo | openssl s_client \
    -connect google.com:443 \
    -servername google.com \
    -tls1_1 \
    -brief >/tmp/tls11-block.out 2>&1; then

    cat /tmp/tls11-block.out
    failf "TLS 1.1 handshake unexpectedly succeeded"
  else
    echo "TLS 1.1 block output:"
    cat /tmp/tls11-block.out
    pass "TLS 1.1 handshake is blocked or unsupported"
  fi
else
  failf "openssl not installed"
fi

echo
echo "--- Crypto operation checks ---"

echo "test" | sha256sum >/dev/null
pass "SHA256 operation works"

echo "test" | sha512sum >/dev/null
pass "SHA512 operation works"

if command -v openssl >/dev/null 2>&1; then
  echo "test" | openssl dgst -sha256 >/dev/null
  pass "OpenSSL SHA256 digest works"

  echo "test" | openssl dgst -sha512 >/dev/null
  pass "OpenSSL SHA512 digest works"
fi

echo
echo "--- Non-approved crypto block checks ---"

if command -v openssl >/dev/null 2>&1; then
  if echo "test" | openssl dgst -md5 -propquery 'fips=yes' >/tmp/md5-block.out 2>&1; then
    cat /tmp/md5-block.out
    failf "MD5 was allowed with fips=yes"
  else
    echo "MD5 block output:"
    cat /tmp/md5-block.out
    pass "MD5 is blocked for fips=yes"
  fi
else
  failf "openssl not installed"
fi

echo
echo "--- Image FIPS environment indicators ---"

env | grep -E 'GOFIPS|GODEBUG|OPENSSL|FIPS' || true

echo
echo "=== Image-local FIPS Validation Summary ==="

if [ "$fail" -ne 0 ]; then
  echo "FAIL: One or more image-local FIPS checks failed"
  exit 1
fi

echo "PASS: Image-local FIPS checks completed"