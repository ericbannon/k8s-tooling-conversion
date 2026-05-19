Validation that the Chainguard JDK FIPS image routes standard JVM crypto operations through the Bouncy Castle FIPS provider. MD5 is still available from BCFIPS for compatibility/non-security checksum use cases such as S3 Content-MD5, while approved cryptographic operations like SHA-256 and AES/GCM also resolve through BCFIPS. This means applications using normal JVM crypto APIs generally do not need code changes unless they explicitly pin a non-FIPS provider or rely on non-approved algorithms for security-sensitive use.

```
docker run --rm -v "$PWD":/work -w /work \
  cgr.dev/YOUR-ORG/jdk-fips:latest \
  sh -c 'javac FipsCryptoCheck.java && java FipsCryptoCheck'
```

**Expected Output**

```
╰─⠠⠵ docker run --rm -v "$PWD":/work -w /work \
  cgr.dev/chainguard-private/jdk-fips:latest \
  sh -c 'javac FipsCryptoCheck.java && java FipsCryptoCheck'
Security providers:
  BCFIPS - BouncyCastle Security Provider (FIPS edition) v2.1.1
  BCJSSE - Bouncy Castle JSSE Provider Version 2.1.22
  BCRNG - Bouncy Castle JENT Entropy Provider v1.3.6 [arm64_linux 7 successfully loaded]
  SunJGSS - Sun (Kerberos v5, SPNEGO)
  SunSASL - Sun SASL provider(implements client mechanisms for: DIGEST-MD5, EXTERNAL, PLAIN, CRAM-MD5, NTLM; server mechanisms for: DIGEST-MD5, CRAM-MD5, NTLM)
  XMLDSig - XMLDSig (DOM XMLSignatureFactory; DOM KeyInfoFactory; C14N 1.0, C14N 1.1, Exclusive C14N, Base64, Enveloped, XPath, XPath2, XSLT TransformServices)
  SunPCSC - Sun PC/SC provider
  JdkLDAP - JdkLDAP Provider (implements LDAP CertStore)
  JdkSASL - JDK SASL provider(implements client and server mechanisms for GSSAPI)

MD5 provider: BCFIPS
S3 Content-MD5: KL19Y2UUx1fDa0kMnfPXuQ==

SHA-256 provider: BCFIPS
SHA-256: kB6lYVgjaU0UvS9n/lZ8mGrhi+Bp4BO/YL7esquWwxk=

AES/GCM provider: BCFIPS
```
