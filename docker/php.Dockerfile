ARG PHP_VERSION="8.3"

FROM php:${PHP_VERSION}-fpm-alpine

RUN apk add --no-cache icu-libs icu-dev \
    && docker-php-ext-install intl
# Install dependencies
RUN apk update && apk --no-cache add --update \
    build-base \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    libzip-dev \
    zsh \
    wget \
    openssh-server \
    supervisor \
    sshpass \
    openssh-client \
    iputils \
    sudo \
    bash \
    autoconf \
    make \
    g++ \
    gcc \
    linux-headers \
    icu-libs \
    icu-dev \
    openrc

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    zip \
    exif \
    pcntl \
    bcmath \
    gd \
    intl

RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Install xdebug and redis if php version is greater than 8.0
RUN if [ $(echo ${PHP_VERSION} | sed -E 's/^([0-9]+)\.([0-9]+).*/\1\2/') -ge 80 ]; then \
    pecl install xdebug redis && \
    docker-php-ext-enable xdebug redis.so; \
fi

# Set the PATH environment variable
ENV PATH="/usr/local/bin:${PATH}"

# Copy php.ini configuration
COPY /docker/php/php.ini /usr/local/etc/php/php.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# user configuration
ARG USER_UID
ARG USER_GID
ARG USER_NAME
ARG USER_PASSWORD
ARG ROOT_PASSWORD

# Install laravel installer
RUN composer global require laravel/installer

# Create user '${USER_NAME}' with sudo privileges
RUN adduser -D -h /home/${USER_NAME} -s /bin/bash -G root -u ${USER_UID} ${USER_NAME} && \
    echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd && \
    echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "root:${ROOT_PASSWORD}" | chpasswd

# Generate SSH host keys
RUN ssh-keygen -A

# Configure SSH
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config


# Create a directory for misc storage and set ownership
RUN mkdir -p /home/misc-storage && \
    chown -R ${USER_UID}:${USER_GID} /home/misc-storage

# Copy the supervisord configuration
COPY /docker/supervisor/supervisord.conf /etc/supervisord.conf

# Configure Supervisor if the directory exists
RUN DIR_NAME=$(echo ${PHP_VERSION} | sed -E 's/^([0-9]+)\.([0-9]+).*/\1\2/') && \
    sed -i "s/files =.*/files = \/etc\/supervisor\/conf.d\/php${DIR_NAME}\/\*.conf/g" /etc/supervisord.conf

USER ${USER_NAME}

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install laravel installer
RUN composer global require laravel/installer

# zshrc configuration
COPY /docker/zsh/php/zshrc /home/${USER_NAME}/.zshrc

# Expose port 9000 for PHP-FPM, 22 for SSH, and 6001 for websockets
EXPOSE 9000 22 6001
