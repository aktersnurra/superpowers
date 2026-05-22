---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work using jj bookmarks, push, or cleanup
---

# Finishing Development Work

## Overview

Guide completion of development work by presenting clear options and handling the chosen jj workflow.

**Core principle:** Verify tests → inspect jj workspace → present options → execute choice → clean up only what this workflow owns.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

Before presenting options, verify tests pass:

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

If tests fail:

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with publish/discard until tests pass.
```

Stop. Don't proceed to Step 2.

### Step 2: Inspect jj State

Determine workspace and change state before presenting options:

```bash
jj workspace root
jj workspace list
jj st
jj log -r 'ancestors(@, 5)'
```

Note:

- current workspace path
- current working-copy change (`@`)
- whether a bookmark already points at the work
- whether there are conflicts or failing tests

### Step 3: Ensure Change Description

If `@` does not have a meaningful description, set one before publishing or handing off:

```bash
jj describe -m "<clear summary of completed work>"
```

### Step 4: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Publish via jj bookmark and push
2. Keep the jj workspace as-is (I'll handle it later)
3. Squash into parent change
4. Discard this work

Which option?
```

Don't add extra explanation unless the user asks.

### Step 5: Execute Choice

#### Option 1: Publish via jj Bookmark and Push

If no suitable bookmark exists, create one:

```bash
jj bookmark create <feature-name>
```

If the bookmark exists but needs to point at the current change:

```bash
jj bookmark set <feature-name> -r @
```

Push the bookmark:

```bash
jj git push -b <feature-name>
```

Then provide a concise PR summary and test plan for the user or hosting tool.

Do not remove the workspace automatically; PR iteration may need it.

#### Option 2: Keep As-Is

Report:

```
Keeping jj workspace at <path>.
Current change: <rev/description>
Bookmark: <bookmark or none>
```

Do not clean up the workspace.

#### Option 3: Squash Into Parent Change

Only do this when the user confirms the current change should be folded into its parent.

```bash
jj squash
```

Then verify:

```bash
jj st
jj log -r 'ancestors(@, 5)'
```

Do not remove the workspace automatically.

#### Option 4: Discard

Confirm first:

```
This will abandon the current jj change and may make workspace changes unrecoverable.

Current change: <rev/description>
Workspace: <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:

```bash
jj abandon @
```

Then proceed to Step 6 if this workflow created a dedicated jj workspace that should be removed.

### Step 6: Cleanup jj Workspace

Only run cleanup when the user chose discard or explicitly asked to remove the workspace.

List workspaces and identify the current workspace name:

```bash
jj workspace list
```

From another workspace or after moving out of the directory, unregister the workspace:

```bash
jj workspace forget <workspace-name>
```

Then remove the directory manually if the user confirmed removal.

If the workspace was created by the harness or you cannot prove this workflow owns it, leave it in place.

## Quick Reference

| Option        | Action                                          | Cleanup                        |
| ------------- | ----------------------------------------------- | ------------------------------ |
| 1. Publish    | `jj bookmark create/set`, then `jj git push -b` | Preserve workspace             |
| 2. Keep as-is | Report path/change/bookmark                     | Preserve workspace             |
| 3. Squash     | `jj squash` after confirmation                  | Preserve workspace             |
| 4. Discard    | `jj abandon @` after typed confirmation         | Optional `jj workspace forget` |

## Common Mistakes

**Skipping test verification**

- **Problem:** Publish broken code.
- **Fix:** Always verify tests before offering options.

**Forgetting that jj has no staging area**

- **Problem:** Thinking un-staged files are separate from the current change.
- **Fix:** Treat every file change as part of `@`; use `jj split` or `jj squash` to organize.

**Publishing without a bookmark**

- **Problem:** Remote push has no named target for review.
- **Fix:** Create or set a bookmark before `jj git push -b`.

**Deleting workspace directories first**

- **Problem:** Leaves stale jj workspace registrations.
- **Fix:** Use `jj workspace forget <name>` before removing directories.

**Cleaning up harness-owned workspaces**

- **Problem:** Removing a workspace the harness created causes phantom state.
- **Fix:** Only clean up a workspace this workflow created or the user explicitly asked to remove.

## Red Flags

**Never:**

- Proceed with failing tests
- Publish without verifying tests
- Delete or abandon work without typed confirmation
- Use git branch/worktree commands for jj workflow cleanup
- Remove a workspace you did not create or cannot identify

**Always:**

- Verify tests before offering options
- Inspect `jj workspace` and `jj st` before presenting the menu
- Present exactly 4 options
- Get typed confirmation for discard
- Preserve the workspace for publish/PR iteration
- Use `jj workspace forget` before removing a workspace directory
