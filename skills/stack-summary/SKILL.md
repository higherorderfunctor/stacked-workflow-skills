---
name: stack-summary
description: >-
  Analyze a commit stack and produce a structured summary with per-commit
  classification, philosophy audit, and violation flags. Output is designed
  to feed directly into /stack-plan restructure mode. Use INSTEAD of manual
  git log inspection when evaluating stack quality.
argument-hint: "<range | --root | (none for stack())>"
disable-model-invocation: true
compatibility: "Requires git-branchless"
---

Analyze a commit stack and produce a structured report. The output serves two
purposes:

- **Human review** — understand what each commit does at a glance
- **Planner input** — feed violations directly into `/stack-plan` restructure

## Pre-flight

1. **Load references** — read `references/philosophy.md` (relative to this
   skill's directory).

2. **Check branchless init**:
   ```bash
   if [ ! -d ".git/branchless" ]; then git branchless init; fi
   ```

3. **Check for stale rebase state**:
   ```bash
   ls .git/rebase-merge .git/rebase-apply 2>/dev/null
   ```
   If present, run `git rebase --abort` before proceeding.

## Determine Range

Examine `$ARGUMENTS` to select the commit range:

- If `$ARGUMENTS` is a range (`main..HEAD`, `hash..hash`) → use it
- If `$ARGUMENTS` is `--root` → use the full history from root to HEAD
- If `$ARGUMENTS` is empty → use `stack()` (current stack)
- If on main with no stack → use full history (`--root`)

Resolve to `BASE` and `TIP`:
```bash
# Range:
BASE=<resolved>; TIP=<resolved>

# --root:
BASE=$(git hash-object -t tree /dev/null)   # empty tree
TIP=HEAD

# stack() (use branchless commands, not git log):
git sl
```

## Gather Data

For each commit in the range, collect:

```bash
# 1. Commit list with messages
git log --oneline --reverse $BASE..$TIP

# 2. Per-commit file stats
git log --reverse --stat --format="=== %h %s ===" $BASE..$TIP

# 3. Total diff stats for verification
git diff --stat $BASE..$TIP

# For --root, use these instead (git log supports --root but git diff doesn't,
# so we diff against the empty-tree hash):
git log --oneline --reverse --root
git log --reverse --stat --format="=== %h %s ===" --root
git diff --stat $(git hash-object -t tree /dev/null) HEAD
```

For commits flagged during audit (oversized, potentially bundled), read the
full diff to understand the content:
```bash
git show <hash> --stat
git show <hash>   # full diff when needed
```

## Classify Each Commit

For every commit, determine:

1. **Type**: which concern does it address?
   - `identity` — LICENSE, README intro, project setup
   - `instructions` — CLAUDE.md, coding standards, conventions
   - `build` — flake, dependencies, devShell, overlays, lock files
   - `format` — formatters, linters, dprint, alejandra
   - `ci` — GitHub Actions, CI workflows
   - `tooling` — editor config, Claude Code settings, steering files
   - `reference` — reference docs (philosophy, tool docs)
   - `skill` — SKILL.md files
   - `integration` — symlinks, routing tables, skill wiring
   - `docs` — README sections, installation guides, user-facing docs
   - `test` — tests, test infrastructure
   - `chore` — TODO, changelog, metadata

2. **Files**: list of files created or modified
3. **Lines**: insertions + deletions (from `--stat`)
4. **Scope**: the most specific component name

## Audit Against Philosophy

Check each commit against `references/philosophy.md` rules:

### Sizing (§ Sizing Heuristic)
- Flag commits exceeding 200 lines changed
- Flag commits under 50 lines that could merge with adjacent same-concern

### Atomic (§ Atomic Commits)
- Flag commits with "and" in the description (may need splitting)
- Flag commits touching unrelated concerns (e.g. build + docs + skill)
- Flag commits that bundle multiple features (e.g. 3 skills in one commit)

### Incremental Content (§ Incremental Content)
- Flag README/CLAUDE.md content that appears in a late batch commit instead
  of with the feature it documents
- Flag doc-only commits whose content belongs with earlier feature commits
- Flag monolithic doc commits (>100 lines of docs added at once)

### Dependency Timing (§ Dependency Timing)
- Flag dependencies/config added before they're used
- Flag forward references (commit references something from a later commit)

### Ordering (§ Commit Ordering)
- Flag refactoring mixed with feature work
- Flag features before their dependencies

### History Hygiene (§ History Hygiene)
- Flag "fix", "WIP", "tweaks", "addresses feedback" commits

## Produce Output

Format the summary in two sections:

### Stack Summary

```
Stack: <range> (<N> commits, <total lines> lines)

| # | Hash | Message | Type | Files | Lines | Flags |
|---|------|---------|------|-------|-------|-------|
| 1 | abc1234 | chore: initial commit | identity | LICENSE, README.md | 29 | |
| 2 | def5678 | feat(flake): add skeleton | build | flake.nix, ... | 81 | |
| 3 | ghi9012 | feat(skills): add fix, split, test | skill | 3 SKILL.md | 388 | OVERSIZED, BUNDLED |
...
```

Use these flag labels:
- `OVERSIZED` — exceeds 200 lines
- `UNDERSIZED` — under 50 lines, mergeable with adjacent
- `BUNDLED` — multiple features in one commit
- `BATCHED-DOCS` — docs that should be distributed to feature commits
- `FORWARD-REF` — references something from a later commit
- `MIXED-CONCERNS` — touches unrelated concerns
- `EARLY-DEP` — dependency added before first use
- `HYGIENE` — fix/WIP/tweaks commit message

### Violations

For each flagged commit, explain:

```
### [OVERSIZED] abc1234 feat(skills): add fix, split, test (388 lines)

Three distinct skills bundled into one commit. Each skill is an independent
feature with its own SKILL.md. Should be split into 3 commits (~130 lines
each).

Suggested split:
1. feat(stack-fix): add stack-fix skill — skills/stack-fix/SKILL.md (~182 lines)
2. feat(stack-split): add stack-split skill — skills/stack-split/SKILL.md (~113 lines)
3. feat(stack-test): add stack-test skill — skills/stack-test/SKILL.md (~93 lines)
```

### Planner Handoff

If violations are found, end with:

```
To restructure this stack, run:
  /stack-plan restructure <range>

Key changes needed:
- Split commit abc1234 into 3 skill commits
- Distribute README content from xyz7890 to feature commits
- Move CLAUDE.md routing table from ... to skill commits
```

If no violations are found:

```
Stack is clean. No restructuring needed.
```

## Tips

- Don't over-flag. A 210-line commit for a single large reference doc is
  fine — it's one coherent document. Flag the pattern, not the number.
- Bundled commits are the most impactful violation to catch — they affect
  revertibility and review quality.
- The summary table should be copy-pasteable into a conversation with
  `/stack-plan` for restructuring.
- When unsure if content is "batched docs" vs. legitimate cross-cutting
  packaging docs, note the ambiguity rather than hard-flagging.
