# Orchestration Decision Matrix

**Quick reference for task routing decisions - WITH TEAM NAMES**

---

## Task Classification Matrix (Team Edition)

| Task Type | Complexity | Agent | Time | Cost | Example | If Busy? |
|-----------|------------|-------|------|------|---------|----------|
| Greeting | Trivial | Nikoline | <5s | $0 | "Hi", "What's up?" | N/A |
| Status Check | Trivial | Nikoline | <10s | $0 | "What are you working on?" | N/A |
| Calendar Lookup | Trivial | Nikoline | <10s | $0 | "What's my next meeting?" | N/A |
| Read File | Simple | Harald | <1m | $0.01 | "Read config.json" | Queue or → Sonny |
| Search Web | Simple | Harald | <2m | $0.03 | "Search for Node.js docs" | Queue or → Sonny |
| Extract Data | Simple | Harald | <2m | $0.05 | "Extract all emails from logs" | Queue or → Sonny |
| Summarize | Simple | Harald | <2m | $0.05 | "Summarize this article" | Queue or → Sonny |
| Debug Issue | Complex | Sonny | 5-15m | $1-2 | "Why is API returning 500?" | Queue or offer break down |
| Design Schema | Complex | Sonny | 10-20m | $2-3 | "Design database for blog" | Queue or offer break down |
| Write Script | Complex | Sonny | 5-15m | $1-2 | "Script to process logs" | Queue or offer break down |
| Research Topic | Complex | Sonny | 10-30m | $2-5 | "Compare 3 auth solutions" | Queue or offer break down |
| Analyze Codebase | Complex | Sonny | 15-30m | $3-5 | "Find security vulnerabilities" | Queue or offer break down |
| Build Feature | Project | ClaudeCode | 30-120m | $0* | "Build REST API" | Queue (30+ min wait) |
| Refactor Module | Project | ClaudeCode | 30-180m | $0* | "Refactor auth to use JWT" | Queue (30+ min wait) |
| Migrate System | Project | ClaudeCode | 60-300m | $0* | "Migrate to TypeScript" | Queue (1+ hour wait) |
| Fix All Tests | Project | ClaudeCode | 30-120m | $0* | "Debug all failing tests" | Queue (30+ min wait) |

*\*Included in ClaudeCode Max plan*

**NEW: "If Busy?" column shows options when worker is unavailable**

---

## Decision Tree: Visual

```
┌─────────────────────────────────────────────────────────────────┐
│ Task from Glenn                                                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                   ┌─────────▼─────────┐
                   │ Can answer in <30s│
                   │ without tools?    │
                   └─────────┬─────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
              YES                        NO
                │                         │
         ┌──────▼──────┐         ┌───────▼────────┐
         │ Answer      │         │ Needs tools/   │
         │ directly    │         │ reasoning      │
         └─────────────┘         └───────┬────────┘
                                         │
                             ┌───────────▼──────────┐
                             │ Is it multi-file     │
                             │ coding project?      │
                             └───────────┬──────────┘
                                         │
                             ┌───────────┴──────────┐
                             │                      │
                           YES                     NO
                             │                      │
                    ┌────────▼────────┐   ┌────────▼────────┐
                    │ Claude Code     │   │ Single file or  │
                    │ (Max Plan)      │   │ non-coding task │
                    │ • 3+ files      │   └────────┬────────┘
                    │ • Refactoring   │            │
                    │ • Build systems │   ┌────────▼────────┐
                    └─────────────────┘   │ Needs complex   │
                                          │ reasoning?      │
                                          └────────┬────────┘
                                                   │
                                       ┌───────────┴──────────┐
                                       │                      │
                                     YES                     NO
                                       │                      │
                              ┌────────▼────────┐   ┌────────▼────────┐
                              │ Sonnet          │   │ Haiku           │
                              │ • Debug         │   │ • Read          │
                              │ • Design        │   │ • Search        │
                              │ • Research      │   │ • Extract       │
                              │ • Analysis      │   │ • Summarize     │
                              └─────────────────┘   └─────────────────┘
```

