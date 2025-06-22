# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Urban Vision ERP is a full-stack enterprise resource planning system built specifically for construction and urban development companies. It's a containerized application using Directus CMS as the core backend with PostgreSQL/PostGIS for spatial data capabilities.

## Key Architecture

- **Directus CMS**: Provides the API, admin interface, and core data management
- **PostgreSQL 13 + PostGIS**: Primary database with spatial capabilities
- **Redis**: Caching and session storage
- **Docker Compose**: Container orchestration
- **External APIs**: QuickBooks (financial) and DocuSeal (document signing)

The system follows a headless CMS architecture where Directus provides the backend API and admin interface, while frontend applications can be built separately to consume the API.

## Essential Commands

### Development Workflow

```bash
# Start all services
./uv.sh start

# Check service status
./uv.sh status

# View logs (all or specific service)
./uv.sh logs [service]

# Quick development reset (creates backup + resets + bootstraps)
./uv.sh dev-reset

# Complete fresh start (safest reset option)
./uv.sh fresh-start
```

### Database Operations

```bash
# Bootstrap Directus (initial setup)
./uv.sh bootstrap

# Create timestamped backup
./uv.sh db-backup

# Restore from backup
./uv.sh db-restore backups/backup-20240101_120000.sql

# Direct PostgreSQL access
docker exec -it uv-erp-database psql -U directus directus
```

### Schema Management

```bash
# Export current schema
./uv.sh schema-export

# Apply schema from file
./uv.sh schema-apply schema/production.yaml

# Create new migration
docker exec uv-erp-directus npx directus database migrate:make migration_name

# Run pending migrations
docker exec uv-erp-directus npx directus database migrate:latest
```

### Running Tests

The project uses Directus's built-in validation and doesn't have a traditional test suite. For custom extensions:

```bash
# Extensions are auto-reloaded when EXTENSIONS_AUTO_RELOAD=true
# Modify files in ./extensions/ and changes will be reflected immediately
```

## Code Organization

### Directory Structure
- `extensions/`: Custom Directus extensions (auto-reloaded in development)
- `schema/`: Database schema snapshots in YAML format
- `migrations/`: Database migration files
- `uploads/`: File storage for Directus
- `backups/`: Database backup files (created by db-backup command)

### Key Business Modules
- Lead Management
- Project Management
- Procurement & RFP
- Warehouse/Inventory
- Financial Management (QuickBooks integration)
- Document Management (DocuSeal integration)
- Quality Control
- Human Resources with RBAC

### Development Patterns
- All business logic is implemented through Directus collections, flows, and extensions
- API-first design - frontend applications consume the Directus API
- Role-based access control is configured at the Directus level
- File uploads are handled by Directus and stored in the uploads directory
- Spatial data uses PostGIS extensions in PostgreSQL

## Important Notes

- The admin credentials are: admin@urbanvision.com / urbanvision123
- CORS is pre-configured for common frontend ports (3000, 5173, 4200, 8080)
- WebSocket support is enabled for real-time updates
- Rate limiting is disabled in development
- Email testing uses MailDev at http://localhost:1080
- The project includes spatial capabilities via PostGIS for location-based features