# Workflows

Two workflow paths are available. Everything else in the plugin supports one of these two paths.

## Which path?

| Situation | Path |
|-----------|------|
| Small feature, bug fix, typo, config tweak — you know exactly what to change | **Fast Track** (`/quick`) |
| New feature, design-sensitive change, anything that warrants a design doc | **Pipeline** (`/brief → /qa`) |
| Not sure | Start with **Pipeline** — you can abandon it after `/brief` if it turns out to be simple |

---

## Fast Track

```text
/quick [task description]     Sonnet implements directly — no artifacts
/quick --deep [task]          Escalate to Opus for trickier problems
/quick                        Prompts you for task description
```

**What it does:**
1. Parses your task, clarifies if ambiguous (one question max)
2. Reads only the relevant files — not the whole codebase
3. Implements the change following existing patterns
4. Self-reviews the diff before handing back
5. Offers a lightweight audit: LSP diagnostics, security spot-check, test reminder

**What it does NOT do:**
- Write `.pipeline/` artifacts — ever
- Invoke the full QA pipeline
- Refactor surrounding code unless asked

**When NOT to use Fast Track:**
- The change requires a design decision with non-obvious trade-offs
- Multiple systems are affected
- The change is large enough that a plan would prevent rework

---

## Pipeline

A quality-gated sequence. Each phase writes an artifact. The gate hook blocks forward progress until the required artifact exists.

```text
/brief    →  .pipeline/brief.md         requirements crystallization (Opus)
/design   →  .pipeline/design.md        first-principles design (Opus + Context7)
/review   →  .pipeline/design.approved  adversarial review (Opus + Codex in parallel)
/plan     →  .pipeline/plan.md          atomic execution plan (Opus + Repomix)
/build    →  .pipeline/build.complete   coordinated build (Opus lead + Sonnet builders)
/qa                                     post-build audits (parallel or sequential)
```

### What each phase produces

| Phase | Output | Purpose |
|-------|--------|---------|
| `/brief` | `brief.md` | Requirements, constraints, non-goals, success criteria — the contract |
| `/design` | `design.md` | Architecture, component breakdown, library decisions, testing strategy |
| `/review` | `design.approved` | Adversarial findings addressed; design hardened before any code |
| `/plan` | `plan.md` | Exact file paths, code patterns, test cases, acceptance criteria per task group |
| `/build` | `build.complete` | Implementation complete and drift-verified against the plan |
| `/qa` | (none) | Dead code, frontend/backend/doc/security audits — run after `/build` completes; use `--parallel` for speed or `--sequential` for interactive mode |

### Resetting to a prior phase

```bash
# Start over completely
rm -rf .pipeline/

# Redo from /design (keep brief)
rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Redo from /review (keep design)
rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Redo from /plan (keep approved design)
rm .pipeline/plan.md .pipeline/build.complete

# Redo from /build (keep plan)
rm .pipeline/build.complete
```

---

## Always-Available Skills

These run independently of any pipeline state — no gate, no artifacts required.

| Skill | When to use |
|-------|-------------|
| `/status` | Any time — shows pipeline state and next step; with no active pipeline, shows available workflow choices |
| `/init` | New project or missing boilerplate — generates README, CHANGELOG, CONTRIBUTING, .gitignore |
| `/git-workflow` | Before branch creation, first push, PR open/merge, or destructive git op (force-push, reset --hard) |
| `/pack` | Before `/qa` or `/quick --deep` to snapshot the codebase |
| `/plugin-architecture` | When deciding whether to use a skill vs agent in a plugin you're building |
| `/drift-check` | After `/build` — verify implementation matches the approved design; also run standalone at any time |
| `/quick` | Fast-track implementation (see above) |

---

## How Agents Work

Three named agents exist in the `agents/` directory: `strategic-critic`, `drift-verifier`, and `task-builder`. Two skills also dispatch Codex MCP (an external MCP tool, not a local agent) for independent parallel analysis. You never invoke agents or Codex MCP directly — skills dispatch them automatically:

- `/review` dispatches `strategic-critic` (Opus) and Codex MCP in parallel
- `/drift-check` dispatches `drift-verifier` (Sonnet) and Codex MCP in parallel
- `/build` dispatches `task-builder` (Sonnet) per task group

The agents enforce model routing (`model: opus` / `model: sonnet`) at the runtime level rather than by prompt instruction alone. This is an implementation detail — for workflow purposes, just run the skill.
