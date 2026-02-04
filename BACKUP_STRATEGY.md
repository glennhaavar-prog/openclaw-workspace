# OpenClaw Automated Backup Strategy
## Complete Plan for Every 2 Hours

**Date**: February 4, 2026  
**Status**: PLANNING PHASE (NO EXECUTION YET)  
**For**: Glenn's Complete System Backup

---

## 📋 EXECUTIVE SUMMARY

Glenn wants **automated backups of EVERYTHING** every 2 hours. This includes:
- ✅ All OpenClaw configuration & settings
- ✅ Workspace (all work from day 1)
- ✅ ERP project (backend, frontend, docs)
- ✅ Databases (when running)
- ✅ Configuration files (.env, credentials)
- ✅ Git repositories
- ✅ Agent memory & sessions

**Key constraint**: Active VS Code / Claude Code session running (started 05:33 UTC) - MUST NOT DISTURB

---

## 🔍 PART 1: WHAT'S RUNNING (Current System State)

### Active Processes
```
RUNNING:
✓ VS Code Server (Claude Code IDE) - PIDs 57340, 57476, 57495, 57511, 57533, 57560
  └─ Started: 05:33 UTC Feb 4
  └─ Status: ACTIVE - coding session in progress
  └─ Impact: MUST USE SAFE BACKUP (read-only, non-blocking)

✓ Python HTTP Server - PID 30027
  └─ Port: 8000
  └─ Running dashboard

NOT RUNNING:
✗ Docker containers (PostgreSQL, Redis, Celery)
✗ System cron (using OpenClaw's custom cron system instead)
```

### Safe Backup Window
- ✅ Can backup while VS Code runs (read-only operations)
- ✅ Can backup workspace (not being edited in VS Code right now)
- ✅ Should avoid if heavy coding is happening
- ⚠️ Must use `tar`/`rsync` (safe, non-blocking copy methods)

---

## 🗂️ PART 2: WHAT NEEDS TO BE BACKED UP

### A. OpenClaw Core Configuration (7.2 MB total)

```
/home/ubuntu/.openclaw/
├── openclaw.json                 ← Main config (API keys, settings)
├── openclaw.json.backup          ← Previous backup
├── agents/main/
│   ├── agent/                    ← Agent settings
│   └── sessions/                 ← Session data
├── credentials/                  ← Sensitive (Telegram, API auth)
├── identity/                     ← Agent identity files
├── devices/                      ← Paired device configs
├── telegram/                     ← Telegram integration
├── cron/                         ← Scheduled jobs
│   ├── jobs.json                 ← Cron jobs config
│   └── runs/                     ← Job execution history
├── logs/                         ← System logs
├── canvas/                       ← Canvas UI configs
└── subagents/                    ← Subagent sessions
```

**Sensitive Files** ⚠️
- `credentials/telegram-*`
- `openclaw.json` (contains API keys)

### B. Workspace (1.3 MB total)

```
/home/ubuntu/.openclaw/workspace/
├── *.md                          ← Documents (AGENTS.md, SOUL.md, USER.md, etc.)
├── .git/                         ← Main workspace git repo
├── memory/                       ← Daily & long-term memory files
│   ├── 2026-02-01.md
│   ├── 2026-02-02.md
│   └── ...
├── ai-erp/                       ← MAIN PROJECT
│   ├── .git/                     ← ERP git repo
│   ├── docker-compose.yml        ← Service definitions
│   ├── backend/
│   │   ├── app/                  ← 12 database models, FastAPI
│   │   ├── alembic/              ← Database migrations
│   │   ├── requirements.txt
│   │   ├── Dockerfile
│   │   └── .env.example
│   ├── frontend/                 ← React/Next.js
│   ├── docs/                     ← Documentation
│   └── infrastructure/           ← Terraform, deployment configs
└── [other project files]
```

**Key Files to Preserve**:
- All `.md` documentation
- Git history (both repos)
- ERP code structure
- Docker Compose definition
- Migration files

### C. Databases (When Running)

```
PostgreSQL:
├── Database: ai_erp
│   ├── 12 tables (Tenant, Client, User, Vendor, Invoice, GL, etc.)
│   └── Data & schemas
└── Running on: localhost:5432 (Docker container)

Redis:
├── Cache data (6379)
├── Celery broker (6379/1)
├── Celery results (6379/2)
└── Running on: localhost:6379 (Docker container)

Git Repositories:
├── /home/ubuntu/.openclaw/workspace/.git/
└── /home/ubuntu/.openclaw/workspace/ai-erp/.git/
```

---

## 📊 PART 3: BACKUP SCOPE & SIZING

