# claude-developer-toolbox

A quality-gated development pipeline for Claude Code. Every transition between phases is enforced by a hook that blocks forward progress until the required artifact exists.

> Code is a liability; judgement is an asset.

## Pipeline

```
idea
 ├─ /quick [--deep]          # fast track — no pipeline, no artifacts
 ├─ /git-workflow             # destructive git op safety gate — always available, standalone
 ├─ /init                    # project boilerplate — CLAUDE.md, README, CHANGELOG, CONTRIBUTING, PR template
 ├─ /status                  # inspect current pipeline phase — always available
 ├─ /reset                   # reset pipeline to a specific phase — always available
 ├─ /pack [path]             # Repomix snapshot — run before /qa for token efficiency
 │
 └─ /brief      → .pipeline/brief.md
     └─ /design → .pipeline/design.md
         └─ /review → .pipeline/design.approved
             └─ /plan   → .pipeline/plan.md
                 └─ /build  → .pipeline/build.complete
                     └─ /qa [--parallel|--sequential]
                         ├─ /cleanup
                         ├─ /frontend-audit
                         ├─ /backend-audit
                         ├─ /doc-audit
                         └─ /security-review
```

Each arrow is a quality gate. You cannot run `/design` without a brief. You cannot run `/plan` without an approved design. The hook enforces this mechanically.

## Invocation Model

Core workflow and safety skills are explicit slash-command entrypoints:
`/brief`, `/design`, `/review`, `/plan`, `/build`, `/qa`, `/init`,
`/git-workflow`, `/reset`, `/rollback`, and `/status`.

These skills set `disable-model-invocation: true` so Claude does not auto-enter
a stateful workflow from a natural-language prompt. Run the slash command when
you want that workflow to start.

Interactive skills prefer structured prompts when the runtime supports them, but
all current workflows fall back to plain-text questions if picker-style prompts
are unavailable.

## Platform Support

| Platform | Status |
|----------|--------|
| macOS | Fully supported |
| Linux | Fully supported |
| Windows (WSL) | Fully supported (hooks run inside WSL bash) |
| Windows (native) | Not supported — hooks require bash |

All hooks are bash scripts. On Windows, use [WSL](https://learn.microsoft.com/en-us/windows/wsl/) to run Claude Code with this plugin.

## Prerequisites

### Required

| Tool | Purpose | Install |
|------|---------|---------|
| Claude Code | Runtime | [docs.claude.ai](https://docs.claude.ai) |
| Context7 | Live library docs grounding | `/plugin install context7@claude-plugins-official` |

### Optional

| Tool | Purpose | Install |
|------|---------|---------|
| VS Code IDE Integration | Primary diagnostics tier for `/cleanup`, `/frontend-audit`, `/backend-audit` — tried before LSP tools | Built-in when running Claude Code inside VS Code |
| TypeScript LSP | Type-aware audits for TS/JS projects (secondary tier) | `/plugin install typescript-lsp@claude-plugins-official` |
| Go LSP | Symbol resolution for Go projects (secondary tier) | `/plugin install gopls-lsp@claude-plugins-official` |
| Python LSP | Type inference for Python projects (secondary tier) | `/plugin install python-lsp@claude-plugins-official` |
| C# LSP | Symbol resolution for .NET projects (secondary tier) | `/plugin install csharp-lsp@claude-plugins-official` |
| Repomix CLI | Token-efficient codebase packing for `/pack` and `/qa` shared snapshot | `npm install -g repomix` |

Diagnostics degrade gracefully across three tiers: VS Code IDE integration → LSP tool plugin → heuristic grep. Each absent tier reduces precision, not availability.

## Quick Install

```bash
# 1. Install Context7 (required — live library docs for /design and /review)
# Run inside a Claude Code session:
/plugin install context7@claude-plugins-official

# 2. Install repomix (recommended — token-efficient codebase packing for /pack and /qa)
npm install -g repomix

# 3. Add the marketplace and install the plugin
# Run inside a Claude Code session:
/plugin marketplace add pmco23/claude-developer-toolbox
/plugin install claude-developer-toolbox@pmco23-tools
```

Restart Claude Code. Run `/brief` to verify. Core workflow skills are
intentionally slash-only, so use the command explicitly rather than expecting
Claude to auto-load it from a natural-language request. See the [full installation guide](docs/guides/installation.md) for statusline setup, optional LSP tools, and verification steps.

## Documentation

### Guides

| Guide | |
|-------|--|
| [Workflows](docs/guides/workflows.md) | Decision guide, explicit slash-command behavior, mode flags, language support, end-to-end example |
| [Installation](docs/guides/installation.md) | Full install steps, statusline setup, slash-only behavior, verification |
| [Hooks](docs/guides/hooks.md) | Hook lifecycle, JSON outputs, statusline maintenance, and Repomix session-end packing |
| [Repomix Guide](docs/guides/mcp-setup.md) | Snapshot architecture, manual CLI usage, installation, troubleshooting |
| [Troubleshooting](docs/guides/troubleshooting.md) | Common issues and fixes |
| [Changelog](CHANGELOG.md) | Release history and version notes |

### Skills

| Skill | Description |
|-------|-------------|
| `/brief` | Requirements crystallization |
| `/design` | First-principles design |
| `/review` | Adversarial review |
| `/plan` | Atomic execution planning |
| `/drift-check` | Design-to-build drift detection |
| `/build` | Parallel build |
| `/qa` | Post-build QA pipeline |
| `/cleanup` | Dead code removal |
| `/frontend-audit` | Frontend style audit |
| `/backend-audit` | Backend style audit |
| `/doc-audit` | Documentation freshness audit (CHANGELOG + README drift) |
| `/security-review` | OWASP vulnerability scan |
| `/quick` | Fast-track implementation |
| `/init` | Project boilerplate scaffolding (CLAUDE.md, README, CHANGELOG, CONTRIBUTING, PR template, .gitignore) |
| `/git-workflow` | Destructive git operation safety gate (force-push, reset --hard, branch -D, rebase on published commits) |
| `/status` | Pipeline state check |
| `/pack` | Repomix codebase snapshot |
| `/test` | Run the project test suite |
| `/tdd` | Test-driven development — Iron Law, Red-Green-Refactor cycle, valid exceptions |
| `/rollback` | Undo a completed build with safety backups and git restore |
| `/reset` | Reset pipeline to a specific phase |

### Commands

Lightweight git operations — no pipeline artifacts, no multi-step process.

| Command | Description |
|---------|-------------|
| `/commit` | Stage changes and create a conventional commit |
| `/push` | Push current branch to remote (with `-u` if first push) |
| `/commit-push-pr` | Commit, push, and open a pull request in one shot |
| `/sync` | Fetch and rebase current branch onto upstream |
| `/clean-branches` | Remove local branches deleted from remote |
| `/release patch\|minor\|major` | Full release: version bump, changelog, commit, tag, push, GitHub release |

### Configuration (CLAUDE.md flags)

| Flag | Effect |
|------|--------|
| `tdd: disabled` | Switches `/plan` to implementation-first task ordering (skip Red-Green-Refactor) |
| `session-end-pack: disabled` | Skips automatic Repomix packing on session end |
