#!/usr/bin/env bash
# Build and run the CLI tool, forwarding any arguments.
#
#   ./run-cli.sh                        # play the shared test pattern
#   ./run-cli.sh 'c3 e3 g3 c4'          # play mini-notation
#   ./run-cli.sh -s sawtooth 'c2*4'     # choose a sound
#   ./run-cli.sh --list-sounds
set -euo pipefail
cd "$(dirname "$0")"
exec swift run synth-cli "$@"
