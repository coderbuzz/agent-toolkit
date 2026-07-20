#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TOOLKIT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

cd "$TOOLKIT_DIR"
PYTHONDONTWRITEBYTECODE=1 python3 scripts/toolkit.py validate
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
PYTHONDONTWRITEBYTECODE=1 python3 scripts/toolkit.py export --all --bundle core
PYTHONDONTWRITEBYTECODE=1 python3 scripts/toolkit.py validate --dist dist --bundle core
PYTHONDONTWRITEBYTECODE=1 python3 scripts/toolkit.py check-drift --all --bundle core
