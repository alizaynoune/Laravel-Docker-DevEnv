#########################################
#		Laravel Docker DevEnv v2.0		#
#########################################

# Variables
DOCKER_COMPOSE_OLD_COMMAND = docker-compose
DOCKER_COMPOSE_MODERN_COMMAND = docker compose
DOCKER_COMPOSE_COMMAND = $(shell if docker compose > /dev/null 2>&1; then echo $(DOCKER_COMPOSE_MODERN_COMMAND); else echo $(DOCKER_COMPOSE_OLD_COMMAND); fi)
DOCKER = docker

# Load environment variables
ifneq (,$(wildcard .env))
	include .env
endif

# User variables from .env
NETWORK_NAME = laravel-docker-devenv-network
PROJECT_NAME = laravel-devenv

# Colors
DEFAULT = \033[1;0m
BLUE = \033[1;96m
GREEN = \033[1;32m
RED = \033[1;31m
YELLOW = \033[1;33m
PURPLE = \033[1;35m

.PHONY: help up down stop start restart ps logs exec clean re build prune install update status ssh workspace mysql redis nginx php-versions generate-services

# Default target
.DEFAULT_GOAL := help

#########################################
# HELP                                  #
#########################################
help:
	@echo -e "$(BLUE)╔══════════════════════════════════════════════════════════════════════╗$(DEFAULT)"
	@echo -e "$(BLUE)║                Laravel Docker Development Environment v2.0           ║$(DEFAULT)"
	@echo -e "$(BLUE)║                    Multi-PHP Laravel Development Stack               ║$(DEFAULT)"
	@echo -e "$(BLUE)╚══════════════════════════════════════════════════════════════════════╝$(DEFAULT)"
	@echo -e ""
	@echo -e "$(BLUE)📋 Container Management:$(DEFAULT)"
	@echo -e "  $(GREEN)up$(DEFAULT)              Create and start all containers"
	@echo -e "  $(GREEN)down$(DEFAULT)            Stop and remove containers, networks, local images, and volumes"
	@echo -e "  $(GREEN)stop$(DEFAULT)            Stop all containers"
	@echo -e "  $(GREEN)start$(DEFAULT)           Start all containers"
	@echo -e "  $(GREEN)restart$(DEFAULT)         Restart all containers"
	@echo -e "  $(GREEN)re$(DEFAULT)              Rebuild and restart all containers"
	@echo -e "  $(GREEN)build$(DEFAULT)           Rebuild all containers"
	@echo -e ""
	@echo -e "$(BLUE)📊 Information & Monitoring:$(DEFAULT)"
	@echo -e "  $(GREEN)ps$(DEFAULT)              List all containers"
	@echo -e "  $(GREEN)logs$(DEFAULT)            Show logs for all services"
	@echo -e "  $(GREEN)status$(DEFAULT)          Show detailed container status"
	@echo -e "  $(GREEN)php-versions$(DEFAULT)    Show available PHP versions"
	@echo -e "  $(GREEN)project-status$(DEFAULT)  Show comprehensive project status"
	@echo -e ""
	@echo -e "$(BLUE)🔧 Service Access:$(DEFAULT)"
	@echo -e "  $(GREEN)workspace$(DEFAULT)       Access workspace container (main development environment)"
	@echo -e "  $(GREEN)ssh$(DEFAULT)             SSH into workspace container"
	@echo -e "  $(GREEN)exec$(DEFAULT)            Execute command in container (usage: make exec CONTAINER)"
	@echo -e "  $(GREEN)mysql$(DEFAULT)           Access MySQL console"
	@echo -e "  $(GREEN)redis$(DEFAULT)           Access Redis console"
	@echo -e ""
	@echo -e "$(BLUE)⚙️  Configuration & Maintenance:$(DEFAULT)"
	@echo -e "  $(GREEN)install$(DEFAULT)         Initial setup: copy env files and create directories"
	@echo -e "  $(GREEN)generate-services$(DEFAULT) Generate optional services based on .env configuration"
	@echo -e "  $(GREEN)update$(DEFAULT)          Pull latest changes and rebuild containers"
	@echo -e "  $(GREEN)clean$(DEFAULT)           Remove all containers, networks, images and volumes"
	@echo -e "  $(GREEN)prune$(DEFAULT)           Remove unused Docker data"
	@echo -e ""
	@echo -e "$(BLUE)🌐 Web Access:$(DEFAULT)"
	@echo -e "  $(YELLOW)Applications:$(DEFAULT)     http://your-app.local (configure in sitesMap.yaml)"
	@echo -e "  $(YELLOW)PHPMyAdmin:$(DEFAULT)       http://localhost:$(PHPMYADMIN_PORT)"
	@echo -e "  $(YELLOW)MailHog:$(DEFAULT)          http://localhost:$(MAILHOG_WEB_PORT)"
	@echo -e "  $(YELLOW)Workspace SSH:$(DEFAULT)    ssh $(USER_NAME)@localhost -p $(WORKSPACE_SSH_PORT)"
	@echo -e ""

#########################################
# SETUP                                 #
#########################################
install:
	@echo -e "$(BLUE)🚀 Setting up Laravel Docker Development Environment v2.0$(DEFAULT)"
	@echo -e "$(BLUE)════════════════════════════════════════════════════════$(DEFAULT)"
	@if [ ! -f .env ]; then \
		echo -e "$(YELLOW)📝 Creating .env file from example...$(DEFAULT)"; \
		cp env.example .env; \
		sed -i "s/USER_UID=.*/USER_UID=$$(id -u)/" .env; \
		sed -i "s/USER_GID=.*/USER_GID=$$(id -g)/" .env; \
		echo -e "$(GREEN)✅ Created .env file. Please edit it with your settings.$(DEFAULT)"; \
	else \
		echo -e "$(YELLOW)📝 .env file already exists$(DEFAULT)"; \
	fi
	@if [ ! -f sitesMap.yaml ]; then \
		echo -e "$(YELLOW)🗺️  Creating sitesMap.yaml file from example...$(DEFAULT)"; \
		cp sitesMap.example.yaml sitesMap.yaml; \
		echo -e "$(GREEN)✅ Created sitesMap.yaml file. Please add your site configurations.$(DEFAULT)"; \
	else \
		echo -e "$(YELLOW)🗺️  sitesMap.yaml file already exists$(DEFAULT)"; \
	fi
# 	add method or alias to .zshrc for run the make command from any location

	@echo -e "$(YELLOW)📁 Creating data directories...$(DEFAULT)"
	@mkdir -p $(MYSQL_DATA_DIR) $(REDIS_DATA_DIR)
	@echo -e "$(GREEN)✅ Data directories created$(DEFAULT)"
	@echo -e "$(BLUE)════════════════════════════════════════════════════════$(DEFAULT)"
	@echo -e "$(GREEN)🎉 Setup complete!$(DEFAULT)"
	@echo -e "$(BLUE)Next steps:$(DEFAULT)"
	@echo -e "  1. Edit .env file with your settings"
	@echo -e "  2. Edit sitesMap.yaml with your projects"
	@echo -e "  3. Run 'make up' to start the environment"
	@echo -e ""

generate-services:
	@echo -e "$(BLUE)⚙️  Generating optional services from .env configuration...$(DEFAULT)"
	@chmod +x scripts/docker-compose-generator.sh
	@./scripts/docker-compose-generator.sh
	@echo -e "$(GREEN)✅ Optional services generated successfully!$(DEFAULT)"

#########################################
# CONTAINER MANAGEMENT                  #
#########################################
up: generate-services
	@echo -e "$(BLUE)🐋 Creating Docker network...$(DEFAULT)"
	@$(DOCKER) network inspect $(NETWORK_NAME) > /dev/null 2>&1 || $(DOCKER) network create $(NETWORK_NAME)
	@echo -e "$(BLUE)🚀 Starting Docker containers...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) up -d $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)✅ Environment is now running!$(DEFAULT)"
	@echo -e ""
	@echo -e "$(BLUE)🌐 Access URLs:$(DEFAULT)"
	@echo -e "  $(YELLOW)PHPMyAdmin:$(DEFAULT)       http://localhost:$(PHPMYADMIN_PORT)"
	@echo -e "  $(YELLOW)MailHog:$(DEFAULT)          http://localhost:$(MAILHOG_WEB_PORT)"
	@echo -e "  $(YELLOW)Workspace SSH:$(DEFAULT)    ssh $(USER_NAME)@localhost -p $(WORKSPACE_SSH_PORT)"
	@echo -e ""
	@echo -e "$(BLUE)💡 Tip:$(DEFAULT) Use 'make workspace' to access the development environment"

stop:
	@echo -e "$(BLUE)🛑 Stopping containers...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) stop $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)✅ Containers stopped$(DEFAULT)"

start:
	@echo -e "$(BLUE)▶️  Starting containers...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) start $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)✅ Containers started$(DEFAULT)"

restart:
	@echo -e "$(BLUE)🔄 Restarting containers...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) restart $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)✅ Containers restarted$(DEFAULT)"

build:
	@echo -e "$(BLUE)🏗️  Rebuilding containers...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) build $(filter-out $@,$(MAKECMDGOALS))
	@echo -e "$(GREEN)✅ Containers rebuilt$(DEFAULT)"

ps:
	@echo -e "$(BLUE)📋 Container Status:$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) ps $(filter-out $@,$(MAKECMDGOALS))

logs:
	@echo -e "$(BLUE)📜 Showing logs...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) logs -f $(filter-out $@,$(MAKECMDGOALS))

status:
	@echo -e "$(BLUE)📊 Detailed Container Status:$(DEFAULT)"
	@echo -e "$(BLUE)════════════════════════════════════════════════════════$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo -e ""
	@echo -e "$(BLUE)💾 Volume Usage:$(DEFAULT)"
	@docker volume ls | grep $(PROJECT_NAME) || echo "No project volumes found"
	@echo -e ""
	@echo -e "$(BLUE)🌐 Network Information:$(DEFAULT)"
	@docker network ls | grep $(NETWORK_NAME) || echo "Network not found"

#########################################
# SERVICE ACCESS                        #
#########################################
workspace:
	@echo -e "$(BLUE)🖥️  Accessing workspace container...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec -u $(USER_NAME) workspace zsh

ssh:
	@echo -e "$(BLUE)🔗 Connecting to workspace via SSH...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec -u $(USER_NAME) workspace zsh

exec:
	@echo -e "$(BLUE)⚡ Executing command in container...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec -u $(USER_NAME) $(filter-out $@,$(MAKECMDGOALS)) zsh

mysql:
	@echo -e "$(BLUE)🗄️  Connecting to MySQL console...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec mysql mysql -u$(MYSQL_USERNAME) -p$(MYSQL_PASSWORD) $(MYSQL_DATABASE)

redis:
	@echo -e "$(BLUE)🔴 Connecting to Redis console...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec redis redis-cli

nginx:
	@echo -e "$(BLUE)🌐 Accessing Nginx container...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) exec nginx sh

#########################################
# INFORMATION                           #
#########################################
php-versions:
	@echo -e "$(BLUE)🐘 Available PHP Versions:$(DEFAULT)"
	@echo -e "$(BLUE)════════════════════════════════════════════════════════$(DEFAULT)"
	@echo -e "$(GREEN)✅ Supported PHP Versions:$(DEFAULT)"
	@echo -e "  🔹 PHP 7.0 - Legacy support"
	@echo -e "  🔹 PHP 7.1 - Legacy support"
	@echo -e "  🔹 PHP 7.2 - Legacy support"
	@echo -e "  🔹 PHP 7.3 - Legacy support"
	@echo -e "  🔹 PHP 7.4 - LTS support"
	@echo -e "  🔹 PHP 8.0 - Legacy support"
	@echo -e "  🔹 PHP 8.1 - LTS support"
	@echo -e "  🔹 PHP 8.2 - Current stable"
	@echo -e "  🔹 PHP 8.3 - Latest stable"
	@echo -e ""
	@echo -e "$(BLUE)💡 Usage:$(DEFAULT)"
	@echo -e "  - Configure services in .env (ENABLE_MYSQL, ENABLE_REDIS, etc.)"
	@echo -e "  - Run 'make generate-services' to create optional service containers"
	@echo -e "  - Use 'php70', 'php81', etc. in workspace to switch versions"

project-status:
	@chmod +x scripts/project-status.sh
	@./scripts/project-status.sh

#########################################
# CLEANUP                               #
#########################################
down:
	@echo -e "$(BLUE)🛑 Stopping and removing containers, networks, local images, and volumes...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) down --volumes --remove-orphans --rmi local
	@echo -e "$(GREEN)✅ Environment stopped and cleaned$(DEFAULT)"

clean:
	@echo -e "$(BLUE)🧹 Removing all containers, networks, images and volumes...$(DEFAULT)"
	@$(DOCKER_COMPOSE_COMMAND) down -v --rmi all --remove-orphans
	@$(DOCKER) network rm $(NETWORK_NAME) 2>/dev/null || true
	@echo -e "$(GREEN)✅ Environment completely cleaned$(DEFAULT)"

prune:
	@echo -e "$(BLUE)🗑️  Pruning unused Docker resources...$(DEFAULT)"
	@$(DOCKER) system prune -f
	@$(DOCKER) volume prune -f
	@$(DOCKER) network prune -f
	@echo -e "$(GREEN)✅ Docker system pruned$(DEFAULT)"

update:
	@echo -e "$(BLUE)📥 Updating environment...$(DEFAULT)"
	@git pull
	@$(MAKE) down
	@$(MAKE) build
	@$(MAKE) up
	@echo -e "$(GREEN)✅ Environment updated and restarted$(DEFAULT)"

re:
	@$(MAKE) down
	@$(MAKE) up

#########################################
# UTILITY TARGETS                       #
#########################################

# This target allows passing arguments to docker-compose commands
%:
	@:
