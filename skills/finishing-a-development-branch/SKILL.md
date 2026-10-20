---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work using jj bookmarks, push, or cleanup
---

# Finishing Development Work

Verify the result, inspect the jj changes, then carry out the authorized
integration. Preserve the checkout for review and iteration.

**Announce:** "I'm using the finishing-a-development-branch skill to complete this work."

## 1. Verify and Inspect

Run the project's required checks and report the actual results. Fix failures
before claiming completion. Inspect:

```bash
jj root
jj workspace list
jj st
jj log -r 'ancestors(@, 5)'
jj bookmark list
```

Confirm the completed change and its base. If `@` contains the completed work,
describe it and run `jj new`, or use `jj commit -m "<summary>"`. If `@` is
already empty, the completed change is `@-`; do not publish the empty `@`.
Check the full commit range for conflicts and unexpected unrelated work.

## 2. Select the Integration

Follow the user's existing instructions for publishing, keeping, or squashing.
Do not ask them to repeat a choice they already made. If no choice is known,
present these three options:

1. Publish a feature bookmark for review.
2. Keep the changes locally.
3. Squash the completed change into a specified parent.

Do not offer to discard completed work. If the user explicitly asks to discard
it, identify the exact changes and confirm that destructive action separately.

### Publish

Identify the intended remote with `jj git remote list` and check the destination
bookmark. Use a feature bookmark for review; updating shared main/master needs
explicit authorization. With an empty `@`:

```bash
# Create a new bookmark at the completed change:
jj bookmark create <feature-name> -r @-
# Or move an existing feature bookmark after inspecting its current target:
jj bookmark set <feature-name> -r @-
jj git push --remote <remote> --bookmark <feature-name>
```

For a new remote bookmark, use the installed jj version's explicit new-bookmark
flag if required (`jj git push --help`). Do not enable broad push settings or
force unrelated bookmarks. Give the user the branch/PR link and validation.
Create a PR only within the authorization and contributor rules for that fork.

### Keep

Report the workspace path, completed change ID, bookmark (if any), and checks.
Leave the workspace available for the next session.

### Squash

Confirm the exact source and destination and inspect their diffs first.
With an empty `@`, the finished change is `@-`; a bare `jj squash` would target
the empty working copy. Use explicit revisions:

```bash
jj squash --from <completed-change> --into <destination-change>
jj st
jj log -r 'ancestors(@, 5)'
```

Do not rewrite published/shared history without authorization. Preserve the
workspace after squashing.

## 3. Cleanup Only When Requested

Only remove a dedicated workspace when cleanup is authorized and its provenance
is known. Follow superpowers:using-jj-workspaces, inspect it for work to preserve,
and unregister it before removing the recorded absolute path. Keep the default
workspace and anything owned by the harness. Publishing does not imply cleanup.
