# OpenClaw Automated Backup System

## 🎯 Overview

This system provides automated, 12-hour interval backups of your OpenClaw workspace and AI-ERP project to GitHub, with storage monitoring and failure alerts.

## 📦 What Gets Backed Up

1. **openclaw-workspace** → https://github.com/glennhaavar-prog/openclaw-workspace.git
   - Configuration files (sanitized, no secrets)
   - Agent files (SOUL.md, USER.md, AGENTS.md, etc.)
   - Memory files
   - Scripts and automation
   - Project documentation

2. **ai-erp** → https://github.com/glennhaavar-prog/ai-erp.git
   - Full ERP application code
   - Backend and frontend
   - Infrastructure configs
   - Documentation

## ⚙️ System Components

### 1. Backup Script
**Location:** `scripts/backup-to-github.sh`

**What it does:**
- Checks for changes in both repositories
- Commits all changes with timestamp
- Pushes to GitHub
- Monitors repository sizes
- Logs all operations to `~/.openclaw/logs/github-backup.log`
- Warns if approaching GitHub storage limits (2 GB per repo)

**Manual execution:**
```bash
cd ~/.openclaw/workspace
./scripts/backup-to-github.sh
```

### 2. Storage Monitor
**Location:** `scripts/check-github-storage.sh`

**What it does:**
- Reports current size of each repository
- Calculates % of GitHub free tier limit (2 GB/repo)
- Shows top 10 largest files
- Color-coded warnings (green=OK, yellow=warning, red=critical)

**Manual execution:**
```bash
cd ~/.openclaw/workspace
./scripts/check-github-storage.sh
```

### 3. Cron Job
**Location:** `~/.openclaw/cron/jobs.json`

**Job ID:** `c9e8522d-6c7b-4f08-9e6e-837d81947714`

**Schedule:** Every 12 hours (43200000 ms)

**Status:** ✅ Enabled

The cron job automatically runs the backup script every 12 hours. No manual intervention required!

## 📊 GitHub Storage Limits (Free Account)

| Limit Type | Value |
|------------|-------|
| Per repository | 2 GB |
| Warning threshold | 1.8 GB (90%) |
| Critical threshold | 1.9 GB (95%) |
| Current workspace size | ~1 MB |
| Current ai-erp size | ~319 MB |
| **Total usage** | **~320 MB (16%)** |

**Status:** ✅ Healthy - Plenty of space remaining

## 🔔 Monitoring & Alerts

### Automatic Monitoring
- Every backup run checks repository sizes
- Logs warnings if approaching limits
- Backup log: `~/.openclaw/logs/github-backup.log`

### Manual Monitoring
Run storage check anytime:
```bash
~/.openclaw/workspace/scripts/check-github-storage.sh
```

### Alert Levels

**🟢 GREEN (OK):** < 1.8 GB
- Everything normal
- No action needed

**🟡 YELLOW (Warning):** 1.8 - 1.9 GB
- Getting close to limit
- Review large files
- Consider cleanup

**🔴 RED (Critical):** > 1.9 GB
- Approaching hard limit
- Immediate action required
- Clean up or upgrade plan

## 🛠️ Maintenance Tasks

### Weekly
```bash
# Check storage health
~/.openclaw/workspace/scripts/check-github-storage.sh
```

### Monthly
```bash
# Review backup logs
tail -100 ~/.openclaw/logs/github-backup.log

# Check Git object sizes
cd ~/.openclaw/workspace && git count-objects -vH
cd ~/.openclaw/workspace/ai-erp && git count-objects -vH
```

### When Approaching Limits
1. Run storage check to identify large files
2. Remove unnecessary files (node_modules, logs, temp files)
3. Update `.gitignore` to exclude large files
4. Consider Git LFS for large binary files
5. Or upgrade to GitHub Pro (larger limits)

## 🔐 Security Notes

**✅ What IS backed up:**
- Sanitized configs (secrets replaced with placeholders)
- Code and documentation
- Safe metadata

**❌ What is NOT backed up:**
- Real API keys or tokens
- `~/.openclaw/credentials/` (ignored)
- `~/.openclaw/telegram/` (ignored)
- Local secrets or passwords

**Gitignore protection:**
The workspace `.gitignore` excludes:
- Credentials directory
- Telegram data
- Local secrets
- Temporary files

## 🚨 Troubleshooting

### Backup fails to push
```bash
# Check if you're logged into GitHub
cd ~/.openclaw/workspace
git remote -v

# Test manual push
git push origin main

# If auth fails, may need to update credentials
```

### Cron job not running
```bash
# Check OpenClaw gateway status
openclaw gateway status

# View cron jobs
cat ~/.openclaw/cron/jobs.json

# Check if job is enabled (should be "enabled": true)
```

### Large repository size
```bash
# Find what's taking space
~/.openclaw/workspace/scripts/check-github-storage.sh

# Git garbage collection (may help)
cd ~/.openclaw/workspace
git gc --aggressive --prune=now
```

## 📝 Backup Log Format

Each backup run logs:
- Timestamp
- Repository sizes
- Changes detected
- Commit status
- Push status
- Any warnings or errors

Example:
```
[2026-02-04 18:00:00 UTC] 🚀 Starting automated GitHub backup
[2026-02-04 18:00:00 UTC] 📊 openclaw-workspace size: 1 MB
[2026-02-04 18:00:01 UTC] ✅ openclaw-workspace: No changes to commit
[2026-02-04 18:00:01 UTC] ✅ openclaw-workspace: Successfully pushed to GitHub
[2026-02-04 18:00:01 UTC] 📊 ai-erp size: 319 MB
[2026-02-04 18:00:02 UTC] ✅ ai-erp: Changes committed
[2026-02-04 18:00:05 UTC] ✅ ai-erp: Successfully pushed to GitHub
[2026-02-04 18:00:05 UTC] 🎉 All backups completed successfully!
```

## 🔄 Next Backup

The next automatic backup will run 12 hours after the cron job was created or last ran. To check:

```bash
# View cron job state
cat ~/.openclaw/cron/jobs.json | grep -A 5 "GitHub Backup"
```

## 📚 Additional Resources

- [GitHub Storage Limits](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-storage-and-bandwidth-usage)
- [Git LFS (Large File Storage)](https://git-lfs.github.com/)
- [OpenClaw Cron Jobs Documentation](https://docs.openclaw.com/cron)

---

**System Status:** ✅ Fully operational  
**Last Updated:** 2026-02-04  
**Next Review:** Weekly storage check recommended
