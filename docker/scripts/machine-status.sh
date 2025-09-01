#!/bin/bash
###############################################################################
# Project Status Dashboard
# Part of Laravel Docker Development Environment v2.0
###############################################################################
#
# This script provides a comprehensive overview of the development environment
# including service status, PHP versions, nginx sites, and system resources.
#
# Usage: machine-status.sh [--detailed]
#
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
DESTINATION_DIR=${DESTINATION_DIR:-/var/www}
SITES_MAP_FILE="${DESTINATION_DIR}/sitesMap.yaml"
PHP_VERSIONS=("7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3")

# Utility functions
print_header() {
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}$1${NC} ${BOLD}${BLUE}                                           ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${BOLD}${CYAN}📋 $1${NC}"
    echo "────────────────────────────────────────────────────────────────────────────────"
}

status_icon() {
    local status="$1"
    case "$status" in
        "RUNNING"|"running"|"UP"|"healthy")
            echo "🟢"
        ;;
        "STOPPED"|"stopped"|"DOWN"|"unhealthy")
            echo "🔴"
        ;;
        "STARTING"|"starting"|"restarting")
            echo "🟡"
        ;;
        *)
            echo "⚪"
        ;;
    esac
}

# Function to show environment overview
show_environment_overview() {
    print_section "Environment Overview"

    echo "🐳 Docker Environment: Laravel Development Environment v2.0"
    echo "📅 Current Date: $(date)"
    echo "👤 Current User: $(whoami)"
    echo "🖥️  Hostname: $(hostname)"
    echo "📂 Project Directory: ${DESTINATION_DIR}"
    echo ""
}

# Function to show Supervisor status
show_supervisor_status() {
    print_section "Supervisor Status"

    # Since we're inside the container, show supervisor-managed services
    if command -v supervisorctl >/dev/null 2>&1; then
        echo "Supervisor Services:"
        sudo supervisorctl status | while read line; do
            service=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2}')
            icon=$(status_icon "$status")
            echo "  $icon $service: $status"
        done
    else
        echo "⚠️  Supervisor not available"
    fi
    echo ""
}

# Function to show PHP status
show_php_status() {
    print_section "PHP Environment"

    echo "Default PHP Version:"
    if command -v php >/dev/null 2>&1; then
        echo "  🐘 $(php --version | head -1)"
    else
        echo "  ❌ PHP not available"
    fi
    echo ""

    echo "Available PHP Versions:"
    for version in "${PHP_VERSIONS[@]}"; do
        local status="❌"
        local socket_status="❌"
        local service_status="❌"

        # Check if PHP binary exists
        if command -v "php${version}" >/dev/null 2>&1; then
            status="✅"
        fi

        # Check if socket exists
        if [ -S "/run/php/php${version}-fpm.sock" ]; then
            socket_status="✅"
        fi

        # Check service status via supervisor
        if sudo supervisorctl status "php${version}-fpm" >/dev/null 2>&1; then
            if sudo supervisorctl status "php${version}-fpm" | grep -q "RUNNING"; then
                service_status="🟢"
            else
                service_status="🔴"
            fi
        fi

        echo "  PHP ${version}: Binary $status | Socket $socket_status | Service $service_status"
    done
    echo ""
}

# Function to show nginx status
show_nginx_status() {
    print_section "Nginx Web Server"

    # Check nginx status
    if pgrep nginx >/dev/null 2>&1; then
        echo "🟢 Nginx: Running"
        echo "  📊 Worker Processes: $(pgrep nginx | wc -l)"

        # Show nginx user
        local nginx_user=$(ps aux | grep '[n]ginx: worker' | head -1 | awk '{print $1}')
        if [ -n "$nginx_user" ]; then
            echo "  👤 Running as: $nginx_user"
        fi
    else
        echo "🔴 Nginx: Not running"
    fi
    echo ""

    # Show configured sites
    echo "Configured Sites:"
    if [ -f "$SITES_MAP_FILE" ] && command -v yq >/dev/null 2>&1; then
        local site_count=$(yq eval '.sites | length' "$SITES_MAP_FILE" 2>/dev/null || echo "0")
        if [ "$site_count" -gt 0 ]; then
            for ((i=0; i<site_count; i++)); do
                local site_map=$(yq eval ".sites[$i].map" "$SITES_MAP_FILE" 2>/dev/null | sed 's/^"//;s/"$//')
                local site_php=$(yq eval ".sites[$i].php" "$SITES_MAP_FILE" 2>/dev/null | sed 's/^"//;s/"$//')
                local site_to=$(yq eval ".sites[$i].to" "$SITES_MAP_FILE" 2>/dev/null | sed 's/^"//;s/"$//')

                # Check if nginx config exists
                local config_status="❌"
                if [ -f "/etc/nginx/sites-available/${site_map}.conf" ]; then
                    config_status="✅"
                fi

                echo "  🌐 $site_map → PHP $site_php ($site_to) $config_status"
            done
        else
            echo "  ⚠️  No sites configured in sitesMap.yaml"
        fi
    else
        echo "  ⚠️  sitesMap.yaml not found or yq not available"
    fi
    echo ""
}

