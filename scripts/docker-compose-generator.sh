#!/bin/sh

BASEDIR=$(dirname "$0")
ROOT_DIR=$(echo "$BASEDIR" | sed 's/scripts//')
SITES_MAP_FILE=$ROOT_DIR"sitesMap.yaml"
DOCKER_COMPOSE_FILE=$ROOT_DIR"docker-compose.override.yml"
# Assign PHP_VERSION from the .env file or set the default value as 8.0
DEFAULT_PHP=$(grep DEFAULT_PHP "$ROOT_DIR".env | cut -d '=' -f2)
DEFAULT_PHP=${DEFAULT_PHP:-8.0}


# Check if the sitesMap.yaml file exists
if [ ! -f "$SITES_MAP_FILE" ]; then
  echo "sitesMap.yaml file not found."
  exit 1
fi

# remove the docker-compose.override.yml file if it exists
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
  rm "$DOCKER_COMPOSE_FILE"
fi

echo "Generating docker-compose.override.yml file..."

awk '
  BEGIN {
    print "########################################################################"
    print "# This file is generated automatically. Do not edit it manually.       #"
    print "# Any changes made to this file will be lost when the `make build` is  #"
    print "# executed.                                                            #"
    print "# Instead, edit the sitesMap.yaml file and run the script again.       #"
    print "#                                                                      #"
    print "# This file is used to add PHP services to the docker-compose.yml file #"
    print "# based on the PHP versions specified in the sitesMap.yaml file.       #"
    print "########################################################################"
    print ""
    print "########################################################################"
    print "#              Default PHP service configuration                       #"
    print "########################################################################"
    print "x-php: &default-php"
    print "  volumes:"
    print "    - app-data:${DESTINATION_DIR}:rw"
    print "    - ./docker/supervisor/conf.d:/etc/supervisor/conf.d:rw"
    print "    - ./docker/ssh:/home/${USER_NAME}/.ssh:rw"
    print "    - ./docker/scripts/php.entrypoint.sh:/entrypoint.sh:ro"
    print "  command: /entrypoint.sh"
    print "  networks:"
    print "    - laravel-docker-devenv-network"
    print "  extra_hosts:"
  }
' > "$DOCKER_COMPOSE_FILE"

    #loop through the hosts and add them to the docker-compose.override.yml file
    yq -r '.sites[] | .map' "$SITES_MAP_FILE" | while IFS= read -r line; do
      echo "    - $line:172.19.0.30" >> "$DOCKER_COMPOSE_FILE"
    done

awk '
  BEGIN {
    print "  tty: true"
    print "  restart: unless-stopped"
    print "  working_dir: ${DESTINATION_DIR}"
    print "  deploy:"
    print "    resources:"
    print "      limits:"
    print "        cpus: \"2\""
    print ""
    print "########################################################################"
    print "#              Default arguments configuration                         #"
    print "########################################################################"
    print "x-app-args: &default-args"
    print "  USER_UID: ${USER_UID}"
    print "  USER_GID: ${USER_GID}"
    print "  USER_NAME: ${USER_NAME}"
    print "  USER_PASSWORD: ${USER_PASSWORD}"
    print "  ROOT_PASSWORD: ${ROOT_PASSWORD}"
    print ""
    print "########################################################################"
    print "#              PHP services configuration                              #"
    print "########################################################################"
    print "services:"
  }
' >> "$DOCKER_COMPOSE_FILE"

add_php_service() {
  PHP_VERSION=$1
  # remove dots from the PHP version to use it as a service name
  SERVICE_NAME="php"$(echo "$PHP_VERSION" | sed 's/\.//g')

  # Check if the service already exists in docker-compose.override.yml
  if grep -q "^\s*$SERVICE_NAME:" "$DOCKER_COMPOSE_FILE"; then
    echo "Service $SERVICE_NAME already exists in docker-compose.override.yml. No changes made."
  else
    echo "Adding service $SERVICE_NAME to docker-compose.override.yml"

    # Temporary file to store the updated docker-compose.override.yml
    TEMP_FILE=$(mktemp)

    ####################################################################
    #             PHP 8.2 service configuration                        #
    ####################################################################

    # Append the new service after the "services:" line
    awk -v service_name="$SERVICE_NAME" -v php_version="$PHP_VERSION" '
        /^services:/ {
            print;
            print "    ####################################################################";
            print "    #                " service_name " service configuration                       #";
            print "    ####################################################################";
            print "    " service_name ":";
            print "        <<: *default-php";
            print "        build:";
            print "            context: ./";
            print "            dockerfile: docker/php.Dockerfile";
            print "            args:";
            print "                <<: *default-args";
            print "                PHP_VERSION: \"" php_version "\"";
            print "        container_name: " service_name;
            print "        hostname: " service_name;
            print "        depends_on:";
            print "            - workspace";
            next
        }
        { print }
    ' "$DOCKER_COMPOSE_FILE" > "$TEMP_FILE"

    # Replace the original docker-compose.override.yml with the updated one
    mv "$TEMP_FILE" "$DOCKER_COMPOSE_FILE"
  fi
}

# add default PHP service
add_php_service "$DEFAULT_PHP"

# Loop through the sitesMap.yaml file and add PHP services to the docker-compose.override.yml file
yq -r '.sites[] | [.php] | @sh' "$SITES_MAP_FILE" | while IFS= read -r line; do
  # Read the values into variables
  eval "set -- $line"
  PHP_VERSION=$1
  SERVICE_NAME="php"$(echo "$PHP_VERSION" | sed 's/\.//g')

  add_php_service "$PHP_VERSION"
done




