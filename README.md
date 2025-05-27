# Laravel Docker Development Environment

<div align="center">
  <img src="https://img.shields.io/badge/PHP-8.x-blue" alt="PHP Versions"/>
  <img src="https://img.shields.io/badge/MySQL-8.0-orange" alt="MySQL"/>
  <img src="https://img.shields.io/badge/Nginx-Latest-green" alt="Nginx"/>
  <img src="https://img.shields.io/badge/Redis-Alpine-red" alt="Redis"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
</div>

A professional, feature-rich Docker environment for Laravel development with support for multiple PHP versions, MySQL, Redis, Nginx, and more. Designed for seamless local development with flexibility and ease of use.

## Features

- **Multi-PHP Support**: Run different PHP versions (7.4, 8.0, 8.1, 8.2) simultaneously for different projects
- **Nginx Web Server**: Configured for Laravel with custom domain support
- **MySQL Database**: Pre-configured MySQL 8.0 with phpMyAdmin
- **Redis Cache**: Alpine-based Redis for high performance
- **Workspace Container**: For running Composer, Artisan, and other CLI commands
- **Automatic Configuration**: Dynamic generation of Docker configurations
- **Supervisor Integration**: Manage background processes easily
- **SSH Access**: Secure shell access to containers
- **Flexible Architecture**: Easily extendable for custom requirements

## System Requirements

- Docker Engine 20.10+
- Docker Compose 2.0+
- Make
- `yq` for YAML processing

## Quick Start

### 1. Clone the Repository

```bash
git https://github.com/alizaynoune/Laravel-Docker-DevEnv.git
cd Laravel-Docker-DevEnv
```

### 2. Run the Installation Command

```bash
make install
```

This command:
- Creates a `.env` file from `env.example`
- Creates a `sitesMap.yaml` file from `sitesMap.example.yaml`

### 3. Configure Your Environment

Edit the `.env` file to set:
- User details
- Database credentials
- Directory paths
- PHP versions

Edit the `sitesMap.yaml` to define your sites:

```yaml
sites:
  - map: myproject.local
    to: myproject/public
    php: "8.1"
```

### 4. Start the Environment

```bash
make up
```

### 5. Update Your Hosts File

Add your site domains to your `/etc/hosts` file:

```
127.0.0.1 myproject.local
```

### 6. Access Your Projects

- Web: `http://myproject.local`
- phpMyAdmin: `http://localhost:8080`

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| USER_NAME | Username in containers | docker |
| USER_UID | User ID in containers | 1000 |
| USER_GID | Group ID in containers | 1000 |
| MYSQL_DATABASE | Default database name | laravel |
| APP_DIR | Path to your code on host | ~/Code |
| DESTINATION_DIR | Mount path in containers | /var/www |
| DEFAULT_PHP | Default PHP version | 8.0 |

### Site Configuration

In `sitesMap.yaml`, configure sites with:

| Option | Description | Required |
|--------|-------------|----------|
| map | Domain name | Yes |
| to | Application path relative to APP_DIR | Yes |
| php | PHP version to use | Yes |

## Usage

### Common Commands

| Command | Description |
|---------|-------------|
| `make up` | Start all containers |
| `make down` | Stop and remove containers |
| `make restart` | Restart all containers |
| `make logs` | View container logs |
| `make exec workspace` | Access workspace container shell |
| `make status` | Show container status |
| `make build` | Rebuild containers |

### Working with PHP

Access the workspace container to run PHP commands:

```bash
make exec workspace
```

From within the workspace container:

```bash
# Create a Laravel project
composer create-project laravel/laravel myproject

# Run artisan commands
cd myproject
php artisan migrate

# Switch PHP version
php74  # For PHP 7.4
php80  # For PHP 8.0
php81  # For PHP 8.1
php82  # For PHP 8.2
```

### Database Access

- **From Host**: Connect to MySQL at `localhost:3306`
- **From Containers**: Connect to MySQL at `mysql:3306`
- **Web Interface**: phpMyAdmin at `http://localhost:8080`

### Redis Access

- **From Host**: Connect to Redis at `localhost:6379`
- **From Containers**: Connect to Redis at `redis:6379`

## Directory Structure

```
Laravel-Docker-DevEnv/
├── docker-compose.yml        # Main Docker Compose config
├── docker-compose.override.yml # Auto-generated PHP services
├── Makefile                  # Make commands for management
├── env.example               # Environment variables template
├── sitesMap.example.yaml     # Site configuration template
├── docker/                   # Docker configurations
│   ├── nginx/                # Nginx configurations
│   ├── php/                  # PHP configurations
│   ├── mysql/                # MySQL configurations
│   └── redis/                # Redis configurations
└── scripts/                  # Utility scripts
```

## Advanced Configuration

### Custom PHP Extensions

Edit the Dockerfile at `docker/php.Dockerfile` to add custom PHP extensions.

### Custom Nginx Configuration

Modify `docker/nginx/nginx.conf` for custom web server settings.

### Supervisor Configuration

Add supervisor config files to `docker/supervisor/conf.d/` for process management.

## Troubleshooting

### Permission Issues

If you encounter permission issues, ensure your USER_UID and USER_GID in the .env file match your host user:

```bash
sed -i "s/^USER_UID=.*/USER_UID=$(id -u)/" .env
sed -i "s/^USER_GID=.*/USER_GID=$(id -g)/" .env
```

### Container Access Issues

To debug container access issues, check the container logs:

```bash
make logs nginx
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.