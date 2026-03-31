# Skills & Tools for Pi

Adaptation of the framework for Pi, the minimal terminal-based coding agent.

Website: https://shittycodingagent.ai

## Key Differences from Other Platforms

| Aspect | OpenCode | Claude Code | Pi |
|--------|----------|-------------|-----|
| **Config Dir** | `~/.config/opencode/` | `~/.claude/` | `~/.pi/agent/` |
| **Tool Config** | TypeScript tools | MCP plugins | CLI tools + READMEs |
| **Skill System** | Markdown skills | Claude Skills | Capability packages |
| **MCP Support** | Yes | Yes (excellent) | No (by design) |
| **Philosophy** | Feature-rich | Plugin ecosystem | Primitives, not features |

## Installation

### Prerequisites

```bash
# Install Pi
npm install -g @mariozechner/pi-coding-agent
```

### Option 1: Auto-Installer (Recommended)

```bash
./scripts/install.sh
```

### Option 2: Manual Installation

```bash
# Create skills directory
mkdir -p ~/.pi/agent/skills

# Copy universal skills
cp -r skills/* ~/.pi/agent/skills/
```

## How Skills Work in Pi

Pi uses skills as **capability packages** — bundles of instructions and tool definitions that extend the agent's abilities. Unlike MCP-based platforms, Pi deliberately omits MCP support in favour of CLI tools with READMEs as skill documentation.

Skills are loaded from `~/.pi/agent/skills/` and provide:
- **Instructions**: Markdown files describing how to use the capability
- **Tool definitions**: CLI commands the agent can invoke
- **Context**: Domain knowledge for the task at hand

## Figma Integration

Pi uses the REST API approach (no MCP):

### Setup

```bash
export FIGMA_PERSONAL_TOKEN='figd_your-token'
```

### Usage

```bash
pi -p "Get design tokens from Figma file ABC123"
```

Pi will use the Figma skill instructions to make REST API calls:

```
# Figma REST API endpoints used by the skill:
GET https://api.figma.com/v1/files/{file_key}
GET https://api.figma.com/v1/files/{file_key}/nodes?ids={node_id}
GET https://api.figma.com/v1/files/{file_key}/variables/local
```

## JIRA & Confluence Integration

Same REST API approach:

```bash
export ATLASSIAN_API_TOKEN='your-token'
export ATLASSIAN_EMAIL='your.email@example.com'
export ATLASSIAN_SITE='your-domain.atlassian.net'
```

```bash
pi -p "Get details for JIRA issue PROJ-123"
pi -p "Search Confluence for deployment docs"
```

## Project Configuration

Pi uses `AGENTS.md` for per-project instructions. You can reference skills from there:

`./AGENTS.md`:
```markdown
# Project Instructions

This project uses the Figma design system. When implementing UI:
1. Extract design tokens from Figma before coding
2. Use the figma-interaction skill for API access
3. Never hardcode colors or spacing values
```

## Extensions

Pi's extension system supports TypeScript modules. You can create custom extensions that wrap the skill instructions into programmatic tools:

```typescript
// ~/.pi/agent/extensions/figma.ts
export default {
  name: 'figma',
  tools: {
    async getTokens(fileKey: string) {
      const token = process.env.FIGMA_PERSONAL_TOKEN;
      const res = await fetch(
        `https://api.figma.com/v1/files/${fileKey}/variables/local`,
        { headers: { 'X-Figma-Token': token } }
      );
      return res.json();
    }
  }
};
```

## Platform-Specific Tips

### Pi Advantages
- Minimal and fast — no bloat
- Any model via 15+ providers (Anthropic, OpenAI, Google, etc.)
- Aggressively extensible via packages, extensions, and skills
- Tree-structured session history (`/tree`)
- No lock-in to any specific model or provider

### Limitations
- No MCP support (by design — use CLI tools instead)
- No built-in sub-agents (install via packages)
- No plan mode or to-dos in core (available as packages)

### Best Practices

1. **Use AGENTS.md** for project-specific instructions that reference skills
2. **Use extensions** for programmatic tool access (TypeScript modules)
3. **Use packages** for community-built capabilities (`npm install` or git)
4. **Keep it minimal** — Pi's philosophy is primitives over features

## Quick Start

```bash
# 1. Install Pi
npm install -g @mariozechner/pi-coding-agent

# 2. Install skills
./scripts/install.sh

# 3. Set tokens
export FIGMA_PERSONAL_TOKEN='figd_...'
export ATLASSIAN_API_TOKEN='...'

# 4. Test
pi -p "Get design tokens from Figma file ABC123"
```

## Comparison Table

| Feature | OpenCode | Claude Code | Gemini | Pi |
|---------|----------|-------------|---------|-----|
| **Skills** | Markdown | Claude Skills | System instructions | Capability packages |
| **Tools** | TypeScript | MCP plugins | Shell scripts | CLI tools + extensions |
| **MCP** | Full | Full (best) | Limited | None |
| **Figma** | REST + OAuth | Official MCP | REST API | REST API |
| **GitHub** | `gh` CLI | `gh` CLI | `gh` CLI | `gh` CLI |
| **Models** | Any (OpenRouter) | Claude only | Gemini only | Any (15+ providers) |
| **Best For** | Custom workflows | Figma-heavy | Free tier | Minimal/extensible |

## References

- [Pi Coding Agent](https://shittycodingagent.ai)
- [Pi on npm](https://www.npmjs.com/package/@mariozechner/pi-coding-agent)
