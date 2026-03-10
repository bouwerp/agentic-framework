# Orchestrator-Worker-Validator for Claude Code

Adaptation of the O-W-V framework for Anthropic's Claude Code.

## Key Differences from OpenCode

| Aspect | OpenCode | Claude Code |
|--------|----------|-------------|
| **Agent Config** | Markdown files in `.opencode/agents/` | Claude Skills + MCP |
| **Tool Config** | TypeScript in `.opencode/tools/` | Claude Skills + MCP tools |
| **Model Selection** | `opencode.json` | Built-in (Claude models only) |
| **MCP Support** | Yes | Yes (excellent) |

## Installation

### Option 1: Claude Code Plugin (Recommended)

Claude Code uses plugins for agent skills:

```bash
# Install Figma plugin (includes MCP + skills)
claude plugin install figma@claude-plugins-official

# Install JIRA plugin
claude plugin install jira@claude-plugins-official

# Install Confluence plugin  
claude plugin install confluence@claude-plugins-official
```

### Option 2: Manual MCP Setup

```bash
# Add Figma MCP server
claude mcp add --transport http figma https://mcp.figma.com/mcp

# Authenticate
claude mcp auth figma
```

### Option 3: Claude Skills

Create skills in `~/.claude/skills/`:

```bash
mkdir -p ~/.claude/skills

# Copy skills from this framework
cp -r /path/to/agentic-framework/.opencode/skills/* ~/.claude/skills/
```

## Agent Implementation

Claude Code doesn't have explicit agent definitions like OpenCode. Instead, use **system prompts** and **skills**:

### Orchestrator Pattern

Create `~/.claude/skills/orchestrator.md`:

```markdown
# Orchestrator Role

You are coordinating a multi-agent workflow:

1. Break down complex tasks
2. Delegate to specialized agents
3. Coordinate validation
4. Report results

## Delegation Pattern

When you need to implement code:
1. Plan the implementation
2. Ask for implementation details
3. Request validation after completion

## Example

User: "Implement a login page from this Figma design"

You:
1. Analyze requirements
2. Extract design tokens from Figma
3. Plan component structure
4. Implement code
5. Validate against design
```

### Worker Pattern

Create `~/.claude/skills/worker.md`:

```markdown
# Worker Role

You are implementing code changes:

## Tools Available
- File write/edit
- GSR (Global Search & Replace)
- Figma API integration

## Workflow
1. Receive specific implementation task
2. Use appropriate tools
3. Preview changes before applying
4. Report completion

## GSR Usage
Always preview before applying:
- Run with dryRun: true first
- Review matches
- Apply with dryRun: false
```

### Validator Pattern

Create `~/.claude/skills/validator.md`:

```markdown
# Validator Role

You are reviewing code changes:

## Validation Checklist
- [ ] Code follows existing patterns
- [ ] No hardcoded values (use design tokens)
- [ ] Matches Figma design (if applicable)
- [ ] Accessibility requirements met

## Figma Validation
- Compare colors against tokens
- Verify spacing matches spec
- Check visual fidelity
```

## Model Configuration

Claude Code automatically uses Claude models:
- **Default**: Claude 3.5 Sonnet (best balance)
- **Complex tasks**: Claude 3.5 Opus (more reasoning)
- **Simple tasks**: Claude 3.5 Haiku (faster)

No manual configuration needed - Claude auto-selects.

## Figma Integration

### Using MCP (Recommended)

```bash
# Already configured via plugin
claude "Get design tokens from this Figma: <url>"
```

### Using REST API

Set environment variable:
```bash
export FIGMA_PERSONAL_TOKEN='figd_...'
```

Then use in prompts:
```
claude "Use the Figma REST API to get variables from file abc123"
```

## GSR Tool Adaptation

Claude Code doesn't have native GSR. Create a skill:

`~/.claude/skills/gsr.md`:

```markdown
# Global Search & Replace

When asked to rename or replace text across files:

1. Use grep to find all instances
2. Show preview of changes
3. Ask for confirmation
4. Apply changes file by file

## Example

User: "Rename getUser to fetchUser everywhere"

You:
1. grep -r "getUser" src/
2. Show all matches
3. Ask: "Found 15 instances. Replace all?"
4. Edit each file
```

## Example Workflow

### Full O-W-V Flow in Claude Code

```bash
# User request
claude "Implement the dashboard from this Figma: <url>"

# Claude (as Orchestrator):
# 1. Analyzes Figma URL
# 2. Extracts design tokens
# 3. Plans component structure

# Claude (as Worker):
# 4. Implements React components
# 5. Uses design tokens
# 6. Creates Tailwind styles

# Claude (as Validator):
# 7. Reviews implementation
# 8. Checks against Figma
# 9. Validates accessibility

# Claude (as Orchestrator):
# 10. Reports completion
```

## Platform-Specific Tips

### Claude Code Advantages
- ✅ Excellent MCP support (official Figma plugin)
- ✅ Built-in agent skills system
- ✅ Automatic model selection
- ✅ Great for Figma integration

### Limitations vs OpenCode
- ❌ No custom TypeScript tools (use skills instead)
- ❌ No explicit agent configuration
- ❌ Claude models only (no Qwen/Kimi)

### Best Practices

1. **Use Skills for Specialization**
   - Create separate skills for each role
   - Reference skills in prompts when needed

2. **Leverage MCP**
   - Use official plugins where available
   - MCP tools work seamlessly

3. **Prompt Engineering**
   - Be explicit about which "role" Claude should act as
   - Example: "As the Worker, implement this component..."

## Quick Start

```bash
# 1. Install plugins
claude plugin install figma@claude-plugins-official

# 2. Set tokens
export FIGMA_PERSONAL_TOKEN='figd_...'

# 3. Test
claude "As the Orchestrator, plan the implementation of this Figma design: <url>"
```

## References

- [Claude Code Skills](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/skills)
- [Claude Code MCP](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/mcp)
- [Claude Code Plugins](https://claude.com/blog/claude-code-plugins)
