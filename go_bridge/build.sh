#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# build.sh — Cross-compile the JioTV-Go FFI bridge as a C-shared library
#
# Usage:
#   ./build.sh <os> <arch>        Build for a specific target
#   ./build.sh all                Build all Android + Linux targets
#
# Examples:
#   ./build.sh android arm64
#   ./build.sh linux amd64
#   ./build.sh all
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Resolve Android NDK.  Tries ANDROID_NDK_HOME, then common SDK locations.
find_ndk_toolchain() {
    local ndk=""
    if [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
        ndk="$ANDROID_NDK_HOME"
    elif [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME/ndk" ]]; then
        ndk="$(ls -d "$ANDROID_HOME/ndk/"* 2>/dev/null | sort -V | tail -1)"
    elif [[ -d "$HOME/Android/Sdk/ndk" ]]; then
        ndk="$(ls -d "$HOME/Android/Sdk/ndk/"* 2>/dev/null | sort -V | tail -1)"
    fi

    if [[ -z "$ndk" || ! -d "$ndk" ]]; then
        echo "ERROR: Android NDK not found. Set ANDROID_NDK_HOME." >&2
        exit 1
    fi

    local host_tag
    case "$(uname -s)" in
        Linux*)  host_tag="linux-x86_64" ;;
        Darwin*) host_tag="darwin-x86_64" ;;
        *)       echo "ERROR: Unsupported host OS for NDK" >&2; exit 1 ;;
    esac

    echo "$ndk/toolchains/llvm/prebuilt/$host_tag/bin"
}

build_target() {
    local target_os="$1"
    local target_arch="$2"

    export CGO_ENABLED=1

    local out_dir=""
    local out_name="libjiotv_go.so"

    case "$target_os" in
        android)
            local toolchain
            toolchain="$(find_ndk_toolchain)"

            case "$target_arch" in
                arm64)
                    export GOOS=android GOARCH=arm64
                    export CC="$toolchain/aarch64-linux-android21-clang"
                    out_dir="../android/app/src/main/jniLibs/arm64-v8a"
                    ;;
                arm)
                    export GOOS=android GOARCH=arm GOARM=7
                    export CC="$toolchain/armv7a-linux-androideabi21-clang"
                    out_dir="../android/app/src/main/jniLibs/armeabi-v7a"
                    ;;
                x86_64)
                    export GOOS=android GOARCH=amd64
                    export CC="$toolchain/x86_64-linux-android21-clang"
                    out_dir="../android/app/src/main/jniLibs/x86_64"
                    ;;
                *)
                    echo "ERROR: Unsupported Android arch: $target_arch" >&2
                    exit 1
                    ;;
            esac
            ;;
        linux)
            export GOOS=linux
            case "$target_arch" in
                amd64)  export GOARCH=amd64 ;;
                arm64)  export GOARCH=arm64 ;;
                *)      echo "ERROR: Unsupported Linux arch: $target_arch" >&2; exit 1 ;;
            esac
            out_dir="../linux/lib"
            ;;
        darwin)
            export GOOS=darwin
            case "$target_arch" in
                amd64)  export GOARCH=amd64 ;;
                arm64)  export GOARCH=arm64 ;;
                *)      echo "ERROR: Unsupported Darwin arch: $target_arch" >&2; exit 1 ;;
            esac
            out_dir="../macos/lib"
            out_name="libjiotv_go.dylib"
            ;;
        *)
            echo "ERROR: Unsupported OS: $target_os" >&2
            exit 1
            ;;
    esac

    mkdir -p "$out_dir"

    echo "→ Building $target_os/$target_arch ..."
    go build -buildmode=c-shared \
        -trimpath \
        -ldflags="-s -w" \
        -o "$out_dir/$out_name" \
        .

    # Remove the auto-generated C header (we don't need it at runtime).
    rm -f "$out_dir/"*.h

    echo "  ✓ $out_dir/$out_name"
}

build_all() {
    build_target android arm64
    build_target android arm
    build_target linux amd64
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if [[ "${1:-}" == "all" ]]; then
    build_all
elif [[ $# -ge 2 ]]; then
    build_target "$1" "$2"
else
    echo "Usage: $0 <os> <arch>  OR  $0 all"
    echo "  os:   android | linux | darwin"
    echo "  arch: arm64 | arm | amd64 | x86_64"
    exit 1
fi