# Function to show system resources
show_system_resources() {
    print_section "System Resources"

    # Memory usage
    if [ -f "/proc/meminfo" ]; then
        local total_mem=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
        local available_mem=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
        local used_mem=$((total_mem - available_mem))
        local mem_percent=$((used_mem * 100 / total_mem))

        echo "💾 Memory Usage: ${used_mem}MB / ${total_mem}MB (${mem_percent}%)"
    fi

    # Disk usage for ${DESTINATION_DIR}
    if command -v df >/dev/null 2>&1; then
        local disk_info=$(df -h "${DESTINATION_DIR}" 2>/dev/null | tail -1)
        if [ -n "$disk_info" ]; then
            local used=$(echo "$disk_info" | awk '{print $3}')
            local available=$(echo "$disk_info" | awk '{print $4}')
            local percent=$(echo "$disk_info" | awk '{print $5}')
            echo "💿 Disk Usage (${DESTINATION_DIR}): ${used} used, ${available} available (${percent})"
        fi
    fi

    # Load average
    if [ -f "/proc/loadavg" ]; then
        local load=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
        echo "⚡ Load Average: $load"
    fi

    # Process count
    local process_count=$(ps aux | wc -l)
    echo "🔄 Running Processes: $process_count"
    echo ""
}

# Function to show network status
show_network_status() {
    print_section "Network Status"

    echo "Listening Ports:"
    if command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep LISTEN | while read line; do
            local port=$(echo "$line" | awk '{print $4}' | sed 's/.*://')
            local process=$(echo "$line" | awk '{print $7}' | cut -d'/' -f2)

            case "$port" in
                "22") echo "  🔐 SSH: $port ($process)" ;;
                "80") echo "  🌐 HTTP: $port ($process)" ;;
                "443") echo "  🔒 HTTPS: $port ($process)" ;;
                "3306") echo "  🗄️  MySQL: $port ($process)" ;;
                "6379") echo "  🔴 Redis: $port ($process)" ;;
                "8025") echo "  📧 MailHog: $port ($process)" ;;
                *) echo "  📡 Port $port ($process)" ;;
            esac
        done
    else
        echo "  ⚠️  netstat not available"
    fi
    echo ""
}

# Function to show recent logs
show_recent_activity() {
    print_section "Recent Activity"

    echo "Recent Nginx Access (last 5 entries):"
    if [ -d "/var/log/nginx" ]; then
        find /var/log/nginx -name "*access.log" -type f -exec tail -5 {} \; 2>/dev/null | head -5 | while read line; do
            echo "  📝 $line"
        done
    else
        echo "  ⚠️  No nginx logs found"
    fi
    echo ""

    echo "Recent PHP-FPM Errors (last 3 entries):"
    local error_found=false
    for version in "${PHP_VERSIONS[@]}"; do
        local log_file="/var/log/php${version}-fpm.log"
        if [ -f "$log_file" ]; then
            local recent_errors=$(tail -3 "$log_file" 2>/dev/null | grep -i error | head -1)
            if [ -n "$recent_errors" ]; then
                echo "  🚨 PHP $version: $recent_errors"
                error_found=true
            fi
        fi
    done

    if [ "$error_found" = false ]; then
        echo "  ✅ No recent PHP-FPM errors"
    fi
    echo ""
}

# Function to show helpful commands
show_helpful_commands() {
    print_section "Helpful Commands"

    echo "PHP Management:"
    echo "  📊 php-manager status          - Show all PHP-FPM status"
    echo "  🔌 php-manager sockets         - List PHP sockets"
    echo "  🔄 php-manager restart         - Restart all PHP services"
    echo "  ℹ️  php-manager info            - Detailed PHP information"
    echo ""

    echo "Site Management:"
    echo "  🌐 generate-sites              - Regenerate nginx sites"
    echo "  🔧 nginx -t                       - Test nginx configuration"
    echo "  📋 supervisorctl status           - Show all services"
    echo ""

    echo "Development:"
    echo "  🎯 composer --version             - Check Composer"
    echo "  📦 npm --version                  - Check Node.js/NPM"
    echo "  🧶 yarn --version                 - Check Yarn"
    echo ""
}

# Main function
main() {
    local detailed="$1"

    clear
    print_header "Laravel Docker Development Environment - Status Dashboard"

    show_environment_overview
    show_supervisor_status
    show_php_status
    show_nginx_status

    if [ "$detailed" = "--detailed" ] || [ "$detailed" = "-d" ]; then
        show_system_resources
        show_network_status
        show_recent_activity
    fi

    show_helpful_commands

    echo ""
    echo -e "${BOLD}${GREEN}✅ Status check completed!${NC}"
    echo -e "💡 Run with ${BOLD}--detailed${NC} flag for more information"
    echo ""
}

# Check if running with help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Project Status Dashboard"
    echo "======================="
    echo ""
    echo "Usage: $0 [--detailed]"
    echo ""
    echo "Options:"
    echo "  --detailed, -d    Show detailed system information"
    echo "  --help, -h        Show this help message"
    echo ""
    exit 0
fi

# Run main function
main "$@"
