---
id: "0003"
title: keep disable-model-invocation true on stacked workflow skills
status: superseded
superseded-by: "0004"
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
Rely on explicit `/slash-command` invocation via routing table.

## Consequences

- Skills require explicit invocation — no accidental activation
- ~600 fewer tokens per session (skill descriptions not loaded at startup)
- Claude Code routing table is the primary discovery mechanism
- Other platforms (Kiro, Copilot) may not discover skills at all

## Evidence Log

- 2026-03-24: Owner reports skills used LESS with auto-discovery enabled.
  Claude Code docs confirm flag is correct for task-driven skills with side
  effects. 650-trial study shows only 77% activation rate even with good
  descriptions. (confidence: 0.75)
- 2026-03-27: Superseded by ADR 0004 — cross-ecosystem testing showed Kiro
  and Copilot require auto-discovery.
