#!/usr/bin/env node
// Claude Code Statusline — claude-agents-custom edition
// Shows: model | current task | pipeline phase | directory | context usage
// Adapted from https://github.com/gsd-build/get-shit-done/blob/main/hooks/gsd-statusline.js

const fs = require('fs');
const path = require('path');
const os = require('os');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const remaining = data.context_window?.remaining_percentage;

    // Context window display (scaled: 80% real usage = 100% displayed)
    let ctx = '';
    if (remaining != null) {
      const rem = Math.round(remaining);
      const rawUsed = Math.max(0, Math.min(100, 100 - rem));
      const used = Math.min(100, Math.round((rawUsed / 80) * 100));

      // Write bridge file for context-monitor.sh
      if (session) {
        try {
          const bridgePath = path.join(os.tmpdir(), `claude-ctx-${session}.json`);
          fs.writeFileSync(bridgePath, JSON.stringify({
            session_id: session,
            remaining_percentage: remaining,
            used_pct: used,
            timestamp: Math.floor(Date.now() / 1000)
          }));
        } catch (e) {
          // Silent fail — bridge is best-effort
        }
      }

      // Progress bar (10 segments)
      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

      if (used < 63) {
        ctx = ` \x1b[32m${bar} ${used}%\x1b[0m`;
      } else if (used < 81) {
        ctx = ` \x1b[33m${bar} ${used}%\x1b[0m`;
      } else if (used < 95) {
        ctx = ` \x1b[38;5;208m${bar} ${used}%\x1b[0m`;
      } else {
        ctx = ` \x1b[5;31m\u{1F480} ${bar} ${used}%\x1b[0m`;
      }
    }

    // Current in-progress task from todos
    let task = '';
    const todosDir = path.join(os.homedir(), '.claude', 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);

        if (files.length > 0) {
          const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
          const inProgress = todos.find(t => t.status === 'in_progress');
          if (inProgress) task = inProgress.activeForm || '';
        }
      } catch (e) {
        // Silent fail
      }
    }

    // Pipeline phase from .pipeline/ artifacts in cwd
    let phase = '';
    const pipelineDir = path.join(dir, '.pipeline');
    try {
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
    } catch (e) {
      // Silent fail
    }

    // Assemble segments
    const parts = [`\x1b[2m${model}\x1b[0m`];
    if (task)  parts.push(`\x1b[1m${task}\x1b[0m`);
    if (phase) parts.push(`\x1b[2m${phase}\x1b[0m`);
    parts.push(`\x1b[2m${path.basename(dir)}\x1b[0m`);

    process.stdout.write(parts.join(' \u2502 ') + ctx);
  } catch (e) {
    // Silent fail — never break the statusline
  }
});
