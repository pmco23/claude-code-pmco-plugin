---
name: git-workflow
description: Use before branch creation, first push to remote, opening or merging a PR, and any destructive git operation (force-push, reset --hard, branch -D). Not required for routine commits on an already-established branch.
---

# GIT-WORKFLOW

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are enforcing git discipline before a significant git operation. Detect the project type, load the right workflow reference, verify all safety checks pass, then proceed. If any check fails, block or escalate — never silently skip a gate.

## Hard Rules

1. **One question per turn.** If both project type and operation parameters are ambiguous, resolve project type first. Never ask multiple clarifying questions in a single response.
2. **All questions use AskUserQuestion.** Provide options covering the plausible choices; include `"Other / let me explain"` when the option space can't be fully enumerated. Never ask a plain-text question.
3. **Never execute a git operation until all safety gate checks pass.** If any check fails, block and explain — do not proceed silently.
4. **Destructive operations require explicit confirmation.** Force-push, `reset --hard`, and `branch -D` are never performed without an explicit user "proceed" response in the current turn. A previous approval in a different context does not carry over.

## Process

### Step 1: Detect project type

Use a two-tier check. Stop as soon as a tier yields a conclusive answer.

**Tier 1 — root-level config files (check first, most reliable)**

Look only at the repo root directory (not subdirectories).

Root-level **code config** (any match → code project):
- `package.json`, `go.mod`, `requirements.txt`, `pyproject.toml`, `setup.py`, `Cargo.toml`, `*.csproj`, `*.sln`, `pom.xml`, `build.gradle`

Root-level **infra config** (any match, and no code config found → infra project):
- `*.tf` or `*.tfvars` — Terraform root module
- `Chart.yaml` — Helm chart root
- `kustomization.yaml` or `kustomization.yml` — Kustomize root

If both code config and infra config exist at root (genuine mixed-root monorepo), skip to the disambiguation question below.

**Tier 2 — repo-wide heuristic (only if Tier 1 found neither)**

Scan the full repo for signals:

Infra signals:
- Directories named `helm`, `terraform`, `kustomize`, `manifests`
- Files matching `*.tf`, `*.tfvars` anywhere in the repo

Code signals:
- Files matching `*.ts`, `*.tsx`, `*.js`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.cs`

If only infra signals found → infra project.
If only code signals found → code project.

**If still ambiguous** (both tiers match both types, or neither tier found anything):

Use AskUserQuestion with:
  question: "Is this a code project or an infrastructure project?"
  header: "Project type"
  options:
    - label: "Code project"
      description: "Trunk-based: feature/fix branches, squash-merge to main"
    - label: "Infrastructure project"
      description: "Three-environment: development → preproduction → main promotion"

Do not proceed until confirmed.

### Step 1.5: Identify the operation and gather parameters

Run `git status` and `git branch --show-current` to read the current state.

Determine which operation the user is requesting from their invocation args or context:

| Operation | Parameters needed |
|-----------|-----------------|
| Branch creation | Intended branch name |
| First push to remote | Remote name, branch name |
| PR open | PR title, target branch |
| PR merge | PR number or title |
| Destructive op (force-push, reset --hard, branch -D) | Specific target ref |

If the operation is clear from the invocation: extract parameters silently and proceed.
If the operation is ambiguous, use AskUserQuestion with:
  question: "Which git operation are you performing?"
  header: "Git operation"
  options:
    - label: "Branch creation"
      description: "Create a new branch from current HEAD"
    - label: "First push to remote"
      description: "Push a local branch to the remote for the first time"
    - label: "Open or merge a PR"
      description: "Open a new PR or merge an existing one"
    - label: "Destructive operation"
      description: "Force-push, reset --hard, branch -D, or rebase on published commits"

Record the operation type and parameters — Steps 3–4 apply the safety gate to this specific operation.

### Step 2: Load the workflow reference

Read the appropriate path rules from this skill's base directory:
`references/code-path.md` (code) or `references/infra-path.md` (infra). Apply those rules when executing the operation.

### Step 3: Safety gate

Verify all of the following before proceeding:

- [ ] **Branch name** matches the selected path convention (spec: https://conventional-branch.github.io/)
- [ ] **Commit message** matches the selected path convention (spec: https://www.conventionalcommits.org/en/v1.0.0/)
  - If not: rewrite the message to conform before proceeding. Do not commit with a non-conforming message.
  - When explaining why a branch name or commit message fails validation, cite the relevant spec URL so the user knows the source of the rule.
- [ ] **Operation is not destructive** (force-push, reset --hard, branch -D, rebase on published commits)
  - If destructive: stop and ask the user for explicit confirmation before proceeding.
  - If the user requests force-push to a protected branch repeatedly: escalate — do not comply silently.
- [ ] **Target branch is not protected** (main, master, development, preproduction) for direct push
  - If protected: block and warn — use a PR instead.
  - If the promotion path is unclear in a three-environment project: escalate rather than guess.

### Step 4: Proceed

Once all gate checks pass, perform the git operation.

## Output

- Detected project type (code / infra / confirmed by user)
- Workflow reference applied (Code Path or Infra Path)
- Gate check results (pass / block / confirmed)
