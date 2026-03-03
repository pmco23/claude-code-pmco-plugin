---
name: cleanup
description: Use after build is complete to strip dead code, unused imports, unreachable branches, and commented-out code. Requires .pipeline/build.complete. Safe to run standalone or as part of /qa pipeline.
---

# DENOISE — Dead Code Removal

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

You are acting as a code cleaner. Remove confirmed dead code only. Do not refactor, rename, or restructure anything live.

**Repomix:** if `outputId` in context, use `mcp__repomix__grep_repomix_output(outputId, pattern)` and `mcp__repomix__read_repomix_output(outputId, startLine, endLine)` for discovery; else native Glob/Read/Grep. Modifications (Step 4) use native Edit/Write only — never Repomix.

## Hard Rules

1. Remove dead code only — do not refactor, rename, or restructure live code.
2. Never remove a symbol without presenting it to the user first (Step 3 confirmation gate).
3. If tests fail after removal: report — do not attempt to fix.

## Process

### Step 1: Identify project language

**Detect language:** `brief.md` first; else root config (`package.json`→TS/JS, `go.mod`→Go, `requirements.txt`/`pyproject.toml`/`setup.py`→Python, `*.csproj`/`*.sln`→C#, `Cargo.toml`→Rust); else LSP availability hint; else announce: "Language unknown — findings will be heuristic and will cover all file types."
Also check which LSP tools are in session (needed for Step 2 quality tier regardless of detection path).

### Step 2: Find dead code

**IDE Diagnostics (try first):** Call `mcp__ide__getDiagnostics` (no URI) — if results, use as authoritative source.

**Announce quality tier before proceeding:**
- If `mcp__ide__getDiagnostics` returned results: output `🟢 IDE diagnostics active — errors and warnings are authoritative (VS Code integration).`
- Else if LSP is available: output `🟢 LSP active — dead code findings are authoritative.`
- Else: output `🟡 No IDE or LSP diagnostics available — findings are heuristic (grep-pattern). Install the language LSP for authoritative results (see README Language Support Matrix).`

**If LSP is available** for the project language, use it:
- Request all unused symbol diagnostics
- Request all unreachable code diagnostics
- List unused imports via LSP

**If LSP is not available**, use static analysis:
- Search for symbols defined but never referenced (grep patterns)
- Look for commented-out code blocks (// TODO: remove, /* dead */, etc.)
- Find imports with no usages in the file
- Identify functions/methods with no callers (search for their name across codebase)

**Note:** If running as part of `/qa --parallel`, `/backend-audit` also checks unused imports for Go and TypeScript. Overlapping findings on that category are expected — both reports are correct.

### Step 3: Confirm before removing

Present the dead code list to the user before making any changes:

```
Dead code found:
- [file:line] — [symbol/description] — [reason: unused/unreachable/no callers]
```

Use AskUserQuestion with:
  question: "Found [N] dead code items. How should I proceed?"
  header: "Cleanup action"
  options:
    - label: "Remove all"
      description: "Remove every item in the list without further prompting"
    - label: "Review each"
      description: "Confirm each removal individually"
    - label: "Skip"
      description: "Report findings only — make no changes"

### Step 4: Remove confirmed dead code

For each confirmed item:
- Remove the dead symbol or block
- Remove any imports that become unused as a result
- Do not touch surrounding code

### Step 5: Verify no regressions

Check for test files (`test/`, `tests/`, `*_test.go`, `*.test.ts`, `spec/`, etc.).

If no test files found: skip this step silently.

If test files found, use AskUserQuestion with:
  question: "Run test suite to confirm no regressions from dead code removal?"
  header: "Regression check"
  options:
    - label: "Run now"
      description: "Execute the project test suite via /test"
    - label: "Skip"
      description: "Skip — run tests manually before committing"

If "Run now": follow the `/test` skill process to detect the runner, execute the suite,
and report results. Do not attempt to fix failures — report them.

## Output

Report: "Removed [N] dead code items across [M] files."
