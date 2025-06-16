#!/bin/bash

# Urban Vision ERP - Quick Setup Script
# This script sets up the entire development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_header() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    URBAN VISION ERP SETUP                           ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_step() {
    echo -e "${BLUE}🔧 $1${NC}"
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

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_requirements() {
    log_step "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_warning "Node.js is not installed. Some CLI features may not work."
    else
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 18 ]; then
            log_warning "Node.js version is less than 18. Consider upgrading for better compatibility."
        fi
    fi
    
    log_success "System requirements check completed"
}

setup_environment() {
    log_step "Setting up development environment..."
    
    # Make sure all required directories exist
    mkdir -p data/{database,minio} uploads extensions schema backups migrations
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env
        log_success "Created .env file from template"
    else
        log_info ".env file already exists"
    fi
    
    log_success "Environment setup completed"
}

start_services() {
    log_step "Starting Docker services..."
    
    # Pull latest images
    docker compose pull
    
    # Start services
    docker compose up -d
    
    log_success "Services started successfully"
}

wait_for_services() {
    log_step "Waiting for services to be ready..."
    
    # Wait for database
    echo -n "Waiting for database"
    while ! docker exec uv-erp-database pg_isready -U directus >/dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    echo ""
    log_success "Database is ready"
    
    # Wait for Directus
    echo -n "Waiting for Directus"
    for i in {1..30}; do
        if curl -s http://localhost:8055/server/health >/dev/null 2>&1; then
            break
        fi
        echo -n "."
        sleep 3
    done
    echo ""
    
    if curl -s http://localhost:8055/server/health >/dev/null 2>&1; then
        log_success "Directus is ready"
    else
        log_warning "Directus may still be starting up. Check logs with: ./uv.sh logs directus"
    fi
}

bootstrap_directus() {
    log_step "Bootstrapping Directus database..."
    
    # Give Directus a moment to fully initialize
    sleep 5
    
    # Bootstrap the database
    if docker exec uv-erp-directus npx directus bootstrap; then
        log_success "Directus database bootstrapped successfully"
    else
        log_warning "Bootstrap may have failed. You can try again with: ./uv.sh bootstrap"
    fi
}

show_completion_info() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    SETUP COMPLETED SUCCESSFULLY!                    ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${GREEN}🎉 Urban Vision ERP is now ready for development!${NC}"
    echo ""
    
    echo -e "${BLUE}📍 Access Points:${NC}"
    echo "   • Directus Admin: http://localhost:8055"
    echo "   • Email Testing:  http://localhost:1080"
    echo "   • MinIO Console:  http://localhost:9001"
    echo "   • Database Admin: http://localhost:8080"
    echo ""
    
    echo -e "${BLUE}🔑 Default Credentials:${NC}"
    echo "   • Directus: admin@urbanvision.com / urbanvision123"
    echo "   • MinIO: urbanvision / urbanvision123"
    echo "   • Database: directus / directus"
    echo ""
    
    echo -e "${BLUE}🛠 Useful Commands:${NC}"
    echo "   • ./uv.sh status        - Check service status"
    echo "   • ./uv.sh logs          - View all logs"
    echo "   • ./uv.sh logs directus - View Directus logs"
    echo "   • ./uv.sh access        - Show all access points"
    echo "   • ./uv.sh help          - Show all available commands"
    echo ""
    
    echo -e "${BLUE}📚 Next Steps:${NC}"
    echo "   1. Visit http://localhost:8055 and log in"
    echo "   2. Explore the Directus admin interface"
    echo "   3. Set up your schema using the CLI tools"
    echo "   4. Configure QuickBooks and DocuSeal integrations"
    echo "   5. Import your initial data"
    echo ""
    
    echo -e "${YELLOW}💡 Need help? Check the README.md file or run: ./uv.sh help${NC}"
    echo ""
}

# Main execution
main() {
    log_header
    
    check_requirements
    setup_environment
    start_services
    wait_for_services
    bootstrap_directus
    show_completion_info
}

# Run main function
main "$@"