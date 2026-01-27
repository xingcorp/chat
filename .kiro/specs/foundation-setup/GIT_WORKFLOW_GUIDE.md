# Git Workflow Guide

## Overview

This document defines the Git workflow, branching strategy, and best practices for the Sharitek Office Chat project. Following this workflow ensures code quality, enables collaboration, and maintains a clean Git history.

## Branch Strategy

### Main Branches

**`main` branch:**
- Production-ready code only
- Protected branch (requires PR + reviews)
- Deployed to production
- Never commit directly to `main`
- Tagged with version numbers (v1.0.0, v1.1.0, etc.)

**`develop` branch:**
- Integration branch for features
- Protected branch (requires PR + CI pass)
- Deployed to staging environment
- All feature branches merge here first
- Regularly merged to `main` for releases

### Supporting Branches

**Feature branches:**
- Format: `feature/phase-X-feature-name`
- Examples:
  - `feature/phase-1-graphql-operations`
  - `feature/phase-1-data-models`
  - `feature/phase-2-message-reactions`
- Created from: `develop`
- Merged to: `develop`
- Deleted after merge

**Bugfix branches:**
- Format: `bugfix/issue-description`
- Examples:
  - `bugfix/message-not-sending`
  - `bugfix/offline-sync-crash`
- Created from: `develop` or `main` (for hotfixes)
- Merged to: `develop` (or `main` for hotfixes)
- Deleted after merge

**Hotfix branches:**
- Format: `hotfix/critical-issue`
- Examples:
  - `hotfix/authentication-failure`
  - `hotfix/data-loss-bug`
- Created from: `main`
- Merged to: `main` AND `develop`
- Deleted after merge
- Used only for critical production issues

**Release branches:**
- Format: `release/vX.Y.Z`
- Examples:
  - `release/v1.0.0`
  - `release/v1.1.0`
- Created from: `develop`
- Merged to: `main` AND `develop`
- Deleted after merge
- Used for release preparation (version bumps, final testing)

## Workflow Steps

### 1. Starting New Work

```bash
# Ensure you're on develop and up-to-date
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/phase-1-graphql-operations

# Verify you're on the correct branch
git branch
```

### 2. Making Changes

```bash
# Make your code changes
# ...

# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: implement GraphQL conversation operations

- Add chatConversationList query
- Add chatConversationDetail query
- Add chatGroupAdd mutation
- Add tests for all operations

Refs: #123"

# Push to remote
git push origin feature/phase-1-graphql-operations
```

### 3. Creating Pull Request

1. Go to GitHub/GitLab
2. Click "New Pull Request"
3. Select:
   - Base: `develop`
   - Compare: `feature/phase-1-graphql-operations`
4. Fill in PR template:
   - Title: Clear, descriptive
   - Description: What, why, how
   - Related issues: Link to issues
   - Testing: How to test
   - Screenshots: If UI changes
5. Request reviewers
6. Wait for CI/CD to pass
7. Address review feedback
8. Merge after approval

### 4. Keeping Branch Updated

```bash
# Fetch latest changes
git fetch origin

# Rebase on develop (preferred)
git rebase origin/develop

# Or merge develop (if rebase is complex)
git merge origin/develop

# Resolve conflicts if any
# ...

# Push updated branch
git push origin feature/phase-1-graphql-operations --force-with-lease
```

### 5. After Merge

```bash
# Switch back to develop
git checkout develop

# Pull latest changes
git pull origin develop

# Delete local feature branch
git branch -d feature/phase-1-graphql-operations

# Delete remote feature branch (if not auto-deleted)
git push origin --delete feature/phase-1-graphql-operations
```

## Commit Message Convention

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation changes
- **style:** Code style changes (formatting, no logic change)
- **refactor:** Code refactoring (no feature change)
- **perf:** Performance improvements
- **test:** Adding or updating tests
- **chore:** Build process, dependencies, tooling
- **ci:** CI/CD configuration changes

### Examples

