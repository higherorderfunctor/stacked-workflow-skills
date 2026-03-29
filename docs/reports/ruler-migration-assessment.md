# Ruler Migration: Before vs After Assessment

Report generated 2026-03-27 from analysis of `todo/pre-publish` branch
(12 commits ahead of main).

---

## Executive Summary

The migration achieved its primary goal: **editing the routing table no longer
requires Nix knowledge** (markdown vs Nix attribute sets). The source of truth
is cleaner and more accessible. However, it introduced a new build step
(`scripts/generate.sh`) that must be run manually, and some docs are now stale
or misleading. Net complexity is **different, not reduced** — easier editing,
harder build pipeline.

---

## What Improved

### 1. Routing source is human-readable

- **Before:** `lib/routing-data.nix` — a Nix array of attribute sets. Required
  Nix syntax knowledge to edit.
- **After:** `.ruler/routing.md` — a markdown table. Anyone can edit it.

### 2. No routing duplication in AGENTS.md or CLAUDE.md

CLAUDE.md now uses `@.generated/claude-routing.md` (an include, not a copy).
AGENTS.md has zero routing content. The routing table lives in exactly one
place: `.ruler/routing.md`.

### 3. Nix lib is simpler

Old generators computed markdown from data at eval time. Now they're one-line
`builtins.readFile` calls. Faster evaluation, less Nix to maintain.

### 4. Ecosystem consistency

All three ecosystem outputs (Claude, Kiro, Copilot) have **identical routing
table bodies**. The only differences are YAML frontmatter, which is stitched
per-ecosystem by `generate.sh`.

---

## What Got Worse or Stayed the Same

### 5. New manual build step

- **Before:** `nix eval` computed output on demand — no pre-generation needed.
- **After:** Must run `scripts/generate.sh` after editing `.ruler/`. Easy to
  forget. New contributors won't know to do it. CI catches staleness but
  that's a slow feedback loop.
- **Verdict:** The trigger automation is correctly deferred in TODO.md, but
  until it's solved this is a real friction point.

### 6. More generated files (3 → 5)

| Before                          | After                                                   |
| ------------------------------- | ------------------------------------------------------- |
| `.generated/claude-routing.md`  | `.generated/claude-routing.md`                          |
| `.generated/kiro-routing.md`    | `.generated/kiro-routing.md`                            |
| `.generated/copilot-routing.md` | `.generated/copilot-routing.md`                         |
|                                 | `.kiro/steering/stacked-workflow.md`                    |
|                                 | `.github/instructions/stacked-workflow.instructions.md` |

