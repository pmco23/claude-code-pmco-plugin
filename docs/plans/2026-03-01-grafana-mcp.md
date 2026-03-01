# Grafana MCP Bundle and `/grafana` Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bundle mcp-grafana as a plugin MCP server and create a `/grafana` skill that acts as a standalone SRE toolbox using a capability catalogue + ReAct execution loop.

**Architecture:** Three changes — add `mcp-grafana` to `plugin.json` mcpServers, create `skills/grafana/SKILL.md` with a full tool catalogue and ReAct loop, and add `uvx` to `session_start_check.sh`. No scripts, no tests (prose/config changes only).

**Tech Stack:** JSON (`plugin.json`), Markdown (`skills/grafana/SKILL.md`), Bash (`hooks/session_start_check.sh`)

---

### Task 1: Add `mcp-grafana` to `.claude-plugin/plugin.json`

**Files:**
- Modify: `.claude-plugin/plugin.json`

**Step 1: Read the current file**

Read `.claude-plugin/plugin.json` in full. It currently declares `codex` and `repomix` under `mcpServers`.

**Step 2: Add `mcp-grafana` entry**

Add a third entry inside `mcpServers`, after the `repomix` block:

```json
"mcp-grafana": {
  "command": "uvx",
  "args": [
    "mcp-grafana",
    "--enabled-tools", "search,prometheus,loki,datasource,alerting,dashboard,asserts,sift,navigation,rendering,examples,searchlogs,runpanelquery"
  ],
  "env": {
    "GRAFANA_URL": "${GRAFANA_URL}",
    "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${GRAFANA_SERVICE_ACCOUNT_TOKEN}"
  }
}
```

The complete file should look like:

```json
{
  "name": "claude-agents-custom",
  "version": "1.3.0",
  "description": "Quality-gated development pipeline: brief → design → review → plan → build → qa",
  "author": {
    "name": "pemcoliveira"
  },
  "keywords": ["pipeline", "quality-gates", "tdd", "adversarial-review"],
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"]
    },
    "repomix": {
      "command": "repomix",
      "args": ["--mcp"]
    },
    "mcp-grafana": {
      "command": "uvx",
      "args": [
        "mcp-grafana",
        "--enabled-tools", "search,prometheus,loki,datasource,alerting,dashboard,asserts,sift,navigation,rendering,examples,searchlogs,runpanelquery"
      ],
      "env": {
        "GRAFANA_URL": "${GRAFANA_URL}",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${GRAFANA_SERVICE_ACCOUNT_TOKEN}"
      }
    }
  }
}
```

**Step 3: Verify**

Read `.claude-plugin/plugin.json` and confirm:
- `mcpServers` has three entries: `codex`, `repomix`, `mcp-grafana`
- `mcp-grafana` command is `uvx`, first arg is `mcp-grafana`
- `--enabled-tools` value is the full comma-separated list
- `env` contains `GRAFANA_URL` and `GRAFANA_SERVICE_ACCOUNT_TOKEN`

**Step 4: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: bundle mcp-grafana as plugin MCP server"
```

---

### Task 2: Create `skills/grafana/SKILL.md`

**Files:**
- Create: `skills/grafana/SKILL.md`

**Step 1: Create the directory and file**

Create `skills/grafana/SKILL.md` with the following complete content:

````markdown
---
name: grafana
description: Use for any Grafana observability task — querying metrics, exploring dashboards, investigating logs, checking alerts, rendering panels, running Sift investigations, or searching logs. Accepts free-text tasks and uses a ReAct loop to pick the right tools. Requires GRAFANA_URL and GRAFANA_SERVICE_ACCOUNT_TOKEN in the environment.
---

# GRAFANA — SRE Toolbox

## Role

You are an SRE assistant with full access to a local Grafana instance. You receive a free-text task and work through it using the available MCP tools, reasoning step-by-step until the task is complete.

**Prerequisites:** The following environment variables must be set before MCP tools will work:
- `GRAFANA_URL` — e.g. `http://localhost:3000`
- `GRAFANA_SERVICE_ACCOUNT_TOKEN` — a Grafana service account token with the required permissions

If either is missing, stop and tell the user: "Set GRAFANA_URL and GRAFANA_SERVICE_ACCOUNT_TOKEN in your environment, then retry."

## Capability Catalogue

All tools available via the `mcp-grafana` MCP server (prefix: `mcp__mcp-grafana__`):

### Search
| Tool | Description |
|------|-------------|
| `search_dashboards` | Find dashboards by title, tag, or folder |

### Dashboard
| Tool | Description |
|------|-------------|
| `get_dashboard_by_uid` | Retrieve full dashboard JSON by UID |
| `get_dashboard_summary` | Compact overview — use instead of full JSON when exploring |
| `get_dashboard_property` | Extract a specific field using a JSONPath expression |
| `get_dashboard_panel_queries` | Get panel titles, queries, and datasource info |
| `update_dashboard` | Create or fully replace a dashboard |
| `patch_dashboard` | Apply targeted changes without sending full JSON |

### Prometheus
| Tool | Description |
|------|-------------|
| `query_prometheus` | Execute a PromQL instant or range query |
| `query_prometheus_histogram` | Calculate histogram percentile (e.g. p99 latency) |
| `list_prometheus_metric_names` | List all available metric names |
| `list_prometheus_metric_metadata` | Retrieve metadata (type, help) for metrics |
| `list_prometheus_label_names` | List label names matching a selector |
| `list_prometheus_label_values` | List values for a specific label |

