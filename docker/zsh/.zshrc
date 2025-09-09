# Laravel Docker Development Environment - Zsh Configuration

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git aliases colorize cp history node npm nvm composer laravel)
source $ZSH/oh-my-zsh.sh

# PHP Version Management
alias php70='phpv 7.0'
alias php71='phpv 7.1'
alias php72='phpv 7.2'
alias php73='phpv 7.3'
alias php74='phpv 7.4'
alias php80='phpv 8.0'
alias php81='phpv 8.1'
alias php82='phpv 8.2'
alias php83='phpv 8.3'

# PHP Management aliases
alias php-status='php-manager.sh status'
alias php-restart='php-manager.sh restart'
alias php-sockets='php-manager.sh sockets'
alias php-logs='php-manager.sh logs'
alias php-info='php-manager.sh info'
alias php-versions='php-manager.sh versions'
alias machine-status='machine-status.sh'
alias php-manager='sudo php-manager.sh'

# Laravel aliases
alias art='php artisan'
alias tinker='php artisan tinker'
alias migrate='php artisan migrate'
alias seed='php artisan db:seed'
alias routes='php artisan route:list'

# Nginx aliases
alias nginx-reload='sudo nginx -s reload'
alias nginx-test='sudo nginx -t'
alias nginx-status='sudo supervisorctl status nginx'
alias nginx-restart='sudo supervisorctl restart nginx'
alias nginx-sites='sudo /usr/local/bin/generate-sites.sh'

# PHP version switcher function
phpv() {
    if [ -z "$1" ]; then
        echo "Current PHP version: $(php --version | head -n1)"
        echo "Available versions: 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3"
        echo "Usage: phpv <version>"
        return
    fi

    case "$1" in
        "7.0"|"70") sudo update-alternatives --set php /usr/bin/php7.0 ;;
        "7.1"|"71") sudo update-alternatives --set php /usr/bin/php7.1 ;;
        "7.2"|"72") sudo update-alternatives --set php /usr/bin/php7.2 ;;
        "7.3"|"73") sudo update-alternatives --set php /usr/bin/php7.3 ;;
        "7.4"|"74") sudo update-alternatives --set php /usr/bin/php7.4 ;;
        "8.0"|"80") sudo update-alternatives --set php /usr/bin/php8.0 ;;
        "8.1"|"81") sudo update-alternatives --set php /usr/bin/php8.1 ;;
        "8.2"|"82") sudo update-alternatives --set php /usr/bin/php8.2 ;;
        "8.3"|"83") sudo update-alternatives --set php /usr/bin/php8.3 ;;
        *) echo "Unsupported PHP version: $1" ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Switched to PHP $1"
        php --version | head -n1
    fi
}

# Development information function
dev-info() {
    echo ""
    echo "🚀 Laravel Docker Development Environment"
    echo "=========================================="
    echo ""
    echo "📍 Current Location: $(pwd)"
    echo "🐘 PHP Version: $(php --version | head -n1)"
    echo "🎼 Composer Version: $(composer --version 2>/dev/null || echo 'Not available')"
    echo "📦 Node Version: $(node --version 2>/dev/null || echo 'Not available')"
    echo "📦 NPM Version: $(npm --version 2>/dev/null || echo 'Not available')"
    echo "🌐 Nginx Status: $(nginx-status 2>/dev/null | awk '{print $2}' || echo 'Unknown')"
    echo ""
    echo "🔧 Available PHP Versions:"
    echo "   phpv 7.0-8.3  - Switch PHP version"
    echo "   php70-php83    - Use specific PHP version"
    echo ""
    echo "🛠️  Development Commands:"
    echo "   machine-status  - Show machine status"
    echo "   php-status      - Show PHP-FPM pool status"
    echo "   php-restart     - Restart all PHP-FPM services"
    echo "   php-sockets     - List PHP-FPM socket files"
    echo "   php-logs        - Show PHP-FPM log files"
    echo "   php-info        - Show detailed PHP information"
    echo "   php-versions    - List available PHP versions"
	echo "   php-manager     - Manage PHP-FPM services"
}

# Welcome message
if [[ $- == *i* ]]; then
    USER=$(whoami)
    CURENT_DIR=$(pwd)
    clear
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                 🚀 Laravel Docker Development Environment            ║"
    echo "║                                                                      ║"
    echo "║  Welcome to your multi-PHP Laravel development workspace!            ║"
    echo "║                                                                      ║"
    echo "║  📋 Available Commands:                                              ║"
    echo "║    • php-versions    - Show available PHP versions                   ║"
    echo "║    • laravel-new     - Create new Laravel project                    ║"
    echo "║    • dev-info        - Show development environment info             ║"
	echo "║    • machine-status - Show machine status                            ║"
	echo "║    • php-manager     - Manage PHP-FPM services                       ║"
    echo "║    • artisan         - Run Laravel artisan commands                  ║"
    echo "║                                                                      ║"
    echo "║  🔧 PHP Version Switchers:                                           ║"
    echo "║    • php70, php71, php72, php73, php74                               ║"
    echo "║    • php80, php81, php82, php83                                      ║"
    echo "║                                                                      ║"
    echo "║  📁 Working Directory: $CURENT_DIR$(printf '%*s' $((46 - ${#CURENT_DIR})) '')║"
    echo "║  👤 User: $USER$(printf '%*s' $((59 - ${#USER})) '')║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo ""
fi
