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
| OpenAI MCP | Codex access for adversarial review and code validation | See [OpenAI MCP setup](#openai-mcp-setup) |

### Optional (enhances specific skills)

| Tool | Purpose | Install |
|------|---------|---------|
| TypeScript LSP | Type-aware audits for TS/JS projects | `/plugin install typescript-lsp@claude-plugins-official` |
| Go LSP | Symbol resolution for Go projects | `/plugin install gopls-lsp@claude-plugins-official` |
| Python LSP | Type inference for Python projects | `/plugin install python-lsp@claude-plugins-official` |
| C# LSP | Symbol resolution for .NET projects | `/plugin install csharp-lsp@claude-plugins-official` |

LSP tools degrade gracefully — absent means reduced precision, not failure.

## OpenAI MCP Setup

Configure the OpenAI MCP server so Claude can call Codex. Add to your `~/.claude/settings.json` or project `.mcp.json`:

```json
{
  "mcpServers": {
    "openai": {
      "command": "npx",
      "args": ["-y", "@openai/mcp-server"],
      "env": {
        "OPENAI_API_KEY": "your-key-here"
      }
    }
  }
}
```

Verify it's working: start Claude Code and confirm OpenAI tools appear in the available tools list.

## Installation

### Step 1: Add the development marketplace

```bash
claude
/plugin marketplace add ~/claude-agents-custom
```

### Step 2: Install the plugin

```
/plugin install claude-agents-custom@local-dev
```

### Step 3: Restart Claude Code

Quit and reopen. The skills will appear in the skill list and the gate hook will be active.

### Step 4: Verify installation

```bash
# In a Claude Code session:
/brief
```

You should see the brief skill start a Q&A session. If the gate hook is active, trying `/design` before running `/brief` will show a block message.

## The .pipeline/ State Directory

Each pipeline phase writes a state artifact to `.pipeline/` in your project root. This is how the hook knows where you are in the pipeline.

```
.pipeline/
├── brief.md          # written by /brief
├── design.md         # written by /design
├── design.approved   # written by /review when review loop resolves
├── plan.md           # written by /plan
└── build.complete    # written by /build after /drift-check passes
```

**The `.pipeline/` directory is not committed to git by default.** Add it to `.gitignore`:

```
.pipeline/
```

Or commit it if you want a paper trail of your pipeline state.

**To reset the pipeline** (start over from a specific phase):

```bash
# Reset everything — start fresh from /brief
rm -rf .pipeline/

# Re-open from design phase (keep brief, redo design forward)
rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Re-open from review phase (keep design, redo /review forward)
rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete
```

## Command Reference

### /brief — Requirements Crystallization

**Gate:** None (always available)
**Writes:** `.pipeline/brief.md`
**Model:** Opus

Extracts requirements, constraints, non-goals, style preferences, and key concepts from fuzzy input through conversational Q&A. Detects your project language and available LSP tools. Ends with a forced-choice checkpoint to resolve remaining ambiguities before writing the brief.

```
/brief
```

---

### /design — First-Principles Design

**Gate:** `.pipeline/brief.md` must exist
**Writes:** `.pipeline/design.md`
**Model:** Opus
**Tools used:** Context7, web search, LSP (if available)

Reads the brief and performs first-principles analysis. Classifies every constraint as hard or soft. Flags soft constraints being treated as hard. Grounds all library and pattern recommendations in live docs via Context7 before drawing conclusions. Iterates with you until alignment. Output is a formal design document.

```
/design
```

---

### /review — Adversarial Review

**Gate:** `.pipeline/design.md` must exist
**Writes:** `.pipeline/design.approved` (on loop exit)
**Models:** Opus (strategic critique) + Codex via OpenAI MCP (code-grounded critique)
**Tools used:** Context7, filesystem

Dispatches Opus and Codex in parallel. Each critiques the design from a different angle. Lead Opus deduplicates findings, fact-checks each against the actual codebase, runs cost/benefit analysis, and outputs a structured report. Loop continues until no remaining findings warrant mitigation.

```
/review
```

---

### /plan — Atomic Execution Planning

**Gate:** `.pipeline/design.approved` must exist
**Writes:** `.pipeline/plan.md`
**Model:** Opus

Transforms the approved design into an execution document precise enough that build agents never ask clarifying questions. ~5 tasks per agent group. Exact file paths. Complete code examples. Named test cases with setup and assertions defined at plan time. Flags which task groups are safe for parallel execution.

```
/plan
```

---

### /drift-check — Drift Detection

**Gate:** `.pipeline/plan.md` must exist
**Writes:** nothing (report only)
**Models:** Sonnet (agent 1) + Codex via OpenAI MCP (agent 2) + Opus (lead)

Two agents independently extract claims from a source-of-truth document and verify each against a target. Lead reconciles conflicts and mitigates drift.

```
/drift-check
```

---

### /build — Parallel Build

**Gate:** `.pipeline/plan.md` must exist
**Writes:** `.pipeline/build.complete` (after /drift-check passes)
**Models:** Opus (lead) + Sonnet (builders)
**Flags:** `--parallel` | `--sequential`

```
/build --parallel     # Sonnets in independent agents, own context each
/build --sequential   # Task groups executed one at a time, current session
/build                # Prompts you to choose
```

Lead Opus coordinates and unblocks. Never writes implementation code. Runs /drift-check post-build. Writes `build.complete` only when /drift-check passes.

---

### /qa — Post-Build QA Pipeline

**Gate:** `.pipeline/build.complete` must exist
**Flags:** `--parallel` | `--sequential`

```
/qa --parallel    # All QA skills dispatched simultaneously
/qa --sequential  # cleanup → frontend-audit → backend-audit → doc-audit → security-review in order
/qa               # Prompts you to choose
```

Individual skills are also available standalone (each requires `build.complete`):

| Skill | What it does |
|-------|-------------|
| `/cleanup` | Strips dead code, unused imports, unreachable branches |
| `/frontend-audit` | Frontend style audit (TypeScript/JS/CSS) |
| `/backend-audit` | Backend style audit (Go/Python/C#/TS) |
| `/doc-audit` | Documentation freshness — docs vs. implementation drift |
| `/security-review` | OWASP Top 10 vulnerability scan |

---

### /quick — Fast Implementation

**Gate:** None (always available — pipeline-aware, never blocked)
**Writes:** nothing
**Model:** Sonnet (default) | Opus with `--deep`

Implements small features, bug fixes, typo corrections, config tweaks, or any well-understood change that does not require the full pipeline. Completely independent of the brief → design → review → plan → build → qa flow.

If a pipeline is active in the current project, a warning is shown before proceeding — you decide whether to continue.

```
/quick fix the null check in UserCard.tsx
/quick --deep refactor the auth middleware   # escalates to Opus
/quick                                        # prompts for task description
```

After implementing, offers an optional lightweight audit on touched files only: LSP diagnostics, security spot-check on changed code, and a reminder to run existing tests if they exist. No `.pipeline/` artifacts written.

**Pipeline warnings:**

| Active state | Warning shown |
|---|---|
| Build in progress | `⚠ Build in progress — /quick may conflict with active builders if touching the same files.` |
| QA phase | `Pipeline at QA phase — /quick will not affect pipeline artifacts.` |
| Planning/design phases | Informational note, no risk |

---

### /init — Project Boilerplate

**Gate:** None (always available)
**Writes:** `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`
**Model:** Sonnet

Scaffolds best-practice project boilerplate adapted to the current project. Extracts context from `package.json`, `go.mod`, `requirements.txt`, `*.csproj`, `.git/config`, and existing files. Falls back to clearly marked placeholders (`[DESCRIPTION]`, `[AUTHOR]`, etc.) for anything it can't detect.

```
/init
```

Asks before touching any file that already exists: **Overwrite / Skip / Merge**. Merge shows a diff before writing.

**Generated files:**

| File | Standard |
|------|---------|
| `README.md` | Title, description, install (language-aware), usage, contributing, license |
| `CHANGELOG.md` | [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format |
| `CONTRIBUTING.md` | Branching ([Conventional Branch](https://conventional-branch.github.io/)), commits ([Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)), PR process |
| `.github/pull_request_template.md` | Type of change, testing checklist, verification evidence, spec compliance checklist |

---

### /git-workflow — Git Discipline

**Gate:** None (always available)
**Writes:** nothing
**Model:** inherits from calling context

Enforces correct branching, commit message format, and safety checks before any significant git operation. Detects whether the project is code (trunk-based) or infrastructure (three-environment) and loads the appropriate workflow reference.

```
/git-workflow     # standalone — run before branch creation, first push, PR open/merge,
                  # or any destructive operation (force-push, reset --hard, branch -D)
```

Also referenced in `/build` (builders invoke it before committing) and `/quick` (invoked during self-review before committing).

**Project type detection:**

| Signal | Workflow |
|--------|---------|
| `*.tf`, `*.tfvars`, `Chart.yaml`, `helm/`, `terraform/` | Three-environment: development → preproduction → main |
| `*.ts`, `*.js`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.cs` | Trunk-based: feature branch → main |
| Ambiguous | Asks you to confirm |

**Safety gate — blocks or asks confirmation for:**
- Non-conforming branch names or commit messages (rewrites message before proceeding)
- Destructive operations (force-push, reset --hard, branch -D)
- Direct push to protected branches (main, master, development, preproduction)

---

### /status — Pipeline State Check

**Gate:** None (always available)
**Writes:** nothing
**Model:** inherits from calling context

Reports the current pipeline phase based on which `.pipeline/` artifacts exist. Run `/status` at any point to know where you are and what to run next.

```
/status
```

Example output:

```
Pipeline status: Plan ready / build in progress

  brief.md         ✓ exists
  design.md        ✓ exists
  design.approved  ✓ exists
  plan.md          ✓ exists
  build.complete   ✗ missing

Next: Run /build
```

---

## Language Support Matrix

What each optional LSP adds per skill:

| LSP | /cleanup | /frontend-audit | /backend-audit | /review | /build | /security-review |
|-----|---------|-----|-----|-----|--------|-----------------|
| TypeScript | Definitive unused symbols | Type-aware audit | Type errors | Type-grounded critique | Accurate refactoring | Taint analysis |
| Go | Definitive unused symbols | — | Unused imports, diagnostics | Code-grounded critique | Accurate refactoring | Taint analysis |
| Python | Definitive unused imports | — | Type annotation gaps | Code-grounded critique | Accurate refactoring | Taint analysis |
| C# | Definitive unused usings | — | Nullable warnings, naming | Code-grounded critique | Accurate refactoring | Taint analysis |

Without LSP: skills fall back to heuristic static analysis — still useful, less precise.

## End-to-End Walkthrough

Starting a new API endpoint feature:

```bash
# 1. Start a Claude Code session in your project directory
cd ~/my-project
claude

# 2. Crystallize your idea
/brief
# Opus asks: What does this endpoint do? → answer
# Opus asks: What's the input/output shape? → answer
# ... Q&A continues ...
# Brief written to .pipeline/brief.md

# 3. Design it
/design
# Opus reads brief, calls Context7 for your framework's docs
# Opus classifies constraints, reconstructs optimal approach
# Iterates until you say "looks good"
# Design written to .pipeline/design.md

# 4. Stress-test the design
/review
# Opus and Codex critique in parallel
# Lead deduplicates, runs cost/benefit on each finding
# You review the report, iterate until resolved
# .pipeline/design.approved written

# 5. Plan the build
/plan
# Opus writes an execution doc with exact file paths and test cases
# Plan written to .pipeline/plan.md

# 6. Build it
/build --parallel
# Sonnets build in parallel, Opus coordinates
# /drift-check runs post-build
# .pipeline/build.complete written

# 7. Clean and audit
/qa --parallel
# All QA skills run simultaneously
# Review findings, fix what's flagged
```

## Mode Flag Guide

### When to use --parallel

Use `--parallel` when:
- Task groups in the plan have no file conflicts between them
- The plan explicitly flags groups as "safe for parallel"
- You want fastest wall-clock time and don't need to debug mid-build

Use `/qa --parallel` when:
- You want all audits in one shot
- The audits are independent (they always are — different concerns)

### When to use --sequential

Use `--sequential` when:
- Task groups have dependencies (one must complete before another can start)
- You want to review and potentially intervene between tasks
- Debugging a previous build that failed mid-way

Use `/qa --sequential` when:
- You want to review each audit's output before running the next
- One audit's output informs what to fix before running the next

## Troubleshooting

### "No brief found. Run /brief first"

You tried to run `/design` without a brief. Run `/brief` first.

### "Design not approved. Run /review and iterate until all findings resolve."

You tried to run `/plan` without going through `/review`. Run `/review` and iterate until the review loop resolves.

### Gate is not firing (hook not active)

1. Verify the plugin is installed: in Claude Code, run `/plugin list` and confirm `claude-agents-custom@local-dev` appears.
2. Restart Claude Code — hooks are loaded at startup.
3. Check that `hooks/pipeline_gate.sh` is executable: `ls -la ~/claude-agents-custom/hooks/`
4. Check `hooks/hooks.json` is valid: `python3 -m json.tool ~/claude-agents-custom/hooks/hooks.json`

### OpenAI MCP tools not appearing

1. Verify your `OPENAI_API_KEY` is set correctly in the MCP server config.
2. Run `claude` and check the startup output for MCP connection errors.
3. Try: `npx -y @openai/mcp-server` directly to verify the package installs and starts.

### Resetting pipeline state

```bash
# Full reset
rm -rf .pipeline/

# Partial reset (see .pipeline/ State Directory section above)
```

### Plugin not loading after changes

```bash
/plugin uninstall claude-agents-custom@local-dev
/plugin install claude-agents-custom@local-dev
# Restart Claude Code
```
