#!/usr/bin/env bash
# fetch-fyy-binary.sh — Download or build fyy CLI binary
#
# Usage:
#   Release mode (default):
#     ./scripts/fetch-fyy-binary.sh --version v1.0.0 --arch amd64 --output ./fyy
#
#   Dev mode (from local fyy-src):
#     ./scripts/fetch-fyy-binary.sh --mode dev --source /path/to/fyy-src --arch arm64 --output ./fyy
#
#   Custom URL:
#     ./scripts/fetch-fyy-binary.sh --version v1.0.0 --arch amd64 --output ./fyy --url https://example.com/fyy

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
MODE="release"
VERSION=""
ARCH=""
OUTPUT=""
SOURCE=""
URL=""
FYY_REPO="feiyueyun/fyy"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
usage() {
    cat <<'EOF'
Usage: fetch-fyy-binary.sh [options]

Required:
  --arch <amd64|arm64>    Target architecture
  --output <path>         Output file path

Optional:
  --version <version>     fyy CLI version (required for release mode, e.g. v1.0.0)
  --mode <release|dev>    Fetch mode (default: release)
  --source <path>         fyy-src repo path (required for dev mode)
  --url <url>             Custom download URL (overrides default GitHub Releases URL)
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --arch)    ARCH="$2";    shift 2 ;;
        --output)  OUTPUT="$2";  shift 2 ;;
        --mode)    MODE="$2";    shift 2 ;;
        --source)  SOURCE="$2";  shift 2 ;;
        --url)     URL="$2";     shift 2 ;;
        -h|--help) usage ;;
        *) echo "ERROR: Unknown argument: $1" >&2; usage ;;
    esac
done

# Validate required args
if [[ -z "$ARCH" ]]; then
    echo "ERROR: --arch is required" >&2
    usage
fi
if [[ -z "$OUTPUT" ]]; then
    echo "ERROR: --output is required" >&2
    usage
fi
if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo "ERROR: --arch must be amd64 or arm64, got: $ARCH" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Release mode: download from GitHub Releases
# ---------------------------------------------------------------------------
fetch_release() {
    if [[ -z "$VERSION" ]]; then
        echo "ERROR: --version is required for release mode" >&2
        usage
    fi

    # Construct download URL
    local binary_name="fyy-linux-${ARCH}"
    if [[ -n "$URL" ]]; then
        DOWNLOAD_URL="$URL"
    else
        DOWNLOAD_URL="https://github.com/${FYY_REPO}/releases/download/${VERSION}/${binary_name}"
    fi

    local sha256_url="${DOWNLOAD_URL}.sha256"

    echo "==> Fetching fyy CLI ${VERSION} for linux/${ARCH}..."
    echo "    Download URL: ${DOWNLOAD_URL}"
    echo "    SHA256 URL:   ${sha256_url}"

    # Download binary
    local http_code
    http_code=$(curl -fsSL -w '%{http_code}' -o "$OUTPUT" "$DOWNLOAD_URL" 2>/dev/null) || {
        echo "ERROR: Failed to download fyy binary from ${DOWNLOAD_URL}" >&2
        echo "       HTTP status: ${http_code:-unknown}" >&2
        echo "       Please check the version and try again." >&2
        exit 1
    }

    # Download SHA256 checksum file
    local sha256_file="${OUTPUT}.sha256"
    curl -fsSL -o "$sha256_file" "$sha256_url" 2>/dev/null || {
        echo "WARNING: Could not download SHA256 checksum file from ${sha256_url}" >&2
        echo "         Skipping checksum verification." >&2
        chmod +x "$OUTPUT"
        echo "==> Done (no checksum verification)."
        return
    }

    # Verify SHA256 checksum
    verify_sha256 "$OUTPUT" "$sha256_file"

    chmod +x "$OUTPUT"
    rm -f "$sha256_file"
    echo "==> Done."
}

# ---------------------------------------------------------------------------
# Dev mode: copy or build from local fyy-src
# ---------------------------------------------------------------------------
fetch_dev() {
    if [[ -z "$SOURCE" ]]; then
        echo "ERROR: --source is required for dev mode" >&2
        usage
    fi
    if [[ ! -d "$SOURCE" ]]; then
        echo "ERROR: Source directory does not exist: ${SOURCE}" >&2
        exit 1
    fi

    echo "==> Fetching fyy CLI from local source: ${SOURCE}"

    # Check for pre-built binary matching the target arch
    local host_arch
    host_arch=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')

    if [[ "$ARCH" == "$host_arch" && -f "${SOURCE}/bin/fyy" ]]; then
        echo "    Copying pre-built binary: ${SOURCE}/bin/fyy"
        cp "${SOURCE}/bin/fyy" "$OUTPUT"
        chmod +x "$OUTPUT"
        echo "==> Done."
        return
    fi

    # Cross-compile from source
    if [[ ! -f "${SOURCE}/Makefile" ]]; then
        echo "ERROR: No Makefile found in ${SOURCE}. Cannot compile." >&2
        exit 1
    fi

    echo "    Cross-compiling for linux/${ARCH}..."
    local go_os="linux"
    local go_arch="$ARCH"

    if ! (cd "$SOURCE" && GOOS="$go_os" GOARCH="$go_arch" go build -o "$OUTPUT" ./cmd/fyy/); then
        echo "ERROR: Cross-compilation failed for GOOS=${go_os} GOARCH=${go_arch}" >&2
        echo "       Check the Go toolchain and source code." >&2
        exit 1
    fi

    chmod +x "$OUTPUT"
    echo "==> Done."
}

# ---------------------------------------------------------------------------
# SHA256 verification
# ---------------------------------------------------------------------------
verify_sha256() {
    local binary="$1"
    local sha256_file="$2"

    # Read expected hash from file (first field, to handle "hash  filename" format)
    local expected_hash
    expected_hash=$(awk '{print $1}' "$sha256_file" 2>/dev/null) || {
        echo "ERROR: Could not read SHA256 checksum file: ${sha256_file}" >&2
        exit 1
    }

    if [[ -z "$expected_hash" ]]; then
        echo "ERROR: Empty SHA256 checksum in file: ${sha256_file}" >&2
        exit 1
    fi

    # Compute actual hash
    local actual_hash
    actual_hash=$(sha256sum "$binary" | awk '{print $1}')

    if [[ "$actual_hash" != "$expected_hash" ]]; then
        echo "ERROR: SHA256 checksum mismatch!" >&2
        echo "       Expected: ${expected_hash}" >&2
        echo "       Actual:   ${actual_hash}" >&2
        echo "       The binary may be corrupted. Delete it and try again." >&2
        rm -f "$binary"
        exit 1
    fi

    echo "    SHA256 checksum verified: ${actual_hash}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
case "$MODE" in
    release) fetch_release ;;
    dev)     fetch_dev ;;
    *)
        echo "ERROR: Unknown mode: ${MODE}. Use 'release' or 'dev'." >&2
        exit 1
        ;;
esac
