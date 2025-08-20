#!/bin/bash

###############################################################################
# Laravel Docker Development Environment - Project Status Dashboard
# Version: 2.0
#
# This script provides a comprehensive overview of the Laravel Docker
# development environment from the host machine, including Docker container
# status, services health, network information, and helpful development tips.
#
# Usage:
#   ./scripts/project-status.sh
#
###############################################################################

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
SITES_MAP_FILE="$PROJECT_ROOT/sitesMap.yaml"

# Color codes for beautiful output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Docker compose command detection
DOCKER_COMPOSE_CMD=""
if command -v "docker" >/dev/null 2>&1; then
    if docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
    elif docker-compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker-compose"
    fi
fi

# Global variables
PROJECT_NAME="laravel-devenv"
NETWORK_NAME="laravel-docker-devenv-network"

###############################################################################
# UTILITY FUNCTIONS
###############################################################################

# Print styled header
print_header() {
    local title="$1"
    local width=80

    echo -e "${BOLD}${BLUE}"
    printf "╔"
    printf "═%.0s" $(seq 1 $((width-2)))
    printf "╗\n"
    printf "║ %-*s ║\n" $((width-4)) "$title"
    printf "╚"
    printf "═%.0s" $(seq 1 $((width-2)))
    printf "╝\n"
    echo -e "${NC}"
}

# Print section header
print_section() {
    local title="$1"
    echo -e "${BOLD}${CYAN}📋 $title${NC}"
    printf "%s\n" "$(printf "─%.0s" $(seq 1 80))"
}

# Load environment variables
load_environment() {
    if [ -f "$ENV_FILE" ]; then
        # Source the .env file while handling comments and empty lines
        eval "$(grep -E '^[A-Z_][A-Z0-9_]*=' "$ENV_FILE" | sed 's/^/export /')"
        return 0
    else
        echo -e "${YELLOW}⚠️  Warning: .env file not found at $ENV_FILE${NC}"
        return 1
    fi
}

# Check if Docker is available
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not installed or not available${NC}"
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker daemon is not running${NC}"
        return 1
    fi

    if [ -z "$DOCKER_COMPOSE_CMD" ]; then
        echo -e "${RED}❌ Docker Compose is not available${NC}"
        return 1
    fi

    return 0
}

###############################################################################
# STATUS FUNCTIONS
###############################################################################

# Show environment overview
show_environment_overview() {
    print_section "Environment Overview"

    echo -e "🐳 ${BOLD}Laravel Docker Development Environment v2.0${NC}"
    echo -e "📅 Current Date: ${WHITE}$(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
    echo -e "👤 Host User: ${WHITE}$(whoami)${NC}"
    echo -e "🖥️  Host System: ${WHITE}$(uname -s) $(uname -r)${NC}"
    echo -e "📂 Project Root: ${WHITE}${PROJECT_ROOT}${NC}"

    if [ -n "${APP_DIR:-}" ]; then
        echo -e "📁 App Directory: ${WHITE}${APP_DIR}${NC}"
    fi

    if [ -n "${DESTINATION_DIR:-}" ]; then
        echo -e "🎯 Container Mount: ${WHITE}${DESTINATION_DIR}${NC}"
    fi

    echo ""
}

# Show Docker status
show_docker_status() {
    print_section "Docker Environment"

    if ! check_docker; then
        echo -e "${RED}❌ Docker environment is not available${NC}"
        echo ""
        return 1
    fi

    # Docker version info
    local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "Unknown")
    local compose_version=""

    if [[ "$DOCKER_COMPOSE_CMD" == "docker compose" ]]; then
        compose_version=$(docker compose version --short 2>/dev/null || echo "Unknown")
    else
        compose_version=$(docker-compose version --short 2>/dev/null || echo "Unknown")
    fi

    echo -e "🐋 Docker Engine: ${GREEN}v${docker_version}${NC}"
    echo -e "🔧 Docker Compose: ${GREEN}${compose_version}${NC}"
    echo -e "📋 Compose Command: ${CYAN}${DOCKER_COMPOSE_CMD}${NC}"

    # Network status
    local network_status="❌ Not Found"
    if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
        network_status="✅ Active"
    fi
    echo -e "🌐 Project Network: $network_status (${NETWORK_NAME})"

    echo ""
}

