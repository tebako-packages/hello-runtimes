/**
 * hello-java — the tebako sample app on the openjdk runtime.
 * Single-file source-code launch (java 11+): the driver runs
 * `java /app/Hello.java <args>` — no compilation step anywhere.
 */
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello from tebako (java "
            + System.getProperty("java.version") + ", "
            + System.getProperty("os.name") + "/"
            + System.getProperty("os.arch") + ")");
    }
}