```bash
# Feature
git commit -m "feat(chat): add message reactions

Implement add/remove reaction functionality
- Add AddReactionUseCase
- Add RemoveReactionUseCase
- Update MessageModel with reactions field
- Add reaction UI components

Refs: #234"

# Bug fix
git commit -m "fix(offline): resolve sync queue crash

Fix null pointer exception in sync queue
when processing offline messages

Fixes: #456"

# Documentation
git commit -m "docs(readme): update setup instructions

Add Flutter SDK version requirement
Add build_runner setup steps"

# Refactoring
git commit -m "refactor(repository): simplify error handling

Extract error mapping to separate utility
Reduce code duplication in repositories"

# Test
git commit -m "test(usecase): add unit tests for GetMessagesUseCase

Add tests for:
- Success case
- Network failure case
- Empty result case"
```

## Branch Protection Rules

### `main` Branch Protection

**Required:**
- [ ] Require pull request before merging
- [ ] Require 2 approvals
- [ ] Require status checks to pass (CI/CD)
- [ ] Require branches to be up to date
- [ ] Require conversation resolution
- [ ] Do not allow bypassing (even for admins)
- [ ] Restrict who can push (only release manager)

**Status Checks Required:**
- [ ] `flutter-analyze`
- [ ] `flutter-test`
- [ ] `build-success`

### `develop` Branch Protection

**Required:**
- [ ] Require pull request before merging
- [ ] Require 1 approval
- [ ] Require status checks to pass (CI/CD)
- [ ] Require branches to be up to date
- [ ] Allow force push (for rebasing)

**Status Checks Required:**
- [ ] `flutter-analyze`
- [ ] `flutter-test`

## Git Hooks (Optional but Recommended)

### Pre-commit Hook

Runs before each commit to ensure code quality.

**Location:** `.git/hooks/pre-commit`

```bash
#!/bin/sh
# Pre-commit hook for Flutter project

echo "Running pre-commit checks..."

# Run Flutter analyze
echo "Running flutter analyze..."
flutter analyze
if [ $? -ne 0 ]; then
  echo "❌ Flutter analyze failed. Please fix errors before committing."
  exit 1
fi

# Run Flutter format check
echo "Checking code formatting..."
flutter format --set-exit-if-changed .
if [ $? -ne 0 ]; then
  echo "❌ Code is not formatted. Run 'flutter format .' to fix."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
exit 0
```

### Pre-push Hook

Runs before pushing to ensure tests pass.

**Location:** `.git/hooks/pre-push`

```bash
#!/bin/sh
# Pre-push hook for Flutter project

echo "Running pre-push checks..."

# Run Flutter tests
echo "Running flutter test..."
flutter test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Please fix failing tests before pushing."
  exit 1
fi

echo "✅ Pre-push checks passed!"
exit 0
```

### Commit Message Hook

Validates commit message format.

**Location:** `.git/hooks/commit-msg`

```bash
#!/bin/sh
# Commit message hook

commit_msg_file=$1
commit_msg=$(cat "$commit_msg_file")

# Check if commit message matches conventional format
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|chore|ci)(\(.+\))?: .+"; then
  echo "❌ Invalid commit message format."
  echo "Format: <type>(<scope>): <subject>"
  echo "Example: feat(chat): add message reactions"
  exit 1
fi

echo "✅ Commit message format is valid!"
exit 0
```

### Installing Hooks

```bash
# Make hooks executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
chmod +x .git/hooks/commit-msg

# Or use a tool like Husky (for Node.js projects)
# Or use lefthook (for any project)
```

## Code Review Process

### For Authors

**Before Creating PR:**
1. [ ] Run `flutter analyze` - no errors
2. [ ] Run `flutter test` - all tests pass
3. [ ] Run `flutter format .` - code formatted
4. [ ] Self-review your changes
5. [ ] Update documentation if needed
6. [ ] Add tests for new features
7. [ ] Ensure CI/CD passes

**Creating PR:**
1. [ ] Write clear title and description
2. [ ] Link related issues
3. [ ] Add screenshots for UI changes
4. [ ] Request appropriate reviewers
5. [ ] Add labels (feature, bugfix, etc.)

