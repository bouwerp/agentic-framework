---
name: jira-interaction
description: This skill should be used when the user asks to "update JIRA issue", "view JIRA ticket", "add JIRA comment", "modify JIRA description", or works with JIRA API and Atlassian Document Format (ADF). Provides guidance on JIRA REST API interactions using ADF format.
version: 1.0.0
---

# JIRA Issue Interaction

This skill provides guidance on interacting with JIRA issues via the REST API using Atlassian Document Format (ADF).

## Overview

Use this skill when:
- Updating JIRA issue descriptions with rich formatting
- Viewing JIRA issue details
- Adding comments to JIRA issues
- Working with JIRA REST API and ADF format

## Authentication Setup

### Priority Order for Credentials

1. **Environment Variables** (highest priority - use if available)
   - `ATLASSIAN_API_TOKEN` (primary, works for both JIRA and Confluence)
   - `ATLASSIAN_EMAIL`
   - `ATLASSIAN_SITE` (e.g., `your-domain.atlassian.net`)
   - Legacy: `JIRA_API_TOKEN`, `JIRA_EMAIL`, `JIRA_SITE`

2. **ACLI Config File** (medium priority - decode if env vars not set)
   - Located at `~/.config/acli/jira_config.yaml`
   - Extract email and site from config
   - For OAuth tokens, check `~/.config/acli/oauth_tokens.yaml`

3. **Ask User Directly** (fallback - if neither env nor config available)
   - Request API token from user
   - Token URL: https://id.atlassian.com/manage-profile/security/api-tokens

### Checking Environment Variables

```bash
# Check if env vars are available (ATLASSIAN_* is primary, JIRA_* for backward compat)
if [ -n "$ATLASSIAN_API_TOKEN" ]; then
  API_TOKEN="$ATLASSIAN_API_TOKEN"
  EMAIL="${ATLASSIAN_EMAIL:-$JIRA_EMAIL}"
  SITE="${ATLASSIAN_SITE:-$JIRA_SITE:-$JIRA_DOMAIN}"
elif [ -n "$JIRA_API_TOKEN" ]; then
  API_TOKEN="$JIRA_API_TOKEN"
  EMAIL="${JIRA_EMAIL:-$ATLASSIAN_EMAIL}"
  SITE="${JIRA_SITE:-$ATLASSIAN_SITE:-$JIRA_DOMAIN}"
fi
```

### Decoding from ACLI Config

```bash
# Parse ACLI config for JIRA
ACLI_CONFIG="$HOME/.config/acli/jira_config.yaml"

if [ -f "$ACLI_CONFIG" ]; then
  # Extract email and site from config
  EMAIL=$(grep 'email:' "$ACLI_CONFIG" | head -1 | sed 's/.*email: //')
  SITE=$(grep 'site:' "$ACLI_CONFIG" | head -1 | sed 's/.*site: //')
  
  # For OAuth tokens, check oauth_tokens.yaml
  OAUTH_CONFIG="$HOME/.config/acli/oauth_tokens.yaml"
  if [ -f "$OAUTH_CONFIG" ]; then
    # Extract access token
    ACCESS_TOKEN=$(grep 'access_token:' "$OAUTH_CONFIG" | head -1 | sed 's/.*access_token: //')
    if [ -n "$ACCESS_TOKEN" ]; then
      API_TOKEN="$ACCESS_TOKEN"
    fi
  fi
fi
```

### Asking User for API Token (Fallback)

If environment variables and ACLI config are not available, ask the user:

```
The JIRA API requires authentication. Could you please provide your JIRA API token?
You can generate one at: https://id.atlassian.com/manage-profile/security/api-tokens
```

If the user provides a token, use it for JIRA operations. If the token fails, ask for a fresh one.

### Constructing API Headers

```bash
# After user provides token
JIRA_SITE="your-domain.atlassian.net"
EMAIL="your-email@example.com"
API_TOKEN="user-provided-token"

# Test the connection
curl -u "$EMAIL:$API_TOKEN" \
  "https://$JIRA_SITE/rest/api/3/myself" \
  -H "Accept: application/json"
```

## Atlassian Document Format (ADF)

ADF is a JSON-based format for rich content in JIRA.

### Basic ADF Structure

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "Your text here"
        }
      ]
    }
  ]
}
```

### Common ADF Elements

#### Paragraph with Formatting

```json
{
  "type": "paragraph",
  "content": [
    {
      "type": "text",
      "text": "Bold text",
      "marks": [{"type": "strong"}]
    },
    {
      "type": "text",
      "text": " and "
    },
    {
      "type": "text",
      "text": "italic text",
      "marks": [{"type": "em"}]
    }
  ]
}
```

#### Code Block

```json
{
  "type": "codeBlock",
  "attrs": {"language": "python"},
  "content": [
    {
      "type": "text",
      "text": "def hello():\n    print('Hello World')"
    }
  ]
}
```

#### Bullet List

```json
{
  "type": "bulletList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "Item 1"}]
        }
      ]
    },
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "Item 2"}]
        }
      ]
    }
  ]
}
```

#### Heading

```json
{
  "type": "heading",
  "attrs": {"level": 2},
  "content": [{"type": "text", "text": "Section Title"}]
}
```

#### Link

```json
{
  "type": "text",
  "text": "Click here",
  "marks": [
    {
      "type": "link",
      "attrs": {"href": "https://example.com"}
    }
  ]
}
```

## API Operations

### 1. View JIRA Issue

```bash
JIRA_SITE="your-domain.atlassian.net"
ISSUE_KEY="PROJ-123"
EMAIL="your-email@example.com"
API_TOKEN="your-api-token"

