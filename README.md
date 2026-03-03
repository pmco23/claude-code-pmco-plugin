# claude-developer-toolbox

A quality-gated development pipeline for Claude Code. Every transition between phases is enforced by a hook that blocks forward progress until the required artifact exists.

> Code is a liability; judgement is an asset.

## Pipeline

```
idea
 ├─ /quick [--deep]          # fast track — no pipeline, no artifacts
 ├─ /git-workflow             # git discipline — always available, standalone
 ├─ /init                    # project boilerplate — README, CHANGELOG, CONTRIBUTING, PR template
 ├─ /status                  # inspect current pipeline phase — always available
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

## Prerequisites

### Required

| Tool | Purpose | Install |
|------|---------|---------|
| Claude Code | Runtime | [docs.claude.ai](https://docs.claude.ai) |
| Context7 | Live library docs grounding | `/plugin install context7@claude-plugins-official` |
| Codex CLI | Adversarial review and code validation | [MCP setup →](docs/guides/mcp-setup.md#codex-mcp) |

### Optional

| Tool | Purpose | Install |
|------|---------|---------|
| VS Code IDE Integration | Primary diagnostics tier for `/cleanup`, `/frontend-audit`, `/backend-audit` — tried before LSP tools | Built-in when running Claude Code inside VS Code |
| TypeScript LSP | Type-aware audits for TS/JS projects (secondary tier) | `/plugin install typescript-lsp@claude-plugins-official` |
| Go LSP | Symbol resolution for Go projects (secondary tier) | `/plugin install gopls-lsp@claude-plugins-official` |
| Python LSP | Type inference for Python projects (secondary tier) | `/plugin install python-lsp@claude-plugins-official` |
| C# LSP | Symbol resolution for .NET projects (secondary tier) | `/plugin install csharp-lsp@claude-plugins-official` |
| Repomix MCP | Token-efficient codebase packing for `/pack`, `/qa`, `/plan`, `/brief` | [MCP setup →](docs/guides/mcp-setup.md#repomix-mcp) |

Diagnostics degrade gracefully across three tiers: VS Code IDE integration → LSP tool plugin → heuristic grep. Each absent tier reduces precision, not availability.

## Quick Install

```bash
claude
/plugin marketplace add ~/claude-developer-toolbox
/plugin install claude-developer-toolbox@local-dev
```

Restart Claude Code. Run `/brief` to verify. See the [full installation guide](docs/guides/installation.md) for statusline setup and verification steps.

## Documentation

### Guides

| Guide | |
|-------|--|
| [Workflows](docs/guides/workflows.md) | Decision guide, pipeline reference, mode flags, language support, end-to-end example |
| [Installation](docs/guides/installation.md) | Full install steps, statusline setup, verification |
| [MCP Setup](docs/guides/mcp-setup.md) | Codex and Repomix MCP configuration |
| [Troubleshooting](docs/guides/troubleshooting.md) | Common issues and fixes |

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
| `/doc-audit` | Documentation freshness audit |
| `/security-review` | OWASP vulnerability scan |
| `/quick` | Fast-track implementation |
| `/init` | Project boilerplate scaffolding |
| `/git-workflow` | Git discipline |
| `/plugin-architecture` | Plugin architecture guide |
| `/status` | Pipeline state check |
| `/pack` | Repomix codebase snapshot |
| `/test` | Run the project test suite |
| `/release` | Cut a new release (version bump, CHANGELOG, tag) |
| `/rollback` | Undo a completed build |
