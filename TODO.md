# TODO

## Stack status: ruler migration (todo/pre-publish)

19 stacked PRs created (#69–#87) from 20 atomic commits. Sentinel
(`todo/pre-publish`) pushed but no PR. 4 additional commits at tip
(not yet in PRs):

- `5daad5c` build: add agnix pre-commit hook and flake check
- `e7017d4` docs: add agnix validation instructions to AGENTS.md and CLAUDE.md
- `caec8a7` build: add dprint formatter with alejandra exec plugin and biome JSON
- `f73fdbf` chore: update TODO.md for pre-publish review tracking (sentinel)

Next: merge PRs #69–#87 from bottom up. After each squash merge:
`git sync --pull`, `gh pr edit <next-PR> --base main`, force-push
remaining branches. Then distribute the 3 tip commits into the stack
or submit as new PRs.

## Linter and tool integration

Detailed research verified and saved in memory file
`reference_lsp_mcp_integration_research.md`. Original research doc from
Claude web session at `/home/caubut/Downloads/lsp-mcp-research-context.md`.
All claims verified against upstream repos on 2026-03-28.

### Recommended strategy: pre-commit hook + flake check + MCP (later)

**Why this order:**

- Pre-commit hook is universal — works for all three CLIs (Claude, Kiro,
  Copilot) because it's git-level, not tool-level. All three respect commit
  failures and self-correct. Covers the Bash tool bypass gap completely.
- Flake check gives `nix flake check` parity with formatting/spelling.
- MCP is deferred because agnix-mcp exists but its API isn't well-documented
  yet. Pre-commit already covers 100% of the "agent wrote bad config" case.
  MCP would add proactive validation (check before writing) — nice-to-have.
- LSP is deferred entirely — no consumer in vibe-coding workflow (no human
  editor to show squiggly lines). MCP bridge is the path when needed.

### Phase 1: pre-commit hook — DONE

Implemented as `scripts/pre-commit` (standalone shell script, no Python
`pre-commit` framework). Four steps in order:

1. Generated file freshness (regenerate if `.ruler/` files staged)
2. agnix `--fix` (auto-fix agent config issues)
3. dprint `fmt` (format everything last, catches all modifications)
4. agnix `--strict` (final validation on formatted output)

Hook runs in ~330ms. Install: `ln -sfn ../../scripts/pre-commit .git/hooks/pre-commit`

### Phase 2: nix flake check — DONE

Added `checks.agent-configs` to flake.nix. Uses `pkgsWithAgnix` (imports
nixpkgs with rust-overlay + agnix overlay) since agnix isn't in nixpkgs.

- [ ] Evaluate adding agnix to CI workflow alongside structural check.

### Phase 3: instruction files — DONE

- AGENTS.md: added Formatting section (run `dprint fmt` after all edits
  including Bash), Validation section with `agnix --strict`, and
  no-global-installs rule.
- CLAUDE.md: added MCP Integration section with known limitation that
  agnix-mcp does not read `.agnix.toml` (ignore suppressed rule hits).

### Phase 4: agnix MCP server — DONE

agnix overlay now builds all binary crates (agnix, agnix-lsp, agnix-mcp)
as a single derivation. `getExe` returns `agnix`, `getExe'` can pick
`agnix-mcp` or `agnix-lsp`.

MCP server configured in `.mcp.json` for Claude Code. Exposes 4 tools:

- `validate_file` — validate a single agent config file
- `validate_project` — validate all agent configs in a directory
- `get_rules` — list all 385 validation rules
- `get_rule_docs` — look up docs for a specific rule by ID

**Known limitation:** agnix-mcp uses `LintConfig::default()` — does not
load `.agnix.toml`. The CLI uses `LintConfig::load_or_default()` with
`resolve_config_path`. MCP returns unfiltered diagnostics including
suppressed rules. Workaround: ignore rules listed in `.agnix.toml`
`disabled_rules`. No upstream issue filed — may file later.

Requires devShell (`agnix-mcp` must be on PATH). Kiro/Copilot MCP
configs deferred.

### Phase 4b: dprint formatter — DONE

dprint configured with three plugins:

- markdown (existing, lineWidth 80)
- biome (JSON formatting, 2-space indent)
- exec/alejandra (Nix formatting via stdin)

PostToolUse hook auto-formats after Write/Edit. Bash edits bypass hooks
— AGENTS.md instructs agents to run `dprint fmt <file>` explicitly.
`nix fmt` now wraps dprint. Flake check uses `dprint check`.

No dprint MCP or LSP — PostToolUse hook + pre-commit hook + AGENTS.md
instruction covers it.

### Propagate allowed tools for consumer installs

The `.claude/settings.json` in this repo has allowed tool permissions
(git branchless commands, dprint, etc.) but consumers installing via
home-manager or manual symlinks don't get these. They have to approve
every tool invocation.

- [ ] Research if `programs.claude-code.settings.permissions.allow` in
      the home-manager module can propagate allowed tool patterns to
      consumers. The stacked-workflow skills need git-branchless, git-absorb,
      git-revise, and formatting commands to work without prompting.
- [ ] Determine the right scope — should allowed tools be per-skill
      (SKILL.md `allowed-tools` frontmatter) or project-wide (settings.json)?
      The Agent Skills spec has an `allowed-tools` field but Claude Code
      may not respect it yet.
- [ ] If per-skill `allowed-tools` works, add it to each SKILL.md
      frontmatter so consumers get the permissions automatically when
      the skill is invoked.

### Phase 5: nixd via MCP bridge (deferred)

For Nix language diagnostics (not agent config linting):

- [ ] Use `isaacphi/mcp-language-server` (Go, 1504 stars, actively
      maintained) to bridge nixd as an MCP server. Tools: definition,
      references, diagnostics, hover, rename, edit.
- [ ] Alternative: `cclsp` (github.com/ktnyt/cclsp, TypeScript/Bun,
      596 stars) — handles LLM line/column inaccuracy with fuzzy position.
- [ ] `mcps.nix` (github.com/roman/mcps.nix) has `lsp-nix` preset but
      uses `nil` not `nixd`. Would need a custom preset for nixd.
- [ ] Single MCP config works for all three ecosystems.

### Phase 6: native LSP per ecosystem (deferred, low priority)

LSP serves human editors. In a vibe-coding workflow, MCP is the right
abstraction. Only pursue if we start doing manual editing:

- **Claude Code**: plugin marketplace system, `ENABLE_LSP_TOOL=1` env
  var may still be needed, Piebald-AI/claude-code-lsps has 20+ languages
- **Kiro**: native `lsp.json` config, straightforward
- **Copilot CLI**: experimental, requires `--experimental` flag,
  `~/.copilot/lsp-config.json` or `.github/lsp.json`

### Resolved open questions

- **`ENABLE_LSP_TOOL` env var** — no longer needed on Claude Code 2.1.50+.
  LSP auto-enables when a plugin with `.lsp.json` is installed via the
  marketplace system. Confirmed 2026-03-28.
- **Declarative config module** — not needed now. LSP/MCP config is local
  dev only (this repo's devShell, not published). If later shared across
  multiple skill packages, extract to its own flake at that point.
- **agnix Nix rule set for LSP configs** — not relevant. agnix validates
  agent configs (SKILL.md, CLAUDE.md), not LSP configs. Dropped.
- **Kiro/Copilot LSP format parity, Copilot diagnostic push behavior** —
  deferred. Focus on Claude Code first.

## Codify memory into repo instructions

Context from memory files that applies to all contributors/AI tools working
on this repo, not just the current user's private preferences:

- [ ] AGENTS.md: add "don't install packages" rule — use tools available
      in the devShell. If something is missing, ask the user or use
      `npx`/`uvx`/`nix run` instead of installing globally.
- [ ] AGENTS.md or CONTRIBUTING.md: add skill fallback guidance — "if the
      Skill tool invocation fails, read the SKILL.md and execute its instructions
      step by step." The routing table says MANDATORY but doesn't cover the
      fallback path when tool invocation is unavailable.
- [ ] CONTRIBUTING.md: consider clarifying generate.sh design rationale —
      ruler can't do per-target frontmatter injection, so generate.sh exists.
      Currently only in references/ruler.md note; not obvious to contributors
      who might try `ruler apply`.

## Skill improvements from 2026-03-27 restructure session

Lessons from restructuring a 20-commit stack (splitting a kitchen-sink
commit, merging small commits, reordering, creating 19 stacked PRs).
These should be codified into the skills themselves so consumers benefit.

### stack-plan restructure mode — intermediate file states

The #1 source of rework during restructure. When flattening a stack and
recommitting, files like CLAUDE.md and flake.nix need DIFFERENT content
at different commits (e.g., CLAUDE.md has inline routing in commit 1 but
switches to `@.generated` import in commit 6). The skill already warns
about this in the Tips section, but it needs stronger guidance:

- [ ] Add to stack-plan: "Before staging each commit, Write every file
      that has intermediate states to its correct content for THIS commit.
      The working tree contains the FINAL state — you must overwrite files
      with their intermediate versions before staging. Verify with
      `git diff --cached` that only the intended content is staged."
- [ ] Add to stack-plan: "Plan ALL intermediate states BEFORE flattening.
      For each file that appears in multiple commits, write out what content
      it should have at each commit boundary. Don't discover intermediate
      states as you go — that leads to fixups."

### stack-plan restructure mode — rename/move orphaned deletions

When staging renamed files (e.g., `.claude/skills/stack-*` →
`.claude/skills/sws-*`), only the new paths get staged. The deletions
of the old paths are left unstaged. This is subtle because `git status`
shows them as separate deletions, not as renames.

- [ ] Add to stack-plan: "After staging renamed/moved files, check
      `git status` for orphaned deletions of the old paths. Stage them in
      the same commit."

### stack-plan restructure mode — hooks fire during inconsistent state

PostToolUse hooks (agnix linting, etc.) fire when using Write/Edit
during a restructure. The working tree is intentionally inconsistent
between commits (e.g., flake.nix references overlay files that haven't
been staged yet). This produces scary error output that is harmless.

- [ ] Add to stack-plan Tips: "Expect hook failures during restructure.
      The working tree is intentionally inconsistent between commits. Hook
      errors are harmless — they'll pass once all files are committed."

### stack-plan restructure mode — tree hash verification

The `FINAL_TREE` comparison caught a CLAUDE.md bug where the file had
intermediate content instead of its final state. Without this check the
broken tree would have been pushed.

- [ ] Strengthen the post-verification step in stack-plan: make tree
      hash comparison a REQUIRED step, not just suggested. When mismatch
      is detected, diff against the backup branch to identify which files
      diverge.

### stack-submit — large stack scripting

For stacks > 10 commits, manual branch creation and PR creation is
error-prone. During this session, bash scripts were written for both.

- [ ] Add to stack-submit: "For stacks > 10 commits, script branch
      creation and PR creation. Use a bash array of (branch, hash) pairs
      for branches, and (branch, base, title) tuples for PRs. Add
      `sleep 1` between `gh pr create` calls to avoid GitHub rate limiting."
- [ ] Add to stack-submit: example bash script template for large
      stack PR creation with stacked bases (each PR targets the previous
      branch, first targets main).

### stack-submit — autosquash fixups for post-hoc corrections

When you discover a missed change after the commit is already made
during restructure, `git commit --fixup <hash>` + autosquash rebase
is the right pattern. This worked well and is faster than checking
out each commit to amend.

- [ ] Add to stack-plan or philosophy.md: document the fixup pattern
      as a recovery mechanism during restructure. Currently only mentioned
      in philosophy.md § Bulk Stack Modification but not connected to
      the restructure workflow.

### Remove sentinel commit convention from shared skills

The sentinel commit pattern (TODO.md at stack tip, excluded from PRs)
is a personal workflow preference, not a universal best practice. It's
currently documented in `references/philosophy.md` § Sentinel Commits
and referenced in stack-plan and stack-submit skills.

- [ ] Remove § Sentinel Commits from `references/philosophy.md`
- [ ] Remove sentinel handling from `skills/stack-plan/SKILL.md`
      (references to sentinel insertion, tip management)
- [ ] Remove sentinel handling from `skills/stack-submit/SKILL.md`
      (sentinel branch exclusion from PRs, tracking-only push)
- [ ] Remove sentinel references from `skills/stack-summary/SKILL.md`
      (sentinel detection in audit)
- [ ] If the pattern is still useful for some users, move it to a
      separate "optional patterns" section or a tips doc rather than
      baking it into the core skills

### Explore rolling stack workflow pattern

Currently the skills assume a bounded stack: you plan commits, build
them, submit PRs, merge them all, done. In practice, work is a
continuous stream — you're always adding new commits on top while
earlier ones are still in review or waiting to merge. The stack never
fully drains.

This "rolling stack" pattern has specific challenges not covered by
the current skills:

- **Ongoing work on top of unmerged PRs** — you keep committing new
  features while PRs #1-5 are in review. When #1 merges, #2-5 need
  rebasing, but so do your new unsubmitted commits on top.
- **Partial merges change the base** — after squash-merging PR #1,
  `git sync --pull` rebases the remaining stack. But new commits that
  weren't part of the original submission also get rebased. The
  boundary between "submitted" and "not yet submitted" is fluid.
- **Incremental submission** — you submit PRs for the first N commits
  while continuing to work on N+1, N+2, etc. Later you submit those
  too. The stack-submit skill currently assumes all-at-once submission.
- **Review feedback while developing** — reviewer comments on PR #3
  arrive while you're working on commit #15. You need to context-switch
  to fix #3, absorb the fix, restack, force-push #3-N, then resume
  work on #15. The stack-fix skill handles the fix itself but not the
  workflow of interleaving review fixes with ongoing development.
- **Stack never ends** — there's no "final commit" or clean endpoint.
  The sentinel pattern (if kept) would need to float continuously.
  Without it, the tip is always the latest work-in-progress.
- **Batched PR creation** — with a rolling stack, you might submit
  PRs 1-5 on Monday, continue working, submit 6-10 on Tuesday after
  1-3 are merged. The stack-submit skill tip about batching touches
  this but doesn't describe the full workflow.

Things to explore:

- [ ] Document the rolling stack pattern in `references/philosophy.md`
      or a new `references/rolling-stack.md`
- [ ] Update stack-submit to handle incremental submission (submit
      only the first N commits, leave the rest as local-only)
- [ ] Update stack-fix to describe the review-fix-while-developing
      workflow (stash or commit WIP, switch context, fix, resume)
- [ ] Consider whether stack-plan needs a "continue" mode — add to
      an existing stack rather than always building from scratch
- [ ] Consider whether `git sync --pull` + selective force-push is
      sufficient or if the skills need explicit guidance for the
      post-partial-merge rebase flow
- [ ] Think about how this interacts with the 10+ PR batching advice
      in stack-submit — is the rolling pattern actually the natural way
      to handle large stacks? (submit first batch, keep working, submit
      next batch after merges)

## Copilot review feedback (PRs #69–#87)

37 inline comments triaged. Full triage in memory file
`project_copilot_review_triage.md`. Summary:

- **~10 stacked-PR artifacts** — Copilot flagging inconsistencies that are
  resolved by later PRs in the stack. Dismiss by resolving threads.
- **~18 real bugs** — actual issues to fix via `/sws-stack-fix`
- **~5 low-priority suggestions** — consider later

### Real bugs to absorb into stack (grouped by target commit)

PR #72 (feat/ruler-source):

- [ ] Add `<!-- dprint-ignore -->` before routing table in `.ruler/routing.md`
- [ ] Add `<!-- dprint-ignore -->` before table in `.ruler/dev-skills.md`

PR #73 (build/generate-sh):

- [ ] Fix generate.sh:54 comment — says "sorted" but files are hardcoded

PR #76 (feat/copilot-skills-ci):

- [ ] Add `scripts/generate.sh` to CI workflow trigger paths

PR #79 (docs/ref-agnix):

- [ ] Fix double `||` pipe in table syntax (lines 53, 68)
- [ ] Add PE-001 suppression comment to `.agnix.toml` documentation

PR #80 (docs/ref-nix-workflow):

- [ ] Fix "stage modified files" → only untracked need staging
- [ ] Fix alejandra check to note .nvfetcher exclusion
- [ ] Fix `.nvfetcher/` → `overlays/.nvfetcher/` path

PR #81 (docs/ref-ruler):

- [ ] Remove .ruler/AGENTS.md from directory tree (doesn't exist)

PR #83 (docs/adr-0003):

- [ ] Consider creating ADR 0004 for superseding decision per review-policy

PR #84 (docs/install-stale-fixes):

- [ ] Clarify "append contents" wording for Copilot (file includes frontmatter)

PR #85 (docs/migration-assessment):

- [ ] Add "kirodotdev" to .cspell/project-terms.txt

PR #86 (test/structural-validation):

- [ ] Remove unused `routing_body` variable in test-structural.sh
- [ ] Remove unused `diffutils` from flake.nix structural check

PR #87 (test/smoke-discovery):

- [ ] Treat empty tool output as failure
- [ ] Use `grep -F` instead of `grep -q` for literal matching
- [ ] Capture stderr for debugging (don't discard with 2>/dev/null)

### Stacked-PR artifact threads to dismiss

- PR #69: 1 thread (rename confusion)
- PR #70: 7 threads (ADR 0003 — updated in PR #83)
- PR #73: 2 threads (lib/routing still used — retired in PR #74)
- PR #74: 2 threads (docs still reference old pipeline — fixed in #82/#84)
- PR #78: 1 thread (reference files — added in #79-#81)
- PR #82: 1 thread (agnix.md CDX-AG-005 — stale cross-ref)

## Deferred: generation trigger automation

The ruler migration replaced Nix-computed routing (on-demand via `nix eval`)
with pre-generated files via `scripts/generate.sh`. This introduced a manual
build step — contributors must remember to run `generate.sh` after editing
`.ruler/` source files. CI catches staleness but that's a slow feedback loop.

Lifecycle automation is the mitigation. Options to evaluate:

- [ ] Git pre-commit hook — auto-run `generate.sh` when `.ruler/` files are
      staged. Most reliable; works for all contributors regardless of editor.
- [ ] Claude Code lifecycle hooks (PostToolUse on `.ruler/` edits) — triggers
      when AI edits `.ruler/` files. Note: the agnix hook bypass issue (below)
      shows that Bash tool fallback bypasses PostToolUse hooks, so this alone
      is insufficient.
- [ ] Kiro hooks — equivalent lifecycle trigger for Kiro users.
- [ ] GitHub Actions — current CI workflow is a safety net (checks staleness),
      not a primary trigger. Could be extended to auto-commit regenerated files.
- [ ] Combination — pre-commit hook as primary, AI lifecycle hooks as
      convenience, CI as safety net.

Related gap: the agnix PostToolUse hook (`Write|Edit` matcher) doesn't fire
when Claude falls back to Bash/sed. Same limitation would apply to a
`.ruler/` PostToolUse hook. See "agnix hook bypass via Bash tool" below.

## Deferred: dev tools without Nix

Explore npx/uvx for running dev tools (ruler, agnix) without requiring
global installs or `nix develop`:

- [ ] `npx @intellectronica/ruler apply` as alternative to devShell
- [ ] `npx agnix --strict .` as alternative to devShell
- [ ] Document in CONTRIBUTING.md once validated

## agnix hook bypass via Bash tool

The PostToolUse hook (`Write|Edit` matcher) only fires for the Edit and Write
tools. When the Edit tool cannot express a change (e.g., trailing whitespace —
Edit strips it), Claude falls back to Bash/sed, which bypasses the hook
entirely. The file is modified but agnix never runs.

Observed: editing `skills/stack-fix/SKILL.md` via `sed` produced no lint check.
Editing `CLAUDE.md` via Edit fired the hook (passed silently, exit 0).

## Post-publish validation

- [ ] Validate Copilot CLI global path (`~/.copilot/`) with `gh copilot`
- [ ] Validate Kiro global path (`~/.kiro/`)
- [ ] Test Kiro skill discovery with stacked workflow operations
- [ ] Test Copilot skill discovery with stacked workflow operations

## nix-mcp-servers integration test

- [ ] Add stacked-workflow-skills as flake input
- [ ] Install skills to `.claude/skills/` (project-level)
- [ ] Add routing table to project CLAUDE.md
- [ ] Test real stack manipulation work to verify skills are invoked

## Repo review findings (2026-03-27)

Full 6-reviewer analysis saved in `docs/reports/ruler-migration-assessment.md`.
8 recommended changes, ~25 observations, 0 decision challenges.

### Recommended changes (needs triage)

- [ ] sws-* directory names violate Agent Skills spec (name must match dir)
- [ ] README Quick Start symlink uses fragile `$(pwd)` pattern
- [ ] home-manager `claudeAvailable` check is fragile (`hasAttrByPath` +
      direct config access)
- [ ] Copilot module `~/.copilot/` vs manual `.github/` path confusion
- [ ] generate.sh missing blank line separators between concatenated sections
- [ ] Reviewer personality files reference deleted `lib/routing-data.nix`
- [ ] generate.sh comment references deleted `ruler.toml`
- [ ] AGENTS.md says `agnix .` but CI uses `agnix --strict .`

### Notable observations (no action required yet)

- Pre-flight block duplicated across 6 skills — extract candidate
- `import'` naming and duplication (flake.nix + overlays/default.nix)
- `mk` prefix on lib string values (not functions)
- `argument-hint` is Claude Code-specific, not in Agent Skills spec
- Per-skill `references/` symlinks break outside source tree
- README lacks "why stacked workflows" intro and usage example
- Unreleased git-branchless features not documented
- `git-config-full.nix` should use `lib.recursiveUpdate` over `//`
- Home-manager module hardcodes skill/reference lists (could derive from fs)

## Observations

- rust-overlay in all perPkg including Python git-revise — harmless
- CDX-AG-005 suppressed in `.agnix.toml` — appears to be an agnix bug
  where rule message is not interpolated. Review on next agnix upgrade.
- Ruler's `--project-root` doesn't isolate config loading — it still walks
  up to find root AGENTS.md. Profile approach abandoned; `generate.sh`
  uses direct `cat` concatenation instead of `ruler apply`.
- Ruler stays in devShell for future MCP distribution use and as reference
  tooling, but is not used in the generation pipeline.
