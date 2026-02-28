# Pipeline Plugin Implementation Plan

**Goal:** Build a standalone Claude Code plugin that enforces a quality-gated development pipeline via skills and a PreToolUse hook script.

**Architecture:** Vanilla plugin with no external skill dependencies. Skills are SKILL.md files; gates are enforced by a single bash hook script that checks `.pipeline/` state artifacts. Three build phases ordered by complexity: simple single-agent skills first, then external-tool-integrated skills, then multi-agent orchestration skills.

**Tech Stack:** Claude Code plugin system (SKILL.md + hooks/hooks.json + .claude-plugin/plugin.json), bash for the gate hook, OpenAI MCP (pre-configured by user) for Codex, Context7 plugin (pre-installed) for live docs.

---

## Phase 1 — Foundation

### Task 1: Plugin Scaffold

**Files:**
- Create: `claude-agents-custom/.claude-plugin/plugin.json`
- Create: `claude-agents-custom/.claude-plugin/marketplace.json`
- Create all skill directories

**Step 1: Create the directory structure**

```bash
cd ~/claude-agents-custom
mkdir -p .claude-plugin
mkdir -p skills/arm
mkdir -p skills/design
mkdir -p skills/ar
mkdir -p skills/plan
mkdir -p skills/pmatch
mkdir -p skills/build
mkdir -p skills/qa
mkdir -p skills/denoise
mkdir -p skills/qf
mkdir -p skills/qb
mkdir -p skills/qd
mkdir -p skills/security-review
mkdir -p hooks
```

**Step 2: Write plugin.json**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "claude-agents-custom",
  "version": "1.0.0",
  "description": "Quality-gated development pipeline: arm → design → ar → plan → build → qa",
  "author": {
    "name": "pemcoliveira"
  },
  "keywords": ["pipeline", "quality-gates", "tdd", "adversarial-review"]
}
```

**Step 3: Write marketplace.json**

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "local-dev",
  "plugins": [
    {
      "name": "claude-agents-custom",
      "source": "./"
    }
  ]
}
```

**Step 4: Validate JSON**

```bash
python3 -m json.tool .claude-plugin/plugin.json > /dev/null && echo "plugin.json OK"
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo "marketplace.json OK"
```

Expected: both print OK with no errors.

---

### Task 2: Pipeline Gate Hook

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/pipeline_gate.sh`
- Create: `hooks/test_gate.sh`

**Step 1: Write hooks.json**

Create `hooks/hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/pipeline_gate.sh\""
          }
        ]
      }
    ]
  }
}
```

**Step 2: Write pipeline_gate.sh**

Create `hooks/pipeline_gate.sh`:

```bash
#!/usr/bin/env bash
# pipeline_gate.sh
# Enforces quality gates for the development pipeline.
# Reads PreToolUse JSON from stdin; blocks if required .pipeline/ artifact is missing.

set -euo pipefail

INPUT=$(cat)

# Extract skill name from JSON payload
SKILL=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    skill = d.get('tool_input', {}).get('skill', '')
    print(skill)
except Exception:
    print('')
" 2>/dev/null || echo "")

# Not a skill invocation or parse failed — allow
if [ -z "$SKILL" ]; then
  exit 0
fi

# Walk up from cwd to find .pipeline/ directory
find_pipeline_dir() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.pipeline" ]; then
      echo "$dir/.pipeline"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  echo "$PWD/.pipeline"
}

PIPELINE_DIR=$(find_pipeline_dir)

block() {
  local message="$1"
  echo "PIPELINE GATE BLOCKED: $message" >&2
  echo "$message"
  exit 2
}

case "$SKILL" in
  "design")
    [ -f "$PIPELINE_DIR/brief.md" ] || block "No brief found. Run /arm first to crystallize requirements into a brief."
    ;;
  "ar")
    [ -f "$PIPELINE_DIR/design.md" ] || block "No design doc found. Run /design first."
    ;;
  "plan")
    [ -f "$PIPELINE_DIR/design.approved" ] || block "Design not approved. Run /ar and iterate until all findings resolve."
    ;;
  "build"|"pmatch")
    [ -f "$PIPELINE_DIR/plan.md" ] || block "No execution plan found. Run /plan first."
    ;;
  "denoise"|"qf"|"qb"|"qd"|"security-review"|"qa")
    [ -f "$PIPELINE_DIR/build.complete" ] || block "Build not complete. Run /build first, then ensure /pmatch passes."
    ;;
esac

exit 0
```

**Step 3: Make hook executable**

```bash
chmod +x hooks/pipeline_gate.sh
```

**Step 4: Write test script**

Create `hooks/test_gate.sh`:

```bash
#!/usr/bin/env bash
# Tests the pipeline gate logic against all gate scenarios.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/pipeline_gate.sh"
TMPDIR=$(mktemp -d)
PASS=0
FAIL=0

run_gate() {
  local skill="$1"
  local pipeline_dir="$2"
  echo "{\"tool_input\":{\"skill\":\"$skill\"}}" | PIPELINE_TEST_DIR="$pipeline_dir" bash "$GATE"
  return $?
}

expect_block() {
  local skill="$1"
  local pipeline_dir="$2"
  local desc="$3"
  if run_gate "$skill" "$pipeline_dir" > /dev/null 2>&1; then
    echo "FAIL: $desc — expected block, got allow"
    FAIL=$((FAIL+1))
  else
    echo "PASS: $desc"
    PASS=$((PASS+1))
  fi
}

expect_allow() {
  local skill="$1"
  local pipeline_dir="$2"
  local desc="$3"
  if run_gate "$skill" "$pipeline_dir" > /dev/null 2>&1; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc — expected allow, got block"
    FAIL=$((FAIL+1))
  fi
}

# /arm — always allowed
expect_allow "arm" "$TMPDIR" "/arm with no .pipeline dir: allow"

# /design — requires brief.md
empty_dir=$(mktemp -d)
expect_block "design" "$empty_dir" "/design with no brief: block"
mkdir -p "$empty_dir/.pipeline" && touch "$empty_dir/.pipeline/brief.md"
expect_allow "design" "$empty_dir" "/design with brief: allow"

# /ar — requires design.md
ar_dir=$(mktemp -d)
mkdir -p "$ar_dir/.pipeline" && touch "$ar_dir/.pipeline/design.md"
expect_allow "ar" "$ar_dir" "/ar with design.md: allow"
expect_block "ar" "$empty_dir" "/ar without design.md: block"

