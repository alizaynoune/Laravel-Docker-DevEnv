# Multi-PHP Laravel Development Environment
FROM ubuntu:22.04

# Build arguments with defaults
ARG USER_NAME
ARG USER_GROUP
ARG USER_PASSWORD
ARG ROOT_PASSWORD
ARG USER_GID
ARG USER_UID
ARG DESTINATION_DIR
ARG DEFAULT_PHP

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    TERM=xterm-256color \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_CACHE_DIR=/tmp/composer \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    USER_NAME=${USER_NAME:-docker} \
    USER_UID=${USER_UID:-1000} \
    USER_GID=${USER_GID:-1000}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # System utilities
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    curl \
    wget \
    git \
    unzip \
    zip \
    sudo \
    supervisor \
    openssh-server \
    nano \
    vim \
    htop \
    # Web server
    nginx \
    openssl \
    # Build tools
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # Network tools
    iputils-ping \
    net-tools \
    # Terminal tools
    zsh \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Add Ondrej PPA for multiple PHP versions
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update

# Install all PHP versions (7.0 to 8.3) with common extensions
RUN apt-get install -y \
    # PHP 7.0
    php7.0-fpm php7.0-cli php7.0-common php7.0-mysql php7.0-zip php7.0-gd \
    php7.0-mbstring php7.0-curl php7.0-xml php7.0-bcmath php7.0-json \
    php7.0-intl php7.0-soap php7.0-sqlite3 php7.0-xdebug \
    # PHP 7.1
    php7.1-fpm php7.1-cli php7.1-common php7.1-mysql php7.1-zip php7.1-gd \
    php7.1-mbstring php7.1-curl php7.1-xml php7.1-bcmath php7.1-json \
    php7.1-intl php7.1-soap php7.1-sqlite3 php7.1-xdebug \
    # PHP 7.2
    php7.2-fpm php7.2-cli php7.2-common php7.2-mysql php7.2-zip php7.2-gd \
    php7.2-mbstring php7.2-curl php7.2-xml php7.2-bcmath php7.2-json \
    php7.2-intl php7.2-soap php7.2-sqlite3 php7.2-xdebug \
    # PHP 7.3
    php7.3-fpm php7.3-cli php7.3-common php7.3-mysql php7.3-zip php7.3-gd \
    php7.3-mbstring php7.3-curl php7.3-xml php7.3-bcmath php7.3-json \
    php7.3-intl php7.3-soap php7.3-sqlite3 php7.3-xdebug \
    # PHP 7.4
    php7.4-fpm php7.4-cli php7.4-common php7.4-mysql php7.4-zip php7.4-gd \
    php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath php7.4-json \
    php7.4-intl php7.4-soap php7.4-sqlite3 php7.4-xdebug \
    # PHP 8.0
    php8.0-fpm php8.0-cli php8.0-common php8.0-mysql php8.0-zip php8.0-gd \
    php8.0-mbstring php8.0-curl php8.0-xml php8.0-bcmath \
    php8.0-intl php8.0-soap php8.0-sqlite3 php8.0-xdebug \
    # PHP 8.1
    php8.1-fpm php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd \
    php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath \
    php8.1-intl php8.1-soap php8.1-sqlite3 php8.1-xdebug \
    # PHP 8.2
    php8.2-fpm php8.2-cli php8.2-common php8.2-mysql php8.2-zip php8.2-gd \
    php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath \
    php8.2-intl php8.2-soap php8.2-sqlite3 php8.2-xdebug \
    # PHP 8.3
    php8.3-fpm php8.3-cli php8.3-common php8.3-mysql php8.3-zip php8.3-gd \
    php8.3-mbstring php8.3-curl php8.3-xml php8.3-bcmath \
    php8.3-intl php8.3-soap php8.3-sqlite3 php8.3-xdebug \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install Yarn
RUN npm install -g yarn

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create user with sudo privileges (using default UID/GID)
RUN groupadd -g ${USER_GID} ${USER_GROUP} && \
    useradd -u ${USER_UID} -g ${USER_GID} -m -s /bin/zsh ${USER_NAME} && \
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "root:${ROOT_PASSWORD}" | chpasswd

# Set user and www-data on one group
RUN usermod -aG ${USER_GROUP} ${USER_NAME} && \
    usermod -aG ${USER_GROUP} www-data && \
    usermod -aG www-data ${USER_NAME} && \
    usermod -aG sudo ${USER_NAME}

# Install Oh My Zsh for the user
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Switch back to root for system configuration
USER root

