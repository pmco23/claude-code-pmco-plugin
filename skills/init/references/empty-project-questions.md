# Empty Project Q&A — Three Questions (one per turn)

**Question 1 — Primary language:**

Prefer AskUserQuestion with:
  question: "What is the primary language for this project?"
  header: "Language"
  options:
    - label: "TypeScript / Node.js"
      description: "npm install, tsconfig.json, .js/.ts source files"
    - label: "Go"
      description: "go mod init, .go source files"
    - label: "Python"
      description: "pip / poetry / uv, .py source files"
    - label: "Other"
      description: "Rust, C#, Ruby, Java, or any other — specify in the text field"

If structured prompts are unavailable in this runtime, ask the same question in plain text and include the options inline.

**Question 2 — License:**

Prefer AskUserQuestion with:
  question: "Which license for this project?"
  header: "License"
  options:
    - label: "MIT"
      description: "Permissive — use freely, attribution required"
    - label: "Apache 2.0"
      description: "Permissive — includes patent grant"
    - label: "GPL-3.0"
      description: "Copyleft — derivatives must also be open source"
    - label: "Other / proprietary"
      description: "Specify another SPDX identifier, or 'All rights reserved'"

If structured prompts are unavailable in this runtime, ask the same question in plain text and include the options inline.

**Question 3 — Project type:**

Prefer AskUserQuestion with:
  question: "What kind of project is this?"
  header: "Project type"
  options:
    - label: "CLI tool"
      description: "Command-line application"
    - label: "Web API / service"
      description: "HTTP server, REST or GraphQL API"
    - label: "Library / package"
      description: "Reusable module to be published to a registry"
    - label: "Other / custom"
      description: "Describe it yourself in the text field"

If structured prompts are unavailable in this runtime, ask the same question in plain text and include the options inline.

**After all three answers**, update the context object:
- `language` → from Q1 (or user's free-form text if "Other")
- `license` → from Q2 (or user's free-form text if "Other")
- `description` → `"A [language] [project-type] for [DESCRIPTION]"` — if "Other / custom", use their text or `[DESCRIPTION]` if blank
- `project_name` → directory name (already set)
- `author` → from `git config user.name` if available, otherwise `[AUTHOR]`

Announce before proceeding to Step 2:
```
Context gathered:
  Project:  [directory name]
  Language: [from Q1]
  License:  [from Q2]
  Type:     [from Q3]
  Author:   [from git config or [AUTHOR]]
  Placeholders remaining: [description — fill in after generation]
```
