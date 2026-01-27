# Worktree Management Scripts

Shell scripts for managing git worktrees in Manifest Automations.

## Overview

Worktrees enable parallel development without merge conflicts. Each worktree is an independent working directory sharing the same git history. These scripts implement the "sibling naming pattern" where worktrees live alongside the main repo.

## Scripts

### worktree-create.sh

Create a new worktree with a fresh branch.

```bash
./scripts/worktree-create.sh <branch-name> [base-branch]

# Examples:
./scripts/worktree-create.sh feature-auth        # Based on main
./scripts/worktree-create.sh feature-auth develop # Based on develop
```

Creates: `../<repo-name>-<branch-name>/`

### worktree-list.sh

List all active worktrees with their status.

```bash
./scripts/worktree-list.sh           # Human-readable
./scripts/worktree-list.sh --porcelain # Machine-readable
```

### worktree-remove.sh

Remove a worktree and optionally its branch.

```bash
./scripts/worktree-remove.sh <branch-name> [options]

# Options:
#   --force        Remove even with uncommitted changes
#   --keep-branch  Don't delete the branch

# Examples:
./scripts/worktree-remove.sh feature-auth
./scripts/worktree-remove.sh feature-auth --force
./scripts/worktree-remove.sh feature-auth --keep-branch
```

### worktree-cleanup.sh

Clean up stale worktrees based on inactivity.

```bash
./scripts/worktree-cleanup.sh [options]

# Options:
#   --dry-run     Show what would be cleaned up
#   --days=N      Inactivity threshold (default: 7)

# Examples:
./scripts/worktree-cleanup.sh --dry-run
./scripts/worktree-cleanup.sh --days=14
```

## Naming Convention

Worktrees use the **sibling naming pattern**:

```
/path/to/
├── manifest-automations/           # Main repo
├── manifest-automations-feature-a/ # Worktree for feature-a branch
├── manifest-automations-bugfix-42/ # Worktree for bugfix-42 branch
└── manifest-automations-experiment/ # Worktree for experiment branch
```

Benefits:
- Quick visibility: `ls ..` shows all active work
- Easy cleanup: delete directory without affecting repo
- No path confusion: worktrees are never nested inside main repo

## Workflow

### Typical Development Cycle

1. **Create** worktree for new feature:
   ```bash
   ./scripts/worktree-create.sh feature-auth
   cd ../manifest-automations-feature-auth
   ```

2. **Work** in the worktree:
   ```bash
   # Make changes, commit, push
   git add .
   git commit -m "feat: add auth module"
   git push -u origin feature-auth
   ```

3. **Create PR** and merge

4. **Remove** worktree after merge:
   ```bash
   cd ../manifest-automations
   ./scripts/worktree-remove.sh feature-auth
   ```

### Cleanup Stale Worktrees

```bash
# Check what's stale (dry run)
./scripts/worktree-cleanup.sh --dry-run

# Prune administrative files for deleted directories
./scripts/worktree-cleanup.sh
```

## Integration with Orchestrator

These scripts are designed to be called by the orchestrator agent for automated worktree management:

- **On task assignment**: Orchestrator calls `worktree-create.sh`
- **On PR merge**: Orchestrator calls `worktree-remove.sh`
- **On scheduled cleanup**: Orchestrator calls `worktree-cleanup.sh`

## Troubleshooting

**"Branch already exists"**: Use a different branch name or delete the existing branch first.

**"Worktree has uncommitted changes"**: Commit, stash, or use `--force` to discard changes.

**"Worktree not found"**: Run `./scripts/worktree-list.sh` to see available worktrees.

## References

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Phase 01 Research](.planning/phases/01-foundation/01-RESEARCH.md)