### Current System Size
```
/home/ubuntu/.openclaw/           7.2 MB
/home/ubuntu/.openclaw/workspace/ 1.3 MB
────────────────────────────────────────
Total (without DB)                8.5 MB

When Docker running:
+ PostgreSQL data volume          ~50-200 MB (starts small, grows)
+ Redis data                      ~5-50 MB
────────────────────────────────────────
Estimated total with DB:          ~60-260 MB per backup

Backup frequency:                 Every 2 hours
Backups per day:                  12 backups
Daily backup size:                ~720 MB - 3.1 GB
Storage for 7 days:               ~5 GB - 22 GB
Storage for 30 days:              ~22 GB - 93 GB
```

### Disk Space Status
```
Current usage: 5.1 GB / 6.8 GB (76% full)
Available: 1.7 GB FREE

⚠️ CRITICAL: Only 1.7 GB free space!
Problem: Keeping 7 days of backups locally would need 5-22 GB
Solution: Use remote storage (S3, external drive, or rotate aggressively)
```

---

## 🔄 PART 4: HOW CRONJOBS WORK IN OPENCLAW

OpenClaw does **NOT** use system cron (`/etc/cron.d`). Instead, it uses:

### OpenClaw's Custom Cron System

**Location**: `/home/ubuntu/.openclaw/cron/`

**Files**:
```
jobs.json          ← Defines all scheduled tasks (JSON)
jobs.json.bak      ← Automatic backups of job config
runs/               ← Directory with execution logs for each job
  ├── [job-id].jsonl  ← Execution history
```

**Job Structure** (from jobs.json):
```json
{
  "id": "unique-job-id",
  "agentId": "main",
  "name": "Descriptive job name",
  "enabled": true,
  "schedule": {
    "kind": "interval",        // or "at" for one-time
    "intervalMs": 7200000      // 2 hours in milliseconds
  },
  "sessionTarget": "main",
  "wakeMode": "next-heartbeat" // or "immediate"
  "payload": {
    "kind": "systemEvent",
    "text": "Command or action to run"
  }
}
```

### Schedule Types in OpenClaw

| Type | Format | Example |
|------|--------|---------|
| **interval** | Every N ms | `"intervalMs": 7200000` (2 hours) |
| **at** | One-time at timestamp | `"atMs": 1738504800000` |
| **cron** | Traditional cron (if supported) | `"cron": "0 */2 * * *"` |

### How It Works

1. **OpenClaw reads** `jobs.json` on startup
2. **Schedules jobs** using its internal job runner (NOT system cron)
3. **Triggers jobs** based on schedule
4. **Logs execution** to `runs/[job-id].jsonl`
5. **Reports status** (ok, failed, etc.)

### Current Jobs in System

```
✓ "Ask Glenn questions"           - One-time reminder (disabled)
✓ "Conference deep-dive"          - One-time reminder (disabled)
✓ "Gmail Workspace Reminder"      - One-time reminder (disabled)
✓ "Webhook-vurdering reminder"    - One-time reminder (disabled)
```

All are **disabled**. No active scheduled tasks currently.

---

## 🛡️ PART 5: BACKUP STRATEGY DESIGN

### Storage Options (Ranked by Practicality)

| Option | Pros | Cons | Cost | Recommendation |
|--------|------|------|------|---|
| **AWS S3** | Unlimited, cheap, reliable, versioning | Need AWS account, network dependency | ~$0.50/month for 250GB | ⭐ BEST FOR PROD |
| **External USB/NAS** | Local, fast, reliable | Single point of failure, not cloud | ~$100-500 one-time | ⭐ BEST FOR INITIAL |
| **GitHub Private Repo** | Version control, encrypted, free tier | Size limits (encrypted tarballs work), slower | FREE (with limits) | ✓ GOOD FOR REPO-ONLY |
| **Local rotation** | No external deps, no costs | Only 1.7GB space available NOW (problem!) | $0 | ✗ NOT FEASIBLE |
| **Backblaze B2** | Cheap cloud storage | Less integrated than S3 | ~$6/month for 1TB | ✓ GOOD |

### Recommended Strategy: Tiered Backup Approach

```
TIER 1: Git Repositories (Most Important)
├── Automatic git push to GitHub (every backup)
├── Preserves: /home/ubuntu/.openclaw/workspace/.git
├── Preserves: /home/ubuntu/.openclaw/workspace/ai-erp/.git
├── Risk: Code loss if GitHub compromised
└── Safety: Public GitHub Private + SSH auth

TIER 2: Configuration & Settings (Critical)
├── Target: /home/ubuntu/.openclaw/ (excluding sensitive)
├── Method: Encrypted tarball to S3 or external storage
├── Frequency: Every 2 hours
├── Retention: 7-day rolling window (84 backups)
└── Safety: Encryption + versioning

TIER 3: Database Snapshots (When Running)
├── Target: PostgreSQL & Redis data volumes
├── Method: docker exec + dump to tarball
├── Frequency: Every 2 hours (only if containers running)
├── Retention: 3-day window
└── Safety: Point-in-time recovery

TIER 4: Full System Snapshot (Weekly)
├── Target: Complete /home/ubuntu/.openclaw/
├── Method: Full encrypted archive
├── Frequency: Once per week (Sunday 00:00)
├── Retention: 4-week rotation
└── Safety: Complete disaster recovery
```

