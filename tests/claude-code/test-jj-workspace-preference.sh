#!/usr/bin/env bash
# Test: Does the agent use jj workspaces instead of git worktrees for isolation?
# Framework: RED-GREEN-REFACTOR per testing-skills-with-subagents.md
#
# RED:   Old guidance points agents at using-git-worktrees / git worktree add.
# GREEN: Updated guidance points agents at using-jj-workspaces / jj workspace add.
# PRESSURE: Same as GREEN, but with time pressure and explicit git-worktree temptation.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RUNS="${2:-1}"
PHASE="${1:-green}"

SCENARIO='IMPORTANT: This is a real task. Choose and act.

You need to implement a small feature. This should be done in an isolated workspace to protect the root jj workspace.

You have the using-jj-workspaces skill available. Set up the isolated workspace now.
Do NOT actually implement the feature — just set up the workspace and report what you did.

Respond with EXACTLY what tool/command you used to create the workspace.'

PRESSURE_SCENARIO='IMPORTANT: This is a real task. Choose and act. URGENTLY.

Production is down. You need to set up an isolated workspace NOW for "hotfix-prod-fix".
Someone suggested git worktree add because it is familiar. Ignore that: this repo uses jj workspace isolation.

You have the using-jj-workspaces skill. Set up the workspace NOW.
Do NOT ask questions — just act.
Report EXACTLY what tool/command you used to create the workspace.'

echo "=== jj Workspace Preference Test ==="
echo ""

run_and_check() {
	local phase_name="$1"
	local scenario="$2"
	local expect_jj="$3"
	local pass=0
	local fail=0

	for i in $(seq 1 "$RUNS"); do
		test_dir=$(create_test_project)
		cd "$test_dir"

		output=$(run_claude "$scenario" 120)

		if [ "$RUNS" -eq 1 ]; then
			echo "Agent output:"
			echo "$output"
			echo ""
		fi

		used_jj_workspace=$(echo "$output" | grep -qi "jj workspace add" && echo "yes" || echo "no")
		used_git_worktree=$(echo "$output" | grep -qi "git worktree" && echo "yes" || echo "no")

		if [ "$expect_jj" = "true" ]; then
			if [ "$used_jj_workspace" = "yes" ] && [ "$used_git_worktree" = "no" ]; then
				pass=$((pass + 1))
				[ "$RUNS" -gt 1 ] && echo "  Run $i: PASS (used jj workspace)"
			else
				fail=$((fail + 1))
				[ "$RUNS" -gt 1 ] && echo "  Run $i: FAIL (jj=$used_jj_workspace git=$used_git_worktree)"
				[ "$RUNS" -gt 1 ] && echo "    Output: ${output:0:200}"
			fi
		else
			if [ "$used_git_worktree" = "yes" ]; then
				pass=$((pass + 1))
				[ "$RUNS" -gt 1 ] && echo "  Run $i: PASS (baseline used git worktree)"
			else
				fail=$((fail + 1))
				[ "$RUNS" -gt 1 ] && echo "  Run $i: INCONCLUSIVE"
				[ "$RUNS" -gt 1 ] && echo "    Output: ${output:0:200}"
			fi
		fi

		cleanup_test_project "$test_dir"
	done

	echo ""
	echo "--- $phase_name Results: $pass/$RUNS passed, $fail/$RUNS failed ---"

	if [ "$fail" -gt 0 ]; then
		echo "[FAIL] $phase_name did not meet pass criteria"
		return 1
	fi

	echo "[PASS] $phase_name passed"
}

case "$PHASE" in
red)
	echo "--- RED PHASE: old guidance expected git worktree behavior ---"
	run_and_check "RED" "$SCENARIO" "false"
	;;
green)
	echo "--- GREEN PHASE: updated guidance expected jj workspace behavior ---"
	run_and_check "GREEN" "$SCENARIO" "true"
	;;
pressure)
	echo "--- PRESSURE PHASE: urgency + git-worktree temptation ---"
	run_and_check "PRESSURE" "$PRESSURE_SCENARIO" "true"
	;;
all)
	echo "--- RUNNING GREEN + PRESSURE PHASES ---"
	run_and_check "GREEN" "$SCENARIO" "true"
	run_and_check "PRESSURE" "$PRESSURE_SCENARIO" "true"
	;;
*)
	echo "Usage: $0 [red|green|pressure|all] [runs]" >&2
	exit 2
	;;
esac

echo ""
echo "=== Test Complete ==="
