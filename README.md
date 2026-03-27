# AI Assistant Skills & Tools

A collection of universal skills and tools for AI coding assistants (OpenCode, Claude Code, Gemini, Cursor, Pi).

## What's Included

### Skills (9)
Universal skills that work across all platforms:

- **`figma-interaction/`** - Figma integration via MCP or REST API
  - Generate code from Figma designs
  - Extract design tokens (colors, spacing, typography)
  - Create design system documentation
  - Supports OAuth and Personal Access Tokens

- **`jira/`** - JIRA integration with ADF support
  - View and update JIRA issues
  - Work with Atlassian Document Format
  - OAuth and PAT authentication

- **`confluence/`** - Confluence integration with ADF support
  - Read/write Confluence pages
  - Search documentation
  - Summarize content
  - OAuth and PAT authentication

- **`github/`** - GitHub PR workflow via `gh` CLI
  - Create and update pull requests
  - Get review comments and unresolved threads
  - Resolve review threads (single and batch)
  - Check CI/CD status and read check logs
  - Full review cycle management

- **`planning-with-files/`** - Persistent file-based planning methodology
  - Three-file system: task_plan.md, findings.md, progress.md
  - Structured phases with dependency tracking
  - Session recovery from context resets
  - Hierarchical plans for large tasks
  - Git checkpoint integration

- **`aws/`** - AWS CLI interaction with safety-first patterns
  - Read-first, confirm-before-mutating approach
  - 16 service references: S3, EC2, Lambda, ECS, CloudFormation, IAM, CloudWatch, RDS, DynamoDB, SQS/SNS, Secrets Manager, SSM, ECR, Route53, Step Functions, Cost Explorer
  - Command safety classification (safe/dangerous/destructive)
  - JMESPath query patterns, pagination, waiters
  - Credential management and cost awareness

- **`context-compactor/`** - Context window management and compaction
  - Three-tier memory model: hot (context), warm (files), cold (git)
  - Proactive offloading and filesystem-backed state
  - Pre-compaction checkpointing and post-compaction recovery
  - Anti-patterns that waste context tokens
  - Platform-specific compaction commands and hooks

- **`code-review/`** - Post-implementation code review and simplification
  - Three-pass review: reuse, simplicity, security/performance
  - AI-generated code smell detection (over-engineering, cargo cult, hallucinated APIs)
  - Language-specific checks: TypeScript, Python, Go, Rust, Java
  - OWASP-aligned security checklist
  - Test quality assessment

- **`test-driven-development/`** - TDD workflow and testing patterns
  - Red-green-refactor cycle with framework detection
  - Test commands for Jest, Vitest, pytest, Go, Cargo, JUnit, RSpec, PHPUnit
  - Edge case strategies, parameterized tests, mocking guidance
  - Bug-to-regression-test workflow
  - Test quality: assertion verification, mutation testing, the 40/60 rule

### Tools (3)
Custom TypeScript tools for OpenCode:

- **`gsr.ts`** - Global Search & Replace
  - Large-scale code refactors
  - Regex support
  - Preview mode (dry-run)
  - File pattern filtering

- **`figma-rest.ts`** - Figma REST API
  - Get file structure
  - Extract design tokens
  - Get node details
  - Get screenshots

- **`figma-oauth.ts`** - Figma OAuth
  - Headless OAuth flow
  - Token management
  - Token refresh

## Installation

### Quick Install (Auto-detects platform)

```bash
git clone https://github.com/bouwerp/agentic-framework.git
cd agentic-framework
./scripts/install.sh
./scripts/verify.sh
```

### Platform-Specific Setup

#### OpenCode (Native Support)

Best for: Custom workflows, full control

```bash
./scripts/install.sh
```

Installs:
- All 9 skills
- All 3 TypeScript tools
- Auto-approve permissions config

#### Claude Code (Recommended)

Best for: Figma-heavy workflows, official plugin support

```bash
# Install official plugins
claude plugin install figma@claude-plugins-official
claude plugin install jira@claude-plugins-official
claude plugin install confluence@claude-plugins-official

# Or manual MCP setup
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp auth figma
```

#### Gemini

Best for: Multi-turn conversations, free tier

```bash
./scripts/install.sh
```

Note: Uses REST API approach (limited MCP support)

#### Cursor