# Show container status (optimized for speed)
show_container_status() {
    print_section "Container Health & Status"

    if [ -z "$DOCKER_COMPOSE_CMD" ]; then
        echo -e "${RED}❌ Docker Compose not available${NC}"
        echo ""
        return 1
    fi

    # Navigate to project directory for docker-compose commands
    cd "$PROJECT_ROOT"

    # Get basic container status only (fast)
    local containers_status
    if ! containers_status=$($DOCKER_COMPOSE_CMD ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null); then
        echo -e "${YELLOW}⚠️  No containers found or docker-compose.yml not accessible${NC}"
        echo ""
        return 1
    fi

    # Parse and display basic container information
    if [ -n "$containers_status" ]; then
        echo "$containers_status" | tail -n +2 | while IFS=$'\t' read -r name status; do
            if [ -n "$name" ] && [ -n "$status" ]; then
                # Determine status icon based on status text only
                local icon="⚪"
                local status_color="$WHITE"

                if [[ "$status" =~ [Uu]p ]]; then
                    icon="🟢"
                    status_color="$GREEN"
                elif [[ "$status" =~ [Ee]xit ]]; then
                    icon="🔴"
                    status_color="$RED"
                elif [[ "$status" =~ [Rr]estarting ]]; then
                    icon="🟡"
                    status_color="$YELLOW"
                fi

                # Display container information (basic only)
                echo -e "  $icon ${BOLD}${name}${NC}"
                echo -e "     Status: ${status_color}${status}${NC}"
                echo ""
            fi
        done
    else
        echo -e "${YELLOW}⚠️  No containers found${NC}"
    fi

    echo ""
}

# Show service health with essential details
show_service_health() {
    print_section "Service Health Details"

    cd "$PROJECT_ROOT"

    # Check if containers are running
    local running_containers
    if running_containers=$($DOCKER_COMPOSE_CMD ps --services --filter "status=running" 2>/dev/null); then

        # Check workspace container
        if echo "$running_containers" | grep -q "workspace"; then
            echo -e "🖥️  ${BOLD}Workspace Container${NC}"
            echo -e "     Status: ${GREEN}✅ Running${NC}"
            echo ""
        fi

        # Check MySQL
        if echo "$running_containers" | grep -q "mysql"; then
            echo -e "🗄️  ${BOLD}MySQL Database${NC}"
            echo -e "     Status: ${GREEN}✅ Running${NC}"
            if [ -n "${MYSQL_PORT:-}" ]; then
                echo -e "     Port: ${CYAN}${MYSQL_PORT}${NC}"
            fi
            echo ""
        fi

        # Check Redis
        if echo "$running_containers" | grep -q "redis"; then
            echo -e "🔴 ${BOLD}Redis Cache${NC}"
            echo -e "     Status: ${GREEN}✅ Running${NC}"
            if [ -n "${REDIS_PORT:-}" ]; then
                echo -e "     Port: ${CYAN}${REDIS_PORT}${NC}"
            fi
            echo ""
        fi

        # Check PHPMyAdmin
        if echo "$running_containers" | grep -q "phpmyadmin"; then
            echo -e "🔧 ${BOLD}PHPMyAdmin${NC}"
            # Use PHPMYADMIN_URL from .env, fallback to localhost with port
            if [ -n "${PHPMYADMIN_URL:-}" ]; then
                echo -e "     Access: ${CYAN}http://${PHPMYADMIN_URL}${NC}"
            elif [ -n "${PHPMYADMIN_PORT:-}" ]; then
                echo -e "     Access: ${CYAN}http://localhost:${PHPMYADMIN_PORT}${NC}"
            else
                echo -e "     Access: ${CYAN}http://localhost:8080${NC}"
            fi
            echo -e "     Status: ${GREEN}✅ Available${NC}"
            echo ""
        fi

        # Check MailHog
        if echo "$running_containers" | grep -q "mailhog"; then
            echo -e "📧 ${BOLD}MailHog Email Testing${NC}"
            echo -e "     Web UI: ${CYAN}http://localhost:${MAILHOG_WEB_PORT:-8025}${NC}"
            echo -e "     Status: ${GREEN}✅ Available${NC}"
            echo ""
        fi

    else
        echo -e "${YELLOW}⚠️  No running services found${NC}"
        echo -e "   Run 'make up' to start the development environment"
    fi

    echo ""
}

