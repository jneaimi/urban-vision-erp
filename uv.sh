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
    # Ensure backup directory exists
    mkdir -p backups
    
    BACKUP_FILE="backups/backup-$(date +%Y%m%d_%H%M%S).sql"
    log_info "Creating database backup..."
    
    # Check if database is ready
    if ! docker exec $DATABASE_CONTAINER pg_isready -U directus >/dev/null 2>&1; then
        log_error "Database is not ready. Please ensure services are running."
        return 1
    fi
    
    # Create backup with proper error handling
    if docker exec $DATABASE_CONTAINER pg_dump -U directus directus > "$BACKUP_FILE" 2>/dev/null; then
        log_success "Database backed up to $BACKUP_FILE"
    else
        log_error "Failed to create backup"
        rm -f "$BACKUP_FILE" 2>/dev/null
        return 1
    fi
}

db_restore() {
    if [ -z "$1" ]; then
        log_error "Please specify backup file: uv db-restore <backup_file>"
        return 1
    fi

    if [ ! -f "$1" ]; then
        log_error "Backup file $1 not found"
        return 1
    fi

    # Check if database is ready
    if ! docker exec $DATABASE_CONTAINER pg_isready -U directus >/dev/null 2>&1; then
        log_error "Database is not ready. Please ensure services are running."
        return 1
    fi

    log_warning "This will replace all current data. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Restoring database from $1..."
        
        # Stop Directus to prevent connections
        log_info "Stopping Directus to prevent active connections..."
        docker compose stop directus
        
        # Wait for container to fully stop
        sleep 2
        
        # Drop and recreate database to ensure clean restore
        log_info "Preparing database for restore..."
        docker exec $DATABASE_CONTAINER psql -U directus -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'directus' AND pid <> pg_backend_pid();" postgres >/dev/null 2>&1
        docker exec $DATABASE_CONTAINER psql -U directus postgres -c "DROP DATABASE IF EXISTS directus;" >/dev/null 2>&1
        docker exec $DATABASE_CONTAINER psql -U directus postgres -c "CREATE DATABASE directus;" >/dev/null 2>&1
        
        # Restore the backup with progress indication
        log_info "Restoring data (this may take a moment)..."
        if cat "$1" | docker exec -i $DATABASE_CONTAINER psql -U directus directus >/dev/null 2>&1; then
            log_success "Database restored successfully"
            
            # Restart Directus
            log_info "Starting Directus..."
            docker compose start directus
            
            # Wait for Directus to be fully ready
            log_info "Waiting for Directus to be ready..."
            local retries=30
            while [ $retries -gt 0 ]; do
                if curl -s http://localhost:8055/server/health >/dev/null 2>&1; then
                    log_success "Directus is ready!"
                    break
                fi
                retries=$((retries - 1))
                sleep 2
            done
            
            if [ $retries -eq 0 ]; then
                log_warning "Directus took longer than expected to start. Check logs with 'uv logs directus'"
            fi
        else
            log_error "Failed to restore database"
            # Try to restart Directus anyway
            docker compose start directus
            return 1
        fi
    else
        log_info "Database restore cancelled"
    fi
}