---

## Keyword Detection (Team Routing)

### Trivial (Nikoline handles)
- `hi`, `hello`, `hey`, `what's up`
- `status`, `how's it going`
- `time`, `date`, `weather`
- `calendar`, `next meeting`
- Message length < 20 characters

### Simple (Send to Harald)
- `read [file]`
- `search [for/web]`
- `find [in]`
- `list [files/items]`
- `extract [from]`
- `summarize [article/doc]`
- `check [if/url]`
- `get [data/info]`

**If Harald busy:** Queue or suggest Sonny

### Complex (Send to Sonny)
- `debug [error/issue]`
- `why [is/does]`
- `design [architecture/schema]`
- `analyze [code/logs]`
- `research [topic]`
- `compare [options]`
- `write [code/script]` (single file)
- `create [script]`
- `fix [bug]` (specific issue)

**If Sonny busy:** Queue or offer to break down

### Project (Send to ClaudeCode)
- `refactor [system/module]`
- `migrate [to/from]`
- `build [feature/api/system]`
- `implement [feature]`
- `add [to entire/across]`
- `update [entire/all]`
- `convert [codebase]`
- `fix [all/tests]` (multiple)

**If ClaudeCode busy:** Queue with ETA

---

## Cost Comparison Table

| Scenario | Without Orchestration | With Orchestration | Savings |
|----------|----------------------|-------------------|---------|
| 10 simple searches | 10 × Sonnet = $1.50 | 10 × Haiku = $0.15 | **$1.35 (90%)** |
| 5 debug tasks | 5 × Sonnet = $7.50 | 5 × Sonnet = $7.50 | $0 (same) |
| 3 big projects | 3 × Sonnet = $45 | 3 × Claude Code = $0 | **$45 (100%)** |
| Mixed day (typical) | Sonnet all = $50 | Optimized = $15 | **$35 (70%)** |

### Typical Day Breakdown

**Tasks:**
- 20 chat messages
- 10 simple tasks
- 3 complex tasks
- 1 big project

**Without orchestration:**
- All via Sonnet: ~500K tokens = $50/day

**With orchestration:**
- Chat (Nikoline): $1.50
- Simple (Haiku): $0.50
- Complex (Sonnet): $9.00
- Project (Claude Code): $0
- **Total: $11/day**

**Monthly savings: ~$1,170**

---

## Token Estimates by Task

| Task Type | Avg Input | Avg Output | Total Tokens | Cost (Haiku) | Cost (Sonnet) |
|-----------|-----------|------------|--------------|--------------|---------------|
| Read file | 5K | 2K | 7K | $0.009 | $0.11 |
| Search web | 3K | 5K | 8K | $0.010 | $0.12 |
| Summarize | 10K | 1K | 11K | $0.014 | $0.17 |
| Extract data | 8K | 2K | 10K | $0.013 | $0.15 |
| Debug issue | 20K | 15K | 35K | $0.044 | $0.53 |
| Design schema | 15K | 20K | 35K | $0.044 | $0.53 |
| Write script | 10K | 30K | 40K | $0.050 | $0.60 |
| Research | 30K | 50K | 80K | $0.100 | $1.20 |

---

## Team Member Capabilities Comparison

| Capability | Harald (Haiku) | Sonny (Sonnet) | Opus | ClaudeCode |
|------------|-------|--------|------|-------------|
| **Speed** | ⚡⚡⚡ | ⚡⚡ | ⚡ | ⚡ (depends on size) |
| **Cost** | 💰 ($0.01-0.1) | 💰💰 ($0.75-3) | 💰💰💰 ($7.50+) | Free* |
| **Reasoning** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Coding** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Multi-file** | ❌ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Context** | 200K | 200K | 200K | Unlimited |
| **Best for** | Simple/fast | Complex tasks | Edge cases | Big projects |
| **Status cmd** | `status` | `status` | N/A | `status` |
| **Auto-escalate if busy?** | ✅ Yes → Sonny | ⏳ Queue | Rare | ⏳ Queue |

