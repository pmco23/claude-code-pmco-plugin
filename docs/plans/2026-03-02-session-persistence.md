# Session Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Surface past conversation context automatically at session start and at the beginning of `/brief` and `/init` workflows using the episodic-memory plugin.

**Architecture:** Three lightweight integrations — extend the existing SessionStart hook to sync + write to MEMORY.md, and prepend a visible memory-search step to `/brief` and `/init` skills. No new skills, no end-of-session discipline required.

**Tech Stack:** Bash (hook), Node.js CLI for episodic-memory, Claude Code MCP tool `mcp__plugin_episodic-memory_episodic-memory__search`, Markdown skill files.

---

### Task 1: Extend SessionStart hook — sync + write MEMORY.md

**Files:**
- Modify: `hooks/session_start_check.sh`

**Step 1: Read the current file**

Read `hooks/session_start_check.sh` to understand the existing structure before editing.

**Step 2: Add the episodic-memory block**

Append the following block to `hooks/session_start_check.sh`, after the existing MISSING check and before `exit 0`:

```bash
# --- Episodic memory: sync last session and inject recent context into MEMORY.md ---

EPISODIC_BIN="$HOME/.claude/plugins/cache/superpowers-marketplace/episodic-memory/1.0.15/cli/episodic-memory.js"

if [ ! -f "$EPISODIC_BIN" ]; then
  echo "⚠ claude-agents-custom: episodic-memory not found at expected path — skipping session context injection" >&2
else
  # Sync last session into index (silent)
  node "$EPISODIC_BIN" sync >/dev/null 2>&1

  # Search recent activity across all projects (last 7 days)
  AFTER_DATE=$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
  SEARCH_OUTPUT=$(node "$EPISODIC_BIN" search "recent work" --limit 3 --after "$AFTER_DATE" 2>/dev/null \
    | grep -v "^Loading\|^Embedding\|^Lines\|^$" \
    | sed 's/ - [-0-9]*% match//')

  if [ -n "$SEARCH_OUTPUT" ]; then
    # Compute MEMORY.md path from current working directory
    ENCODED=$(echo "$PWD" | sed 's|^/||; s|/|-|g')
    MEMORY_DIR="$HOME/.claude/projects/-${ENCODED}/memory"
    MEMORY_FILE="$MEMORY_DIR/MEMORY.md"

    mkdir -p "$MEMORY_DIR"

    TODAY=$(date +%Y-%m-%d)
    NEW_BLOCK="<!-- session-context-start -->
## Recent Activity (auto-updated at session start — ${TODAY})

${SEARCH_OUTPUT}
<!-- session-context-end -->"

    if [ -f "$MEMORY_FILE" ] && grep -q "<!-- session-context-start -->" "$MEMORY_FILE"; then
      # Replace existing block between sentinels
      python3 -c "
import sys, re
content = open('$MEMORY_FILE').read()
new_block = '''$NEW_BLOCK'''
result = re.sub(
  r'<!-- session-context-start -->.*?<!-- session-context-end -->',
  new_block,
  content,
  flags=re.DOTALL
)
open('$MEMORY_FILE', 'w').write(result)
"
    elif [ -f "$MEMORY_FILE" ]; then
      # Append to existing file
      printf '\n%s\n' "$NEW_BLOCK" >> "$MEMORY_FILE"
    else
      # Create new file
      printf '%s\n' "$NEW_BLOCK" > "$MEMORY_FILE"
    fi
  fi
fi
```

**Step 3: Verify the script is valid bash**

Run: `bash -n hooks/session_start_check.sh`
Expected: no output (no syntax errors)

**Step 4: Run the script manually to test**

Run: `bash hooks/session_start_check.sh`
Expected: exits without error. Check that MEMORY.md was created or updated:
```bash
cat ~/.claude/projects/-home-pemcoliveira-claude-agents-custom/memory/MEMORY.md
```
Expected: contains `<!-- session-context-start -->` block with at least one recent conversation entry.

**Step 5: Commit**

```bash
git add hooks/session_start_check.sh
git commit -m "feat: extend SessionStart hook — sync episodic memory and inject recent context into MEMORY.md"
```

---

### Task 2: Add Step 0 to `/brief` — surface past decisions before Q&A

**Files:**
- Modify: `skills/brief/SKILL.md:14-16` (insert before `## Process`)

**Step 1: Read the file**

Read `skills/brief/SKILL.md` to get the exact text of the `## Process` section heading and `### Step 1` heading.

**Step 2: Insert Step 0 before Step 1**

The section beginning at `## Process` currently opens directly into `### Step 1: Detect project context`. Insert a new step before it:

Find this exact text:
```
## Process

### Step 1: Detect project context
```

