#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/milankusari1-art/ui.git"
INSTALL_DIR="${1:-$HOME/opiumware-ui}"
APP_DIR="${2:-$HOME/Applications/OpiumwareUI.app}"
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

create_mac_app_bundle() {
  echo "Creating macOS app bundle at: $APP_DIR"
  rm -rf "$APP_DIR"
  mkdir -p "$APP_DIR/Contents/MacOS"
  mkdir -p "$APP_DIR/Contents/Resources/app"
  mkdir -p "$APP_DIR/Contents/Resources"

  cp -R "$INSTALL_DIR"/. "$APP_DIR/Contents/Resources/app/"
  cp assets/icon.icns "$APP_DIR/Contents/Resources/"

  cat > "$APP_DIR/Contents/MacOS/OpiumwareUI" <<'EOF'
#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "$0")/../Resources/app" && pwd)"
NODE="$(command -v node || true)"
if [[ -z "$NODE" ]]; then
  if [[ -x "$HOME/.local/nodejs/bin/node" ]]; then
    NODE="$HOME/.local/nodejs/bin/node"
  elif [[ -x "/usr/local/bin/node" ]]; then
    NODE="/usr/local/bin/node"
  elif [[ -x "/opt/homebrew/bin/node" ]]; then
    NODE="/opt/homebrew/bin/node"
  fi
fi
if [[ -z "$NODE" || ! -x "$NODE" ]]; then
  echo "Error: Node.js is required to run OpiumwareUI.app."
  exit 1
fi
cd "$DIR"
exec "$NODE" index.js
EOF

  chmod +x "$APP_DIR/Contents/MacOS/OpiumwareUI"

  cat > "$APP_DIR/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>OpiumwareUI</string>
  <key>CFBundleDisplayName</key>
  <string>Opiumware UI</string>
  <key>CFBundleIdentifier</key>
  <string>com.opiumware.ui</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>0.1.0</string>
  <key>CFBundleExecutable</key>
  <string>OpiumwareUI</string>
  <key>CFBundleIconFile</key>
  <string>icon.icns</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.14</string>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
EOF
  printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"
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

create_mac_app_bundle

cat <<EOF
Installation complete.

The app bundle has been created at:
  $APP_DIR

Opening the app now...

If the app does not start, run:
  open "$APP_DIR"

If you want to install to a different location, rerun with:
  curl -fsSL "https://raw.githubusercontent.com/milankusari1-art/ui/main/studio.sh" | bash -s -- /path/to/install
EOF

open "$APP_DIR"
