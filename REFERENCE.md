# Urban Vision ERP - Complete Setup Reference

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Architecture](#architecture)
- [Environment Configuration](#environment-configuration)
- [Service Details](#service-details)
- [CLI Commands Reference](#cli-commands-reference)
- [Database Schema](#database-schema)
- [Integration Points](#integration-points)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)
- [Production Deployment](#production-deployment)

---

## 🏗 System Overview

Urban Vision ERP is a comprehensive Enterprise Resource Planning system built on Directus CMS with integrated QuickBooks financial management and DocuSeal document signing capabilities.

### Key Features
- **Lead Management** - Sales pipeline and customer acquisition
- **Project Management** - Full project lifecycle tracking
- **Procurement** - RFP, supplier management, and purchasing
- **Warehouse Management** - Inventory tracking and stock control
- **Financial Management** - Invoicing, budgets, and QuickBooks sync
- **Document Management** - Contract generation and electronic signing
- **Quality Control** - Quality checks and compliance tracking
- **Human Resources** - Employee and department management

### Technology Stack
- **Backend**: Directus CMS (Node.js)
- **Database**: PostgreSQL 13 with PostGIS extensions
- **Cache**: Redis 6
- **Storage**: Local filesystem with MinIO S3 compatibility
- **Containerization**: Docker Compose
- **Integrations**: QuickBooks Online API, DocuSeal API

---

## 🏛 Architecture

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Mobile App    │    │   3rd Party     │
│   (React/Vue)   │    │   (Optional)    │    │   Integrations  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴───────────────┐
                    │      Directus CMS           │
                    │   (API Gateway & Admin)     │
                    └─────────────┬───────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
    ┌─────┴─────┐        ┌────────┴────────┐      ┌──────┴──────┐
    │   Redis   │        │   PostgreSQL    │      │   File      │
    │  (Cache)  │        │   + PostGIS     │      │   Storage   │
    └───────────┘        └─────────────────┘      └─────────────┘
```

### Docker Service Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                       │
│                     (uv-erp-network)                           │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  Directus   │  │ PostgreSQL  │  │    Redis    │             │
│  │   :8055     │  │    :5432    │  │    :6379    │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   MailDev   │  │   MinIO     │  │   Adminer   │             │
│  │ :1080/:1025 │  │:9000/:9001  │  │    :8080    │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Environment Configuration

### Directory Structure
```
urban-vision-erp/
├── docker-compose.yml          # Main Docker configuration
├── .env                        # Environment variables (development)
├── .env.example                # Environment template
├── .gitignore                  # Git ignore rules
├── README.md                   # Project documentation
├── REFERENCE.md               # This reference file
├── package.json               # Node.js scripts
├── uv.sh                      # Management CLI tool
├── setup.sh                   # One-command setup script
├── data/                      # Persistent data (Docker volumes)
│   ├── database/             # PostgreSQL data
│   └── minio/                # MinIO data
├── uploads/                   # Directus file uploads
├── extensions/                # Custom Directus extensions
├── schema/                    # Schema snapshots and exports
├── migrations/                # Database migrations
└── backups/                   # Database backups
```

### Environment Variables

#### Core Configuration
```bash
# Security Keys (MUST be changed for production)
KEY=c6274b2503e4d6d42689c725e5969fbdd266d697b47e285ce03192790acf6d35
SECRET=bbf1e18a3f30d68f511ba4e3f3f69cf842fba89aca03f2b2583f88ccb2df861f

# Database Configuration
DB_CLIENT=pg
DB_HOST=database
DB_PORT=5432
DB_DATABASE=directus
DB_USER=directus
DB_PASSWORD=directus

# Admin User
ADMIN_EMAIL=admin@urbanvision.com
ADMIN_PASSWORD=urbanvision123
```

#### Integration Configuration
```bash
# QuickBooks Integration
QB_CONSUMER_KEY=your-consumer-key
QB_CONSUMER_SECRET=your-consumer-secret
QB_ACCESS_TOKEN=your-access-token
QB_ACCESS_TOKEN_SECRET=your-access-token-secret
QB_COMPANY_ID=your-company-id
QB_SANDBOX=true

# DocuSeal Integration
DOCUSEAL_API_URL=https://api.docuseal.co
DOCUSEAL_API_KEY=your-api-key

# Email Configuration
EMAIL_FROM=noreply@urbanvision.com
EMAIL_TRANSPORT=smtp
EMAIL_SMTP_HOST=maildev
EMAIL_SMTP_PORT=1025

# Public URL
PUBLIC_URL=http://localhost:8055

# Storage Configuration
STORAGE_LOCATIONS=local
STORAGE_LOCAL_DRIVER=local
STORAGE_LOCAL_ROOT=./uploads
```

---

## 🔧 Service Details

### Directus CMS (Port 8055)
- **Role**: Main application backend and admin interface
- **Features**: REST API, GraphQL API, Admin dashboard
- **Access**: http://localhost:8055
- **Credentials**: admin@urbanvision.com / urbanvision123
- **Health Check**: http://localhost:8055/server/health

### PostgreSQL + PostGIS (Port 5432)
- **Role**: Primary database with geospatial capabilities
- **Version**: PostgreSQL 13 with PostGIS 3.4
- **Database**: `directus`
- **User**: `directus` / `directus`
- **Features**: ACID compliance, JSON support, spatial data

### Redis (Port 6379)
- **Role**: Caching and session storage
- **Version**: Redis 6 Alpine
- **Features**: Memory caching, session persistence

### MailDev (Ports 1080/1025)
- **Role**: Email testing in development
- **SMTP**: Port 1025 (for Directus)
- **Web Interface**: http://localhost:1080
- **Features**: Email capture, preview, debugging

### MinIO (Ports 9000/9001)
- **Role**: S3-compatible object storage
- **API**: Port 9000
- **Console**: http://localhost:9001
- **Credentials**: urbanvision / urbanvision123
- **Features**: File storage, S3 API compatibility

### Adminer (Port 8080)
- **Role**: Database administration interface
- **Access**: http://localhost:8080
- **Connection**: Server: `database`, User: `directus`, Password: `directus`, Database: `directus`
- **Features**: SQL queries, schema management, data export

---

## 🛠 CLI Commands Reference

### Service Management
```bash
# Start all services
./uv.sh start

# Stop all services
./uv.sh stop

# Restart all services
./uv.sh restart

# Check service status
./uv.sh status

# View logs (all services)
./uv.sh logs

# View logs (specific service)
./uv.sh logs directus
./uv.sh logs database
./uv.sh logs cache
```

### Database Operations
```bash
# Bootstrap Directus database
./uv.sh bootstrap

# Create database backup
./uv.sh db-backup

# Restore database from backup
./uv.sh db-restore backups/backup-20231201.sql

# Access PostgreSQL directly
docker exec -it uv-erp-database psql -U directus directus
```

### Schema Management
```bash
# Export current schema
./uv.sh schema-export

# Apply schema from file
./uv.sh schema-apply schema/production.yaml

# Compare schemas
docker exec uv-erp-directus npx directus schema diff ./schema/target.yaml
```

### Migration Management
```bash
# Create new migration
./uv.sh migration-create add_new_feature

# Run pending migrations
./uv.sh migration-run

# Check migration status
./uv.sh migration-status
```

### Information Commands
```bash
# Show all access points and credentials
./uv.sh access

# Show help and available commands
./uv.sh help
```

### Node.js Scripts (Alternative)
```bash
# Using npm/yarn scripts
npm start                # Same as ./uv.sh start
npm run bootstrap        # Same as ./uv.sh bootstrap
npm run backup          # Same as ./uv.sh db-backup
npm run status          # Same as ./uv.sh status
```

---

## 📊 Database Schema

### Core Collections Overview

#### CRM & Sales
- **leads** - Sales pipeline management
- **customers** - Customer relationship management
- **lead_notes** - Lead activity tracking

#### Project Management
- **projects** - Project lifecycle tracking
- **contracts** - Contract management with DocuSeal integration
- **contract_signers** - Electronic signature tracking

#### Procurement & Supply Chain
- **suppliers** - Supplier relationship management
- **products** - Product catalog
- **product_categories** - Product categorization
- **rfps** - Request for Proposal management
- **purchase_orders** - Purchase order tracking
- **po_line_items** - Purchase order details

#### Warehouse & Inventory
- **warehouses** - Warehouse locations
- **inventory** - Stock level tracking
- **goods_received_notes** - Delivery tracking
- **material_requests** - Internal material requests
- **stock_issues** - Stock distribution

#### Financial Management
- **sales_invoices** - Customer invoicing
- **purchase_invoices** - Vendor bill management
- **budgets** - Project budget tracking
- **chart_of_accounts** - QuickBooks account mapping

#### Quality & Compliance
- **quality_checks** - Quality control tracking
- **material_rejection_notes** - Quality rejection tracking

#### Human Resources
- **departments** - Organizational structure
- **employees** - Staff management
- **positions** - Job positions

#### Integration Collections
- **qb_sync_log** - QuickBooks synchronization tracking
- **qb_mapping_config** - Field mapping configuration
- **document_templates** - DocuSeal template management
- **signing_notifications** - Document signing notifications

### Key Relationships
```
Leads → Customers → Projects → Contracts
                 ↓              ↓
              Invoices      Signatures
                 ↓              ↓
              QuickBooks    DocuSeal

RFPs → Purchase Orders → GRNs → Inventory
  ↓         ↓             ↓        ↓
Suppliers  Invoices   Quality   Stock Issues
  ↓         ↓         Checks       ↓
Contracts QuickBooks     ↓     Material Requests
            ↓         Projects       ↓
        Accounting                Projects
```

---

## 🔗 Integration Points

### QuickBooks Online Integration

#### Features
- Bidirectional sync of customers, vendors, items, and transactions
- Real-time financial data synchronization
- Automated invoice and bill creation
- Chart of accounts mapping

#### Setup Process
1. Create QuickBooks app at [Intuit Developer](https://developer.intuit.com/)
2. Obtain OAuth2 credentials (Consumer Key/Secret)
3. Update environment variables in `.env`
4. Configure field mappings via Directus admin
5. Set up webhook endpoints for real-time sync

#### Sync Schedule
- **Real-time**: Customer/vendor updates via webhooks
- **Hourly**: Invoice and payment status updates
- **Daily**: Financial reports and reconciliation

### DocuSeal Integration

#### Features
- Automated contract generation
- Electronic signature workflows
- Multi-party signing support
- Audit trail and compliance

#### Setup Process
1. Sign up at [DocuSeal](https://www.docuseal.co/)
2. Generate API key in DocuSeal dashboard
3. Update environment variables in `.env`
4. Upload contract templates to DocuSeal
5. Configure template mappings in Directus

#### Workflow
1. Contract approved in Directus
2. Document generated from template
3. Signing invitations sent automatically
4. Status tracked in real-time
5. Completed documents stored in Directus

---

## 🔄 Development Workflow

### Initial Setup
```bash
# 1. Clone repository
git clone <repository-url>
cd urban-vision-erp

# 2. Copy environment template
cp .env.example .env

# 3. Generate new security keys (for production)
node -e "console.log('KEY=' + require('crypto').randomBytes(32).toString('hex'))"
node -e "console.log('SECRET=' + require('crypto').randomBytes(32).toString('hex'))"

# 4. Start environment
./setup.sh
```

### Daily Development
```bash
# Start services
./uv.sh start

# Check status
./uv.sh status

# View logs during development
./uv.sh logs directus

# Make schema changes in Directus admin
# Export schema changes
./uv.sh schema-export

# Commit changes
git add schema/
git commit -m "Update schema: add new collections"
```

### Schema Updates
```bash
# Option 1: Via Admin Interface
# 1. Make changes in Directus admin (http://localhost:8055)
# 2. Export schema: ./uv.sh schema-export
# 3. Commit to version control

# Option 2: Via Migrations
# 1. Create migration: ./uv.sh migration-create add_feature
# 2. Edit migration file in migrations/
# 3. Run migration: ./uv.sh migration-run
# 4. Export updated schema: ./uv.sh schema-export
```

### Testing Integrations
```bash
# Test email functionality
# - Send test emails through Directus
# - View emails at http://localhost:1080

# Test QuickBooks sync
# - Configure QB credentials in .env
# - Create test customer in Directus
# - Verify sync in QuickBooks sandbox

# Test DocuSeal workflow
# - Configure DocuSeal API key
# - Create test contract
# - Test signing workflow
```

### Database Management
```bash
# Daily backup
./uv.sh db-backup

# Reset development database
./uv.sh stop
rm -rf data/database/*
./uv.sh start
./uv.sh bootstrap

# Apply production schema to development
./uv.sh schema-apply schema/production.yaml
```

---

## 🚨 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check Docker status
docker info

# Check port conflicts
lsof -i :8055
lsof -i :5432

# Check logs
./uv.sh logs

# Reset everything
./uv.sh stop
docker system prune -f
./uv.sh start
```

#### Database Connection Issues
```bash
# Check database health
docker exec uv-erp-database pg_isready -U directus

# Check database logs
./uv.sh logs database

# Reset database
./uv.sh stop
rm -rf data/database/*
./uv.sh start
./uv.sh bootstrap
```

#### Directus Issues
```bash
# Check Directus logs
./uv.sh logs directus

# Reset Directus data but keep database
docker exec uv-erp-directus npx directus database migrate:down --all
docker exec uv-erp-directus npx directus bootstrap

# Complete reset
./uv.sh stop
rm -rf uploads/* data/
./setup.sh
```

#### Integration Issues
```bash
# QuickBooks connectivity
curl -H "Authorization: Bearer $QB_ACCESS_TOKEN" \
     "https://sandbox-quickbooks.api.intuit.com/v3/company/$QB_COMPANY_ID/companyinfo/$QB_COMPANY_ID"

# DocuSeal connectivity
curl -H "Authorization: Bearer $DOCUSEAL_API_KEY" \
     "https://api.docuseal.co/templates"

# Check integration logs
./uv.sh logs directus | grep -E "(QB|DocuSeal)"
```

### Log Analysis
```bash
# View real-time logs
./uv.sh logs directus | grep ERROR

# Export logs for analysis
./uv.sh logs > debug.log

# Database query logs
docker exec uv-erp-database tail -f /var/log/postgresql/postgresql-*.log

# Container resource usage
docker stats
```

### Performance Issues
```bash
# Check memory usage
docker stats

# Check disk usage
df -h
du -sh data/

# Optimize database
docker exec uv-erp-database psql -U directus directus -c "VACUUM ANALYZE;"

# Clear Redis cache
docker exec uv-erp-cache redis-cli FLUSHALL
```

---

## 🚀 Production Deployment

### Pre-Production Checklist

#### Security
- [ ] Generate new KEY and SECRET values
- [ ] Change all default passwords
- [ ] Configure HTTPS/SSL certificates
- [ ] Set up proper CORS origins
- [ ] Enable rate limiting
- [ ] Configure firewall rules

#### Environment
- [ ] Set up production database (managed PostgreSQL)
- [ ] Configure Redis cluster (if needed)
- [ ] Set up S3 bucket for file storage
- [ ] Configure SMTP server
- [ ] Set up monitoring and logging

#### Configuration
```bash
# Production environment variables
KEY=<new-production-key>
SECRET=<new-production-secret>
ADMIN_PASSWORD=<secure-password>
DB_HOST=<production-db-host>
DB_PASSWORD=<secure-db-password>
PUBLIC_URL=https://erp.urbanvision.com
CORS_ORIGIN=https://app.urbanvision.com
RATE_LIMITER_ENABLED=true
FORCE_HTTPS=true
```

### Deployment Methods

#### Docker Compose (Single Server)
```bash
# 1. Upload files to server
scp -r . user@server:/opt/urban-vision-erp/

# 2. Configure environment
cp .env.example .env
# Edit .env with production values

# 3. Deploy
docker compose up -d

# 4. Apply schema
./uv.sh schema-apply schema/production.yaml
```

#### Container Orchestration (Kubernetes/Docker Swarm)
```yaml
# Example docker-compose.prod.yml
version: '3.8'
services:
  directus:
    image: directus/directus:latest
    environment:
      - KEY=${KEY}
      - SECRET=${SECRET}
      - DB_HOST=${DB_HOST}
      - PUBLIC_URL=${PUBLIC_URL}
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
```

### Backup Strategy

#### Automated Backups
```bash
# Create backup script: /opt/scripts/backup.sh
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups"

# Database backup
pg_dump $DATABASE_URL > "$BACKUP_DIR/db_$DATE.sql"

# Schema backup
./uv.sh schema-export

# Upload to S3
aws s3 sync $BACKUP_DIR s3://urbanvision-backups/

# Retention (keep 30 days)
find $BACKUP_DIR -type f -mtime +30 -delete
```

#### Scheduled Backups
```bash
# Add to crontab
0 2 * * * /opt/scripts/backup.sh
0 12 * * * /opt/scripts/backup.sh
```

### Monitoring

#### Health Checks
```bash
# Application health
curl -f http://localhost:8055/server/health

# Database health
pg_isready -h $DB_HOST -U $DB_USER

# Integration health
curl -H "Authorization: Bearer $QB_ACCESS_TOKEN" \
     "$QB_API_URL/v3/company/$QB_COMPANY_ID/companyinfo/$QB_COMPANY_ID"
```

#### Metrics
- Response time monitoring
- Database connection pool status
- Memory and CPU usage
- Disk space utilization
- Integration sync success rates

### Scaling Considerations

#### Horizontal Scaling
- Load balancer configuration
- Session storage in Redis
- Shared file storage (S3)
- Database read replicas

#### Vertical Scaling
- Memory allocation for containers
- Database connection limits
- CPU resources for background jobs

---

## 📚 Additional Resources

### Documentation Links
- [Directus Documentation](https://docs.directus.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [QuickBooks API Documentation](https://developer.intuit.com/app/developer/qbo/docs/api)
- [DocuSeal API Documentation](https://docs.docuseal.co/)

### Community Resources
- [Directus Discord](https://discord.gg/directus)
- [Directus GitHub](https://github.com/directus/directus)
- [Urban Vision ERP GitHub](https://github.com/urban-vision/erp)

### Support Contacts
- **Development Team**: dev@urbanvision.com
- **System Administrator**: admin@urbanvision.com
- **Emergency Support**: +1-XXX-XXX-XXXX

---

## 📝 Changelog

### Version 1.0.0 (Current)
- Initial Docker Compose setup
- Core Directus configuration
- QuickBooks integration framework
- DocuSeal integration framework
- CLI management tools
- Basic schema design

### Planned Features
- Advanced reporting dashboard
- Mobile application
- API rate limiting
- Advanced audit logging
- Multi-tenant support
- Advanced workflow automation

---

**Last Updated**: June 16, 2025  
**Version**: 1.0.0  
**Maintainer**: Urban Vision Development Team