Replace with:
```
## Process

### Step 0: Search past conversations for context

Call `mcp__plugin_episodic-memory_episodic-memory__search` with the user's stated feature or topic as the query (extract it from their message or ask "What feature or task are we working on?" if unclear).

Use `mode: "both"` and `limit: 5`.

**If relevant results are found**, display them visibly before proceeding:

```
Checking past conversations for context on "[topic]"...

Found N relevant conversation(s):
  · [YYYY-MM-DD · project-name] "snippet..."
  · [YYYY-MM-DD · project-name] "snippet..."

Carrying these forward into requirements Q&A.
```

**If no relevant results**, proceed silently to Step 1 with no output.

### Step 1: Detect project context
```

**Step 3: Verify the file looks correct**

Read `skills/brief/SKILL.md` and confirm Step 0 appears before Step 1 with correct markdown heading levels.

**Step 4: Commit**

```bash
git add skills/brief/SKILL.md
git commit -m "feat: add episodic memory search step to /brief"
```

---

### Task 3: Add Step 0 to `/init` — surface past project context before scaffolding

**Files:**
- Modify: `skills/init/SKILL.md:24-26` (insert before `### Step 1`)

**Step 1: Read the file**

Read `skills/init/SKILL.md` to get the exact text around `### Step 1: Extract project context`.

**Step 2: Insert Step 0 before Step 1**

Find this exact text:
```
## Process

### Step 1: Extract project context
```

Replace with:
```
## Process

### Step 0: Search past conversations for project context

Call `mcp__plugin_episodic-memory_episodic-memory__search` with the project name (use the current directory name as the query).

Use `mode: "both"` and `limit: 3`.

**If relevant results are found**, display them visibly before proceeding:

```
Checking past conversations for context on this project...

Found N relevant conversation(s):
  · [YYYY-MM-DD · project-name] "snippet..."

Carrying these forward into project scaffolding.
```

**If no relevant results**, proceed silently to Step 1 with no output.

### Step 1: Extract project context
```

**Step 3: Verify the file looks correct**

Read `skills/init/SKILL.md` and confirm Step 0 appears before Step 1.

**Step 4: Commit**

```bash
git add skills/init/SKILL.md
git commit -m "feat: add episodic memory search step to /init"
```

---

### Task 4: Update docs and dependency check

**Files:**
- Modify: `docs/skills/brief.md`
- Modify: `docs/skills/init.md`
- Modify: `hooks/session_start_check.sh` (add episodic-memory to MISSING check)

**Step 1: Update docs/skills/brief.md**

Append to `docs/skills/brief.md`:

```markdown

## Past context

Before Q&A begins, `/brief` searches past conversations for the stated feature or topic using `episodic-memory`. Found results are displayed visibly and carried forward into requirements extraction.
```

**Step 2: Update docs/skills/init.md**

Append to `docs/skills/init.md`:

```markdown

## Past context

Before scaffolding, `/init` searches past conversations for the project name using `episodic-memory`. Found results are displayed visibly and carried forward.
```

**Step 3: Add episodic-memory to the MISSING check in session_start_check.sh**

In `hooks/session_start_check.sh`, the existing `command -v` checks use this pattern:
```bash
command -v repomix >/dev/null 2>&1 || MISSING+=("repomix — required for /pack and /qa codebase snapshots")
```

The episodic-memory plugin is a Node.js script (not a PATH binary), so instead of `command -v`, add a file-existence check after the other MISSING checks:

```bash
EPISODIC_CHECK="$HOME/.claude/plugins/cache/superpowers-marketplace/episodic-memory/1.0.15/cli/episodic-memory.js"
[ -f "$EPISODIC_CHECK" ] || MISSING+=("episodic-memory plugin — required for session context injection (install via superpowers marketplace)")
```

**Step 4: Verify bash syntax**

Run: `bash -n hooks/session_start_check.sh`
Expected: no output.

**Step 5: Commit**

```bash
git add docs/skills/brief.md docs/skills/init.md hooks/session_start_check.sh
git commit -m "docs: document episodic memory context steps in brief and init; add dependency check"
```

---

### Task 5: Update CHANGELOG and smoke test

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Add entry under `[Unreleased]`**

Add to the `## [Unreleased]` section in `CHANGELOG.md`:

```markdown
### Added
- SessionStart hook now syncs episodic memory and injects a "Recent Activity" block into `MEMORY.md` at the start of every session
- `/brief` Step 0: searches past conversations for the stated feature/topic and displays results before Q&A
- `/init` Step 0: searches past conversations for the project name and displays results before scaffolding
```

**Step 2: Smoke test the hook**

Simulate a new session by running the hook directly:

```bash
bash hooks/session_start_check.sh
```

Check output: no errors, no warnings about episodic-memory being missing.

Check MEMORY.md:
```bash
cat ~/.claude/projects/-home-pemcoliveira-claude-agents-custom/memory/MEMORY.md
```

Run it a second time and verify the sentinel block is replaced (not duplicated).

**Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "chore: update changelog for session persistence via episodic memory"
```