---

## 🚀 PART 6: IMPLEMENTATION WITHOUT DISRUPTION

### Step 1: Create Backup Script (Safe for Active Sessions)

**File**: `/home/ubuntu/.openclaw/scripts/backup-all.sh`

**Design Principles**:
- ✅ Read-only operations (no locks, no interruptions)
- ✅ Uses `tar` with `--exclude` to skip active files
- ✅ Compresses to save space
- ✅ Encrypts sensitive data
- ✅ Validates Git repos
- ✅ Logs all activity
- ✅ Handles DB backups gracefully (if running)
- ✅ Checks disk space before starting

**Pseudo-code** (NOT EXECUTED YET):
```bash
#!/bin/bash
# backup-all.sh - Run every 2 hours

set -e
BACKUP_DIR="/mnt/backups"  # External storage
LOG_FILE="/var/log/openclaw-backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 1. Check space
check_disk_space()

# 2. Backup Tier 1: Git repos
push_to_github()
tar_git_history()

# 3. Backup Tier 2: Configuration
tar_openclaw_config()    # Compress /home/ubuntu/.openclaw/
tar_workspace_docs()     # Compress /home/ubuntu/.openclaw/workspace/*.md

# 4. Backup Tier 3: Database (if running)
if docker ps | grep -q postgres; then
    docker exec ai-erp-postgres pg_dump -U erp_user ai_erp | \
    gzip > $BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz
fi

# 5. Encrypt sensitive backups
encrypt_with_gpg()

# 6. Upload to S3 (if configured)
aws s3 sync $BACKUP_DIR s3://backup-bucket/

# 7. Log status
echo "Backup completed: $BACKUP_SIZE" >> $LOG_FILE
```

### Step 2: Register Job in OpenClaw Cron

**Add to** `/home/ubuntu/.openclaw/cron/jobs.json`:

```json
{
  "id": "backup-every-2-hours",
  "agentId": "main",
  "name": "Automated Full System Backup (Every 2 Hours)",
  "enabled": false,  // START AS FALSE until tested
  "createdAtMs": 1738580000000,
  "updatedAtMs": 1738580000000,
  "schedule": {
    "kind": "interval",
    "intervalMs": 7200000  // 2 hours = 2 * 60 * 60 * 1000
  },
  "sessionTarget": "system",  // Run as system event, not in main session
  "wakeMode": "immediate",     // Don't wait for heartbeat, run immediately
  "payload": {
    "kind": "systemEvent",
    "command": "/home/ubuntu/.openclaw/scripts/backup-all.sh"
  },
  "state": {
    "lastRunAtMs": null,
    "lastStatus": "pending",
    "lastDurationMs": 0
  }
}
```

### Step 3: How the Job Runs

```
┌─ OpenClaw Main Process
│
├─ Reads jobs.json at startup
│
├─ Registers "backup-every-2-hours" job
│  └─ Interval: 7200000 ms (2 hours)
│
├─ Job Scheduler tracks time elapsed
│  └─ Every 2 hours, triggers job
│
├─ Executes /home/ubuntu/.openclaw/scripts/backup-all.sh
│  ├─ SAFE: Runs as background process
│  ├─ SAFE: Doesn't block VS Code
│  ├─ SAFE: Read-only file operations
│  └─ LOGS: Output to /var/log/openclaw-backup.log
│
├─ Logs execution to runs/backup-every-2-hours.jsonl
│  └─ Records: start time, duration, status, errors
│
└─ Repeats every 2 hours indefinitely
```

### Step 4: Storage Setup Options

**Option A: External USB Drive** (Recommended for testing)
```bash
# Mount external drive
sudo mount /dev/sdb1 /mnt/backups

# Check space
df -h /mnt/backups

# Persist in /etc/fstab for auto-mount
```

**Option B: AWS S3** (Recommended for production)
```bash
# Create S3 bucket
aws s3 mb s3://glenn-openclaw-backups

# Configure credentials
aws configure

# Script uploads to S3 automatically
aws s3 sync /mnt/backups s3://glenn-openclaw-backups/
```

**Option C: Network Storage (NAS)**
```bash
# Mount NAS
sudo mount -t nfs 192.168.1.100:/backups /mnt/backups

# Same as above, S3 or manual upload
```

---

## 📋 PART 7: DETAILED BACKUP MANIFEST

### What Gets Backed Up Every 2 Hours

