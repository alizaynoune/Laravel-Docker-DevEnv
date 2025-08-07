#!/bin/bash
###############################################################################
# PHP-FPM Management Utility
# Part of Laravel Docker Development Environment v2.0
###############################################################################
#
# This script provides comprehensive management for multiple PHP-FPM versions
# including status monitoring, service control, and debugging capabilities.
#
# Usage: php-manager.sh [command]
# Commands: status, sockets, logs, restart, test, versions, info
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
NC='\033[0m' # No Color

# PHP versions managed by this system
PHP_VERSIONS=("7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3")

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show PHP-FPM service status
show_status() {
    log "PHP-FPM Pool Status:"
    
    for version in "${PHP_VERSIONS[@]}"; do
        if supervisorctl status "php${version}-fpm" >/dev/null 2>&1; then
            supervisorctl status "php${version}-fpm"
        else
            warning "PHP $version not found in supervisor"
        fi
    done
}

# Function to show socket files
show_sockets() {
    log "PHP-FPM Socket Files:"
    
    if [ -d "/run/php" ]; then
        ls -la /run/php/ | grep -E "\.(sock|pid)$" || echo "No socket files found"
    else
        warning "Socket directory /run/php does not exist"
    fi
}

# Function to show log files
show_logs() {
    local version="$1"
    
    if [ -n "$version" ]; then
        # Show logs for specific version
        log "PHP $version FPM logs:"
        echo "--- Error log ---"
        if [ -f "/var/log/php${version}-fpm.log" ]; then
            tail -20 "/var/log/php${version}-fpm.log"
        else
            warning "Log file not found: /var/log/php${version}-fpm.log"
        fi
        
        echo "--- Access log ---"
        if [ -f "/var/log/php${version}-fpm.access.log" ]; then
            tail -10 "/var/log/php${version}-fpm.access.log"
        else
            warning "Access log not found: /var/log/php${version}-fpm.access.log"
        fi
    else
        # Show all log files
        log "Available PHP-FPM log files:"
        for version in "${PHP_VERSIONS[@]}"; do
            echo "--- PHP $version ---"
            if [ -f "/var/log/php${version}-fpm.log" ]; then
                echo "Error log: /var/log/php${version}-fpm.log"
                echo "Last error:"
                tail -1 "/var/log/php${version}-fpm.log" 2>/dev/null || echo "No errors"
            fi
            if [ -f "/var/log/php${version}-fpm.access.log" ]; then
                echo "Access log: /var/log/php${version}-fpm.access.log"
            fi
            echo ""
        done
    fi
}

# Function to restart PHP-FPM services
restart_services() {
    local version="$1"
    
    if [ -n "$version" ]; then
        # Restart specific version
        log "Restarting PHP $version FPM..."
        if supervisorctl restart "php${version}-fpm" >/dev/null 2>&1; then
            success "PHP $version FPM restarted"
        else
            error "Failed to restart PHP $version FPM"
        fi
    else
        # Restart all versions
        log "Restarting all PHP-FPM services..."
        for version in "${PHP_VERSIONS[@]}"; do
            log "Restarting php${version}-fpm..."
            if supervisorctl restart "php${version}-fpm" >/dev/null 2>&1; then
                echo "php${version}-fpm: stopped"
                echo "php${version}-fpm: started"
            else
                warning "Failed to restart php${version}-fpm"
            fi
        done
        success "All PHP-FPM services restarted"
    fi
}

# Function to test PHP-FPM configurations
test_configs() {
    log "Testing PHP-FPM configurations:"
    
    local errors=0
    for version in "${PHP_VERSIONS[@]}"; do
        local config_file="/etc/php/${version}/fpm/php-fpm.conf"
        if [ -f "$config_file" ]; then
            if php-fpm${version} -t >/dev/null 2>&1; then
                echo "✅ PHP $version configuration: OK"
            else
                echo "❌ PHP $version configuration: ERROR"
                ((errors++))
            fi
        else
            warning "PHP $version configuration file not found"
        fi
    done
    
    if [ $errors -eq 0 ]; then
        success "All PHP-FPM configurations are valid"
    else
        error "$errors configuration(s) have errors"
    fi
}

# Function to show PHP versions
show_versions() {
    log "Available PHP Versions:"
    
    for version in "${PHP_VERSIONS[@]}"; do
        local status="❌"
        local socket_status="❌"
        
        # Check if PHP is installed
        if command -v "php${version}" >/dev/null 2>&1; then
            status="✅ Installed"
        else
            status="❌ Not installed"
        fi
        
        # Check if socket exists
        if [ -S "/run/php/php${version}-fpm.sock" ]; then
            socket_status="✅"
        else
            socket_status="❌"
        fi
        
        echo "  PHP ${version}: ${status} (Socket: ${socket_status})"
    done
}

# Function to show comprehensive information
show_info() {
    log "PHP Environment Information:"
    
    echo "📍 Current default PHP version:"
    php --version | head -1
    
    echo ""
    echo "📁 PHP Configuration directories:"
    ls -la /etc/php/ 2>/dev/null || echo "PHP configuration directory not found"
    
    echo ""
    echo "🔌 Active PHP-FPM sockets:"
    local socket_count=0
    if [ -d "/run/php" ]; then
        echo "  Active sockets: $(find /run/php -name "*.sock" | wc -l)"
        find /run/php -name "*.sock" | while read socket; do
            echo "  - $socket"
        done
        socket_count=$(find /run/php -name "*.sock" | wc -l)
    fi
    
    echo ""
    echo "📊 Memory usage by PHP-FPM processes:"
    local total_memory=0
    if command -v ps >/dev/null 2>&1; then
        # Calculate total RSS memory for all PHP-FPM processes
        total_memory=$(ps aux | grep '[p]hp.*fpm' | awk '{sum += $6} END {print sum/1024}')
        echo "  Total RSS: ${total_memory} MB"
    else
        echo "  Unable to calculate memory usage (ps not available)"
    fi
}

# Function to show help
show_help() {
    echo "PHP-FPM Management Utility"
    echo "=========================="
    echo ""
    echo "Usage: $0 [command] [version]"
    echo ""
    echo "Commands:"
    echo "  status              Show status of all PHP-FPM services"
    echo "  sockets             List PHP-FPM socket files"
    echo "  logs [version]      Show log files (all or specific version)"
    echo "  restart [version]   Restart PHP-FPM services (all or specific version)"
    echo "  test                Test all PHP-FPM configurations"
    echo "  versions            Show available PHP versions"
    echo "  info                Show comprehensive PHP environment information"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status           # Show all PHP-FPM service status"
    echo "  $0 restart 8.1      # Restart only PHP 8.1 FPM"
    echo "  $0 logs 7.4         # Show logs for PHP 7.4"
    echo "  $0 sockets          # List all socket files"
    echo ""
    echo "Available PHP versions: ${PHP_VERSIONS[*]}"
}

# Main function
main() {
    local command="$1"
    local version="$2"
    
    case "$command" in
        "status"|"s")
            show_status
        ;;
        "sockets"|"sock")
            show_sockets
        ;;
        "logs"|"log"|"l")
            show_logs "$version"
        ;;
        "restart"|"r")
            restart_services "$version"
        ;;
        "test"|"t")
            test_configs
        ;;
        "versions"|"v")
            show_versions
        ;;
        "info"|"i")
            show_info
        ;;
        "help"|"h"|""|"--help")
            show_help
        ;;
        *)
            error "Unknown command: $command"
            echo ""
            show_help
            exit 1
        ;;
    esac
}

# Run main function
main "$@"
