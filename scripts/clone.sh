#!/usr/bin/env bash
# Clone all ofxstatement repos as siblings of the testbed.
# Sets up 'upstream' remote on the two forks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTBED_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$TESTBED_DIR/.." && pwd)"

cd "$WORKSPACE_DIR"

clone_if_missing() {
    local repo="$1"
    if [[ -d "$repo" ]]; then
        echo "ok  $repo already cloned"
    else
        echo "==> cloning eduralph/$repo"
        if command -v gh >/dev/null 2>&1; then
            gh repo clone "eduralph/$repo"
        else
            git clone "https://github.com/eduralph/$repo.git"
        fi
    fi
}

set_upstream() {
    local repo="$1"
    local upstream_url="$2"
    (
        cd "$WORKSPACE_DIR/$repo"
        if git remote | grep -q '^upstream$'; then
            echo "ok  $repo already has upstream remote"
        else
            echo "==> adding upstream on $repo -> $upstream_url"
            git remote add upstream "$upstream_url"
        fi
        git fetch upstream --quiet
    )
}

# Core (fork of kedder/ofxstatement)
clone_if_missing "ofxstatement"
set_upstream "ofxstatement" "https://github.com/kedder/ofxstatement.git"

# Own-work plugins
clone_if_missing "ofxstatement-revolut"
clone_if_missing "ofxstatement-scalable"
clone_if_missing "ofxstatement-consorsbank"

# Forked plugin (fork of Alfystar/ofxstatement-paypal-2)
clone_if_missing "ofxstatement-paypal-2"
set_upstream "ofxstatement-paypal-2" "https://github.com/Alfystar/ofxstatement-paypal-2.git"

echo
echo "All repos ready under $WORKSPACE_DIR"
