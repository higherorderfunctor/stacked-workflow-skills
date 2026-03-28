---
id: "0003"
title: enable auto-invocation on all stacked workflow skills
status: superseded
date: 2026-03-24
confidence: 0.70
last-reinforced: 2026-03-27
reinforcement-count: 2
---

## Context

The agentic UX reviewer flagged `disable-model-invocation: true` as the root
cause of Claude not using skills. Research showed mixed evidence:
- Auto-discovery is unreliable (~77% activation rate with good descriptions)
- These skills make structural git changes (commits, rebases, force-pushes)
- Official guidance recommends the flag for "task-driven" skills with side
  effects like commits, deploys, restructuring
- The owner observed that skills were used LESS with auto-discovery enabled

## Original Decision (2026-03-24)

Keep `disable-model-invocation: true` on all six stacked workflow skills.
Rely on explicit `/slash-command` invocation via routing table.

## Superseded Decision (2026-03-27)

Set `disable-model-invocation: false` on all skills. Cross-ecosystem testing
revealed that Kiro and Copilot benefit from auto-discovery since their
routing table support is less mature than Claude Code's. The routing table
remains as a reinforcement mechanism, but auto-invocation ensures skills are
discoverable across all platforms.

## Consequences

- Skills are visible to auto-discovery on Claude Code, Kiro, and Copilot
- Kiro and Copilot can match user requests to skill descriptions directly
- ~600 additional tokens per session (skill descriptions loaded at startup)
- Routing table still guides explicit invocation and serves as fallback
- Risk of false activation on ambiguous requests — mitigated by specific
  skill descriptions that include "INSTEAD of" language

## Evidence Log

- 2026-03-24: Owner reports skills used LESS with auto-discovery enabled.
  Claude Code docs confirm flag is correct for task-driven skills with side
  effects. 650-trial study shows only 77% activation rate even with good
  descriptions. (confidence: 0.75)
- 2026-03-27: Cross-ecosystem testing with Kiro CLI and Copilot. Kiro
  custom agents don't auto-load skills; default agent requires
  auto-discovery to work. Copilot respects the flag (skills hidden from
  auto-load when true). Enabling auto-invocation is required for
  cross-platform parity. (confidence: 0.70 — needs validation with
  extended use across all three platforms)
