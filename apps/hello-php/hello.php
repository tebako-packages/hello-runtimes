#!/usr/bin/env php
<?php
// hello-php — the tebako sample app on the php runtime. Core-only (no
// extension beyond json, which is always compiled in since php 8.0): the
// runtime edge is a version RANGE (pure-language law), never an ABI line,
// so one payload rides every compatible php line. The spec-17 driver
// mounts the payload at / and composes [php, /app/hello.php,
// <user args…>] (spec 29 §1: the interpreter at index 0, args_default
// between it and the entry). The shebang keeps the entry spawnable as a
// program (the CLI SAPI strips it; the ruby/node arms' idiom).
echo "Hello from tebako (php " . PHP_VERSION . ", " . PHP_OS_FAMILY . "/" . php_uname("m") . ")\n";

// The argv echo: each user arg after the entry echoes on its own line —
// the proof that user args survive the composition ($argv[0] is the
// entry itself).
foreach (array_slice($argv, 1) as $arg) {
    echo "argv: $arg\n";
}

// The extension surface boots: json is a core extension (always present —
// the composer-class payload's floor). A payload needing ext-ffi/ext-gd
// class extensions declares the ABI line instead (spec 05 §5 — the
// xml2rfc feedstock's shape).
echo "ext json: " . json_encode(["probe" => "ok"]) . "\n";
