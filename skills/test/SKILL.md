---
name: test
description: Use to run the project test suite. Supports /test [file-or-pattern] to scope to specific files or test names. Detects jest, vitest, go test, pytest, dotnet test, and cargo test automatically. No pipeline artifacts required — can run at any time.
argument-hint: [file-or-pattern]
---

# TEST — Run Test Suite

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Mechanical task — detect runner, run, report.

You are acting as a test runner. Detect the project's test framework, build the correct command, execute it, and report results clearly.

## Process

### Step 1: Parse args

Check the invocation arguments for a file pattern or test name filter (e.g., `/test auth`, `/test src/user.test.ts`). Record it as the scope filter if present; proceed without scope if not.

### Step 2: Detect runner

Check for test configuration in this order:

- `package.json` → look for `jest` or `vitest` in `devDependencies` or `scripts.test` → use `npm test` or `npx jest` / `npx vitest run`
- `go.mod` → Go → use `go test ./...`
- `pyproject.toml`, `pytest.ini`, `setup.cfg` with `[tool:pytest]` → Python → use `pytest`
- `*.csproj` or `*.sln` → .NET → use `dotnet test`
- `Cargo.toml` → Rust → use `cargo test`

If no runner can be detected, prefer AskUserQuestion with:
  question: "No test runner detected. Which test command should I run?"
  header: "Test runner"
  options:
    - label: "npm test"
      description: "Node.js / Jest / Vitest"
    - label: "go test ./..."
      description: "Go"
    - label: "pytest"
      description: "Python"
    - label: "cargo test"
      description: "Rust"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the answer.

### Step 3: Build run command

Compose the full command:
- Apply scope filter if provided (e.g., `npx jest auth`, `go test ./auth/...`, `pytest tests/test_auth.py`, `cargo test auth`)
- Use appropriate flags for output verbosity (e.g., `--verbose` for jest, `-v` for go test)

### Step 4: Execute

Run via Bash. Capture exit code, stdout, and stderr.

### Step 5: Report

Report:
- Pass count, fail count, skip count (if available), total duration
- If all pass: "All [N] tests passed in [duration]."
- If failures: list each failed test — name, file:line, error message

### Step 6: Offer fix if failures

If any tests failed, prefer AskUserQuestion with:
  question: "Tests failed. What next?"
  header: "Test failures"
  options:
    - label: "Attempt fix with /quick"
      description: "Invoke /quick with the failing test context to attempt a fix"
    - label: "Report only"
      description: "Done — fix manually"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

If "Attempt fix with /quick": follow the /quick skill process, passing the failing test names and error messages as the task description.

## Output

Test results reported inline. No `.pipeline/` artifacts written.
