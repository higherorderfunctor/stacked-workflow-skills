---
name: stack-submit
description: >-
  Sync, validate, and push an entire commit stack. Use INSTEAD of manual
  git sync + git submit + gh pr create. Handles branch creation, stacked
  PR creation with correct base branches, and sentinel commit exclusion.
argument-hint: "[revset]"
disable-model-invocation: true
compatibility:
  - git-branchless
---

Submit the current commit stack for review. If an argument is provided, use it
as a revset to select which commits to submit. Default is the current stack.

## Pre-flight

1. **Load references** — read `references/git-branchless.md` from this package
   before proceeding.

2. **Check branchless init**:
   ```bash
   if [ ! -d ".git/branchless" ]; then git branchless init; fi
   ```

3. **Check for stale rebase state**:
   ```bash
   ls .git/rebase-merge .git/rebase-apply 2>/dev/null
   ```
   If present, run `git rebase --abort` before proceeding.

4. **Check remote and pushDefault**:
   ```bash
   git remote -v
   git config remote.pushDefault
   ```
   If no remote exists, ask the user for the remote URL.
   If `remote.pushDefault` is not set, set it:
   ```bash
   git config remote.pushDefault origin
   ```
   `git submit -c` requires this to know where to push new branches.

## Steps

1. **Visualize the stack** with `git sl` to understand what will be submitted.

2. **Determine the commit range**:
   ```bash
   # If argument is a revset (use git sl or git branchless log, not git log):
   git sl

   # If no argument, try stack():
   git sl

   # If on main with no stack, use draft():
   git query 'draft()'

   # If all commits are public (on main), the user needs to specify
   # a range explicitly or use --root
   ```

