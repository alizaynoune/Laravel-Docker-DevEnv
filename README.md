# Laravel Docker Development Environment

This project sets up a Dockerized PHP development environment with multiple PHP versions, Redis, and MySQL, all managed through docker-compose and environment variables. It's designed to streamline Laravel development by providing a flexible, scalable, and easy-to-use setup.

## Features

- **Multiple PHP Versions:** Easily switch between PHP versions for different projects.
- **MySQL and Redis:** Pre-configured services to support database and caching requirements.
- **Supervisor Support:** Automatically manage long-running processes like Laravel WebSockets.
- **SSH Access:** Secure access to containers for development and debugging.
- **Nginx Support:** Configured for serving Laravel applications.

## Services

- **PHP:** Multiple PHP versions (7.4, 8.0, 8.1) with Composer and Xdebug.
- **Nginx:** Web server for serving Laravel applications.
- **MySQL:** Database service for storing application data.
- **Redis:** In-memory data structure store for caching.
- **workspace:** Container for running Composer and Artisan commands.

## Prerequisites

- Docker
- Docker Compose
- Make
- `yq` (for parsing YAML files)

## Setup

1. **Clone the repository:**

    ```sh
    git clone https://github.com/alizaynoune/Laravel-Docker-DevEnv.git
    cd Laravel-Docker-DevEnv
    ```

2. **Create and configure the `.env` file:**

    Copy the `.env.example` to `.env` and adjust the variables as needed.

    ```sh
    cp env.example .env
    ```
3. **Add your sites to the `sitesMap.yaml` file:**

    Copy the `sitesMap.example.yaml` to `sitesMap.yaml` and adjust the entries as needed.

    ```sh
    cp sitesMap.example.yaml sitesMap.yaml
    ```
    Example entry in `sitesMap.yaml`:

    ```yaml
    - map: example.local
      to: example-app/public
      php: "8.0"
   ```
4. **Build and start the containers:**

    ```sh
    make up
    ```

## Configuration

### Environment Variables

The `.env` file contains the following variables:

- **User Configuration:**
  - `USER_NAME` <sub>(the user name for the container)</sub>
  - `USER_PASSWORD` <sub>(the user password for the container)</sub>
  - `USER_UID` <sub>(the user ID for the container)</sub>
  - `USER_GID` <sub>(the user group ID for the container)</sub>
  - `ROOT_PASSWORD`

- **MySQL Configuration:**
  - `MYSQL_ROOT_PASSWORD` <sub>(the root password for MySQL)</sub>
  - `MYSQL_DATABASE` <sub>(the default database name)</sub>
  - `MYSQL_USERNAME` <sub>(the default username)</sub>
  - `MYSQL_PASSWORD` <sub>(the default password)</sub>

- **Redis Configuration:**
  - `REDIS_ARGS` <sub>(additional arguments for the Redis service)</sub>

- **Directories:**
  - `APP_DIR` <sub>(the application directory)</sub>
  - `DESTINATION_DIR` <sub>(the destination directory in the container)</sub>
  - `REDIS_DATA_DIR` <sub>(the Redis data directory)</sub>
  - `MYSQL_DATA_DIR` <sub>(the MySQL data directory)</sub>

- **Default PHP Version:**
  - `DEFAULT_PHP` <sub>(the default PHP version for the workspace container)</sub>

### Docker Compose Files

- `docker-compose.yml`: Main Docker Compose configuration.
- `docker-compose.override.yml`: This is where the PHP services are defined. (auto-generated), do not edit this file.

### PHP Services

The PHP services are configured based on the `sitesMap.yaml` file. Each site can specify a different PHP version.

Example entry in `sitesMap.yaml`:

```yaml
- map: example.local
  to: example-app/public
  php: "8.0"
```

## Usage

- **Make Commands:**

    - `make up`: Build and start the containers.
    - `make down`: Stop and remove the containers.
    - `make restart`: Restart the containers.
    - `make logs`: Show the container logs.
    - `make exec`: Execute a command in the workspace container.


- **Workspace Container:**

    The workspace container is used for running Composer and Artisan commands.

    ```sh
    make exec workspace
    ```
   - **Run Commands:**

        ```sh
        composer install
        php artisan migrate
        php artisan db:seed
        ```
   - **Change PHP Version:**

        ```sh
        php 80 # Switch to PHP 8.0
        ```