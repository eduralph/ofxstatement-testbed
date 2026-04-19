#!/usr/bin/env bash
# Run pytest in each plugin's own repo. Reports which plugins passed/failed/skipped.
set -uo pipefail  # no -e: we want to collect results across all plugins

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTBED_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$TESTBED_DIR/.." && pwd)"

if [[ -f "$TESTBED_DIR/.venv/bin/activate" ]]; then
    # shellcheck source=/dev/null
    source "$TESTBED_DIR/.venv/bin/activate"
fi

plugins=(
    ofxstatement-revolut
    ofxstatement-scalable
    ofxstatement-consorsbank
    ofxstatement-paypal-2
)

declare -a passed=()
declare -a failed=()
declare -a skipped=()

for plugin in "${plugins[@]}"; do
    dir="$WORKSPACE_DIR/$plugin"
    echo "=== $plugin ==="

    if [[ ! -d "$dir" ]]; then
        echo "  skipped: not cloned"
        skipped+=("$plugin")
        echo
        continue
    fi

    has_tests=0
    [[ -d "$dir/tests" ]] && has_tests=1
    find "$dir" -maxdepth 3 -name 'test_*.py' -print -quit 2>/dev/null | grep -q . && has_tests=1

    if [[ "$has_tests" -eq 0 ]]; then
        echo "  skipped: no tests found"
        skipped+=("$plugin")
        echo
        continue
    fi

    if (cd "$dir" && pytest); then
        passed+=("$plugin")
    else
        failed+=("$plugin")
    fi
    echo
done

echo "=== Summary ==="
echo "Passed  (${#passed[@]}): ${passed[*]:-}"
echo "Failed  (${#failed[@]}): ${failed[*]:-}"
echo "Skipped (${#skipped[@]}): ${skipped[*]:-}"

[[ ${#failed[@]} -eq 0 ]]
