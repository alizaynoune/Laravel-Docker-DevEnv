#!/bin/bash

###############################################################################
# PHP-FPM Socket Permission Fix Script
# Part of Laravel Docker Development Environment v2.0
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
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

main() {
    log "Fixing PHP-FPM socket permissions for nginx access..."
    
    # Check if we're running as root
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
    
    # Check if sockets exist
    if [ ! -d "/run/php" ]; then
        error "PHP socket directory does not exist"
        exit 1
    fi
    
    # Count sockets
    SOCKET_COUNT=$(find /run/php -name "*.sock" | wc -l)
    
    if [ "$SOCKET_COUNT" -eq 0 ]; then
        warning "No PHP-FPM sockets found"
        exit 0
    fi
    
    log "Found $SOCKET_COUNT PHP-FPM socket(s)"
    
    # Fix permissions
    find /run/php -name "*.sock" -exec chmod 666 {} \;
    
    success "Fixed permissions for $SOCKET_COUNT socket(s)"
    
    # Show current permissions
    log "Current socket permissions:"
    ls -la /run/php/*.sock 2>/dev/null | while read line; do
        echo "  $line"
    done
    
    success "Socket permission fix completed"
}

# Run main function
main "$@"