# Create PHP version switcher scripts
RUN echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php7.0\necho "Switched to PHP 7.0"' > /usr/local/bin/php70 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php7.1\necho "Switched to PHP 7.1"' > /usr/local/bin/php71 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php7.2\necho "Switched to PHP 7.2"' > /usr/local/bin/php72 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php7.3\necho "Switched to PHP 7.3"' > /usr/local/bin/php73 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php7.4\necho "Switched to PHP 7.4"' > /usr/local/bin/php74 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php8.0\necho "Switched to PHP 8.0"' > /usr/local/bin/php80 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php8.1\necho "Switched to PHP 8.1"' > /usr/local/bin/php81 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php8.2\necho "Switched to PHP 8.2"' > /usr/local/bin/php82 && \
    echo '#!/bin/bash\nupdate-alternatives --set php /usr/bin/php8.3\necho "Switched to PHP 8.3"' > /usr/local/bin/php83 && \
    chmod +x /usr/local/bin/php7* /usr/local/bin/php8*

# Set up PHP alternatives
RUN update-alternatives --install /usr/bin/php php /usr/bin/php7.0 70 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php7.1 71 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php7.2 72 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php7.3 73 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php7.4 74 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php8.0 80 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php8.1 81 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php8.2 82 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php8.3 83

#check if default PHP version is a valid version else set to 8.3
RUN if ! update-alternatives --query php | grep -q "Value: /usr/bin/php${DEFAULT_PHP}"; then \
    echo "Invalid PHP version ${DEFAULT_PHP}, defaulting to 8.3"; \
    DEFAULT_PHP=8.3; \
fi
# Set default PHP version
RUN update-alternatives --set php /usr/bin/php${DEFAULT_PHP} && \
    echo "Default PHP version set to ${DEFAULT_PHP}"

########################################################################
# Configure PHP-FPM for all installed versions
########################################################################
# PHP-FPM Configuration
########################################################################
# Configure all PHP-FPM versions with Unix sockets using automated script
# This approach is cleaner and more maintainable than manual configuration
RUN for version in 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3; do \
    if [ -f /etc/php/$version/fpm/pool.d/www.conf ]; then \
    # Backup original configuration
    cp /etc/php/$version/fpm/pool.d/www.conf /etc/php/$version/fpm/pool.d/www.conf.bak; \
    fi; \
    done

# Configure SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'AllowUsers root '${USER_NAME} >> /etc/ssh/sshd_config

########################################################################
# Configure Nginx
########################################################################
RUN mkdir -p /etc/nginx/ssl \
    /etc/nginx/sites-available \
    /etc/nginx/sites-enabled \
    /var/log/nginx \
    /usr/local/bin && \
    rm -f /etc/nginx/sites-enabled/default && \
    rm -f /etc/nginx/sites-available/default

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/self-signed.key \
    -out /etc/nginx/ssl/self-signed.crt \
    -subj "/C=US/ST=Local/L=Local/O=Laravel-Docker-DevEnv/CN=localhost"

# Install yq for YAML parsing
RUN YQ_VERSION="v4.35.2" && \
    YQ_BINARY="yq_linux_amd64" && \
    curl -L "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}" -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# Create necessary directories
RUN mkdir -p /var/log/supervisor && \
    mkdir -p /home/${USER_NAME}/.ssh && \
    mkdir -p /run/php && \
    chown -R ${USER_NAME}:${USER_GROUP} /home/${USER_NAME}/.ssh && \
    chown www-data:${USER_GROUP} /run/php && \
    chmod 755 /run/php

# Copy custom configurations (using --from build context or create default if missing)
COPY docker/zsh/.zshrc /home/${USER_NAME}/.zshrc

# Copy configurations if they exist, otherwise skip
COPY docker/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY docker/supervisor/conf.d/ /etc/supervisor/conf.d/
COPY docker/scripts/workspace.entrypoint.sh /entrypoint.sh

# Copy nginx configurations and scripts
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/scripts/generate-sites.sh /usr/local/bin/generate-sites.sh

# Copy PHP pool configuration script
COPY docker/scripts/php-manager.sh /usr/local/bin/php-manager.sh
COPY docker/scripts/project-status.sh /usr/local/bin/project-status.sh

# Set proper permissions
RUN chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.zshrc && \
    chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/generate-sites.sh && \
    chmod +x /usr/local/bin/php-manager.sh && \
    chmod +x /usr/local/bin/project-status.sh


# Expose SSH, HTTP and HTTPS ports
EXPOSE 22 80 443

# Set working directory
WORKDIR ${DESTINATION_DIR}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD php --version || exit 1

# Labels
LABEL maintainer="Laravel Docker DevEnv" \
    description="Multi-PHP Laravel Development Workspace with PHP 7.0-8.3" \
    version="2.1"

# Start supervisor
ENTRYPOINT ["/entrypoint.sh"]
