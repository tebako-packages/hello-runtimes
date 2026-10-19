#!/usr/bin/env node
// hello-node — the tebako sample app on the node runtime (node 24 LTS via
// the tebako node runtime pair). Single file, zero dependencies, copied
// verbatim: the spec-17 driver mounts the payload at / and composes
// [node, /app/cli.js, <user args…>] before the dispatch. The shebang
// keeps the entry spawnable as a program (the launcher runs the entry
// directly; the ruby arm's `#!/usr/bin/env ruby` is the same mechanism).
console.log(`Hello from tebako (node ${process.version}, ${process.platform}/${process.arch})`);

// The argv echo: each user arg after the entry echoes on its own line —
// the proof that user args survive the wrapper composition.
for (const arg of process.argv.slice(2)) {
  console.log(`argv: ${arg}`);
}
