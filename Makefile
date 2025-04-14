#########################################
#		Laravel Docker DevEnv			#
#########################################

# Variables
COMPOSE_OVERRIDE = docker-compose.override.yml
DOCKER_COMPOSE_OLD_COMMAND = docker-compose
DOCKER_COMPOSE_MODERN_COMMAND = docker compose
DOCKER_COMPOSE_COMMAND = $(shell if docker compose > /dev/null 2>&1; then echo $(DOCKER_COMPOSE_MODERN_COMMAND); else echo $(DOCKER_COMPOSE_OLD_COMMAND); fi)
DOCKER = docker
SCRIPTS_GENERATE_PHP_CONTAINERS = scripts/docker-compose-generator.sh

# User variables
USER_NAME = $(shell grep USER_NAME .env 2>/dev/null | cut -d '=' -f 2)
NETWORK_NAME = laravel-docker-devenv-network

# Colors
DEFAULT = \033[1;0m
BLUE = \033[1;96m
GREEN = \033[1;32m
RED = \033[1;31m
YELLOW = \033[1;33m

.PHONY: help up down stop start restart ps logs exec clean re build prune install update status

# Default target
.DEFAULT_GOAL := help

#########################################
# HELP                                  #
#########################################
help:
	@echo -e "$(BLUE)Laravel Docker Development Environment$(DEFAULT)"
	@echo -e ""
	@echo -e "$(BLUE)Usage:$(DEFAULT)"
	@echo -e "  make [command]"
	@echo -e ""
	@echo -e "$(BLUE)Container Management:$(DEFAULT)"
	@echo -e "  $(GREEN)up$(DEFAULT)          Create and start containers"
	@echo -e "  $(GREEN)down$(DEFAULT)        Stop and remove containers, networks, local images, and volumes"
	@echo -e "  $(GREEN)stop$(DEFAULT)        Stop containers"
	@echo -e "  $(GREEN)start$(DEFAULT)       Start containers"
	@echo -e "  $(GREEN)restart$(DEFAULT)     Restart containers"
	@echo -e "  $(GREEN)re$(DEFAULT)          Rebuild and restart all containers"
	@echo -e "  $(GREEN)build$(DEFAULT)       Rebuild all containers"
	@echo -e ""
	@echo -e "$(BLUE)Information:$(DEFAULT)"
	@echo -e "  $(GREEN)ps$(DEFAULT)          List containers"
	@echo -e "  $(GREEN)logs$(DEFAULT)        Show logs"
	@echo -e "  $(GREEN)status$(DEFAULT)      Show container status"
	@echo -e ""
	@echo -e "$(BLUE)Interaction:$(DEFAULT)"
	@echo -e "  $(GREEN)exec$(DEFAULT)        Login to container (usage: make exec workspace)"
	@echo -e "  $(GREEN)ssh$(DEFAULT)         SSH into workspace container"
	@echo -e ""
	@echo -e "$(BLUE)Maintenance:$(DEFAULT)"
	@echo -e "  $(GREEN)clean$(DEFAULT)       Remove all containers, networks, images, volumes, and $(COMPOSE_OVERRIDE)"
	@echo -e "  $(GREEN)prune$(DEFAULT)       Remove unused Docker data (containers, networks, images, volumes)"
	@echo -e "  $(GREEN)install$(DEFAULT)     Initial setup: copy env files and create directories"
	@echo -e "  $(GREEN)update$(DEFAULT)      Pull latest changes and rebuild containers"
	@echo -e ""

#########################################
# SETUP                                 #
#########################################
install:
	@echo -e "$(BLUE)Setting up Laravel Docker Development Environment$(DEFAULT)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Creating .env file from example...$(DEFAULT)"; \
		cp env.example .env; \
		echo "$(GREEN)Created .env file. Please edit it with your settings.$(DEFAULT)"; \
	else \
		echo "$(YELLOW).env file already exists$(DEFAULT)"; \
	fi
	@if [ ! -f sitesMap.yaml ]; then \
		echo "$(YELLOW)Creating sitesMap.yaml file from example...$(DEFAULT)"; \
		cp sitesMap.example.yaml sitesMap.yaml; \
		echo "$(GREEN)Created sitesMap.yaml file. Please add your site configurations.$(DEFAULT)"; \
	else \
		echo "$(YELLOW)sitesMap.yaml file already exists$(DEFAULT)"; \
	fi
	@echo -e "$(GREEN)Setup complete! Run 'make up' to start the environment.$(DEFAULT)"

#########################################
# CONTAINER MANAGEMENT                  #
#########################################
up:
	@echo -e "$(BLUE)Creating network$(DEFAULT)"
	@$(DOCKER) network inspect $(NETWORK_NAME) > /dev/null 2>&1 || $(DOCKER) network create $(NETWORK_NAME)
	@echo -e "$(BLUE)Generating docker-compose configuration$(DEFAULT)"
	@sh $(SCRIPTS_GENERATE_PHP_CONTAINERS)
	@echo -e "$(BLUE)Starting docker containers$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) up -d $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)Environment is now running!$(DEFAULT)"

stop:
	@echo -e "$(BLUE)Stopping containers$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) stop $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)Containers stopped$(DEFAULT)"

start:
	@echo -e "$(BLUE)Starting containers$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) start $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)Containers started$(DEFAULT)"

restart:
	@echo -e "$(BLUE)Restarting containers$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) restart $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)Containers restarted$(DEFAULT)"

build:
	@echo -e "$(BLUE)Rebuilding containers$(DEFAULT)"
	@sh $(SCRIPTS_GENERATE_PHP_CONTAINERS)
	@$(DOCKER_COMPOSE_COMMAND) build $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)Containers rebuilt$(DEFAULT)"

ps:
	@echo -e "$(BLUE)Listing containers$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) ps $(filter-out $@,$(MAKECMDGOALS))

logs:
	@echo -e "$(BLUE)Showing logs$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) logs -f $(filter-out $@,$(MAKECMDGOALS))

status:
	@echo -e "$(BLUE)Container Status:$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

#########################################
# INTERACTION                           #
#########################################
exec:
	@echo -e "$(BLUE)Executing command in container$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec -u $(USER_NAME) $(filter-out $@,$(MAKECMDGOALS)) zsh

ssh:
	@echo -e "$(BLUE)Connecting to workspace container$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec -u $(USER_NAME) workspace zsh

#########################################
# CLEANUP                               #
#########################################
down:
	@echo -e "$(BLUE)Stopping and removing containers, networks, local images, and volumes$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) down --volumes --remove-orphans --rmi local
	@rm -f $(COMPOSE_OVERRIDE)
	@echo -e "$(GREEN)Environment stopped and cleaned$(DEFAULT)"

clean:
	@echo -e "$(BLUE)Removing all containers, networks, images, volumes, and $(COMPOSE_OVERRIDE)$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) down -v --rmi all --remove-orphans
	@$(DOCKER) network rm $(NETWORK_NAME) 2>/dev/null || true
	@rm -f $(COMPOSE_OVERRIDE)
	@echo -e "$(GREEN)Environment completely cleaned$(DEFAULT)"

prune:
	@echo -e "$(BLUE)Pruning unused Docker resources$(DEFAULT)"
	@$(DOCKER) system prune -f
	@echo -e "$(GREEN)Docker system pruned$(DEFAULT)"

update:
	@echo -e "$(BLUE)Updating environment$(DEFAULT)"
	@git pull
	@$(MAKE) down
	@$(MAKE) up
	@echo -e "$(GREEN)Environment updated and restarted$(DEFAULT)"

re: down up

# This target allows passing arguments to docker-compose commands
%:
	@: