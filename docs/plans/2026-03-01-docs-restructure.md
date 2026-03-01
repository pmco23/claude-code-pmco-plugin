# Documentation Restructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Slim `README.md` from 638 lines to ~100 lines by extracting all detailed content into `docs/guides/` (4 files) and `docs/skills/` (19 files).

**Architecture:** Pure file creation and editing — no code changes. Content is moved verbatim from README sections into new files; README is rewritten last. No content is lost, only reorganized.

**Tech Stack:** Markdown only.

---

### Task 1: Create `docs/guides/mcp-setup.md`

**Files:**
- Create: `docs/guides/mcp-setup.md`

**Step 1: Create the file**

Write `docs/guides/mcp-setup.md` with this exact content:

```markdown
# MCP Setup

MCP registration for all three servers is handled automatically by the plugin. You only need to install the binaries and (for Grafana) set environment variables.

## Codex MCP

### Install Codex CLI

```bash
npm install -g @openai/codex
```

### Troubleshooting — Codex server not connecting

If Codex was installed via nvm, the `codex` binary may not be on PATH in non-interactive shells. Fix by using the absolute path:

```bash
# Find the path
which codex

# Edit ~/.claude/settings.json — replace "command": "codex" with the absolute path
# under the mcpServers entry for your plugin installation path
```

## Repomix MCP

### Install Repomix

```bash
npm install -g repomix
```

### Troubleshooting — Repomix server not connecting

If Repomix was installed via nvm, the `repomix` binary may not be on PATH in non-interactive shells. Fix by using the absolute path:

```bash
# Find the path
which repomix

# Edit ~/.claude/settings.json — replace "command": "repomix" with the absolute path
# under the mcpServers entry for your plugin installation path
```

## Grafana MCP

### Install uv

```bash
# macOS / Linux
brew install uv
# or
pip install uv
```

### Set environment variables

Add these to your shell profile (`.bashrc`, `.zshrc`, etc.):

```bash
export GRAFANA_URL=http://localhost:3000
export GRAFANA_SERVICE_ACCOUNT_TOKEN=<your-token>
```

Restart Claude Code after setting the variables so the MCP server picks them up.

### Troubleshooting — Grafana server not connecting

If `uvx` is not on PATH in non-interactive shells, fix by using the absolute path:

```bash
# Find the path
which uvx

# Edit ~/.claude/settings.json — replace "command": "uvx" with the absolute path
# under the mcpServers entry for your plugin installation path
```

If the MCP server starts but tools return auth errors, verify `GRAFANA_SERVICE_ACCOUNT_TOKEN` is exported (not just set) and that the token has the required Grafana permissions.
```

**Step 2: Verify**

Read `docs/guides/mcp-setup.md` and confirm all three MCP sections are present (Codex, Repomix, Grafana) each with install and troubleshooting subsections.

**Step 3: Commit**

```bash
git add docs/guides/mcp-setup.md
git commit -m "docs: add docs/guides/mcp-setup.md — Codex, Repomix, Grafana MCP setup"
```

---

### Task 2: Create `docs/guides/installation.md`

**Files:**
- Create: `docs/guides/installation.md`

**Step 1: Create the file**

Write `docs/guides/installation.md` with this exact content:

```markdown
# Installation

## Step 1: Add the development marketplace

```bash
claude
/plugin marketplace add ~/claude-agents-custom
```

## Step 2: Install the plugin

```
/plugin install claude-agents-custom@local-dev
```

## Step 3: Restart Claude Code

Quit and reopen. The skills will appear in the skill list and the gate hook will be active.

## Step 4: Verify installation

```bash
# In a Claude Code session:
/brief
```

You should see the brief skill start a Q&A session. If the gate hook is active, trying `/design` before running `/brief` will show a block message.

## Statusline Setup

The statusline hook shows model, current task, pipeline phase, directory, and context usage in the Claude Code status bar.

Add this to `~/.claude/settings.json` (one-time global setup):

```json
"statusline": {
  "command": "node ~/claude-agents-custom/hooks/statusline.js"
}
```

> **Note:** Replace `~/claude-agents-custom` with your actual install path. Run `/plugin list` in a Claude Code session to see the installed path.

Restart Claude Code. The statusline will appear immediately.

**Example output:**

```
claude-sonnet-4-6 │ Implementing auth │ plan ready │ my-project ████░░░░░░ 42%
```

The context bar turns yellow above 63%, orange above 81%, and red-blinking with 💀 above 95%. A PostToolUse hook also injects context warnings directly into Claude's context when thresholds are exceeded.

## Reinstalling after changes

```bash
/plugin uninstall claude-agents-custom@local-dev
/plugin install claude-agents-custom@local-dev
# Restart Claude Code
```
```

