---
name: using-jj-workspaces
description: Use when starting feature work that needs isolation from the current workspace or before executing implementation plans in a jj-managed repository
---

# Using jj Workspaces

Inspect the current workspace first. Reuse it for sequential work; create a
separate working tree when concurrent work needs isolation. jj has no staging
area: file changes belong to the working-copy change (`@`).

**Announce:** "I'm using the using-jj-workspaces skill to inspect the workspace."

## 1. Inspect

```bash
jj root
jj workspace list
jj st
jj log --no-graph -r @ -T 'empty ++ " " ++ description.first_line()'
```

Record the workspace path and existing work. If `@` is already empty, use it;
there is no need to create another empty change. If it contains unrelated
work, preserve it and start a new change with `jj new` before editing. Do not
rewrite or squash someone else's change.

## 2. Choose the Working Tree

| Situation | Action |
| --- | --- |
| Single sequential task, current checkout suitable | Reuse current directory and empty `@` |
| Already in a workspace dedicated to this task | Reuse it |
| Parallel sessions or side-by-side features need separate files | Create a jj workspace |
| Harness provides the checkout | Preserve it; add a workspace only if isolation is still needed |
| jj is unavailable or this is a Git-only checkout | Report it; do not initialize or migrate VCS without authorization |

For a separate workspace, inspect the intended base revision first. Use an
explicit base instead of inheriting an accidental parent. Keep workspaces
under a dedicated container:

```bash
# Run from the original workspace. BASE is the chosen revision/commit ID.
repo="$(basename "$(jj root)")"
container="$(dirname "$(jj root)")/${repo}.workspaces"
mkdir -p "$container"
jj workspace add "$container/<feature-name>" --name "<feature-name>" -r "$BASE"
cd "$container/<feature-name>"
jj st
```

Record the absolute new path and workspace name for later cleanup. Never use
`git worktree` in a jj repository. `jj new` creates a change in the same
working tree; it does not isolate parallel sessions.

If the sandbox blocks the chosen path, use an allowed container. Continue in
the existing checkout only when concurrent sessions will not modify it;
otherwise stop until a usable isolated path is available.

## 3. Setup and Baseline

Read the project's setup instructions and use its declared package manager
and test command. Run only the setup it needs (respect lockfiles), then run
the appropriate baseline checks. Report failures by name before changing code.
Do not claim a green baseline when checks could not run. Report the path,
`jj st`, and baseline result.

## 4. Stable Task Boundaries

Before each planned task, start with an empty `@` and record the full commit
ID of its parent:

```bash
jj log --no-graph -r @- -T commit_id
```

After editing and verification, run `jj commit -m "<task summary>"` (or
`jj describe` then `jj new`). This freezes the completed change as `@-` and
leaves an empty `@` for the next task. A snapshot rewrites the commit ID of
`@`, so never keep its old SHA as a review base while continuing to edit it.
Use `jj diff`, `jj split`, and `jj squash` to organize changes deliberately;
there is no `git add` step. Do not rebase recorded task ranges during a plan.

## Cleanup

Preserve workspaces for review and PR iteration. Remove one only when the
user authorized cleanup and you can identify the workspace this workflow
created. Check `jj st`, its history and bookmarks, and the exact path first.
Never remove the original/default or harness-owned workspace automatically.
From a surviving workspace:

```bash
jj workspace forget <feature-name>
```

This unregisters the workspace but leaves its files. Remove only the recorded
absolute directory after checking it contains no work to preserve. Never run
an inferred relative `rm -rf` from an unknown working directory. On versions
with `jj workspace remove`, inspect its help and preservation checks before
using it. Use `jj workspace update-stale` to recover a stale workspace after
history was rewritten elsewhere.
