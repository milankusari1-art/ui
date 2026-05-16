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

  if [[ -x "/usr/local/bin/brew" ]]; then
    PATH="/usr/local/bin:$PATH"
    return 0
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    PATH="/opt/homebrew/bin:$PATH"
    return 0
  fi

  echo "Homebrew was not found. Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    PATH="/usr/local/bin:$PATH"
    return 0
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    PATH="/opt/homebrew/bin:$PATH"
    return 0
  fi

  return 1
}

install_node_locally() {
  echo "Homebrew is unavailable. Installing Node.js locally..."
  NODE_INSTALL_DIR="$HOME/.local/nodejs"
  mkdir -p "$NODE_INSTALL_DIR"
  NODE_VERSION=$(curl -fsSL https://nodejs.org/dist/index.tab | awk 'NR==2 {print $1}')
  if [[ -z "$NODE_VERSION" ]]; then
    return 1
  fi

  NODE_TARBALL="${NODE_VERSION}-darwin-x64.tar.gz"
  NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_TARBALL}"
  curl -fsSL "$NODE_URL" -o "$TMP_DIR/node.tar.gz"
  tar -xzf "$TMP_DIR/node.tar.gz" -C "$TMP_DIR"

  NODE_DIR="$TMP_DIR/node-${NODE_VERSION}-darwin-x64"
  if [[ ! -d "$NODE_DIR" ]]; then
    return 1
  fi

  rm -rf "$NODE_INSTALL_DIR"
  mv "$NODE_DIR" "$NODE_INSTALL_DIR"
  PATH="$NODE_INSTALL_DIR/bin:$PATH"
  return 0
}

if ! command -v node >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Node.js not found. Installing with Homebrew..."
    brew install node || {
      echo "Error: Homebrew failed to install Node.js."
      echo "Please install Node.js manually and rerun."
      exit 1
    }
  else
    if ! ensure_brew; then
      if ! install_node_locally; then
        echo "Error: Node.js is required. Install Homebrew or Node.js manually and rerun."
        exit 1
      fi
    else
      echo "Node.js not found. Installing with Homebrew..."
      brew install node || {
        echo "Error: Homebrew failed to install Node.js."
        echo "Please install Node.js manually and rerun."
        exit 1
      }
    fi
  fi

  if command -v brew >/dev/null 2>&1; then
    PATH="$(brew --prefix)/bin:$PATH"
  fi

  if ! command -v node >/dev/null 2>&1; then
    echo "Error: Node.js installation completed but 'node' is not in PATH."
    echo "Ensure Node.js is installed and available in PATH, then rerun."
    exit 1
  fi
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

Starting the UI launcher now...

If the app does not start, run:
  cd "$INSTALL_DIR"
  npm start

If you want to install to a different location, rerun with:
  curl -fsSL "https://raw.githubusercontent.com/milankusari1-art/ui/main/studio.sh" | bash -s -- /path/to/install
EOF

cd "$INSTALL_DIR"
npm start
