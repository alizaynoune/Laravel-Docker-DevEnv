#Base Image
FROM debian:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
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
    ssh-client \
    sudo \
    bash \
    autoconf \
    make \
    g++ \
    gcc \
    iputils-ping


# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# user configuration
ARG USER_UID
ARG USER_GID
ARG USER_NAME
ARG USER_PASSWORD
ARG ROOT_PASSWORD

RUN useradd -rm -d /home/${USER_NAME} -s /bin/bash -g root -G sudo -u ${USER_UID} ${USER_NAME}
RUN echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "root:${ROOT_PASSWORD}" | chpasswd

RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
RUN service ssh start

USER ${USER_NAME}

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# zshrc configuration
COPY /docker/zsh/workspace/zshrc /home/${USER_NAME}/.zshrc

EXPOSE 22
