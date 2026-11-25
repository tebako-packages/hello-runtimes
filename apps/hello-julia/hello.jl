# hello-julia — the tebako sample app on the julia runtime. Base-only (no
# package deps): the runtime edge is a version RANGE (pure-language law),
# never an ABI line, so one payload rides every compatible julia line. The
# runtime pair is the wrapper pattern (spec 29): the launcher exe composes
# [julia, /app/hello.jl, <user args…>] before the dispatch, and julia's
# own home materializes from the env image's exec-cache annotation.
println("Hello from tebako (julia $(VERSION), $(Sys.KERNEL)/$(Sys.ARCH))")

# The argv echo: each user arg after the entry echoes on its own line —
# the proof that user args survive the wrapper composition (julia's ARGS
# is exactly the script's argument tail).
for arg in ARGS
    println("argv: $arg")
end