# /plan — requires design.approved
plan_dir=$(mktemp -d)
mkdir -p "$plan_dir/.pipeline" && touch "$plan_dir/.pipeline/design.approved"
expect_allow "plan" "$plan_dir" "/plan with design.approved: allow"
expect_block "plan" "$ar_dir" "/plan without design.approved: block"

# /build — requires plan.md
build_dir=$(mktemp -d)
mkdir -p "$build_dir/.pipeline" && touch "$build_dir/.pipeline/plan.md"
expect_allow "build" "$build_dir" "/build with plan.md: allow"
expect_block "build" "$plan_dir" "/build without plan.md: block"

# /qa and QA skills — require build.complete
qa_dir=$(mktemp -d)
mkdir -p "$qa_dir/.pipeline" && touch "$qa_dir/.pipeline/build.complete"
for skill in qa denoise qf qb qd security-review; do
  expect_allow "$skill" "$qa_dir" "/$skill with build.complete: allow"
  expect_block "$skill" "$build_dir" "/$skill without build.complete: block"
done

rm -rf "$TMPDIR" "$empty_dir" "$ar_dir" "$plan_dir" "$build_dir" "$qa_dir"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

**Step 5: Make test script executable and run it**

```bash
chmod +x hooks/test_gate.sh
bash hooks/test_gate.sh
```

Expected: all tests print PASS, exit 0.

> Note: The test script uses a `PIPELINE_TEST_DIR` env var as an override for the pipeline dir. You may need to adjust `pipeline_gate.sh` to respect this env var during testing. If tests fail on path resolution, modify the `find_pipeline_dir` function to check `$PIPELINE_TEST_DIR` first:
>
> ```bash
> find_pipeline_dir() {
>   if [ -n "${PIPELINE_TEST_DIR:-}" ]; then
>     echo "$PIPELINE_TEST_DIR/.pipeline"
>     return 0
>   fi
>   # ... rest of walk-up logic
> }
> ```

---

### Task 3: /arm Skill

**Files:**
- Create: `skills/arm/SKILL.md`

**Step 1: Write the skill**

Create `skills/arm/SKILL.md`:

````markdown
---
name: arm
description: Use when starting a new feature, project, or task - extracts requirements, constraints, non-goals, style preferences, and key concepts from fuzzy input through conversational Q&A. Output is a structured brief saved to .pipeline/brief.md. Always run this before /design.
---

# ARM — Requirements Crystallization

## Role

You are Opus acting as a requirements analyst. Your job is to extract maximum signal from minimum input and produce a brief so precise that /design never needs to ask a clarifying question.

## Process

### Step 1: Detect project context

Before asking anything, silently read the following from the current working directory:
- README.md (if present)
- Any existing `.pipeline/brief.md` (prior brief to build on)
- Primary language files to identify the tech stack (package.json, go.mod, requirements.txt, *.csproj)
- Any CLAUDE.md or project-specific instructions

