#!/bin/sh
set -x
if [ "$#" -lt 5 ]; then
    echo "Usage: $0 <domain> <root> <http-port> <https-port> <php-version>"
    exit 1
fi

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
    echo "Please provide all the required arguments."
    exit 1
fi

if [ ! -d "/etc/nginx/sites-available" ]; then
    mkdir -p "/etc/nginx/sites-available"
fi

if [ ! -d "/etc/nginx/sites-enabled" ]; then
    mkdir -p "/etc/nginx/sites-enabled"
fi

if [ ! -d "/etc/nginx/ssl" ]; then
    mkdir -p "/etc/nginx/ssl"
fi

if [ ! -f "/etc/nginx/ssl/self-signed.crt" ] || [ ! -f "/etc/nginx/ssl/self-signed.key" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/self-signed.key -out /etc/nginx/ssl/self-signed.crt -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
fi

# Assign PHP_VERSION
PHP_VERSION="$5"

# Use `echo` with `sed` to remove the dot
PHP_HOST=$(echo "php$PHP_VERSION" | sed 's/\.//g')

block="
map \$http_upgrade \$type {
  default \"web\";
  websocket \"ws\";
}

server {
  listen ${3:-80};
  listen ${4:-443} ssl;
  server_name .$1;
  root \"$2\";
  index index.html index.htm index.php;
  charset utf-8;

  location @web {
    try_files \$uri \$uri/ /index.php?\$query_string;
  }

  location @ws {
    proxy_pass http://$PHP_HOST:6001;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_http_version 1.1;
  }

  location / {
    try_files /nonexistent @\$type;
  }

  location = /favicon.ico { access_log off; log_not_found off; }
  location = /robots.txt  { access_log off; log_not_found off; }
  access_log off;
  error_log  /var/log/nginx/$1-error.log error;
  sendfile off;
  location ~ \.php$ {
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass $PHP_HOST:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_intercept_errors off;
    fastcgi_buffer_size 16k;
    fastcgi_buffers 4 16k;
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
  }

  location ~ /\.ht {
    deny all;
  }

  ssl_certificate     /etc/nginx/ssl/self-signed.crt;
  ssl_certificate_key /etc/nginx/ssl/self-signed.key;
}
"
echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
