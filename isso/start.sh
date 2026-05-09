#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
export ISSO_SETTINGS="$DIR/isso.conf"
./venv/bin/isso -c "$DIR/isso.conf" run
