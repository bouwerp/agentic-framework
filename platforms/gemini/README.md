# Orchestrator-Worker-Validator for Gemini

Adaptation of the O-W-V framework for Google's Gemini (Gemini CLI / Gemini Code Assist).

## Key Differences from OpenCode

| Aspect | OpenCode | Gemini |
|--------|----------|--------|
| **Agent Config** | Markdown files | System instructions |
| **Tool Config** | TypeScript tools | Gemini Extensions |
| **Model Selection** | Config file | Built-in (Gemini models) |
| **MCP Support** | Yes | Limited/None |
| **Primary Approach** | MCP + Tools | REST API + Extensions |

## Architecture Notes

**Gemini has limited MCP support**, so the framework adapts to use:
- **System instructions** for agent roles
- **REST API tools** instead of MCP
- **Gemini Extensions** for custom tools (if available)

## Installation

### Option 1: Gemini CLI (Recommended)

```bash
# Install Gemini CLI
npm install -g @anthropic-ai/gemini-cli

# Or use Gemini Studio in browser
# https://aistudio.google.com/
```

### Option 2: Gemini Code Assist (VS Code)

Install the extension:
- VS Code: "Gemini Code Assist" extension
- JetBrains: "Gemini Assistant" plugin

## Agent Implementation

Gemini doesn't have explicit agent definitions. Use **system instructions**:

### Orchestrator System Instruction

```markdown
You are an Orchestrator agent coordinating a multi-agent workflow.

Your role:
1. Analyze user requests and break into tasks
2. Coordinate implementation and validation
3. Ensure quality through review cycles

When implementing from Figma:
1. Extract design tokens first
2. Plan component structure  
3. Delegate implementation
4. Request validation
5. Report completion
```

### Worker System Instruction

```markdown
You are a Worker agent implementing code changes.

Your role:
1. Implement specific features
2. Use design tokens (no hardcoded values)
3. Preview changes before applying
4. Report what was changed

Tools available:
- File operations (read/write/edit)
- Search/replace across files
- Figma REST API
```

### Validator System Instruction

```markdown
You are a Validator agent reviewing code changes.

Your role:
1. Review implementation quality
2. Validate against design tokens
3. Check accessibility compliance
4. Approve or request fixes

Validation checklist:
- Code matches design tokens
- No hardcoded colors/spacing
- Follows existing patterns
- WCAG 2.1 AA compliant
```

## Figma Integration (REST API Only)

Gemini doesn't support MCP well, so use REST API:

### Setup

```bash
export FIGMA_PERSONAL_TOKEN='figd_...'
```

### Usage in Prompts

```
Using the Figma REST API, get all design variables from file abc123xyz.
The token is in the FIGMA_PERSONAL_TOKEN environment variable.

API endpoint: https://api.figma.com/v1/files/abc123xyz/variables/local
Header: X-Figma-Token: $FIGMA_PERSONAL_TOKEN
```

### Custom Extension (Advanced)

If using Gemini with Extensions support, create `figma-extension.js`:

```javascript
// Gemini Extension for Figma API
module.exports = {
  name: 'figma-api',
  functions: {
    async getVariables(fileKey) {
      const token = process.env.FIGMA_PERSONAL_TOKEN;
      const response = await fetch(
        `https://api.figma.com/v1/files/${fileKey}/variables/local`,
        { headers: { 'X-Figma-Token': token } }
      );
      return response.json();
    },
    
    async getNode(fileKey, nodeId) {
      const token = process.env.FIGMA_PERSONAL_TOKEN;
      const response = await fetch(
        `https://api.figma.com/v1/files/${fileKey}/nodes?ids=${nodeId}`,
        { headers: { 'X-Figma-Token': token } }
      );
      return response.json();
    }
  }
};
```

## GSR Adaptation

Create a shell script for global search & replace:

`~/.gemini/tools/gsr.sh`:

```bash
#!/bin/bash
# Global Search & Replace for Gemini

SEARCH="$1"
REPLACE="$2"
PATTERN="${3:-**/*}"

