// hello-dotnet — the tebako sample app on the dotnet runtime (the .NET
// SDK pair). Like the java arm, the payload ships the COMPILED form of
// the app's own source (audience law 3: a runnable-payload developer
// compiles only their own code — here with the runner's hosted .NET SDK,
// never anything tebako-side): a framework-dependent hello.dll riding
// the runtime's shared framework. The spec-17 driver mounts the payload
// at / and composes [dotnet, /app/hello.dll, <user args…>].
using System.Runtime.InteropServices;

Console.WriteLine($"Hello from tebako (dotnet {Environment.Version}, {RuntimeInformation.OSDescription}/{RuntimeInformation.OSArchitecture})");

// The argv echo: each user arg after the entry echoes on its own line —
// the proof that user args survive the wrapper composition.
foreach (var arg in args)
{
    Console.WriteLine($"argv: {arg}");
}
