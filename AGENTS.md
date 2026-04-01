# Agentic Framework - Agent Guide

This document helps agents work effectively in the agentic-framework repository.

## Repository Overview

This repository contains skills, tools, and installation scripts for AI coding assistants (OpenCode, Claude Code, Gemini, Cursor, Pi). It's not a traditional application codebase but a framework for enhancing AI assistant capabilities.

## Directory Structure

```
agentic-framework/
├── scripts/                 # Installation and verification scripts
│   ├── install.sh          # Multi-platform installer
│   └── verify.sh           # Installation verifier
├── platforms/              # Platform-specific setup guides
│   ├── claude-code/        # Claude Code setup
│   ├── gemini/             # Gemini setup
│   └── pi/                 # Pi setup
├── tools/                  # TypeScript tools (OpenCode only)
│   ├── gsr.ts              # Global Search & Replace
│   ├── figma-rest.ts       # Figma REST API
│   └── figma-oauth.ts      # Figma OAuth
├── skills/                 # Universal skills for all platforms
│   ├── figma-interaction/
│   ├── jira/
│   ├── confluence/
│   ├── github/
│   ├── planning-with-files/
│   ├── aws/
│   ├── context-compactor/
│   ├── code-review/
│   ├── test-driven-development/
│   ├── playwright-browser-automation/
│   ├── webapp-testing/
│   ├── mcp-builder/
│   ├── postgres/
│   ├── root-cause-tracing/
│   ├── threat-hunting-sigma/
│   ├── git-pushing/
│   ├── review-implementing/
│   └── test-fixing/
├── README.md               # Main documentation
├── INSTALL.md              # Detailed installation guide
├── PLATFORMS.md            # Platform comparison
└── opencode.json           # OpenCode configuration
```

## Essential Commands

### Installation
```bash
# Full installation (auto-detects platform)
./scripts/install.sh

# Verify installation
./scripts/verify.sh
```

### Platform-Specific Usage

#### OpenCode
```bash
opencode run "<task description>"
# Example: opencode run "Get design tokens from Figma file ABC123"
```

#### Claude Code
```bash
claude "<task description>"
# Example: claude "Get design tokens from Figma file ABC123"
```

#### Gemini
```bash
gemini "<task description>"
# Example: gemini "Get design tokens from Figma file ABC123"
```

#### Cursor
Use Cursor's agent chat interface with natural language requests.

#### Pi
```bash
pi -p "<task description>"
# Example: pi -p "Get design tokens from Figma file ABC123"
```

### GitHub PR Workflow (via github skill)
All platforms support GitHub operations through the github skill:
```bash
# Create PR
gh pr create --title "Title" --body "Description"

# Check PR status
gh pr view PR_NUMBER

# Get review comments
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments

# Resolve review threads
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "THREAD_ID"}) { thread { id isResolved } } }'

# Merge PR
gh pr merge PR_NUMBER --squash
```

## Code Organization & Patterns

### Skills Structure
Each skill in `.opencode/skills/` follows this pattern:
- `SKILL.md` - Main skill documentation
- Platform-specific variants may exist in `platforms/` directories

### Skill portability (all agents)
Skills in `skills/` are written for **any** supported assistant (OpenCode, Claude Code, Gemini CLI, Cursor, Pi). They describe **what to do**, not a single product’s tool IDs.

- **Paths:** Commands that reference `skills/...` assume the **git workspace root** (this repo) or the path where `install.sh` copied the skill (e.g. under `~/.claude/skills/`, `~/.cursor/skills/`, `~/.config/opencode/skills/`). Adjust the prefix to match your install location.
- **Tasks / todos:** Use whatever task-tracking the host provides (built-in todo list, plan mode, or a checklist in your notes file).
- **Edits and search:** Use the host’s normal code search and apply-edit capabilities (names differ per product).
- **Project rules:** Prefer each repo’s convention files — typically `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, or project docs — not a single fixed filename.

### Tools (OpenCode Only)
TypeScript tools in `.opencode/tools/`:
- `gsr.ts` - Global Search & Replace with preview/dry-run capabilities
- `figma-rest.ts` - Figma REST API interactions
- `figma-oauth.ts` - Figma OAuth token management

### Scripts
- `install.sh` - Detects platform and installs appropriate components
- `verify.sh` - Validates installation for each platform

## Testing Approach

This repository doesn't contain traditional application code with tests. Instead:

### Skill Validation
Skills are validated through:
1. Installation verification (`./scripts/verify.sh`)
2. Functional testing via AI assistant platforms
3. Manual verification of skill capabilities

### TDD Skill
The repository includes a `test-driven-development` skill that provides:
- Red-green-refactor workflow guidance and strict test-first discipline (failing test before production code)
- Framework detection for various languages
- Test patterns and conventions
- Mocking and anti-pattern guidance
- Test quality principles (40/60 rule, mutation testing)

### Playwright vs webapp testing
- `playwright-browser-automation` — Node `@playwright/test` projects, CI-oriented E2E.
- `webapp-testing` — Python Playwright scripts plus `with_server.py` for local dev servers and quick verification.

When working with actual code using this framework, agents should:
1. Discover test setup using framework detection patterns
2. Establish a green baseline by running existing tests
3. Follow red-green-refactor cycle for new features
4. Write tests before implementation
5. Focus on meaningful assertions and edge cases

## Important Gotchas & Non-Obvious Patterns

### Platform Detection
The install and verify scripts auto-detect platforms by checking:
- Environment variables (`OPENCODE_CONFIG`)
- Command existence (`claude`, `gemini`, `cursor`, `pi`)
- Directory presence (`~/.config/opencode`, `~/.claude`, etc.)

### Skill Installation Variations
Different platforms receive different skill installations:
- **OpenCode**: Gets TypeScript tools + all skills
- **Claude Code**: Gets skills + optional MCP setup guidance
- **Gemini**: Gets skills + shell script versions of tools
- **Cursor**: Gets skills + MCP/plugin setup guidance
- **Pi**: Gets skills as capability packages (no MCP support)

### Environment Variables
Required for full functionality:
- `FIGMA_PERSONAL_TOKEN` - For Figma API access
- `ATLASSIAN_API_TOKEN` + `ATLASSIAN_EMAIL` + `ATLASSIAN_SITE` - For JIRA/Confluence

### Tool Availability
- TypeScript tools (`gsr.ts`, `figma-rest.ts`, `figma-oauth.ts`) are **OpenCode only**
- Other platforms receive shell script adaptations or rely on MCP/plugins
- Gemini gets `gsr.sh` as a shell script alternative

### Permission Model
OpenCode installation includes auto-approve permissions config for seamless operation.

### Context Management
Includes a `context-compactor` skill for managing context window limitations with:
- Three-tier memory model (hot/warm/cold)
- Proactive offloading and filesystem-backed state
- Pre-compaction checkpointing and post-compaction recovery

## Getting Started

1. Run `./scripts/install.sh` to install for your platform
2. Set required environment variables (Figma, JIRA/Confluence tokens)
3. Reload shell or restart your AI assistant platform
4. Verify installation with `./scripts/verify.sh`
5. Begin using platform-specific commands to leverage skills

## Finding More Information

- `README.md` - High-level overview
- `INSTALL.md` - Detailed installation instructions
- `PLATFORMS.md` - Platform-specific feature comparison
- Individual skill directories (`SKILL.md` files) - Detailed usage guides
- Platform READMEs in `platforms/` - Setup specifics
