# Urban Vision ERP - Reset Operations Guide

This guide explains the different reset operations available in the `uv.sh` script to help you manage your development environment effectively.

## 🎯 Quick Reference

| Command | Purpose | Data Loss | Backup Created | Time Required |
|---------|---------|-----------|---------------|---------------|
| `dev-reset` | Quick development reset | Database only | ✅ Yes | ~2 minutes |
| `fresh-start` | Complete fresh environment | Everything | ✅ Yes | ~3 minutes |
| `reset-database` | Database only | Database only | ❌ No | ~1 minute |
| `reset-uploads` | Files only | Uploads only | ❌ No | ~30 seconds |
| `reset-schema` | Schema only | Database structure | ❌ No | ~1 minute |
| `reset-all` | Nuclear option | Everything | ❌ No | ~2 minutes |

## 🔧 Reset Commands Explained

### 1. `./uv.sh dev-reset` - Recommended for Development
**Purpose**: Quick reset for daily development work
**What it does**:
- ✅ Creates automatic backup before reset
- 🗑️ Resets database completely
- 🚀 Automatically bootstraps fresh Directus
- 📁 Keeps uploads and extensions intact

**When to use**:
- Daily development workflow
- Testing schema changes
- Cleaning up test data
- Starting fresh but keeping files

```bash
./uv.sh dev-reset
```

### 2. `./uv.sh fresh-start` - Complete Fresh Environment
**Purpose**: Start completely fresh with backup safety
**What it does**:
- ✅ Creates backup if database exists
- 🗑️ Removes all data, uploads, volumes
- 🧹 Cleans all Docker volumes
- 🚀 Starts services and bootstraps automatically
- 📋 Shows access credentials

**When to use**:
- Beginning new development cycle
- Major updates or changes
- Corrupted environment recovery
- Demo preparation

```bash
./uv.sh fresh-start
```

### 3. `./uv.sh reset-database` - Database Only
**Purpose**: Reset just the database, keep everything else
**What it does**:
- ⚠️ Requires manual confirmation (`RESET`)
- 🗑️ Completely removes database volume
- 📂 Keeps uploads, extensions, config files
- 🚀 Restarts services (requires manual bootstrap)

**When to use**:
- Schema corruption issues
- Major database changes
- Keep uploads but fresh DB

```bash
./uv.sh reset-database
# Then manually run:
./uv.sh bootstrap
```

### 4. `./uv.sh reset-uploads` - Files Only
**Purpose**: Clear uploaded files while keeping database
**What it does**:
- 🗑️ Removes all files in uploads directory
- 📁 Recreates empty uploads folder
- 💾 Keeps database intact
- ⚡ Fast operation

**When to use**:
- Clean up test files
- Storage space issues
- Fresh file environment

```bash
./uv.sh reset-uploads
```

### 5. `./uv.sh reset-schema` - Schema Structure Only
**Purpose**: Reset database schema but keep container/volume structure
**What it does**:
- 🗑️ Drops and recreates database
- 🔄 Restarts Directus container
- 📊 Keeps Docker volumes
- 🚀 Requires manual bootstrap

**When to use**:
- Schema migration issues
- Faster than full reset
- Keep Docker state

```bash
./uv.sh reset-schema
# Then manually run:
./uv.sh bootstrap
```

### 6. `./uv.sh reset-all` - Nuclear Option ☢️
**Purpose**: Complete destructive reset (USE WITH CAUTION)
**What it does**:
- ⚠️ Requires manual confirmation (`RESET-ALL`)
- 🗑️ Removes ALL data, uploads, volumes
- 🧹 Prunes Docker volumes
- 📁 Recreates directory structure
- 🚀 Starts services (requires manual bootstrap)

**When to use**:
- Last resort for corrupted environment
- Major version upgrades
- Complete clean slate needed

```bash
./uv.sh reset-all
# Then manually run:
./uv.sh bootstrap
```

## 🛡️ Safety Features

### Confirmation Prompts
- **Database operations**: Require typing `RESET` to confirm
- **Complete reset**: Requires typing `RESET-ALL` to confirm
- **File operations**: Require Y/N confirmation

### Automatic Backups
Commands that create automatic backups:
- `dev-reset`: Always creates backup before reset
- `fresh-start`: Creates backup if database exists

### Backup Location
All backups are stored in `backups/` directory with timestamp:
```
backups/
├── backup-20241216_143022.sql    # Database backup
├── backup-20241216_150315.sql    # Another backup
└── ...
```

