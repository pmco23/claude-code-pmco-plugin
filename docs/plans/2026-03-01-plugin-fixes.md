# Plugin Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix six findings from a deep plugin audit: narrow the PostToolUse hook matcher, correct a wrong README verification step, fix ambiguous /quick audit wording, add a codebase scan step to /plan, fix statusline directory walk, and research/implement skill model enforcement.

**Architecture:** Six independent fixes across hooks, SKILL.md files, a JS hook, and the README. Each fix is self-contained — no ordering dependencies except the test suite runs after every task. Tasks are ordered smallest to largest.

**Tech Stack:** Bash hooks, JSON config, Node.js (statusline), Markdown (SKILL.md files), shell test suite (`hooks/test_gate.sh`, 44 tests).

---

### Task 1: F3 — Narrow context-monitor.sh PostToolUse matcher

**Files:**
- Modify: `hooks/hooks.json`

The PostToolUse matcher is currently `"*"`, which fires context-monitor.sh on every single tool call. Narrowing to `Bash` and `Agent` (the operations that actually grow context significantly) eliminates the overhead on reads, writes, edits, and other lightweight calls.

**Step 1: Read current hooks.json**

Read `hooks/hooks.json` to confirm the current PostToolUse block.

**Step 2: Replace the PostToolUse block**

Find:
```json
"PostToolUse": [
  {
    "matcher": "*",
    "hooks": [
      {
        "type": "command",
        "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/context-monitor.sh\""
      }
    ]
  }
]
```

Replace with two matchers:
```json
"PostToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      {
        "type": "command",
        "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/context-monitor.sh\""
      }
    ]
  },
  {
    "matcher": "Agent",
    "hooks": [
      {
        "type": "command",
        "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/context-monitor.sh\""
      }
    ]
  }
]
```

**Step 3: Validate JSON**

```bash
python3 -m json.tool hooks/hooks.json
```

Expected: valid JSON printed, no error.

**Step 4: Run test suite**

```bash
bash hooks/test_gate.sh
```

Expected: 44/44 tests pass.

**Step 5: Commit**

```bash
git add hooks/hooks.json
git commit -m "fix: narrow PostToolUse matcher from * to Bash and Agent"
```

---

### Task 2: F2 — Fix README Codex MCP verification instruction

**Files:**
- Modify: `README.md` (Codex MCP Setup section, Step 3)

The current Step 3 says "Run `/status`. If `mcp__codex__codex` appears in the available tools list, the server is connected." This is wrong — `/status` only reports pipeline artifacts, not available tools.

**Step 1: Read the current Codex MCP Setup section**

Read `README.md` lines 52–89 to see the exact current text of Step 3.

**Step 2: Replace the verification step**

Find:
```markdown
**3. Verify**

Start a Claude Code session and run:

```
/status
```

If `mcp__codex__codex` appears in the available tools list, the server is connected.
```

Replace with:
```markdown
**3. Verify**

Start a Claude Code session. At startup, Claude Code logs which MCP servers connected successfully — look for a line confirming the `codex` server. Then run:

```
/review
```

If the Codex MCP is connected, `/review` will dispatch Agent 2 via `mcp__codex__codex`. If it is not connected, `/review` will fall back to a second Opus subagent and note "Codex MCP unavailable" in the report.
```

**Step 3: Run test suite**

```bash
bash hooks/test_gate.sh
```

Expected: 44/44 pass.

**Step 4: Commit**

```bash
git add README.md
git commit -m "fix: correct Codex MCP verification instruction in README"
```

---

### Task 3: F5 — Fix /quick audit wording for LSP diagnostics

**Files:**
- Modify: `skills/quick/SKILL.md`

Step 7 currently says "Report any errors or warnings introduced by the change (not pre-existing ones)." The skill never establishes a baseline before the change, so distinguishing new from pre-existing diagnostics is not implementable. The instruction should match what can actually be done.

**Step 1: Read the current Step 7 in skills/quick/SKILL.md**

Read the file and locate the LSP diagnostics subsection under Step 7.

