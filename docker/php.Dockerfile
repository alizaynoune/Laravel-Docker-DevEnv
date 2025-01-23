ARG PHP_VERSION="8.3"

FROM php:${PHP_VERSION}-fpm-alpine

# Install build dependencies
RUN apk update && apk --no-cache add \
    icu-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    freetype-dev \
    libzip-dev \
    bzip2-dev \
    oniguruma-dev \
    autoconf \
    make \
    g++ \
    gcc \
    linux-headers \
    libtool \
    vim \
    unzip \
    git \
    curl \
    zsh \
    wget \
    openssh-server \
    supervisor \
    bash \
    sudo

# Extract PHP source
RUN docker-php-source extract

# Install PHP extensions
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp && \
    docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    zip \
    exif \
    pcntl \
    bcmath \
    gd \
    intl

# Update the PECL channel and install extensions
RUN apk add --no-cache autoconf && \
    pecl channel-update pecl.php.net && \
    if [ "$(echo ${PHP_VERSION} | sed -E 's/^([0-9]+)\.([0-9]+).*/\1\2/')" -ge 80 ]; then \
    pecl install xdebug redis && \
    docker-php-ext-enable xdebug redis; \
fi

# Clean up after installation
RUN docker-php-source delete && \
    apk del autoconf make g++ gcc linux-headers libtool && \
    rm -rf /var/cache/apk/*

# Install gnu-libiconv for Alpine compatibility
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Set the PATH environment variable
ENV PATH="/usr/local/bin:${PATH}"

# Copy php.ini configuration
COPY /docker/php/php.ini /usr/local/etc/php/php.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# User configuration
ARG USER_UID
ARG USER_GID
ARG USER_NAME
ARG USER_PASSWORD
ARG ROOT_PASSWORD

# Create user '${USER_NAME}' with sudo privileges
RUN adduser -D -h /home/${USER_NAME} -s /bin/bash -u ${USER_UID} ${USER_NAME} && \
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "root:${ROOT_PASSWORD}" | chpasswd

# Set up SSH
RUN ssh-keygen -A && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

# Configure Supervisor
COPY /docker/supervisor/supervisord.conf /etc/supervisord.conf
RUN DIR_NAME=$(echo ${PHP_VERSION} | sed -E 's/^([0-9]+)\.([0-9]+).*/\1\2/') && \
    sed -i "s/files =.*/files = \/etc\/supervisor\/conf.d\/php${DIR_NAME}\/\*.conf/g" /etc/supervisord.conf

# Install Oh My Zsh
USER ${USER_NAME}
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Copy zsh configuration
COPY /docker/zsh/php/zshrc /home/${USER_NAME}/.zshrc

# Expose necessary ports
EXPOSE 9000 22 6001
