---
id: "0001"
title: use MADR-style decision records with confidence scoring
status: accepted
date: 2026-03-24
confidence: 0.80
last-reinforced: 2026-03-24
reinforcement-count: 1
---

## Context

The `/review` skill runs multiple AI reviewer personalities in parallel.
Without a mechanism to record decisions, each run re-litigates the same
questions. We need a "don't re-litigate" system that also acknowledges
decisions can become stale as ecosystems evolve.

## Decision Drivers

- Decisions must be machine-parseable (AI reviewers consume them)
- Decisions must be human-readable (reviewed in PRs)
- Confidence must decay when evidence stops supporting a decision
- The format should be a recognized standard, not custom

## Decision

Use MADR-style decision records in `docs/decisions/` with additional YAML
frontmatter fields for confidence tracking:

- `confidence` (0.0–1.0)
- `last-reinforced` (date)
- `reinforcement-count` (integer)

Confidence mechanics are defined in `dev/repo-review/review-policy.md` and
are themselves subject to review.

## Consequences

- Each `/repo-review` run reads all decisions as context
- Reviewers skip accepted decisions with confidence >= 0.5
- Decisions below 0.5 confidence get flagged for re-evaluation
- New decisions require 4/6 reviewer agreement to accept
- The decision log grows over time but individual files are small

## Evidence Log

- 2026-03-24: Initial decision. MADR is the actively maintained ADR
  standard (github.com/adr/madr). Confidence scoring is novel but follows
  the pattern of citation freshness models in academic literature.
  (confidence: 0.80)
