# GitHub Coordination Scripts

Scripts for managing GitHub Projects v2 as the authoritative coordination layer for multi-agent orchestration.

## Overview

These scripts use the GitHub CLI (`gh`) and GraphQL API to:
- Create and configure GitHub Projects with custom fields
- Manage issue lifecycle (claim, status updates, linking)
- Track agent metadata and work state
- Provide programmatic access to project data

## Prerequisites

- **gh CLI**: v2.86.0 or higher ([install](https://cli.github.com/))
- **jq**: v1.7+ for JSON parsing ([install](https://jqlang.github.io/jq/download/))
- **Authentication**: GitHub token with `repo` and `read:project` scopes

Verify installation:
```bash
gh --version  # Should be >= 2.86.0
jq --version  # Should be >= 1.7
gh auth status  # Verify token scopes
```

## Scripts

### project-bootstrap.sh

**Purpose:** Create and configure GitHub Project with custom fields for agent coordination.

**Features:**
- Idempotent - safe to run multiple times
- Creates project "Manifest Automations" if missing
- Adds 6 custom fields: Status, Claimed By, Priority, Complexity, Agent Type, Phase
- Caches field IDs to `.cache/github/project-fields.json` for subsequent scripts

**Usage:**
```bash
bash scripts/github/project-bootstrap.sh
```

**What it creates:**

1. **GitHub Project**: "Manifest Automations"
   - Located at: `https://github.com/users/YOUR_USERNAME/projects/N`
   - Type: Projects v2 (not Classic)

2. **Custom Fields**:
   - **Status** (Single Select): Backlog, Ready, Claimed, In Progress, In Review, Done
   - **Claimed By** (Text): Agent identifier (e.g., "backend-developer")
   - **Priority** (Single Select): P0-critical, P1-high, P2-medium, P3-low
   - **Complexity** (Single Select): XS, S, M, L, XL
   - **Agent Type** (Single Select): agent:any, agent:code-reviewer, agent:backend-developer, agent:frontend-developer, agent:architect
   - **Phase** (Single Select): phase:1, phase:2, phase:3, phase:4, phase:5, phase:6, phase:7

3. **Cache File**: `.cache/github/project-fields.json`
   - Contains field IDs and option IDs for API calls
   - TTL: 1 hour (regenerate if older)

**Idempotency:**
- Checks for existing project before creating
- Checks for existing fields before creating
- Can be run multiple times without errors or duplicates

**Example output:**
```
==========================================
GitHub Project Bootstrap
==========================================

Fetching authenticated user...
✓ Authenticated as: your-username

Checking for existing project 'Manifest Automations'...
⚠ Project already exists: #1
   Project ID: PVT_abc123...

Fetching project fields...
✓ Fields cached to .cache/github/project-fields.json

Checking/creating custom fields...

⚠ Field already exists: Status
   Field ID: PVTF_abc...

✓ Created text field: Claimed By
   Field ID: PVTF_def...

...

==========================================
Bootstrap Complete
==========================================

Project: Manifest Automations (#1)
URL: https://github.com/users/your-username/projects/1

Custom fields:
  - Status (SINGLE_SELECT)
  - Claimed By (TEXT)
  - Priority (SINGLE_SELECT)
  - Complexity (SINGLE_SELECT)
  - Agent Type (SINGLE_SELECT)
  - Phase (SINGLE_SELECT)

Cache: .cache/github/project-fields.json

✓ Project ready for agent coordination!
```

## Cache Structure

The `.cache/github/project-fields.json` file contains:

```json
{
  "data": {
    "user": {
      "projectV2": {
        "id": "PVT_...",
        "fields": {
          "nodes": [
            {
              "id": "PVTF_...",
              "name": "Status",
              "dataType": "SINGLE_SELECT",
              "options": [
                {"id": "...", "name": "Backlog"},
                {"id": "...", "name": "Ready"},
                {"id": "...", "name": "Claimed"},
                {"id": "...", "name": "In Progress"},
                {"id": "...", "name": "In Review"},
                {"id": "...", "name": "Done"}
              ]
            },
            {
              "id": "PVTF_...",
              "name": "Claimed By",
              "dataType": "TEXT"
            }
          ]
        }
      }
    }
  }
}
```

**Usage in scripts:**
```bash
# Extract Status field ID
STATUS_FIELD_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .id' .cache/github/project-fields.json)

# Extract "Claimed" option ID
CLAIMED_OPTION_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .options[] | select(.name=="Claimed") | .id' .cache/github/project-fields.json)
```

## Troubleshooting

### "Resource not accessible by integration"

**Cause:** GitHub token missing required scopes.

**Fix:**
```bash
# Check current scopes
gh auth status

# Refresh token with correct scopes
gh auth refresh --scopes repo,read:project,workflow
```

### "jq: command not found"

**Cause:** jq not installed.

**Fix:**
```bash
# Windows (Chocolatey)
choco install jq

# Windows (Scoop)
scoop install jq

# Verify
jq --version
```

### "Project not found" after creation

**Cause:** User vs Organization project mismatch.

**Fix:** This script creates user projects. For organization projects, modify the GraphQL query to use `organization(login: $org)` instead of `user(login: $owner)`.

### Rate limit errors

**Cause:** Too many GraphQL API calls in short time.

**Fix:**
```bash
# Check rate limit
gh api rate_limit | jq '.resources.graphql'

# Wait for reset time, or use cache more aggressively
```

## Next Steps

After running `project-bootstrap.sh`:

1. **Verify in GitHub UI**:
   - Go to https://github.com/users/YOUR_USERNAME/projects
   - Click "Manifest Automations"
   - Settings → Fields → Verify all 6 custom fields exist

2. **Create Views** (currently manual - see issue tracker):
   - "All Work" (Board): Group by Status, sort by Priority
   - "Ready Queue" (Table): Filter Status=Ready, show Priority/Complexity/Agent Type
   - "By Phase" (Table): Group by Phase, show Status/Priority

3. **Add Issues to Project**:
   ```bash
   gh issue create --title "Test issue" --body "Test" --label "feature,P2-medium"
   gh issue edit 1 --add-project "Manifest Automations"
   ```

4. **Update Custom Fields** (requires GraphQL - future script):
   ```bash
   # Coming soon: scripts/github/issue-claim.sh
   # Coming soon: scripts/github/issue-update-status.sh
   ```

## References

- [GitHub Projects v2 API](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GraphQL Rate Limits](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api)
- Phase 02 Research: `.planning/phases/02-github-coordination/02-RESEARCH.md`
