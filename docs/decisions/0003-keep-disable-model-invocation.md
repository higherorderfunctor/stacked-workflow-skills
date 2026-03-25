---
id: "0003"
title: keep disable-model-invocation true on all stacked workflow skills
status: accepted
date: 2026-03-24
confidence: 0.75
last-reinforced: 2026-03-24
reinforcement-count: 1
---

## Context

The agentic UX reviewer flagged `disable-model-invocation: true` as the root
cause of Claude not using skills. Research showed mixed evidence:
- Auto-discovery is unreliable (~77% activation rate with good descriptions)
- These skills make structural git changes (commits, rebases, force-pushes)
- Official guidance recommends the flag for "task-driven" skills with side
  effects like commits, deploys, restructuring
- The owner observed that skills were used LESS with auto-discovery enabled

## Decision

Keep `disable-model-invocation: true` on all six stacked workflow skills.
The real fix for skill usage is:
1. Trim CLAUDE.md to reduce competing instructions (done)
2. Ensure the routing table is prominent and unambiguous (done)
3. Users invoke skills explicitly via `/slash-command`

## Consequences

- Skills are invisible to Claude's auto-discovery — users must know to use
  `/stack-fix`, `/stack-plan`, etc.
- The routing table in CLAUDE.md is the only mechanism telling Claude about
  skills — if it gets lost in context, Claude falls back to raw commands
- Saves ~600 tokens per session (6 skill descriptions not loaded)

## Evidence Log

- 2026-03-24: Owner reports skills used LESS with auto-discovery enabled.
  Claude Code docs confirm flag is correct for task-driven skills with side
  effects. 650-trial study shows only 77% activation rate even with good
  descriptions. (confidence: 0.75)
