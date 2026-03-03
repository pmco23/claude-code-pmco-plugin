---
name: tdd
description: Apply when asked to enforce TDD, practice test-driven development, write test first, or follow Red-Green-Refactor. Enforces the Iron Law — no production code without a failing test first. Covers the full Red-Green-Refactor cycle, when TDD applies, and valid exceptions.
---

# TDD — Test-Driven Development

## Role

You are enforcing Test-Driven Development. Every unit of behaviour must have a failing test before production code is written. The Red-Green-Refactor cycle is not optional.

## Hard Rules

1. **Iron Law.** Write the test. Watch it fail. Write minimal code to pass. Never write production code for a behaviour until a failing test for that behaviour exists and you have run it and seen it fail.
2. **Minimal GREEN code.** Write only the code needed to make the failing test pass. No pre-emptive abstractions, no extra logic.
3. **Refactor only on GREEN.** Structural improvements happen after tests pass — never while tests are failing.
4. **One cycle at a time.** Complete the full RED → GREEN → REFACTOR cycle for one named test case before starting the next.
5. **Failing test required, not just written.** A test that passes immediately is not a RED test — it means the test is wrong or the behaviour already exists. Rewrite or investigate before continuing.

## Process

### RED — Write the failing test

1. Identify the next named test case from the task group.
2. Write the test. Reference only the public interface; do not peek at implementation.
3. Run the test: `bash <test-command>` scoped to the new test file or test name.
4. Confirm it **FAILS**. If it passes immediately — stop. The test is wrong. Rewrite it before continuing.

### GREEN — Write minimal production code

5. Write the smallest production code change that makes the failing test pass.
6. Do not add logic that is not required by the current test.
7. Run the test again. Confirm it **PASSES**.
8. Run the full suite scoped to your task group. All previously passing tests must still pass.

### REFACTOR — Improve without breaking

9. Improve naming, structure, or duplication in the code just written.
10. Do not change behaviour. Run the test suite after each refactor step — all tests must remain green.
11. When the code is clean, move to the next named test case and return to RED.

## When TDD Applies

- New feature or behaviour (any language)
- Bug fix — write a test that reproduces the bug first, then fix it
- Refactoring — tests must exist and be green before refactoring starts
- Behaviour changes — existing tests must be updated to reflect the new expected behaviour before the code changes

## Valid Exceptions

TDD is not appropriate for:

- **Throwaway prototypes** — code that will not be merged or shipped; document this explicitly
- **Generated code** — output from code generators or scaffolding tools that is not maintained by hand
- **Configuration files** — JSON, YAML, TOML, environment files with no executable logic
- **Pure UI layout** — pixel-level visual composition with no state logic; cover the state separately
- **Per-project opt-out** — add `tdd: disabled` to the project's `CLAUDE.md`. The pipeline
  respects this setting: `/plan` switches to implementation-first task ordering and writes
  `TDD: disabled` in the plan header; `task-builder` skips the Red-Green-Refactor cycle.
  Use for projects where no test harness exists yet, or where TDD is not feasible given
  current constraints. Document the reason in CLAUDE.md alongside the flag.

When an exception applies, document it inline: `# TDD exception: [reason]` at the top of the file. Do not use exceptions to avoid writing difficult tests.

## Anti-Patterns Reference

See `references/testing-anti-patterns.md` for the five patterns that defeat TDD benefits even when tests are present.
