---
name: backend-audit
description: Use after build is complete to audit backend code against the project style guide. Supports Go, Python, TypeScript, and C# backends. Checks naming, error handling patterns, package structure, and API conventions. Requires .pipeline/build.complete.
---

# QB — Backend Style Audit

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are Sonnet acting as a backend code reviewer. For TypeScript projects, audit backend TypeScript only (Node.js, APIs, CLI tools) — frontend TypeScript components are covered by `/frontend-audit`. Audit against the project's own style guide and language idioms — not generic linting rules. Match what the codebase already does.

**Repomix:** if `outputId` in context, use `mcp__repomix__grep_repomix_output(outputId, pattern)` and `mcp__repomix__read_repomix_output(outputId, startLine, endLine)` for discovery; else native Glob/Read/Grep.

## Process

### Step 1: Identify backend language and style guide

**Detect language:** `brief.md` first; else root config (`package.json`→TS/JS, `go.mod`→Go, `requirements.txt`/`pyproject.toml`→Python, `*.csproj`/`*.sln`→C#, `Cargo.toml`→Rust); else LSP availability hint; else announce: "Language unknown — falling back to general backend patterns."
Check which LSP tools are available (needed for the quality tier announcement in Step 2).

Look for style guidance:
1. `STYLE.md`, `BACKEND.md`, `docs/style-guide.md`
2. Language-specific config: `.golangci.yml`, `pyproject.toml`/`setup.cfg`, `.editorconfig`
3. `CLAUDE.md`
4. Infer from existing code patterns

Present the rules you will audit against before starting.

### Step 2: Language-specific LSP audit

**IDE Diagnostics (try first):** Call `mcp__ide__getDiagnostics` (no URI) — if results, use as authoritative source.

**Announce quality tier before proceeding.** Check which tools are available for the detected language:
- If `mcp__ide__getDiagnostics` returned results: output `🟢 IDE diagnostics active — errors and warnings are authoritative (VS Code integration).`
- Else if Go + `go_lsp`: output `🟢 Go LSP active — unused import and diagnostic findings are authoritative.`
- Else if Python + `python_lsp`: output `🟢 Python LSP active — unused import findings are authoritative.`
- Else if TypeScript + `typescript_lsp`: output `🟢 TypeScript LSP active — type error findings are authoritative.`
- Else if C# + `csharp_lsp`: output `🟢 C# LSP active — nullable and unused-using findings are authoritative.`
- Else if Rust + `rust_lsp`: output `🟢 Rust LSP active — unused variable and dead code findings are authoritative.`
- Else: output `🟡 No IDE or LSP diagnostics available for [language] — findings are heuristic. Install the language LSP for authoritative results (see README Language Support Matrix).`


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

