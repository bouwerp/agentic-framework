---
name: github-interaction
description: This skill should be used when the user asks to "create a PR", "check PR status", "get review comments", "resolve PR threads", "check CI/CD", "fix PR feedback", or any GitHub workflow involving pull requests, reviews, and checks. Provides guidance on GitHub CLI (gh) usage for PR lifecycle management.
version: 1.0.0
---

# GitHub Pull Request Workflow

This skill provides guidance on working with GitHub pull requests via the `gh` CLI — creating PRs, handling reviews, resolving feedback, and monitoring checks.

## Overview

Use this skill when:
- Creating or updating pull requests
- Reading and addressing PR review comments
- Resolving review threads after fixing issues
- Checking CI/CD status and reading check logs
- Managing the full PR review cycle

## Prerequisites

### GitHub CLI

The `gh` CLI must be installed and authenticated:

```bash
# Check if authenticated
gh auth status

# Login if needed
gh auth login
```

### Repository Context

All commands assume you are inside a git repository. The `--repo OWNER/REPO` flag can be used to target a specific repository when outside one.

---

## Creating Pull Requests

### Basic PR Creation

```bash
# Create PR against default branch
gh pr create --title "Short descriptive title" --body "Description of changes"

# Create PR against a specific base branch
gh pr create --base develop --title "Title" --body "Description"

# Create draft PR
gh pr create --draft --title "WIP: Title" --body "Description"
```

### PR Body Best Practices

Use a structured body with a HEREDOC for correct formatting:

```bash
gh pr create --title "Add user authentication" --body "$(cat <<'EOF'
## Summary
- Add JWT-based authentication middleware
- Create login/logout endpoints
- Add session management

## Test plan
- [ ] Unit tests for auth middleware
- [ ] Integration tests for login flow
- [ ] Manual testing with expired tokens
EOF
)"
```

### Updating an Existing PR

```bash
# Update title
gh pr edit PR_NUMBER --title "New title"

# Update body
gh pr edit PR_NUMBER --body "New description"

# Add reviewers
gh pr edit PR_NUMBER --add-reviewer username1,username2

# Add labels
gh pr edit PR_NUMBER --add-label "bug,priority:high"
```

---

## Checking PR Status and CI/CD

### View PR Status

```bash
# Overview of a PR
gh pr view PR_NUMBER

# JSON output for programmatic use
gh pr view PR_NUMBER --json state,reviewDecision,statusCheckRollup,mergeable
```

### Check CI/CD Status

```bash
# List all checks and their status
gh pr checks PR_NUMBER

# Wait for checks to complete (blocks until done)
gh pr checks PR_NUMBER --watch

# Get check details as JSON
gh pr view PR_NUMBER --json statusCheckRollup --jq '.statusCheckRollup[] | {name: .name, status: .status, conclusion: .conclusion}'
```

### Reading Check Logs

When a check fails, retrieve the logs to understand what went wrong:

```bash
# List workflow runs for the PR's branch
gh run list --branch BRANCH_NAME --limit 5

# View a specific run
gh run view RUN_ID

# Download failed run logs
gh run view RUN_ID --log-failed

# Download full logs
gh run view RUN_ID --log
```

### Re-running Failed Checks

```bash
# Re-run all failed jobs in a workflow run
gh run rerun RUN_ID --failed

# Re-run a specific job
gh run rerun RUN_ID --job JOB_ID
```

---

## Getting Review Comments

### List All Review Comments

```bash
# Get all review comments on a PR via the REST API
gh api repos/OWNER/REPO/pulls/PR_NUMBER/reviews

# Get inline review comments (code-level feedback)
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments
```

### Get Review Threads with Resolution Status

Use GraphQL to get full thread details including resolution status and thread IDs:

```bash
gh api graphql -f query='
query {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 10) {
            nodes {
              author { login }
              body
              createdAt
            }
          }
        }
      }
    }
  }
}'
```

### Filter Unresolved Threads

Use `jq` to extract only unresolved threads:

