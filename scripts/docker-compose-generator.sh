#!/bin/sh

#########################################
#   Docker Compose Generator Script     #
#########################################

# Constants and derived paths
SCRIPT_DIR=$(dirname "$0")
ROOT_DIR=$(realpath "$SCRIPT_DIR/..")
SITES_MAP_FILE="$ROOT_DIR/sitesMap.yaml"
DOCKER_COMPOSE_OVERRIDE="$ROOT_DIR/docker-compose.override.yml"
ENV_FILE="$ROOT_DIR/.env"

# Banner function for better visual separation
print_banner() {
  echo "########################################################################"
  echo "# $1"
  printf '%0.s#' $(seq 1 72)
  echo ""
}

# Error handling function
handle_error() {
  echo "ERROR: $1" >&2
  exit 1
}

# Load default PHP version from .env
if [ -f "$ENV_FILE" ]; then
  DEFAULT_PHP=$(grep DEFAULT_PHP "$ENV_FILE" | cut -d '=' -f2)
  DEFAULT_PHP=${DEFAULT_PHP:-8.0} # Default to 8.0 if not specified
else
  handle_error "Environment file (.env) not found. Please run 'make install' first."
fi

# Check for required files
if [ ! -f "$SITES_MAP_FILE" ]; then
  handle_error "Sites map file (sitesMap.yaml) not found. Please run 'make install' first."
fi

# Check for required commands
command -v yq >/dev/null 2>&1 || handle_error "yq command not found. Please install yq (https://github.com/mikefarah/yq)"

echo "Generating docker-compose.override.yml file..."

# Create header for the docker-compose.override.yml file
cat > "$DOCKER_COMPOSE_OVERRIDE" <<EOF
########################################################################
# AUTOMATICALLY GENERATED FILE - DO NOT EDIT MANUALLY                  #
########################################################################
# This file is generated automatically by the docker-compose-generator.sh script.
# Any changes made directly to this file will be overwritten when the script
# is executed again.
# 
# To modify the PHP services, edit the sitesMap.yaml file and run:
# $ make build
########################################################################

########################################################################
#              Default PHP service configuration                       #
########################################################################
x-php: &default-php
  volumes:
    - app-data:\${DESTINATION_DIR}:rw
    - ./docker/supervisor/conf.d:/etc/supervisor/conf.d:rw
    - ./docker/ssh:/home/\${USER_NAME}/.ssh:rw
    - ./docker/scripts/php.entrypoint.sh:/entrypoint.sh:ro
  command: /entrypoint.sh
  networks:
    - laravel-docker-devenv-network
  extra_hosts:
EOF

# Add hosts to the docker-compose.override.yml file
yq -r '.sites[] | .map' "$SITES_MAP_FILE" | while IFS= read -r line; do
  if [ -n "$line" ]; then
    echo "    - $line:172.19.0.30" >> "$DOCKER_COMPOSE_OVERRIDE"
  fi
done

# Add default PHP service configuration
cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF
  tty: true
  restart: unless-stopped
  working_dir: \${DESTINATION_DIR}
  deploy:
    resources:
      limits:
        cpus: "2"

########################################################################
#              Default arguments configuration                         #
########################################################################
x-app-args: &default-args
  USER_UID: \${USER_UID}
  USER_GID: \${USER_GID}
  USER_NAME: \${USER_NAME}
  USER_PASSWORD: \${USER_PASSWORD}
  ROOT_PASSWORD: \${ROOT_PASSWORD}

########################################################################
#              PHP services configuration                              #
########################################################################
services:
EOF

# Function to add a PHP service to the docker-compose.override.yml file
add_php_service() {
  local PHP_VERSION=$1
  # Remove dots from PHP version for service name
  local SERVICE_NAME="php$(echo "$PHP_VERSION" | sed 's/\.//g')"

  # Check if the service already exists
  if grep -q "^\s*$SERVICE_NAME:" "$DOCKER_COMPOSE_OVERRIDE"; then
    echo "Service $SERVICE_NAME already exists in docker-compose.override.yml"
    return
  fi

  echo "Adding PHP $PHP_VERSION service ($SERVICE_NAME)"
  
  # Add service definition to docker-compose.override.yml
  cat >> "$DOCKER_COMPOSE_OVERRIDE" <<EOF

  ####################################################################
  #                $SERVICE_NAME service configuration                      #
  ####################################################################
  $SERVICE_NAME:
    <<: *default-php
    build:
      context: ./
      dockerfile: docker/php.Dockerfile
      args:
        <<: *default-args
        PHP_VERSION: "$PHP_VERSION"
    container_name: $SERVICE_NAME
    hostname: $SERVICE_NAME
    depends_on:
      - workspace
EOF
}

# Add default PHP service
add_php_service "$DEFAULT_PHP"

# Add PHP services for each site
echo "Processing sites from sitesMap.yaml..."
yq -r '.sites[] | select(.php != null) | .php' "$SITES_MAP_FILE" | sort | uniq | while IFS= read -r php_version; do
  if [ -n "$php_version" ]; then
    add_php_service "$php_version"
  fi
done

echo "Docker Compose override file generated successfully at $DOCKER_COMPOSE_OVERRIDE"




