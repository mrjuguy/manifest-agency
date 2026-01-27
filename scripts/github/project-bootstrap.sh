#!/bin/bash
# scripts/github/project-bootstrap.sh
# Idempotent GitHub Project setup for Manifest Automations
#
# Creates GitHub Project with custom fields for agent coordination.
# Safe to run multiple times - checks for existing resources before creating.

set -e

# Configuration
PROJECT_TITLE="Manifest Automations"
CACHE_FILE=".cache/github/project-fields.json"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "GitHub Project Bootstrap"
echo "=========================================="
echo ""

# Ensure cache directory exists
mkdir -p "$(dirname "$CACHE_FILE")"

# Get authenticated user login
echo "Fetching authenticated user..."
OWNER=$(gh api user -q '.login')
echo -e "${GREEN}✓${NC} Authenticated as: $OWNER"
echo ""

# Check for existing project
echo "Checking for existing project '$PROJECT_TITLE'..."
EXISTING_PROJECT=$(gh api graphql -f query='
  query($owner: String!) {
    user(login: $owner) {
      projectsV2(first: 20, query: "Manifest Automations") {
        nodes {
          id
          number
          title
        }
      }
    }
  }' -f owner="$OWNER" 2>/dev/null || echo '{"data":{"user":{"projectsV2":{"nodes":[]}}}}')

PROJECT_ID=$(echo "$EXISTING_PROJECT" | jq -r '.data.user.projectsV2.nodes[] | select(.title=="'"$PROJECT_TITLE"'") | .id')
PROJECT_NUMBER=$(echo "$EXISTING_PROJECT" | jq -r '.data.user.projectsV2.nodes[] | select(.title=="'"$PROJECT_TITLE"'") | .number')

if [ -n "$PROJECT_ID" ] && [ "$PROJECT_ID" != "null" ]; then
  echo -e "${YELLOW}⚠${NC} Project already exists: #$PROJECT_NUMBER"
  echo "   Project ID: $PROJECT_ID"
else
  # Create project
  echo "Creating new project '$PROJECT_TITLE'..."
  CREATE_RESULT=$(gh api graphql -f query='
    mutation($ownerId: ID!, $title: String!) {
      createProjectV2(input: {ownerId: $ownerId, title: $title}) {
        projectV2 {
          id
          number
          title
        }
      }
    }' -f ownerId="$(gh api user -q '.node_id')" -f title="$PROJECT_TITLE")

  PROJECT_ID=$(echo "$CREATE_RESULT" | jq -r '.data.createProjectV2.projectV2.id')
  PROJECT_NUMBER=$(echo "$CREATE_RESULT" | jq -r '.data.createProjectV2.projectV2.number')

  echo -e "${GREEN}✓${NC} Project created: #$PROJECT_NUMBER"
  echo "   Project ID: $PROJECT_ID"
fi

echo ""

# Fetch existing fields
echo "Fetching project fields..."
FIELDS=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
        id
        fields(first: 50) {
          nodes {
            ... on ProjectV2Field {
              id
              name
              dataType
            }
            ... on ProjectV2SingleSelectField {
              id
              name
              dataType
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }' -f owner="$OWNER" -F number="$PROJECT_NUMBER")

# Save to cache
echo "$FIELDS" > "$CACHE_FILE"
echo -e "${GREEN}✓${NC} Fields cached to $CACHE_FILE"
echo ""

# Define custom fields to create
# Format: FIELD_NAME|FIELD_TYPE|OPTIONS (comma-separated)
CUSTOM_FIELDS=(
  "Status|SINGLE_SELECT|Backlog,Ready,Claimed,In Progress,In Review,Done"
  "Claimed By|TEXT|"
  "Priority|SINGLE_SELECT|P0-critical,P1-high,P2-medium,P3-low"
  "Complexity|SINGLE_SELECT|XS,S,M,L,XL"
  "Agent Type|SINGLE_SELECT|agent:any,agent:code-reviewer,agent:backend-developer,agent:frontend-developer,agent:architect"
  "Phase|SINGLE_SELECT|phase:1,phase:2,phase:3,phase:4,phase:5,phase:6,phase:7"
)

echo "Checking/creating custom fields..."
echo ""

for FIELD_DEF in "${CUSTOM_FIELDS[@]}"; do
  IFS='|' read -r FIELD_NAME FIELD_TYPE OPTIONS <<< "$FIELD_DEF"

  # Check if field already exists
  EXISTING_FIELD_ID=$(echo "$FIELDS" | jq -r --arg name "$FIELD_NAME" '.data.user.projectV2.fields.nodes[] | select(.name==$name) | .id')

  if [ -n "$EXISTING_FIELD_ID" ] && [ "$EXISTING_FIELD_ID" != "null" ]; then
    echo -e "${YELLOW}⚠${NC} Field already exists: $FIELD_NAME"
    echo "   Field ID: $EXISTING_FIELD_ID"
  else
    # Create field
    echo "Creating field: $FIELD_NAME ($FIELD_TYPE)"

    if [ "$FIELD_TYPE" = "TEXT" ]; then
      # Text field
      CREATE_FIELD_RESULT=$(gh api graphql -f query='
        mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!) {
          createProjectV2Field(input: {
            projectId: $projectId
            dataType: $dataType
            name: $name
          }) {
            projectV2Field {
              ... on ProjectV2Field {
                id
                name
              }
            }
          }
        }' -f projectId="$PROJECT_ID" -f name="$FIELD_NAME" -f dataType="$FIELD_TYPE")

      NEW_FIELD_ID=$(echo "$CREATE_FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.id')
      echo -e "${GREEN}✓${NC} Created text field: $FIELD_NAME"
      echo "   Field ID: $NEW_FIELD_ID"

    elif [ "$FIELD_TYPE" = "SINGLE_SELECT" ]; then
      # Single select field with options
      IFS=',' read -ra OPTION_ARRAY <<< "$OPTIONS"
      OPTIONS_JSON=$(printf '%s\n' "${OPTION_ARRAY[@]}" | jq -R . | jq -s 'map({name: ., color: "GRAY"})')

      CREATE_FIELD_RESULT=$(gh api graphql -f query='
        mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!, $options: [ProjectV2SingleSelectFieldOptionInput!]!) {
          createProjectV2Field(input: {
            projectId: $projectId
            dataType: $dataType
            name: $name
            singleSelectOptions: $options
          }) {
            projectV2Field {
              ... on ProjectV2SingleSelectField {
                id
                name
                options {
                  id
                  name
                }
              }
            }
          }
        }' -f projectId="$PROJECT_ID" -f name="$FIELD_NAME" -f dataType="$FIELD_TYPE" -f options="$OPTIONS_JSON")

      NEW_FIELD_ID=$(echo "$CREATE_FIELD_RESULT" | jq -r '.data.createProjectV2Field.projectV2Field.id')
      echo -e "${GREEN}✓${NC} Created single select field: $FIELD_NAME"
      echo "   Field ID: $NEW_FIELD_ID"
      echo "   Options: ${OPTION_ARRAY[@]}"
    fi
  fi

  echo ""
done

# Refresh fields cache after creation
echo "Refreshing fields cache..."
FIELDS=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
        id
        fields(first: 50) {
          nodes {
            ... on ProjectV2Field {
              id
              name
              dataType
            }
            ... on ProjectV2SingleSelectField {
              id
              name
              dataType
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }' -f owner="$OWNER" -F number="$PROJECT_NUMBER")

echo "$FIELDS" > "$CACHE_FILE"
echo -e "${GREEN}✓${NC} Fields cache updated"
echo ""

# Summary
echo "=========================================="
echo "Bootstrap Complete"
echo "=========================================="
echo ""
echo "Project: $PROJECT_TITLE (#$PROJECT_NUMBER)"
echo "URL: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER"
echo ""
echo "Custom fields:"
for FIELD_DEF in "${CUSTOM_FIELDS[@]}"; do
  IFS='|' read -r FIELD_NAME FIELD_TYPE OPTIONS <<< "$FIELD_DEF"
  FIELD_ID=$(echo "$FIELDS" | jq -r --arg name "$FIELD_NAME" '.data.user.projectV2.fields.nodes[] | select(.name==$name) | .id')
  if [ -n "$FIELD_ID" ] && [ "$FIELD_ID" != "null" ]; then
    echo "  - $FIELD_NAME ($FIELD_TYPE)"
  fi
done
echo ""
echo "Cache: $CACHE_FILE"
echo ""
echo -e "${GREEN}✓${NC} Project ready for agent coordination!"
