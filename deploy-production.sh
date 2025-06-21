#!/bin/bash

# Urban Vision ERP - Production Deployment Helper
# This script helps deploy schema and database to production servers

set -e

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

# Configuration
PRODUCTION_SERVER=""
PRODUCTION_USER=""
PRODUCTION_PATH=""
PRODUCTION_DB_CONTAINER="directus-database"  # Adjust based on your production setup

# Load production config if exists
if [ -f ".production.env" ]; then
    source .production.env
fi

# Validate configuration
validate_config() {
    if [ -z "$PRODUCTION_SERVER" ] || [ -z "$PRODUCTION_USER" ] || [ -z "$PRODUCTION_PATH" ]; then
        log_error "Production configuration not set!"
        log_info "Please create a .production.env file with:"
        echo "PRODUCTION_SERVER=your-server.com"
        echo "PRODUCTION_USER=your-ssh-user"
        echo "PRODUCTION_PATH=/path/to/production/app"
        echo "PRODUCTION_DB_CONTAINER=your-db-container-name"
        exit 1
    fi
}

# Export current schema
export_schema() {
    log_info "Exporting current schema..."
    ./uv.sh schema-export
    
    # Get the latest schema file
    LATEST_SCHEMA=$(ls -t schema/schema-*.yaml | head -1)
    log_success "Schema exported: $LATEST_SCHEMA"
    echo "$LATEST_SCHEMA"
}

# Create production backup
create_production_backup() {
    log_info "Creating production database backup..."
    
    ssh "${PRODUCTION_USER}@${PRODUCTION_SERVER}" "cd ${PRODUCTION_PATH} && docker exec ${PRODUCTION_DB_CONTAINER} pg_dump -U directus directus > backups/production-backup-\$(date +%Y%m%d_%H%M%S).sql"
    
    log_success "Production backup created"
}

# Push schema to production
push_schema() {
    validate_config
    
    if [ -z "$1" ]; then
        # Export current schema if not specified
        SCHEMA_FILE=$(export_schema)
    else
        SCHEMA_FILE="$1"
    fi
    
    if [ ! -f "$SCHEMA_FILE" ]; then
        log_error "Schema file not found: $SCHEMA_FILE"
        exit 1
    fi
    
    log_info "Pushing schema to production..."
    
    # Create backup first
    log_warning "Creating production backup before schema update..."
    create_production_backup
    
    # Copy schema file to production
    scp "$SCHEMA_FILE" "${PRODUCTION_USER}@${PRODUCTION_SERVER}:${PRODUCTION_PATH}/schema/"
    
    # Apply schema on production
    SCHEMA_FILENAME=$(basename "$SCHEMA_FILE")
    log_info "Applying schema on production..."
    
    ssh "${PRODUCTION_USER}@${PRODUCTION_SERVER}" "cd ${PRODUCTION_PATH} && docker exec directus npx directus schema apply --yes /directus/schema/${SCHEMA_FILENAME}"
    
    log_success "Schema applied to production!"
}

# Push database backup to production
push_database() {
    validate_config
    
    if [ -z "$1" ]; then
        log_error "Please specify backup file: deploy-production.sh push-db <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        log_error "Backup file not found: $1"
        exit 1
    fi
    
    log_warning "⚠️  This will replace the production database!"
    log_warning "Are you ABSOLUTELY sure? Type 'DEPLOY-PRODUCTION' to confirm:"
    read -r response
    
    if [ "$response" != "DEPLOY-PRODUCTION" ]; then
        log_info "Production deployment cancelled"
        exit 0
    fi
    
    # Create production backup
    create_production_backup
    
    # Copy backup to production
    log_info "Copying backup to production..."
    scp "$1" "${PRODUCTION_USER}@${PRODUCTION_SERVER}:${PRODUCTION_PATH}/backups/staging-import.sql"
    
    # Restore on production
    log_info "Restoring database on production..."
    ssh "${PRODUCTION_USER}@${PRODUCTION_SERVER}" << 'EOF'
        cd ${PRODUCTION_PATH}
        
        # Stop Directus
        docker compose stop directus
        
        # Drop and recreate database
        docker exec ${PRODUCTION_DB_CONTAINER} psql -U directus postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'directus' AND pid <> pg_backend_pid();"
        docker exec ${PRODUCTION_DB_CONTAINER} psql -U directus postgres -c "DROP DATABASE IF EXISTS directus;"
        docker exec ${PRODUCTION_DB_CONTAINER} psql -U directus postgres -c "CREATE DATABASE directus;"
        
        # Restore backup
        cat backups/staging-import.sql | docker exec -i ${PRODUCTION_DB_CONTAINER} psql -U directus directus
        
        # Start Directus
        docker compose start directus
        
        # Clean up staging import
        rm -f backups/staging-import.sql
EOF
    
    log_success "Production database restored!"
}

# Sync uploads to production
sync_uploads() {
    validate_config
    
    log_info "Syncing uploads to production..."
    
    # Use rsync to sync uploads directory
    rsync -avz --progress uploads/ "${PRODUCTION_USER}@${PRODUCTION_SERVER}:${PRODUCTION_PATH}/uploads/"
    
    log_success "Uploads synced to production!"
}

# Full deployment (schema + uploads, no database)
deploy_changes() {
    validate_config
    
    log_info "Starting production deployment (schema + uploads)..."
    
    # Export and push schema
    push_schema
    
    # Sync uploads
    sync_uploads
    
    log_success "Production deployment complete!"
}

# Show production status
production_status() {
    validate_config
    
    log_info "Checking production status..."
    
    ssh "${PRODUCTION_USER}@${PRODUCTION_SERVER}" "cd ${PRODUCTION_PATH} && docker compose ps"
}

# Show help
help() {
    echo ""
    echo "Urban Vision ERP - Production Deployment Helper"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  push-schema [file]    Push schema to production (exports current if not specified)"
    echo "  push-db <file>        Push database backup to production (DANGEROUS!)"
    echo "  sync-uploads          Sync uploads directory to production"
    echo "  deploy                Deploy schema + uploads (no database)"
    echo "  status                Show production status"
    echo "  help                  Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Create a .production.env file with:"
    echo "    PRODUCTION_SERVER=your-server.com"
    echo "    PRODUCTION_USER=your-ssh-user"
    echo "    PRODUCTION_PATH=/path/to/production/app"
    echo "    PRODUCTION_DB_CONTAINER=your-db-container-name"
    echo ""
    echo "Examples:"
    echo "  $0 push-schema                           # Export and push current schema"
    echo "  $0 push-schema schema/schema-latest.yaml # Push specific schema file"
    echo "  $0 push-db backups/backup-20250621.sql   # Push database to production"
    echo "  $0 deploy                                # Deploy schema + uploads"
    echo ""
}

# Main command dispatcher
case "${1:-help}" in
    push-schema)
        push_schema "$2"
        ;;
    push-db)
        push_database "$2"
        ;;
    sync-uploads)
        sync_uploads
        ;;
    deploy)
        deploy_changes
        ;;
    status)
        production_status
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