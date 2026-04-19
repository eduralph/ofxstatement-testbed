# CLAUDE.md

Context for future Claude sessions working in this repo.

## What this is

A development + CI harness aggregating five repos that are cloned **as siblings** of this one:

```
workspace-ofx/
├── ofxstatement/              # core, fork of kedder/ofxstatement
├── ofxstatement-revolut/      # own work
├── ofxstatement-scalable/     # own work
├── ofxstatement-consorsbank/  # own work
├── ofxstatement-paypal-2/     # fork of Alfystar/ofxstatement-paypal-2
└── ofxstatement-testbed/      # this repo
```

Scripts, the multi-root code-workspace, and CI all assume this layout. `scripts/clone.sh` sets it up.

## Repo cheat-sheet

| Repo | Own/Fork | Default branch | Upstream remote |
|---|---|---|---|
| `ofxstatement` | fork | `master` | `kedder/ofxstatement` |
| `ofxstatement-revolut` | own | `master` | — |
| `ofxstatement-scalable` | own | `master` | — |
| `ofxstatement-consorsbank` | own | `master` | — |
| `ofxstatement-paypal-2` | fork | `master` | `Alfystar/ofxstatement-paypal-2` |
| `ofxstatement-testbed` (this) | own | `main` | — |

**All five aggregated repos default to `master`, not `main`.** Do not assume `main`.

## Branch protection

All five aggregated repos carry the same Repository Ruleset named `default branch protection`, deliberately mirrored from `eduralph/gramps-testbed`:

- Target: `~DEFAULT_BRANCH`
- Rules: `deletion`, `non_fast_forward`, `pull_request` (0 approvals, require thread resolution)
- No required status checks (CI still runs on PRs, just not blocking)
- Bypass: Maintain role, pull-request mode only

**Practical impact:** direct `git push` to the default branch is rejected on all five. Every change lands via PR. If the user asks to commit + push on any of these, default to a PR workflow (feature branch → push → `gh pr create`).

The testbed repo itself (this one) is currently **not** protected.

## Plugin extras

All four plugins declare dev/test deps under `[project.optional-dependencies].dev`. `bootstrap.sh` and `.github/workflows/ci.yml` install with `[dev]` uniformly. If adding a new plugin, follow the same convention.

## Setup & tests

```sh
./scripts/clone.sh        # clone siblings, set upstream remotes on the two forks
./scripts/bootstrap.sh    # create .venv, pip install -e core + all plugins[dev], + ruff + pytest-cov
./scripts/test-all.sh     # pytest in core + each plugin; passes/fails/skips summary
./scripts/sync-upstream.sh  # READ-ONLY drift report for the two forks; never merges
```

## CI

`.github/workflows/ci.yml` matrix: Python 3.10/3.11/3.12/3.13 × core source (PyPI release / `kedder/master` / `eduralph/master`). Weekly cron catches upstream-core drift before it breaks plugins.

## Things to avoid

- Don't assume default branch is `main` for the aggregated repos — it's `master`.
- Don't try to `git push` to `master` on the aggregated repos — it's blocked. Open a PR.
- Don't add features, hooks, or abstractions to the scripts unless asked; they're deliberately minimal.
- Don't centralise test fixtures. Each plugin keeps its own `tests/` folder; the testbed aggregates, it does not own fixtures.
- `scripts/sync-upstream.sh` must stay read-only — do not add an auto-merge path.
