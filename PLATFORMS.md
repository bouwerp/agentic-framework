# Multi-Platform Support

Universal skills and tools for 5 major AI coding platforms.

## Supported Platforms

| Platform | Installer Support | Verification | Status |
|----------|------------------|--------------|--------|
| **OpenCode** | ✅ Full | ✅ Full | Native |
| **Claude Code** | ✅ Full | ✅ Full | Recommended |
| **Gemini** | ✅ Full | ✅ Full | REST API |
| **Cursor** | ✅ Full | ✅ Full | Plugin-based |
| **Pi** | ✅ Full | ✅ Full | Skills-based |

## Quick Install

The installer auto-detects your platform:

```bash
./scripts/install.sh
```

Or specify platform explicitly:

```bash
# OpenCode
OPENCODE_CONFIG=~/.config/opencode ./scripts/install.sh

# Claude Code
claude plugin install figma@claude-plugins-official

# Gemini
export GEMINI_CONFIG=~/.gemini && ./scripts/install.sh

# Cursor
export CURSOR_CONFIG=~/.cursor && ./scripts/install.sh
```

## Platform-Specific Details

### OpenCode (Native Support)

**Best for**: Custom workflows, full control

**Installation**:
```bash
./scripts/install.sh
```

**Installs**:
- Tools: `gsr.ts`, `figma-rest.ts`, `figma-oauth.ts`
- Skills: all 8 universal skills
- Config: `opencode.json`

**Test**:
```bash
opencode run "Get design tokens from Figma file ABC123"
```

---

### Claude Code (Recommended)

**Best for**: Figma-heavy workflows, official plugin support

**Installation**:
```bash
# Run installer for skills
./scripts/install.sh

# Install official plugins (optional)
claude plugin install figma@claude-plugins-official
claude plugin install jira@claude-plugins-official
claude plugin install confluence@claude-plugins-official

# Or manual MCP setup
claude mcp add --transport http figma https://mcp.figma.com/mcp
claude mcp auth figma
```

**Installs**:
- Skills: all 8 universal skills
- MCP: Figma, JIRA, Confluence servers (optional)

**Test**:
```bash
claude "Extract colors and spacing from this Figma design: <url>"
```

---

### Gemini

**Best for**: Multi-turn conversations, free tier

**Installation**:
```bash
./scripts/install.sh
```

**Installs**:
- Skills: all 8 universal skills
- Tools: Shell scripts (`gsr.sh`)

**Note**: Gemini has limited MCP support, uses REST API approach.

**Test**:
```bash
gemini "Get design tokens from Figma file ABC123"
```

---

### Cursor

**Best for**: IDE integration, VS Code users

**Installation**:
```bash
./scripts/install.sh

# In Cursor chat:
/plugin-add figma
/plugin-add jira
```

**Installs**:
- Skills: all 8 universal skills
- MCP: Manual configuration via GUI

**Test**:
```
Open Cursor agent chat
Type: "Get design tokens from Figma file ABC123"
```

---

### Pi

**Best for**: Minimal, extensible terminal agent

**Website**: https://shittycodingagent.ai

**Installation**:
```bash
# Install Pi first
npm install -g @mariozechner/pi-coding-agent

# Run installer for skills
./scripts/install.sh
```

**Installs**:
- Skills: all 8 universal skills

**Note**: Pi deliberately omits MCP support. Skills are capability packages with instructions and CLI tool definitions. Pi emphasizes "primitives, not features" — extensions and skills are the primary extensibility mechanism.

**Test**:
```bash
pi -p "Get design tokens from Figma file ABC123"
```

---

## Verification

After installation, verify your setup:

```bash
./scripts/verify.sh
```

This checks:
- ✓ Platform detected
- ✓ All components installed
- ✓ Environment variables set
- ✓ Configuration valid

## Environment Setup

All platforms require these environment variables:

```bash
# ~/.zshrc or ~/.bashrc
export FIGMA_PERSONAL_TOKEN='figd_your-token'
export ATLASSIAN_API_TOKEN='your-token'
export ATLASSIAN_EMAIL='your.email@example.com'
export ATLASSIAN_SITE='your-domain.atlassian.net'
```

Get tokens:
- **Figma**: https://www.figma.com/developers/api#access-tokens
- **Atlassian**: https://id.atlassian.com/manage-profile/security/api-tokens

## Platform Comparison

| Feature | OpenCode | Claude Code | Gemini | Cursor | Pi |
|---------|----------|-------------|---------|--------|-----|
| **Skills** | All 8 | All 8 | All 8 | All 8 | All 8 |
| **Tool System** | TypeScript | MCP plugins | Shell scripts | MCP | CLI tools |
| **MCP Support** | Full | Full (best) | Limited | Full | None |
| **Figma** | REST + OAuth | Official MCP | REST API | MCP plugin | REST API |
| **JIRA** | REST + ADF | MCP plugin | REST API | MCP plugin | REST API |
| **Confluence** | REST + ADF | MCP plugin | REST API | MCP plugin | REST API |
| **GitHub** | `gh` CLI | `gh` CLI | `gh` CLI | `gh` CLI | `gh` CLI |
| **Models** | Any (OpenRouter) | Claude only | Gemini only | Any | Any (15+ providers) |
| **Best For** | Custom | Figma-heavy | Free tier | IDE users | Minimal/extensible |

## Troubleshooting

### Installation fails
```bash
# Check platform detection
./scripts/verify.sh

# Manual install for your platform
# See platform-specific sections above
```

### Tools not available
```bash
# Verify installation
./scripts/verify.sh

# Re-run installer
./scripts/install.sh
```

### Platform not detected
```bash
# Set config directory explicitly
export OPENCODE_CONFIG=~/.config/opencode
export CLAUDE_CONFIG=~/.claude
export GEMINI_CONFIG=~/.gemini
export CURSOR_CONFIG=~/.cursor
export PI_CONFIG=~/.pi

./scripts/install.sh
```

## Getting Help

- **Documentation**: See README.md and INSTALL.md
- **Platform guides**: See `platforms/` directory
- **Issues**: https://github.com/bouwerp/agentic-framework/issues
