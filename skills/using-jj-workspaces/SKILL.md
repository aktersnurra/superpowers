---
name: using-jj-workspaces
description: Use when starting feature work that needs isolation from the current workspace or before executing implementation plans in a jj-managed repository
---

# Using jj Workspaces

## Overview

Ensure feature work happens in an isolated jj workspace, not in the root workspace.

**Core principle:** jj has no staging area; every file change belongs to the current working-copy commit (`@`). Use `jj workspace` for isolation instead of git worktrees.

**Announce at start:** "I'm using the using-jj-workspaces skill to set up an isolated workspace."

## Step 0: Inspect Workspace State

Before creating anything, inspect the current jj workspace:

```bash
jj workspace root
jj workspace list
jj st
```

Report the current workspace path and working-copy state.

If you are already in a purpose-specific jj workspace for this feature, skip to Step 2.

If you are in the root/default workspace and starting feature work, create a new workspace in Step 1. Do not use `jj new` as a substitute for workspace isolation when running feature work in parallel.

## Step 1: Create a Workspace When Needed

Use a separate jj workspace only when the task needs an isolated working tree,
such as parallel agent sessions, long-running tests, or side-by-side feature
work. For ordinary single-threaded feature work, prefer staying in the current
checkout and creating a new change with:

```bash
jj new
````

When a separate workspace is useful, create it under a dedicated workspace
container instead of polluting the parent directory with ad-hoc sibling repos.

```bash
# From the current repository workspace:
repo="$(basename "$(jj root)")"
mkdir -p "../${repo}.workspaces"

jj workspace add "../${repo}.workspaces/<feature-name>" --name "<feature-name>"
cd "../${repo}.workspaces/<feature-name>"
```

Then verify:

```bash
jj workspace root
jj st
jj workspace list
```

When the workspace is no longer needed, unregister it and remove the directory:

```bash
jj workspace forget <feature-name>
rm -rf "../${repo}.workspaces/<feature-name>"
```

Or, from inside the workspace being removed:

```bash
jj workspace forget
cd ..
rm -rf "<feature-name>"
```

`jj workspace forget` only removes jj’s registration for the workspace. It does
not delete the working-tree directory.

**Sandbox fallback:** If workspace creation fails because the environment blocks
writing outside the current directory, tell the user and continue with `jj new`
in the current checkout unless the user provides another workspace path.

## Step 2: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify Clean Baseline

Run the project test command before implementation:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures and ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
jj workspace ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation                                 | Action                                                          |
| ----------------------------------------- | --------------------------------------------------------------- |
| Already in feature-specific jj workspace  | Skip creation                                                   |
| In root/default workspace for new feature | `jj workspace add ../<repo>-<feature>`                          |
| Need to park current work                 | `jj new` only after deciding how to preserve current `@`        |
| Need to list workspaces                   | `jj workspace list`                                             |
| Need current workspace root               | `jj workspace root`                                             |
| Need cleanup after finishing              | `jj workspace forget <name>` then remove the directory manually |
| Workspace stale after history rewrite     | `jj workspace update-stale`                                     |
| Tests fail during baseline                | Report failures and ask                                         |

## Common Mistakes

### Using git worktrees in a jj repo

- **Problem:** Creates a parallel model that conflicts with the user's jj workflow.
- **Fix:** Use `jj workspace add` for isolated working trees.

### Treating jj like git staging

- **Problem:** Waiting to stage files or trying to protect untracked changes with an index.
- **Fix:** Remember every change is already in `@`; use `jj st`, `jj diff`, `jj split`, and `jj squash` to organize work.

### Using `jj new` instead of workspace isolation

- **Problem:** A new change in the same working tree does not isolate parallel feature sessions.
- **Fix:** Use `jj workspace add` for feature work that needs a separate directory.

### Removing workspace directories without forgetting them

- **Problem:** Leaves stale workspace registrations.
- **Fix:** Run `jj workspace forget <name>` before deleting the directory, or recover stale workspaces with `jj workspace update-stale`.

## Red Flags

**Never:**

- Use git worktree commands for feature isolation in this repo
- Start feature work directly in the root/default workspace when isolation is needed
- Use `jj new` as a replacement for workspace isolation
- Delete a workspace directory before `jj workspace forget <name>`
- Proceed with failing baseline tests without asking

**Always:**

- Inspect workspace state first
- Use `jj workspace add` for isolated feature work
- Verify setup and baseline tests before implementation
- Report the workspace path and current `jj st`
