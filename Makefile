#########################################
# Makefile for setup docker container		#
#########################################

# Variables
COMPOSE_OVERRIDE = docker-compose.override.yml
DOCKER_COMPOSE_OLD_COMMAND = docker-compose
DOCKER_COMPOSE_MODERN_COMMAND = docker compose
DOCKER_COMPOSE_COMMAND = $(shell if docker compose > /dev/null 2>&1; then echo $(DOCKER_COMPOSE_MODERN_COMMAND); else echo $(DOCKER_COMPOSE_OLD_COMMAND); fi)
DOCKER=docker
SCRIPTS_GENERATE_PHP_CONTAINERS = scripts/docker-compose-generator.sh

USER_NAME = $(shell grep USER_NAME .env | cut -d '=' -f 2)
NETWORK_NAME = docker_network

# Colors
DEFAULT	= \033[1;0m
BLUE	= \033[1;96m
GREEN	= \033[1;32m

help:
	@echo "$(BLUE)Usage:$(DEFAULT)"
	@echo "  make [command]"
	@echo ""
	@echo "$(BLUE)Commands:$(DEFAULT)"
	@echo "  $(GREEN)up$(DEFAULT)          Create and start containers"
	@echo "  $(GREEN)down$(DEFAULT)        Stop and remove containers, networks, local images, and volumes"
	@echo "  $(GREEN)stop$(DEFAULT)        Stop containers"
	@echo "  $(GREEN)start$(DEFAULT)       Start containers"
	@echo "  $(GREEN)restart$(DEFAULT)     Restart containers"
	@echo "  $(GREEN)ps$(DEFAULT)          List containers"
	@echo "  $(GREEN)logs$(DEFAULT)        Show logs"
	@echo "  $(GREEN)exec$(DEFAULT)        Login to container"
	@echo "  $(GREEN)clean$(DEFAULT)       Remove all containers, networks, images, volumes, and $(COMPOSE_OVERRIDE)"
	@echo "  $(GREEN)re$(DEFAULT)          Restart all containers"
	@echo "  $(GREEN)help$(DEFAULT)        Show this message"


up:
	@echo "$(BLUE)Create network$(DEFAULT)"
	@$(DOCKER) network inspect $(NETWORK_NAME) > /dev/null 2>&1 || $(DOCKER) network create $(NETWORK_NAME)
	@echo "$(BLUE)Generate docker-compose.yml$(DEFAULT)"
	@sh $(SCRIPTS_GENERATE_PHP_CONTAINERS)
	@echo "$(BLUE)Start docker containers$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) up -d $(filter-out $@,$(MAKECMDGOALS))

stop:
	@echo "$(BLUE)Stop containers$(filter-out $@,$(MAKECMDGOALS))$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) stop $(filter-out $@,$(MAKECMDGOALS))

start:
	@echo "$(BLUE)Start containers$(filter-out $@,$(MAKECMDGOALS))$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) start $(filter-out $@,$(MAKECMDGOALS))

restart:
	@echo "$(BLUE)Restart containers$(filter-out $@,$(MAKECMDGOALS))$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) restart $(filter-out $@,$(MAKECMDGOALS))

ps:
	@echo "$(BLUE)List containers$(filter-out $@,$(MAKECMDGOALS))$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) ps $(filter-out $@,$(MAKECMDGOALS))

logs:
	@echo "$(BLUE)Show logs$(filter-out $@,$(MAKECMDGOALS))$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) logs -f $(filter-out $@,$(MAKECMDGOALS))

exec:
	@echo "$(BLUE)Execute command in container$(fileter-out $@,$(MAKECMDGOALS))$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec -u $(USER_NAME) $(filter-out $@,$(MAKECMDGOALS)) zsh

down:
	@echo "$(BLUE)Stop and remove containers, networks, local images, and volumes$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) down --volumes --remove-orphans --rmi local
	@rm -f $(COMPOSE_OVERRIDE)

clean:
	@echo "$(BLUE)Remove all containers, networks, images, volumes, and $(COMPOSE_OVERRIDE)(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) down -v --rmi all --remove-orphans
	@$(DOCKER) network rm $(NETWORK_NAME) || true
	@rm -f $(COMPOSE_OVERRIDE)

re: down up

%:
	@:

.PHONY: help up down stop start restart ps logs exec clean re