Best for: IDE integration, VS Code users

```bash
./scripts/install.sh

# In Cursor chat:
/plugin-add figma
/plugin-add jira
```

#### Pi

Best for: Minimal, extensible terminal agent

```bash
# Install Pi first: npm install -g @mariozechner/pi-coding-agent
./scripts/install.sh
```

Note: Pi uses skills as capability packages, no MCP support. See https://shittycodingagent.ai

## Environment Setup

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Figma Personal Access Token
# Get from: https://www.figma.com/developers/api#access-tokens
export FIGMA_PERSONAL_TOKEN='figd_your-token'

# Atlassian API Token (for JIRA/Confluence)
# Get from: https://id.atlassian.com/manage-profile/security/api-tokens
export ATLASSIAN_API_TOKEN='your-token'
export ATLASSIAN_EMAIL='your.email@example.com'
export ATLASSIAN_SITE='your-domain.atlassian.net'
```

## Usage Examples

### Figma Skills

```bash
# OpenCode
opencode run "Get design tokens from this Figma: https://www.figma.com/file/ABC123"

# Claude Code
claude "Extract colors and spacing from this Figma design: <url>"

# Gemini
gemini --system="You are a designer" "Get variables from Figma file ABC123"

# Pi
pi -p "Get design tokens from this Figma: https://www.figma.com/file/ABC123"
```

### GSR Tool (OpenCode only)

```bash
# Preview changes
opencode run "Rename getUser to fetchUser with dryRun: true"

# Apply changes
opencode run "Rename getUser to fetchUser across all .ts files"
```

### JIRA Skills

```bash
opencode run "Get details for JIRA issue PROJ-123"
claude "Update JIRA ticket PROJ-456 with status 'In Progress'"
```

### GitHub Skills

```bash
opencode run "Get unresolved review comments on PR #42"
claude "Check CI status and fix failing tests on PR #42"
pi -p "Resolve all review threads on PR #42 and post a summary"
```

## Platform Comparison

| Feature | OpenCode | Claude Code | Gemini | Cursor | Pi |
|---------|----------|-------------|---------|--------|-----|
| **Skills** | ✅ All 9 | ✅ All 9 | ✅ All 9 | ✅ All 9 | ✅ All 9 |
| **Tools** | ✅ TypeScript | ❌ MCP only | ❌ Shell scripts | ❌ MCP only | ❌ CLI tools |
| **MCP** | ✅ Full | ✅ Full (best) | ⚠️ Limited | ✅ Full | ❌ None |
| **Figma** | REST + OAuth | Official MCP | REST API | MCP plugin | REST API |
| **JIRA** | REST + ADF | MCP plugin | REST API | MCP plugin | REST API |
| **Confluence** | REST + ADF | MCP plugin | REST API | MCP plugin | REST API |
| **GitHub** | `gh` CLI | `gh` CLI | `gh` CLI | `gh` CLI | `gh` CLI |

## Repository Structure

```
agentic-framework/
├── scripts/
│   ├── install.sh          # Multi-platform installer
│   └── verify.sh           # Installation verifier
├── platforms/
│   ├── claude-code/        # Claude-specific guide
│   ├── gemini/             # Gemini-specific guide
│   └── pi/                 # Pi-specific guide
├── .opencode/
│   ├── tools/              # TypeScript tools (OpenCode only)
│   │   ├── gsr.ts
│   │   ├── figma-rest.ts
│   │   └── figma-oauth.ts
│   └── skills/             # Universal skills
│       ├── figma-interaction/
│       ├── jira/
│       ├── confluence/
│       ├── github/
│       ├── planning-with-files/
│       ├── aws/
│       ├── context-compactor/
│       ├── code-review/
│       └── test-driven-development/
├── README.md               # This file
├── INSTALL.md              # Detailed installation guide
├── PLATFORMS.md            # Platform comparison
└── opencode.json           # OpenCode configuration
```

## Documentation

- **[INSTALL.md](INSTALL.md)** - Complete installation guide
- **[PLATFORMS.md](PLATFORMS.md)** - Platform-specific details
- **`platforms/claude-code/README.md`** - Claude Code setup
- **`platforms/gemini/README.md`** - Gemini setup
- **`platforms/pi/README.md`** - Pi setup

## License

MIT