The two new in-repo files exist for local auto-discovery (Kiro's
`inclusion: auto`, Copilot's `applyTo`). Useful, but more surface area.

### 7. generate.sh is brittle

- **Hardcoded filenames** — if you add a new `.ruler/*.md` file, the script
  won't discover it. Must be manually updated.
- **No blank line separators** — concatenated sections run together
  (`.kiro/steering/stacked-workflow.md` lines 14–16 have a table row directly
  abutting a `##` heading).
- **Hardcoded concatenation order** — `dev-skills.md`, `operations.md`,
  `routing.md` — undocumented.

### 8. Three languages instead of one

- **Before:** Nix only (data + generators + consumers).
- **After:** Markdown (source) + Bash (generator) + Nix (consumers). More
  moving parts across language boundaries.

---

## Stale / Misleading Documentation — RESOLVED

All items below were fixed on 2026-03-27:

- **INSTALL.md** — updated to reference `.ruler/routing.md` and
  `scripts/generate.sh`. Nix lib section clarified as pass-through.
- **CONTRIBUTING.md** — removed stale `ruler.toml` mention.
- **.ruler/ruler.toml** — deleted (unused artifact with wrong output paths).
- **references/ruler.md** — added note clarifying this repo uses
  `generate.sh` instead of `ruler apply`.

---

## DRY Scorecard

| Aspect                     | Before               | After                     | Verdict                       |
| -------------------------- | -------------------- | ------------------------- | ----------------------------- |
| Routing table source       | 1 place (Nix)        | 1 place (markdown)        | **Same** (both single-source) |
| Routing in CLAUDE.md       | Inline copy          | `@` include               | **Better**                    |
| Routing in AGENTS.md       | None                 | None                      | Same                          |
| Per-ecosystem content      | Computed differently | Identical body            | **Better**                    |
| Frontmatter                | N/A (Nix handled it) | Explicit in generate.sh   | Same                          |
| Doc references to pipeline | Accurate             | Fixed (was stale)         | **Same**                      |
| Unused config files        | None                 | None (ruler.toml deleted) | **Same**                      |

---

## Remaining Recommendations

1. **Add blank line separators in generate.sh** — concatenated sections run
   together (cosmetic but violates markdown style)
2. **Consider glob discovery in generate.sh** — `for f in .ruler/*.md` instead
   of hardcoded list (trade-off: loses explicit ordering control)

---

## What's Next

### 1. Lifecycle automation (mitigates the manual build step)

The main net negative of the migration is that `scripts/generate.sh` must be
run manually after editing `.ruler/`. TODO.md now frames this explicitly and
lists options:

- **Git pre-commit hook** — most reliable, works for all contributors
- **Claude Code PostToolUse hook** — convenience for AI-driven edits (but
  Bash tool fallback bypasses it — known gap)
- **Kiro hooks** — equivalent for Kiro users
- **CI safety net** — already in place, catches staleness on push

A pre-commit hook is the strongest candidate for primary trigger.

### 2. Bottom commit split (`a5e632f`)

Kitchen-sink commit mixing skill renames, symlinks, model-invocation flips,
hooks, and docs. Needs splitting into atomic commits via `/stack-split` or
`/stack-plan` before merge.

### 3. Ecosystem testing (blocked on home-manager rebuild)

- Kiro CLI skill discovery (`.kiro/skills/` symlinks)
- Copilot CLI skill discovery (`.github/skills/` symlinks)
- Kiro steering file loading
- AGENTS.md auto-loading in Kiro CLI

### 4. Verification

- `@.generated/claude-routing.md` import in live Claude Code session
- `@AGENTS.md` import in live Claude Code session

### 5. Stack submission

Split stack into PRs via `/stack-submit` once above items are resolved.

---

## Bottom Line

The migration is a net positive for **editability** (markdown > Nix) and
**consistency** (identical bodies across ecosystems). The original net negative
for **build complexity** (manual step) has a clear mitigation path via
lifecycle automation (pre-commit hook + AI lifecycle hooks). Documentation
staleness has been resolved.

---

---

# Full Repo Review Report (2026-03-27)

6 specialized reviewers ran in parallel: Git Expert, Agentic UX, Human UX,
Nix Expert, FP/DRY Expert, Consistency Auditor.

## Recommended Changes (HIGH severity or 3+ reviewer agreement)

### 1. [HIGH] sws-* directory names violate Agent Skills spec (AUX-001)

`.claude/skills/sws-stack-fix/` contains a SKILL.md with `name: stack-fix`.
The Agent Skills spec requires name to match the parent directory name.
Claude Code works (uses directory name for slash command) but this would
fail `skills-ref validate` and may break other Agent Skills consumers.
Copilot/Kiro symlinks use correct matching names.

**Suggestion:** Either remove the `sws-` prefix from `.claude/skills/`
symlinks (and use a different disambiguation strategy), or accept and
document the spec deviation.

**Reviewers:** agentic-ux (1/6)

### 2. [HIGH] Claude Code Quick Start symlink uses fragile $(pwd) (HUX-006)

README line 163-165: `$(pwd)/stacked-workflow-skills` after `git clone`.
If the user changes directories between clone and symlink, the target is
wrong. Silent failure — skills just don't appear.

**Suggestion:** Combine clone + symlink in a single block with explicit
`cd`, or use `$HOME/src/...` with a note to adjust.

**Reviewers:** human-ux (1/6)

### 3. [HIGH] home-manager claudeAvailable check is fragile (NIX-008)

`home-manager/default.nix:40-42` uses `hasAttrByPath` on `options` then
accesses `config` directly. Works due to NixOS/HM invariant but fragile.

**Suggestion:** Use `lib.attrByPath ["programs" "claude-code" "enable"]
false config` or add a comment explaining why the options check suffices.

**Reviewers:** nix-expert (1/6)

### 4. [HIGH] Copilot module vs manual install path confusion (CA-009)

Module places files at `~/.copilot/` (CLI); INSTALL.md manual section
shows `.github/` (editor). Different mechanisms insufficiently
distinguished.

**Suggestion:** Add a clarifying note in INSTALL.md distinguishing
`gh copilot` CLI (global `~/.copilot/`) from editor Copilot (per-project
`.github/`).

**Reviewers:** consistency-auditor (1/6)

### 5. [MEDIUM, 3/6 agree] generate.sh missing blank line separators (CA-003/004, FP-06, assessment §7)

`.kiro/steering/stacked-workflow.md` line 14-15: table row directly abuts
`## Operations Without Skills` heading with no blank line. Same in
`.github/instructions/`. Malformed markdown.

**Suggestion:** Insert `printf '\n'` between concatenated files in
`scripts/generate.sh`.

**Reviewers:** consistency-auditor, fp-dry-expert, migration-assessment (3/6)

### 6. [MEDIUM, 2/6 agree] Stale routing-data.nix references in reviewer personality files (CA-001/002)

`dev/repo-review/personalities/consistency-auditor.md` and
`fp-dry-expert.md` still reference `lib/routing-data.nix` as the source
of truth. These guide future AI reviews — stale references propagate
confusion.

**Suggestion:** Update both to reference `.ruler/routing.md` and
`scripts/generate.sh`.

**Reviewers:** consistency-auditor (2 findings)

### 7. [MEDIUM] generate.sh comment references deleted ruler.toml (CA-006)

Line 53: "excludes ruler.toml" — file no longer exists.

**Suggestion:** Remove the parenthetical.

**Reviewers:** consistency-auditor (1/6)

### 8. [MEDIUM] AGENTS.md says `agnix .` but CONTRIBUTING.md and CI use `agnix --strict .` (CA-005)

**Suggestion:** Align AGENTS.md to `agnix --strict .`.

**Reviewers:** consistency-auditor (1/6)

---

## Observations (MEDIUM severity, < 3 reviewers)

### Nix

- **NIX-001** `import'` name shadows builtin `import` — consider
  `importOverlay` (medium)
- **NIX-004** `import'` duplicated in flake.nix and overlays/default.nix
  (medium, also FP-04)
- **NIX-006** Rust 1.88.0 pin for git-branchless will accumulate tech debt
  if rust-overlay drops it (medium)
- **NIX-010** `mk` prefix on lib values that are strings, not functions —
  `mkClaudeRouting` should be `claudeRouting` (medium)
- **NIX-013** `git-config-full.nix` uses shallow `//` merge — should use
  `lib.recursiveUpdate` (medium, also FP-10)
- **NIX-011** `--update-input` deprecated in newer Nix — use
  `nix flake update` (low)

### Agentic UX

- **AUX-002** `argument-hint` is Claude Code-specific, not in Agent Skills
  spec; triggers VS Code warnings (medium)
- **AUX-003** Per-skill `references/` symlinks break when copied outside
  source tree (medium)
- **AUX-004** Kiro CLI loads full SKILL.md at startup — known bug
  kirodotdev/Kiro#6680 (medium)
- **AUX-005** Skills use prose for reference paths instead of
  `${CLAUDE_SKILL_DIR}` substitution variable (medium)

### Human UX

- **HUX-001** README opens with "What's Included" before explaining what
  stacked workflows ARE (medium)
- **HUX-002** Install method table appears before actionable Quick Start
  — reorder for scannability (medium, respects ADR 0002)
- **HUX-004** Routing table lacks "start here" guidance for new users
  (medium)
- **HUX-008** No usage example showing what skill invocation looks like
  (low)
- **HUX-010** Agentic install prompt uses Nix flake URL instead of HTTPS
  (medium)

### FP/DRY

- **FP-01** Pre-flight block duplicated verbatim across all 6 skills —
  extract to `references/pre-flight.md` (medium)
- **FP-02/03** Reference and skill file lists hardcoded in home-manager
  module — could derive from filesystem (medium)
- **FP-05** Overlay source import boilerplate repeated 5x (medium)

### Git Expert

- **GIT-01** Unreleased git-branchless features (`git record --fixup`,
  `git move --dry-run`) not documented (medium)
- **GIT-02** Gap between v0.10.0 release and unreleased master work not
  conveyed (medium)
- **GIT-04** `git move -F` panic warning may be stale on current master
  (medium)
- **GIT-05** stack-submit recovery suggests `git branch -f main` before
  `git sync --pull` — should be reversed (medium)

### Consistency

- **CA-013** AGENTS.md says `devShell` (singular) but flake exports
  `devShells` (plural) (medium)
- **CA-014** CONTRIBUTING.md lists ruler in devShell tools without noting
  it's reference-only (medium)
- **CA-015** Manual install uses per-skill symlinks but HM module uses
  whole-directory symlink for Kiro/Copilot (medium)

---

## Decision Challenges

None. All 6 reviewers confirmed existing decisions (ADR 0001, 0002, 0003)
are respected. No contradicting evidence found.

---

## Proposed New Decisions

None proposed. No findings rose to the level of architectural choices
requiring a decision record.

---

## Summary

<!-- dprint-ignore -->
| Reviewer | High | Medium | Low | Total |
|----------|------|--------|-----|-------|
| Git Expert | 0 | 5 | 3 | 8 |
| Agentic UX | 1 | 4 | 4 | 9 |
| Human UX | 1 | 4 | 5 | 10 |
| Nix Expert | 1 | 6 | 7 | 14 |
| FP/DRY Expert | 0 | 5 | 5 | 10 |
| Consistency Auditor | 1 | 7 | 5 | 13 |
| **Deduplicated total** | **4** | **~25** | **~20** | **~49** |

After deduplication: **8 recommended changes** (4 high + 1 with 3/6
agreement + 3 medium actionable), **~25 observations**, 0 decision
challenges.

**Status: 8 recommended changes, ~25 observations.**
