# Codex Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references                 | Codex equivalent                                                                                                      |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `Task` tool (dispatch subagent)  | `spawn_agent` (see [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)) |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls                                                                                          |
| Task returns result              | `wait_agent`                                                                                                          |
| Task completes automatically     | `close_agent` to free slot                                                                                            |
| `TodoWrite` (task tracking)      | `update_plan`                                                                                                         |
| `Skill` tool (invoke a skill)    | Skills load natively — just follow the instructions                                                                   |
| `Read`, `Write`, `Edit` (files)  | Use your native file tools                                                                                            |
| `Bash` (run commands)            | Use your native shell tools                                                                                           |

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait_agent`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.

Legacy note: Codex builds before `rust-v0.115.0` exposed spawned-agent
waiting as `wait`. Current Codex uses `wait_agent` for spawned agents. The
`wait` name now belongs to code-mode `exec/wait`, which resumes a yielded exec
cell by `cell_id`; it is not the spawned-agent result tool.

## Environment Detection

Skills that create isolated workspaces should detect their jj workspace state
before proceeding:

```bash
jj workspace root
jj workspace list
jj st
```

- Already in a purpose-specific workspace → skip creation
- In the root/default workspace for new feature work → use `using-jj-workspaces`

See `using-jj-workspaces` Step 0 for the workspace setup flow.

## Codex App Finishing

When the sandbox blocks remote operations, the agent commits all work and
informs the user to use the App's native controls:

- **"Create branch"** — names the branch, then handles publish/PR via App UI
- **"Hand off to local"** — transfers work to the user's local checkout

The agent can still run tests and output suggested change descriptions for the
user to copy.
