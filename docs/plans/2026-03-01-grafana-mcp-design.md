# Design: Bundle Grafana MCP and `/grafana` SRE Skill

**Date:** 2026-03-01
**Feature:** Add mcp-grafana as a bundled MCP server and a `/grafana` skill that acts as a standalone SRE toolbox

## Context

The plugin already bundles Codex and Repomix MCP servers. Adding mcp-grafana extends it with full Grafana observability access — dashboards, Prometheus/Loki querying, alerting, Sift investigations, log search, and panel rendering — without requiring manual `claude mcp add` steps.

## Scope

- Local/self-hosted Grafana (`GRAFANA_URL=http://localhost:3000`)
- Single `/grafana <task>` entry point — broad SRE toolbox, no domain restriction
- Approach: capability catalogue (A) + ReAct execution loop (C)

## Design

### Change 1: Add `mcp-grafana` to `plugin.json` mcpServers

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

Passing the complete tool list to `--enabled-tools` replaces the default set, giving exact control over what is exposed. Excluded groups: admin, incident, oncall, annotations, clickhouse, cloudwatch, elasticsearch, pyroscope.

### Change 2: Create `skills/grafana/SKILL.md`

Structure:

1. **Capability catalogue** — table of all enabled tool groups and their tools, so Claude knows its full toolkit before acting.

2. **ReAct execution loop** — Reason → pick tool → call → observe → repeat until task is complete. Handles both single-step queries ("list firing alerts") and multi-hop investigations ("find the dashboard for service X, then query its error panel").

3. **Output** — structured summary with findings, deeplinks where applicable, and rendered panel image when visual context adds value.

**Invocation:** `/grafana <free-text task>`

**Tool groups covered:**

| Group | Key tools |
|-------|-----------|
| Search | `search_dashboards` |
| Dashboard | `get_dashboard_by_uid`, `get_dashboard_summary`, `get_dashboard_property`, `get_dashboard_panel_queries`, `update_dashboard`, `patch_dashboard` |
| Prometheus | `query_prometheus`, `query_prometheus_histogram`, `list_prometheus_metric_names`, `list_prometheus_metric_metadata`, `list_prometheus_label_names`, `list_prometheus_label_values` |
| Loki | `query_loki_logs`, `query_loki_stats`, `query_loki_patterns`, `list_loki_label_names`, `list_loki_label_values` |
| Datasource | `list_datasources`, `get_datasource` |
| Alerting | `list_alert_rules`, `get_alert_rule_by_uid`, `create_alert_rule`, `update_alert_rule`, `delete_alert_rule`, `list_contact_points` |
| Asserts | assertion summary retrieval |
| Sift | `list_sift_investigations`, `get_sift_investigation`, `get_sift_analyses`, `find_error_patterns_in_logs`, `find_slow_requests` |
| Navigation | `generate_deeplinks` |
| Rendering | `get_panel_image`, `get_dashboard_image` |
| Examples | `get_query_examples` |
| SearchLogs | `search_logs` |
| RunPanelQuery | `run_panel_query` |

### Change 3: Add `uvx` check to `session_start_check.sh`

Add `uvx` to the missing-tool check so users are warned at session start if Python/uv is not installed (required to run `uvx mcp-grafana`).

## Files Affected

- `.claude-plugin/plugin.json` — add `mcp-grafana` to `mcpServers`
- `skills/grafana/SKILL.md` — new skill file
- `hooks/session_start_check.sh` — add `uvx` check
