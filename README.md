# claude-agents-custom

A quality-gated development pipeline for Claude Code. Every transition between phases is enforced by a hook that blocks forward progress until the required artifact exists.

> Code is a liability; judgement is an asset.

## Pipeline

```
idea
 ├─ /quick [--deep]          # fast track — no pipeline, no artifacts
 ├─ /git-workflow             # git discipline — always available, standalone or via /build and /quick
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
| TypeScript LSP | Type-aware audits for TS/JS projects | `/plugin install typescript-lsp@claude-plugins-official` |
| Go LSP | Symbol resolution for Go projects | `/plugin install gopls-lsp@claude-plugins-official` |
| Python LSP | Type inference for Python projects | `/plugin install python-lsp@claude-plugins-official` |
| C# LSP | Symbol resolution for .NET projects | `/plugin install csharp-lsp@claude-plugins-official` |
| Repomix MCP | Token-efficient codebase packing for `/pack`, `/qa`, `/plan`, `/brief` | [MCP setup →](docs/guides/mcp-setup.md#repomix-mcp) |

LSP tools degrade gracefully — absent means reduced precision, not failure.

## Quick Install

```bash
claude
/plugin marketplace add ~/claude-agents-custom
/plugin install claude-agents-custom@local-dev
```

Restart Claude Code. Run `/brief` to verify. See the [full installation guide](docs/guides/installation.md) for statusline setup and verification steps.

## Documentation

### Guides

| Guide | |
|-------|--|
| [Installation](docs/guides/installation.md) | Full install steps, statusline setup, verification |
| [MCP Setup](docs/guides/mcp-setup.md) | Codex, Repomix, and Grafana MCP configuration |
| [Walkthrough](docs/guides/walkthrough.md) | End-to-end example, `.pipeline/` reference, mode flags, language matrix |
| [Troubleshooting](docs/guides/troubleshooting.md) | Common issues and fixes |

### Skills

| Skill | Description |
|-------|-------------|
| [/brief](docs/skills/brief.md) | Requirements crystallization |
| [/design](docs/skills/design.md) | First-principles design |
| [/review](docs/skills/review.md) | Adversarial review |
| [/plan](docs/skills/plan.md) | Atomic execution planning |
| [/drift-check](docs/skills/drift-check.md) | Design-to-build drift detection |
| [/build](docs/skills/build.md) | Parallel build |
| [/qa](docs/skills/qa.md) | Post-build QA pipeline |
| [/cleanup](docs/skills/cleanup.md) | Dead code removal |
| [/frontend-audit](docs/skills/frontend-audit.md) | Frontend style audit |
| [/backend-audit](docs/skills/backend-audit.md) | Backend style audit |
| [/doc-audit](docs/skills/doc-audit.md) | Documentation freshness audit |
| [/security-review](docs/skills/security-review.md) | OWASP vulnerability scan |
| [/quick](docs/skills/quick.md) | Fast-track implementation |
| [/init](docs/skills/init.md) | Project boilerplate scaffolding |
| [/git-workflow](docs/skills/git-workflow.md) | Git discipline |
| [/plugin-architecture](docs/skills/plugin-architecture.md) | Plugin architecture guide |
| [/status](docs/skills/status.md) | Pipeline state check |
| [/pack](docs/skills/pack.md) | Repomix codebase snapshot |
| [/grafana](docs/skills/grafana.md) | Grafana SRE toolbox |
