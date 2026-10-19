#!/usr/bin/env bun
// hello-bun — the tebako sample app on the bun runtime. THE headline: bun
// transpiles TypeScript in-process, so the .ts entry needs no compile
// step — no press-compile, no hosted tsc (contrast the java arm's jar).
// Single file, zero dependencies; the spec-17 driver mounts the payload
// at / and composes [bun, /app/cli.ts, <user args…>].
console.log(`Hello from tebako (bun ${Bun.version}, ${process.platform}/${process.arch})`);

// The argv echo, typed: bun runs this TypeScript directly — the
// annotations cost nothing at run time.
const echo = (args: readonly string[]): void => {
  for (const arg of args) console.log(`argv: ${arg}`);
};
echo(process.argv.slice(2));
