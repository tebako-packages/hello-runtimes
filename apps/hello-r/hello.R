# hello-r — the tebako sample app on the r runtime. Base-only (no package
# deps): the runtime edge is a version RANGE (pure-language law), never an
# ABI line, so one payload rides every compatible r line. The runtime
# exe's front-end is Rscript-shaped (the factory's fs TU carries the
# Rscript translation — upstream's Rscript shell launcher cannot work
# inside the VFS): the spec-17 driver's --tebako-entry /app/hello.R
# becomes --file=, and trailing user args arrive via commandArgs(TRUE).
cat("Hello from tebako (r ", as.character(getRversion()), ", ", R.version$platform, ")\n", sep = "")

# The argv echo: each user arg after the entry echoes on its own line —
# the proof that user args survive the Rscript front-end's routing.
for (arg in commandArgs(TRUE)) {
  cat("argv: ", arg, "\n")
}
