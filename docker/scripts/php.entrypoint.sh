#!/bin/sh

sudo /usr/bin/supervisord -c /etc/supervisord.conf &
sudo /usr/sbin/sshd -D &
php-fpm
