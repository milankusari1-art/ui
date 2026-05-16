#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/milankusari1-art/ui.git"
INSTALL_DIR="${1:-$HOME/opiumware-ui}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: This installer is for macOS only."
  exit 1
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" && "$ARCH" != "i386" ]]; then
  echo "Error: This installer is for Intel macOS only. Detected architecture: $ARCH"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required. Install curl and retry."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Git not found. Installing Xcode Command Line Tools..."
  xcode-select --install || true
  until command -v git >/dev/null 2>&1; do
    echo "Waiting for Git installation to complete..."
    sleep 5
  done
fi

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  echo "Homebrew was not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

if ! command -v node >/dev/null 2>&1; then
  ensure_brew
  if ! command -v brew >/dev/null 2>&1; then
    echo "Error: Homebrew installation failed. Install Node.js manually and rerun."
    exit 1
  fi

  echo "Node.js not found. Installing with Homebrew..."
  brew install node
fi

mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "Downloading installer repository..."
git clone --depth=1 "$REPO_URL" repo
cd repo

if [[ ! -f package.json || ! -f index.js ]]; then
  echo "Error: repository content is incomplete."
  exit 1
fi

echo "Installing dependencies..."
npm install --silent

mkdir -p "$INSTALL_DIR"
find "$INSTALL_DIR" -mindepth 1 -delete
cp -R . "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/.git"

cat <<EOF
Installation complete.

To run the UI launcher:
  cd "$INSTALL_DIR"
  npm start

If you want to install to a different location, rerun with:
  curl -fsSL "https://raw.githubusercontent.com/milankusari1-art/ui/main/studio.sh" | bash -s -- /path/to/install
EOF