**Step 2: Verify**

Read `docs/guides/installation.md` and confirm it has: 4-step install, statusline setup, reinstall instructions.

**Step 3: Commit**

```bash
git add docs/guides/installation.md
git commit -m "docs: add docs/guides/installation.md — full install and statusline setup"
```

---

### Task 3: Create `docs/guides/walkthrough.md`

**Files:**
- Create: `docs/guides/walkthrough.md`

**Step 1: Create the file**

Write `docs/guides/walkthrough.md` with this exact content:

```markdown
# Walkthrough and Reference

## The .pipeline/ State Directory

Each pipeline phase writes a state artifact to `.pipeline/` in your project root. This is how the hook knows where you are in the pipeline.

```
.pipeline/
├── brief.md          # written by /brief
├── design.md         # written by /design
├── design.approved   # written by /review when review loop resolves
├── plan.md           # written by /plan
├── build.complete    # written by /build after /drift-check passes
└── repomix-pack.json # written by /pack or auto-generated by /qa preamble
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

## Language Support Matrix

What each optional LSP adds per skill:

| LSP | /cleanup | /frontend-audit | /backend-audit | /review | /build | /security-review |
|-----|---------|-----|-----|-----|--------|-----------------|
| TypeScript | Definitive unused symbols | Type-aware audit | Type errors | Type-grounded critique | Accurate refactoring | Taint analysis |
| Go | Definitive unused symbols | — | Unused imports, diagnostics | Code-grounded critique | Accurate refactoring | Taint analysis |
| Python | Definitive unused imports | — | Type annotation gaps | Code-grounded critique | Accurate refactoring | Taint analysis |
| C# | Definitive unused usings | — | Nullable warnings, naming | Code-grounded critique | Accurate refactoring | Taint analysis |

Without LSP: skills fall back to heuristic static analysis — still useful, less precise.
```

**Step 2: Verify**

Read `docs/guides/walkthrough.md` and confirm it has: .pipeline/ reference, end-to-end walkthrough, mode flag guide, language matrix.

**Step 3: Commit**

```bash
git add docs/guides/walkthrough.md
git commit -m "docs: add docs/guides/walkthrough.md — pipeline reference, walkthrough, mode flags, language matrix"
```

---

### Task 4: Create `docs/guides/troubleshooting.md`

**Files:**
- Create: `docs/guides/troubleshooting.md`

**Step 1: Create the file**

Write `docs/guides/troubleshooting.md` with this exact content:

```markdown
# Troubleshooting

## "No brief found. Run /brief first"

You tried to run `/design` without a brief. Run `/brief` first.

## "Design not approved. Run /review and iterate until all findings resolve."

You tried to run `/plan` without going through `/review`. Run `/review` and iterate until the review loop resolves.

## Gate is not firing (hook not active)

1. Verify the plugin is installed: in Claude Code, run `/plugin list` and confirm `claude-agents-custom@local-dev` appears.
2. Restart Claude Code — hooks are loaded at startup.
3. Check that `hooks/pipeline_gate.sh` is executable: `ls -la ~/claude-agents-custom/hooks/`
4. Check `hooks/hooks.json` is valid: `python3 -m json.tool ~/claude-agents-custom/hooks/hooks.json`

## Codex MCP not connecting