**During Review:**
1. [ ] Respond to comments promptly
2. [ ] Address all feedback
3. [ ] Re-request review after changes
4. [ ] Resolve conversations
5. [ ] Keep PR updated with develop

### For Reviewers

**Review Checklist:**
- [ ] Code follows Clean Architecture
- [ ] No layer violations
- [ ] Proper error handling with `Either<Failure, T>`
- [ ] Uses dependency injection
- [ ] Has unit tests
- [ ] Uses localization for UI strings
- [ ] No hardcoded values
- [ ] Proper null safety
- [ ] Performance optimized
- [ ] Documented public APIs
- [ ] No `print()` statements
- [ ] No relative imports
- [ ] Follows naming conventions

**Review Guidelines:**
1. Review within 24 hours
2. Be constructive and specific
3. Ask questions if unclear
4. Suggest improvements
5. Approve only if all checks pass
6. Request changes if issues found

## Common Git Commands

### Checking Status

```bash
# View current status
git status

# View commit history
git log --oneline --graph --all

# View changes
git diff

# View staged changes
git diff --staged
```

### Undoing Changes

```bash
# Discard unstaged changes
git checkout -- <file>

# Unstage changes
git reset HEAD <file>

# Amend last commit
git commit --amend

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

### Stashing Changes

```bash
# Stash current changes
git stash

# List stashes
git stash list

# Apply latest stash
git stash apply

# Apply and remove latest stash
git stash pop

# Stash with message
git stash save "WIP: implementing feature X"
```

### Rebasing

```bash
# Rebase on develop
git rebase origin/develop

# Interactive rebase (squash commits)
git rebase -i HEAD~3

# Continue after resolving conflicts
git rebase --continue

# Abort rebase
git rebase --abort
```

## Troubleshooting

### Merge Conflicts

```bash
# When you encounter conflicts
git status  # See conflicted files

# Edit files to resolve conflicts
# Look for <<<<<<< HEAD markers

# After resolving
git add <resolved-files>
git commit  # Or git rebase --continue if rebasing
```

### Accidentally Committed to Wrong Branch

```bash
# If not pushed yet
git reset --soft HEAD~1  # Undo commit, keep changes
git stash  # Stash changes
git checkout correct-branch
git stash pop  # Apply changes
git add .
git commit -m "..."
```

### Need to Update PR After Force Push

```bash
# After rebasing or amending
git push origin feature-branch --force-with-lease

# --force-with-lease is safer than --force
# It prevents overwriting others' work
```

## Best Practices

### DO:
✅ Commit often with meaningful messages  
✅ Keep commits focused and atomic  
✅ Write descriptive commit messages  
✅ Pull/rebase before pushing  
✅ Review your own changes before creating PR  
✅ Keep PRs small and focused  
✅ Respond to review comments promptly  
✅ Delete branches after merging  

### DON'T:
❌ Commit directly to `main` or `develop`  
❌ Force push to shared branches  
❌ Commit large binary files  
❌ Commit secrets or credentials  
❌ Create huge PRs (>500 lines)  
❌ Ignore CI/CD failures  
❌ Leave unresolved merge conflicts  
❌ Use `git push --force` (use `--force-with-lease`)  

## Git Configuration

### Initial Setup

```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default editor
git config --global core.editor "code --wait"  # VS Code
# or
git config --global core.editor "vim"  # Vim

# Set default branch name
git config --global init.defaultBranch main

# Enable color output
git config --global color.ui auto

# Set up SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"
# Add to GitHub/GitLab settings
```

### Useful Aliases

```bash
# Add to ~/.gitconfig or run git config --global alias.<name> <command>

[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  unstage = reset HEAD --
  last = log -1 HEAD
  visual = log --oneline --graph --all --decorate
  amend = commit --amend --no-edit
  undo = reset --soft HEAD~1
```

## Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Best Practices](https://sethrobertson.github.io/GitBestPractices/)

---

**Last Updated:** [Date]  
**Maintained by:** Technical Lead  
**Questions?** Ask in #sharitek-chat-dev channel