### Loki
| Tool | Description |
|------|-------------|
| `query_loki_logs` | Run a LogQL log or metric query |
| `query_loki_stats` | Statistics about log streams matching a selector |
| `query_loki_patterns` | Detected log patterns for a stream |
| `list_loki_label_names` | All available log label names |
| `list_loki_label_values` | Values for a specific log label |

### Datasource
| Tool | Description |
|------|-------------|
| `list_datasources` | List all configured datasources |
| `get_datasource` | Details for a datasource by UID or name |

### Alerting
| Tool | Description |
|------|-------------|
| `list_alert_rules` | List alert rules and their current status |
| `get_alert_rule_by_uid` | Retrieve a specific alert rule by UID |
| `create_alert_rule` | Create a new alert rule |
| `update_alert_rule` | Modify an existing alert rule |
| `delete_alert_rule` | Remove an alert rule by UID |
| `list_contact_points` | List configured notification contact points |

### Asserts
| Tool | Description |
|------|-------------|
| `get_asserts_summary` | Retrieve assertion summary for a service or namespace |

### Sift
| Tool | Description |
|------|-------------|
| `list_sift_investigations` | List available Sift investigations |
| `get_sift_investigation` | Details of a specific investigation by UUID |
| `get_sift_analyses` | A specific analysis from an investigation |
| `find_error_patterns_in_logs` | Detect elevated error patterns in Loki logs |
| `find_slow_requests` | Detect slow requests in traces |

### Navigation
| Tool | Description |
|------|-------------|
| `generate_deeplinks` | Create accurate deeplink URLs to dashboards or panels |

### Rendering
| Tool | Description |
|------|-------------|
| `get_panel_image` | Render a dashboard panel as a PNG image |
| `get_dashboard_image` | Render a full dashboard as a PNG image |

### Examples
| Tool | Description |
|------|-------------|
| `get_query_examples` | Retrieve example queries for a datasource type |

### SearchLogs
| Tool | Description |
|------|-------------|
| `search_logs` | High-level log search across Loki (and ClickHouse if configured) |

### RunPanelQuery
| Tool | Description |
|------|-------------|
| `run_panel_query` | Execute a dashboard panel's query with custom time range and variable overrides |

## Execution: ReAct Loop

For each step:

1. **Reason** — state in one sentence what you need to find out or do next, and which tool from the catalogue fits
2. **Act** — call the tool
3. **Observe** — read the result
4. **Decide** — is the task complete? If yes, go to Output. If not, return to Reason with updated context.

**Tips:**
- Start broad (search, list) before going narrow (get by UID, query specific metric)
- Use `get_dashboard_summary` instead of `get_dashboard_by_uid` unless you need full JSON — it uses far fewer tokens
- Use `list_datasources` first when you need to know which Prometheus or Loki UID to pass to query tools
- Use `generate_deeplinks` to include clickable links in your output
- Use `get_panel_image` or `get_dashboard_image` when a visual would help the user understand the data — attach the image to your response

## Output

End every task with a structured summary:

```
## Result

[1-3 sentence summary of what was found or done]

### Details
[Findings, data, or changes — use tables or lists where appropriate]

### Links
[Deeplinks to relevant dashboards or panels, if generated]
```

If the task required rendering, attach the image directly above the Result block.
````

**Step 2: Verify**

Read `skills/grafana/SKILL.md` and confirm:
- Frontmatter has `name: grafana` and a description mentioning ReAct and env var requirements
- Capability catalogue covers all 13 groups: Search, Dashboard, Prometheus, Loki, Datasource, Alerting, Asserts, Sift, Navigation, Rendering, Examples, SearchLogs, RunPanelQuery
- ReAct loop section has the 4-step Reason/Act/Observe/Decide structure
- Output section has the Result template

**Step 3: Commit**

```bash
git add skills/grafana/SKILL.md
git commit -m "feat: add /grafana SRE toolbox skill with capability catalogue and ReAct loop"
```

---

### Task 3: Add `uvx` check to `session_start_check.sh`

**Files:**
- Modify: `hooks/session_start_check.sh`

**Step 1: Read the current file**

Read `hooks/session_start_check.sh` in full. It currently checks: `jq`, `python3`, `repomix`, `codex`.

**Step 2: Add `uvx` check**

Add a `uvx` line after the `codex` line:

```bash
command -v uvx     >/dev/null 2>&1 || MISSING+=("uvx     — required to run mcp-grafana (install via: pip install uv or brew install uv)")
```

The full MISSING checks block should look like:

```bash
command -v jq      >/dev/null 2>&1 || MISSING+=("jq      — JSON parsing in hooks falls back to python3")
command -v python3 >/dev/null 2>&1 || MISSING+=("python3 — JSON parsing fallback in hooks")
command -v repomix >/dev/null 2>&1 || MISSING+=("repomix — required for /pack and /qa codebase snapshots")
command -v codex   >/dev/null 2>&1 || MISSING+=("codex   — required for Codex MCP server")
command -v uvx     >/dev/null 2>&1 || MISSING+=("uvx     — required to run mcp-grafana (install via: pip install uv or brew install uv)")
```

**Step 3: Smoke test**

Run the script directly to confirm it exits 0 and prints the expected warning for any missing tool:

```bash
bash hooks/session_start_check.sh
echo "exit: $?"
```

Expected: exits `0`. If `uvx` is not installed, it should appear in the warning list.

**Step 4: Commit**

```bash
git add hooks/session_start_check.sh
git commit -m "feat: add uvx check to session start hook (required for mcp-grafana)"
```
