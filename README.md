# ofxstatement-testbed

Local development environment and integration CI for a set of [ofxstatement](https://github.com/kedder/ofxstatement) plugins.

## Repos under test

Cloned as siblings of this repo.

| Repo | Role | Upstream |
|---|---|---|
| [`ofxstatement`](https://github.com/eduralph/ofxstatement) | core (fork) | [kedder/ofxstatement](https://github.com/kedder/ofxstatement) |
| [`ofxstatement-revolut`](https://github.com/eduralph/ofxstatement-revolut) | plugin | — |
| [`ofxstatement-scalable`](https://github.com/eduralph/ofxstatement-scalable) | plugin | — |
| [`ofxstatement-consorsbank`](https://github.com/eduralph/ofxstatement-consorsbank) | plugin | — |
| [`ofxstatement-paypal-2`](https://github.com/eduralph/ofxstatement-paypal-2) | plugin (fork) | [Alfystar/ofxstatement-paypal-2](https://github.com/Alfystar/ofxstatement-paypal-2) |

## Setup

```sh
./scripts/clone.sh       # clone sibling repos, configure upstream remotes on the two forks
./scripts/bootstrap.sh   # create .venv in testbed, install core + plugins editable, add pytest + ruff
./scripts/test-all.sh    # run every plugin's own test suite, report pass/fail/skip
```

Then open `ofxstatement-testbed.code-workspace` for the multi-root VS Code view.

## Upstream sync

`ofxstatement` (core) and `ofxstatement-paypal-2` are forks. To see what has changed upstream without merging:

```sh
./scripts/sync-upstream.sh
```

Read-only — reports `ahead/behind` counts and new upstream commits, never merges.

## CI

GitHub Actions runs on push, PR, manual dispatch, and weekly (Mondays 06:00 UTC). Matrix:

- **Python:** 3.10 / 3.11 / 3.12 / 3.13
- **Core source:** PyPI release / `kedder/master` / `eduralph/master`

The weekly schedule is the main payoff of this repo — it catches upstream-core changes that break the plugins before a user upgrades core and is surprised.

## Layout

```
workspace-ofx/
├── ofxstatement/              # core, fork, editable install
├── ofxstatement-revolut/
├── ofxstatement-scalable/
├── ofxstatement-consorsbank/
├── ofxstatement-paypal-2/     # fork
└── ofxstatement-testbed/      # this repo
```

Each plugin keeps its own `tests/` folder; the testbed does not centralise fixtures.
