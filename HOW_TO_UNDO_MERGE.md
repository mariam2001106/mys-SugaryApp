# How to Go Back Before a Merge

This guide covers different scenarios for undoing or reverting merges in Git.

## Current Status
- **Branch**: `copilot/fix-local-notification-issue`
- **Status**: Clean working directory, no active merge
- **Last Actions**: Commits on feature branch, no merge performed yet

---

## Scenario 1: Abort a Merge in Progress

If you're in the **middle of a merge** and want to cancel it:

### Check if merge is in progress:
```bash
git status
```

If you see "You have unmerged paths" or merge conflicts, abort with:

```bash
git merge --abort
```

This returns you to the state before you started the merge.

### What it does:
- ✅ Cancels the merge operation
- ✅ Restores your working directory to pre-merge state
- ✅ No commits are created
- ✅ Safe to use - won't lose your work

---

## Scenario 2: Undo a Merge That Was Just Completed

If you **just merged** but haven't pushed yet:

### Check recent commits:
```bash
git log --oneline -5
```

### Option A: Reset to Before the Merge (Recommended if not pushed)
```bash
# Find the commit hash BEFORE the merge
git log --oneline -10

# Reset to that commit (replace COMMIT_HASH with actual hash)
git reset --hard COMMIT_HASH
```

**⚠️ WARNING**: `--hard` will discard all changes. Use `--soft` if you want to keep changes.

### Option B: Undo Last Commit (if merge was the last commit)
```bash
git reset --hard HEAD~1
```

### Option C: Keep changes but undo commit
```bash
git reset --soft HEAD~1
```

This keeps your changes staged, just undoes the commit.

---

## Scenario 3: Undo a Merge That Was Already Pushed

If the merge was **pushed to remote**, use revert instead of reset:

### Option A: Revert the Merge Commit
```bash
# Find the merge commit hash
git log --oneline --merges -5

# Revert it (replace MERGE_COMMIT_HASH)
git revert -m 1 MERGE_COMMIT_HASH

# Push the revert
git push origin main
```

The `-m 1` tells Git which parent to consider as the "mainline".

### Option B: Revert to a Specific Commit (Creates new commit)
```bash
# Find the commit you want to go back to
git log --oneline -10

# Create a new commit that undoes everything since that commit
git revert --no-commit COMMIT_HASH..HEAD
git commit -m "Revert to state before merge"
git push origin main
```

### Why not use `reset` after pushing?
- ❌ Rewrites history (bad for shared branches)
- ❌ Causes issues for other collaborators
- ❌ Can lose work from other people
- ✅ `revert` creates a new commit that undoes changes (safe!)

---

## Scenario 4: Undo via GitHub (If Merged via Pull Request)

If you merged via GitHub Pull Request:

### Option A: Revert via GitHub Interface (Easiest!)
1. Go to the Pull Request on GitHub
2. Scroll down to the merge commit
3. Click **"Revert"** button
4. GitHub creates a new PR that undoes the merge
5. Merge the revert PR

### Option B: Manual Revert on GitHub
1. Go to repository → **"Commits"**
2. Find the merge commit
3. Click the `<>` icon to browse at that commit
4. Click **"Revert"** from the dropdown
5. Create PR with the revert

---

## Scenario 5: Go Back to a Specific Point in Time

To restore your repository to a specific state:

### View history with dates:
```bash
git log --oneline --graph --date=short --pretty=format:"%h %ad %s"
```

### Create a new branch at that point:
```bash
# Create a branch at a specific commit
git checkout -b rollback-branch COMMIT_HASH

# Or go back on current branch (dangerous!)
git reset --hard COMMIT_HASH
```

### Restore specific files only:
```bash
# Restore a file to its state in a specific commit
git checkout COMMIT_HASH -- path/to/file

# Restore a file to state before merge
git checkout HEAD~1 -- path/to/file
```

---

## Scenario 6: Undo Changes in Your Current Branch (Before Merging)

Since you're on `copilot/fix-local-notification-issue` and **haven't merged yet**:

### To undo recent commits on your feature branch:

```bash
# See what you'll be undoing
git log --oneline -5

# Undo last commit, keep changes
git reset --soft HEAD~1

# Undo last commit, discard changes
git reset --hard HEAD~1

# Undo multiple commits (e.g., last 3)
git reset --hard HEAD~3
```

### To go back to a specific commit:
```bash
# Find the commit you want
git log --oneline -10

# Reset to that commit
git reset --hard COMMIT_HASH
```

