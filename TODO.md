# TODO

## Stack status

16 stacked PRs (#88–#103) + 4 tip commits (agnix hook, validation
instructions, dprint formatter, sentinel). Old PRs #69–#87 closed after
restructure. Don't push branches or recreate PRs until ready to
distribute — Copilot auto-review burns tokens per push.

---

## Implementation work

### Copilot review fixes (absorb into stack)

From Copilot review of PRs #69–#87. Full triage in memory file
`project_copilot_review_triage.md`. Some items already resolved by the
restructure (ADR absorbed into auto-invocation commit, INSTALL.md
pipeline refs absorbed into routing refactor). Remaining:

- [ ] `.ruler/routing.md`: add `<!-- dprint-ignore -->` before table
- [ ] `.ruler/dev-skills.md`: add `<!-- dprint-ignore -->` before table
- [ ] `generate.sh:54`: fix comment ("sorted" → hardcoded file list)
- [ ] CI workflow: add `scripts/generate.sh` to trigger paths
- [ ] `references/agnix.md`: fix double `||` pipe in tables (lines 53, 68)
- [ ] `references/agnix.md`: add PE-001 suppression rationale
- [ ] `references/nix-workflow.md`: fix "stage modified" → only untracked
- [ ] `references/nix-workflow.md`: fix `.nvfetcher/` → `overlays/.nvfetcher/`
- [ ] `references/nix-workflow.md`: note .nvfetcher exclusion in alejandra check
- [ ] `references/ruler.md`: remove .ruler/AGENTS.md from tree (doesn't exist)
- [ ] `test-structural.sh`: remove unused `routing_body` variable
- [ ] `flake.nix`: remove unused `diffutils` from structural check
- [ ] `test-smoke.sh`: treat empty output as failure
- [ ] `test-smoke.sh`: use `grep -F` for literal matching
- [ ] `test-smoke.sh`: capture stderr for debugging
- [ ] `.cspell/project-terms.txt`: add "kirodotdev"
- [ ] INSTALL.md: clarify "append contents" wording for Copilot frontmatter
- [ ] Consider ADR 0004 for superseding decision (per review-policy process)

### Repo review fixes (from 6-reviewer analysis)

Full report in `docs/reports/ruler-migration-assessment.md`. Items not
already covered by Copilot fixes above:

- [ ] sws-* directory names violate Agent Skills spec (name must match dir)
- [ ] README Quick Start symlink uses fragile `$(pwd)` pattern
- [ ] home-manager `claudeAvailable` check fragile (`hasAttrByPath`)
- [ ] Copilot module `~/.copilot/` vs manual `.github/` path confusion
- [ ] generate.sh missing blank line separators between sections
- [ ] Reviewer personality files reference deleted `lib/routing-data.nix`

### Codify repo instructions

- [ ] AGENTS.md: "don't install packages" rule (use devShell, npx, nix run)
- [ ] AGENTS.md: skill fallback guidance (if Skill tool fails, read SKILL.md)
- [ ] CONTRIBUTING.md: generate.sh design rationale (why not ruler apply)
- [ ] Evaluate adding agnix to CI workflow alongside structural check

### Skill content improvements

Lessons from restructuring sessions. Codify into skills so consumers benefit.

- [ ] stack-plan: strengthen intermediate file state guidance (plan ALL
  states before flattening, Write correct content before staging each commit)
- [ ] stack-plan: add rename/move orphaned deletion check
- [ ] stack-plan: note that hooks fire during inconsistent restructure state
- [ ] stack-plan: make tree hash verification REQUIRED, not suggested
- [ ] stack-plan: document fixup pattern as restructure recovery mechanism
- [ ] stack-submit: add large stack scripting template (>10 commits)
- [ ] Remove sentinel commit convention from shared skills (personal pattern,
  not universal — remove from philosophy.md, stack-plan, stack-submit,
  stack-summary)

### Reduce tool approval friction

During restructure, many tool invocations required manual approval. Explore
ways to reduce this for both repo developers and skill consumers:

- [ ] Research using MCPs (git-mcp, github-mcp) instead of Bash for git
  operations — MCP tools are easier to bulk-approve than Bash commands
- [ ] Research `allowed-tools` in SKILL.md frontmatter — does Claude Code
  auto-approve tools listed there when a skill is invoked?
- [ ] Evaluate propagating permissions via home-manager module
  (`programs.claude-code.settings.permissions.allow`) for consumers
- [ ] Consider adding common git-branchless commands to `.claude/settings.json`
  `permissions.allow` patterns (already partially done — check coverage)
- [ ] Explore `--no-verify` alternatives during restructure that don't
  skip all hooks (e.g., env var to skip agnix but keep dprint)

### Explore rolling stack workflow

Currently skills assume bounded stacks. In practice, work is a continuous
stream — new commits on top while earlier ones are in review. Challenges:

- Ongoing work on top of unmerged PRs
- Partial merges change the base (`git sync --pull` rebases everything)
- Incremental submission (stack-submit assumes all-at-once)
- Review feedback arrives while developing new commits
- Stack never fully drains

Explore:

- [ ] Document rolling stack pattern in references/philosophy.md or new doc
- [ ] stack-submit: incremental submission mode (first N commits only)
- [ ] stack-fix: review-fix-while-developing workflow
- [ ] stack-plan: "continue" mode (add to existing stack)

### Deferred tooling

**nixd MCP bridge** — for Nix language diagnostics via
`isaacphi/mcp-language-server` or `cclsp`. Single MCP config for all
ecosystems. `mcps.nix` has `lsp-nix` preset (uses nil, not nixd).

**Native LSP per ecosystem** — low priority, only if manual editing
is needed. Claude Code plugin marketplace, Kiro `lsp.json`, Copilot
experimental `--experimental` flag.

**Dev tools without Nix** — `npx agnix`, `npx ruler` as devShell
alternatives. Document in CONTRIBUTING.md once validated.

---

## Distribution work

### Merge workflow

Merge PRs #88–#103 from bottom up. After each squash merge:

```bash
git sync --pull
gh pr edit <next-PR> --base main
git push --force-with-lease origin <remaining-branches>
```

### Post-merge: distribute tip commits

3 tip commits not in PRs (agnix hook, validation instructions, dprint
formatter). After main PRs merged, either absorb into existing commits
or submit as new PRs.

### Post-merge: validation

- [ ] Validate Copilot CLI global path (`~/.copilot/`)
- [ ] Validate Kiro global path (`~/.kiro/`)
- [ ] Test Kiro/Copilot skill discovery with real stack operations
- [ ] nix-mcp-servers integration test (add as flake input, test skills)

### Dismiss stale Copilot threads (old PRs #69–#87)

Old PRs are closed. Threads are moot. If any reopen, dismiss:

- PR #69: rename confusion (Copilot misread diff)
- PR #70: 7x ADR 0003 (absorbed into restructured commit)
- PR #73: lib/routing still used (retired in next commit)
- PR #74: docs reference old pipeline (absorbed into restructured commit)
- PR #78: reference files don't exist yet (reordered after references)

---

## Observations

- rust-overlay in all perPkg including Python git-revise — harmless
- CDX-AG-005 suppressed in `.agnix.toml` — agnix bug, review on upgrade
- Ruler `--project-root` doesn't isolate config loading — abandoned
- agnix-mcp doesn't read `.agnix.toml` — uses `LintConfig::default()`
  instead of `load_or_default()`. May file upstream issue later.
- PostToolUse hooks don't fire on Bash tool edits (known limitation)
- `ENABLE_LSP_TOOL` no longer needed on Claude Code 2.1.50+
