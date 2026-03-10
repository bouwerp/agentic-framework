#!/bin/bash

# Orchestrator-Worker-Validator Framework Installer
# Supports: OpenCode, Claude Code, Gemini, Cursor

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Orchestrator-Worker-Validator Framework Installer    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect platform
detect_platform() {
    if [ -n "$OPENCODE_CONFIG" ] || [ -d "$HOME/.config/opencode" ]; then
        echo "opencode"
    elif command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
        echo "claude-code"
    elif command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then
        echo "gemini"
    elif command -v cursor >/dev/null 2>&1 || [ -d "$HOME/.cursor" ]; then
        echo "cursor"
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)

echo -e "${YELLOW}Detected platform: ${PLATFORM}${NC}"
echo ""

# Platform-specific installation
install_opencode() {
    OPENCODE_DIR="${OPENCODE_CONFIG:-$HOME/.config/opencode}"
    
    echo -e "${GREEN}✓${NC} Installing for OpenCode: ${OPENCODE_DIR}"
    echo ""
    
    echo -e "${YELLOW}Step 1/4: Creating directories...${NC}"
    mkdir -p "$OPENCODE_DIR/agents"
    mkdir -p "$OPENCODE_DIR/tools"
    mkdir -p "$OPENCODE_DIR/skills"
    echo -e "${GREEN}✓${NC} Directories created"
    echo ""
    
    echo -e "${YELLOW}Step 2/4: Installing agents...${NC}"
    cp "$PROJECT_ROOT/.opencode/agents/"*.md "$OPENCODE_DIR/agents/"
    echo -e "${GREEN}✓${NC} Agents installed (orchestrator, worker, validator)"
    echo ""
    
    echo -e "${YELLOW}Step 3/4: Installing tools...${NC}"
    cp "$PROJECT_ROOT/.opencode/tools/"*.ts "$OPENCODE_DIR/tools/"
    echo -e "${GREEN}✓${NC} Tools installed (gsr, figma-rest, figma-oauth)"
    echo ""
    
    echo -e "${YELLOW}Step 4/4: Installing skills...${NC}"
    if [ -d "$PROJECT_ROOT/.opencode/skills" ]; then
        cp -r "$PROJECT_ROOT/.opencode/skills/"* "$OPENCODE_DIR/skills/" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Skills installed (figma-interaction, jira, confluence)"
    fi
    echo ""
    
    install_config "$OPENCODE_DIR/opencode.json"
}

install_claude_code() {
    CLAUDE_DIR="$HOME/.claude"
    
    echo -e "${GREEN}✓${NC} Installing for Claude Code: ${CLAUDE_DIR}"
    echo ""
    
    echo -e "${YELLOW}Step 1/3: Creating directories...${NC}"
    mkdir -p "$CLAUDE_DIR/skills"
    echo -e "${GREEN}✓${NC} Directories created"
    echo ""
    
    echo -e "${YELLOW}Step 2/3: Installing skills...${NC}"
    # Copy platform-specific skills for Claude
    if [ -d "$PROJECT_ROOT/platforms/claude-code" ]; then
        cp "$PROJECT_ROOT/platforms/claude-code/"*.md "$CLAUDE_DIR/skills/" 2>/dev/null || true
    fi
    # Copy universal skills
    if [ -d "$PROJECT_ROOT/.opencode/skills" ]; then
        cp -r "$PROJECT_ROOT/.opencode/skills/"* "$CLAUDE_DIR/skills/" 2>/dev/null || true
    fi
    echo -e "${GREEN}✓${NC} Skills installed"
    echo ""
    
    echo -e "${YELLOW}Step 3/3: Setting up MCP servers...${NC}"
    echo "To add Figma MCP server, run:"
    echo "  claude mcp add --transport http figma https://mcp.figma.com/mcp"
    echo "  claude mcp auth figma"
    echo ""
    
    echo "Claude Code uses plugins for additional functionality:"
    echo "  claude plugin install figma@claude-plugins-official"
    echo "  claude plugin install jira@claude-plugins-official"
    echo "  claude plugin install confluence@claude-plugins-official"
    echo ""
}

install_gemini() {
    GEMINI_DIR="$HOME/.gemini"
    
    echo -e "${GREEN}✓${NC} Installing for Gemini: ${GEMINI_DIR}"
    echo ""
    
    echo -e "${YELLOW}Step 1/3: Creating directories...${NC}"
    mkdir -p "$GEMINI_DIR/skills"
    mkdir -p "$GEMINI_DIR/tools"
    echo -e "${GREEN}✓${NC} Directories created"
    echo ""
    
    echo -e "${YELLOW}Step 2/3: Installing skills and tools...${NC}"
    # Copy platform-specific skills for Gemini
    if [ -d "$PROJECT_ROOT/platforms/gemini" ]; then
        cp "$PROJECT_ROOT/platforms/gemini/"*.md "$GEMINI_DIR/skills/" 2>/dev/null || true
    fi
    # Copy REST API tools (Gemini doesn't support TypeScript tools)
    if [ -d "$PROJECT_ROOT/.opencode/tools" ]; then
        # Create shell script versions for Gemini
        cat > "$GEMINI_DIR/tools/gsr.sh" << 'GSREOF'
#!/bin/bash
# Global Search & Replace for Gemini
SEARCH="$1"
REPLACE="$2"
PATTERN="${3:-**/*}"
echo "Searching for: $SEARCH"
echo "Replacing with: $REPLACE"
grep -r "$SEARCH" --include="$PATTERN" . || echo "No matches found"
echo ""
read -p "Apply changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  find . -name "$PATTERN" -type f -exec sed -i '' "s/$SEARCH/$REPLACE/g" {} \;
  echo "Changes applied!"
fi
GSREOF
        chmod +x "$GEMINI_DIR/tools/gsr.sh"
        echo -e "${GREEN}✓${NC} Tools installed (gsr.sh)"
    fi
    echo ""
    
    echo -e "${YELLOW}Step 3/3: Environment setup...${NC}"
    echo "Add to ~/.zshrc or ~/.bashrc:"
    echo "  export FIGMA_PERSONAL_TOKEN='figd_your-token'"
    echo "  export ATLASSIAN_API_TOKEN='your-token'"
    echo ""
}