*\*Included in Max plan subscription*

**Note:** Check agent status before assigning. If busy, offer Glenn options (wait, escalate, queue, cancel).

---

## When to Override Defaults

### Use Sonnet Instead of Haiku When:
- Task involves multiple steps
- Output needs to be well-reasoned
- Data extraction is complex (nested JSON, etc.)
- Summary needs analysis, not just extraction

### Use Opus Instead of Sonnet When:
- Novel problem never seen before
- Critical business decision
- Extremely complex reasoning needed
- Sonnet has failed twice

### Use Claude Code Instead of Sonnet When:
- More than 2 files need changes
- Need to refactor across modules
- Build/config system changes
- Long-running coding task (>30 min)

### Use Sub-Agent Instead of Direct When:
- Task will take >2 minutes
- Glenn might want to chat while waiting
- Task is well-defined and can run independently

---

## Parallel Execution Matrix

| Scenario | Can Parallelize? | Why |
|----------|-----------------|-----|
| Search 3 different topics | ✅ Yes | Independent tasks |
| Search topic + debug issue | ✅ Yes | No dependencies |
| Debug issue + fix based on findings | ❌ No | Fix depends on debug results |
| Read file + summarize it | ❌ No | Summary depends on read |
| Process 10 files (same operation) | ⚠️ Maybe | Better: 1 agent processes all 10 |
| Build feature + write tests for it | ❌ No | Tests depend on feature code |
| Refactor module A + module B | ✅ Yes | If modules are independent |

**Rule of thumb:** If task B needs results from task A, serialize. Otherwise parallelize.

---

## Escalation Criteria

### Haiku → Sonnet
- Haiku returns "too complex"
- Haiku output is incomplete/wrong
- Task requires reasoning Haiku can't provide
- Multiple attempts fail

### Sonnet → Opus
- Sonnet returns "uncertain"
- Sonnet output quality is poor after 2 tries
- Task is critical and needs highest quality
- Glenn explicitly requests it

### Sonnet → Claude Code
- Task scope expands to 3+ files
- Realize it's a project, not a task
- Time estimate exceeds 30 minutes

### Sub-Agent → Direct (Nikoline)
- Sub-agent fails to spawn
- Task is simpler than initially thought
- Faster to do directly

---

## Session Isolation Reference

| Session | Purpose | Can Access | Cannot Access |
|---------|---------|-----------|---------------|
| `agent:main:main` | Nikoline's main chat with Glenn | - All tools<br>- Glenn's messages<br>- Workspace files<br>- Spawn sub-agents/Claude Code | - Sub-agent internals<br>- Claude Code stdin |
| `agent:main:subagent:<uuid>` | Sub-agent task execution | - Assigned tools<br>- Workspace files<br>- Task description | - Glenn's messages<br>- Other sub-agents<br>- Nikoline's chat history |
| `exec:pty:<pid>` | Claude Code session | - PTY terminal<br>- Workspace files<br>- Full codebase | - Glenn's messages<br>- Nikoline's state<br>- Other sessions |

**Key insight:** Glenn's messages ONLY go to `agent:main:main`. Never to sub-agents or Claude Code.

---

## Monitoring Strategy

### Passive Monitoring (Automatic)
- **Frequency:** Every 5-10 minutes (heartbeat)
- **Method:** `process.log()` (read-only)
- **Reports:** Milestones to Glenn
- **Cost:** ~5K tokens per check

### Active Monitoring (On Request)
- **Trigger:** Glenn asks "How's X going?"
- **Method:** Read latest logs, parse status
- **Reports:** Current progress to Glenn
- **Cost:** ~10K tokens per request

