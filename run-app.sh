#!/usr/bin/env bash
# Build and launch the macOS GUI app.
set -euo pipefail
cd "$(dirname "$0")"
exec swift run synth-app
