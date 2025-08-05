#!/bin/bash
#########################################
# Laravel Docker Development Environment
# Nginx Site Configuration Generator v2.0
#########################################
#
# This script generates nginx site configurations based on a YAML sites map.
# Each site entry in sitesMap.yaml creates a corresponding nginx configuration
# with SSL support, PHP-FPM integration, and WebSocket support for Laravel WebSockets.
#
# Author: Docker Environment Team
# Version: 2.0
# Date: 2025-08-01
#
#########################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
SITES_MAP_FILE="/var/www/sitesMap.yaml"
SITES_AVAILABLE_DIR="/etc/nginx/sites-available"
SITES_ENABLED_DIR="/etc/nginx/sites-enabled"

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        error "yq is not installed. Please install yq to parse YAML files."
        exit 1
    fi
}

# Function to validate the sites map file
validate_sites_map() {
    if [ ! -f "$SITES_MAP_FILE" ]; then
        error "Sites map file not found: $SITES_MAP_FILE"
        exit 1
    fi

    if ! yq eval '.sites' "$SITES_MAP_FILE" &> /dev/null; then
        error "Invalid YAML format in $SITES_MAP_FILE"
        exit 1
    fi

    local site_count
    site_count=$(yq eval '.sites | length' "$SITES_MAP_FILE")
    if [ "$site_count" -eq 0 ]; then
        warning "No sites found in $SITES_MAP_FILE"
        exit 0
    fi

    echo "$site_count"
}

