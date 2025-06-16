#!/bin/bash

# Urban Vision ERP - Development Helper Script
# This script provides convenient commands for common development tasks

set -e

PROJECT_NAME="urban-vision-erp"
DIRECTUS_CONTAINER="uv-erp-directus"
DATABASE_CONTAINER="uv-erp-database"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
}

# Start all services
start() {
    log_info "Starting Urban Vision ERP development environment..."
    check_docker
    docker compose up -d
    log_success "Services started! Directus will be available at http://localhost:8055"
    log_info "Use 'uv status' to check when all services are ready"
}

# Stop all services
stop() {
    log_info "Stopping Urban Vision ERP services..."
    docker compose down
    log_success "Services stopped"
}

# Restart all services
restart() {
    log_info "Restarting Urban Vision ERP services..."
    docker compose restart
    log_success "Services restarted"
}

# Show service status
status() {
    log_info "Urban Vision ERP Service Status:"
    docker compose ps
    echo ""
    
    # Check if Directus is ready
    if curl -s http://localhost:8055/server/health >/dev/null 2>&1; then
        log_success "Directus is ready at http://localhost:8055"
    else
        log_warning "Directus is not ready yet. Check logs with 'uv logs directus'"
    fi
    
    # Check database
    if docker exec $DATABASE_CONTAINER pg_isready -U directus >/dev/null 2>&1; then
        log_success "Database is ready"
    else
        log_warning "Database is not ready yet"
    fi
}

# Show logs
logs() {
    if [ -n "$1" ]; then
        log_info "Showing logs for $1..."
        docker compose logs -f "$1"
    else
        log_info "Showing logs for all services..."
        docker compose logs -f
    fi
}

# Bootstrap database
bootstrap() {
    log_info "Bootstrapping Directus database..."
    docker exec $DIRECTUS_CONTAINER npx directus bootstrap
    log_success "Database bootstrapped successfully!"
    log_info "You can now access Directus at http://localhost:8055"
    log_info "Login: admin@urbanvision.com / urbanvision123"
}

# Database operations
db_backup() {
    BACKUP_FILE="backups/backup-$(date +%Y%m%d_%H%M%S).sql"
    log_info "Creating database backup..."
    docker exec $DATABASE_CONTAINER pg_dump -U directus directus > "$BACKUP_FILE"
    log_success "Database backed up to $BACKUP_FILE"
}

db_restore() {
    if [ -z "$1" ]; then
        log_error "Please specify backup file: uv db-restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        log_error "Backup file $1 not found"
        exit 1
    fi
    
    log_warning "This will replace all current data. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Restoring database from $1..."
        cat "$1" | docker exec -i $DATABASE_CONTAINER psql -U directus directus
        log_success "Database restored successfully"
    else
        log_info "Database restore cancelled"
    fi
}

# Schema operations
schema_export() {
    SCHEMA_FILE="schema/schema-$(date +%Y%m%d_%H%M%S).yaml"
    log_info "Exporting current schema..."
    docker exec $DIRECTUS_CONTAINER npx directus schema snapshot "/directus/$SCHEMA_FILE"
    log_success "Schema exported to $SCHEMA_FILE"
}

schema_apply() {
    if [ -z "$1" ]; then
        log_error "Please specify schema file: uv schema-apply <schema_file>"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        log_error "Schema file $1 not found"
        exit 1
    fi
    
    log_info "Applying schema from $1..."
    docker exec $DIRECTUS_CONTAINER npx directus schema apply "/directus/$1"
    log_success "Schema applied successfully"
}

# Migration operations
migration_create() {
    if [ -z "$1" ]; then
        log_error "Please specify migration name: uv migration-create <migration_name>"
        exit 1
    fi
    
    log_info "Creating migration: $1"
    docker exec $DIRECTUS_CONTAINER npx directus database migrate:make "$1"
    log_success "Migration created successfully"
}

migration_run() {
    log_info "Running pending migrations..."
    docker exec $DIRECTUS_CONTAINER npx directus database migrate:latest
    log_success "Migrations completed"
}

migration_status() {
    log_info "Migration status:"
    docker exec $DIRECTUS_CONTAINER npx directus database migrate:status
}

# Show access points
access() {
    echo ""
    log_info "Urban Vision ERP Access Points:"
    echo "┌─────────────────────┬─────────────────────────────────┬──────────────────────────────────────┐"
    echo "│ Service             │ URL                             │ Credentials                          │"
    echo "├─────────────────────┼─────────────────────────────────┼──────────────────────────────────────┤"
    echo "│ Directus Admin      │ http://localhost:8055           │ admin@urbanvision.com / urbanvision123│"
    echo "│ MailDev             │ http://localhost:1080           │ (No login required)                  │"
    echo "│ MinIO Console       │ http://localhost:9001           │ urbanvision / urbanvision123         │"
    echo "│ Adminer             │ http://localhost:8080           │ Server: database, User: directus     │"
    echo "│ PostgreSQL Direct   │ localhost:5432                  │ User: directus, DB: directus         │"
    echo "└─────────────────────┴─────────────────────────────────┴──────────────────────────────────────┘"
    echo ""
}

# Show help
help() {
    echo ""
    echo "Urban Vision ERP Development Helper"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Service Management:"
    echo "  start              Start all services"
    echo "  stop               Stop all services"
    echo "  restart            Restart all services"
    echo "  status             Show service status"
    echo "  logs [service]     Show logs (all services or specific service)"
    echo ""
    echo "Database Operations:"
    echo "  bootstrap          Bootstrap Directus database"
    echo "  db-backup          Create database backup"
    echo "  db-restore <file>  Restore database from backup"
    echo ""
    echo "Schema Management:"
    echo "  schema-export      Export current schema"
    echo "  schema-apply <file> Apply schema from file"
    echo ""
    echo "Migration Management:"
    echo "  migration-create <name>  Create new migration"
    echo "  migration-run           Run pending migrations"
    echo "  migration-status        Show migration status"
    echo ""
    echo "Information:"
    echo "  access             Show all access points and credentials"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                           # Start all services"
    echo "  $0 logs directus                   # Show Directus logs"
    echo "  $0 db-backup                       # Backup database"
    echo "  $0 schema-export                   # Export current schema"
    echo "  $0 migration-create add_contracts  # Create new migration"
    echo ""
}

# Main command dispatcher
case "${1:-help}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$2"
        ;;
    bootstrap)
        bootstrap
        ;;
    db-backup)
        db_backup
        ;;
    db-restore)
        db_restore "$2"
        ;;
    schema-export)
        schema_export
        ;;
    schema-apply)
        schema_apply "$2"
        ;;
    migration-create)
        migration_create "$2"
        ;;
    migration-run)
        migration_run
        ;;
    migration-status)
        migration_status
        ;;
    access)
        access
        ;;
    help|--help|-h)
        help
        ;;
    *)
        log_error "Unknown command: $1"
        help
        exit 1
        ;;
esac