1. Run `which codex` — if not found, install with `npm install -g @openai/codex`.
2. Run `claude` and check the startup output for MCP connection errors.
3. If installed via nvm, replace `"command": "codex"` with the absolute path in `~/.claude/settings.json` (see [Codex MCP setup](mcp-setup.md#codex-mcp)).

## Resetting pipeline state

```bash
# Full reset
rm -rf .pipeline/

# Partial reset — see .pipeline/ reference in walkthrough.md
```

## Verifying gate logic

Run `hooks/test_gate.sh` to confirm all pipeline gate rules are working correctly:

```bash
bash ~/claude-agents-custom/hooks/test_gate.sh
```

Expected: `Results: 49 passed, 0 failed`

## Plugin not loading after changes

```bash
/plugin uninstall claude-agents-custom@local-dev
/plugin install claude-agents-custom@local-dev
# Restart Claude Code
```
```

**Step 2: Verify**

Read `docs/guides/troubleshooting.md` and confirm all 6 troubleshooting entries are present.

**Step 3: Commit**

```bash
git add docs/guides/troubleshooting.md
git commit -m "docs: add docs/guides/troubleshooting.md"
```

---

### Task 5: Create `docs/skills/` — pipeline skills

**Files:**
- Create: `docs/skills/brief.md`
- Create: `docs/skills/design.md`
- Create: `docs/skills/review.md`
- Create: `docs/skills/plan.md`
- Create: `docs/skills/drift-check.md`
- Create: `docs/skills/build.md`
- Create: `docs/skills/qa.md`

**Step 1: Create `docs/skills/brief.md`**

```markdown
# /brief — Requirements Crystallization

**Gate:** None (always available)
**Writes:** `.pipeline/brief.md`
**Model:** Opus

Extracts requirements, constraints, non-goals, style preferences, and key concepts from fuzzy input through conversational Q&A. Detects your project language and available LSP tools. Ends with a forced-choice checkpoint to resolve remaining ambiguities before writing the brief.

## Usage

```
/brief
```
```

**Step 2: Create `docs/skills/design.md`**

```markdown
# /design — First-Principles Design

**Gate:** `.pipeline/brief.md` must exist
**Writes:** `.pipeline/design.md`
**Model:** Opus
**Tools used:** Context7, web search, LSP (if available)

Reads the brief and performs first-principles analysis. Classifies every constraint as hard or soft. Flags soft constraints being treated as hard. Grounds all library and pattern recommendations in live docs via Context7 before drawing conclusions. Iterates with you until alignment. Output is a formal design document.

## Usage

```
/design
```
```

**Step 3: Create `docs/skills/review.md`**

```markdown
# /review — Adversarial Review

**Gate:** `.pipeline/design.md` must exist
**Writes:** `.pipeline/design.approved` (on loop exit)
**Models:** Opus (strategic critique) + Codex via Codex MCP (code-grounded critique)
**Tools used:** Context7, filesystem

Dispatches Opus and Codex in parallel. Each critiques the design from a different angle. Lead Opus deduplicates findings, fact-checks each against the actual codebase, runs cost/benefit analysis, and outputs a structured report. Loop continues until no remaining findings warrant mitigation.

## Usage

```
/review
```
```

**Step 4: Create `docs/skills/plan.md`**

```markdown
# /plan — Atomic Execution Planning

**Gate:** `.pipeline/design.approved` must exist
**Writes:** `.pipeline/plan.md`
**Model:** Opus

Transforms the approved design into an execution document precise enough that build agents never ask clarifying questions. ~5 tasks per agent group. Exact file paths. Complete code examples. Named test cases with setup and assertions defined at plan time. Flags which task groups are safe for parallel execution.

## Usage

```
/plan
```
```

**Step 5: Create `docs/skills/drift-check.md`**

```markdown
# /drift-check — Drift Detection

**Gate:** `.pipeline/plan.md` must exist
**Writes:** nothing (report only)
**Models:** Sonnet (agent 1) + Codex via Codex MCP (agent 2) + Opus (lead)

Two agents independently extract claims from a source-of-truth document and verify each against a target. Lead reconciles conflicts and mitigates drift.

## Usage

```
/drift-check
```
```

**Step 6: Create `docs/skills/build.md`**

```markdown
# /build — Parallel Build

**Gate:** `.pipeline/plan.md` must exist
**Writes:** `.pipeline/build.complete` (after /drift-check passes)
**Models:** Opus (lead) + Sonnet (builders)
**Flags:** `--parallel` | `--sequential`

Lead Opus coordinates and unblocks. Never writes implementation code. Runs /drift-check post-build. Writes `build.complete` only when /drift-check passes.

## Usage

```
/build --parallel     # Sonnets in independent agents, own context each
/build --sequential   # Task groups executed one at a time, current session
/build                # Prompts you to choose
```
```

**Step 7: Create `docs/skills/qa.md`**

```markdown
# /qa — Post-Build QA Pipeline

**Gate:** `.pipeline/build.complete` must exist
**Flags:** `--parallel` | `--sequential`

## Usage

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
```

**Step 8: Verify**

Confirm all 7 files exist under `docs/skills/` and each contains the correct gate, writes, model, and usage content.

**Step 9: Commit**

```bash
git add docs/skills/brief.md docs/skills/design.md docs/skills/review.md docs/skills/plan.md docs/skills/drift-check.md docs/skills/build.md docs/skills/qa.md
git commit -m "docs: add docs/skills/ — pipeline skills (brief, design, review, plan, drift-check, build, qa)"
```

---

### Task 6: Create `docs/skills/` — QA sub-skills

**Files:**
- Create: `docs/skills/cleanup.md`
- Create: `docs/skills/frontend-audit.md`
- Create: `docs/skills/backend-audit.md`
- Create: `docs/skills/doc-audit.md`
- Create: `docs/skills/security-review.md`

**Step 1: Create `docs/skills/cleanup.md`**

```markdown
# /cleanup — Dead Code Removal

**Gate:** `.pipeline/build.complete` must exist
**Writes:** nothing
**Model:** inherits from calling context

Strips dead code, unused imports, and unreachable branches. Run standalone or as part of `/qa`.

## Usage

```
/cleanup
```
```

**Step 2: Create `docs/skills/frontend-audit.md`**

```markdown
# /frontend-audit — Frontend Style Audit

**Gate:** `.pipeline/build.complete` must exist
**Writes:** nothing
**Model:** inherits from calling context

Frontend style audit covering TypeScript/JS/CSS. Run standalone or as part of `/qa`.

## Usage

```
/frontend-audit
```
```

**Step 3: Create `docs/skills/backend-audit.md`**

```markdown
# /backend-audit — Backend Style Audit

**Gate:** `.pipeline/build.complete` must exist
**Writes:** nothing
**Model:** inherits from calling context

Backend style audit covering Go, Python, C#, and TypeScript. Run standalone or as part of `/qa`.

## Usage

```
/backend-audit
```
```

**Step 4: Create `docs/skills/doc-audit.md`**

```markdown
# /doc-audit — Documentation Freshness Audit

**Gate:** `.pipeline/build.complete` must exist
**Writes:** nothing
**Model:** inherits from calling context

Checks documentation freshness — detects drift between docs and implementation. Run standalone or as part of `/qa`.

## Usage

```
/doc-audit
```
```

**Step 5: Create `docs/skills/security-review.md`**

```markdown
# /security-review — OWASP Vulnerability Scan

**Gate:** `.pipeline/build.complete` must exist
**Writes:** nothing
**Model:** inherits from calling context

OWASP Top 10 vulnerability scan on the implementation. Run standalone or as part of `/qa`.

## Usage

```
/security-review
```
```

**Step 6: Verify**

Confirm all 5 files exist under `docs/skills/` with correct gate and description.

**Step 7: Commit**

```bash
git add docs/skills/cleanup.md docs/skills/frontend-audit.md docs/skills/backend-audit.md docs/skills/doc-audit.md docs/skills/security-review.md
git commit -m "docs: add docs/skills/ — QA sub-skills (cleanup, frontend-audit, backend-audit, doc-audit, security-review)"
```

---

### Task 7: Create `docs/skills/` — standalone skills

**Files:**
- Create: `docs/skills/quick.md`
- Create: `docs/skills/init.md`
- Create: `docs/skills/git-workflow.md`
- Create: `docs/skills/plugin-architecture.md`
- Create: `docs/skills/status.md`
- Create: `docs/skills/pack.md`
- Create: `docs/skills/grafana.md`

**Step 1: Create `docs/skills/quick.md`**

```markdown
# /quick — Fast Implementation

**Gate:** None (always available — pipeline-aware, never blocked)
**Writes:** nothing
**Model:** Sonnet (default) | Opus with `--deep`

Implements small features, bug fixes, typo corrections, config tweaks, or any well-understood change that does not require the full pipeline. Completely independent of the brief → design → review → plan → build → qa flow.

If a pipeline is active in the current project, a warning is shown before proceeding — you decide whether to continue.

After implementing, offers an optional lightweight audit on touched files only: LSP diagnostics, security spot-check on changed code, and a reminder to run existing tests if they exist. No `.pipeline/` artifacts written.

## Usage

```
/quick fix the null check in UserCard.tsx
/quick --deep refactor the auth middleware   # escalates to Opus
/quick                                        # prompts for task description
```

## Pipeline warnings

| Active state | Warning shown |
|---|---|
| Build in progress | `⚠ Build in progress — /quick may conflict with active builders if touching the same files.` |
| QA phase | `Pipeline at QA phase — /quick will not affect pipeline artifacts.` |
| Planning/design phases | Informational note, no risk |
```

**Step 2: Create `docs/skills/init.md`**

```markdown
# /init — Project Boilerplate

**Gate:** None (always available)
**Writes:** `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`
**Model:** Sonnet

Scaffolds best-practice project boilerplate adapted to the current project. Extracts context from `package.json`, `go.mod`, `requirements.txt`, `*.csproj`, `.git/config`, and existing files. Falls back to clearly marked placeholders (`[DESCRIPTION]`, `[AUTHOR]`, etc.) for anything it can't detect.

Asks before touching any file that already exists: **Overwrite / Skip / Merge**. Merge shows a diff before writing.

## Usage

```
/init
```

## Generated files

| File | Standard |
|------|---------|
| `README.md` | Title, description, install (language-aware), usage, contributing, license |
| `CHANGELOG.md` | [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format |
| `CONTRIBUTING.md` | Branching ([Conventional Branch](https://conventional-branch.github.io/)), commits ([Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)), PR process |
| `.github/pull_request_template.md` | Type of change, testing checklist, verification evidence, spec compliance checklist |
```

**Step 3: Create `docs/skills/git-workflow.md`**

```markdown
# /git-workflow — Git Discipline

**Gate:** None (always available)
**Writes:** nothing
**Model:** inherits from calling context

Enforces correct branching, commit message format, and safety checks before any significant git operation. Detects whether the project is code (trunk-based) or infrastructure (three-environment) and loads the appropriate workflow reference.

Also referenced in `/build` (builders invoke it before committing) and `/quick` (invoked during self-review before committing).

## Usage

```
/git-workflow     # standalone — run before branch creation, first push, PR open/merge,
                  # or any destructive operation (force-push, reset --hard, branch -D)
```

## Project type detection

| Signal | Workflow |
|--------|---------|
| `*.tf`, `*.tfvars`, `Chart.yaml`, `helm/`, `terraform/` | Three-environment: development → preproduction → main |
| `*.ts`, `*.js`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.cs` | Trunk-based: feature branch → main |
| Ambiguous | Asks you to confirm |

## Safety gate

Blocks or asks confirmation for:
- Non-conforming branch names or commit messages (rewrites message before proceeding)
- Destructive operations (force-push, reset --hard, branch -D)
- Direct push to protected branches (main, master, development, preproduction)
```

**Step 4: Create `docs/skills/plugin-architecture.md`**

```markdown
# /plugin-architecture — Plugin Architecture Guide

**Gate:** None (always available)
**Writes:** nothing
**Model:** inherits from calling context

Decision guide for when to use skills vs agents in Claude Code plugin development. Covers the fitness criterion (self-contained + read-only + verbose output), the thin wrapper and split patterns, agent frontmatter format, composition rules, and anti-patterns. Run when designing a new plugin component or evaluating whether an existing skill should become an agent.

## Usage

```
/plugin-architecture
```
```

**Step 5: Create `docs/skills/status.md`**

```markdown
# /status — Pipeline State Check

**Gate:** None (always available)
**Writes:** nothing
**Model:** inherits from calling context

Reports the current pipeline phase based on which `.pipeline/` artifacts exist, including file age for each artifact and Repomix pack stats. Run at any point to know where you are and what to run next.

## Usage

```
/status
```

## Example output

```
Pipeline status: Plan ready / build in progress

  brief.md         ✓ 2h 14m old
  design.md        ✓ 1h 52m old
  design.approved  ✓ 1h 30m old
  plan.md          ✓ 23m old
  build.complete   ✗ missing
  repomix-pack     ✓ 18m old — 142 files, 28400 tokens

Next: Run /build
```
```

**Step 6: Create `docs/skills/pack.md`**

```markdown
# /pack — Repomix Codebase Snapshot

**Gate:** None (always available — requires Repomix MCP)
**Writes:** `.pipeline/repomix-pack.json`
**Model:** inherits from calling context

Packs the local codebase using Repomix MCP and stores the outputId in `.pipeline/repomix-pack.json`. Run before `/qa` to share one compressed pack across all five audit agents (significant token reduction via Tree-sitter compression — ratio reported after each pack). `/qa` automatically uses the stored pack if it is less than 1 hour old.

If Repomix MCP is not installed, this skill will fail. Other skills (`/qa`, `/plan`, `/brief`) fall back to native file tools when no pack is available.

## Usage

```
/pack              # pack current working directory
/pack src/         # pack a subdirectory
```
```

**Step 7: Create `docs/skills/grafana.md`**

```markdown
# /grafana — Grafana SRE Toolbox

**Gate:** None (always available — requires Grafana MCP)
**Writes:** nothing
**Model:** inherits from calling context

Accepts a free-text observability task and works through it using a ReAct loop (Reason → Act → Observe → Decide). Knows its full tool catalogue upfront: dashboards, Prometheus/Loki querying, alerting, Sift investigations, log search, deeplink generation, and panel rendering. Handles both single-step queries and multi-hop investigations.

Requires `GRAFANA_URL` and `GRAFANA_SERVICE_ACCOUNT_TOKEN` to be exported in the shell environment. See the [Grafana MCP setup guide](../guides/mcp-setup.md#grafana-mcp).

## Usage

```
/grafana what alerts are currently firing?
/grafana show me the p99 latency for service checkout over the last hour
/grafana find dashboards related to postgres and render the connections panel
/grafana search for error patterns in logs for the auth service
```
```

**Step 8: Verify**

Confirm all 7 files exist under `docs/skills/` with correct content.

**Step 9: Commit**

```bash
git add docs/skills/quick.md docs/skills/init.md docs/skills/git-workflow.md docs/skills/plugin-architecture.md docs/skills/status.md docs/skills/pack.md docs/skills/grafana.md
git commit -m "docs: add docs/skills/ — standalone skills (quick, init, git-workflow, plugin-architecture, status, pack, grafana)"
```

---

### Task 8: Rewrite `README.md`

**Files:**
- Modify: `README.md`

**Step 1: Read the current README**

Read `README.md` in full before editing to confirm the existing content.

**Step 2: Replace the entire file**

Write `README.md` with this exact content:

```markdown
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
 ├─ /grafana <task>          # Grafana SRE toolbox — dashboards, metrics, logs, alerts, Sift
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
| Grafana MCP | Grafana observability access for `/grafana` | [MCP setup →](docs/guides/mcp-setup.md#grafana-mcp) |

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
```

**Step 3: Verify**

Read `README.md` and confirm:
- Line count is under 110 lines
- Pipeline diagram is intact
- Prerequisites table links to `docs/guides/mcp-setup.md` (not inline `#codex-mcp-setup` anchors)
- Quick Install section has 3-step bash block
- Documentation section has 4 guide rows and 19 skill rows
- No MCP setup sections, no Command Reference, no walkthrough, no troubleshooting inline

**Step 4: Run line count check**

```bash
wc -l README.md
```

Expected: under 110 lines.

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: slim README to ~100 lines — detailed content moved to docs/guides/ and docs/skills/"
```