echo "Searching for: $SEARCH"
echo "Replacing with: $REPLACE"
echo "Pattern: $PATTERN"
echo ""

# Preview
echo "Files that would be modified:"
grep -r "$SEARCH" --include="$PATTERN" . || echo "No matches found"

echo ""
read -p "Apply changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  find . -name "$PATTERN" -type f -exec sed -i '' "s/$SEARCH/$REPLACE/g" {} \;
  echo "Changes applied!"
fi
```

Make executable:
```bash
chmod +x ~/.gemini/tools/gsr.sh
```

## Model Configuration

Gemini auto-selects models:
- **Gemini 2.0 Pro**: Complex reasoning (default)
- **Gemini 2.0 Flash**: Fast responses
- **Gemini 2.5**: Advanced coding (when available)

No manual configuration needed.

## Example Workflow

### Full O-W-V Flow in Gemini

```bash
# Set token
export FIGMA_PERSONAL_TOKEN='figd_...'

# User request (with system instruction)
gemini --system="You are the Orchestrator" \
  "Implement the login page from this Figma: <url>"

# Expected flow:
# 1. Gemini (Orchestrator): Plans approach
# 2. Gemini (Worker): Extracts tokens via REST API
# 3. Gemini (Worker): Implements code
# 4. Gemini (Validator): Reviews implementation
# 5. Gemini (Orchestrator): Reports completion
```

### Multi-Turn Conversation

```
User: Implement this Figma design: <url>

Gemini (Orchestrator): I'll coordinate this implementation.
First, let me extract the design tokens...

[Switches to Worker role]

Gemini (Worker): I've extracted the design tokens:
- Primary color: #007AFF
- Spacing scale: 4px, 8px, 16px, 24px
- Typography: Heading 32px, Body 16px

Now implementing the React component...

[Implementation complete]

[Switches to Validator role]

Gemini (Validator): Reviewing the implementation...
✓ Colors match design tokens
✓ Spacing uses token values  
✓ Typography matches spec
✓ Accessibility compliant

Implementation approved!

[Switches back to Orchestrator]

Gemini (Orchestrator): Implementation complete and validated.
The login page has been created with full design fidelity.
```

## Platform-Specific Tips

### Gemini Advantages
- ✅ Excellent at multi-turn conversations
- ✅ Good at following system instructions
- ✅ Strong visual understanding (with images)
- ✅ Free tier available

### Limitations vs OpenCode
- ❌ No native MCP support
- ❌ No custom TypeScript tools
- ❌ No explicit agent configuration
- ❌ Gemini models only

### Best Practices

1. **Use System Instructions**
   - Start each session with role definition
   - Example: "You are the Orchestrator agent..."

2. **Explicit Role Switching**
   - Prompt Gemini to switch roles
   - Example: "Now act as the Worker and implement..."

3. **REST API for External Tools**
   - Use curl/fetch for API calls
   - Set environment variables for tokens

4. **Multi-Turn Conversations**
   - Break complex tasks into turns
   - Each turn can have different "role"

## Quick Start

```bash
# 1. Install Gemini CLI
npm install -g @anthropic-ai/gemini-cli

# 2. Set tokens
export FIGMA_PERSONAL_TOKEN='figd_...'

# 3. Test with system instruction
gemini --system="You are the Orchestrator" \
  "Plan the implementation of this Figma design: <url>"
```

## Comparison Table

| Feature | OpenCode | Claude Code | Gemini |
|---------|----------|-------------|---------|
| **Agent Definitions** | Markdown files | Skills | System instructions |
| **Tool System** | TypeScript | Skills + MCP | Extensions + REST |
| **MCP Support** | Full | Full | Limited |
| **Figma Integration** | REST + OAuth | MCP (official) | REST API only |
| **Model Selection** | Manual config | Auto | Auto |
| **Best For** | Custom workflows | Figma-heavy | Multi-turn conversations |

## References

- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [Gemini API](https://ai.google.dev/api)
- [Gemini Extensions](https://ai.google.dev/gemini-api/docs/extensions)
