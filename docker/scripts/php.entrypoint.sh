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

sudo /usr/bin/supervisord -c /etc/supervisord.conf &
sudo /usr/sbin/sshd -D &
php-fpm
