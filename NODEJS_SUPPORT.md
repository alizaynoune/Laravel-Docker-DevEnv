# Node.js Support in Laravel Docker DevEnv v2.0

## 🚀 Overview

This Laravel Docker Development Environment includes comprehensive Node.js support for modern frontend development with Laravel applications.

## 📦 What's Included

### Node.js & Package Managers

-   **Node.js 20 LTS** - Latest long-term support version
-   **NPM** - Node Package Manager (comes with Node.js)
-   **Yarn** - Alternative package manager for faster installs

### Frontend Tools

-   **Vite** - Modern build tool (Laravel default)
-   **Webpack** - Traditional build tool support
-   **Laravel Mix** - Laravel's wrapper around Webpack

## 🛠️ Usage in Workspace Container

All Node.js tools are available in the workspace container:

```bash
# Access workspace
make workspace

# Check versions
node --version    # Node.js version
npm --version     # NPM version
yarn --version    # Yarn version

# Package management
npm install       # Install dependencies
npm run dev       # Run development build
npm run build     # Run production build
npm run watch     # Watch for changes

# Using Yarn (faster alternative)
yarn install      # Install dependencies
yarn dev          # Run development build
yarn build        # Run production build
yarn watch        # Watch for changes
```

## 🎯 Laravel Frontend Workflows

### 🆕 New Laravel Project with Vite

```bash
# Create new Laravel project
laravel-new myproject 8.2
cd myproject

# Install frontend dependencies
npm install

# Development workflow
npm run dev       # Build assets for development
npm run watch     # Watch for changes and rebuild

# Production build
npm run build     # Build optimized assets for production
```

### 🔧 Laravel Mix Projects

For older Laravel projects using Mix:

```bash
cd myproject

# Install dependencies
npm install

# Development
npm run dev       # Compile assets
npm run watch     # Watch and recompile on changes

# Production
npm run production  # Compile and minify for production
```

### ⚡ Vite Configuration

Modern Laravel projects use Vite. Example `vite.config.js`:

```javascript
import { defineConfig } from "vite";
import laravel from "laravel-vite-plugin";

export default defineConfig({
    plugins: [
        laravel({
            input: ["resources/css/app.css", "resources/js/app.js"],
            refresh: true,
        }),
    ],
    server: {
        host: "0.0.0.0", // Important for Docker
        port: 5173,
        hmr: {
            host: "localhost",
        },
    },
});
```

## 🌐 Frontend Frameworks

### Vue.js Setup

```bash
# Install Vue 3
npm install vue@next @vitejs/plugin-vue

# Install Inertia.js for Vue (optional)
npm install @inertiajs/vue3
```

### React Setup

```bash
# Install React
npm install react react-dom @vitejs/plugin-react

# Install Inertia.js for React (optional)
npm install @inertiajs/react
```

### Tailwind CSS Setup

```bash
# Install Tailwind CSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Install additional Tailwind packages
npm install @tailwindcss/forms @tailwindcss/typography
```

## 🔄 Hot Module Replacement (HMR)

### Vite HMR Configuration

Update your `vite.config.js` for Docker:

```javascript
export default defineConfig({
    plugins: [
        laravel({
            input: ["resources/css/app.css", "resources/js/app.js"],
            refresh: true,
        }),
    ],
    server: {
        host: "0.0.0.0",
        port: 5173,
        hmr: {
            host: "localhost",
            port: 5173,
        },
        watch: {
            usePolling: true, // Important for Docker file watching
        },
    },
});
```

### Expose Vite Dev Server

Add to your `docker-compose.override.yml` if you want to expose Vite:

```yaml
services:
    workspace:
        ports:
            - "5173:5173" # Vite dev server
```

## 📱 Frontend Development Workflow

### 🎨 Complete Frontend Setup

```bash
# 1. Access workspace
make workspace

# 2. Navigate to your Laravel project
cd /var/www/myproject

# 3. Install Node dependencies
npm install

# 4. Install frontend framework (example: Vue + Tailwind)
npm install vue@next @vitejs/plugin-vue
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# 5. Start development server
npm run dev
```

### 🔍 Debugging Frontend Issues

```bash
# Check Node.js environment
node --version
npm list                    # List installed packages
npm outdated               # Check for outdated packages

# Clear caches
npm cache clean --force    # Clear NPM cache
rm -rf node_modules        # Remove node_modules
npm install                # Reinstall dependencies

# Yarn alternative
yarn cache clean
rm -rf node_modules
yarn install
```

## ⚙️ Advanced Configuration

### 🎛️ Environment Variables for Frontend

Create `.env.local` for frontend-specific variables:

```env
# Vite environment variables (must start with VITE_)
VITE_APP_NAME="${APP_NAME}"
VITE_API_URL="${APP_URL}/api"
```

### 📦 Package.json Scripts

Optimize your `package.json` scripts:

```json
{
    "scripts": {
        "dev": "vite",
        "build": "vite build",
        "watch": "vite build --watch",
        "serve": "vite preview",
        "lint": "eslint resources/js --ext .js,.vue",
        "lint:fix": "eslint resources/js --ext .js,.vue --fix",
        "test": "vitest"
    }
}
```

### 🧪 Testing Setup

```bash
# Install testing tools
npm install -D vitest @vue/test-utils jsdom

# Install Cypress for E2E testing
npm install -D cypress

# Run tests
npm run test        # Unit tests with Vitest
npx cypress open    # E2E tests with Cypress
```

## 🚀 Performance Optimization

### 📈 Build Optimization

```javascript
// vite.config.js
export default defineConfig({
    build: {
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: ["vue", "axios"],
                    utils: ["lodash"],
                },
            },
        },
        chunkSizeWarningLimit: 1000,
    },
    optimizeDeps: {
        include: ["vue", "axios"],
    },
});
```

### 📦 Bundle Analysis

```bash
# Install bundle analyzer
npm install -D rollup-plugin-visualizer

# Analyze bundle size
npm run build -- --report
```

## 🔧 Troubleshooting

### 🐛 Common Issues

#### File Watching Issues

```bash
# If file watching doesn't work in Docker
# Add to vite.config.js:
server: {
    watch: {
        usePolling: true,
        interval: 1000,
    },
}
```

#### Permission Issues

```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) /usr/local/lib/node_modules
```

#### Port Conflicts

```bash
# Check what's using port 5173
sudo netstat -tulpn | grep :5173

# Use different port in vite.config.js
server: {
    port: 3000,  // Use different port
}
```

## 📚 Learning Resources

### 🎓 Official Documentation

-   [Vite Documentation](https://vitejs.dev/)
-   [Laravel Vite Documentation](https://laravel.com/docs/vite)
-   [Vue.js Documentation](https://vuejs.org/)
-   [React Documentation](https://reactjs.org/)
-   [Tailwind CSS Documentation](https://tailwindcss.com/)

### 💡 Best Practices

1. **Use Vite** for new Laravel projects
2. **Keep dependencies updated** regularly
3. **Use TypeScript** for better development experience
4. **Implement proper linting** with ESLint and Prettier
5. **Write tests** for your frontend components
6. **Optimize bundles** for production

---

**Happy Frontend Development! 🎨**
