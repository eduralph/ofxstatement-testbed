#!/usr/bin/env bash
# Show drift between the two forks and their upstreams. Read-only; does not merge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTBED_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$TESTBED_DIR/.." && pwd)"

report_drift() {
    local repo="$1"
    local branch="${2:-master}"

    echo "=== $repo ==="
    if [[ ! -d "$WORKSPACE_DIR/$repo" ]]; then
        echo "  ! not cloned -- run scripts/clone.sh first"
        echo
        return
    fi

    cd "$WORKSPACE_DIR/$repo"

    if ! git remote | grep -q '^upstream$'; then
        echo "  ! no 'upstream' remote -- run scripts/clone.sh first"
        echo
        return
    fi

    git fetch upstream --quiet

    local behind ahead
    ahead=$(git rev-list --count "upstream/$branch..$branch" 2>/dev/null || echo "?")
    behind=$(git rev-list --count "$branch..upstream/$branch" 2>/dev/null || echo "?")

    echo "  $branch is $ahead ahead, $behind behind upstream/$branch"

    if [[ "$behind" != "0" && "$behind" != "?" ]]; then
        echo "  new upstream commits:"
        git --no-pager log --oneline "$branch..upstream/$branch" | sed 's/^/    /'
    fi
    echo
}

report_drift "ofxstatement"
report_drift "ofxstatement-paypal-2"