# Main execution starts here
main() {
    log "Cleaning existing site configurations..."

    # Check if yq is installed
    check_yq

    # Validate sites map file
    SITE_COUNT=$(validate_sites_map)

    # Create directories if they don't exist
    mkdir -p "$SITES_AVAILABLE_DIR" "$SITES_ENABLED_DIR"

    # Remove existing site configurations
    rm -f "$SITES_ENABLED_DIR"/*
    rm -f "$SITES_AVAILABLE_DIR"/*.conf

    log "Generating nginx site configurations from $SITES_MAP_FILE..."
    log "Found $SITE_COUNT site(s) to configure"

    # Process each site
    for ((i=0; i<SITE_COUNT; i++)); do
        SITE_MAP=$(yq eval ".sites[$i].map" "$SITES_MAP_FILE")
        SITE_TO=$(yq eval ".sites[$i].to" "$SITES_MAP_FILE")
        SITE_PHP=$(yq eval ".sites[$i].php" "$SITES_MAP_FILE")

        # Remove quotes if present
        SITE_MAP=$(echo "$SITE_MAP" | sed 's/^"//;s/"$//')
        SITE_TO=$(echo "$SITE_TO" | sed 's/^"//;s/"$//')
        SITE_PHP=$(echo "$SITE_PHP" | sed 's/^"//;s/"$//')

        # Use Unix socket based on PHP version
        PHP_SOCKET="unix:/run/php/php${SITE_PHP}-fpm.sock"

        # Determine if it's a Laravel project (has public directory)
        if [[ "$SITE_TO" == *"/public" ]]; then
            ROOT_PATH="/var/www/$SITE_TO"
            INDEX_FILE="index.php"
            TRY_FILES='$uri $uri/ /index.php?$query_string'
        else
            ROOT_PATH="/var/www/$SITE_TO"
            INDEX_FILE="index.php index.html index.htm"
            TRY_FILES='$uri $uri/ /index.php?$args'
        fi

        log "Configuring site: $SITE_MAP -> $ROOT_PATH (PHP $SITE_PHP)"

        # Generate nginx configuration
        SITE_CONFIG="$SITES_AVAILABLE_DIR/$SITE_MAP.conf"

        cat > "$SITE_CONFIG" << EOF
# Laravel/PHP Site Configuration: $SITE_MAP
# Generated automatically - DO NOT EDIT MANUALLY

server {
    listen 80;
    listen [::]:80;
    server_name $SITE_MAP;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $SITE_MAP;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/self-signed.crt;
    ssl_certificate_key /etc/nginx/ssl/self-signed.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Document root
    root $ROOT_PATH;
    index $INDEX_FILE;

    # Charset
    charset utf-8;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # WebSocket location block
    location @ws {
        proxy_pass http://127.0.0.1:6001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_http_version 1.1;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Web location block
    location @web {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Main location block with WebSocket routing
    location / {
        try_files /nonexistent @\$type;
    }

    # Handle PHP files
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass $PHP_SOCKET;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        include fastcgi_params;

        # Laravel specific
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;

        # Timeouts
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to sensitive files
    location ~* \.(env|git|svn|htaccess|htpasswd)$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Handle static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        log_not_found off;
    }

    # Optimize images
    location ~* \.(jpg|jpeg|png|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        access_log off;
        log_not_found off;
    }

    # Handle Laravel storage and public files
    location ~* /storage/.*\.(php|php\d+|phtml|inc)$ {
        deny all;
    }

    # Error and access logs
    error_log /var/log/nginx/${SITE_MAP}_error.log;
    access_log /var/log/nginx/${SITE_MAP}_access.log;

    # Client settings
    client_max_body_size 100M;
    client_body_timeout 60s;
    client_header_timeout 60s;
}
EOF

        # Enable the site
        ln -sf "$SITE_CONFIG" "$SITES_ENABLED_DIR/"
        success "Site $SITE_MAP configured successfully"
    done

    # Generate a default server block for unmatched domains
    log "Generating default server configuration..."
    cat > "$SITES_AVAILABLE_DIR/default.conf" << 'EOF'
# Default server block
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;

    # SSL Configuration (for default HTTPS)
    ssl_certificate /etc/nginx/ssl/self-signed.crt;
    ssl_certificate_key /etc/nginx/ssl/self-signed.key;

    # Return 444 for unmatched domains
    return 444;
}
EOF

    ln -sf "$SITES_AVAILABLE_DIR/default.conf" "$SITES_ENABLED_DIR/"

    success "Nginx site generation completed!"
    log "Generated configurations for $SITE_COUNT site(s)"

    # Test nginx configuration
    if nginx -t > /dev/null 2>&1; then
        success "Nginx configuration test passed"
    else
        error "Nginx configuration test failed"
        nginx -t
        exit 1
    fi

    success "All nginx configurations generated and validated successfully!"
}

# Run main function
main "$@"
        exit 0
    fi

    echo "$site_count"
}

# Main execution starts here
main() {
    log "Cleaning existing site configurations..."

    # Check if yq is installed
    check_yq

    # Validate sites map file
    SITE_COUNT=$(validate_sites_map)

    # Create directories if they don't exist
    mkdir -p "$SITES_AVAILABLE_DIR" "$SITES_ENABLED_DIR"

    # Remove existing site configurations
    rm -f "$SITES_ENABLED_DIR"/*
    rm -f "$SITES_AVAILABLE_DIR"/*.conf

    log "Generating nginx site configurations from $SITES_MAP_FILE..."
    log "Found $SITE_COUNT site(s) to configure"

    # Process each site
    for ((i=0; i<SITE_COUNT; i++)); do
        SITE_MAP=$(yq eval ".sites[$i].map" "$SITES_MAP_FILE")
        SITE_TO=$(yq eval ".sites[$i].to" "$SITES_MAP_FILE")
        SITE_PHP=$(yq eval ".sites[$i].php" "$SITES_MAP_FILE")

        # Remove quotes if present
        SITE_MAP=$(echo "$SITE_MAP" | sed 's/^"//;s/"$//')
        SITE_TO=$(echo "$SITE_TO" | sed 's/^"//;s/"$//')
        SITE_PHP=$(echo "$SITE_PHP" | sed 's/^"//;s/"$//')

        # Use Unix socket based on PHP version
        PHP_SOCKET="unix:/run/php/php${SITE_PHP}-fpm.sock"

        # Determine if it's a Laravel project (has public directory)
        if [[ "$SITE_TO" == *"/public" ]]; then
            ROOT_PATH="/var/www/$SITE_TO"
            INDEX_FILE="index.php"
            TRY_FILES='$uri $uri/ /index.php?$query_string'
        else
            ROOT_PATH="/var/www/$SITE_TO"
            INDEX_FILE="index.php index.html index.htm"
            TRY_FILES='$uri $uri/ /index.php?$args'
        fi

        log "Configuring site: $SITE_MAP -> $ROOT_PATH (PHP $SITE_PHP)"

        # Generate nginx configuration
        SITE_CONFIG="$SITES_AVAILABLE_DIR/$SITE_MAP.conf"

        cat > "$SITE_CONFIG" << EOF
# Laravel/PHP Site Configuration: $SITE_MAP
# Generated automatically - DO NOT EDIT MANUALLY

server {
    listen 80;
    listen [::]:80;
    server_name $SITE_MAP;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $SITE_MAP;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/self-signed.crt;
    ssl_certificate_key /etc/nginx/ssl/self-signed.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Document root
    root $ROOT_PATH;
    index $INDEX_FILE;

    # Charset
    charset utf-8;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # WebSocket location block
    location @ws {
        proxy_pass http://127.0.0.1:6001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_http_version 1.1;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Web location block
    location @web {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Main location block with WebSocket routing
    location / {
        try_files /nonexistent @\$type;
    }

    # Handle PHP files
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass $PHP_SOCKET;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        include fastcgi_params;

        # Laravel specific
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;

        # Timeouts
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to sensitive files
    location ~* \.(env|git|svn|htaccess|htpasswd)$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Handle static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        log_not_found off;
    }

    # Optimize images
    location ~* \.(jpg|jpeg|png|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        access_log off;
        log_not_found off;
    }

    # Handle Laravel storage and public files
    location ~* /storage/.*\.(php|php\d+|phtml|inc)$ {
        deny all;
    }

    # Error and access logs
    error_log /var/log/nginx/${SITE_MAP}_error.log;
    access_log /var/log/nginx/${SITE_MAP}_access.log;

    # Client settings
    client_max_body_size 100M;
    client_body_timeout 60s;
    client_header_timeout 60s;
}
EOF

        # Enable the site
        ln -sf "$SITE_CONFIG" "$SITES_ENABLED_DIR/"
        success "Site $SITE_MAP configured successfully"
    done

    # Generate a default server block for unmatched domains
    log "Generating default server configuration..."
    cat > "$SITES_AVAILABLE_DIR/default.conf" << 'EOF'
# Default server block
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;

    # SSL Configuration (for default HTTPS)
    ssl_certificate /etc/nginx/ssl/self-signed.crt;
    ssl_certificate_key /etc/nginx/ssl/self-signed.key;

    # Return 444 for unmatched domains
    return 444;
}
EOF

    ln -sf "$SITES_AVAILABLE_DIR/default.conf" "$SITES_ENABLED_DIR/"

    success "Nginx site generation completed!"
    log "Generated configurations for $SITE_COUNT site(s)"

    # Test nginx configuration
    if nginx -t > /dev/null 2>&1; then
        success "Nginx configuration test passed"
    else
        error "Nginx configuration test failed"
        nginx -t
        exit 1
    fi

    success "All nginx configurations generated and validated successfully!"
}

# Run main function
main "$@"
