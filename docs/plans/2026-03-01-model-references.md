# Model References Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a formal `> **Model:**` block to every skill that is missing one, so all 19 skills consistently document their intended model tier.

**Architecture:** Pure documentation edits — insert one blockquote after the `## Role` header in each SKILL.md. No logic changes. 5 skills already have the block; 14 need it added. Grouped into 4 tasks by tier/batch.

**Tech Stack:** Markdown only.

---

### Task 1: Add Opus block to `review`

**Files:**
- Modify: `skills/review/SKILL.md`

**Step 1: Edit the file**

In `skills/review/SKILL.md`, find:

```
## Role

You are Opus acting as a review team lead.
```

Replace with:

```
## Role

> **Model:** Opus (`claude-opus-4-6`). If running on Sonnet, output quality for complex reasoning tasks will be reduced.

You are Opus acting as a review team lead.
```

**Step 2: Verify**

Read `skills/review/SKILL.md` lines 1–15 and confirm the blockquote appears between `## Role` and `You are Opus`.

**Step 3: Commit**

```bash
git add skills/review/SKILL.md
git commit -m "docs: add model reference to /review — Opus"
```

---

### Task 2: Add Sonnet blocks — QA audit skills

**Files:**
- Modify: `skills/backend-audit/SKILL.md`
- Modify: `skills/frontend-audit/SKILL.md`
- Modify: `skills/doc-audit/SKILL.md`
- Modify: `skills/security-review/SKILL.md`

All four follow the same pattern. In each file, find:

```
## Role

You are Sonnet acting as a [role description].
```

Insert the blockquote so it becomes:

```
## Role

> **Model:** Sonnet (`claude-sonnet-4-6`). If running on Haiku, output quality may be reduced for tasks requiring judgment.

You are Sonnet acting as a [role description].
```

**Step 1: Edit `skills/backend-audit/SKILL.md`**

Find `## Role\n\nYou are Sonnet acting as a backend code reviewer.` and insert the blockquote between the header and the paragraph.

**Step 2: Edit `skills/frontend-audit/SKILL.md`**

Find `## Role\n\nYou are Sonnet acting as a frontend code reviewer.` and insert the blockquote.

**Step 3: Edit `skills/doc-audit/SKILL.md`**

Find `## Role\n\nYou are Sonnet acting as a documentation auditor.` and insert the blockquote.

**Step 4: Edit `skills/security-review/SKILL.md`**

Find `## Role\n\nYou are Sonnet acting as a security auditor.` and insert the blockquote.

**Step 5: Verify**

Read the `## Role` section of each of the 4 files and confirm the blockquote is present between the header and the `You are Sonnet` line.

**Step 6: Commit**

```bash
git add skills/backend-audit/SKILL.md skills/frontend-audit/SKILL.md skills/doc-audit/SKILL.md skills/security-review/SKILL.md
git commit -m "docs: add model references to QA audit skills — Sonnet"
```

---

### Task 3: Add Sonnet blocks — orchestration and standalone skills

**Files:**
- Modify: `skills/qa/SKILL.md`
- Modify: `skills/quick/SKILL.md`
- Modify: `skills/init/SKILL.md`
- Modify: `skills/git-workflow/SKILL.md`
- Modify: `skills/grafana/SKILL.md`
- Modify: `skills/plugin-architecture/SKILL.md`

**Step 1: Edit `skills/qa/SKILL.md`**

`qa` has no `## Role` header — its first section is `## Repomix Preamble`. Add a `## Role` section at the top of the file body (after the frontmatter `---`), before `## Repomix Preamble`:

```markdown
## Role

> **Model:** Sonnet (`claude-sonnet-4-6`). If running on Haiku, output quality may be reduced for tasks requiring judgment.

You are Sonnet acting as a QA pipeline orchestrator. Acquire a Repomix pack, then dispatch the five audit agents according to the selected mode.

```

**Step 2: Edit `skills/quick/SKILL.md`**

Find:

```
## Role

You are Sonnet (or Opus with `--deep`) acting as a focused implementer.
```

Insert the blockquote. Note the `--deep` escalation in the wording:

```
## Role

> **Model:** Sonnet (`claude-sonnet-4-6`) by default. Use `--deep` to escalate to Opus for trickier problems. If running on Haiku, output quality may be reduced for tasks requiring judgment.

You are Sonnet (or Opus with `--deep`) acting as a focused implementer.
```

**Step 3: Edit `skills/init/SKILL.md`**

Find `## Role\n\nYou are Sonnet acting as a project scaffolder.` and insert the standard Sonnet blockquote.

**Step 4: Edit `skills/git-workflow/SKILL.md`**

Find `## Role\n\nYou are enforcing git discipline` and insert the standard Sonnet blockquote before that line.

**Step 5: Edit `skills/grafana/SKILL.md`**

Find `## Role\n\nYou are an SRE assistant` and insert the standard Sonnet blockquote.

**Step 6: Edit `skills/plugin-architecture/SKILL.md`**

`plugin-architecture` has no `## Role` header — its first section is `## Core Distinction`. Add a `## Role` section at the top of the file body (after the frontmatter `---`), before `## Core Distinction`:

```markdown
## Role

> **Model:** Sonnet (`claude-sonnet-4-6`). If running on Haiku, output quality may be reduced for tasks requiring judgment.

You are a Claude Code plugin architecture advisor. Present the framework below and apply it to the user's specific question.

```

**Step 7: Verify**

Read the `## Role` section of each of the 6 files and confirm the blockquote is present.

**Step 8: Commit**

```bash
git add skills/qa/SKILL.md skills/quick/SKILL.md skills/init/SKILL.md skills/git-workflow/SKILL.md skills/grafana/SKILL.md skills/plugin-architecture/SKILL.md
git commit -m "docs: add model references to orchestration and standalone skills — Sonnet"
```

---

### Task 4: Add Haiku blocks — mechanical skills

**Files:**
- Modify: `skills/status/SKILL.md`
- Modify: `skills/pack/SKILL.md`
- Modify: `skills/cleanup/SKILL.md`

**Step 1: Edit `skills/status/SKILL.md`**

Find `## Role\n\nYou are reporting the current pipeline phase` and insert:

```
## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

You are reporting the current pipeline phase to the user.
```

**Step 2: Edit `skills/pack/SKILL.md`**

Find `## Role\n\nPack the current project` and insert:

```
## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

Pack the current project into a compressed Repomix snapshot.
```

**Step 3: Edit `skills/cleanup/SKILL.md`**

Find `## Role\n\nYou are Sonnet acting as a code cleaner.` and replace with:

```
## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

You are acting as a code cleaner.
```

Note: Remove "You are Sonnet" from the body — the blockquote is now the canonical model reference. This avoids a contradiction between saying "You are Sonnet" while the block says Haiku.

**Step 4: Verify**

Read the `## Role` section of all three files and confirm:
- Haiku blockquote is present in each
- `status` and `pack` have no "You are Sonnet" contradiction
- `cleanup` no longer says "You are Sonnet" in the body

**Step 5: Verify complete coverage**

Run:

```bash
grep -l "Model:" skills/*/SKILL.md | wc -l
```

Expected: `19` (all skills have a model reference).

**Step 6: Commit**

```bash
git add skills/status/SKILL.md skills/pack/SKILL.md skills/cleanup/SKILL.md
git commit -m "docs: add model references to mechanical skills — Haiku (status, pack, cleanup)"
```
