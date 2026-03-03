# Execution Plan: [Feature Name]

**Date:** [YYYY-MM-DD]
**Design:** `.pipeline/design.md`
**Parallelism:** [summary of which groups are parallel-safe]
**TDD:** [enabled | disabled]

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

### Task [N.1]: Write tests

Named test cases:

| Test name | Setup | Assertion |
|-----------|-------|-----------|
| `test_doThing_with_valid_input` | `input = { ... }` | `result === expected_value` |
| `test_doThing_with_null_input` | `input = null` | `throws TypeError` |

> These tests must FAIL before Task N.2 begins. A test that passes immediately is invalid.

### Task [N.2]: Implement

[Exact minimal code to make all Task N.1 tests pass — no over-engineering]

```typescript
// Complete implementation — not pseudocode
export function doThing(input: InputType): OutputType {
  // actual implementation
}
```

### Task [N.3]: Verify and refactor

- Run all Task N.1 tests — all must pass
- Refactor for clarity; tests must remain green

### Acceptance Criteria (non-negotiable)
- [ ] All named test cases pass
- [ ] No TypeScript errors on compile
- [ ] [specific criterion from design]

---

> **TDD disabled mode** — if `tdd: disabled` was found in CLAUDE.md, use this ordering instead:
>
> ### Task [N.1]: [Action/implement]
> [Exact code to write]
>
> ### Task [N.2]: Write tests
> Named test cases: [table as before]
>
> ### Task [N.3]: Verify
> - Run all tests — all must pass
