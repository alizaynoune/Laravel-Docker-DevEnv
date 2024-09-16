#!/bin/sh

USER_NAME=$(whoami)

# check if ssh public key is exists in the directory
if [ -f "$HOME"/.ssh/id_rsa.pub ]; then
    echo "SSH key already exists"
else
    echo "Generating SSH key"
    ssh-keygen -t rsa -b 4096 -C "$USER_NAME@workspace" -f "$HOME"/.ssh/id_rsa -P ""
    cat "$HOME"/.ssh/id_rsa.pub > "$HOME"/.ssh/authorized_keys
fi

# user name
sed -i "s/{ssh_user}/$USER_NAME/g" $HOME/.zshrc
# php version
PHP_VERSION=$(echo "$1" | sed 's/\.//g')
sed -i "s/{php_version}/php$PHP_VERSION/g" "$HOME"/.zshrc

# shellcheck disable=SC3046
source "$HOME"/.zshrc

sudo /usr/sbin/sshd -D
