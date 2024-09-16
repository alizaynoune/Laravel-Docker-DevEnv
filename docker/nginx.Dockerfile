FROM nginx:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    vim \
    unzip \
    git \
    curl \
    zsh \
    wget \
    openssh-server \
    supervisor \
    sshpass \
    ssh-client \
    iputils-ping \
    sudo \
    yq

# Destination directory
ARG DESTINATION_DIR

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/ssl

COPY /docker/nginx/scripts /scripts
COPY /sitesMap.yaml /scripts

COPY /docker/nginx/nginx.conf /etc/nginx/nginx.conf

RUN chmod +x /scripts/*
RUN sh /scripts/script.sh $DESTINATION_DIR
