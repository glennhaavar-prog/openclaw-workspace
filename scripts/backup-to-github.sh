#!/bin/bash
# OpenClaw Automated GitHub Backup Script
# Runs every 12 hours via OpenClaw cron job
# Backs up: openclaw-workspace and ai-erp to GitHub

set -e  # Exit on error

LOG_FILE="$HOME/.openclaw/logs/github-backup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')
WORKSPACE_DIR="$HOME/.openclaw/workspace"
AI_ERP_DIR="$WORKSPACE_DIR/ai-erp"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Function to check repo size and warn if approaching limits
check_repo_size() {
    local repo_path=$1
    local repo_name=$2
    local size_mb=$(du -sm "$repo_path" | cut -f1)
    local warning_threshold=1800  # Warn at 1.8 GB (2 GB limit)
    
    log "📊 $repo_name size: ${size_mb} MB"
    
    if [ $size_mb -gt $warning_threshold ]; then
        log "⚠️  WARNING: $repo_name is ${size_mb} MB (approaching 2 GB GitHub limit!)"
        return 1
    elif [ $size_mb -gt 1000 ]; then
        log "ℹ️  $repo_name is over 1 GB but still safe"
    fi
    return 0
}

# Function to backup a git repository
backup_repo() {
    local repo_path=$1
    local repo_name=$2
    
    log "🔄 Starting backup for $repo_name..."
    
    if [ ! -d "$repo_path" ]; then
        log "❌ ERROR: Repository not found at $repo_path"
        return 1
    fi
    
    cd "$repo_path"
    
    # Check if it's a git repository
    if [ ! -d .git ]; then
        log "❌ ERROR: $repo_path is not a git repository"
        return 1
    fi
    
    # Check repo size before backup
    check_repo_size "$repo_path" "$repo_name"
    
    # Check for changes
    if git diff --quiet && git diff --cached --quiet; then
        log "✅ $repo_name: No changes to commit"
    else
        # Stage all changes
        git add -A
        
        # Commit changes
        local commit_msg="Automated backup: $TIMESTAMP"
        if git commit -m "$commit_msg"; then
            log "✅ $repo_name: Changes committed"
        else
            log "❌ $repo_name: Commit failed"
            return 1
        fi
    fi
    
    # Push to GitHub
    if git push origin main 2>&1 | tee -a "$LOG_FILE"; then
        log "✅ $repo_name: Successfully pushed to GitHub"
    else
        log "❌ $repo_name: Push failed"
        return 1
    fi
    
    return 0
}

# Main backup execution
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🚀 Starting automated GitHub backup"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

backup_success=true

# Backup openclaw-workspace
if backup_repo "$WORKSPACE_DIR" "openclaw-workspace"; then
    log "✅ openclaw-workspace backup complete"
else
    log "❌ openclaw-workspace backup failed"
    backup_success=false
fi

echo "" >> "$LOG_FILE"

# Backup ai-erp (if it exists)
if [ -d "$AI_ERP_DIR" ]; then
    if backup_repo "$AI_ERP_DIR" "ai-erp"; then
        log "✅ ai-erp backup complete"
    else
        log "❌ ai-erp backup failed"
        backup_success=false
    fi
else
    log "ℹ️  ai-erp directory not found, skipping"
fi

echo "" >> "$LOG_FILE"

# Summary
if [ "$backup_success" = true ]; then
    log "🎉 All backups completed successfully!"
    exit 0
else
    log "⚠️  Some backups failed - check log for details"
    exit 1
fi
