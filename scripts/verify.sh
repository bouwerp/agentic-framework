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
    elif command -v pi >/dev/null 2>&1 || [ -d "$HOME/.pi" ]; then
        echo "pi"
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

    # Check tools
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
    for skill in figma-interaction jira confluence github planning-with-files aws context-compactor code-review; do
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
        echo -e "${GREEN}  ✓${NC} opencode.json found"
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
    for skill in figma-interaction jira confluence github planning-with-files aws context-compactor code-review; do
        if [ -d "$CLAUDE_DIR/skills/$skill" ]; then
            echo -e "${GREEN}  ✓${NC} $skill/"
        else
            echo -e "${YELLOW}  ○${NC} $skill/ (not installed)"
        fi
    done

    # Check MCP config
    echo ""
    echo "Checking MCP configuration..."
    if [ -f "$CLAUDE_DIR/mcp.json" ]; then
        if grep -q "figma" "$CLAUDE_DIR/mcp.json" 2>/dev/null; then
            echo -e "${GREEN}  ✓${NC} Figma MCP configured"
        else
            echo -e "${YELLOW}  ○${NC} Figma MCP not configured (optional)"
        fi
    else
        echo -e "${YELLOW}  ○${NC} mcp.json not found (optional)"
    fi

    # Check plugins
    echo ""
    echo "Checking plugins..."
    if command -v claude >/dev/null 2>&1; then
        if claude plugins list 2>/dev/null | grep -q "figma"; then
            echo -e "${GREEN}  ✓${NC} Figma plugin installed"
        else
            echo -e "${YELLOW}  ○${NC} Figma plugin not installed (optional)"
        fi
    fi
}

verify_gemini() {
    GEMINI_DIR="$HOME/.gemini"

    echo -e "${GREEN}✓${NC} Found Gemini config: $GEMINI_DIR"
    echo ""

    # Check skills
    echo "Checking skills..."
    for skill in figma-interaction jira confluence github planning-with-files aws context-compactor code-review; do
        if [ -d "$GEMINI_DIR/skills/$skill" ]; then
            echo -e "${GREEN}  ✓${NC} $skill/"
        else
            echo -e "${YELLOW}  ○${NC} $skill/ (not installed)"
        fi
    done

    # Check tools
    echo ""
    echo "Checking tools..."
    if [ -f "$GEMINI_DIR/tools/gsr.sh" ]; then
        echo -e "${GREEN}  ✓${NC} gsr.sh"
    else
        echo -e "${YELLOW}  ○${NC} gsr.sh (not installed)"
    fi
}

verify_cursor() {
    CURSOR_DIR="$HOME/.cursor"

    echo -e "${GREEN}✓${NC} Found Cursor config: $CURSOR_DIR"
    echo ""

    # Check skills
    echo "Checking skills..."
    for skill in figma-interaction jira confluence github planning-with-files aws context-compactor code-review; do
        if [ -d "$CURSOR_DIR/skills/$skill" ]; then
            echo -e "${GREEN}  ✓${NC} $skill/"
        else
            echo -e "${YELLOW}  ○${NC} $skill/ (not installed)"
        fi
    done
}

verify_pi() {
    PI_DIR="$HOME/.pi/agent"

    echo -e "${GREEN}✓${NC} Found Pi config: $PI_DIR"
    echo ""

    # Check skills
    echo "Checking skills..."
    for skill in figma-interaction jira confluence github planning-with-files aws context-compactor code-review; do
        if [ -d "$PI_DIR/skills/$skill" ]; then
            echo -e "${GREEN}  ✓${NC} $skill/"
        else
            echo -e "${YELLOW}  ○${NC} $skill/ (not installed)"
        fi
    done

    # Check AGENTS.md
    echo ""
    echo "Checking configuration..."
    if [ -f "$PI_DIR/AGENTS.md" ]; then
        echo -e "${GREEN}  ✓${NC} AGENTS.md found"
    else
        echo -e "${YELLOW}  ○${NC} AGENTS.md not found (optional)"
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
    pi)
        verify_pi
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
        echo "  opencode run \"Get design tokens from Figma file ABC123\""
        ;;
    claude-code)
        echo "To test the framework:"
        echo "  claude \"Get design tokens from Figma file ABC123\""
        ;;
    gemini)
        echo "To test the framework:"
        echo "  gemini \"Get design tokens from Figma file ABC123\""
        ;;
    cursor)
        echo "To test the framework:"
        echo "  Open Cursor agent chat and type: \"Get design tokens from Figma file ABC123\""
        ;;
    pi)
        echo "To test the framework:"
        echo "  pi -p \"Get design tokens from Figma file ABC123\""
        ;;
esac
echo ""
