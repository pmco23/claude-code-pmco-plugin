---
name: cleanup
description: Use after build is complete to strip dead code, unused imports, unreachable branches, and commented-out code. Requires .pipeline/build.complete. Safe to run standalone or as part of /qa pipeline.
---

# DENOISE — Dead Code Removal

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

You are acting as a code cleaner. Remove confirmed dead code only. Do not refactor, rename, or restructure anything live.

**Repomix snapshot:** Check `.pipeline/repomix-pack.json` for `snapshots.code.filePath`; if present, use Grep/Read on the code snapshot for discovery. If code variant missing but `.pipeline/repomix-full.xml` exists, use that. Else native Glob/Read/Grep on source files. Modifications (Step 4) use native Edit/Write only.

## Hard Rules

1. Remove dead code only — do not refactor, rename, or restructure live code.
2. Never remove a symbol without presenting it to the user first (Step 3 confirmation gate).
3. If tests fail after removal: report — do not attempt to fix.

## Process

### Step 1: Identify project language

**Detect language:** `brief.md` first; else root config (`package.json`→TS/JS, `go.mod`→Go, `requirements.txt`/`pyproject.toml`/`setup.py`→Python, `*.csproj`/`*.sln`→C#, `Cargo.toml`→Rust); else LSP availability hint; else announce: "Language unknown — findings will be heuristic and will cover all file types."
Also check which LSP tools are in session (needed for Step 2 quality tier regardless of detection path).

### Step 2: Find dead code

Read `references/detection-methods.md` from this skill's base directory. Follow the diagnostics tier, announce quality level, then apply the appropriate detection method (LSP or static analysis fallback).

### Step 3: Confirm before removing

Present the dead code list to the user before making any changes:

```
Dead code found:
- [file:line] — [symbol/description] — [reason: unused/unreachable/no callers]
```

Prefer AskUserQuestion with:
  question: "Found [N] dead code items. How should I proceed?"
  header: "Cleanup action"
  options:
    - label: "Remove all"
      description: "Remove every item in the list without further prompting"
    - label: "Review each"
      description: "Confirm each removal individually"
    - label: "Skip"
      description: "Report findings only — make no changes"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

### Step 4: Remove confirmed dead code

For each confirmed item:
- Remove the dead symbol or block
- Remove any imports that become unused as a result
- Do not touch surrounding code

### Step 5: Verify no regressions

Check for test files (`test/`, `tests/`, `*_test.go`, `*.test.ts`, `spec/`, etc.).

If no test files found: skip this step silently.

If test files found, prefer AskUserQuestion with:
  question: "Run test suite to confirm no regressions from dead code removal?"
  header: "Regression check"
  options:
    - label: "Run now"
      description: "Execute the project test suite via /test"
    - label: "Skip"
      description: "Skip — run tests manually before committing"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

If "Run now": follow the `/test` skill process to detect the runner, execute the suite,
and report results. Do not attempt to fix failures — report them.

## Output

Report: "Removed [N] dead code items across [M] files."