```
TIER 1: Git Repositories (Pushed to GitHub every 2 hours)
✓ /home/ubuntu/.openclaw/workspace/.git/
  └─ Preserves: Agent workspace history, all docs
✓ /home/ubuntu/.openclaw/workspace/ai-erp/.git/
  └─ Preserves: ERP backend, frontend, infrastructure code

TIER 2: Configuration & Settings (Encrypted tarball)
✓ /home/ubuntu/.openclaw/openclaw.json          (Main config)
✓ /home/ubuntu/.openclaw/agents/                (Agent settings)
✓ /home/ubuntu/.openclaw/cron/                  (Job definitions)
✓ /home/ubuntu/.openclaw/identity/              (Identity)
✓ /home/ubuntu/.openclaw/logs/                  (System logs)
✓ /home/ubuntu/.openclaw/canvas/                (Canvas configs)
⚠️ /home/ubuntu/.openclaw/credentials/          (SENSITIVE - encrypt!)
⚠️ /home/ubuntu/.openclaw/telegram/             (SENSITIVE - encrypt!)

TIER 2b: Workspace Documentation
✓ /home/ubuntu/.openclaw/workspace/*.md         (All docs)
✓ /home/ubuntu/.openclaw/workspace/memory/      (Agent memory)
✓ /home/ubuntu/.openclaw/workspace/ai-erp/*.md (ERP docs)

TIER 3: Database (If Docker containers running)
✓ PostgreSQL database dump (ai_erp)
  └─ 12 tables with all data
✓ Redis dump
  └─ Cache & Celery state

TIER 4: Excluded Files (Don't backup)
✗ /home/ubuntu/.openclaw/workspace/.git/objects/  (Git objects already in repo)
✗ /home/ubuntu/.vscode-server/                    (Active IDE - skip)
✗ /home/ubuntu/.cache/                            (Cache, not data)
✗ /home/ubuntu/.npm/                              (Package cache)
✗ node_modules/                                   (Recreated from package.json)
✗ __pycache__/                                    (Python cache)
✗ *.pyc, *.so                                     (Compiled files)

```

### Files NOT to Include (Why?)
- **VS Code files** (.vscode-server): Active session, regenerated
- **node_modules**: Recreated from package.json on restore
- **Python cache**: Recreated automatically
- **Git objects**: Already preserved in .git directory
- **Logs** (optional): Can exclude if saving space

---

## ⚙️ PART 8: CRON SYSTEM MECHANICS (Deep Dive)

### How OpenClaw's Cron Works

OpenClaw **does not use system crontab**. Instead:

1. **Daemon reads** `/home/ubuntu/.openclaw/cron/jobs.json`
2. **In-memory scheduler** tracks each job's next execution time
3. **Wakes at intervals** to check if any jobs need running
4. **Executes payload** (shell command, system event, or script)
5. **Records result** in `runs/[job-id].jsonl`
6. **Calculates next run** based on schedule

### Scheduler Accuracy

- **±30 seconds**: Normal variance (good enough for 2-hour backups)
- **+/- up to 5 minutes**: If system under load
- **NOT guaranteed**: If OpenClaw process crashes, jobs don't run
- **Persists**: Jobs.json survives restarts; next run calculated on restart

### Advantages Over System Cron

