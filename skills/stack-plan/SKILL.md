---
name: stack-plan
description: >-
  Plan and build a commit stack from a description, uncommitted work, or
  existing commits. Use INSTEAD of manual git rebase -i, git reset --soft,
  or ad-hoc git move sequences. Prevents: wrong commit ordering, forward
  references, git move -F panics, untested intermediate commits.
argument-hint: "<plan | range | (none for working tree)>"
disable-model-invocation: true
compatibility:
  - git-branchless
---

Plan and execute a commit stack. Determines mode automatically based on input:

- **From a plan/description** — user describes what needs to be built; skill
  produces the commit ordering and executes it
- **From uncommitted work** — working tree has changes; skill classifies and
  commits them as an atomic stack
- **From existing commits** — range like `main..HEAD`; skill restructures into
  a clean atomic stack

## Pre-flight

1. **Load references** — read `references/philosophy.md` and
   `references/git-branchless.md` from this package before proceeding.

2. **Check branchless init**:
   ```bash
   if [ ! -d ".git/branchless" ]; then git branchless init; fi
   ```

3. **Check for stale rebase state**:
   ```bash
   ls .git/rebase-merge .git/rebase-apply 2>/dev/null
   ```
   If present, run `git rebase --abort` before proceeding.

## Determine Mode

Examine `$ARGUMENTS` and repo state to select the mode:

- If `$ARGUMENTS` looks like a commit range (`main..HEAD`, `hash1..hash2`,
  branch name) → **Restructure mode**
- If `$ARGUMENTS` is a natural-language description of work to do →
  **Plan mode**
- If `$ARGUMENTS` is empty and the working tree has uncommitted changes →
  **Working tree mode**
- If `$ARGUMENTS` is empty and the working tree is clean → ask the user what
  they want to do

## Plan Mode

The user describes work to be done. Build the stack from scratch.

1. **Understand the task** from `$ARGUMENTS`. If the description is vague, ask
   clarifying questions.

2. **Design the commit stack** following the ordering in
   `references/philosophy.md`:
   1. Refactoring / cleanup (separate from feature work, always first)
   2. Dependencies / build config changes
   3. Scaffolding / types / interfaces / schemas
   4. Core business logic
   5. Edge cases / error handling
   6. Tests

   For each commit, note:
   - One-sentence commit message (Conventional Commits format)
   - Which files will be created or modified
   - Estimated line count (target 50-200 per commit)
   - Dependencies on prior commits (no forward references)

3. **Verify no forward references**: each commit must only reference files,
   imports, and config that exist in it or earlier commits. Documentation goes
   WITH the feature it documents. Dependencies arrive in the commit that first
   uses them.

4. **Present the plan** to the user:
   ```
   Proposed stack (N commits):

   1. type(scope): description — files X, Y (~80 lines)
   2. type(scope): description — files A, B (~120 lines)
   3. type(scope): description — files C, D, E (~150 lines)
   ...
   ```
   **Wait for user approval.** Adjust if they have feedback.

5. **Execute the plan** — implement each commit in order:
   ```bash
   # Write the code for commit 1
   git add <files>
   git commit -m "type(scope): description"

   # Write the code for commit 2
   git add <files>
   git commit -m "type(scope): description"
   ```
   After each commit, verify the codebase is in a working state.

## Working Tree Mode

Uncommitted changes exist. Classify and commit them as a stack.

1. **Survey the changes**:
   ```bash
   git status --short
   git diff --stat
   git diff
   ```
   Read the full diff. Count total lines changed.

2. **Classify every change** into logical groups following the ordering in
   `references/philosophy.md`. For each group, note:
   - Which files and hunks belong to it
   - A one-sentence commit message
   - Estimated line count (target 50-200 per commit)

   If a file has changes spanning multiple groups, it will need `git add -p`
   to split hunks across commits.

3. **Present the plan** to the user (same format as Plan mode step 4).
   **Wait for user approval.**

4. **Commit each group** in plan order:
   ```bash
   # For file-level grouping:
   git add <file1> <file2>
   git commit -m "type(scope): description"

   # For hunk-level splitting within a file:
   git add -p <file>
   git commit -m "type(scope): description"
   ```

   After each commit, verify nothing was missed or double-counted:
   ```bash
   git diff --stat   # remaining uncommitted changes
   ```

## Restructure Mode

Existing commits need to be reorganized into a clean atomic stack.

1. **Parse the range** from `$ARGUMENTS`. Resolve to a `<base>` and `<tip>`:
   ```bash
   # For range syntax (base..tip):
   BASE=<resolved base>
   TIP=<resolved tip>

   # For a branch name, find the merge-base:
   BASE=$(git merge-base main <branch>)
   TIP=<branch>
   ```

2. **Understand the current state**:
   ```bash
   git sl
   git log --oneline $BASE..$TIP
   git diff --stat $BASE..$TIP
   git diff $BASE..$TIP
   ```
   Read the full diff. Count total lines changed.

3. **Classify every change** into logical groups (same as Working Tree mode
   step 2).

4. **Present the plan** (same format as Plan mode step 4).
   **Wait for user approval.**

5. **Check for uncommitted work** before flattening:
   ```bash
   git status --short
   ```
   If there are uncommitted changes, warn the user and ask whether to stash
   or commit them first.

6. **Flatten the range** into the working tree:
   ```bash
   git reset --soft $BASE
   git restore --staged .
   ```
   Verify the working tree matches the original diff:
   ```bash
   git diff --stat   # should match step 2's total diff
   ```

7. **Commit each group** in plan order (same as Working Tree mode step 4).

## Post-execution

1. **Verify the result**:
   ```bash
   git sl
   ```
   Show the user the new stack.

2. **Confirm total diff is identical** (Restructure mode only — `$BASE` is
   only defined in Restructure mode, not Working Tree mode):
   ```bash
   git diff $BASE..HEAD --stat   # should match the original
   ```

3. **Run tests** if a test command is identifiable:
   ```bash
   git test run -x '<test-command>' 'stack()'
   ```
   Report any commits that break the build.

## Tips

- **Don't lose changes.** After flattening, double-check `git diff --stat`
  matches the original range diff. If anything is missing, stop and
  investigate.
- Format-only changes (whitespace, import sorting) should ALWAYS be a separate
  commit — they dominate diffs and obscure real changes.
- If the total changeset is small enough to group by file (no hunk splitting
  needed), prefer `git add <files>` over `git add -p` for speed.
- If a commit exceeds 200 lines, split it further rather than letting it grow.
- Commit messages should explain WHY, not just WHAT.
- If the user wants to keep some original commit boundaries, respect that —
  not every restructure needs to flatten everything.
