Validation that the Chainguard JDK FIPS image routes standard JVM crypto operations through the Bouncy Castle FIPS provider. MD5 is still available from BCFIPS for compatibility/non-security checksum use cases such as S3 Content-MD5, while approved cryptographic operations like SHA-256 and AES/GCM also resolve through BCFIPS. This means applications using normal JVM crypto APIs generally do not need code changes unless they explicitly pin a non-FIPS provider or rely on non-approved algorithms for security-sensitive use.

```
docker run --rm -v "$PWD":/work -w /work \

  cgr.dev/YOUR-ORG/jdk-fips:latest \

  sh -c 'javac FipsCryptoCheck.java && java FipsCryptoCheck'
```
