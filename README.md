# 🐋 Laravel Docker Development Environment

<div align="center">

![Laravel Docker DevEnv](https://img.shields.io/badge/Laravel-Docker-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)
![PHP Versions](https://img.shields.io/badge/PHP-7.0%20to%208.3-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-Latest-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-Alpine-DC382D?style=for-the-badge&logo=redis&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Latest-2496ED?style=for-the-badge&logo=docker&logoColor=white)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/alizaynoune/Laravel-Docker-DevEnv?style=for-the-badge)](https://github.com/alizaynoune/Laravel-Docker-DevEnv/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/alizaynoune/Laravel-Docker-DevEnv?style=for-the-badge)](https://github.com/alizaynoune/Laravel-Docker-DevEnv/issues)

**A Professional, Feature-Rich Docker Development Stack for Laravel**

*Streamline your Laravel development with multi-PHP support, modern tooling, and zero-configuration setup*

</div>

---

## 🌟 Overview

The Laravel Docker Development Environment is a comprehensive, production-ready Docker stack designed specifically for Laravel developers. Whether you're maintaining legacy applications on PHP 7.x or building cutting-edge projects with PHP 8.3, this environment provides everything you need in a single, unified workspace.

### 🎯 Why Choose This Environment?

- **🔄 Zero Configuration**: Get up and running in under 5 minutes
- **🐘 Multi-PHP Ready**: All PHP versions (7.0-8.3) in one container
- **🚀 Performance Optimized**: Designed for speed and efficiency
- **📦 Modular Architecture**: Enable only the services you need
- **🛠️ Developer-Focused**: Built by developers, for developers

---

## ✨ Key Features

<table>
<tr>
<td width="50%" valign="top">

### 🐘 **Multi-PHP Support**
- **Complete PHP stack**: 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3
- **Instant switching**: Change PHP versions with simple commands
- **Per-project configuration**: Different PHP versions for different projects
- **Extension support**: All common Laravel extensions pre-installed

### 🌐 **Web Server & SSL**
- **Nginx**: High-performance web server
- **Auto-configuration**: Sites generated from YAML config
- **SSL certificates**: Self-signed certificates for HTTPS development
- **Multi-domain**: Handle multiple projects simultaneously

</td>
<td width="50%" valign="top">

### 🗄️ **Database & Caching**
- **MySQL 8.0**: Latest MySQL with optimized settings
- **PHPMyAdmin**: Web-based database management
- **Redis**: Advanced caching and session storage
- **Persistent storage**: Data survives container restarts

### 🛠️ **Development Tools**
- **Modern terminal**: Zsh with Oh My Zsh
- **Package managers**: Composer, NPM, Yarn pre-installed
- **Email testing**: MailHog for email development
- **SSH access**: Full remote development support

</td>
</tr>
</table>

---

## 🚀 Quick Start Guide

### Prerequisites

Ensure you have these installed:
- 🐋 [Docker Engine](https://docs.docker.com/get-docker/) 20.10+
- 🔧 [Docker Compose](https://docs.docker.com/compose/install/) 2.0+
- 🛠️ Make utility (`sudo apt install make` on Ubuntu)
- 📦 Git

### 1️⃣ Clone & Setup

```bash
# Clone the repository
git clone https://github.com/alizaynoune/Laravel-Docker-DevEnv.git
cd Laravel-Docker-DevEnv

# Initialize environment (creates .env and sitesMap.yaml)
make install
```

### 2️⃣ Configure Your Environment

#### Edit `.env` file:
```bash
nano .env
```

**Essential settings:**
```env
# Your Laravel projects directory
APP_DIR=${HOME}/Code

# Services (enable/disable as needed)
ENABLE_MYSQL=true
ENABLE_PHPMYADMIN=true
ENABLE_REDIS=true
ENABLE_MAILHOG=true

# Database credentials
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=laravel
MYSQL_USERNAME=docker
MYSQL_PASSWORD=docker

# Default PHP version
DEFAULT_PHP=8.3
```

#### Configure your sites in `sitesMap.yaml`:
```bash
nano sitesMap.yaml
```

**Example configuration:**
```yaml
sites:
    # Modern Laravel 10+ application
    - map: myapp.local
      to: myapp/public
      php: "8.3"

    # Legacy application
    - map: legacy-app.local
      to: legacy-project/public
      php: "7.4"

    # API project
    - map: api.local
      to: api-service/public
      php: "8.2"
```

### 3️⃣ Start the Environment

```bash
# Generate services and start containers
make up
```

### 4️⃣ Configure Local Domains

Add your domains to `/etc/hosts`:
```bash
echo "127.0.0.1 myapp.local legacy-app.local api.local" | sudo tee -a /etc/hosts
```

### 5️⃣ Access Your Environment

🌐 **Web Applications:**
- Your apps: `http://myapp.local`, `http://legacy-app.local`
- PHPMyAdmin: `http://phpmyadmin.local` (if configured)

🛠️ **Development Tools:**
- MailHog: `http://localhost:8025`
- Workspace SSH: `ssh docker@localhost -p 2222`

**🎉 You're ready to develop!**

---

## 📖 Usage Guide

### 🖥️ Workspace Access

The workspace container is your main development environment:

```bash
# Primary access method
make workspace

# Alternative SSH access
ssh docker@localhost -p 2222

# Execute commands directly
make exec workspace "php artisan --version"
```

### 🐘 PHP Version Management

Switch between PHP versions instantly:

```bash
# Inside the workspace container
php70    # Switch to PHP 7.0
php74    # Switch to PHP 7.4
php81    # Switch to PHP 8.1
php82    # Switch to PHP 8.2
php83    # Switch to PHP 8.3

# Check current version
php --version

# List all available versions
php-versions
```

### 🛠️ Container Management

```bash
# Core commands
make up              # Start all services
make down            # Stop and remove containers
make restart         # Restart all containers
make status          # Show detailed status
make logs            # Show all logs
make logs mysql      # Show specific service logs

# Service access
make workspace       # Access main development environment
make mysql          # MySQL console
make redis          # Redis console
```

### 🗄️ Database Operations

```bash
# MySQL console access
make mysql

# Connect from workspace
mysql -h mysql -u docker -p

# Database management via PHPMyAdmin
# http://phpmyadmin.local (configure in sitesMap.yaml)
```

### 📧 Email Testing with MailHog

Perfect for testing email functionality:

**Laravel configuration (`.env`):**
```env
MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

**Access:** http://localhost:8025

---

## ⚙️ Configuration Reference

### 🌐 Sites Configuration (sitesMap.yaml)

```yaml
sites:
    - map: domain.local      # Local domain (add to /etc/hosts)
      to: project/public     # Path relative to APP_DIR
      php: "8.3"            # PHP version to use

    # Multiple domains for same project
    - map: app.local
      to: myapp/public
      php: "8.2"

    - map: www.app.local
      to: myapp/public
      php: "8.2"
```

**Supported PHP Versions:**
`7.0` • `7.1` • `7.2` • `7.3` • `7.4` • `8.0` • `8.1` • `8.2` • `8.3`

### 🔧 Environment Variables (.env)

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_DIR` | Host directory containing your projects | `${HOME}/Code` |
| `DESTINATION_DIR` | Container mount point | `/var/www` |
| `USER_NAME` | Container username | `docker` |
| `USER_PASSWORD` | Container password | `docker` |
| `DEFAULT_PHP` | Default PHP version | `8.3` |
| `ENABLE_MYSQL` | Enable MySQL service | `true` |
| `ENABLE_PHPMYADMIN` | Enable PHPMyAdmin | `true` |
| `ENABLE_REDIS` | Enable Redis service | `true` |
| `ENABLE_MAILHOG` | Enable MailHog service | `true` |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | `root` |
| `MYSQL_DATABASE` | Default database | `laravel` |
| `WORKSPACE_SSH_PORT` | SSH port for workspace | `2222` |
| `TZ` | Timezone | `UTC` |

### 📁 Project Structure

```
Laravel-Docker-DevEnv/
├── 📄 README.md                     # This documentation
├── 📄 docker-compose.yml           # Core services configuration
├── 📄 docker-compose.override.yml  # Auto-generated optional services
├── 📄 Makefile                     # Management commands
├── 📄 .env                         # Environment configuration
├── 📄 sitesMap.yaml               # Sites and domains configuration
├── 📁 docker/                     # Docker configurations
│   ├── 🐳 workspace.Dockerfile     # Multi-PHP workspace
│   ├── 📁 nginx/                   # Nginx configurations
│   ├── 📁 supervisor/              # Process management
│   ├── 📁 scripts/                 # Utility scripts
│   └── 📁 db/                      # Database configurations
└── 📁 scripts/                    # Management scripts
    ├── 📜 docker-compose-generator.sh
    └── 📜 project-status.sh
```

---

## 🔍 Advanced Usage

### 🎛️ Service Management

Enable or disable services by modifying `.env`:

```bash
# Disable unnecessary services for lighter setup
ENABLE_MYSQL=false
ENABLE_PHPMYADMIN=false
ENABLE_REDIS=true
ENABLE_MAILHOG=true

# Regenerate services
make generate-services
make up
```

### 🔧 Custom PHP Extensions

Add extensions in `docker/workspace.Dockerfile`:

```dockerfile
RUN apt-get install -y \
    php8.3-extension-name \
    php8.2-extension-name \
    php8.1-extension-name
```

### 🌐 Custom Nginx Configuration

Modify `docker/nginx/nginx.conf` for advanced web server settings.

### 📊 Monitoring & Status

```bash
# Comprehensive project status
make project-status

# Container resource usage
docker stats

# Service health checks
make status
```

---

## 🚨 Troubleshooting

### 🔧 Common Issues & Solutions

<details>
<summary><strong>🚫 Port Conflicts</strong></summary>

**Problem:** Ports 80, 443, or 3306 are already in use.

**Solution:**
```bash
# Check what's using the ports
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :3306

# Stop conflicting services
sudo systemctl stop apache2
sudo systemctl stop mysql
sudo systemctl stop nginx
```
</details>

<details>
<summary><strong>🌐 Site Not Loading</strong></summary>

**Problem:** Your Laravel app shows 404 or doesn't load.

**Solution:**
1. Check `/etc/hosts` entry:
   ```bash
   grep myapp.local /etc/hosts
   ```

2. Verify sitesMap.yaml syntax:
   ```bash
   make logs nginx
   ```

3. Ensure document root exists:
   ```bash
   ls -la ${APP_DIR}/myapp/public
   ```
</details>

<details>
<summary><strong>🔐 Permission Issues</strong></summary>

**Problem:** Permission denied errors.

**Solution:**
```bash
# Check your user ID
id

# Update .env with correct values
USER_UID=$(id -u)
USER_GID=$(id -g)

# Rebuild containers
make build
make up
```
</details>

<details>
<summary><strong>🐘 PHP Version Not Working</strong></summary>

**Problem:** PHP version switching fails.

**Solution:**
```bash
# Access workspace and check available versions
make workspace
php-versions

# Manually switch version
sudo update-alternatives --config php
```
</details>

### 🔄 Complete Reset

If you need to start fresh:

```bash
# Nuclear option - removes everything
make clean

# Rebuild from scratch
make build
make up
```

---

## 🎯 Development Workflows

### 📅 Daily Development Routine

```bash
# Morning startup
make up
make workspace

# Work on your project
cd /var/www/myproject
php83  # Switch to PHP 8.3
composer install
php artisan migrate:fresh --seed

# Test with different PHP versions
php74  # Switch to PHP 7.4 for compatibility testing
vendor/bin/phpunit

# End of day (optional)
exit
make stop
```

### 🚀 New Project Setup

```bash
# Access workspace
make workspace

# Create new Laravel project
cd /var/www
composer create-project laravel/laravel new-project
cd new-project

# Set up environment
cp .env.example .env
php artisan key:generate

# Configure database connection
php artisan migrate
```

### 🔄 Legacy Project Migration

```bash
# Clone your existing project to APP_DIR
git clone https://github.com/your/legacy-project.git ${APP_DIR}/legacy-project

# Add to sitesMap.yaml
echo "
    - map: legacy.local
      to: legacy-project/public
      php: \"7.4\"
" >> sitesMap.yaml

# Add to hosts file
echo "127.0.0.1 legacy.local" | sudo tee -a /etc/hosts

# Restart to apply changes
make restart
```

### 🧪 Testing & Quality Assurance

```bash
# Inside workspace
make workspace

# Run tests across PHP versions
php81
composer test

php82
composer test

php83
composer test

# Code quality
composer run-script phpstan
composer run-script phpcs
```

---

## 📈 Performance & Optimization

### 🚀 Performance Tips

1. **Resource Allocation:**
   ```bash
   # Monitor resource usage
   docker stats

   # Adjust Docker Desktop resources if needed
   # Recommended: 4GB RAM, 2 CPUs minimum
   ```

2. **Volume Optimization:**
   - Use bind mounts for development (default setup)
   - Consider named volumes for database data in production

3. **Service Management:**
   - Disable unused services in `.env`
   - Use `make generate-services` after changes

### 🔧 Container Optimization

```bash
# Remove unused Docker resources
make prune

# Check disk usage
docker system df

# Clean up everything (nuclear option)
docker system prune -a --volumes
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🛠️ Development Setup

```bash
# Fork the repository on GitHub
git clone https://github.com/your-username/Laravel-Docker-DevEnv.git
cd Laravel-Docker-DevEnv

# Create feature branch
git checkout -b feature/amazing-feature

# Make your changes and test
make up
make workspace

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature
```

### 📋 Contribution Guidelines

- **Bug Reports:** Use GitHub Issues with detailed reproduction steps
- **Feature Requests:** Discuss in Issues before implementing
- **Code Style:** Follow existing patterns and conventions
- **Testing:** Ensure changes work across PHP versions
- **Documentation:** Update README for new features

### 🏆 Contributors

Thanks to all contributors who have helped improve this project!

---

## 📄 License & Legal

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### 📜 MIT License Summary

- ✅ **Commercial use**
- ✅ **Modification**
- ✅ **Distribution**
- ✅ **Private use**
- ❌ **Liability**
- ❌ **Warranty**

---

## 🆘 Support & Community

### 📞 Getting Help

- 🐛 **Bug Reports:** [GitHub Issues](https://github.com/alizaynoune/Laravel-Docker-DevEnv/issues)
- 💡 **Feature Requests:** [GitHub Discussions](https://github.com/alizaynoune/Laravel-Docker-DevEnv/discussions)
- 📖 **Documentation:** This README and inline code comments
- 💬 **Community:** Share experiences and help others

### 📊 Project Statistics

![GitHub Stars](https://img.shields.io/github/stars/alizaynoune/Laravel-Docker-DevEnv?style=social)
![GitHub Forks](https://img.shields.io/github/forks/alizaynoune/Laravel-Docker-DevEnv?style=social)
![GitHub Contributors](https://img.shields.io/github/contributors/alizaynoune/Laravel-Docker-DevEnv)

---

## 🎉 Acknowledgments

Special thanks to:

- 🚀 **Laravel Team** - For the amazing framework that powers modern PHP development
- 🐋 **Docker Team** - For revolutionizing application containerization
- 🌐 **Nginx Team** - For the high-performance web server
- 🐘 **PHP Team** - For the continuous evolution of the language
- 👥 **Open Source Community** - For countless tools and inspirations
- 🙏 **All Contributors** - Who have helped improve this project

---

<div align="center">

## 🚀 Ready to Start Developing?

### Get up and running in 5 minutes:

```bash
git clone https://github.com/alizaynoune/Laravel-Docker-DevEnv.git
cd Laravel-Docker-DevEnv
make install
make up
make workspace
```

<br>

**⭐ Star this repo if it helped you!**

**📢 Share with your team and colleagues**

**🤝 Contribute to make it even better**

<br>

---

*Built with ❤️ by developers, for developers*

**Happy Coding! 🎯**

</div>