# Schema operations
schema_export() {
    SCHEMA_FILE="schema/schema-$(date +%Y%m%d_%H%M%S).yaml"
    log_info "Exporting current schema..."
    docker exec $DIRECTUS_CONTAINER npx directus schema snapshot --yes "/directus/$SCHEMA_FILE"
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

# Reset operations
reset_database() {
    log_warning "⚠️  This will completely reset the database and all data will be lost!"
    log_warning "Are you sure you want to continue? Type 'RESET' to confirm:"
    read -r response

    if [ "$response" = "RESET" ]; then
        log_info "Stopping services..."
        docker compose down

        log_info "Removing database volume..."
        docker volume rm ${PROJECT_NAME}_database_data 2>/dev/null || true
        rm -rf data/database/* 2>/dev/null || true

        log_info "Starting services..."
        docker compose up -d database cache

        log_info "Waiting for database to be ready..."
        sleep 10

        log_info "Starting Directus..."
        docker compose up -d directus

        log_success "Database reset complete! Use 'uv bootstrap' to initialize."
    else
        log_info "Database reset cancelled"
    fi
}

reset_uploads() {
    log_warning "⚠️  This will delete all uploaded files!"
    log_warning "Are you sure? (y/N)"
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Removing uploads..."
        rm -rf uploads/*
        mkdir -p uploads
        log_success "Uploads directory reset"
    else
        log_info "Upload reset cancelled"
    fi
}

reset_schema() {
    log_warning "⚠️  This will reset the database schema but keep the data structure!"
    log_warning "Are you sure? (y/N)"
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Dropping and recreating database..."
        docker exec $DATABASE_CONTAINER psql -U directus -c "DROP DATABASE IF EXISTS directus;"
        docker exec $DATABASE_CONTAINER psql -U directus -c "CREATE DATABASE directus;"

        log_info "Restarting Directus..."
        docker compose restart directus

        log_success "Schema reset complete! Use 'uv bootstrap' to initialize."
    else
        log_info "Schema reset cancelled"
    fi
}

reset_all() {
    log_warning "🚨 COMPLETE RESET - This will:"
    log_warning "   • Delete all database data"
    log_warning "   • Remove all uploaded files"
    log_warning "   • Reset all volumes"
    log_warning "   • Remove all containers"
    echo ""
    log_warning "Type 'RESET-ALL' to confirm complete reset:"
    read -r response

    if [ "$response" = "RESET-ALL" ]; then
        log_info "Stopping all services..."
        docker compose down -v

        log_info "Removing all volumes..."
        docker volume prune -f

        log_info "Removing uploads..."
        rm -rf uploads/*
        mkdir -p uploads

        log_info "Removing database data..."
        rm -rf data/database/*

        log_info "Removing cache data..."
        rm -rf data/minio/*

        log_info "Creating fresh directories..."
        mkdir -p {data/database,data/minio,uploads,backups}

        log_info "Starting services..."
        docker compose up -d

        log_success "Complete reset finished! Use 'uv bootstrap' to initialize."
        log_info "Default credentials: admin@urbanvision.com / urbanvision123"
    else
        log_info "Complete reset cancelled"
    fi
}

# Development helpers
fresh_start() {
    log_info "Starting fresh development environment..."

    # Create backup if database exists and has data
    if docker exec $DATABASE_CONTAINER pg_isready -U directus >/dev/null 2>&1; then
        # Check if database has tables
        TABLE_COUNT=$(docker exec $DATABASE_CONTAINER psql -U directus -d directus -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")
        TABLE_COUNT=$(echo $TABLE_COUNT | tr -d ' ')
        
        if [ "$TABLE_COUNT" -gt "0" ]; then
            log_info "Creating backup before fresh start..."
            db_backup
        fi
    fi

    # Reset everything
    reset_all

    # Wait a bit for services to start
    log_info "Waiting for services to initialize..."
    sleep 15

    # Bootstrap
    bootstrap

    log_success "Fresh environment ready!"
    access
}

# Quick reset for development (keeps backups)
dev_reset() {
    log_info "Quick development reset (keeps backups)..."

    # Backup current state if database exists and has data
    if docker exec $DATABASE_CONTAINER pg_isready -U directus >/dev/null 2>&1; then
        # Check if database has tables
        TABLE_COUNT=$(docker exec $DATABASE_CONTAINER psql -U directus -d directus -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")
        TABLE_COUNT=$(echo $TABLE_COUNT | tr -d ' ')
        
        if [ "$TABLE_COUNT" -gt "0" ]; then
            db_backup
        fi
    fi

    # Reset database only
    reset_database

    # Bootstrap
    bootstrap

    log_success "Development environment reset complete!"
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
    echo "  migration-run            Run pending migrations"
    echo "  migration-status         Show migration status"
    echo ""
    echo "Reset Operations:"
    echo "  reset-database     Reset database (removes all data)"
    echo "  reset-uploads      Reset uploads directory"
    echo "  reset-schema       Reset database schema only"
    echo "  reset-all          Complete reset (database + uploads + volumes)"
    echo "  fresh-start        Complete reset + bootstrap (with backup)"
    echo "  dev-reset          Quick development reset (backup + reset + bootstrap)"
    echo ""
    echo "Information:"
    echo "  access             Show all access points and credentials"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start                           # Start all services"
    echo "  $0 logs directus                   # Show Directus logs"
    echo "  $0 db-backup                       # Backup database"
    echo "  $0 fresh-start                     # Complete fresh start"
    echo "  $0 dev-reset                       # Quick development reset"
    echo "  $0 reset-database                  # Reset database only"
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
    reset-database)
        reset_database
        ;;
    reset-uploads)
        reset_uploads
        ;;
    reset-schema)
        reset_schema
        ;;
    reset-all)
        reset_all
        ;;
    fresh-start)
        fresh_start
        ;;
    dev-reset)
        dev_reset
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
