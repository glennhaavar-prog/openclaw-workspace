# OpenClaw Configuration Restore Guide

## 🔒 Security Note
This backup contains **SANITIZED** configuration files with placeholder values. You must replace these with your actual secrets to restore a working OpenClaw instance.

## 📋 Quick Restore Checklist

### 1. Install OpenClaw
If starting fresh on a new machine:
```bash
npm install -g openclaw
# or update existing installation
npm update -g openclaw
```

### 2. Restore Configuration Files

#### Copy openclaw.json
```bash
cp config-backup/openclaw.json ~/.openclaw/openclaw.json
```

#### Copy jobs.json
```bash
mkdir -p ~/.openclaw/cron
cp config-backup/jobs.json ~/.openclaw/cron/jobs.json
```

### 3. Replace Secrets in openclaw.json

Open `~/.openclaw/openclaw.json` and replace these placeholders:

#### A. Brave Search API Key
**Location:** `tools.web.search.apiKey`
```json
"apiKey": "YOUR_BRAVE_API_KEY_HERE"
```
**Get yours at:** https://brave.com/search/api/

#### B. Telegram Bot Token
**Location:** `channels.telegram.botToken`
```json
"botToken": "YOUR_TELEGRAM_BOT_TOKEN_HERE"
```
**Get yours from:** @BotFather on Telegram

#### C. Gateway Auth Token
**Location:** `gateway.auth.token`
```json
"token": "YOUR_GATEWAY_AUTH_TOKEN_HERE"
```
**Generate new token:**
```bash
openssl rand -hex 24
```

### 4. Set Up Anthropic API Key

OpenClaw needs your Anthropic API key. Set it as an environment variable:

```bash
# Add to ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY="your-anthropic-api-key-here"

# Or set for current session
export ANTHROPIC_API_KEY="your-anthropic-api-key-here"
```

**Get your key at:** https://console.anthropic.com/

### 5. Verify Configuration

```bash
# Check configuration
openclaw gateway doctor

# Start the gateway
openclaw gateway start

# Check status
openclaw gateway status
```

### 6. Restore Workspace Files

Your workspace is at `~/.openclaw/workspace`. If you cloned from GitHub, it should already contain:
- Agent configuration (SOUL.md, USER.md, AGENTS.md, etc.)
- Memory files
- Tools configuration
- Scripts and automation

If starting fresh:
```bash
cd ~/.openclaw/workspace
git init
git remote add origin https://github.com/YOUR_USERNAME/openclaw-workspace.git
git pull origin main
```

## 🔐 Secrets Reference

Here's where to find each secret:

| Secret | Config Path | How to Get |
|--------|-------------|------------|
| Brave API Key | `tools.web.search.apiKey` | https://brave.com/search/api/ |
| Telegram Bot Token | `channels.telegram.botToken` | @BotFather on Telegram |
| Gateway Auth Token | `gateway.auth.token` | `openssl rand -hex 24` |
| Anthropic API Key | Environment variable | https://console.anthropic.com/ |

## 🚨 Troubleshooting

### Gateway won't start
```bash
# Check logs
tail -f ~/.openclaw/logs/gateway.log

# Reset gateway
openclaw gateway stop
openclaw gateway start
```

### Telegram not connecting
1. Verify bot token is correct
2. Check that bot is not already running elsewhere
3. Ensure `dmPolicy` and `groupPolicy` match your needs

### Web search not working
1. Verify Brave API key is valid
2. Check API usage limits at Brave dashboard

## 📝 Notes

- **Workspace path:** Update if your workspace is not at `/home/ubuntu/.openclaw/workspace`
- **Port conflicts:** Default gateway port is 18789. Change if needed.
- **Cron jobs:** Review `jobs.json` and enable/disable as needed
- **Backups:** This restore guide assumes you're restoring from the GitHub backup

## 🔄 Automated Backups

The workspace includes automated backup scripts:
- **Script:** `scripts/backup-to-github.sh`
- **Cron job:** Runs every 12 hours
- **What it backs up:** Workspace changes, sanitized configs

To manually run a backup:
```bash
cd ~/.openclaw/workspace
./scripts/backup-to-github.sh
```

## 📚 Additional Resources

- OpenClaw Documentation: https://docs.openclaw.com
- Telegram Bot Setup: https://core.telegram.org/bots
- Brave Search API Docs: https://brave.com/search/api/docs
- Anthropic API Docs: https://docs.anthropic.com

---

**Last Updated:** 2026-02-04  
**Config Version:** openclaw.json v2026.1.30
