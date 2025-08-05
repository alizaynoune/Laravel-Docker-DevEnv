# Laravel Docker Development Environment v2.0

<div align="center">
  <img src="https://img.shields.io/badge/PHP-7.0%20to%208.3-blue" alt="PHP Versions"/>
  <img src="https://img.shields.io/badge/MySQL-8.0-orange" alt="MySQL"/>
  <img src="https://img.shields.io/badge/Nginx-Latest-green" alt="Nginx"/>
  <img src="https://img.shields.io/badge/Redis-Alpine-red" alt="Redis"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
</div>

## 🚀 Overview

A professional, feature-rich Docker environment for Laravel development with comprehensive multi-PHP support (7.0-8.3), MySQL, Redis, Nginx, and development tools. Designed for seamless local development with maximum flexibility and productivity.

## ✨ Key Features

### 🐘 Multi-PHP Support

-   **All PHP versions**: 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3
-   **Single workspace container** with all PHP versions installed
-   **Easy version switching** with simple commands (`php70`, `php81`, etc.)
-   **Per-project PHP versions** via sitesMap.yaml configuration

### 🌐 Web Server & Networking

-   **Nginx** with automatic site generation from sitesMap.yaml
-   **SSL support** with self-signed certificates
-   **Multi-domain support** for different projects
-   **Laravel-optimized** configurations

### 🗄️ Database & Cache

-   **MySQL 8.0** with persistent data storage
-   **PHPMyAdmin** web interface (localhost:8080)
-   **Redis** for caching and sessions
-   **Automatic database connections** from containers

### 🛠️ Development Tools

-   **Workspace container** with Zsh, Oh My Zsh, and development tools
-   **SSH access** to containers
-   **Composer** and **Node.js/NPM/Yarn** pre-installed
-   **Git** and development utilities
-   **MailHog** for email testing (localhost:8025)

### ⚡ Advanced Features

-   **Automatic service generation** based on your projects
-   **Health checks** for all services
-   **Resource limits** and optimization
-   **Hot reloading** and file watching support
-   **Supervisor** for process management

## 📋 System Requirements

-   **Docker Engine** 20.10+
-   **Docker Compose** 2.0+
-   **Make** utility
-   **Git**
-   4GB+ RAM recommended
-   10GB+ disk space

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/alizaynoune/Laravel-Docker-DevEnv.git
cd Laravel-Docker-DevEnv
```

### 2. Initialize the Environment

```bash
make install
```

This command:

-   Creates `.env` file from `env.example`
-   Creates `sitesMap.yaml` from `sitesMap.example.yaml`
-   Creates necessary data directories

### 3. Configure Your Environment

#### Edit `.env` file:

```bash
nano .env
```

Key settings to configure:

```env
# Your projects directory
APP_DIR=${HOME}/Code

# User settings
USER_NAME=docker

# Optional Services (enable/disable as needed)
ENABLE_MYSQL=true
ENABLE_PHPMYADMIN=true
ENABLE_REDIS=true
ENABLE_MAILHOG=true

# Database settings
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=laravel
```

#### Edit `sitesMap.yaml`:

```bash
nano sitesMap.yaml
```

Configure your Laravel projects:

```yaml
sites:
    # Modern Laravel with PHP 8.2
    - map: myapp.local
      to: myapp/public
      php: "8.2"

    # Legacy project with PHP 7.4
    - map: legacy.local
      to: legacy-project/public
      php: "7.4"
```

### 4. Start the Environment

```bash
make up
```

### 5. Add Domains to Hosts File

Add your configured domains to `/etc/hosts`:

```bash
echo "127.0.0.1 myapp.local legacy.local" | sudo tee -a /etc/hosts
```

### 6. Access Your Environment

-   **Your Laravel apps**: https://myapp.local
-   **PHPMyAdmin**: http://localhost:8080
-   **MailHog**: http://localhost:8025
-   **Workspace SSH**: `ssh docker@localhost -p 2222`

## 📖 Usage Guide

### 🖥️ Accessing the Workspace

The workspace container is your main development environment with all PHP versions:

```bash
# Access workspace container
make workspace

# Alternative SSH access
make ssh
# or
ssh docker@localhost -p 2222
```

### 🐘 PHP Version Management

Inside the workspace container, easily switch between PHP versions:

```bash
# Switch to different PHP versions
php70    # Switch to PHP 7.0
php74    # Switch to PHP 7.4
php81    # Switch to PHP 8.1
php82    # Switch to PHP 8.2
php83    # Switch to PHP 8.3

# Check current PHP version
php --version

# Show all available versions
php-versions
```

### 🆕 Creating Laravel Projects

Use the built-in helper to create new Laravel projects:

```bash
# Create new Laravel project with specific PHP version
laravel-new myproject 8.2

# Create with default PHP version
laravel-new myproject
```

### 🎛️ Container Management

```bash
# Start all services
make up

# Stop all services
make down

# Restart specific service
make restart nginx

# View logs
make logs
make logs nginx  # specific service

# Check status
make status

# Access different containers
make workspace   # Main development environment
make mysql      # MySQL console
make redis      # Redis console
```

### 🗄️ Database Operations

```bash
# Access MySQL console
make mysql

# From workspace, connect to MySQL
mysql -h mysql -u docker -pdocker laravel

