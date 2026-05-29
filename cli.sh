#!/usr/bin/env bash
# STRAAS CLI installer — ADR-005 §4.1
#
# Usage:
#   curl -fsSL https://install.straas.ai/cli.sh | bash
#   curl -fsSL https://install.straas.ai/cli.sh | bash -s -- v0.2.0
#   curl -fsSL https://install.straas.ai/cli.sh | STRAAS_INSTALL_DIR=$HOME/bin bash

set -euo pipefail

REPO="straas-tech/straas-workspace"
VERSION="${1:-latest}"
INSTALL_DIR="${STRAAS_INSTALL_DIR:-}"

# Detect OS
case "$(uname -s)" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux" ;;
  *)
    echo "error: unsupported OS: $(uname -s)" >&2
    echo "STRAAS supports macOS and Linux only." >&2
    exit 1
    ;;
esac

# Detect arch
case "$(uname -m)" in
  x86_64|amd64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)
    echo "error: unsupported arch: $(uname -m)" >&2
    exit 1
    ;;
esac

# Resolve install dir — prefer /usr/local/bin (writable), fallback ~/.local/bin
if [ -z "$INSTALL_DIR" ]; then
  if [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
  else
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
  fi
fi

# Resolve 'latest' to actual tag via GitHub API
if [ "$VERSION" = "latest" ]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -E '"tag_name"' \
    | head -1 \
    | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/')"
  if [ -z "$VERSION" ]; then
    echo "error: failed to resolve latest version from GitHub API" >&2
    exit 1
  fi
fi

ARCHIVE="straas_${OS}_${ARCH}.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$ARCHIVE"
CHECKSUMS_URL="https://github.com/$REPO/releases/download/$VERSION/checksums.txt"

echo "Installing STRAAS $VERSION ($OS/$ARCH) → $INSTALL_DIR/straas"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Download archive and checksums file
curl -fsSL -o "$TMPDIR/$ARCHIVE" "$URL"
curl -fsSL -o "$TMPDIR/checksums.txt" "$CHECKSUMS_URL"

# Verify SHA256 — abort if mismatch (tampering or corrupted download)
cd "$TMPDIR"
EXPECTED="$(grep "$ARCHIVE" checksums.txt | awk '{print $1}')"
if [ -z "$EXPECTED" ]; then
  echo "error: $ARCHIVE not found in checksums.txt" >&2
  exit 1
fi

# sha256sum on Linux, shasum -a 256 on macOS
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
else
  ACTUAL="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
fi

if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "error: checksum mismatch for $ARCHIVE" >&2
  echo "  expected: $EXPECTED" >&2
  echo "  actual:   $ACTUAL" >&2
  exit 1
fi

# Extract binary and install
tar -xzf "$ARCHIVE"
chmod +x straas
mv straas "$INSTALL_DIR/straas"

# Smoke test — verify the installed binary runs
if ! "$INSTALL_DIR/straas" --version >/dev/null 2>&1; then
  echo "error: installed binary does not execute correctly" >&2
  exit 1
fi

echo "STRAAS $VERSION installed to $INSTALL_DIR/straas"

# PATH hint when install dir is not in PATH
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo
    echo "warning: $INSTALL_DIR is not in your PATH."
    echo "Add this line to your shell profile (~/.zshrc, ~/.bashrc, etc.):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac
