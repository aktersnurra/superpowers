# Superpowers

Superpowers is a complete software development methodology for your coding agents, built on top of a set of composable skills and some initial instructions that make sure your agent uses them.

## Quickstart

Give your agent Superpowers from this fork: [Claude Code](#claude-code), [Pi](#pi), [OpenCode](#opencode).

## This fork

Based on upstream **v7.0.0** (`obra/superpowers` at `bb92a77`). This fork keeps
Claude Code, Pi, and OpenCode installation guidance and uses **jj** for active
development workflows. Pi retains its manual bootstrap visibility and embedded
skill catalog. OpenCode supports V1 and V2 (2.0.4+).

Plan progress and review helpers use jj in jj repositories, including workspaces
without a colocated `.git/`; Git-only repositories retain a compatibility path.
Completed tasks leave an empty `@` after `jj commit`, so recorded review ranges
refer to stable completed commits. Sequential work reuses the current checkout;
parallel working trees use `jj workspace`.

Upstream's new brainstorming, leaner plans, inline execution, plan-scoped
progress, review fixes, and `diagnosing-superpowers` skill are included.

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it _doesn't_ just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do.

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest.

When the task needs a plan, your agent records the decisions, interfaces, tests, and verification an implementer needs. Planning scales to the work. It emphasizes red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY.

Next up, once you say "go", it launches a _subagent-driven-development_ process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for Claude to be able to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.

## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my opensource work](https://github.com/sponsors/obra).

Thanks!

- Jesse

## Installation

This fork lives at `https://github.com/aktersnurra/superpowers`. Prefer direct git-based install methods so your agent uses this fork rather than an upstream marketplace package.

Installation differs by harness. If you use more than one, install Superpowers separately for each one.

### Claude Code

Install this fork directly from GitHub:

```bash
/plugin install https://github.com/aktersnurra/superpowers
```

### Pi

- Install the package globally:

  ```bash
  pi install https://github.com/aktersnurra/superpowers
  ```

- Or install it for the current project:

  ```bash
  pi install -l https://github.com/aktersnurra/superpowers
  ```

### OpenCode

OpenCode uses its own plugin install; install Superpowers separately even if you
already use it in another harness.

- Tell OpenCode:

  ```
  Fetch and follow instructions from https://raw.githubusercontent.com/aktersnurra/superpowers/refs/heads/main/.opencode/INSTALL.md
  ```

- Detailed docs: [docs/README.opencode.md](docs/README.opencode.md)

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves design document.

2. **using-jj-workspaces** - Activates after design approval. Inspects the current checkout, creates a jj workspace when isolation is needed, and verifies the test baseline.

3. **writing-plans** - Activates with approved design. Records checkable tasks with exact paths, signatures, test assertions, and verification steps, without writing the implementation in advance.

4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes the plan inline with a durable progress ledger and a final review.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, follows the authorized jj publish/keep/squash workflow, and cleans up only confirmed workspaces.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## What's Inside

### Skills Library

**Testing**

- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes writing-good-tests reference)

**Debugging**

- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration**

- **diagnosing-superpowers** - Evidence-based session diagnosis
- **brainstorming** - Design refinement scaled to the request
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Inline execution with durable progress and final review
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-jj-workspaces** - Parallel jj workspaces
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)

**Meta**

- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read [the original release announcement](https://blog.fsck.com/2025/10/09/superpowers/).

## Contributing

The general contribution process for Superpowers is below. Keep in mind that we don't generally accept contributions of new skills and that any updates to skills must work across all of the coding agents we support.

1. Fork the repository
2. Switch to the 'dev' branch
3. Create a branch for your work
4. Follow the `writing-skills` skill for creating and testing new and modified skills
5. Submit a PR, being sure to fill in the pull request template.

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Superpowers updates are somewhat coding-agent dependent, but are often automatic.

## License

MIT License - see LICENSE file for details

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

- **Discord**: [Join us](https://discord.gg/35wsABTejz) for community support, questions, and sharing what you're building with Superpowers
- **Issues**: https://github.com/aktersnurra/superpowers/issues
- **Release announcements**: [Sign up](https://primeradiant.com/superpowers/) to get notified about new versions