# PHPMyAdmin web interface
# http://localhost:8080
```

### 📧 Email Testing with MailHog

MailHog captures all emails sent from your Laravel applications:

-   **SMTP Settings**: Host: `mailhog`, Port: `1025`
-   **Web Interface**: http://localhost:8025

Configure in your Laravel `.env`:

```env
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

## ⚙️ Configuration

### 🌐 Site Configuration (sitesMap.yaml)

```yaml
sites:
    - map: domain.local # Local domain name
      to: project/public # Path relative to APP_DIR
      php: "8.1" # PHP version (7.0-8.3)
```

**Supported PHP Versions:**

-   "7.0", "7.1", "7.2", "7.3", "7.4"
-   "8.0", "8.1", "8.2", "8.3"

### 📁 Directory Structure

```
Laravel-Docker-DevEnv/
├── docker-compose.yml           # Main Docker Compose configuration
├── docker-compose.override.yml  # Auto-generated optional services
├── Makefile                     # Make commands for management
├── .env                         # Environment variables
├── sitesMap.yaml               # Site configurations
├── docker/                     # Docker configurations
│   ├── workspace.Dockerfile    # Multi-PHP workspace
│   ├── nginx.Dockerfile        # Nginx web server configuration
│   ├── nginx.Dockerfile        # Nginx with auto-config
│   ├── nginx/                  # Nginx configurations
│   ├── php/                    # PHP configurations
│   ├── supervisor/             # Supervisor configurations
│   └── scripts/                # Utility scripts
└── scripts/                    # Management scripts
```

### 🔧 Advanced Configuration

#### Custom PHP Extensions

Add extensions in `docker/workspace.Dockerfile`:

```dockerfile
RUN apt-get install -y
    php8.1-extension-name
    php8.2-extension-name
```

#### Custom Nginx Configuration

Modify `docker/nginx/nginx.conf` for custom web server settings.

#### Environment Variables

Key `.env` variables:

| Variable              | Description             | Default        |
| --------------------- | ----------------------- | -------------- |
| `APP_DIR`             | Your projects directory | `${HOME}/Code` |
| `ENABLE_MYSQL`        | Enable MySQL service    | `true`         |
| `ENABLE_PHPMYADMIN`   | Enable PHPMyAdmin       | `true`         |
| `ENABLE_REDIS`        | Enable Redis service    | `true`         |
| `ENABLE_MAILHOG`      | Enable MailHog service  | `true`         |
| `DEFAULT_PHP`         | Default PHP version     | `8.1`          |
| `MYSQL_ROOT_PASSWORD` | MySQL root password     | `root`         |
| `MYSQL_DATABASE`      | Default database        | `laravel`      |

## 🔍 Troubleshooting

### 🐛 Common Issues

#### Permission Issues

If you encounter permission issues:

```bash
# Update .env with your actual UID/GID
id  # Check your UID and GID
# Edit .env file with correct values
```

#### Port Conflicts

If ports are already in use:

```bash
# Check what's using the ports
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :3306

# Stop conflicting services
sudo systemctl stop apache2  # If Apache is running
sudo systemctl stop mysql    # If MySQL is running
```

#### Container Access Issues

```bash
# Check container status
make status

# View container logs
make logs workspace
make logs nginx

# Restart problematic containers
make restart nginx
```

#### Site Not Loading

1. Check if domain is in `/etc/hosts`:

    ```bash
    grep myapp.local /etc/hosts
    ```

2. Verify nginx configuration:

    ```bash
    make logs nginx
    ```

3. Check sitesMap.yaml syntax:
    ```bash
    # Validate YAML syntax
    python3 -c "import yaml; yaml.safe_load(open('sitesMap.yaml'))"
    ```

### 🔧 Reset Environment

If you need to start fresh:

```bash
# Complete reset
make clean

# Rebuild everything
make build
make up
```

## 🎯 Development Workflow

### 📊 Typical Daily Workflow

1. **Start your day:**

    ```bash
    make up
    make workspace
    ```

2. **Work on projects:**

    ```bash
    cd /var/www/myproject
    php82  # Switch to PHP 8.2
    composer install
    php artisan migrate
    ```

3. **Test different PHP versions:**

    ```bash
    php74  # Test with PHP 7.4
    vendor/bin/phpunit

    php82  # Test with PHP 8.2
    vendor/bin/phpunit
    ```

4. **End of day:**
    ```bash
    exit  # Exit workspace
    make stop  # Optional: stop containers
    ```

### 🚀 Best Practices

1. **Use version control** for your projects in `APP_DIR`
2. **Keep sitesMap.yaml** updated with your projects
3. **Use specific PHP versions** for each project in sitesMap.yaml
4. **Regular backups** of your database data
5. **Monitor resource usage** with `make status`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

-   **GitHub Issues**: [Report bugs or request features](https://github.com/alizaynoune/Laravel-Docker-DevEnv/issues)
-   **Documentation**: This README and inline code comments
-   **Community**: Share your experience and help others

## 🎉 Acknowledgments

-   **Laravel** community for the amazing framework
-   **Docker** for containerization technology
-   **Nginx** for the robust web server
-   **PHP** community for the language evolution
-   All contributors who have helped improve this project

---

<div align="center">
  <strong>Happy Coding! 🚀</strong>
</div>
