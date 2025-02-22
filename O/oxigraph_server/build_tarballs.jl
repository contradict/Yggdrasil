# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph_server"
version = v"0.3.19"

url_prefix = "https://github.com/oxigraph/oxigraph/releases/download/v$version/oxigraph_server_v$version"

# Collection of sources required to complete build
sources = [
    FileSource("$(url_prefix)_aarch64_apple", "a53629afdbd5e34e0024abcc42ed559bd2d4d8456ad1851a5098b1a7bc10c66b"; filename = "oxigraph_server-aarch64-apple-darwin20"),
    FileSource("$(url_prefix)_x86_64_apple", "6d3cdb5c06746bb09cff3ba892e00ecfb5faaf6ac98c0e35bd06d04ee305a1b3"; filename = "oxigraph_server-x86_64-apple-darwin14"),
    FileSource("$(url_prefix)_aarch64_linux_gnu", "3ebc68013762b8377a2caadc2846aafcaa15830bec0e2368c091a5d99551552b"; filename = "oxigraph_server-aarch64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_linux_gnu", "e93d4a8640f8356acddc6bd8a039b7decbca3852d4c310c396552a8d50ebe05a"; filename = "oxigraph_server-x86_64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_windows_msvc.exe", "ea65b7e283593937e7d932f077e35f865ce408e9a19ee798dd26a745e0cd600f"; filename = "oxigraph_server-x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/oxigraph/oxigraph/v$version/LICENSE-MIT", "1f4f6736adc52ebfda18bb84947e0ef492bd86a408c0e83872efb75ed5e02838"; filename = "LICENSE.txt")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install -Dvm 755 "oxigraph_server-${target}" "${bindir}/oxigraph_server${exeext}"
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> (arch(p) == "powerpc64le" || Sys.isfreebsd(p) || (Sys.islinux(p) && libc(p) == "musl") || nbits(p) != 64))
platforms = expand_cxxstring_abis(platforms)

# Binaries are built upstream using GCC v9+, skip CXX03 string ABI
platforms = filter(x -> cxxstring_abi(x) != "cxx03", platforms)

# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("oxigraph_server", :oxigraph_server),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
