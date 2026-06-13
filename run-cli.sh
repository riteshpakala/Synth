#!/usr/bin/env bash
# Build and run the CLI tool, forwarding any arguments.
#
#   ./run-cli.sh                 # play the shared test sequence
#   ./run-cli.sh C4 E4 G4 C5     # play these notes
#   ./run-cli.sh -w sine -t 90 A4 B4
#   ./run-cli.sh --list
set -euo pipefail
cd "$(dirname "$0")"
exec swift run synth-cli "$@"