## 🔄 Common Workflows

### Daily Development Reset
```bash
# Quick daily reset with backup
./uv.sh dev-reset
```

### Weekly Fresh Start
```bash
# Complete fresh environment
./uv.sh fresh-start
```

### Schema Development Cycle
```bash
# 1. Make schema changes in admin
./uv.sh schema-export

# 2. Test reset
./uv.sh reset-schema
./uv.sh bootstrap
./uv.sh schema-apply schema/schema-YYYYMMDD_HHMMSS.yaml

# 3. If satisfied, commit schema file
git add schema/
git commit -m "Updated schema with new collections"
```

### Emergency Recovery
```bash
# If environment is completely broken
./uv.sh reset-all
./uv.sh bootstrap

# Or restore from backup
./uv.sh db-restore backups/backup-20241216_143022.sql
```

## 📊 Data Management

### What Gets Preserved vs. Lost

| Component | dev-reset | fresh-start | reset-database | reset-uploads | reset-schema | reset-all |
|-----------|-----------|-------------|----------------|---------------|--------------|-----------|
| Database | ❌ Lost | ❌ Lost | ❌ Lost | ✅ Kept | ❌ Lost | ❌ Lost |
| Uploads | ✅ Kept | ❌ Lost | ✅ Kept | ❌ Lost | ✅ Kept | ❌ Lost |
| Extensions | ✅ Kept | ❌ Lost | ✅ Kept | ✅ Kept | ✅ Kept | ❌ Lost |
| Schema | ✅ Kept | ✅ Kept | ✅ Kept | ✅ Kept | ✅ Kept | ✅ Kept |
| Migrations | ✅ Kept | ✅ Kept | ✅ Kept | ✅ Kept | ✅ Kept | ✅ Kept |
| Docker Volumes | ✅ Kept | ❌ Lost | ❌ Lost | ✅ Kept | ✅ Kept | ❌ Lost |
| Auto Backup | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |

## ⚡ Performance Notes

### Reset Speed Comparison
- `reset-uploads`: ~30 seconds
- `reset-schema`: ~1 minute  
- `reset-database`: ~1-2 minutes
- `dev-reset`: ~2 minutes (includes backup + bootstrap)
- `reset-all`: ~2 minutes
- `fresh-start`: ~3 minutes (includes backup + bootstrap)

### Resource Requirements
- **CPU**: Minimal during reset, higher during bootstrap
- **Memory**: ~2GB for Docker containers
- **Disk**: Backups require additional space (typically 10-50MB per backup)

## 🔧 Troubleshooting

### Reset Command Won't Run
```bash
# Make sure script is executable
chmod +x ./uv.sh

# Check Docker is running
docker info
```

### Services Won't Start After Reset
```bash
# Check service status
./uv.sh status

# View logs for issues
./uv.sh logs

# Manual restart
./uv.sh stop
./uv.sh start
```

### Bootstrap Fails
```bash
# Check database connection
docker exec uv-erp-database pg_isready -U directus

# Manual bootstrap with logs
docker exec uv-erp-directus npx directus bootstrap
```

### Out of Disk Space
```bash
# Clean old backups (keeps last 30 days)
find backups/ -type f -mtime +30 -delete

# Clean Docker system
docker system prune -f

# Check disk usage
du -sh backups/ data/ uploads/
```

## 📚 Best Practices

### 1. Regular Backups
```bash
# Weekly manual backup
./uv.sh db-backup

# Export schema after changes
./uv.sh schema-export
```

### 2. Version Control
- Always commit schema files after changes
- Keep track of major resets in commit messages
- Tag important development milestones

### 3. Safe Development
- Use `dev-reset` for daily work (automatic backup)
- Test schema changes on copies first
- Keep multiple backup versions for important data

### 4. Documentation
- Document custom extensions before reset
- Note any manual configuration changes
- Keep deployment notes updated

## 🚀 Quick Start Checklist

For new developers joining the project:

```bash
# 1. Clone and setup
git clone <repository>
cd uv-project

# 2. Fresh start
./uv.sh fresh-start

# 3. Verify access
./uv.sh access

# 4. Check status
./uv.sh status
```

Default credentials after fresh start:
- **Email**: `admin@urbanvision.com`
- **Password**: `urbanvision123`

---

**💡 Pro Tip**: Use `dev-reset` for most development work as it's safe, quick, and includes automatic backups. Save `fresh-start` for when you need a completely clean environment.