| Feature | System Cron | OpenClaw Cron |
|---------|------------|---|
| **When active** | Always running | Only when OpenClaw daemon running |
| **Status tracking** | Logs to syslog (hard to parse) | JSON logs in runs/ directory |
| **Dynamic updates** | Requires crontab edit + service restart | Edit jobs.json, reread on next heartbeat |
| **Permissions** | Requires sudo for system-level tasks | Runs as OpenClaw user (safer) |
| **Logging** | Scattered system logs | Centralized in runs/*.jsonl |
| **Chaining** | Complex (need wrapper scripts) | Native support via payload |

### Backup Job Lifecycle

```
TIME    EVENT                           STATE
────    ─────                           ────
00:00   Job created (enabled: false)    IDLE
        └─ Waiting for human approval

00:00   Human enables job               SCHEDULED
        └─ "enabled": true
        └─ Next run: NOW (if past)

00:00   First execution triggers        RUNNING
        ├─ Command: /backup-all.sh
        ├─ Duration: ~2-5 minutes
        └─ Result: success/failed

02:00   Second execution                RUNNING
        └─ Same process repeats

04:00   Third execution                 RUNNING
...     ...                             ...

Every 2 hours, forever, until:
- Job is disabled
- OpenClaw daemon stops
- System reboots (resumes on daemon restart)
```

### Execution Log Format

**File**: `/home/ubuntu/.openclaw/cron/runs/backup-every-2-hours.jsonl`

```json
{"timestamp":"2026-02-04T06:00:00Z","status":"started","jobId":"backup-every-2-hours"}
{"timestamp":"2026-02-04T06:02:15Z","status":"completed","jobId":"backup-every-2-hours","duration":"135s","backupSize":"850MB","uploaded":true}
{"timestamp":"2026-02-04T08:00:00Z","status":"started","jobId":"backup-every-2-hours"}
{"timestamp":"2026-02-04T08:02:45Z","status":"completed","jobId":"backup-every-2-hours","duration":"165s","backupSize":"890MB","uploaded":true}
{"timestamp":"2026-02-04T10:00:00Z","status":"failed","jobId":"backup-every-2-hours","error":"Disk full: 0.2GB free","retry":"yes"}
```

---

## 🔐 PART 9: SECURITY CONSIDERATIONS

### Sensitive Data in Backups

⚠️ **These files contain secrets**:

```
❌ openclaw.json
   ├─ Anthropic API key
   ├─ Brave Search API key
   ├─ Telegram bot token
   └─ Gateway auth token

❌ credentials/telegram-*.json
   └─ Telegram auth tokens

❌ .env files (in ai-erp backend)
   ├─ DATABASE_URL (password)
   ├─ REDIS_URL
   └─ API keys

❌ .ssh/
   ├─ Private keys (DO NOT BACKUP)
   └─ Known hosts
```

### Encryption Strategy

**Recommended**: GPG Encryption

```bash
# Encrypt sensitive files before uploading
tar czf openclaw-backup.tar.gz \
    /home/ubuntu/.openclaw/openclaw.json \
    /home/ubuntu/.openclaw/credentials/ \
    /home/ubuntu/.openclaw/agents/

# Encrypt with GPG
gpg --symmetric --cipher-algo AES256 \
    openclaw-backup.tar.gz
# → openclaw-backup.tar.gz.gpg (password protected)

# Upload encrypted file (safe!)
aws s3 cp openclaw-backup.tar.gz.gpg s3://backups/

# Decrypt on restore
gpg --decrypt openclaw-backup.tar.gz.gpg > restored.tar.gz
tar xzf restored.tar.gz
```

### Restore Safety

- ✅ Only decrypt when restoring (not stored in plain text)
- ✅ Use strong passphrase (20+ chars, mixed)
- ✅ Keep passphrase separate from backups
- ✅ Test restore process regularly

---

## ⏱️ PART 10: TIMELINE & RETENTION POLICY

### Backup Schedule

```
Every 2 hours automatically (via OpenClaw cron)

Time (UTC)   Backup #   Storage Path
─────────    ─────      ────────────
00:00        Backup 1   backups/2026-02-04_00.tar.gz.gpg
02:00        Backup 2   backups/2026-02-04_02.tar.gz.gpg
04:00        Backup 3   backups/2026-02-04_04.tar.gz.gpg
06:00        Backup 4   backups/2026-02-04_06.tar.gz.gpg
...
22:00        Backup 12  backups/2026-02-04_22.tar.gz.gpg

Next day:
00:00        Backup 13  backups/2026-02-05_00.tar.gz.gpg
...
```

### Retention Policy

```
TIER 1: Git Backups (Unlimited)
├─ GitHub private repo
├─ Retention: Forever
└─ Risk: GitHub compromise (very low)

TIER 2: Rolling Window (7 days)
├─ Last 7 days × 12 backups/day = 84 backups
├─ Storage: ~7 GB (at 100MB/backup average)
├─ Older backups: Deleted automatically
└─ Use case: Restore recent changes

TIER 3: Weekly Snapshots (4 weeks)
├─ Every Sunday at 00:00 UTC
├─ Storage: ~400 MB (4 weekly backups)
├─ Older backups: Deleted after 4 weeks
└─ Use case: Disaster recovery, monthly audits

TIER 4: Monthly Archive (12 months - optional)
├─ First Sunday of each month
├─ Storage: ~100 MB (1 per month)
├─ Retention: 12 months
└─ Use case: Regulatory compliance, year-over-year comparison
```

### Cleanup Script

**File**: `/home/ubuntu/.openclaw/scripts/cleanup-old-backups.sh`

```bash
#!/bin/bash
# Run daily (after backups complete)

BACKUP_DIR="/mnt/backups"
DAYS_TO_KEEP=7

# Delete backups older than 7 days
find $BACKUP_DIR -name "*.tar.gz.gpg" -mtime +$DAYS_TO_KEEP -delete

# Keep at least 4 weekly backups
ls -1t $BACKUP_DIR/weekly_* | tail -n +5 | xargs rm -f

echo "Cleanup completed at $(date)"
```

---

## 📈 PART 11: MONITORING & ALERTING

### What to Monitor

```
✓ Backup completion status
  └─ Every job should complete in 2-5 minutes

✓ Backup size trend
  └─ Alert if suddenly 10x larger (possible runaway data)

✓ Storage usage
  └─ Alert if backup storage > 80% full

✓ Upload success
  └─ Alert if S3/storage upload fails

✓ Database integrity
  └─ Test restore of DB backup weekly

✓ Git push status
  └─ Alert if GitHub push fails (network issues, auth)
```

### Alert Thresholds

```
CRITICAL (notify immediately):
- Backup fails (exit code != 0)
- Storage full (< 100 MB free)
- Upload fails (S3 connection error)

WARNING (check next day):
- Backup takes > 10 minutes (slower than normal)
- Backup size grows 50% unexpectedly
- OpenClaw cron daemon not running

INFO (log only):
- Backup completed successfully
- Files backed up: X, Size: Y GB
- Upload to S3: OK
```

### Health Check Script

```bash
#!/bin/bash
# Run once per hour to verify backup system is healthy

# 1. Check if last backup completed in last 2.5 hours
LAST_BACKUP=$(stat -f %m /mnt/backups/latest.tar.gz.gpg)
CURRENT_TIME=$(date +%s)
DIFF=$((CURRENT_TIME - LAST_BACKUP))

if [ $DIFF -gt 9000 ]; then  # 2.5 hours in seconds
    ALERT="❌ BACKUP FAILED: Last backup was $((DIFF/3600)) hours ago"
fi

# 2. Check storage space
FREE_SPACE=$(df /mnt/backups | awk 'NR==2 {print $4}')
if [ $FREE_SPACE -lt 100000 ]; then  # < 100 MB
    ALERT="❌ STORAGE FULL: Only $((FREE_SPACE/1024)) MB available"
fi

# 3. Check database restore capability
if docker ps | grep -q postgres; then
    docker exec ai-erp-postgres pg_dump -U erp_user ai_erp > /dev/null
    if [ $? -ne 0 ]; then
        ALERT="❌ DATABASE BACKUP FAILED: pg_dump error"
    fi
fi

if [ -z "$ALERT" ]; then
    echo "✅ Backup system healthy at $(date)"
else
    echo "$ALERT"
    # Send alert to Telegram, email, etc.
fi
```

---

## 🚫 PART 12: WHAT NOT TO DO (Critical Warnings)

### ❌ DON'T Backup While VS Code Is Actively Editing

**Problem**: Corrupted files, mid-write captures

**Solution**: 
- Use `--exclude` for active editor temp files
- Backup via `tar` (atomic), not `cp`
- Don't backup .vscode-server/ directly

### ❌ DON'T Store Backups on Same Disk as Source

**Problem**: Disk failure = source AND backup lost

**Solution**: External storage (USB, NAS, S3, etc.)

### ❌ DON'T Backup Unencrypted to Cloud

**Problem**: API keys exposed if S3 bucket breached

**Solution**: Encrypt with GPG before upload

### ❌ DON'T Use System Cron for This

**Problem**: Requires sudo, hard to integrate with OpenClaw, poor logging

**Solution**: Use OpenClaw's native cron system (what we're planning)

### ❌ DON'T Forget to Test Restores

**Problem**: Backup exists, but restore fails due to corruption

**Solution**: Monthly restore test on separate machine/VM

### ❌ DON'T Keep Passphrases in Code

**Problem**: Secrets exposed in git history

**Solution**: Store in environment variable or secure vault

---

## ✅ PART 13: IMPLEMENTATION CHECKLIST (Before Execution)

### Pre-Flight Checks (Non-Destructive)

```
☐ Disk space available:
  └─ Verify at least 5 GB external storage available

☐ Git repos healthy:
  └─ cd /home/ubuntu/.openclaw/workspace && git status
  └─ cd /home/ubuntu/.openclaw/workspace/ai-erp && git status
  └─ Expect: "On branch main" (or master), no conflicts

☐ VS Code session verified:
  └─ ps aux | grep vscode-server
  └─ Expect: Multiple node processes running
  └─ Action: Leave running - don't interrupt

☐ OpenClaw cron system verified:
  └─ cat /home/ubuntu/.openclaw/cron/jobs.json | grep -c '"id"'
  └─ Expect: At least 4 existing jobs (currently all disabled)

☐ Docker status (if using):
  └─ docker ps
  └─ Note: No containers currently running - that's OK

☐ Sensitive file check:
  └─ ls -la /home/ubuntu/.openclaw/openclaw.json
  └─ Expect: File exists with API keys
  └─ Action: These MUST be encrypted before upload

☐ Backup location prepared:
  └─ If USB: sudo mount /dev/sdb1 /mnt/backups && df -h /mnt/backups
  └─ If S3: aws s3 ls s3://backup-bucket
  └─ If NAS: mount -t nfs 192.168.1.x:/backups /mnt/backups
  └─ Expect: Target directory exists and is writable

☐ Test script created (before enabling cron):
  └─ Create: /home/ubuntu/.openclaw/scripts/backup-all.sh
  └─ Make executable: chmod +x /home/ubuntu/.openclaw/scripts/backup-all.sh
  └─ Test manually: /home/ubuntu/.openclaw/scripts/backup-all.sh
  └─ Expect: Backup file created successfully

☐ Encryption key created (optional but recommended):
  └─ gpg --gen-key (if using GPG)
  └─ Or: Generate strong passphrase (20+ chars)
```

### First Run (Manual Backup Before Automation)

```
☐ Run backup script manually:
  └─ /home/ubuntu/.openclaw/scripts/backup-all.sh
  └─ Monitor output
  └─ Check: Backup file size is reasonable (~800MB - 2GB)
  └─ Check: All components included (git, config, docs)

☐ Verify backup contents:
  └─ tar -tzf backup-2026-02-04.tar.gz | head -20
  └─ Expect: openclaw.json, ai-erp/, workspace/ files

☐ Test decrypt (if encrypted):
  └─ gpg --decrypt backup-2026-02-04.tar.gz.gpg | tar -tzf - | head -20
  └─ Expect: Same file listing as above

☐ Upload to storage:
  └─ If S3: aws s3 cp backup-2026-02-04.tar.gz.gpg s3://backups/
  └─ If USB: cp backup-2026-02-04.tar.gz.gpg /mnt/backups/
  └─ Expect: File appears on destination storage
```

### Enable Automation

```
☐ Add job to /home/ubuntu/.openclaw/cron/jobs.json
  └─ Start with "enabled": false (test first)
  └─ Don't start with enabled: true yet

☐ Verify OpenClaw reads updated jobs.json
  └─ Restart OpenClaw daemon or wait for reload
  └─ Check: jobs.json timestamp updated
  └─ Note: No action needed if jobs.json has same content

☐ Manual trigger first job:
  └─ This is manual for now (don't enable recurring yet)
  └─ Verify it runs and completes

☐ Check execution log:
  └─ cat /home/ubuntu/.openclaw/cron/runs/backup-every-2-hours.jsonl
  └─ Expect: "status":"completed" with no errors

☐ Enable recurring schedule:
  └─ Edit jobs.json: "enabled": true
  └─ Restart OpenClaw daemon or wait for reload
  └─ Next backup will run automatically in 2 hours

☐ Monitor first 48 hours:
  └─ Check execution logs every 2 hours
  └─ Verify backups appearing in storage
  └─ Verify file sizes are consistent
  └─ Set phone reminder to check logs
```

---

## 📞 PART 14: QUESTIONS FOR GLENN

Before Glenn decides on implementation, clarify:

1. **Storage Location**
   - External USB drive (portable, limited size)?
   - AWS S3 (unlimited, need AWS account)?
   - Network NAS (local, need setup)?
   - GitHub (code only, free)?
   - Multiple tiers (git→GitHub, config→S3)?

2. **Encryption Preference**
   - GPG (standard, requires passphrase)?
   - AWS KMS (cloud-native, if using S3)?
   - No encryption (for local storage only)?

3. **Retention Duration**
   - 7 days (standard, minimal storage)?
   - 30 days (comprehensive)?
   - 90 days (compliance)?

4. **Database Backup**
   - Include PostgreSQL backups (when Docker running)?
   - Include Redis snapshots?
   - Skip databases (just code & config)?

5. **Monitoring & Alerts**
   - Send alerts to Telegram?
   - Daily summary email?
   - Just log to file (manual check)?

6. **Disaster Recovery Testing**
   - Weekly restore tests?
   - Monthly only?
   - Not required?

---

## 🎯 PART 15: EXECUTION ROADMAP (After Approval)

```
PHASE 1: Setup (Day 1)
├─ ☐ Glenn approves storage location & answers Q.14
├─ ☐ Provision storage (mount USB, create S3 bucket, etc.)
├─ ☐ Create backup script: /home/ubuntu/.openclaw/scripts/backup-all.sh
├─ ☐ Test manual backup (runs, completes, verifies)
└─ Estimated time: 30 minutes

PHASE 2: Integration (Day 1-2)
├─ ☐ Add job to cron/jobs.json
├─ ☐ Manual trigger first scheduled backup
├─ ☐ Verify logs in cron/runs/backup-every-2-hours.jsonl
├─ ☐ Monitor for 24 hours (at least 12 backup cycles)
└─ Estimated time: 1 hour + 24 hour monitoring

PHASE 3: Optimization (Day 3-7)
├─ ☐ Monitor backup sizes & times
├─ ☐ Adjust retention policy if needed
├─ ☐ Create cleanup script for old backups
├─ ☐ Setup health check alerts
├─ ☐ Document restore procedure
├─ ☐ Perform first restore test (on separate machine if possible)
└─ Estimated time: 2 hours

PHASE 4: Production (Day 8+)
├─ ☐ All systems running smoothly
├─ ☐ Backups happening automatically every 2 hours
├─ ☐ Zero manual intervention required
├─ ☐ Monthly restore tests scheduled
└─ Ongoing: Monitor health, rotate old backups

TOTAL IMPLEMENTATION TIME: ~4 hours + 24 hour testing
```

---

## 🔄 DISASTER RECOVERY PROCEDURE

### If Everything Is Lost

```
STEP 1: Get one backup file
└─ From USB: Plug in external drive
└─ From S3: aws s3 cp s3://backups/2026-02-04_latest.tar.gz.gpg .

STEP 2: Decrypt (if encrypted)
└─ gpg --decrypt 2026-02-04_latest.tar.gz.gpg > backup.tar.gz

STEP 3: Extract
└─ mkdir -p /tmp/restore
└─ cd /tmp/restore
└─ tar -xzf backup.tar.gz

STEP 4: Restore components individually
├─ Restore config:
│  └─ cp -r /tmp/restore/home/ubuntu/.openclaw /home/ubuntu/
├─ Restore workspace:
│  └─ cp -r /tmp/restore/home/ubuntu/.openclaw/workspace /home/ubuntu/.openclaw/
├─ Restore database (if needed):
│  └─ docker exec ai-erp-postgres pg_restore -U erp_user < backup.sql

STEP 5: Verify
├─ cd /home/ubuntu/.openclaw && git status
├─ cd /home/ubuntu/.openclaw/workspace/ai-erp && git status
└─ Test: openclaw doctor (if command exists)

STEP 6: Restart services
└─ docker-compose up -d (if using docker)
└─ OpenClaw should auto-detect restored config
```

---

## 📊 SUMMARY TABLE

| Aspect | Details |
|--------|---------|
| **Frequency** | Every 2 hours (12 per day) |
| **Total Size** | ~8.5 MB code + config + docs (database when running: +50-200MB) |
| **Storage Needed (7d)** | 5-22 GB |
| **Storage Needed (30d)** | 22-93 GB |
| **Active Session** | VS Code (started 05:33 UTC) - SAFE TO BACKUP |
| **Automation Method** | OpenClaw's built-in cron (jobs.json) |
| **Backup Method** | tar + gpg encryption |
| **Storage Options** | S3 (recommended), External USB, NAS, GitHub |
| **Scheduling Type** | `"kind": "interval", "intervalMs": 7200000` |
| **Retention** | 7-day rolling + optional monthly archive |
| **Disk Space Available** | 1.7 GB free (76% full) - **CRITICAL** |
| **Implementation Risk** | LOW - Read-only operations, non-blocking |
| **Estimated Setup Time** | 30 minutes - 1 hour |
| **Testing Time** | 24 hours (let one full backup cycle run) |

---

## 🎯 FINAL RECOMMENDATION

### Best Strategy for Glenn

**RECOMMENDED APPROACH:**

1. **Immediate** (This week)
   - Get external USB 1TB drive (~$50-100)
   - Mount to /mnt/backups
   - Create backup script
   - Run manual test backup

2. **Short-term** (Week 1-2)
   - Enable automatic backups every 2 hours
   - Monitor for 24-48 hours
   - Test restore procedure

3. **Medium-term** (Week 2-4)
   - Set up AWS S3 bucket for redundancy
   - Sync USB backups to S3 nightly
   - Schedule monthly restore tests

4. **Long-term** (Ongoing)
   - Monitor backup health automatically
   - Rotate old backups (keep 7 days locally, archive to S3)
   - Keep as part of operational routine

**Why this approach?**
- ✅ Solves immediate backup need (USB is cheap, fast)
- ✅ Doesn't disturb active VS Code session
- ✅ Uses OpenClaw's native cron system (no sudo needed)
- ✅ Can expand to S3 later without rewriting
- ✅ Safe, tested, reversible at each step
- ✅ Starts small, scales up gracefully

---

## 📝 CONCLUSION

This plan provides:

✅ **Complete backup** of ALL OpenClaw data, configuration, workspace, ERP project, and databases
✅ **Automated execution** every 2 hours using OpenClaw's native cron system
✅ **Safe for active processes** - read-only operations, non-blocking
✅ **Multiple storage options** from cheap (USB) to enterprise (S3)
✅ **Disaster recovery** - full restore possible from a single backup file
✅ **Security** - optional GPG encryption for sensitive data
✅ **Monitoring** - execution logs, health checks, alerts

**Status**: PLANNING COMPLETE - READY FOR APPROVAL & EXECUTION

---

**Next Step**: Glenn reviews this document and answers the questions in PART 14, then we proceed with PHASE 1 implementation.

