# Urban Vision ERP - Development Environment

## 🚀 Quick Start

This Docker Compose setup provides a complete development environment for Urban Vision ERP built on Directus CMS with integrated QuickBooks and DocuSeal functionality.

### Prerequisites

- Docker Desktop installed and running
- Node.js 18+ (for CLI operations)
- At least 4GB RAM available for containers

### Initial Setup

1. **Start the development environment:**
```bash
# Navigate to project directory
cd /Users/jneaimimacmini/dev/apps/uv-project

# Start all services
docker compose up -d

# Check service status
docker compose ps
```

2. **Wait for services to be ready:**
```bash
# Follow logs to see startup progress
docker compose logs -f directus

# Services are ready when you see: "Server started at port 8055"
```

## 📚 Documentation

- **[Complete Setup Reference](REFERENCE.md)** - Comprehensive documentation covering all aspects of the system
- **[Schema Design](schema/)** - Database schema and collection details
- **[Integration Guides](integrations/)** - QuickBooks and DocuSeal setup instructions

## 📋 What's Included

### Core Services
- **Directus CMS** (Port 8055) - Main ERP backend
- **PostgreSQL + PostGIS** (Port 5432) - Database with spatial capabilities
- **Redis** (Port 6379) - Caching and session storage

### Development Tools
- **MailDev** (Port 1080) - Email testing interface
- **MinIO** (Port 9000/9001) - S3-compatible storage for testing
- **Adminer** (Port 8080) - Database management interface

## 🌐 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **Directus Admin** | http://localhost:8055 | admin@urbanvision.com / urbanvision123 |
| **MailDev** | http://localhost:1080 | (Email testing - no login) |
| **MinIO Console** | http://localhost:9001 | urbanvision / urbanvision123 |
| **Adminer** | http://localhost:8080 | Server: database, User: directus, Password: directus, DB: directus |
| **PostgreSQL** | localhost:5432 | User: directus, Password: directus, DB: directus |

## 🔧 Initial Configuration

### 1. Bootstrap Directus Database

```bash
# Bootstrap the database with initial schema
docker exec uv-erp-directus npx directus bootstrap

# OR if you prefer step-by-step:
docker exec uv-erp-directus npx directus database install
docker exec uv-erp-directus npx directus database migrate:latest
```

### 2. Verify Installation

Visit http://localhost:8055 and login with:
- **Email:** admin@urbanvision.com  
- **Password:** urbanvision123

## 📁 Project Structure

```
urban-vision-erp/
├── docker-compose.yml          # Main Docker Compose configuration
├── README.md                   # This file
├── RESET_GUIDE.md             # Comprehensive reset operations guide
├── uv.sh                      # Development helper script
├── data/                      # Persistent data (auto-created)
│   ├── database/              # PostgreSQL data
│   └── minio/                 # MinIO data
├── uploads/                   # Directus file uploads
├── extensions/                # Custom Directus extensions
├── schema/                    # Schema snapshots and configurations
├── migrations/                # Database migrations
└── backups/                   # Database backups
```

## ⚡ Development Helper Script

We've included a powerful `uv.sh` script that simplifies common development tasks:

### Quick Commands
```bash
# Make script executable (first time only)
chmod +x ./uv.sh

# Start all services
./uv.sh start

# Check status
./uv.sh status

# View all access points
./uv.sh access

# Get help
./uv.sh help
```

### Reset Operations
```bash
# Quick daily reset (recommended for development)
./uv.sh dev-reset              # Creates backup + resets database + bootstraps

# Complete fresh start
./uv.sh fresh-start            # Complete clean environment with backup

# Individual reset options
./uv.sh reset-database         # Database only
./uv.sh reset-uploads          # Files only
./uv.sh reset-schema           # Schema only
./uv.sh reset-all              # Everything (nuclear option)
```

### Database Operations
```bash
# Backup and restore
./uv.sh db-backup              # Create timestamped backup
./uv.sh db-restore backup.sql  # Restore from backup

# Bootstrap fresh database
./uv.sh bootstrap
```

### Schema Management
```bash
# Export current schema
./uv.sh schema-export

# Apply schema from file
./uv.sh schema-apply schema/production.yaml
```

