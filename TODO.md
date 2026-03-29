# TODO

## Stack status

16 stacked PRs (#88–#103) + 5 tip commits not in PRs (agnix hook,
validation instructions, dprint formatter, review fixes, sentinel).
Old PRs #69–#87 closed. Don't push branches or recreate PRs until
ready to distribute — Copilot auto-review burns tokens per push.

---

## Implementation work

### Review fixes

Full triage in memory `project_copilot_review_triage.md`.

High confidence (can do without HITL):

- [ ] `references/agnix.md`: use https:// URL for repo link
- [ ] `references/ruler.md`: fix generate.sh wording (line 99 — says
      "copying ruler output" but it directly concatenates with printf)
- [ ] `CONTRIBUTING.md`: change `pip install git-revise` to
      `pip install --user git-revise` or `pipx install git-revise`
- [ ] `skills/stack-submit/SKILL.md`: add explicit user approval gate
      before pushing branches (step 8) — currently auto-invocation can
      trigger remote side effects without confirmation

Needs design input:

- [ ] Consider ADR 0004 for superseding decision (per review-policy process)
- [ ] sws-* directory names violate Agent Skills spec (name must match dir)
- [ ] README Quick Start symlink uses fragile `$(pwd)` pattern
- [ ] home-manager `claudeAvailable` check fragile (`hasAttrByPath`)
- [ ] Copilot module `~/.copilot/` vs manual `.github/` path confusion
- [ ] CONTRIBUTING.md Without Nix section: incomplete tool list — is
      non-Nix dev actually supported or just for reference?

### Codify repo instructions

- [ ] CONTRIBUTING.md: generate.sh design rationale (why not ruler apply)
- [ ] Evaluate adding agnix to CI workflow alongside structural check

### Skill content improvements

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

5 tip commits not in PRs (agnix hook, validation instructions, dprint
formatter, review fixes, sentinel). After main PRs merged, absorb into
existing commits or submit as new PRs.

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
