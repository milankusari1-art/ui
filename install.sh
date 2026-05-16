#!/usr/bin/env bash
set -e

echo "Installing Opiumware UI package..."

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is not installed. Install Node.js and retry."
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "Error: npm is not installed. Install npm and retry."
  exit 1
fi

npm install

echo "Installation complete. Run 'npm start' to launch the UI script."