Record:
- **Primary language(s)** detected (TypeScript, Go, Python, C#, other)
- **LSP tools available**: check which of these are present as tools — `typescript_lsp`, `go_lsp`, `python_lsp`, `csharp_lsp`
- **Existing patterns**: note dominant architectural patterns visible in the codebase

### Step 2: Extract signal through Q&A

Ask ONE question at a time. Wait for the answer before asking the next. Prefer multiple-choice when possible.

Cover these areas in order (skip if already clear from context):

1. **Core purpose** — What does this feature/change do? What problem does it solve?
2. **Users/consumers** — Who calls this? End users, other services, CLI, tests?
3. **Hard constraints** — What MUST be true? (latency, compatibility, existing interfaces)
4. **Soft constraints** — What SHOULD be true but could flex? Flag these explicitly.
5. **Non-goals** — What are you explicitly NOT building?
6. **Success criteria** — How will you know it works? What does done look like?
7. **Style preferences** — Any naming conventions, patterns, or anti-patterns to follow?
8. **Key concepts/domain terms** — Any domain vocabulary that must be used consistently?

### Step 3: Force remaining decisions

After Q&A, present a single structured checkpoint with any remaining ambiguities as forced-choice questions. No open-ended questions in this checkpoint — every item must have options. Do not proceed until the user has answered all items.

Format:
```
CHECKPOINT — Remaining decisions:

1. [Decision]: [Option A] / [Option B] / [Option C]
2. [Decision]: [Option A] / [Option B]
```

### Step 4: Write the brief

Write `.pipeline/brief.md` with this exact structure:

```markdown
# Brief: [Feature Name]

**Date:** [YYYY-MM-DD]
**Primary Language:** [language(s)]
**LSP Available:** [list or "none"]

## Requirements
[Bulleted list of what must be built]

## Constraints
### Hard Constraints (non-negotiable)
- [constraint]

### Soft Constraints (flexible, flagged)
- [constraint] — *soft: [reason it could flex]*

## Non-Goals
[Bulleted list of explicit exclusions]

## Success Criteria
[Bulleted list — measurable, specific]

## Style & Conventions
[Naming, patterns, anti-patterns to follow]

## Key Concepts
[Domain terms and their definitions]

## Open Questions
[Any unresolved items — should be empty after checkpoint]
```

## Output

Confirm to the user: "Brief written to `.pipeline/brief.md`. Run `/design` when ready."
````

**Step 2: Verify file exists and is valid markdown**

```bash
[ -f skills/arm/SKILL.md ] && echo "arm SKILL.md OK" || echo "MISSING"
head -5 skills/arm/SKILL.md
```

Expected: prints "arm SKILL.md OK" and the frontmatter header.

---

### Task 4: /denoise Skill

**Files:**
- Create: `skills/denoise/SKILL.md`

**Step 1: Write the skill**

Create `skills/denoise/SKILL.md`:

````markdown
---
name: denoise
description: Use after build is complete to strip dead code, unused imports, unreachable branches, and commented-out code. Requires .pipeline/build.complete. Safe to run standalone or as part of /qa pipeline.
---

# DENOISE — Dead Code Removal

## Role

You are Sonnet acting as a code cleaner. Remove confirmed dead code only. Do not refactor, rename, or restructure anything live.

## Process

### Step 1: Identify project language

Read `.pipeline/brief.md` to find the primary language. Check which LSP tools are available as tools in this session.

### Step 2: Find dead code

**If LSP is available** for the project language, use it:
- Request all unused symbol diagnostics
- Request all unreachable code diagnostics
- List unused imports via LSP

**If LSP is not available**, use static analysis:
- Search for symbols defined but never referenced (grep patterns)
- Look for commented-out code blocks (// TODO: remove, /* dead */, etc.)
- Find imports with no usages in the file
- Identify functions/methods with no callers (search for their name across codebase)

### Step 3: Confirm before removing

Present the dead code list to the user before making any changes:

```
Dead code found:
- [file:line] — [symbol/description] — [reason: unused/unreachable/no callers]
```

Ask: "Remove all of these? (yes / review each / skip)"

### Step 4: Remove confirmed dead code

For each confirmed item:
- Remove the dead symbol or block
- Remove any imports that become unused as a result
- Do not touch surrounding code

### Step 5: Verify

After removal, confirm no tests are broken:
- Check if there are test files (look for test/, tests/, *_test.go, *.test.ts, etc.)
- If tests exist, remind the user to run them: "Run your test suite to confirm no regressions."

## Output

Report: "Removed [N] dead code items across [M] files."
````

---

### Task 5: /qf Skill

**Files:**
- Create: `skills/qf/SKILL.md`

**Step 1: Write the skill**

Create `skills/qf/SKILL.md`:

````markdown
---
name: qf
description: Use after build is complete to audit frontend code against the project style guide. Checks TypeScript/JavaScript/CSS/HTML conventions, naming, component patterns, and accessibility basics. Requires .pipeline/build.complete.
---

# QF — Frontend Style Audit

## Role

You are Sonnet acting as a frontend code reviewer. Audit against the project's own style guide — not generic best practices. If no style guide exists, infer conventions from the existing codebase.

## Process

### Step 1: Find the style guide

Look for frontend style guidance in this order:
1. `STYLE.md`, `FRONTEND.md`, `docs/style-guide.md`, or similar
2. `.eslintrc*`, `.prettierrc*` — extract rules as style expectations
3. `CLAUDE.md` — any project-specific frontend rules
4. Infer from majority patterns in existing components

Record the style rules you will audit against. Present them to the user: "Auditing against these rules: [list]" before proceeding.

### Step 2: Audit with LSP if available

If `typescript_lsp` tool is available:
- Get all type errors and warnings
- Get all unused variable diagnostics
- Use type information to flag patterns that defeat the type system (any casts, @ts-ignore without justification)

### Step 3: Audit without LSP (or in addition)

Check:
- Naming conventions (components PascalCase, hooks usePrefix, etc.)
- Import organization (external before internal, grouped)
- Component size (flag components over 200 lines as candidates for extraction)
- Props patterns (no inline object literals in JSX if project avoids them)
- CSS/styling conventions (CSS modules vs. Tailwind vs. styled-components — match what's already used)
- Console.log statements left in production code
- TODO/FIXME comments that reference completed work

### Step 4: Report findings

Format each finding as:
```
[file:line] [RULE] [description]
```

Group by severity: Errors first, then Warnings, then Style.

If no findings: "Frontend audit complete — no violations found."

## Output

Report saved as text to user. No file written to `.pipeline/`.
````

---

### Task 6: /qb Skill

**Files:**
- Create: `skills/qb/SKILL.md`

**Step 1: Write the skill**

Create `skills/qb/SKILL.md`:

````markdown
---
name: qb
description: Use after build is complete to audit backend code against the project style guide. Supports Go, Python, TypeScript, and C# backends. Checks naming, error handling patterns, package structure, and API conventions. Requires .pipeline/build.complete.
---

# QB — Backend Style Audit

## Role

You are Sonnet acting as a backend code reviewer. Audit against the project's own style guide and language idioms — not generic linting rules. Match what the codebase already does.

## Process

### Step 1: Identify backend language and style guide

Read `.pipeline/brief.md` for the primary language. Check which LSP tools are available.

Look for style guidance:
1. `STYLE.md`, `BACKEND.md`, `docs/style-guide.md`
2. Language-specific config: `.golangci.yml`, `pyproject.toml`/`setup.cfg`, `.editorconfig`
3. `CLAUDE.md`
4. Infer from existing code patterns

Present the rules you will audit against before starting.

### Step 2: Language-specific LSP audit

**Go (if go_lsp available):**
- Unused variables and imports
- Error return values ignored (check for `_ = err`)
- Function signature conventions

**Python (if python_lsp available):**
- Unused imports and variables
- Type annotation consistency (if project uses mypy/pyright)
- Missing `__init__.py` where expected

**TypeScript backend (if typescript_lsp available):**
- Type errors and `any` usage
- Unused imports

**C# (if csharp_lsp available):**
- Unused usings
- Nullable reference warnings
- Naming violations (PascalCase methods, camelCase locals)

### Step 3: General backend audit

Check regardless of language:
- Error handling — are errors surfaced or swallowed?
- Logging — are log statements using the project's logger (not raw print/console)?
- Constants vs. magic numbers — flag unexplained literals
- Package/module naming — match project convention
- Public API surface — is anything public that should be internal?
- Dead endpoints — routes registered but never called from tests or documented

### Step 4: Report findings

Format:
```
[file:line] [RULE] [description]
```

Group by severity: Errors, Warnings, Style.

## Output

Report to user. No file written to `.pipeline/`.
````

---

### Task 7: /qd Skill

**Files:**
- Create: `skills/qd/SKILL.md`

**Step 1: Write the skill**

Create `skills/qd/SKILL.md`:

````markdown
---
name: qd
description: Use after build is complete to validate documentation freshness. Checks that README, API docs, inline comments, and changelogs reflect the current implementation. Requires .pipeline/build.complete.
---

# QD — Documentation Freshness

## Role

You are Sonnet acting as a documentation auditor. Find gaps between what the code does and what the docs say it does. Do not rewrite docs — report stale sections for human review.

## Process

### Step 1: Inventory documentation

Find all documentation files:
- `README.md` and any `docs/` directory
- API documentation files (`openapi.yaml`, `swagger.json`, etc.)
- Inline code comments for public interfaces
- `CHANGELOG.md` or `RELEASE-NOTES.md`
- Any generated documentation configs

### Step 2: Check README accuracy

For each claim in the README:
- Installation steps — do they still work with the current dependency list?
- Usage examples — do they reference functions/commands/APIs that still exist with those signatures?
- Configuration options — are all documented options still valid?
- Badges/links — are they pointing to the right places?

Flag anything that references a renamed, removed, or changed interface.

### Step 3: Check API doc accuracy

For each documented endpoint or public function:
- Does it still exist?
- Do the parameter names and types match?
- Do the return types/shapes match?
- Are new public interfaces missing from docs entirely?

### Step 4: Check CHANGELOG

- Is there an entry for the changes made in this build?
- If no entry exists, flag it: "CHANGELOG has no entry for current build changes."

### Step 5: Report findings

Format:
```
[file:section] STALE — [what's wrong]
[file] MISSING — [what's not documented]
```

If no findings: "Documentation audit complete — all docs reflect current implementation."

## Output

Report to user. No file written to `.pipeline/`.
````

---

### Task 8: /security-review Skill

**Files:**
- Create: `skills/security-review/SKILL.md`

**Step 1: Write the skill**

Create `skills/security-review/SKILL.md`:

````markdown
---
name: security-review
description: Use after build is complete to scan for OWASP Top 10 vulnerabilities. Checks injection, authentication, authorization, data exposure, and misconfiguration risks. Requires .pipeline/build.complete.
---

# SECURITY-REVIEW — OWASP Vulnerability Scan

## Role

You are Sonnet acting as a security auditor. Scan for OWASP Top 10 vulnerabilities. Report findings with severity, location, and remediation. Do not fix — report.

## Process

### Step 1: Read build context

Read `.pipeline/brief.md` to understand:
- Primary language and framework
- What kind of application this is (API, web app, CLI, library)
- Any security constraints noted in the brief

### Step 2: Scan for OWASP Top 10

Check each category relevant to the application type:

**A01 — Broken Access Control**
- Routes/endpoints missing authorization checks
- Direct object references without ownership validation
- Admin endpoints accessible without role checks

**A02 — Cryptographic Failures**
- Sensitive data (passwords, tokens, PII) stored or transmitted without encryption
- Weak algorithms (MD5, SHA1 for passwords, ECB mode)
- Hardcoded secrets, API keys, or credentials in source

**A03 — Injection**
- SQL queries built with string concatenation instead of parameterized queries
- Shell command construction using unsanitized user input
- Template injection patterns

**A04 — Insecure Design**
- Rate limiting absent on authentication endpoints
- No input size limits on file uploads or request bodies
- Business logic that allows negative quantities, price manipulation

**A05 — Security Misconfiguration**
- Debug mode or verbose error messages in production code paths
- Default credentials or configuration left in place
- Overly permissive CORS settings (`Access-Control-Allow-Origin: *` on sensitive APIs)

**A06 — Vulnerable Components**
- Note: flag this category for manual review — check `package.json`, `go.mod`, `requirements.txt`, `*.csproj` for obviously outdated or known-vulnerable dependencies. Do not make claims about specific CVEs without verification.

**A07 — Auth and Session Failures**
- Password hashing without salting
- Tokens without expiry
- Session IDs in URLs

**A08 — Software and Data Integrity Failures**
- Deserialization of untrusted data
- Auto-update mechanisms without signature verification

**A09 — Logging and Monitoring Failures**
- Authentication events (login, logout, failures) not logged
- Sensitive data appearing in logs

**A10 — SSRF**
- User-supplied URLs fetched server-side without allowlist validation

### Step 3: LSP-assisted taint analysis

If LSP is available, trace data flow from entry points (request handlers, CLI args, env vars) to sensitive sinks (SQL queries, shell exec, file paths, network calls) to identify injection paths.

### Step 4: Report findings

Format:
```
[SEVERITY] [OWASP Category] [file:line]
Description: [what the vulnerability is]
Risk: [what an attacker could do]
Remediation: [specific fix guidance]
```

Severity: CRITICAL / HIGH / MEDIUM / LOW / INFO

If no findings: "Security review complete — no OWASP Top 10 vulnerabilities found."

## Output

Report to user. No file written to `.pipeline/`.
````

---

### Task 9: README

**Files:**
- Create: `README.md`

**Step 1: Write README**

Create `README.md`:

````markdown
# claude-agents-custom

A quality-gated development pipeline for Claude Code. Every transition between phases is enforced by a hook that blocks forward progress until the required artifact exists.

> Code is a liability; judgement is an asset.

## Pipeline

```
idea
 └─ /arm        → .pipeline/brief.md
     └─ /design → .pipeline/design.md
         └─ /ar → .pipeline/design.approved
             └─ /plan   → .pipeline/plan.md
                 └─ /build  → .pipeline/build.complete
                     └─ /qa [--parallel|--sequential]
                         ├─ /denoise
                         ├─ /qf
                         ├─ /qb
                         ├─ /qd
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
/arm
```

You should see the arm skill start a Q&A session. If the gate hook is active, trying `/design` before running `/arm` will show a block message.

## The .pipeline/ State Directory

Each pipeline phase writes a state artifact to `.pipeline/` in your project root. This is how the hook knows where you are in the pipeline.

```
.pipeline/
├── brief.md          # written by /arm
├── design.md         # written by /design
├── design.approved   # written by /ar when review loop resolves
├── plan.md           # written by /plan
└── build.complete    # written by /build after /pmatch passes
```

**The `.pipeline/` directory is not committed to git by default.** Add it to `.gitignore`:

```
.pipeline/
```

Or commit it if you want a paper trail of your pipeline state.

**To reset the pipeline** (start over from a specific phase):

```bash
# Reset everything — start fresh from /arm
rm -rf .pipeline/

# Re-open from design phase (keep brief, redo design forward)
rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Re-open from review phase (keep design, redo /ar forward)
rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete
```

## Command Reference

### /arm — Requirements Crystallization

**Gate:** None (always available)
**Writes:** `.pipeline/brief.md`
**Model:** Opus

Extracts requirements, constraints, non-goals, style preferences, and key concepts from fuzzy input through conversational Q&A. Detects your project language and available LSP tools. Ends with a forced-choice checkpoint to resolve remaining ambiguities before writing the brief.

```
/arm
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

### /ar — Adversarial Review

**Gate:** `.pipeline/design.md` must exist
**Writes:** `.pipeline/design.approved` (on loop exit)
**Models:** Opus (strategic critique) + Codex via OpenAI MCP (code-grounded critique)
**Tools used:** Context7, filesystem

Dispatches Opus and Codex in parallel. Each critiques the design from a different angle. Lead Opus deduplicates findings, fact-checks each against the actual codebase, runs cost/benefit analysis, and outputs a structured report. Loop continues until no remaining findings warrant mitigation.

```
/ar
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

### /pmatch — Drift Detection

**Gate:** `.pipeline/plan.md` must exist
**Writes:** nothing (report only)
**Models:** Sonnet (agent 1) + Codex via OpenAI MCP (agent 2) + Opus (lead)

Two agents independently extract claims from a source-of-truth document and verify each against a target. Lead reconciles conflicts and mitigates drift.

```
/pmatch
```

---

### /build — Parallel Build

**Gate:** `.pipeline/plan.md` must exist
**Writes:** `.pipeline/build.complete` (after /pmatch passes)
**Models:** Opus (lead) + Sonnet (builders)
**Flags:** `--parallel` | `--sequential`

```
/build --parallel     # Sonnets in independent agents, own context each
/build --sequential   # Task groups executed one at a time, current session
/build                # Prompts you to choose
```

Lead Opus coordinates and unblocks. Never writes implementation code. Runs /pmatch post-build. Writes `build.complete` only when /pmatch passes.

---

### /qa — Post-Build QA Pipeline

**Gate:** `.pipeline/build.complete` must exist
**Flags:** `--parallel` | `--sequential`

```
/qa --parallel    # All QA skills dispatched simultaneously
/qa --sequential  # denoise → qf → qb → qd → security-review in order
/qa               # Prompts you to choose
```

Individual skills are also available standalone (each requires `build.complete`):

| Skill | What it does |
|-------|-------------|
| `/denoise` | Strips dead code, unused imports, unreachable branches |
| `/qf` | Frontend style audit (TypeScript/JS/CSS) |
| `/qb` | Backend style audit (Go/Python/C#/TS) |
| `/qd` | Documentation freshness — docs vs. implementation drift |
| `/security-review` | OWASP Top 10 vulnerability scan |

## Language Support Matrix

What each optional LSP adds per skill:

| LSP | /denoise | /qf | /qb | /ar | /build | /security-review |
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
/arm
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
/ar
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
# /pmatch runs post-build
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

### "PIPELINE GATE BLOCKED: No brief found"

You tried to run `/design` without a brief. Run `/arm` first.

### "PIPELINE GATE BLOCKED: Design not approved"

You tried to run `/plan` without going through `/ar`. Run `/ar` and iterate until the review loop resolves.

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
````

---

## Phase 2 — External Tool Integration

### Task 10: /design Skill

**Files:**
- Create: `skills/design/SKILL.md`

**Step 1: Write the skill**

Create `skills/design/SKILL.md`:

````markdown
---
name: design
description: Use after /arm to transform a brief into a formal design document. Performs first-principles analysis, classifies constraints, grounds all recommendations in live library docs via Context7 and web search, then iterates until alignment. Writes .pipeline/design.md.
---

# DESIGN — First-Principles Design

## Role

You are Opus acting as a software architect. Your output is a formal design document so rigorous that the adversarial review in /ar has specific claims to verify and refute.

## Hard Rules

1. **Never recommend a library or pattern without grounding it first.** Call Context7 to get the live docs. Do not rely on training data alone.
2. **Classify every constraint.** Hard constraints are non-negotiable. Soft constraints get flagged explicitly.
3. **Reconstruct from validated truths only.** Do not carry forward assumptions from the brief without validating them.
4. **Iterate until aligned.** Do not write the design doc until the user confirms alignment.

## Process

### Step 1: Read the brief

Read `.pipeline/brief.md` in full. Extract:
- Primary language and LSP availability
- All hard and soft constraints
- Success criteria
- Non-goals

### Step 2: Ground constraints and assumptions

For each constraint or assumption in the brief:
1. Is it actually a hard constraint or is it a soft preference stated as a constraint?
2. Does it conflict with any other constraint?

Flag soft constraints treated as hard: "This constraint is stated as hard, but [reason] suggests it may be flexible. Treating it as soft for this design."

### Step 3: Ground library and pattern choices in live docs

Before recommending any library, framework, or architectural pattern:
1. Call Context7 to resolve the library: `resolve_library_id` then `get_library_docs`
2. Verify the recommended API still exists in the current version
3. Note any gotchas or breaking changes in the docs

Use web search for:
- Known pitfalls not in official docs
- Community consensus on the approach
- Security advisories for the recommended stack

### Step 4: Check LSP if available

If the project language LSP is available in this session:
- Query existing symbol names and types relevant to the feature
- Identify existing interfaces the design must be compatible with
- Flag any naming conflicts with existing symbols

### Step 5: Reconstruct the optimal approach

Starting from validated truths only, reconstruct:
- What is the minimal implementation that satisfies all hard constraints?
- What is the recommended approach given the soft constraints?
- What are the key trade-offs between approaches?

### Step 6: Iterate with user

Present the design approach and ask: "Does this direction align with your intent?"

If no: ask what's wrong, adjust, repeat.
If yes: proceed to write the document.

### Step 7: Write the design document

Write `.pipeline/design.md` with this structure:

```markdown
# Design: [Feature Name]

**Date:** [YYYY-MM-DD]
**Brief:** `.pipeline/brief.md`

## Approach

[2-3 paragraphs: what we're building, why this approach, key decisions]

## Constraints Analysis

### Hard Constraints
| Constraint | Source | Impact |
|-----------|--------|--------|
| [constraint] | [brief/discovery] | [how it shapes the design] |

### Soft Constraints (flagged)
| Constraint | Why Flagged | Recommendation |
|-----------|-------------|----------------|
| [constraint] | [why it's soft] | [how to handle it] |

## Architecture

[Diagrams as ASCII or description. Component breakdown. Data flow.]

## Components

### [Component Name]
- **Responsibility:** [what it does]
- **Interface:** [inputs and outputs]
- **Dependencies:** [what it needs]

## Data Model

[Key data structures, schemas, or types]

## Error Handling Strategy

[How errors are surfaced, logged, and handled]

## Testing Strategy

[Unit test targets, integration test targets, what to mock]

## Library Decisions

| Library | Version | Reason | Docs Verified |
|---------|---------|--------|---------------|
| [lib] | [version] | [why] | Context7 ✓ |

## Non-Goals (confirmed)

[From brief — what this design explicitly excludes]

## Open Questions for /ar

[Specific claims in this design that are worth adversarial scrutiny]
```

## Output

Confirm: "Design written to `.pipeline/design.md`. Run `/ar` to stress-test it."
````

---

### Task 11: /plan Skill

**Files:**
- Create: `skills/plan/SKILL.md`

**Step 1: Write the skill**

Create `skills/plan/SKILL.md`:

````markdown
---
name: plan
description: Use after /ar to transform the approved design into an atomic execution plan. Writes task groups with exact file paths, complete code examples, and named test cases with assertions. Build agents must never need to ask clarifying questions. Writes .pipeline/plan.md.
---

# PLAN — Atomic Execution Planning

## Role

You are Opus acting as a technical lead writing a build spec. The target audience is a Sonnet agent that knows nothing about this project. If a builder has to guess anything, you have failed.

## Hard Rules

1. **Exact file paths.** No "in the components directory" — give `src/components/UserCard/UserCard.tsx`.
2. **Complete code.** No "add validation here" — write the actual validation code.
3. **Named test cases with assertions.** Define what to test and what the assertion is, not just "write tests".
4. **Non-negotiable acceptance criteria.** Each task either passes its criteria or does not. No ambiguity.
5. **Flag parallelism.** Explicitly mark which task groups can run in parallel and which must be sequential.

## Process

### Step 1: Read design and brief

Read `.pipeline/design.md` and `.pipeline/brief.md` in full.

### Step 2: Decompose into task groups

Group the work into independent task groups. A task group is a set of tasks that:
- Can be assigned to one agent with one coherent context
- Does not modify files that another concurrent task group modifies
- Produces a testable artifact on its own

Aim for ~5 tasks per group. More than 8 tasks in a group is a smell — split it.

### Step 3: Order and dependency mapping

For each task group:
- Which groups must complete before this one can start?
- Which groups can run in parallel with this one?

Produce a dependency map:
```
Group A ──┬── Group C (depends on A and B)
Group B ──┘
Group D (independent, can run with A and B)
```

### Step 4: Write the plan

Write `.pipeline/plan.md` with this structure:

```markdown
# Execution Plan: [Feature Name]

**Date:** [YYYY-MM-DD]
**Design:** `.pipeline/design.md`
**Parallelism:** [summary of which groups are parallel-safe]

---

## Task Group [N]: [Name]

**Parallel-safe with:** [Group names, or "none"]
**Must run after:** [Group names, or "none"]
**Assigned model:** Sonnet

### Files
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts` (lines 45-67: add X after Y)
- Test: `exact/path/to/file.test.ts`

### Context for agent
[2-3 sentences of context the agent needs. What does this code connect to? What pattern does it follow?]

### Task [N.1]: [Action]

[Exact code to write]

```typescript
// Complete implementation — not pseudocode
export function doThing(input: InputType): OutputType {
  // actual implementation
}
```

### Task [N.2]: Write tests

Named test cases:

| Test name | Setup | Assertion |
|-----------|-------|-----------|
| `test_doThing_with_valid_input` | `input = { ... }` | `result === expected_value` |
| `test_doThing_with_null_input` | `input = null` | `throws TypeError` |

### Acceptance Criteria (non-negotiable)
- [ ] All named test cases pass
- [ ] No TypeScript errors on compile
- [ ] [specific criterion from design]
```

### Step 5: Cross-check for conflicts

Before finalizing: verify no two parallel task groups modify the same file. If they do, either make them sequential or split the shared file modification into its own task group that runs first.

## Output

Confirm: "Plan written to `.pipeline/plan.md`. Run `/build --parallel` or `/build --sequential`."
````

---

## Phase 3 — Multi-Agent Orchestration

### Task 12: /ar Skill

**Files:**
- Create: `skills/ar/SKILL.md`

**Step 1: Write the skill**

Create `skills/ar/SKILL.md`:

````markdown
---
name: ar
description: Use after /design to adversarially review the design document. Dispatches Opus and Codex in parallel — Opus for strategic critique, Codex for code-grounded critique. Lead deduplicates, runs cost/benefit analysis, loops until no findings warrant mitigation. Writes .pipeline/design.approved on loop exit.
---

# AR — Adversarial Review

## Role

You are Opus acting as a review team lead. You orchestrate two critics — yourself and Codex — then synthesize their findings. Your job is to make the design bulletproof before any code is written.

## Hard Rules

1. **Parallel dispatch.** Opus critique and Codex critique run simultaneously via the Task tool. Do not run them sequentially.
2. **Ground before critiquing.** Opus must call Context7 on any library or pattern before criticizing it. No opinions without current docs.
3. **Cost/benefit on every finding.** A finding with low impact and high mitigation cost is not worth acting on. Be ruthless about this.
4. **Fact-check against codebase.** Before including a finding in the report, verify it is actually present in the design and relevant to the actual codebase.
5. **Loop until resolved.** Do not write `design.approved` until no remaining findings warrant mitigation.

## Process

### Step 1: Read the design

Read `.pipeline/design.md` and `.pipeline/brief.md` in full.

### Step 2: Dispatch parallel critics

Use the Task tool to launch two agents simultaneously:

**Agent 1 — Opus Strategic Critic**

Prompt for this agent:
```
You are reviewing a software design document for strategic flaws.

Read the design at .pipeline/design.md and the brief at .pipeline/brief.md.

Before forming any opinion about a library or pattern:
1. Call Context7 to get the live docs for that library
2. Verify your critique is based on current docs, not assumptions

Critique the design on:
- Architectural correctness: does the approach actually solve the stated problem?
- Constraint violations: does the design violate any hard constraints from the brief?
- Soft constraints flagged as hard: are any soft constraints being over-constrained?
- Missing concerns: error handling, observability, scalability, security surface
- Assumption validity: which assumptions in the design are unverified?
- Non-goal drift: is the design building anything that was explicitly excluded?

For each finding:
- Describe the issue
- Assess impact (HIGH/MEDIUM/LOW)
- Estimate mitigation cost (HIGH/MEDIUM/LOW)
- Suggest a specific mitigation

Return a JSON array of findings:
[{"id": "S1", "category": "...", "finding": "...", "impact": "HIGH", "mitigation_cost": "LOW", "mitigation": "..."}]
```

**Agent 2 — Codex Code-Grounded Critic**

Prompt for this agent (dispatched via OpenAI MCP):
```
You are reviewing a software design document for code-grounded issues.

Read the design at .pipeline/design.md and the brief at .pipeline/brief.md.
Read the existing codebase to understand current patterns, interfaces, and constraints.

Critique the design on:
- Interface compatibility: does the design interface correctly with existing code?
- Pattern consistency: does the design follow the patterns already established in the codebase?
- Naming conflicts: does the design introduce names that conflict with existing symbols?
- Dependency feasibility: do the proposed dependencies actually provide the required APIs?
- Type compatibility: are the proposed data structures compatible with how they'll be consumed?

For each finding:
- Describe the issue with specific file and symbol references
- Assess impact (HIGH/MEDIUM/LOW)
- Estimate mitigation cost (HIGH/MEDIUM/LOW)
- Suggest a specific mitigation

Return a JSON array of findings:
[{"id": "C1", "category": "...", "finding": "...", "impact": "HIGH", "mitigation_cost": "LOW", "mitigation": "..."}]
```

### Step 3: Synthesize findings

Once both agents return:

1. **Deduplicate:** Identify findings that both critics raised — merge them into one, noting both sources agree.
2. **Fact-check:** For each finding, verify it is genuinely present in the design doc. Discard findings that are not supported by the actual design text.
3. **Cost/benefit filter:** For each finding, calculate: is the impact high enough relative to the mitigation cost to warrant action?
   - HIGH impact + LOW cost → MUST FIX
   - HIGH impact + HIGH cost → SHOULD FIX, flag for human judgment
   - MEDIUM impact + LOW cost → CONSIDER fixing
   - LOW impact + any cost → SKIP
   - MEDIUM/LOW impact + HIGH cost → SKIP

4. **Structure the report:**

```markdown
# Adversarial Review Report

**Round:** [N]
**Design:** .pipeline/design.md

## Findings Requiring Action

| ID | Source | Category | Finding | Impact | Cost | Mitigation |
|----|--------|---------|---------|--------|------|-----------|
| M1 | Opus+Codex | [category] | [finding] | HIGH | LOW | [mitigation] |

## Findings for Human Judgment

| ID | Source | Category | Finding | Impact | Cost | Note |
|----|--------|---------|---------|--------|------|------|

## Findings Skipped (cost/benefit)

| ID | Source | Finding | Reason skipped |
|----|--------|---------|---------------|

## Loop Decision

[All required-action findings have been mitigated / [N] findings remain unresolved]
```

### Step 4: Human review

Present the report. Ask: "Do you want to update the design to address these findings before the next round, or override any findings?"

If the user wants to update the design: wait for them to update `.pipeline/design.md`, then run the next review round (return to Step 2).

If all MUST FIX findings are resolved and no SHOULD FIX items are outstanding (or user has explicitly accepted them): write `.pipeline/design.approved` as an empty marker file.

### Step 5: Write approval marker

```bash
touch .pipeline/design.approved
```

Confirm: "Design approved. Run `/plan` to create the execution plan."
````

---

### Task 13: /pmatch Skill

**Files:**
- Create: `skills/pmatch/SKILL.md`

**Step 1: Write the skill**

Create `skills/pmatch/SKILL.md`:

````markdown
---
name: pmatch
description: Use to detect drift between a source-of-truth document and a target document or implementation. Dispatches Sonnet and Codex in parallel for independent claim extraction and verification. Requires .pipeline/plan.md. Used internally by /build and available standalone.
---

# PMATCH — Drift Detection

## Role

You are Opus acting as a verification lead. Two independent agents extract claims from a source document and verify each against the target. You reconcile their findings and mitigate drift.

## Process

### Step 1: Identify source and target

Ask the user (or receive from /build context):
- **Source of truth:** what document contains the claims? (default: `.pipeline/plan.md`)
- **Target:** what is being verified against? (default: current implementation in the working directory)

### Step 2: Dispatch parallel verifiers

Use the Task tool to launch two agents simultaneously:

**Agent 1 — Sonnet Verifier**

```
You are verifying implementation drift.

Source of truth: [source document path]
Target: [target path or "current working directory"]

Step 1: Extract all verifiable claims from the source document.
A verifiable claim is a specific, checkable assertion: file paths that should exist, function names that should be implemented, test cases that should pass, acceptance criteria that should be met.

Step 2: For each claim, check whether the target satisfies it.
- EXISTS: the claim is satisfied
- MISSING: the claim is not satisfied — describe what's absent
- PARTIAL: partially satisfied — describe what's missing
- CONTRADICTED: the target actively contradicts the claim

Return a JSON array:
[{"claim_id": "P1", "claim": "...", "status": "EXISTS|MISSING|PARTIAL|CONTRADICTED", "evidence": "..."}]
```

**Agent 2 — Codex Verifier (via OpenAI MCP)**

Same prompt as Agent 1. Codex operates independently to surface any claims the Sonnet agent misses.

### Step 3: Reconcile findings

Once both agents return:

1. **Merge claim lists:** combine all claims both agents identified.
2. **Resolve conflicts:** where agents disagree on a claim's status, manually check the file/symbol to determine ground truth.
3. **Produce drift report:**

```markdown
# Drift Report

**Source:** [source path]
**Target:** [target]
**Date:** [YYYY-MM-DD]

## Summary
- Total claims: [N]
- Satisfied: [N]
- Missing: [N]
- Partial: [N]
- Contradicted: [N]

## Findings

| ID | Claim | Status | Evidence |
|----|-------|--------|---------|
| P1 | [claim] | MISSING | [what's absent] |

## Recommended Actions
[Specific remediations for MISSING, PARTIAL, CONTRADICTED findings]
```

### Step 4: Mitigate if called from /build

If /pmatch is running as part of the /build post-build check:
- MISSING or CONTRADICTED findings → build does NOT complete; report to lead, lead unblocks or flags for re-build
- PARTIAL findings → lead judgment call: acceptable or must fix

If /pmatch is running standalone:
- Present report to user for judgment.
````

---

### Task 14: /build Skill

**Files:**
- Create: `skills/build/SKILL.md`

**Step 1: Write the skill**

Create `skills/build/SKILL.md`:

````markdown
---
name: build
description: Use after /plan to execute the build. Opus leads and coordinates; Sonnets implement. Supports --parallel (independent agent per task group, own context) or --sequential (one task group at a time in current session). Runs /pmatch post-build. Writes .pipeline/build.complete on pass.
---

# BUILD — Parallel Build

## Role

You are Opus acting as a build lead. You coordinate Sonnet builders. You never write implementation code. Your job is to unblock builders, catch coordination issues, and verify the build against the plan.

## Mode Selection

If the user invoked `/build --parallel`: use parallel mode.
If the user invoked `/build --sequential`: use sequential mode.
If no flag was given: ask the user before proceeding.

```
Build mode:
  --parallel   Independent agents, each with own context, faster wall-clock time
  --sequential One task group at a time, easier to debug, review between groups

Which mode? (parallel / sequential)
```

## Process

### Step 1: Read the plan

Read `.pipeline/plan.md` in full. Extract:
- All task groups
- Their dependency ordering
- Which groups are parallel-safe
- The acceptance criteria for each group

### Step 2A: Parallel Mode

For each independent task group (those with no unmet dependencies), dispatch a Sonnet agent simultaneously via the Task tool.

Agent prompt template:
```
You are a Sonnet build agent implementing one task group from an execution plan.

Read your task group from .pipeline/plan.md: Task Group [N] — [Name]

Your constraints:
- Only touch the files listed in your task group's Files section
- Follow the exact patterns shown in the code examples
- Implement all named test cases with the specified assertions
- Do not modify files from other task groups

When complete, report:
- Files created/modified
- Tests written and their pass/fail status
- Any blockers you encountered
```

Monitor agent outputs. When an agent reports a blocker:
- Investigate the blocker
- Provide specific guidance to unblock
- Do not implement code yourself — describe what needs to change

After all parallel groups complete, run dependent groups in the same way.

### Step 2B: Sequential Mode

For each task group in dependency order:

1. Dispatch one Sonnet agent with the task group prompt above
2. Wait for completion
3. Review the agent's output — did it satisfy the acceptance criteria?
4. If yes: proceed to next group
5. If no: provide specific correction guidance and re-dispatch

### Step 3: Post-build verification

After all task groups complete, run /pmatch:

```
/pmatch
```

Source of truth: `.pipeline/plan.md`
Target: current working directory

### Step 4: Evaluate /pmatch result

If /pmatch finds MISSING or CONTRADICTED claims:
- Identify which task group is responsible
- Re-dispatch that task group's Sonnet agent with specific remediation instructions
- Re-run /pmatch after remediation
- Repeat until /pmatch passes

### Step 5: Write build.complete

When /pmatch passes with no unresolved MISSING or CONTRADICTED findings:

```bash
mkdir -p .pipeline
touch .pipeline/build.complete
```

Confirm: "Build complete and verified. Run `/qa` for post-build audits."

## Lead Rules

1. **Never write implementation code.** If you find yourself about to write code, stop. Describe what the agent needs to do instead.
2. **One job: coordinate and unblock.** Route information between agents. Resolve blockers. Keep context narrow for each agent.
3. **Separate contexts.** Each builder gets only the context for their task group. Do not cross-contaminate.
````

---

### Task 15: /qa Skill

**Files:**
- Create: `skills/qa/SKILL.md`

**Step 1: Write the skill**

Create `skills/qa/SKILL.md`:

````markdown
---
name: qa
description: Use after /build to run the full post-build QA pipeline. Supports --parallel (all audits simultaneously) or --sequential (denoise → qf → qb → qd → security-review in order). Requires .pipeline/build.complete.
---

# QA — Post-Build QA Pipeline

## Mode Selection

If the user invoked `/qa --parallel`: use parallel mode.
If the user invoked `/qa --sequential`: use sequential mode.
If no flag was given: ask the user before proceeding.

```
QA mode:
  --parallel   All audits run simultaneously (faster, independent concerns)
  --sequential One audit at a time in order (review each before next)

Which mode? (parallel / sequential)
```

## Process

### Parallel Mode

Dispatch all five QA skills simultaneously via the Task tool:

```
Launch 5 agents at once, each running one skill:
- Agent 1: /denoise
- Agent 2: /qf
- Agent 3: /qb
- Agent 4: /qd
- Agent 5: /security-review
```

Each agent receives only the context for its specific audit. Wait for all five to complete, then present a consolidated report.

**Consolidated report format:**
```markdown
# QA Report

## /denoise
[findings or "clean"]

## /qf — Frontend
[findings or "no violations"]

## /qb — Backend
[findings or "no violations"]

## /qd — Documentation
[findings or "all docs current"]

## /security-review
[findings or "no vulnerabilities found"]
```

### Sequential Mode

Run in order, presenting each result before proceeding:

1. Run /denoise — present findings — ask "Continue to /qf?"
2. Run /qf — present findings — ask "Continue to /qb?"
3. Run /qb — present findings — ask "Continue to /qd?"
4. Run /qd — present findings — ask "Continue to /security-review?"
5. Run /security-review — present final findings

## Output

Present consolidated or sequential findings to the user. No file written to `.pipeline/`.
````

---

### Task 16: Install and Smoke Test

**Step 1: Initialize git (required for some Claude Code operations)**

```bash
cd ~/claude-agents-custom
git init
git add .
git commit -m "feat: initial pipeline plugin scaffold"
```

**Step 2: Install via dev marketplace**

In a Claude Code session:
```
/plugin marketplace add ~/claude-agents-custom
/plugin install claude-agents-custom@local-dev
```

Restart Claude Code.

**Step 3: Verify skills appear in system context**

Start a new Claude Code session. The system-reminder should list all skills:
- arm, design, ar, plan, pmatch, build, qa, denoise, qf, qb, qd, security-review

**Step 4: Test the gate hook**

In a test project directory with no `.pipeline/` dir:
```
/design
```
Expected: gate blocks with "No brief found. Run /arm first."

```
/arm
```
Expected: arm skill starts Q&A (no gate block).

After /arm completes and writes `.pipeline/brief.md`:
```
/design
```
Expected: design skill starts (gate allows).

**Step 5: Run gate unit tests**

```bash
bash ~/claude-agents-custom/hooks/test_gate.sh
```

Expected: all tests pass, exit 0.

---

## Validation Checklist

Before calling this implementation complete:

- [ ] `python3 -m json.tool .claude-plugin/plugin.json` exits 0
- [ ] `python3 -m json.tool .claude-plugin/marketplace.json` exits 0
- [ ] `python3 -m json.tool hooks/hooks.json` exits 0
- [ ] `bash hooks/test_gate.sh` all pass
- [ ] Plugin installs without errors
- [ ] All 12 skills appear in system-reminder after install
- [ ] Gate blocks `/design` with no `.pipeline/brief.md`
- [ ] Gate allows `/arm` always
- [ ] Gate blocks `/qa` without `.pipeline/build.complete`
- [ ] `/arm` completes and writes `.pipeline/brief.md`