### Intervention (Emergency)
- **Trigger:** Glenn says "Stop X" or error detected
- **Method:** `process.write()` or `process.kill()`
- **Reports:** Warn Glenn before action
- **Cost:** Varies

---

## Progress Reporting Guidelines

### Report Immediately:
- Task started
- Task completed
- Task failed/errored
- Critical milestone (e.g., "tests passing")

### Report Periodically (every 10-15 min):
- Long-running task progress
- Claude Code milestones
- Significant sub-steps

### Don't Report:
- Internal state changes
- Routine monitoring checks
- Minor sub-steps
- Reading files, making API calls (too granular)

---

## Error Handling Decision Matrix

| Error Type | Action | Notify Glenn? | Example |
|------------|--------|---------------|---------|
| Sub-agent spawn fails | Retry once, fallback to direct | Yes (after retry) | API timeout |
| Sub-agent crashes | Log, clean up, report | Yes (immediately) | Out of memory |
| Sub-agent returns error | Report result as error | Yes | "File not found" |
| Claude Code crashes | Save logs, report | Yes (urgent) | Segfault |
| State file corrupted | Backup, reset, continue | Yes (urgent) | JSON parse error |
| Process hangs (>30 min) | Kill, report | Yes | Infinite loop |

---

## Testing Checklist

### Classification Tests
- [ ] 10 trivial examples → correctly identified
- [ ] 10 simple examples → Haiku selected
- [ ] 10 complex examples → Sonnet selected
- [ ] 10 project examples → Claude Code selected

### Spawning Tests
- [ ] Haiku sub-agent spawns successfully
- [ ] Sonnet sub-agent spawns successfully
- [ ] Claude Code spawns in PTY background
- [ ] Multiple sub-agents spawn in parallel
- [ ] State updates correctly

### Monitoring Tests
- [ ] Claude Code progress detected
- [ ] Milestones extracted from logs
- [ ] Completion detected
- [ ] Errors detected

### Communication Tests
- [ ] Glenn notified on task start
- [ ] Glenn notified on task complete
- [ ] Glenn notified on errors
- [ ] Notification levels work (urgent/important/info)

### Isolation Tests
- [ ] Glenn's messages go to main session only
- [ ] Sub-agents don't see Glenn's messages
- [ ] Claude Code doesn't receive chat messages
- [ ] Can chat with Glenn while Claude Code runs

---

## Quick Command Reference

### Check Active Tasks
```javascript
const state = require('./lib/orchestration-state');
const active = state.getActiveSubAgents();
const claudeCodeActive = state.state.claudeCode.active;
```

### Spawn Sub-Agent
```javascript
const { delegateTask } = require('./lib/delegator');
await delegateTask("Task description", "haiku"); // or "sonnet"
```

### Spawn Claude Code
```javascript
const { spawnClaudeCode } = require('./lib/delegator');
await spawnClaudeCode("Project description");
```

### Monitor Claude Code
```javascript
const monitor = require('./lib/claude-code-monitor');
await monitor.check();
```

### Notify Glenn
```javascript
const { notifyGlenn, LEVELS } = require('./lib/notifier');
await notifyGlenn("Message", LEVELS.INFO);
```

### Kill Task
```javascript
await process({ action: "kill", sessionId: sessionId });
```

---

## Final Checklist Before Production

- [ ] All libraries implemented (state, classifier, delegator, notifier, monitor)
- [ ] Environment variables set (GLENN_CHAT_ID)
- [ ] HEARTBEAT.md updated with monitoring
- [ ] Test suite passes
- [ ] Manual testing: 5 simple tasks
- [ ] Manual testing: 3 complex tasks
- [ ] Manual testing: 1 Claude Code project
- [ ] Manual testing: Chat while Claude Code runs
- [ ] Cost tracking verified
- [ ] Glenn's guide reviewed
- [ ] Nikoline's reference reviewed
- [ ] 1-week trial period planned
- [ ] Feedback mechanism established

---

**Status:** Decision matrix complete - ready for reference during implementation
