import java.security.*;
import java.util.Base64;

public class FipsCryptoCheck {

  public static void main(String[] args) throws Exception {

    System.out.println("Security providers:");
    for (Provider p : Security.getProviders()) {
      System.out.println("  " + p.getName() + " - " + p.getInfo());
    }

    byte[] payload = "hello-s3".getBytes();

    //
    // MD5 checksum operation (allowed for compatibility use cases like S3)
    //
    MessageDigest md5 = MessageDigest.getInstance("MD5");

    System.out.println("\nMD5 provider: " +
      md5.getProvider().getName());

    System.out.println("S3 Content-MD5: " +
      Base64.getEncoder().encodeToString(md5.digest(payload)));

    //
    // SHA-256 security digest
    //
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");

    System.out.println("\nSHA-256 provider: " +
      sha256.getProvider().getName());

    System.out.println("SHA-256: " +
      Base64.getEncoder().encodeToString(sha256.digest(payload)));

    //
    // AES/GCM crypto operation
    //
    javax.crypto.Cipher cipher =
      javax.crypto.Cipher.getInstance("AES/GCM/NoPadding");

    System.out.println("\nAES/GCM provider: " +
      cipher.getProvider().getName());

    //
    // MD5 security operation should fail
    //
    md5SecurityOperationShouldFail();
  }

  static void md5SecurityOperationShouldFail() {

    System.out.println("\nMD5 security operation test:");

    try {
      Signature sig = Signature.getInstance("MD5withRSA");

      System.out.println("UNEXPECTED: MD5withRSA provider: " +
        sig.getProvider().getName());

    } catch (Exception e) {

      System.out.println(
        "EXPECTED BLOCK: MD5withRSA is not available");

      System.out.println(
        "Actual exception output:");

      e.printStackTrace(System.out);
    }
  }
}
