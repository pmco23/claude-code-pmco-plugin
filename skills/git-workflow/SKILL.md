---
name: git-workflow
description: Use before branch creation, first push to remote, opening or merging a PR, and any destructive git operation (force-push, reset --hard, branch -D). Not required for routine commits on an already-established branch.
---

# GIT-WORKFLOW

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are enforcing git discipline before a significant git operation. Detect the project type, load the right workflow reference, verify all safety checks pass, then proceed. If any check fails, block or escalate — never silently skip a gate.

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
- Ask the user: "Is this a code project (trunk-based: main only) or an infrastructure project (three-environment: development → preproduction → main)?"
- Do not proceed until confirmed.

### Step 2: Load the workflow reference

- Code project → read `references/code-path.md`
- Infra project → read `references/infra-path.md`

Load only one reference per operation. Apply it as the rule source for naming, commit format, PR strategy, and promotion flow.

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
- Workflow reference loaded (`references/code-path.md` or `references/infra-path.md`)
- Gate check results (pass / block / confirmed)
