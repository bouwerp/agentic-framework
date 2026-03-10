#!/bin/bash

# Verify Framework Installation (Multi-Platform)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Framework Installation Verification ===${NC}"
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
echo -e "${YELLOW}Platform: ${PLATFORM}${NC}"
echo ""

verify_opencode() {
    OPENCODE_DIR="${OPENCODE_CONFIG:-$HOME/.config/opencode}"
    
    echo -e "${GREEN}✓${NC} Found OpenCode config: $OPENCODE_DIR"
    echo ""
    
    # Check agents
    echo "Checking agents..."
    for agent in orchestrator worker validator; do
        if [ -f "$OPENCODE_DIR/agents/$agent.md" ]; then
            echo -e "${GREEN}  ✓${NC} $agent.md"
        else
            echo -e "${RED}  ✗${NC} $agent.md (missing)"
        fi
    done
    
    # Check tools
    echo ""
    echo "Checking tools..."
    for tool in gsr figma-rest figma-oauth; do
        if [ -f "$OPENCODE_DIR/tools/$tool.ts" ]; then
            echo -e "${GREEN}  ✓${NC} $tool.ts"
        else
            echo -e "${RED}  ✗${NC} $tool.ts (missing)"
        fi
    done
    
    # Check skills
    echo ""
    echo "Checking skills..."
    for skill in figma-interaction jira confluence; do
        if [ -d "$OPENCODE_DIR/skills/$skill" ]; then
            echo -e "${GREEN}  ✓${NC} $skill/"
        else
            echo -e "${YELLOW}  ○${NC} $skill/ (optional)"
        fi
    done
    
    # Check config
    echo ""
    echo "Checking configuration..."
    if [ -f "$OPENCODE_DIR/opencode.json" ]; then
        if grep -q "orchestrator" "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
            echo -e "${GREEN}  ✓${NC} opencode.json has agent configuration"
        else
            echo -e "${YELLOW}  ○${NC} opencode.json exists but may need updates"
        fi
    else
        echo -e "${YELLOW}  ○${NC} opencode.json not found (using defaults)"
    fi
}

verify_claude_code() {
    CLAUDE_DIR="$HOME/.claude"
    
    echo -e "${GREEN}✓${NC} Found Claude Code config: $CLAUDE_DIR"
    echo ""
    
    # Check skills
    echo "Checking skills..."
    if [ -d "$CLAUDE_DIR/skills" ]; then
        skill_count=$(ls -1 "$CLAUDE_DIR/skills"/*.md 2>/dev/null | wc -l)
        echo -e "${GREEN}  ✓${NC} Skills directory ($skill_count skills)"
    else
        echo -e "${RED}  ✗${NC} Skills directory (missing)"
    fi
    
    # Check MCP config
    echo ""
    echo "Checking MCP configuration..."
    if [ -f "$CLAUDE_DIR/mcp.json" ]; then
        if grep -q "figma" "$CLAUDE_DIR/mcp.json" 2>/dev/null; then
            echo -e "${GREEN}  ✓${NC} Figma MCP configured"
        else
            echo -e "${YELLOW}  ○${NC} Figma MCP not configured"
        fi
    else
        echo -e "${YELLOW}  ○${NC} mcp.json not found"
    fi
    
    # Check plugins
    echo ""
    echo "Checking plugins..."
    if command -v claude >/dev/null 2>&1; then
        if claude plugins list 2>/dev/null | grep -q "figma"; then
            echo -e "${GREEN}  ✓${NC} Figma plugin installed"
        else
            echo -e "${YELLOW}  ○${NC} Figma plugin not installed"
        fi
    fi
}

verify_gemini() {
    GEMINI_DIR="$HOME/.gemini"
    
    echo -e "${GREEN}✓${NC} Found Gemini config: $GEMINI_DIR"
    echo ""
    
    # Check skills
    echo "Checking skills..."
    if [ -d "$GEMINI_DIR/skills" ]; then
        skill_count=$(ls -1 "$GEMINI_DIR/skills"/*.md 2>/dev/null | wc -l)
        echo -e "${GREEN}  ✓${NC} Skills directory ($skill_count skills)"
    else
        echo -e "${RED}  ✗${NC} Skills directory (missing)"
    fi
    
    # Check tools
    echo ""
    echo "Checking tools..."
    if [ -f "$GEMINI_DIR/tools/gsr.sh" ]; then
        echo -e "${GREEN}  ✓${NC} gsr.sh"
    else
        echo -e "${YELLOW}  ○${NC} gsr.sh (optional)"
    fi
}

verify_cursor() {
    CURSOR_DIR="$HOME/.cursor"
    
    echo -e "${GREEN}✓${NC} Found Cursor config: $CURSOR_DIR"
    echo ""
    
    # Check skills
    echo "Checking skills..."
    if [ -d "$CURSOR_DIR/skills" ]; then
        skill_count=$(ls -1 "$CURSOR_DIR/skills"/*.md 2>/dev/null | wc -l)
        echo -e "${GREEN}  ✓${NC} Skills directory ($skill_count skills)"
    else
        echo -e "${RED}  ✗${NC} Skills directory (missing)"
    fi
}

# Check environment variables (all platforms)
echo "Checking environment variables..."
if [ -n "$FIGMA_PERSONAL_TOKEN" ]; then
    echo -e "${GREEN}  ✓${NC} FIGMA_PERSONAL_TOKEN is set"
else
    echo -e "${YELLOW}  ○${NC} FIGMA_PERSONAL_TOKEN (not set, required for Figma)"
fi

if [ -n "$ATLASSIAN_API_TOKEN" ]; then
    echo -e "${GREEN}  ✓${NC} ATLASSIAN_API_TOKEN is set"
else
    echo -e "${YELLOW}  ○${NC} ATLASSIAN_API_TOKEN (not set, required for JIRA/Confluence)"
fi

echo ""

# Platform-specific verification
case $PLATFORM in
    opencode)
        verify_opencode
        ;;
    claude-code)
        verify_claude_code
        ;;
    gemini)
        verify_gemini
        ;;
    cursor)
        verify_cursor
        ;;
    *)
        echo -e "${RED}✗${NC} Unknown platform - cannot verify"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}=== Verification Complete ===${NC}"
echo ""

case $PLATFORM in
    opencode)
        echo "To test the framework:"
        echo "  opencode run \"Hello, I'm the Orchestrator\""
        ;;
    claude-code)
        echo "To test the framework:"
        echo "  claude \"Hello, I'm the Orchestrator\""
        ;;
    gemini)
        echo "To test the framework:"
        echo "  gemini --system=\"You are the Orchestrator\" \"Hello\""
        ;;
    cursor)
        echo "To test the framework:"
        echo "  Open Cursor agent chat and type: \"Hello, I'm the Orchestrator\""
        ;;
esac
echo ""
