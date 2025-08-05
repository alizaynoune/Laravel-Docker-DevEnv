# Laravel Docker DevEnv v2.1 - Architecture Simplification

## 🚀 Major Changes

### ✅ Simplified Container Architecture

**BEFORE (v2.0):**

-   Separate PHP-FPM containers for each PHP version (php70, php71, etc.)
-   Complex USER_UID/USER_GID management
-   Multiple build arguments and configurations

**AFTER (v2.1):**

-   Single workspace container with ALL PHP versions (7.0-8.3)
-   Simplified user management (no UID/GID complexity)
-   Consolidated development environment

### ✅ Optional Service Configuration

**NEW FEATURE:** Environment-based service control via `.env`:

```bash
# Enable/disable services as needed
ENABLE_MYSQL=true
ENABLE_PHPMYADMIN=true
ENABLE_REDIS=true
ENABLE_MAILHOG=true
```

### ✅ Updated File Structure

**Removed:**

-   `docker/php.Dockerfile` - No longer needed
-   `USER_UID` and `USER_GID` variables from all configurations

**Modified:**

-   `docker-compose.yml` - Core services only (workspace + nginx)
-   `docker-compose.override.yml` - Auto-generated optional services
-   `env.example` - Added service toggles, removed UID/GID
-   `scripts/docker-compose-generator.sh` - Rewritten for optional services
-   `Makefile` - Updated descriptions and commands
-   `README.md` - Updated documentation

## 🎯 Benefits

1. **Simpler Setup**: No need to manage user IDs/permissions
2. **Faster Builds**: Single workspace container vs multiple PHP containers
3. **Easier Maintenance**: Less complexity in configuration files
4. **Flexible Services**: Enable only what you need
5. **Consistent Experience**: All PHP versions in one environment

## 🔧 Migration from v2.0

If upgrading from v2.0:

1. **Update `.env` file:**

    ```bash
    # Remove these lines:
    USER_UID=1000
    USER_GID=1000

    # Add these lines:
    ENABLE_MYSQL=true
    ENABLE_PHPMYADMIN=true
    ENABLE_REDIS=true
    ENABLE_MAILHOG=true
    ```

2. **Regenerate services:**

    ```bash
    make clean
    make generate-services
    make up
    ```

3. **Verify functionality:**
    ```bash
    make status
    make workspace
    php81 --version  # Test PHP switching
    ```

## 📋 Service Architecture

### Core Services (Always Available)

-   **workspace**: Multi-PHP development environment
-   **nginx**: Web server with auto-configuration

### Optional Services (Configurable)

-   **mysql**: Database server (if ENABLE_MYSQL=true)
-   **phpmyadmin**: Web database interface (if ENABLE_PHPMYADMIN=true)
-   **redis**: Cache server (if ENABLE_REDIS=true)
-   **mailhog**: Email testing (if ENABLE_MAILHOG=true)

## 🐘 PHP Version Management

All PHP versions (7.0-8.3) are available in the workspace container:

```bash
# Switch PHP versions easily
php70 --version
php81 --version
php83 --version

# Use specific PHP for commands
php81 composer install
php83 artisan serve
```

## 🚀 Quick Start

```bash
# Initial setup
make install

# Edit configuration
nano .env  # Configure services
nano sitesMap.yaml  # Configure sites

# Start environment
make up

# Access workspace
make workspace
```

---

**Version:** 2.1
**Date:** January 2025
**Compatibility:** Docker Compose v2.0+
**PHP Versions:** 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3
