---
id: "0004"
title: enable auto-invocation on all stacked workflow skills
status: accepted
date: 2026-03-27
confidence: 0.70
last-reinforced: 2026-03-27
reinforcement-count: 1
supersedes: "0003"
---

## Context

ADR 0003 kept `disable-model-invocation: true` to prevent accidental
activation of skills with structural side effects. Cross-ecosystem testing
revealed this blocked Kiro and Copilot from discovering skills entirely.

## Decision

Set `disable-model-invocation: false` on all skills. The routing table
remains as a reinforcement mechanism, but auto-invocation ensures skills
are discoverable across all platforms.

## Consequences

- Skills are visible to auto-discovery on Claude Code, Kiro, and Copilot
- Kiro and Copilot can match user requests to skill descriptions directly
- ~600 additional tokens per session (skill descriptions loaded at startup)
- Routing table still guides explicit invocation and serves as fallback
- Risk of false activation on ambiguous requests — mitigated by specific
  skill descriptions that include "INSTEAD of" language
- stack-submit includes an explicit user approval gate before remote
  operations to prevent unintended pushes from auto-invocation

## Evidence Log

- 2026-03-27: Cross-ecosystem testing with Kiro CLI and Copilot. Kiro
  custom agents don't auto-load skills; default agent requires
  auto-discovery to work. Copilot respects the flag (skills hidden from
  auto-load when true). Enabling auto-invocation is required for
  cross-platform parity. (confidence: 0.70 — needs validation with
  extended use across all three platforms)
- 2026-03-29: Smoke test confirms all three ecosystems (Claude Code,
  Kiro CLI, Copilot CLI) discover all 6 stack skills in headless mode.
