#!/usr/bin/env bash
# Exercise the plan helpers against real jj repos, with and without .git/.
set -euo pipefail
command -v jj >/dev/null || { echo "SKIP: jj is required"; exit 0; }
root=$(cd "$(dirname "$0")/../.." && pwd)
sdd="$root/skills/subagent-driven-development/scripts"
ep="$root/skills/executing-plans/scripts"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export JJ_CONFIG="$tmp/config.toml"
cat > "$JJ_CONFIG" <<'CONFIG'
[user]
name = "Test"
email = "test@example.com"
[ui]
paginate = "never"
CONFIG

for mode in --no-colocate --colocate; do
  repo="$tmp/repo-$mode"
  jj git init "$mode" "$repo" >/dev/null 2>&1
  cd "$repo"
  mkdir -p docs/alpha docs/beta
  printf '# Plan\n\n## Task 1: First\n\nImplement it.\n' > docs/alpha/plan.md
  cp docs/alpha/plan.md docs/beta/plan.md
  jj commit -m fixture >/dev/null 2>&1
  # Freeze a base commit: jj new leaves a mutable @ whose SHA changes on edits.
  base=$(jj log --no-graph -r @- -T commit_id)
  out=$(bash "$ep/task-start" docs/alpha/plan.md 1)
  [[ "$out" == *"base: $base"* ]]
  dir=$(bash "$sdd/sdd-workspace" docs/alpha/plan.md)
  other=$(bash "$sdd/sdd-workspace" docs/beta/plan.md)
  [[ "$dir" != "$other" ]]
  [[ "$(cat "$dir/plan-path")" == docs/alpha/plan.md ]]
  # Scratch artifacts must stay out of jj snapshots.
  [[ -z "$(jj diff --name-only)" ]]
  printf 'first\n' > work.txt
  jj commit -m 'task part one' >/dev/null 2>&1
  printf 'second\n' >> work.txt
  jj commit -m 'task part two' >/dev/null 2>&1
  head=$(jj log --no-graph -r @- -T commit_id)
  bash "$ep/task-done" docs/alpha/plan.md 1 "$base" -- true >/dev/null
  grep -qF "commits ${base:0:7}..${head:0:7}" "$dir/progress.md"
  bash "$sdd/review-package" docs/alpha/plan.md "$base" "$head" "$tmp/review.diff" >/dev/null
  grep -q 'task part one' "$tmp/review.diff"
  grep -q 'task part two' "$tmp/review.diff"
  grep -q '+second' "$tmp/review.diff"
  # Empty and backwards ranges must not yield a misleading clean review.
  for range in "$head $head" "$head $base"; do
    read -r start end <<< "$range"
    rc=0
    bash "$sdd/review-package" docs/alpha/plan.md "$start" "$end" >/dev/null 2>&1 || rc=$?
    [[ "$rc" == 3 ]]
  done
  rc=0
  bash "$ep/task-done" docs/alpha/plan.md 2 "$head" -- false >/dev/null 2>&1 || rc=$?
  [[ "$rc" == 1 ]]
  ! grep -q 'Task 2: complete' "$dir/progress.md"
  # Passing tests are insufficient when the recorded BASE is empty or ahead
  # of this task's HEAD. Neither case may become durable completion evidence.
  rc=0
  bash "$ep/task-done" docs/alpha/plan.md 3 "$head" -- true >/dev/null 2>&1 || rc=$?
  [[ "$rc" == 3 ]]
  ! grep -q 'Task 3: complete' "$dir/progress.md"
  jj new -r "$base" >/dev/null 2>&1
  rc=0
  bash "$ep/task-done" docs/alpha/plan.md 3 "$head" -- true >/dev/null 2>&1 || rc=$?
  [[ "$rc" == 3 ]]
  ! grep -q 'Task 3: complete' "$dir/progress.md"
  jj new -r "$head" >/dev/null 2>&1
  # A dirty @ has not been frozen; task-start must not return a base SHA that
  # the next snapshot will rewrite. Existing work must be preserved.
  printf 'unfinished\n' > pending.txt
  rc=0
  bash "$ep/task-start" docs/alpha/plan.md 1 >/dev/null 2>&1 || rc=$?
  [[ "$rc" == 2 ]]
  [[ "$(cat pending.txt)" == unfinished ]]
  # Missing jj must not silently reinterpret a colocated jj repo as Git.
  mkdir -p "$tmp/no-jj"
  for tool in bash git dirname; do
    ln -sf "$(command -v "$tool")" "$tmp/no-jj/$tool"
  done
  rc=0
  PATH="$tmp/no-jj" bash "$ep/task-start" docs/alpha/plan.md 1 > "$tmp/no-jj.out" 2>&1 || rc=$?
  [[ "$rc" == 2 ]]
  grep -q 'jj' "$tmp/no-jj.out"
  # The same fail-closed behavior applies if a jj binary exists but fails.
  printf '#!/usr/bin/env bash\nexit 42\n' > "$tmp/no-jj/jj"
  chmod +x "$tmp/no-jj/jj"
  rc=0
  PATH="$tmp/no-jj" bash "$ep/task-start" docs/alpha/plan.md 1 > "$tmp/no-jj.out" 2>&1 || rc=$?
  [[ "$rc" == 2 ]]
  grep -q 'refusing Git fallback' "$tmp/no-jj.out"
  rm "$tmp/no-jj/jj"
  # A nested Git-only repo must use its own history, not its parent's jj.
  git init -q "$repo/nested"
  (
    cd "$repo/nested"
    source "$sdd/vcs"
    [[ "$SDD_VCS" == git && "$(vcs_root)" == "$repo/nested" ]]
  )
  # A second jj workspace has its own artifacts even for the same plan.
  jj workspace add "$tmp/other-$mode" --name other -r "$head" >/dev/null 2>&1
  cd "$tmp/other-$mode"
  dir2=$(bash "$sdd/sdd-workspace" docs/alpha/plan.md)
  [[ "$dir2" == "$PWD/.superpowers/sdd/plan" && "$dir2" != "$dir" ]]
  echo "PASS: jj plan helpers ($mode)"
done