### To force push after reset (if already pushed):
```bash
# ⚠️ Only do this on YOUR feature branch, not on main!
git push --force origin copilot/fix-local-notification-issue
```

---

## Scenario 7: Temporarily Go Back (Without Undoing)

To look at old code without changing anything:

```bash
# View code at a specific commit
git checkout COMMIT_HASH

# Look around, test things...

# Return to your branch
git checkout copilot/fix-local-notification-issue
```

You're in "detached HEAD" state - just for viewing.

---

## Quick Decision Guide

**Choose based on your situation:**

| Situation | Command | Safe? |
|-----------|---------|-------|
| Merge in progress, want to cancel | `git merge --abort` | ✅ Yes |
| Just merged, not pushed | `git reset --hard HEAD~1` | ✅ Yes |
| Merged and pushed | `git revert -m 1 HASH` | ✅ Yes |
| Merged via GitHub PR | Use GitHub "Revert" button | ✅ Yes |
| Undo commit, keep changes | `git reset --soft HEAD~1` | ✅ Yes |
| Go back multiple commits | `git reset --hard HEAD~N` | ⚠️ If not pushed |
| Shared/main branch | Use `revert`, NOT `reset` | ✅ Yes |
| Your feature branch | Can use `reset --hard` | ✅ Yes |

---

## Important Safety Rules

### ✅ SAFE to use `git reset --hard`:
- On your personal feature branch
- Before pushing to remote
- When you're the only one working on the branch

### ❌ NEVER use `git reset --hard`:
- On `main` or `master` branch (if others use it)
- After pushing (unless on your private branch)
- On shared branches with collaborators

### ✅ ALWAYS use `git revert`:
- On main/master branch
- After pushing to shared branches
- When others have pulled your changes
- When you want to preserve history

---

## Examples for Your Current Situation

### You're on: `copilot/fix-local-notification-issue`

**If you want to undo your last commit:**
```bash
git reset --hard HEAD~1
git push --force origin copilot/fix-local-notification-issue
```

**If you want to undo last 3 commits:**
```bash
git reset --hard HEAD~3
git push --force origin copilot/fix-local-notification-issue
```

**If you want to go back to a specific commit:**
```bash
# Find the commit hash
git log --oneline -10

# Go back to it
git reset --hard <commit-hash>

# Force push
git push --force origin copilot/fix-local-notification-issue
```

**If you haven't merged to main yet:**
- You have full control over your feature branch
- You can reset, force push, rewrite history
- No risk to others since it's your branch

---

## Checking What Will Be Undone

Before undoing anything, check what you'll lose:

```bash
# See changes in last commit
git show HEAD

# See changes in last 3 commits
git log -p -3

# See what will be undone
git diff HEAD~1 HEAD
```

---

## Recovery Options

### If you accidentally reset too far:

```bash
# Find the commit you want to recover
git reflog

# Shows all your recent HEAD movements
# Find the commit hash you want

# Reset back to it
git reset --hard <commit-hash-from-reflog>
```

The `reflog` keeps history of where HEAD has been for about 90 days.

---

## Common Mistakes and Fixes

### Mistake: Used `reset --hard` on main branch
**Fix**: Use reflog to find the commit and reset back
```bash
git reflog
git reset --hard <previous-commit-hash>
```

### Mistake: Pushed a bad merge to main
**Fix**: Use revert, don't reset
```bash
git revert -m 1 <merge-commit-hash>
git push origin main
```

### Mistake: Accidentally deleted commits
**Fix**: Check reflog
```bash
git reflog
git cherry-pick <lost-commit-hash>
```

---

## Testing Before You Undo

Always test first:

```bash
# Create a backup branch before undoing
git branch backup-before-undo

# Now do your undo operation
git reset --hard HEAD~1

# If something goes wrong:
git reset --hard backup-before-undo
```

---

## Summary

**You have NOT merged yet**, so you're in a safe position!

**To go back on your current feature branch:**
```bash
# Undo last commit
git reset --hard HEAD~1

# Or go to specific commit
git log --oneline -10
git reset --hard <commit-hash>

# Then force push (safe on feature branch)
git push --force origin copilot/fix-local-notification-issue
```

**If you ever DO merge and want to undo:**
- On your feature branch: Use `reset --hard`
- On main branch: Use `revert` or GitHub's revert button
- During merge: Use `git merge --abort`

**Always remember:**
- `reset` = rewrite history (use on private branches)
- `revert` = create new commit that undoes (use on shared branches)
- `merge --abort` = cancel merge in progress

Need help with a specific scenario? Ask! 🚀