**📚 For detailed reset options and safety features, see [RESET_GUIDE.md](RESET_GUIDE.md)**

## 🛠 Development Workflow

### Schema Management

```bash
# Export current schema
docker exec uv-erp-directus npx directus schema snapshot /directus/schema/current.yaml

# Apply schema from file
docker exec uv-erp-directus npx directus schema apply /directus/schema/production.yaml

# Create new migration
docker exec uv-erp-directus npx directus database migrate:make add_new_feature

# Run pending migrations
docker exec uv-erp-directus npx directus database migrate:latest
```

### Extension Development

Extensions are auto-reloaded when `EXTENSIONS_AUTO_RELOAD=true`. Simply modify files in the `./extensions/` directory.

### Database Operations

```bash
# Access PostgreSQL directly
docker exec -it uv-erp-database psql -U directus directus

# Backup database
docker exec uv-erp-database pg_dump -U directus directus > backups/backup-$(date +%Y%m%d).sql

# Restore database
cat backups/backup-20231201.sql | docker exec -i uv-erp-database psql -U directus directus
```

## 🔌 Integration Setup

### QuickBooks Integration

1. **Create QuickBooks App:**
   - Visit [Intuit Developer](https://developer.intuit.com/)
   - Create new app and get OAuth2 credentials

2. **Update Environment Variables:**
```bash
# Edit docker-compose.yml and add:
QB_CONSUMER_KEY: "your-consumer-key"
QB_CONSUMER_SECRET: "your-consumer-secret"
QB_ACCESS_TOKEN: "your-access-token"
QB_ACCESS_TOKEN_SECRET: "your-access-token-secret"
QB_COMPANY_ID: "your-company-id"
QB_SANDBOX: "true"  # Set to false for production
```

3. **Restart Directus:**
```bash
docker compose restart directus
```

### DocuSeal Integration

1. **Get DocuSeal API Key:**
   - Sign up at [DocuSeal](https://www.docuseal.co/)
   - Generate API key in settings

2. **Update Environment Variables:**
```bash
# Edit docker-compose.yml and add:
DOCUSEAL_API_KEY: "your-api-key"
```

3. **Restart Directus:**
```bash
docker compose restart directus
```

## 🔍 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check logs
docker compose logs

# Check port conflicts
netstat -an | grep -E ":(5432|6379|8055|8080|9000|9001|1080|1025)"

# Restart specific service
docker compose restart directus
```

**Database connection issues:**
```bash
# Verify database is running
docker exec uv-erp-database pg_isready -U directus

# Check database logs
docker compose logs database
```

**Directus shows errors:**
```bash
# Check Directus logs
docker compose logs directus

# Restart with fresh logs
docker compose restart directus && docker compose logs -f directus
```

### Reset Environment

For comprehensive reset options with safety features, use the helper script:

```bash
# Recommended: Quick development reset (creates backup automatically)
./uv.sh dev-reset

# Complete fresh start (safest option)
./uv.sh fresh-start

# Manual Docker reset (⚠️ DESTRUCTIVE - loses all data)
docker compose down -v
sudo rm -rf data/
mkdir -p data/{database,minio}
docker compose up -d
```

**💡 Pro Tip:** Use `./uv.sh help` to see all available reset options with different safety levels.

## 📈 Production Notes

When deploying to production:

1. **Change all default passwords**
2. **Use proper SSL certificates**
3. **Set strong, unique security keys**
4. **Configure proper CORS origins**
5. **Enable rate limiting**
6. **Use external managed databases**
7. **Set up proper backup strategies**
8. **Configure monitoring and logging**

## 🎯 Next Steps

1. **Set up Urban Vision schema** using the CLI tools
2. **Configure user roles and permissions**
3. **Set up automated workflows** 
4. **Integrate with QuickBooks** for financial data
5. **Configure DocuSeal** for contract signing
6. **Import initial data** (customers, suppliers, products)
7. **Train team members** on the new system

## 📞 Support

For development issues:
- Check the logs: `docker compose logs directus`
- Visit Directus documentation: https://docs.directus.io
- Review Urban Vision schema documentation in the project

---

**Happy developing! 🚀**