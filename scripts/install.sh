#!/bin/sh
# Flow Development Environment Setup
#
# One-liner:
#   sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-ai-tools/main/scripts/install.sh)"
#
# Installs:
#   1. Flow CLI         — core development tool (emulator, deploy, test, etc.)
#   2. Cadence MCP      — AI agent access to Cadence tooling (type-check, review, query)
#   3. Flow AI Tools    — Claude Code plugin with Cadence/Flow skills
#
# After setup, the flow-dev plugin will help Claude Code guide you through
# any additional configuration based on what you're building.

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { printf "${BLUE}==>${NC} %s\n" "$1"; }
success() { printf "${GREEN} ✓${NC}  %s\n" "$1"; }
warn()    { printf "${YELLOW} !${NC}  %s\n" "$1"; }
error()   { printf "${RED} ✗${NC}  %s\n" "$1"; }

has() { command -v "$1" >/dev/null 2>&1; }

# Try to pick up newly-installed binaries without restarting the shell
refresh_path() {
    if [ -d "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
    if [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
    hash -r 2>/dev/null || true
}

# ── Flow CLI ────────────────────────────────────────────────────────────

install_flow_cli() {
    printf "\n${BOLD}[1/3] Flow CLI${NC}\n"

    if has flow; then
        success "Already installed"
        printf "      %s\n" "$(flow version 2>/dev/null | head -1)"
        return 0
    fi

    case "$(uname -s)" in
        Darwin)
            if has brew; then
                info "Installing via Homebrew..."
                brew install flow-cli
            else
                info "Installing via install script..."
                sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"
            fi
            ;;
        Linux)
            info "Installing via install script..."
            sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"
            ;;
        *)
            error "Automatic install not supported on this platform"
            printf "      See: https://developers.flow.com/tools/flow-cli/install\n"
            return 1
            ;;
    esac

    refresh_path

    if has flow; then
        success "Installed"
        printf "      %s\n" "$(flow version 2>/dev/null | head -1)"
    else
        warn "Installed but not in current PATH — restart your shell, then re-run this script"
        return 1
    fi
}

# ── Cadence MCP Server ──────────────────────────────────────────────────

setup_cadence_mcp() {
    printf "\n${BOLD}[2/3] Cadence MCP Server${NC}\n"

    if ! has flow; then
        warn "Flow CLI not found — skipping MCP setup"
        printf "      Install Flow CLI first, then re-run this script\n"
        return 0
    fi

    if ! has claude; then
        warn "Claude Code CLI not found — skipping"
        printf "      After installing Claude Code, run:\n"
        printf "      ${BOLD}claude mcp add --scope user cadence-mcp -- flow mcp${NC}\n"
        return 0
    fi

    # Check if already configured (capture output to avoid noisy health checks)
    MCP_LIST=$(claude mcp list 2>/dev/null) || true
    if printf '%s' "$MCP_LIST" | grep -q "cadence-mcp:"; then
        success "Already configured in Claude Code"
        return 0
    fi

    info "Adding Cadence MCP to Claude Code..."
    if claude mcp add --scope user cadence-mcp -- flow mcp >/dev/null 2>&1; then
        success "Configured (user scope)"
    else
        warn "Could not add automatically"
        printf "      Run: ${BOLD}claude mcp add --scope user cadence-mcp -- flow mcp${NC}\n"
    fi
}

# ── Flow AI Tools Plugin ────────────────────────────────────────────────

install_flow_plugin() {
    printf "\n${BOLD}[3/3] Flow AI Tools Plugin${NC}\n"

    if ! has claude; then
        warn "Claude Code CLI not found — skipping"
        printf "      After installing Claude Code, run inside a Claude Code session:\n"
        printf "      ${BOLD}/plugin marketplace add onflow/flow-ai-tools${NC}\n"
        printf "      ${BOLD}/plugin install flow-dev@flow-ai-tools${NC}\n"
        return 0
    fi

    # Check current state (capture output to keep it quiet)
    MARKETPLACE_LIST=$(claude plugin marketplace list 2>/dev/null) || true
    PLUGIN_LIST=$(claude plugin list 2>/dev/null) || true

    MARKETPLACE_EXISTS=false
    if printf '%s' "$MARKETPLACE_LIST" | grep -q "flow-ai-tools"; then
        MARKETPLACE_EXISTS=true
    fi

    PLUGIN_EXISTS=false
    if printf '%s' "$PLUGIN_LIST" | grep -q "flow-dev@flow-ai-tools"; then
        PLUGIN_EXISTS=true
    fi

    # Everything already in place
    if [ "$MARKETPLACE_EXISTS" = true ] && [ "$PLUGIN_EXISTS" = true ]; then
        success "Already installed"
        return 0
    fi

    # Add marketplace if needed
    if [ "$MARKETPLACE_EXISTS" = true ]; then
        success "Marketplace already added"
    else
        info "Adding Flow AI Tools marketplace..."
        if claude plugin marketplace add onflow/flow-ai-tools >/dev/null 2>&1; then
            success "Marketplace added"
            MARKETPLACE_EXISTS=true
        fi
    fi

    # Install plugin if needed
    if [ "$PLUGIN_EXISTS" = true ]; then
        success "Plugin already installed"
    elif [ "$MARKETPLACE_EXISTS" = true ]; then
        info "Installing flow-dev plugin..."
        if claude plugin install flow-dev@flow-ai-tools >/dev/null 2>&1; then
            success "Plugin installed"
            PLUGIN_EXISTS=true
        fi
    fi

    # Fall back to manual instructions for anything that didn't get set up
    if [ "$MARKETPLACE_EXISTS" != true ] || [ "$PLUGIN_EXISTS" != true ]; then
        warn "Run the remaining step(s) inside a Claude Code session:"
        if [ "$MARKETPLACE_EXISTS" != true ]; then
            printf "      ${BOLD}/plugin marketplace add onflow/flow-ai-tools${NC}\n"
        fi
        if [ "$PLUGIN_EXISTS" != true ]; then
            printf "      ${BOLD}/plugin install flow-dev@flow-ai-tools${NC}\n"
        fi
    fi
}

# ── Main ────────────────────────────────────────────────────────────────

main() {
    printf "\n"
    printf "${BOLD}  Flow Development Environment Setup${NC}\n"
    printf "  ====================================\n"

    install_flow_cli
    setup_cadence_mcp
    install_flow_plugin

    printf "\n  ────────────────────────────────────\n"
    printf "${GREEN}${BOLD}  Setup complete!${NC}\n\n"
    printf "  Quick start:\n"
    printf "    ${BOLD}flow init${NC}          Create a new Flow project\n"
    printf "    ${BOLD}flow emulator${NC}      Start the local blockchain\n"
    printf "    ${BOLD}flow test${NC}          Run Cadence tests\n\n"
    printf "  The flow-dev plugin gives Claude Code deep knowledge\n"
    printf "  of Cadence and Flow. It will guide you through any\n"
    printf "  additional setup based on what you're building.\n\n"
}

main
