#!/bin/bash
# GitHub Storage Monitoring Script
# Checks repository sizes and warns if approaching GitHub limits

WORKSPACE_DIR="$HOME/.openclaw/workspace"
AI_ERP_DIR="$WORKSPACE_DIR/ai-erp"
WARNING_THRESHOLD_MB=1800  # Warn at 1.8 GB (90% of 2 GB limit)
CRITICAL_THRESHOLD_MB=1900  # Critical at 1.9 GB (95% of 2 GB limit)

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_repo() {
    local repo_path=$1
    local repo_name=$2
    
    if [ ! -d "$repo_path" ]; then
        echo -e "${YELLOW}⚠️  $repo_name not found${NC}"
        return 1
    fi
    
    local size_mb=$(du -sm "$repo_path" | cut -f1)
    local git_size_kb=$(cd "$repo_path" && git count-objects -v | grep 'size-pack' | awk '{print $2}')
    local git_size_mb=$((git_size_kb / 1024))
    local percent=$((size_mb * 100 / 2000))
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Total size: ${size_mb} MB"
    echo "Git objects: ${git_size_mb} MB"
    echo "Usage: ${percent}% of 2 GB free limit"
    
    if [ $size_mb -ge $CRITICAL_THRESHOLD_MB ]; then
        echo -e "${RED}🚨 CRITICAL: Approaching 2 GB GitHub limit!${NC}"
        echo -e "${RED}Action required: Clean up large files or consider paid plan${NC}"
        return 2
    elif [ $size_mb -ge $WARNING_THRESHOLD_MB ]; then
        echo -e "${YELLOW}⚠️  WARNING: Getting close to 2 GB limit${NC}"
        echo -e "${YELLOW}Consider reviewing large files${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Storage healthy${NC}"
        return 0
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 GitHub Storage Report${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S UTC')"
echo "Free account limit: 2 GB per repository"

status=0

# Check openclaw-workspace
check_repo "$WORKSPACE_DIR" "openclaw-workspace"
workspace_status=$?
[ $workspace_status -gt $status ] && status=$workspace_status

# Check ai-erp
check_repo "$AI_ERP_DIR" "ai-erp"
erp_status=$?
[ $erp_status -gt $status ] && status=$erp_status

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Find largest files
echo -e "\n${BLUE}🔍 Top 10 largest files in workspace:${NC}"
find "$WORKSPACE_DIR" -type f -not -path "*/\.git/*" -exec du -h {} + 2>/dev/null | \
    sort -rh | head -10 | awk '{printf "  %s\t%s\n", $1, $2}'

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $status -eq 2 ]; then
    echo -e "${RED}Status: CRITICAL - Immediate action required${NC}"
elif [ $status -eq 1 ]; then
    echo -e "${YELLOW}Status: WARNING - Monitor storage usage${NC}"
else
    echo -e "${GREEN}Status: OK - All repositories healthy${NC}"
fi

exit $status
