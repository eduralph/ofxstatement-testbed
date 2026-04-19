#!/usr/bin/env bash
# Create testbed .venv and install core + all plugins in editable mode.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTBED_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$TESTBED_DIR/.." && pwd)"

VENV="$TESTBED_DIR/.venv"

if [[ ! -d "$VENV" ]]; then
    echo "==> creating venv at $VENV"
    python3 -m venv "$VENV"
fi

# shellcheck source=/dev/null
source "$VENV/bin/activate"

python -m pip install --upgrade pip

install_editable() {
    local name="$1"
    local dir="$WORKSPACE_DIR/$name"
    if [[ -d "$dir" ]]; then
        echo "==> pip install -e $name"
        pip install -e "$dir"
    else
        echo "!!  $name not cloned -- run scripts/clone.sh first"
    fi
}

install_editable "ofxstatement"
for plugin in ofxstatement-revolut ofxstatement-scalable ofxstatement-consorsbank ofxstatement-paypal-2; do
    install_editable "$plugin"
done

pip install pytest ruff

echo
echo "Done. Activate with: source $VENV/bin/activate"