curl -u "$EMAIL:$API_TOKEN" \
  "https://$JIRA_SITE/rest/api/3/issue/$ISSUE_KEY" \
  -H "Accept: application/json" | jq .
```

**Fields to extract:**
- `fields.summary` - Issue title
- `fields.description` - Issue description (ADF format)
- `fields.status.name` - Current status
- `fields.assignee.displayName` - Assigned user
- `fields.reporter.displayName` - Reporter

### 2. Update JIRA Issue Description

```bash
JIRA_SITE="your-domain.atlassian.net"
ISSUE_KEY="PROJ-123"
EMAIL="your-email@example.com"
API_TOKEN="your-api-token"

# Create ADF JSON
ADF_JSON='{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [
        {"type": "text", "text": "Updated description"}
      ]
    }
  ]
}'

# Update description
curl -u "$EMAIL:$API_TOKEN" \
  -X PUT \
  "https://$JIRA_SITE/rest/api/3/issue/$ISSUE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"fields\": {
      \"description\": $ADF_JSON
    }
  }"
```

### 3. Add Comment to JIRA Issue

```bash
JIRA_SITE="your-domain.atlassian.net"
ISSUE_KEY="PROJ-123"
EMAIL="your-email@example.com"
API_TOKEN="your-api-token"

# Simple text comment (plain)
curl -u "$EMAIL:$API_TOKEN" \
  -X POST \
  "https://$JIRA_SITE/rest/api/3/issue/$ISSUE_KEY/comment" \
  -H "Content-Type: application/json" \
  -d '{
    "body": {
      "version": 1,
      "type": "doc",
      "content": [
        {
          "type": "paragraph",
          "content": [
            {"type": "text", "text": "This is a comment"}
          ]
        }
      ]
    }
  }'
```

## Complete Example: Update Issue with Rich Description

```bash
#!/bin/bash

# Configuration
JIRA_SITE="realfi.atlassian.net"
ISSUE_KEY="PROJ-123"
EMAIL="your.email@company.io"

# Decode token from ~/.config/acli/jira_config.yaml
TOKEN_B64="<base64-encoded-token>"
API_TOKEN=$(echo "$TOKEN_B64" | base64 -d)

# Build ADF description
read -r -d '' ADF_DESCRIPTION << 'EOF'
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": {"level": 2},
      "content": [{"type": "text", "text": "Summary"}]
    },
    {
      "type": "paragraph",
      "content": [
        {"type": "text", "text": "This issue tracks the implementation of the new feature."}
      ]
    },
    {
      "type": "heading",
      "attrs": {"level": 2},
      "content": [{"type": "text", "text": "Acceptance Criteria"}]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{"type": "text", "text": "Feature must support X"}]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{"type": "text", "text": "Feature must handle Y"}]
            }
          ]
        }
      ]
    }
  ]
}
EOF

# Update the issue
curl -u "$EMAIL:$API_TOKEN" \
  -X PUT \
  "https://$JIRA_SITE/rest/api/3/issue/$ISSUE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"fields\": {
      \"description\": $ADF_DESCRIPTION
    }
  }"

echo "Issue $ISSUE_KEY updated successfully"
```

## Common Errors and Solutions

### Error: 401 Unauthorized

**Cause:** Invalid or expired API token

**Solution:**
1. **Ask the user for a fresh API token** - do NOT attempt to reuse stored/config tokens
2. Verify email matches the account
3. The user can generate a new token at: https://id.atlassian.com/manage-profile/security/api-tokens

### Error: 403 Forbidden

**Cause:** Insufficient permissions

**Solution:**
1. Verify user has edit permissions on the issue
2. Check project permissions in JIRA admin
3. Confirm API token has required scopes

### Error: 400 Bad Request - Invalid ADF

**Cause:** Malformed ADF JSON structure

**Solution:**
1. Validate JSON syntax
2. Ensure all ADF nodes have required `type` field
3. Check `version` is set to 1
4. Verify root element is `type: "doc"`

### Error: 404 Not Found

**Cause:** Issue key doesn't exist or wrong JIRA site

**Solution:**
1. Verify issue key (e.g., PROJ-123)
2. Check JIRA site domain is correct
3. Confirm issue hasn't been deleted

### Error: 415 Unsupported Media Type

**Cause:** Missing or incorrect Content-Type header

**Solution:**
```bash
-H "Content-Type: application/json"
```

## Best Practices

1. **Always ask the user for API token** - never rely on config files that may be corrupted or expired
2. **Validate ADF JSON** before sending - use `jq .` to check syntax
3. **Store credentials securely** - never commit API tokens to version control
4. **Test with GET first** to verify connectivity and permissions
5. **Keep descriptions focused** - ADF supports nesting but deep structures can be hard to read
6. **Handle encoding** - properly escape ADF JSON when embedding in shell commands
7. **If token fails, ask for a new one** - don't try to fix or decode stored tokens

## Syncing to Other AI Tools

This skill should be synced to other AI assistant tools (Claude Code, Gemini, Codex, etc.) using the skill-manager skill. The key update is:

- **Always ask the user for API token** instead of relying on config files
- The prompt for the user should include the URL to generate tokens

### Syncing Command

```bash
# Using skill-manager to sync to all tools
./scripts/sync-skills.sh --source ~/.config/opencode/skills/jira-interaction
```

## References

- [JIRA REST API Documentation](https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/)
- [Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
- [ADF Builder](https://developer.atlassian.com/cloud/jira/platform/apis/document/playground/)