install_cursor() {
    CURSOR_DIR="$HOME/.cursor"
    
    echo -e "${GREEN}✓${NC} Installing for Cursor: ${CURSOR_DIR}"
    echo ""
    
    echo -e "${YELLOW}Step 1/3: Creating directories...${NC}"
    mkdir -p "$CURSOR_DIR/skills"
    echo -e "${GREEN}✓${NC} Directories created"
    echo ""
    
    echo -e "${YELLOW}Step 2/3: Installing skills...${NC}"
    # Copy universal skills
    if [ -d "$PROJECT_ROOT/.opencode/skills" ]; then
        cp -r "$PROJECT_ROOT/.opencode/skills/"* "$CURSOR_DIR/skills/" 2>/dev/null || true
    fi
    echo -e "${GREEN}✓${NC} Skills installed"
    echo ""
    
    echo -e "${YELLOW}Step 3/3: Cursor-specific setup...${NC}"
    echo "In Cursor, you can also install plugins via chat:"
    echo "  /plugin-add figma"
    echo "  /plugin-add jira"
    echo ""
    echo "Or configure MCP manually:"
    echo "  Settings → Cursor Settings → MCP → Add server"
    echo "  URL: https://mcp.figma.com/mcp"
    echo ""
}

install_config() {
    CONFIG_FILE="$1"
    
    echo -e "${YELLOW}Optional: Update configuration file?${NC}"
    echo "This will add agent definitions and model configurations."
    read -p "Update config? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$CONFIG_FILE" ]; then
            cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
            echo -e "${GREEN}✓${NC} Backed up existing config"
        fi
        cp "$PROJECT_ROOT/opencode.json" "$CONFIG_FILE"
        echo -e "${GREEN}✓${NC} Configuration updated"
        echo ""
        echo -e "${YELLOW}Note:${NC} Review the config and update:"
        echo "  - API keys/tokens"
        echo "  - Model preferences"
        echo "  - Provider settings"
    fi
}

show_environment_setup() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}           Environment Variables Setup                 ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Add these to your ~/.zshrc or ~/.bashrc:"
    echo ""
    echo "# Figma Personal Access Token"
    echo "# Get from: https://www.figma.com/developers/api#access-tokens"
    echo "export FIGMA_PERSONAL_TOKEN='figd_your-token-here'"
    echo ""
    echo "# Atlassian API Token (for JIRA/Confluence)"
    echo "# Get from: https://id.atlassian.com/manage-profile/security/api-tokens"
    echo "export ATLASSIAN_API_TOKEN='your-token-here'"
    echo "export ATLASSIAN_EMAIL='your.email@example.com'"
    echo "export ATLASSIAN_SITE='your-domain.atlassian.net'"
    echo ""
}

show_next_steps() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                  Installation Complete!                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    case $PLATFORM in
        opencode)
            echo "Next steps:"
            echo "1. Set your API tokens (see above)"
            echo "2. Restart opencode or reload your shell"
            echo "3. Test with: opencode run \"Hello, I'm the Orchestrator\""
            echo "4. Verify: ./scripts/verify.sh"
            ;;
        claude-code)
            echo "Next steps:"
            echo "1. Set your API tokens (see above)"
            echo "2. Install plugins:"
            echo "   claude plugin install figma@claude-plugins-official"
            echo "3. Test with: claude \"Hello, I'm the Orchestrator\""
            ;;
        gemini)
            echo "Next steps:"
            echo "1. Set your API tokens (see above)"
            echo "2. Test with: gemini --system=\"You are the Orchestrator\" \"Hello\""
            echo "3. Note: Use REST API approach for Figma/JIRA/Confluence"
            ;;
        cursor)
            echo "Next steps:"
            echo "1. Set your API tokens (see above)"
            echo "2. Restart Cursor"
            echo "3. Install plugins via chat: /plugin-add figma"
            echo "4. Test in Cursor agent chat"
            ;;
    esac
    echo ""
}

# Main installation flow
case $PLATFORM in
    opencode)
        install_opencode
        ;;
    claude-code)
        install_claude_code
        ;;
    gemini)
        install_gemini
        ;;
    cursor)
        install_cursor
        ;;
    *)
        echo -e "${RED}✗${NC} Could not detect supported platform"
        echo ""
        echo "Supported platforms:"
        echo "  - OpenCode (opencode)"
        echo "  - Claude Code (claude)"
        echo "  - Gemini (gemini)"
        echo "  - Cursor (cursor)"
        echo ""
        echo "Please install one of these platforms first."
        exit 1
        ;;
esac

show_environment_setup
show_next_steps
