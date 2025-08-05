#!/bin/bash

########################################################################
# Laravel Docker Development Environment - Workspace Entrypoint
########################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# User configuration
USER_NAME="docker"
USER_UID=1000
USER_GID=1000
USER_HOME="/home/${USER_NAME}"

# Setup SSH keys
setup_ssh_keys() {
    log "Setting up SSH keys for user: ${USER_NAME}"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "${USER_HOME}/.ssh"
    
    # Generate SSH key if it doesn't exist
    if [ ! -f "${USER_HOME}/.ssh/id_rsa" ]; then
        log "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "${USER_HOME}/.ssh/id_rsa" -N "" -C "${USER_NAME}@workspace"
        success "SSH key pair generated"
    fi
    
    # Set proper SSH permissions
    chmod 700 "${USER_HOME}/.ssh"
    chmod 600 "${USER_HOME}/.ssh"/* 2>/dev/null || true
    
    # Add localhost to known_hosts to prevent SSH prompts
    ssh-keyscan -H localhost >> "${USER_HOME}/.ssh/known_hosts" 2>/dev/null || true
    
    success "SSH keys configured"
}

# Set proper permissions
set_permissions() {
    log "Setting proper permissions..."
    
    # Set ownership of user home directory
    chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME}"
    
    success "Permissions set successfully"
}

# Start SSH daemon
start_ssh() {
    log "Starting SSH daemon..."
    
    # Generate SSH host keys if they don't exist
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A
    fi
    
    # Start SSH daemon in background
    /usr/sbin/sshd
    
    success "SSH daemon started"
}

# Generate nginx sites and start nginx
setup_nginx() {
    log "Setting up nginx and PHP-FPM..."
    
    # Create PHP-FPM socket directory
    mkdir -p /run/php
    chown www-data:docker /run/php
    chmod 755 /run/php
    
    # Configure PHP pools for all versions
    log "Configuring PHP-FPM pools for all versions..."
    /usr/local/bin/configure-php-pools.sh
    
    # Generate nginx site configurations if sitesMap.yaml exists
    if [ -f "/var/www/sitesMap.yaml" ]; then
        log "Generating nginx site configurations from sitesMap.yaml..."
        /usr/local/bin/generate-sites.sh
        success "Nginx site configurations generated"
    else
        warning "sitesMap.yaml not found, skipping site generation"
    fi
    
    # Test nginx configuration
    if nginx -t > /dev/null 2>&1; then
        success "Nginx configuration test passed"
    else
        error "Nginx configuration test failed"
        nginx -t
    fi
}

# Start supervisor
start_supervisor() {
    log "Starting Supervisor..."
    
    # Start supervisor in background
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
    
    success "Supervisor started"
    
    # Wait a moment for PHP-FPM services to start
    sleep 3
    
    # Fix socket permissions for nginx access
    log "Fixing PHP-FPM socket permissions..."
    find /run/php -name "*.sock" -exec chmod 666 {} \; 2>/dev/null || true
    success "Socket permissions fixed"
}

# Main setup
main() {
    log "Initializing workspace container..."
    
    # Run setup functions
    # setup_ssh_keys
    # set_permissions
    # start_ssh
    setup_nginx
    start_supervisor
    
    success "Workspace container initialized successfully!"
    
    # Keep container running
    if [ "$#" -eq 0 ]; then
        log "Starting interactive shell..."
        # Switch to the docker user and start zsh
        exec su - "${USER_NAME}" -s /bin/zsh
    else
        log "Executing command: $*"
        exec "$@"
    fi
}

# Run main function
main "$@"
    log "Setting proper permissions..."

    # Set ownership of user home directory
    chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME}"

    success "Permissions set successfully"
}

# Start SSH daemon
start_ssh() {
    log "Starting SSH daemon..."

    # Generate SSH host keys if they don't exist
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A
    fi

    # Start SSH daemon in background
    /usr/sbin/sshd

    success "SSH daemon started"
}

# Generate nginx sites and start nginx
setup_nginx() {
    log "Setting up nginx and PHP-FPM..."

    # Create PHP-FPM socket directory
    mkdir -p /run/php
    chown www-data:docker /run/php
    chmod 755 /run/php

    # Configure PHP pools for all versions
    log "Configuring PHP-FPM pools for all versions..."
    /usr/local/bin/configure-php-pools.sh

    # Generate nginx site configurations if sitesMap.yaml exists
    if [ -f "/var/www/sitesMap.yaml" ]; then
        log "Generating nginx site configurations from sitesMap.yaml..."
        /usr/local/bin/generate-sites.sh
        success "Nginx site configurations generated"
    else
        warning "sitesMap.yaml not found, skipping site generation"
    fi

    # Test nginx configuration
    if nginx -t > /dev/null 2>&1; then
        success "Nginx configuration test passed"
    else
        error "Nginx configuration test failed"
        nginx -t
    fi
}

# Start supervisor
start_supervisor() {
    log "Starting Supervisor..."

    # Start supervisor in background
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

    success "Supervisor started"

    # Wait a moment for PHP-FPM services to start
    sleep 3

    # Fix socket permissions for nginx access
    log "Fixing PHP-FPM socket permissions..."
    find /run/php -name "*.sock" -exec chmod 666 {} \; 2>/dev/null || true
    success "Socket permissions fixed"
}

# Main setup
main() {
    log "Initializing workspace container..."

    # Run setup functions
    # setup_ssh_keys
    # set_permissions
    # start_ssh
    setup_nginx
    start_supervisor

    success "Workspace container initialized successfully!"

    # Keep container running
    if [ "$#" -eq 0 ]; then
        log "Starting interactive shell..."
        # Switch to the docker user and start zsh
        exec su - "${USER_NAME}" -s /bin/zsh
    else
        log "Executing command: $*"
        exec "$@"
    fi
}

# Run main function
main "$@"