```bash
gh api graphql -f query='
query {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          path
          line
          comments(first: 10) {
            nodes {
              author { login }
              body
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

---

## Resolving PR Review Feedback

Follow this workflow when addressing PR review comments.

### Step 1: Gather All Unresolved Feedback

First, retrieve all unresolved review threads to understand the full scope of required changes:

```bash
gh api graphql -f query='
query {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          path
          line
          comments(first: 10) {
            nodes {
              author { login }
              body
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

Note down:
- The **thread ID** (`id` field) for each unresolved thread
- The **file path** and **line number** where the comment applies
- The **comment body** describing what needs to change

### Step 2: Address Each Issue

For each unresolved review comment:

1. **Read the comment** carefully to understand the requested change
2. **Fix the code** — make the change in the relevant file at the indicated line
3. **Add or update tests** if the comment relates to correctness or coverage
4. **Verify everything passes** — run the test suite and any linters before committing

Commit fixes with clear messages referencing the feedback:

```bash
git add <changed-files>
git commit -m "Address review: <summary of fix>"
git push
```

### Step 3: Mark Threads as Resolved

After pushing fixes, resolve the corresponding review threads using the `resolveReviewThread` GraphQL mutation.

Resolve a single thread:

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "THREAD_ID_HERE"}) {
    thread {
      id
      isResolved
    }
  }
}'
```

Batch-resolve multiple threads in one request (up to 7-8 per batch):

```bash
gh api graphql -f query='
mutation {
  t1: resolveReviewThread(input: {threadId: "THREAD_ID_1"}) {
    thread { id isResolved }
  }
  t2: resolveReviewThread(input: {threadId: "THREAD_ID_2"}) {
    thread { id isResolved }
  }
  t3: resolveReviewThread(input: {threadId: "THREAD_ID_3"}) {
    thread { id isResolved }
  }
}'
```

### Step 4: Add a Summary Comment

Post a summary of all fixes to the PR so reviewers can see what was addressed at a glance:

```bash
gh pr comment PR_NUMBER --body "$(cat <<'EOF'
## Review feedback addressed

- **file.ts:42** — Fixed null check as suggested
- **utils.ts:18** — Renamed variable for clarity
- **test_auth.py** — Added missing edge case test

All threads resolved. Ready for re-review.
EOF
)"
```

### Step 5: Request Re-review

```bash
# Request re-review from the original reviewers
gh pr edit PR_NUMBER --add-reviewer reviewer-username
```

---

## Replying to Review Comments

### Reply to a Specific Review Comment

```bash
# Reply to an inline review comment by comment ID
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments/COMMENT_ID/replies \
  -f body="Fixed in the latest commit — changed X to Y as suggested."
```

### Add a General PR Comment

```bash
gh pr comment PR_NUMBER --body "Comment text here"
```

---

## Merging Pull Requests

### Merge When Ready

```bash
# Merge with default strategy
gh pr merge PR_NUMBER

# Squash merge (single commit)
gh pr merge PR_NUMBER --squash

# Rebase merge
gh pr merge PR_NUMBER --rebase

# Auto-merge when checks pass
gh pr merge PR_NUMBER --auto --squash
```

### Pre-merge Checklist

Before merging, verify:

```bash
# All checks passing
gh pr checks PR_NUMBER

# Review approved
gh pr view PR_NUMBER --json reviewDecision --jq '.reviewDecision'

# No merge conflicts
gh pr view PR_NUMBER --json mergeable --jq '.mergeable'
```

---

## Common Workflows

### Full Review Cycle

```bash
# 1. Create the PR
gh pr create --title "Feature: user auth" --body "Adds authentication"

# 2. Wait for checks
gh pr checks PR_NUMBER --watch

# 3. Get review feedback
gh api graphql -f query='...' # (see "Get Review Threads" above)

# 4. Fix issues, commit, push
git add . && git commit -m "Address review feedback" && git push

# 5. Resolve threads
gh api graphql -f query='mutation { resolveReviewThread(...) }'

# 6. Post summary
gh pr comment PR_NUMBER --body "All feedback addressed."

# 7. Merge
gh pr merge PR_NUMBER --squash
```

### Debugging a Failed Check

```bash
# 1. See which checks failed
gh pr checks PR_NUMBER

# 2. Find the run ID
gh run list --branch BRANCH_NAME --limit 5

# 3. Read the failed logs
gh run view RUN_ID --log-failed

# 4. Fix the issue, push
git add . && git commit -m "Fix CI: <what was wrong>" && git push

# 5. Watch checks pass
gh pr checks PR_NUMBER --watch
```

---

## Tips

- Always use `gh api graphql` for thread resolution — there is no REST API equivalent for `resolveReviewThread`
- Batch thread resolutions into groups of 7-8 to avoid request size limits
- Use `--jq` with `gh api` to filter JSON output directly
- Use `gh pr checks --watch` to block until CI completes instead of polling manually
- When fixing review feedback, commit each logical fix separately for reviewer clarity
- Always run tests locally before pushing fixes to avoid unnecessary CI churn
