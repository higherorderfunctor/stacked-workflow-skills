---
id: "0002"
title: installation is Nix or manual — no hand-holding for package managers
status: accepted
date: 2026-03-24
confidence: 0.85
last-reinforced: 2026-03-24
reinforcement-count: 1
---

## Context

The human UX reviewer flagged README install friction: 5 methods in a table
before Quick Start, decision paralysis, no brew/apt instructions for
prerequisites. Suggested reducing to one recommended path per audience.

## Decision

Keep the current multi-method install documentation as-is. The target audience
is Nix users (primary) and manual install users (secondary). We don't provide
brew/apt/pip instructions — users who want those can figure it out from the
upstream tool READMEs.

## Consequences

- README stays ecosystem-neutral with parallel quick starts
- No additional package manager instructions to maintain
- Users who can't handle `cargo install` or a Nix flake are not the target
  audience for stacked commit workflows
- The INSTALL.md install table in README may look overwhelming but provides
  correct information for power users who know what they want

## Evidence Log

- 2026-03-24: Owner decision. "It's nix or manual, figure it out yourself
  if you want another package manager." (confidence: 0.85)