# Parse YAML file without yq dependency
parse_sites_yaml() {
    local yaml_file="$1"
    local in_sites_section=false
    local site_map=""
    local site_php=""
    local site_to=""

    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip empty lines and comments
        if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
            continue
        fi

        # Check for sites section
        if [[ "$line" =~ ^sites: ]]; then
            in_sites_section=true
            continue
        fi

        # If we're in the sites section
        if [ "$in_sites_section" = true ]; then
            # Check for end of sites section (new top-level key without indentation)
            if [[ "$line" =~ ^[a-zA-Z][^:]*:[[:space:]]*$ ]] && [[ ! "$line" =~ ^sites: ]]; then
                in_sites_section=false
                continue
            fi

            # New site entry (starts with -)
            if [[ "$line" =~ ^-[[:space:]] ]]; then
                # Output previous site if we have complete data
                if [ -n "$site_map" ] && [ -n "$site_php" ] && [ -n "$site_to" ]; then
                    echo "${site_map}|${site_php}|${site_to}"
                fi

                # Reset for new site
                site_map=""
                site_php=""
                site_to=""
            fi

            # Parse site properties (both inline and multiline formats)
            if [[ "$line" =~ map:[[:space:]]*(.+)$ ]]; then
                site_map="${BASH_REMATCH[1]}"
                # Remove quotes if present
                site_map=$(echo "$site_map" | sed 's/^"//;s/"$//')
            elif [[ "$line" =~ php:[[:space:]]*(.+)$ ]]; then
                site_php="${BASH_REMATCH[1]}"
                # Remove quotes if present
                site_php=$(echo "$site_php" | sed 's/^"//;s/"$//')
            elif [[ "$line" =~ to:[[:space:]]*(.+)$ ]]; then
                site_to="${BASH_REMATCH[1]}"
                # Remove quotes if present
                site_to=$(echo "$site_to" | sed 's/^"//;s/"$//')
            fi
        fi
    done < "$yaml_file"

    # Output the last site if we have complete data
    if [ -n "$site_map" ] && [ -n "$site_php" ] && [ -n "$site_to" ]; then
        echo "${site_map}|${site_php}|${site_to}"
    fi
}

# Show configured sites and their URLs
show_configured_sites() {
    print_section "Configured Projects & URLs"

    if [ ! -f "$SITES_MAP_FILE" ]; then
        echo -e "${YELLOW}⚠️  sitesMap.yaml not found${NC}"
        echo -e "   Create it from sitesMap.example.yaml to configure your sites"
        echo ""
        return
    fi

    # Parse YAML using native bash
    local sites_info
    sites_info=$(parse_sites_yaml "$SITES_MAP_FILE")

    if [ -n "$sites_info" ]; then
        local site_count=$(echo "$sites_info" | wc -l)
        echo -e "${GREEN}Found ${site_count} configured project(s):${NC}"
        echo ""

        # Use a for loop with array processing to avoid potential while loop issues
        local IFS=$'\n'
        for site_line in $sites_info; do
            if [ -n "$site_line" ]; then
                # Split the line manually
                local site_map=$(echo "$site_line" | cut -d'|' -f1)
                local site_php=$(echo "$site_line" | cut -d'|' -f2)
                local site_to=$(echo "$site_line" | cut -d'|' -f3)

                if [ -n "$site_map" ]; then
                    echo -e "  🌐 ${BOLD}${site_map}${NC}"
                    echo -e "     URL: ${GREEN}http://${site_map}${NC}"
                    echo -e "     PHP Version: ${CYAN}${site_php}${NC}"
                    echo -e "     Document Root: ${WHITE}${site_to}${NC}"

                    # Check if domain is in /etc/hosts
                    if grep -q "$site_map" /etc/hosts 2>/dev/null; then
                        echo -e "     Hosts Entry: ${GREEN}✅ Found${NC}"
                    else
                        echo -e "     Hosts Entry: ${YELLOW}⚠️  Not found - add '127.0.0.1 ${site_map}' to /etc/hosts${NC}"
                    fi

                    echo ""
                fi
            fi
        done

        # Show additional helpful information
        echo -e "${BOLD}📝 Quick Setup:${NC}"
        echo -e "  Add these entries to your /etc/hosts file:"
        for site_line in $sites_info; do
            if [ -n "$site_line" ]; then
                local site_map=$(echo "$site_line" | cut -d'|' -f1)
                if [ -n "$site_map" ]; then
                    echo -e "  ${DIM}127.0.0.1 ${site_map}${NC}"
                fi
            fi
        done

        # Add PHPMyAdmin URL if available
        if [ -n "${PHPMYADMIN_URL:-}" ]; then
            echo -e "  ${DIM}127.0.0.1 ${PHPMYADMIN_URL}${NC}"
        fi

    else
        echo -e "${YELLOW}⚠️  No sites configured in sitesMap.yaml${NC}"
        echo -e "   Example configuration:"
        echo -e "${DIM}   sites:"
        echo -e "     - map: myapp.local"
        echo -e "       php: 8.3"
        echo -e "       to: /var/www/myapp/public${NC}"
    fi

    echo ""
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    # Load environment variables
    load_environment >/dev/null 2>&1

    # Clear screen and show header
    # clear  # Commented out to see output in terminal
    print_header "Laravel Docker Development Environment - Status Dashboard"

    # Show all status sections
    show_environment_overview
    show_docker_status
    show_container_status
    show_service_health
    show_configured_sites

    # Final message
    echo -e "${BOLD}${GREEN}✅ Status check completed successfully!${NC}"
    echo ""
}

# Trap to handle script interruption gracefully
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 130' INT

# Execute main function with all arguments
main "$@"
