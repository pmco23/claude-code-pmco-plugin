# Session Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an `/end-session` skill that writes a concise "Last Session" block to `MEMORY.md` and a full summary to `memory/sessions/YYYY-MM-DD.md`, giving Claude always-injected cross-session context.

**Architecture:** One new skill (`skills/end-session/SKILL.md`) that reads git log, `.pipeline/` state, and user input to produce two outputs: a full session file and a lean MEMORY.md block. No changes to existing skills or plugin config — skill discovery is directory-based.

**Tech Stack:** Markdown skill files, Claude Code auto-memory system (`~/.claude/projects/.../memory/`), git CLI, existing `.pipeline/` artifacts.

---

### Task 1: Create the skill skeleton

**Files:**
- Create: `skills/end-session/SKILL.md`

**Step 1: Create the directory and file**

```bash
mkdir -p skills/end-session
```

Write `skills/end-session/SKILL.md` with this content:

```markdown
---
name: end-session
description: Use at the end of a working session to persist session state, decisions, and work log to memory/sessions/ and MEMORY.md. Enables cross-session context restoration.
---

# END-SESSION — Session Persistence

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task.

You are writing a session summary so the next conversation picks up exactly where this one left off.

## Process

### Step 1: Gather automated context

Run the following in parallel:

1. `git log --oneline -10` — recent commits on current branch
2. `git branch --show-current` — current branch name
3. Read `.pipeline/brief.md`, `.pipeline/design.md`, `.pipeline/plan.md`, `.pipeline/build.complete` — check which exist and note the current pipeline phase (use the same phase table as `/status`)
4. Read `memory/MEMORY.md` — note existing content to preserve sections outside "Last Session"

If a file or command fails (no git, no .pipeline/), skip that section silently.

### Step 2: Ask the user two questions

Ask both in a single message:

```
Before I write the session summary, two quick questions:

1. Any decisions worth capturing? (architectural choices, patterns adopted, things to avoid)
   → or type "none"

2. What are the open items / next steps for the next session?
   → or type "none"
```

Wait for the user's response.

### Step 3: Build the session summary

Compose the full session file content:

```markdown
# Session — YYYY-MM-DD [HH:MM]

## Task State
- Branch: <branch or "not in a git repo">
- Pipeline phase: <phase or "no pipeline">
- In progress: <infer from pipeline state + recent commits, or "unclear">

## Work Done
<list of git commits, one per line as "- <sha> <message>", or "- Nothing committed this session">

## Decisions Made
<user's answer to question 1, or "None">

## Open Items / Next Steps
<user's answer to question 2, or "None">
```

### Step 4: Write the session file

Determine the path: `memory/sessions/YYYY-MM-DD.md` where the date is today.

- If `memory/sessions/` does not exist, create it.
- If the file already exists (multiple sessions in one day), append `\n---\n` followed by the new session block.
- If the file does not exist, write it fresh.

### Step 5: Update MEMORY.md

The "Last Session" block is a fixed-format section bounded by these sentinel comments:

```
<!-- last-session-start -->
...
<!-- last-session-end -->
```

**If MEMORY.md exists and contains these sentinels:** replace everything between them (inclusive) with the new block.

**If MEMORY.md exists but has no sentinels:** append the new block at the end of the file.

**If MEMORY.md does not exist:** create it with only the new block.

The block format:

```markdown
<!-- last-session-start -->
## Last Session — YYYY-MM-DD

**Branch:** <branch> | **Pipeline:** <phase>
**Worked on:** <one-line summary inferred from commits + pipeline>
**Shipped:** <comma-separated commit messages, or "nothing committed">
**Decisions:** <user's answer to question 1, truncated to one line, or "none">
**Next:** <user's answer to question 2, truncated to one line, or "none">
→ Full notes: memory/sessions/YYYY-MM-DD.md
<!-- last-session-end -->
```

### Step 6: Confirm

Report to the user:

```
Session saved.
  → memory/sessions/YYYY-MM-DD.md  (full summary)
  → memory/MEMORY.md  (Last Session block updated)

This context will be injected automatically at the start of your next conversation.
```
```

**Step 2: Verify the file was created**

Run: `ls skills/end-session/`
Expected: `SKILL.md`

**Step 3: Commit**

```bash
git add skills/end-session/SKILL.md
git commit -m "feat: add /end-session skill skeleton"
```

---

### Task 2: Add the docs entry

**Files:**
- Create: `docs/skills/end-session.md`

**Step 1: Write the docs file**

```markdown
# /end-session — Session Persistence

**Gate:** None (always available)
**Writes:** `memory/sessions/YYYY-MM-DD.md`, `memory/MEMORY.md`
**Model:** Haiku

Persists session context so the next conversation resumes with full awareness of what was done, what decisions were made, and what's next. Run this at the end of every working session.

## Usage

```
/end-session
```

## Outputs

| File | Content |
|------|---------|
| `memory/sessions/YYYY-MM-DD.md` | Full session summary (branch, commits, decisions, next steps) |
| `memory/MEMORY.md` | Concise "Last Session" block auto-injected into every future conversation |

## Multiple sessions per day

Running `/end-session` twice on the same day appends a second block (separated by `---`) to the existing session file. MEMORY.md always reflects the most recent session.

## Notes

- If there is no git repository, the "Shipped" section is omitted.
- If there is no `.pipeline/` directory, pipeline state is omitted.
- The session file is plain markdown — you can read it directly or search it with `episodic-memory:search-conversations`.
```

**Step 2: Commit**

```bash
git add docs/skills/end-session.md
git commit -m "docs: add /end-session skill reference"
```

---

### Task 3: Smoke test the skill manually

**Step 1: Invoke the skill in the current session**

Run `/end-session` (use the Skill tool or type it in a new message).

**Step 2: Verify session file was created**

Run: `ls ~/.claude/projects/-home-pemcoliveira-claude-agents-custom/memory/sessions/`
Expected: a file named `2026-03-02.md` (today's date).

**Step 3: Verify MEMORY.md was updated**

Run: `cat ~/.claude/projects/-home-pemcoliveira-claude-agents-custom/memory/MEMORY.md`
Expected: contains `<!-- last-session-start -->` ... `<!-- last-session-end -->` block with today's date.

**Step 4: Verify content is correct**

Read the session file. Confirm:
- Branch name is correct
- At least one commit appears in "Work Done" (the commits from this session)
- Decisions and next steps match what was entered

**Step 5: Commit verification note**

```bash
git add -A
git commit -m "chore: verify /end-session smoke test passes" --allow-empty
```

(Use `--allow-empty` only if nothing was changed by the smoke test itself.)

---

### Task 4: Update CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Add entry under `[Unreleased]`**

Add to the `## [Unreleased]` section:

```markdown
### Added
- `/end-session` skill — persists session state, decisions, and work log to `memory/sessions/` and `memory/MEMORY.md` for cross-session context restoration
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "chore: update changelog for /end-session"
```