**Step 2: Replace the ambiguous instruction**

Find (within the `**LSP diagnostics (if available):**` block):
```markdown
- Request diagnostics for each modified file
- Report any errors or warnings introduced by the change (not pre-existing ones)
```

Replace with:
```markdown
- Request diagnostics for each modified file
- Report all errors and warnings found — note that pre-existing issues unrelated to this change may also appear
```

**Step 3: Run test suite**

```bash
bash hooks/test_gate.sh
```

Expected: 44/44 pass.

**Step 4: Commit**

```bash
git add skills/quick/SKILL.md
git commit -m "fix: clarify /quick LSP diagnostics wording — can't distinguish new from pre-existing"
```

---

### Task 4: F1 — Add codebase scan step to /plan

**Files:**
- Modify: `skills/plan/SKILL.md`

The plan skill writes exact file paths and code from design.md alone, without ever looking at the actual project layout. This causes builder friction when paths don't match reality. Add a Step 2 that scans the real directory structure before writing the plan, then renumber the existing steps.

**Step 1: Read skills/plan/SKILL.md in full**

Confirm the current step numbering: Step 1 (read design and brief), Step 2 (decompose into task groups), Step 3 (order and dependency mapping), Step 4 (write the plan), Step 5 (cross-check for conflicts).

**Step 2: Insert new Step 2 — project structure scan**

After Step 1 ("Read design and brief"), insert:

```markdown
### Step 2: Ground file paths in the actual project structure

Before writing any task group, scan the real project layout so the plan's file paths match reality.

1. List the root directory contents (one level)
2. List source directories one level deep — look for common roots: `src/`, `app/`, `lib/`, `pkg/`, `cmd/`, `internal/`, `frontend/`, `backend/`
3. If not already read in Step 1, read the primary language config file (`package.json`, `go.mod`, `requirements.txt`, `*.csproj`) to confirm module name and structure
4. Note actual directory names and naming conventions (kebab-case vs snake_case, flat vs nested)

Use this scan to:
- Correct any file paths in the design that don't match the real layout
- Ensure new files are placed in existing directories where possible
- Flag in the task group if a new directory needs to be created first
```

**Step 3: Renumber existing steps**

- Old Step 2 → Step 3
- Old Step 3 → Step 4
- Old Step 4 → Step 5
- Old Step 5 → Step 6

Update all internal cross-references ("Before finalizing" in old Step 5 refers to "Step 5" — update to "Step 6").

**Step 4: Verify**

Read `skills/plan/SKILL.md` and confirm:
- New Step 2 is present after Step 1
- Steps 3–6 are correctly numbered
- No internal cross-references still point to old numbers

**Step 5: Run test suite**

```bash
bash hooks/test_gate.sh
```

Expected: 44/44 pass.

**Step 6: Commit**

```bash
git add skills/plan/SKILL.md
git commit -m "feat: add codebase scan step to /plan to ground file paths in real project structure"
```

---

### Task 5: F4 — Fix statusline.js pipeline phase directory walk

**Files:**
- Modify: `hooks/statusline.js`

The statusline reads `.pipeline/` from `path.join(dir, '.pipeline')` where `dir` is the workspace root. The pipeline gate walks up from `$PWD` to find `.pipeline/`. These should match — if Claude is opened in a project subdirectory, the gate finds the pipeline but the statusline doesn't show its phase.

**Step 1: Read hooks/statusline.js**

Locate the pipeline phase detection block (lines 78–95). Confirm the current code:

```javascript
let phase = '';
const pipelineDir = path.join(dir, '.pipeline');
try {
  if (fs.existsSync(path.join(pipelineDir, 'build.complete'))) {
    phase = 'qa ready';
  } ...
} catch (e) { }
```

**Step 2: Replace the pipeline phase block**

Replace the entire pipeline phase detection section (from `// Pipeline phase from .pipeline/ artifacts in cwd` through the closing `} catch (e) { }`) with:

```javascript
// Pipeline phase — walk up from dir to find .pipeline/ (mirrors pipeline_gate.sh)
let phase = '';
try {
  let searchDir = dir;
  let pipelineDir = null;
  while (true) {
    const candidate = path.join(searchDir, '.pipeline');
    if (fs.existsSync(candidate)) {
      pipelineDir = candidate;
      break;
    }
    const parent = path.dirname(searchDir);
    if (parent === searchDir) break; // reached filesystem root
    searchDir = parent;
  }
  if (pipelineDir) {
    if (fs.existsSync(path.join(pipelineDir, 'build.complete'))) {
      phase = 'qa ready';
    } else if (fs.existsSync(path.join(pipelineDir, 'plan.md'))) {
      phase = 'plan ready';
    } else if (fs.existsSync(path.join(pipelineDir, 'design.approved'))) {
      phase = 'design approved';
    } else if (fs.existsSync(path.join(pipelineDir, 'design.md'))) {
      phase = 'design';
    } else if (fs.existsSync(path.join(pipelineDir, 'brief.md'))) {
      phase = 'brief';
    }
  }
} catch (e) {
  // Silent fail
}
```

**Step 3: Run test suite**

```bash
bash hooks/test_gate.sh
```

Expected: 44/44 pass.

**Step 4: Commit**

```bash
git add hooks/statusline.js
git commit -m "fix: statusline pipeline phase now walks up directories to find .pipeline/"
```

---

### Task 6: F6 — Skill model enforcement

**Files:**
- Modify: `skills/brief/SKILL.md`, `skills/design/SKILL.md`, `skills/plan/SKILL.md`, `skills/build/SKILL.md`, `skills/drift-check/SKILL.md` (conditionally, based on research)
- Possibly modify: `README.md`

Skills say "You are Opus" in their Role section but skill frontmatter may not support a `model:` field (unlike agent frontmatter which does). Research first, then implement the best available option.

**Step 1: Check if SKILL.md frontmatter supports `model:` field**

Search for any existing skill in the plugin marketplace cache that uses a `model:` field:

```bash
grep -r "^model:" ~/.claude/plugins/cache/ 2>/dev/null | head -20
```

Also check the Claude Code docs via WebFetch or WebSearch: "Claude Code SKILL.md frontmatter model field".

**Step 2: Branch on finding**

**If `model:` IS supported in skill frontmatter:**

Add `model: claude-opus-4-6` to the frontmatter of:
- `skills/brief/SKILL.md`
- `skills/design/SKILL.md`
- `skills/plan/SKILL.md`
- `skills/build/SKILL.md`
- `skills/drift-check/SKILL.md`

Add `model: claude-sonnet-4-6` to:
- `skills/quick/SKILL.md`

**If `model:` is NOT supported in skill frontmatter:**

Add a model advisory line at the top of the Role section for each Opus skill. The advisory appears in the instructions Claude reads, so whatever model is running will know and can surface this to the user.

For `/brief`, `/design`, `/plan` — add after "## Role":
```markdown
> **Model recommendation:** This skill is designed for Opus. If running on Sonnet, output quality for complex requirements may be reduced. To use Opus, start your message with `opus:` or switch models before invoking.
```

For `/build` — add after "## Role":
```markdown
> **Model recommendation:** The build lead role is designed for Opus. Sonnet builders are expected — only the lead (current model) should be Opus.
```

**Step 3: Run test suite**

```bash
bash hooks/test_gate.sh
```

Expected: 44/44 pass.

**Step 4: Commit**

```bash
git add skills/brief/SKILL.md skills/design/SKILL.md skills/plan/SKILL.md skills/build/SKILL.md skills/drift-check/SKILL.md
git commit -m "feat: add model enforcement/advisory to Opus-targeted skills"
```

---

### Task 7: Final verification and push

**Step 1: Confirm all six fixes are in git log**

```bash
git log --oneline -8
```

Expected: 6 commits from Tasks 1–6 on top of `bd9104e`.

**Step 2: Run full test suite one final time**

```bash
bash hooks/test_gate.sh
```

Expected: 44/44 pass.

**Step 3: Push**

```bash
git push
```