3. **Sync with main** to ensure the stack is up to date:
   ```bash
   git sync --pull
   ```
   If this is the first push (remote main doesn't exist or has fewer commits),
   sync may be a no-op — that's fine.

   If conflicts are reported (without `--merge`), stop and inform the user
   which commits conflict. Ask if they want to resolve with
   `git sync --merge` or handle individually with
   `git move -b <hash> -d main --merge`.

4. **Run tests across the stack** to validate each commit independently:
   ```bash
   git test run -x '<test-command>' 'stack()'
   ```
   Determine the test command from the project (package.json scripts, Makefile,
   Cargo.toml, etc.). If no obvious test command exists, ask the user. If the
   project has no tests, skip this step.

   If any commit fails, stop and report which commit(s) failed. Do not submit
   a stack with failing tests.

5. **Verify commit messages** — review `git sl` output. Flag any commits with
   vague messages ("fix", "WIP", "update") and suggest rewording with
   `git reword <commit>`.

6. **Identify sentinel commits** — commits that should be pushed but NOT get
   PRs (e.g. TODO.md, CHANGELOG.md, tracking metadata). Look for:
   - Commits with messages starting with `chore: add TODO` or similar metadata
   - The tip commit if the user mentioned keeping it as a tracking branch
   - Any commits the user explicitly excluded from PR creation

   For sentinel commits, create a tracking branch (e.g. `todo/pre-publish`)
   that will be pushed but skipped during PR creation.

7. **Ensure branches exist** on each commit. For commits without branches,
   generate branch names from commit messages:
   ```bash
   # Pattern: type/scope or type/short-description
   # feat(flake): add minimal flake skeleton → feat/flake-skeleton
   # docs(references): add git-branchless reference → docs/git-branchless-reference
   # chore: add TODO.md → todo/pre-publish (sentinel)
   ```

   Create branches:
   ```bash
   git branch <branch-name> <commit-hash>
   ```

   Present the branch list to the user for review before proceeding.

8. **Push branches** with `git submit` or `git push`:
   ```bash
   git submit -c $ARGUMENTS
   ```

   **Gotcha:** `git submit -c` silently does nothing when commits are on main
   (public/non-draft). This happens when the entire history is being submitted
   for the first time on the main branch. In this case, fall back to manual
   push:
   ```bash
   git push -u origin <branch-1> <branch-2> ... <branch-N>
   ```
   The `-u` flag sets upstream tracking so tools like lazygit show branches
   as in-sync with remote.

   **Gotcha:** `git submit` skips commits with 2+ branches attached. Ensure
   one branch per commit.

   **Gotcha:** `git submit` requires `remote.pushDefault` to be set for
   `--create` mode:
   ```bash
   git config remote.pushDefault origin
   ```

9. **Create stacked PRs** — for each non-sentinel branch, create a PR
   targeting the previous branch in the stack (or `main` for the first):

   ```bash
   # First commit after main:
   gh pr create --head <branch-1> --base main \
     --title "<commit message>" --body "$(cat <<'EOF'
   ## Summary
   <one-line description>

   Stack: 1/N

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   EOF
   )"

   # Subsequent commits:
   gh pr create --head <branch-N> --base <branch-N-1> \
     --title "<commit message>" --body "..."
   ```

   Use the commit message as the PR title. Keep the body minimal — the commit
   diff speaks for itself.

   **Do NOT create PRs for sentinel/tracking branches.**

10. **Report results** — show a summary table:

    ```
    | # | Branch | PR | Base | Status |
    |---|--------|----|------|--------|
    | 1 | feat/flake-skeleton | #2 | main | created |
    | 2 | chore/formatting | #3 | feat/flake-skeleton | created |
    | ... | ... | ... | ... | ... |
    | 25 | todo/pre-publish | — | (tracking only) | pushed |
    ```

## Subsequent Updates

After amending or restacking commits, re-submit with:
```bash
git submit    # force-push all existing remote branches (no -c needed)
```

If `git submit` produces no output (public commits on main), force-push all
branches manually:
```bash
git push origin --force <branch-1> <branch-2> ... <branch-N>
```

PRs auto-update when their branches are force-pushed. No need to recreate PRs.
Only branches downstream of the changed commit need updating, but pushing all
is safe — unchanged branches are skipped automatically.

After each squash-merged PR, you MUST sync and force-push remaining branches.
Without this, downstream PRs show the full diff of all prior commits (the
squash merge creates a new commit hash that downstream branches don't share).

```bash
# 1. Sync: rebases stack onto the new squash-merged main
git checkout <any-stack-branch>
git branch -f main origin/main
git sync --pull

# 2. Force-push ALL remaining branches so PRs show clean single-commit diffs
git push -u --force origin <branch-1> <branch-2> ... <branch-N>
```

This must be done after EVERY squash merge, not just the first. Each merge
changes main, and all downstream branches need rebasing onto it.

**Gotcha:** Squash-merged PRs are not always detected by `git sync` — manually
`git hide -r <hash>` if needed (arxanas/git-branchless#965).

### Out-of-order merge recovery

If a PR is merged out of order (e.g., PR N+1 merged before PR N), the squash
goes into the base branch — not main. Merge the base PR (N) next — it now
contains both changes. After merging:

```bash
git fetch origin && git branch -f main origin/main
git sync --pull     # may only skip one of the two commits
```

If `git sync` doesn't skip the already-merged commit, move the remaining
stack past it:
```bash
git move -f -s <first-unskipped-hash> -d main
```

Then hide orphaned commits and force-push all branches.

## Addressing Review Feedback

When a reviewer (human, Copilot, etc.) comments on a specific PR in the stack:

1. **Identify the target commit** — the PR tells you which branch/commit the
   feedback applies to.

2. **Choose the fix strategy** based on the type of change:

   **Line-level fixes** (typos, adding a line, small edits): use absorb with
   `--base` to constrain routing to the target commit:
   ```bash
   # stage the fix, then:
   git absorb --and-rebase --base <target-branch>^
   ```

   **Structural changes** (rewriting sections, moving content, adding files):
   checkout the target commit and amend directly:
   ```bash
   git checkout <target-branch>
   # edit files...
   git add <files>
   git amend
   ```

3. **Restack descendants** (amend path only — absorb restacks automatically):
   ```bash
   git restack          # in-memory, no conflicts usually
   git restack --merge  # if in-memory fails with conflicts
   ```

4. **Force-push all downstream branches** (target + every branch after it):
   ```bash
   git push --force origin <target-branch> <downstream-1> ... <downstream-N>
   ```

5. **Return to the stack tip** after pushing:
   ```bash
   git checkout <tip-branch>   # e.g. todo/pre-publish or the last PR branch
   ```

6. **Reply to and resolve** the review comments.

**Always use `--base` when absorbing review feedback.** Without it, absorb
searches the full stack by diff context and may route to a later commit with
more matching context — especially for files built incrementally across
commits (README.md, CLAUDE.md). `--base <target>` constrains the search to
that commit.

**Never `git add` + `git amend` after a failed `git checkout`.** If checkout
fails (e.g. "local changes would be overwritten"), you are still on the
PREVIOUS branch. Any subsequent `git amend` goes into that commit, not the
one you intended. Always verify with `git log --oneline -1` before amending
(`git branch --show-current` prints nothing in detached HEAD).
If checkout fails, stash or commit your changes first, then retry.

**Conflict resolution during restack:** If the amend changes a file that
downstream commits also modify (common with README.md, CLAUDE.md), the restack
may hit conflicts. Resolve them manually — the fix is usually to keep the
downstream version and incorporate your amend's change into it.

## Tips

- Always start with `git sl` to understand the stack before submitting.
- One branch per commit. If a commit has multiple branches, `git submit` skips it.
- Sentinel branches (TODO, CHANGELOG) are pushed for backup but don't get PRs.
  Delete them after publish with `git push origin --delete todo/pre-publish`.
- For very large stacks (20+ PRs), consider batching — submit the first 5-10,
  get them merged, then submit the next batch. Reviewers struggle with 20+ open
  PRs at once.
- If `git submit -c` fails with "no remote configured", set
  `git config remote.pushDefault origin`.
- If `git submit -c` produces no output, commits are likely public (on main).
  Use `git push origin <branch> ...` instead.
- For PR creation scripts, use a standalone bash script file rather than
  inline shell — zsh does not support `${!array[@]}` and other bashisms.
  Always use `#!/usr/bin/env bash` with strict mode.
