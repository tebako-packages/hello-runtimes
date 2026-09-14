/**
 * hello-java — the tebako sample app on the openjdk runtime.
 * tools/build compiles this to /app/hello.jar (Main-Class: Hello); the
 * driver composes `java -jar /app/hello.jar <args>` (spec 29 §1). The
 * openjdk runtime is a JRE — no jdk.compiler module — so single-file
 * source launch is not the payload form.
 */
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello from tebako (java "
            + System.getProperty("java.version") + ", "
            + System.getProperty("os.name") + "/"
            + System.getProperty("os.arch") + ")");
    }
}
