import java.security.*;
import java.util.Base64;

public class FipsCryptoCheck {
  public static void main(String[] args) throws Exception {
    System.out.println("Security providers:");
    for (Provider p : Security.getProviders()) {
      System.out.println("  " + p.getName() + " - " + p.getInfo());
    }

    byte[] payload = "hello-s3".getBytes();

    MessageDigest md5 = MessageDigest.getInstance("MD5");
    System.out.println("\nMD5 provider: " + md5.getProvider().getName());
    System.out.println("S3 Content-MD5: " +
      Base64.getEncoder().encodeToString(md5.digest(payload)));

    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    System.out.println("\nSHA-256 provider: " + sha256.getProvider().getName());
    System.out.println("SHA-256: " +
      Base64.getEncoder().encodeToString(sha256.digest(payload)));

    CipherCheck.run();
  }
}

class CipherCheck {
  static void run() throws Exception {
    javax.crypto.Cipher cipher =
      javax.crypto.Cipher.getInstance("AES/GCM/NoPadding");

    System.out.println("\nAES/GCM provider: " +
      cipher.getProvider().getName());
  }
}
