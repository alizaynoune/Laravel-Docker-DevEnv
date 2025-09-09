#!/bin/bash

#########################################
#   Docker Compose Generator Script v2.1 #
#########################################

set -e

# Constants and derived paths
SCRIPT_DIR=$(dirname "$0")
ROOT_DIR=$(realpath "$SCRIPT_DIR/..")
SITES_MAP_FILE="$ROOT_DIR/sitesMap.yaml"
DOCKER_COMPOSE_OVERRIDE="$ROOT_DIR/docker-compose.override.yml"
ENV_FILE="$ROOT_DIR/.env"
# Determine the Docker Compose command to use (docker-compose or docker compose)
DOCKER_COMPOSE_CMD=$(command -v docker-compose >/dev/null 2>&1 && echo "docker-compose" || echo "docker compose")


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner function for better visual separation
print_banner() {
    echo "########################################################################"
    echo "# $1"
    printf '%0.s#' $(seq 1 72)
    echo ""
}

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

# Error handling function
handle_error() {
    error "$1"
    exit 1
}

# Load configuration from .env file
load_config() {
    log "Loading configuration from .env file..."

    if [ ! -f "$ENV_FILE" ]; then
        handle_error "Environment file (.env) not found. Please run 'make install' first."
    fi

    # Load environment variables
    export $(grep -v '^#' "$ENV_FILE" | xargs)

    # Set defaults if not specified
    ENABLE_MYSQL=${ENABLE_MYSQL:-true}
    ENABLE_PHPMYADMIN=${ENABLE_PHPMYADMIN:-true}
    ENABLE_REDIS=${ENABLE_REDIS:-true}
    ENABLE_MAILHOG=${ENABLE_MAILHOG:-true}

    # IF all services are disabled remove docker-compose.override.yml and exit
    if [ "$ENABLE_MYSQL" = "false" ] && [ "$ENABLE_PHPMYADMIN" = "false" ] && [ "$ENABLE_REDIS" = "false" ] && [ "$ENABLE_MAILHOG" = "false" ]; then
        if [ -f "$DOCKER_COMPOSE_OVERRIDE" ]; then
            log "All services are disabled. Removing docker-compose.override.yml"
            rm -f "$DOCKER_COMPOSE_OVERRIDE"
        fi
        success "No services enabled. Exiting without generating docker-compose.override.yml."
        exit 0
    fi

    success "Configuration loaded successfully"
    log "Service status - MySQL: $ENABLE_MYSQL, PHPMyAdmin: $ENABLE_PHPMYADMIN, Redis: $ENABLE_REDIS, MailHog: $ENABLE_MAILHOG"
}

# Generate docker-compose override header
generate_header() {
    log "Generating docker-compose.override.yml header..."

    cat > "$DOCKER_COMPOSE_OVERRIDE" <<EOF
########################################################################
# AUTOMATICALLY GENERATED FILE - DO NOT EDIT MANUALLY                  #
########################################################################
# This file is generated automatically by the docker-compose-generator.sh
# script based on your .env configuration and optional services.
#
# Any changes made directly to this file will be overwritten when the
# script is executed again.
#
# To modify services:
#   1. Edit .env file (ENABLE_* variables)
#   2. Run: make build
#   3. Run: make up
#
# Generated on: $(date)
########################################################################

########################################################################
#              Conditional Services (auto-generated)                   #
########################################################################
services:
EOF
}

# Add MySQL service if enabled
add_mysql_service() {
    if [ "$ENABLE_MYSQL" = "true" ]; then
        log "Adding MySQL service"
        cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF

  ####################################################################
  #                     MySQL Database                              #
  ####################################################################
  mysql:
    image: mysql:8.0
    container_name: mysql
    restart: unless-stopped
    hostname: mysql
    ports:
      - "\${MYSQL_PORT}:3306"
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
      MYSQL_USER: \${MYSQL_USERNAME}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
      TZ: \${TZ}
    volumes:
      - mysql-data:/var/lib/mysql
      - ./docker/db/mysql/my.cnf:/etc/mysql/conf.d/my.cnf:ro
    command: --default-authentication-plugin=mysql_native_password
    networks:
      - laravel-docker-devenv-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p\$\$MYSQL_ROOT_PASSWORD"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
EOF
    else
        log "MySQL service disabled"
    fi
}

# Add Redis service if enabled
add_redis_service() {
    if [ "$ENABLE_REDIS" = "true" ]; then
        log "Adding Redis service"
        cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF

  ####################################################################
  #                     Redis Cache                                  #
  ####################################################################
  redis:
    image: redis:alpine
    container_name: redis
    restart: unless-stopped
    hostname: redis
    ports:
      - "\${REDIS_PORT}:6379"
    volumes:
      - redis-data:/data
      - ./docker/db/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
    command: redis-server /usr/local/etc/redis/redis.conf \${REDIS_ARGS}
    networks:
      - laravel-docker-devenv-network
    environment:
      - TZ=\${TZ}
    deploy:
      resources:
        limits:
          cpus: "2"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
EOF
    else
        log "Redis service disabled"
    fi
}

# Add MailHog service if enabled
add_mailhog_service() {
    if [ "$ENABLE_MAILHOG" = "true" ]; then
        log "Adding MailHog service"
        cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF

  ####################################################################
  #                     MailHog (Email Testing)                      #
  ####################################################################
  mailhog:
    image: mailhog/mailhog:latest
    container_name: mailhog
    restart: unless-stopped
    hostname: mailhog
    ports:
      - "\${MAILHOG_SMTP_PORT}:1025"  # SMTP
      - "\${MAILHOG_WEB_PORT}:8025"    # Web UI
    networks:
      - laravel-docker-devenv-network
    environment:
      - TZ=\${TZ}
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8025/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
EOF
    else
        log "MailHog service disabled"
    fi
}

# Add volume definitions
add_volumes() {
    log "Adding volume definitions for enabled services..."

    cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF

########################################################################
#              Conditional Volumes (auto-generated)                    #
########################################################################
volumes:
EOF

    if [ "$ENABLE_MYSQL" = "true" ]; then
        cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF
  # MySQL data persistence
  mysql-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: \${MYSQL_DATA_DIR}
EOF
    fi

    if [ "$ENABLE_REDIS" = "true" ]; then
        cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF
  # Redis data persistence
  redis-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: \${REDIS_DATA_DIR}
EOF
    fi
}

# Main function
main() {
    print_banner "Laravel Docker Development Environment - Service Generator v2.1"

    log "Starting Docker Compose override generation..."

    # Run all setup functions
    load_config
    generate_header
    add_mysql_service
    add_redis_service
    add_mailhog_service
    add_volumes

    success "Docker Compose override file generated successfully!"
    log "Generated file: $DOCKER_COMPOSE_OVERRIDE"

    # Validate generated docker-compose file
    log "Validating generated Docker Compose configuration..."
    if $DOCKER_COMPOSE_CMD -f docker-compose.yml -f docker-compose.override.yml config > /dev/null 2>&1; then
        success "Docker Compose configuration is valid!"
    else
        warning "Docker Compose configuration validation failed. Please check the generated file."
        return 1
    fi

    log "To start the environment, run: make up"
}

# Run main function
main "$@"
