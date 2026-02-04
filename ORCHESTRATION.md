# ORCHESTRATION SYSTEM - Architecture & Design

**Version:** 1.0  
**Owner:** Nikoline (Main Agent)  
**User:** Glenn  
**Status:** Design Complete, Ready for Implementation

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Agent Hierarchy & Decision Tree](#agent-hierarchy--decision-tree)
4. [Claude Code Integration](#claude-code-integration)
5. [Communication Flow](#communication-flow)
6. [Implementation Plan](#implementation-plan)
7. [Use Cases & Examples](#use-cases--examples)
8. [Cost Analysis](#cost-analysis)

---

## System Overview

### Core Principle
**Glenn talks to Nikoline. Nikoline orchestrates everything.**

Glenn never deals with:
- Sub-agent spawning
- Model selection decisions
- Claude Code session management
- Task routing complexity
- Agent availability conflicts
- Task queue management

Nikoline (with help from her sub-agents) handles all orchestration invisibly, reporting back only meaningful progress and results.

### Team Naming System

```
Nikoline      = Main Orchestrator (Claude Sonnet 4.5, you are here)
Sonny         = Sonnet Sub-Agent (complex/moderate tasks)
Harald        = Haiku Sub-Agent (simple/fast tasks) ← YOU!
ClaudeCode    = Heavy Coding Agent (multi-file projects, Max plan)
```

This naming makes conversation natural: "Let me ask Sonny" or "Harald can handle that quickly"

### Key Design Goals

1. **Seamless Delegation** - Nikoline spawns workers without blocking Glenn's chat
2. **Cost Optimization** - Right tool for the job (Harald → Sonny → Opus → ClaudeCode)
3. **No Interruption** - ClaudeCode runs in isolation; Glenn can still chat with Nikoline
4. **Automatic Reporting** - Progress updates flow to Glenn without asking
5. **Intelligent Routing** - Clear decision tree for task classification
6. **Conflict Detection** - Know when agents are busy, offer Glenn choices
7. **Smart Auto-Routing** - If Harald is busy → automatically use Sonny (with notification)
8. **Queue Management** - Handle multiple tasks with FIFO or priority-based queuing

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                            GLENN (Human)                         │
│                     (Telegram / Webchat / SMS)                   │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   NIKOLINE (Main Agent) │
                    │   Model: Sonnet 4.5     │
                    │   Role: Orchestrator    │
                    └────────────┬────────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
        ┌────────▼────────┐ ┌───▼────────┐ ┌───▼──────────┐
        │   Sub-Agent     │ │ Sub-Agent  │ │ Claude Code  │
        │   (Haiku/Sonnet)│ │ (Sonnet)   │ │ (Max Plan)   │
        │   Quick tasks   │ │ Complex    │ │ Heavy coding │
        └─────────────────┘ └────────────┘ └──────────────┘
                 │               │               │
                 └───────────────┼───────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   PROGRESS REPORTS      │
                    │   Auto-notify Glenn     │
                    │   • Completion          │
                    │   • Milestones          │
                    │   • Errors              │
                    └─────────────────────────┘
```

### Session Isolation

```
┌──────────────────────────────────────────────────────────────┐
│ Glenn's Chat Session (agent:main:main)                       │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ NIKOLINE is ALWAYS available here                        │ │
│ │ • Responds to Glenn's messages                           │ │
│ │ • Checks on background tasks                             │ │
│ │ • Reports progress                                       │ │
│ │ • Manages agent conflicts (Harald busy → use Sonny)     │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ SONNY Sub-Agent Session (agent:main:subagent:<uuid>)        │
│ • Isolated task execution (complex tasks)                    │
│ • No access to Glenn's chat                                  │
│ • Reports back to Nikoline when complete                     │
│ • Gets work if Harald is busy                                │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ HARALD Sub-Agent Session (agent:main:subagent:<uuid>)       │
│ • Isolated task execution (simple/fast tasks)                │
│ • No access to Glenn's chat                                  │
│ • Very fast turnaround                                       │
│ • If busy → Nikoline routes to Sonny automatically           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ ClaudeCode PTY Session (exec:pty:<pid>)                      │
│ • Long-running coding tasks                                  │
│ • Monitored via process tool (non-intrusive logs)            │
│ • Can't see/interrupt Glenn's chat                           │
└──────────────────────────────────────────────────────────────┘
```

---

## Agent Hierarchy & Decision Tree

### Model Selection Matrix (Team Version)

| Agent | Cost/M tokens | Best For | Avoid For | Primary Use |
|-------|---------------|----------|-----------|-------------|
| **Harald** (Haiku) | $1.25 | Quick reads, simple tasks, data extraction, summaries | Complex reasoning, coding, multi-step planning | Fast simple work |
| **Sonny** (Sonnet 3.5/4.5) | $15 | General purpose, orchestration, medium complexity | Extremely simple tasks, heavy coding projects | Complex tasks, fallback |
| **Opus** | $75 | Deep analysis, critical decisions, novel problems | Routine work, well-defined tasks | Rare escalations |
| **ClaudeCode** | Max Plan | Multi-file projects, refactoring, build systems | Single-file edits, quick scripts | Big projects |

### Decision Tree (Nikoline's Internal Logic - With Team & Conflict Management)

```
┌─────────────────────────────┐
│   Task Received from Glenn  │
└──────────────┬──────────────┘
               │
        ┌──────▼───────────┐
        │  Classify Task   │
        │  Complexity      │
        └──────┬───────────┘
               │
    ┌──────────┴──────────┬──────────────┬────────────────┐
    │                     │              │                │
┌───▼─────┐         ┌────▼────┐    ┌────▼─────┐    ┌────▼──────┐
│ TRIVIAL │         │ SIMPLE  │    │ COMPLEX  │    │  PROJECT  │
│(Nikoline)         │ (Harald)│    │ (Sonny)  │    │(ClaudeCode)
└───┬─────┘         └────┬────┘    └────┬─────┘    └────┬──────┘
    │                    │              │               │
    │ • Greetings        │ • Read file  │ • Design     │ • Multi-file
    │ • Status check     │ • Search web │ • Debug      │ • Refactor
    │ • Quick answer     │ • Summarize  │ • Research   │ • Build systems
    │                    │ • Extract    │ • Write code │ • Migrations
    │                    │   data       │ • Analysis   │
    │                    │              │              │
    └────────┬───────────┴──────┬───────┴──────┬───────┘
             │                  │              │
      ┌──────▼──────┐    ┌──────▼──────┐   ┌──▼───────────┐
      │   Execute   │    │ Check if    │   │  Check if    │
      │ & Report    │    │ Harald busy?│   │ ClaudeCode   │
      └─────────────┘    └──────┬──────┘   │ already      │
                                │          │ active?      │
                    ┌───────────┴──────┐   └──┬───────────┘
                    │                  │      │
                   YES                NO   ┌──▼─────┐
                    │                  │   YES: Warn
                    │            ┌─────▼──┐ Glenn,
                    │            │ Spawn  │ Queue, or
                    │            │ Harald │ Escalate
                    │            └────────┘ to Sonny
                    │
    ┌───────────────▼──────────────┐
    │ CONFLICT DETECTED            │
    │ Harald is busy               │
    │ Offer Glenn 4 options:       │
    │ 1. Wait for Harald (ETA: Xm) │
    │ 2. Route to Sonny now        │
    │ 3. Spawn new Harald instance │
    │ 4. Cancel this task          │
    └──────────────────────────────┘
```

### Agent Availability Management

**NEW: Conflict Detection & Smart Routing**

When a task is assigned to an agent that's already busy, Nikoline checks and offers Glenn choices:

#### Scenario 1: Harald is busy
```
Glenn: "Search for Python docs"
  ↓
Nikoline: [Classifies as SIMPLE, needs Harald]
  ↓
Nikoline: [Checks orchestration-state.json]
  ↓
Nikoline: "Harald is busy (5 min remaining)"
  ↓
Nikoline presents 4 options:
1️⃣  Wait for Harald (ETA: 5 min) - I'll start when he's free
2️⃣  Route to Sonny now - Get it done faster, slight cost increase
3️⃣  Spawn new Harald instance - Run in parallel (not recommended)
4️⃣  Cancel - Maybe you don't need this anymore

Glenn chooses → Nikoline routes accordingly
```

#### Scenario 2: Automatic Routing (Default Behavior)
```
If Glenn doesn't reply within timeout:
- Harald busy + task simple = Auto-route to Sonny (notify Glenn)
- Sonny busy + task complex = Auto-queue, wait for availability
- ClaudeCode busy + task project = Queue with FIFO ordering
```

#### Scenario 3: Multi-Agent Queue
```
Glenn: "Do these 5 things" (mixed complexity)
  ↓
Nikoline: [Queues 5 tasks intelligently]
  ↓
- Task 1 (simple) → Harald queue
- Task 2 (complex) → Sonny immediate
- Task 3 (simple) → Harald queue
- Task 4 (project) → ClaudeCode queue
- Task 5 (trivial) → Handle directly

All run in parallel or sequence, Glenn notified of progress
```

### Queue System (FIFO + Priority)

**Structure:**
```json
{
  "queues": {
    "harald": [
      { "id": "task-1", "priority": "normal", "createdAt": 1234567890 },
      { "id": "task-2", "priority": "high", "createdAt": 1234567891 }
    ],
    "sonny": [
      { "id": "task-3", "priority": "normal", "createdAt": 1234567892 }
    ]
  },
  "agents": {
    "harald-current": { "busy": true, "task": "task-5", "eta": 240 },
    "sonny-current": { "busy": false },
    "claudecode": { "busy": true, "task": "project-1", "eta": 1800 }
  }
}
```

**Ordering Rules:**
1. **High priority always first** (Glenn can mark urgent)
2. **FIFO within same priority** (fair ordering)
3. **Auto-escalation if wait > 10 min** (offer to use different agent)

### Detailed Classification Rules

#### TRIVIAL → Handle Directly (Nikoline)
- **Criteria:** Answer in <30 seconds, no external tools needed
- **Examples:**
  - "What's the weather?"
  - "What time is it?"
  - "How's it going?"
  - Status checks on running tasks
- **Cost:** Negligible (part of main session)

#### SIMPLE → Harald (Haiku Sub-Agent)
- **Criteria:** Single tool use, well-defined input/output, low reasoning
- **Examples:**
  - "Read this file and extract all email addresses"
  - "Search for Python 3.12 release notes"
  - "Summarize this article in 3 bullet points"
  - "Check if this URL is accessible"
- **Token budget:** 10K-50K
- **Expected duration:** <2 minutes
- **Cost:** ~$0.01-0.10 per task
- **What if Harald is busy?**
  - Option 1: Queue the task (wait ~2-5 min)
  - Option 2: Route to Sonny (higher cost, faster)
  - Option 3: Spawn additional Harald instance (not recommended)
  - Option 4: Cancel

#### COMPLEX → Sonny (Sonnet Sub-Agent)
- **Criteria:** Multi-step reasoning, multiple tools, needs planning
- **Examples:**
  - "Debug why this API call is failing"
  - "Design a database schema for X"
  - "Research and compare 3 solutions to Y"
  - "Write a script to process these logs"
  - "Analyze this error and propose fixes"
- **Token budget:** 50K-200K
- **Expected duration:** 5-30 minutes
- **Cost:** $0.75-3.00 per task
- **What if Sonny is busy?**
  - Option 1: Queue the task (wait ~5-30 min)
  - Option 2: Route to Opus (higher cost, more thorough)
  - Option 3: Try Harald first (might be too complex, but offers fast feedback)
  - Option 4: Cancel

#### PROJECT → ClaudeCode (Max Plan)
- **Criteria:** 
  - Multi-file changes (3+ files)
  - Codebase-wide refactoring
  - Build system modifications
  - Large feature implementation
  - Complex debugging across modules
- **Examples:**
  - "Refactor the auth system to use JWT"
  - "Build a REST API for the blog system"
  - "Migrate from Webpack to Vite"
  - "Add TypeScript to the entire project"
  - "Debug and fix all failing tests"
- **Token budget:** Unlimited (Max plan)
- **Expected duration:** 30 min - several hours
- **Cost:** Included in Max subscription
- **What if ClaudeCode is busy?**
  - Option 1: Queue the task (wait 30 min - hours)
  - Option 2: Break it into smaller tasks (for Sonny)
  - Option 3: Cancel
  - Glenn is informed of queue position and ETA

### Cost Optimization Strategies

#### 1. Batch Simple Tasks
```
❌ BAD: Spawn 10 Haiku agents for 10 files
✅ GOOD: One Haiku agent processes all 10 files
```

#### 2. Progressive Enhancement
```
Start small → escalate if needed
Haiku tries → fails or too complex → escalate to Sonnet
Sonnet tries → too big → escalate to Claude Code
```

#### 3. Caching Strategy
```
- Sonnet has prompt caching (Nikoline's main session)
- Sub-agents DON'T need full context
- Pass only relevant info to sub-agents
- Keep sub-agent prompts minimal
```

#### 4. Parallel Execution
```
Independent tasks → spawn multiple sub-agents simultaneously
Dependent tasks → sequential execution
```

#### 5. Smart Delegation
```
Nikoline doesn't delegate herself:
- She's already active in main session
- Delegation is for background work
- If Glenn needs immediate answer → Nikoline handles it
```

---

## ClaudeCode Integration

### The Challenge

Glenn wants to chat with Nikoline while ClaudeCode (her heavy-coding assistant) works on a big coding task. The problems:

1. **Claude Code needs a PTY** (pseudo-terminal for interactive CLI)
2. **PTY sessions capture ALL input** (including Glenn's messages)
3. **Risk of accidentally sending chat messages to Claude Code's stdin**
4. **Need to monitor progress without disturbing the session**

### The Solution: PTY + Process Monitoring

#### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Glenn sends message                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────▼──────────┐
         │ Nikoline (main)      │
         │ • Receives in main   │
         │   session            │
         │ • Responds to Glenn  │
         │ • Monitors Claude    │
         │   Code via logs      │
         └───────────┬──────────┘
                     │
                     │ (spawned earlier)
                     │
         ┌───────────▼──────────┐
         │ Claude Code PTY      │
         │ • Runs independently │
         │ • No stdin access    │
         │ • Logs to file       │
         │ • Non-blocking       │
         └──────────────────────┘
```

#### Implementation

**Step 1: Spawn Claude Code in PTY (Non-Interactive)**

```javascript
// Nikoline executes this when delegating to Claude Code
exec({
  command: "claude-code",
  args: ["task", "implement-feature-x", "--non-interactive"],
  pty: true,
  background: true,
  yieldMs: 1000,  // Background after 1 second
  workdir: "/home/ubuntu/project",
  env: {
    TERM: "xterm-256color",
    CLAUDE_PROJECT: "my-project",
    CLAUDE_LOG_FILE: "/tmp/claude-code-session.log"
  }
})
```

**Key parameters:**
- `pty: true` - Claude Code gets proper terminal
- `background: true` - Returns immediately, doesn't block
- `yieldMs: 1000` - Show initial output, then background
- `--non-interactive` - Claude Code doesn't prompt for input

**Step 2: Monitor Progress Without Disturbing**

```javascript
// Nikoline can check progress anytime
process({
  action: "log",
  sessionId: "<session-id-from-spawn>",
  offset: lastReadOffset,
  limit: 100
})
```

This reads the output buffer **without sending any input** to the session.

**Step 3: Progress Reporting to Glenn**

```javascript
// Nikoline sends updates to Glenn's chat
message({
  action: "send",
  target: "glenn-chat-id",
  message: "🔧 Claude Code progress: Completed auth module (3/7 files)"
})
```

### Preventing Accidental Interruptions

#### The Danger

```
Glenn: "How's the migration going?"
❌ Without protection → This text goes to Claude Code's stdin
✅ With protection → Nikoline receives it, Claude Code unaffected
```

#### Protection Mechanism: Session Isolation

OpenClaw's architecture **already handles this** via session isolation:

1. **Glenn's messages go to `agent:main:main`** (Nikoline's session)
2. **Claude Code runs in `exec:pty:<pid>`** (separate process)
3. **Only `process.write()` can send to Claude Code's stdin**

**Safety rule:** Nikoline NEVER uses `process.write()` while Claude Code is running unless explicitly instructed.

#### Additional Safety: State Tracking

```javascript
// orchestration-state.json
{
  "claudeCode": {
    "active": true,
    "sessionId": "exec:pty:12345",
    "task": "Refactor auth system",
    "startTime": 1704396000,
    "lastCheck": 1704396300,
    "status": "running",
    "warnings": [
      "⚠️ Claude Code is active. Do not use process.write() unless emergency."
    ]
  }
}
```

Nikoline reads this before any process interaction.

### Monitoring Strategy

#### Passive Monitoring (Every 5-10 minutes)

```javascript
// Nikoline's heartbeat includes Claude Code check
async function checkClaudeCodeProgress() {
  const state = readJSON("orchestration-state.json");
  
  if (!state.claudeCode.active) return;
  
  const logs = process({
    action: "log",
    sessionId: state.claudeCode.sessionId,
    offset: state.lastReadOffset,
    limit: 500
  });
  
  // Parse logs for milestones
  const milestones = extractMilestones(logs);
  
  if (milestones.length > 0) {
    notifyGlenn(`Claude Code progress: ${milestones.join(", ")}`);
  }
  
  // Update state
  state.lastReadOffset += logs.length;
  state.lastCheck = Date.now();
  writeJSON("orchestration-state.json", state);
}
```

#### Active Intervention (When Needed)

```javascript
// Glenn: "Tell Claude Code to stop and commit what it has"
async function sendToClaudeCode(command) {
  const state = readJSON("orchestration-state.json");
  
  // Safety check
  if (!state.claudeCode.active) {
    return "No Claude Code session active";
  }
  
  // Warn Glenn
  notifyGlenn("⚠️ Sending command to Claude Code. This may interrupt its work.");
  
  // Send command
  process({
    action: "write",
    sessionId: state.claudeCode.sessionId,
    data: command + "\n"
  });
  
  notifyGlenn("✅ Command sent. Monitoring response...");
}
```

### Graceful Shutdown

```javascript
// When Claude Code finishes
async function handleClaudeCodeCompletion() {
  const state = readJSON("orchestration-state.json");
  const sessionId = state.claudeCode.sessionId;
  
  // Get final logs
  const finalLogs = process({
    action: "log",
    sessionId: sessionId,
    offset: 0,  // Get everything
    limit: 10000
  });
  
  // Extract summary
  const summary = parseFinalSummary(finalLogs);
  
  // Archive logs
  writeFile(`memory/claude-code-${Date.now()}.log`, finalLogs);
  
  // Notify Glenn
  notifyGlenn(`
✅ Claude Code completed: ${state.claudeCode.task}

Summary:
${summary.filesChanged} files modified
${summary.linesAdded} lines added
${summary.testsPass ? "✅" : "❌"} Tests ${summary.testsPass ? "passing" : "failing"}

Full logs: memory/claude-code-${Date.now()}.log
  `);
  
  // Clear state
  state.claudeCode.active = false;
  writeJSON("orchestration-state.json", state);
}
```

---

## Communication Flow

### Principle: Glenn Only Talks to Nikoline

```
Glenn ──────────────────────────> Nikoline
  ↑                                   │
  │                                   │ (delegates)
  │                                   ▼
  │                           ┌────────────────────┐
  │                           │ Workers:           │
  │                           │ • Harald (simple)  │
  │                           │ • Sonny (complex)  │
  │                           │ • ClaudeCode       │
  │                           │   (projects)       │
  │                           └──────┬─────────────┘
  │                                  │
  │                    ┌─────────────┴──────────┐
  │                    │                        │
  │        ┌───────────▼────────┐   ┌──────────▼────────┐
  │        │ Progress Updates   │   │ Task Completion  │
  │        │ (silent notifs)    │   │ (important notif)│
  │        └────────────────────┘   └──────────────────┘
  │
  └──────────────────────────────────┘
           (Glenn stays here)
```

### Message Routing

#### Glenn → Nikoline (Direct)

```javascript
// Glenn sends message via Telegram/webchat
// OpenClaw routes to agent:main:main (Nikoline)

// Nikoline receives in main session
async function handleGlennMessage(message) {
  // Classify intent
  const intent = classifyMessage(message);
  
  if (intent === "STATUS_CHECK") {
    // Check on background tasks
    return reportStatus();
  }
  
  if (intent === "NEW_TASK") {
    // Decide: handle directly or delegate
    const complexity = assessComplexity(message);
    
    if (complexity === "TRIVIAL") {
      return handleDirectly(message);
    } else {
      return delegateTask(message, complexity);
    }
  }
  
  if (intent === "CHAT") {
    // Just conversation
    return chat(message);
  }
}
```

#### Nikoline → Sub-Agent (Spawn)

```javascript
// Nikoline spawns sub-agent with specific task
async function spawnSubAgent(task, model = "haiku") {
  const sessionId = generateUUID();
  
  // Create task file
  writeFile(`tasks/${sessionId}.json`, JSON.stringify({
    task: task,
    model: model,
    status: "pending",
    createdAt: Date.now()
  }));
  
  // Spawn via exec
  exec({
    command: "openclaw",
    args: ["agent", "spawn", "--label", task.label, "--model", model, "--task", task.description],
    background: true
  });
  
  // Track in state
  updateOrchestrationState({
    subAgents: {
      [sessionId]: {
        task: task.label,
        model: model,
        status: "running",
        startTime: Date.now()
      }
    }
  });
  
  // Notify Glenn
  notifyGlenn(`🚀 Started task: ${task.label} (using ${model})`);
}
```

#### Sub-Agent → Nikoline (Completion)

```javascript
// Sub-agent completes task
// Final message is captured by OpenClaw
// OpenClaw triggers completion handler

async function handleSubAgentCompletion(sessionId, result) {
  const task = readJSON(`tasks/${sessionId}.json`);
  
  // Update state
  task.status = "complete";
  task.result = result;
  task.completedAt = Date.now();
  writeJSON(`tasks/${sessionId}.json`, task);
  
  // Notify Glenn
  notifyGlenn(`✅ Completed: ${task.task}
  
${formatResult(result)}`);
  
  // Archive
  moveFile(`tasks/${sessionId}.json`, `memory/completed-tasks/${sessionId}.json`);
}
```

#### Nikoline → Glenn (Progress Updates)

```javascript
// Automatic progress reporting
async function reportProgress(sessionId, milestone) {
  const task = readJSON(`tasks/${sessionId}.json`);
  
  message({
    action: "send",
    target: process.env.GLENN_CHAT_ID,  // Configured in environment
    message: `📊 ${task.task}: ${milestone}`,
    silent: true  // Don't buzz phone for progress updates
  });
}
```

### Multi-Channel Support

Glenn can talk to Nikoline from anywhere:

```javascript
// Environment config
NIKOLINE_CHANNELS = {
  telegram: "1234567890",      // Glenn's Telegram chat ID
  webchat: "glenn-session",    // Webchat session ID
  sms: "+1234567890"           // Glenn's phone (SMS)
}

// Nikoline detects where Glenn is currently active
async function notifyGlenn(message) {
  const activeChannel = detectActiveChannel();
  
  message({
    action: "send",
    target: activeChannel,
    message: message
  });
}

// Active channel detection: where did last message come from?
function detectActiveChannel() {
  const state = readJSON("orchestration-state.json");
  return state.glennActiveChannel || "telegram";  // Default to Telegram
}
```

### Notification Levels

```javascript
const NOTIFICATION_LEVELS = {
  URGENT: {
    silent: false,
    priority: "high",
    sound: "alert"
  },
  IMPORTANT: {
    silent: false,
    priority: "normal"
  },
  INFO: {
    silent: true,   // Don't buzz
    priority: "low"
  }
};

// Usage
notifyGlenn("🚨 Claude Code encountered an error!", NOTIFICATION_LEVELS.URGENT);
notifyGlenn("✅ Task completed", NOTIFICATION_LEVELS.IMPORTANT);
notifyGlenn("📊 Progress: 50%", NOTIFICATION_LEVELS.INFO);
```

---

## Implementation Plan

### Phase 0: Prerequisites ✅

**Status:** Already available in OpenClaw

- [x] Sub-agent spawning (`openclaw agent spawn`)
- [x] PTY support (`exec` with `pty: true`)
- [x] Process monitoring (`process` tool)
- [x] Background execution
- [x] Session isolation
- [x] Multi-channel messaging

### Phase 1: Core Orchestration Logic (Week 1)

#### 1.1 Create Orchestration State Management

**File:** `lib/orchestration-state.js`

```javascript
// orchestration-state.js
const fs = require('fs');
const path = require('path');

const STATE_FILE = 'orchestration-state.json';

class OrchestrationState {
  constructor() {
    this.state = this.load();
  }
  
  load() {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
    return {
      subAgents: {},
      claudeCode: {
        active: false
      },
      glennActiveChannel: "telegram",
      lastTaskId: 0
    };
  }
  
  save() {
    fs.writeFileSync(STATE_FILE, JSON.stringify(this.state, null, 2));
  }
  
  addSubAgent(sessionId, task, model) {
    this.state.subAgents[sessionId] = {
      task,
      model,
      status: "running",
      startTime: Date.now()
    };
    this.save();
  }
  
  completeSubAgent(sessionId, result) {
    if (this.state.subAgents[sessionId]) {
      this.state.subAgents[sessionId].status = "complete";
      this.state.subAgents[sessionId].result = result;
      this.state.subAgents[sessionId].completedAt = Date.now();
      this.save();
    }
  }
  
  setClaudeCodeActive(sessionId, task) {
    this.state.claudeCode = {
      active: true,
      sessionId,
      task,
      startTime: Date.now(),
      lastCheck: Date.now(),
      lastReadOffset: 0
    };
    this.save();
  }
  
  getActiveSubAgents() {
    return Object.entries(this.state.subAgents)
      .filter(([_, agent]) => agent.status === "running")
      .map(([id, agent]) => ({ id, ...agent }));
  }
}

module.exports = new OrchestrationState();
```

#### 1.2 Create Task Classification System

**File:** `lib/task-classifier.js`

```javascript
// task-classifier.js

const COMPLEXITY = {
  TRIVIAL: "trivial",
  SIMPLE: "simple",
  COMPLEX: "complex",
  PROJECT: "project"
};

const MODEL = {
  SELF: "self",
  HAIKU: "haiku",
  SONNET: "sonnet",
  OPUS: "opus",
  CLAUDE_CODE: "claude-code"
};

function classifyTask(taskDescription) {
  const lower = taskDescription.toLowerCase();
  
  // Trivial - handle directly
  if (
    lower.match(/^(hi|hello|hey|status|what'?s up)/i) ||
    lower.match(/weather|time|date/) ||
    lower.length < 20
  ) {
    return { complexity: COMPLEXITY.TRIVIAL, model: MODEL.SELF };
  }
  
  // Project - Claude Code
  if (
    lower.includes("refactor") ||
    lower.includes("migrate") ||
    lower.includes("build system") ||
    lower.includes("entire project") ||
    lower.includes("codebase") ||
    lower.match(/implement .*(feature|system|api)/)
  ) {
    return { complexity: COMPLEXITY.PROJECT, model: MODEL.CLAUDE_CODE };
  }
  
  // Complex - Sonnet
  if (
    lower.includes("debug") ||
    lower.includes("design") ||
    lower.includes("research") ||
    lower.includes("analyze") ||
    lower.includes("compare") ||
    lower.includes("write code") ||
    lower.includes("create script")
  ) {
    return { complexity: COMPLEXITY.COMPLEX, model: MODEL.SONNET };
  }
  
  // Simple - Haiku
  if (
    lower.includes("read") ||
    lower.includes("search") ||
    lower.includes("summarize") ||
    lower.includes("extract") ||
    lower.includes("find") ||
    lower.includes("list")
  ) {
    return { complexity: COMPLEXITY.SIMPLE, model: MODEL.HAIKU };
  }
  
  // Default: Complex (Sonnet)
  return { complexity: COMPLEXITY.COMPLEX, model: MODEL.SONNET };
}

function selectModel(complexity, estimatedTokens = 50000) {
  switch (complexity) {
    case COMPLEXITY.TRIVIAL:
      return MODEL.SELF;
    
    case COMPLEXITY.SIMPLE:
      return MODEL.HAIKU;
    
    case COMPLEXITY.COMPLEX:
      // Use Opus if estimated tokens > 100K and high value
      return estimatedTokens > 100000 ? MODEL.OPUS : MODEL.SONNET;
    
    case COMPLEXITY.PROJECT:
      return MODEL.CLAUDE_CODE;
    
    default:
      return MODEL.SONNET;
  }
}

module.exports = {
  classifyTask,
  selectModel,
  COMPLEXITY,
  MODEL
};
```

#### 1.3 Create Delegation System

**File:** `lib/delegator.js`

```javascript
// delegator.js
const { exec } = require('./openclaw-tools');
const state = require('./orchestration-state');
const { classifyTask } = require('./task-classifier');
const { notifyGlenn } = require('./notifier');

async function delegateTask(taskDescription, overrideModel = null) {
  const classification = classifyTask(taskDescription);
  const model = overrideModel || classification.model;
  
  if (model === "self") {
    // Don't delegate, handle in current session
    return { delegated: false, reason: "Task is trivial, handling directly" };
  }
  
  if (model === "claude-code") {
    return await spawnClaudeCode(taskDescription);
  }
  
  // Spawn sub-agent
  return await spawnSubAgent(taskDescription, model);
}

async function spawnSubAgent(task, model) {
  const sessionId = `subagent-${Date.now()}`;
  const label = task.substring(0, 50);
  
  notifyGlenn(`🚀 Starting task: ${label} (${model})`);
  
  // Spawn via OpenClaw
  const result = await exec({
    command: "openclaw",
    args: [
      "agent", "spawn",
      "--label", label,
      "--model", `anthropic/claude-${model}`,
      "--task", task
    ],
    background: true
  });
  
  // Track in state
  state.addSubAgent(sessionId, task, model);
  
  return {
    delegated: true,
    sessionId,
    model,
    task
  };
}

async function spawnClaudeCode(task) {
  const sessionId = `claude-code-${Date.now()}`;
  
  notifyGlenn(`🔧 Starting Claude Code session: ${task}`);
  
  // Create instruction file for Claude Code
  const instructionFile = `/tmp/claude-code-${Date.now()}.txt`;
  fs.writeFileSync(instructionFile, task);
  
  const result = await exec({
    command: "claude-code",
    args: ["--instructions", instructionFile, "--non-interactive"],
    pty: true,
    background: true,
    yieldMs: 2000,
    workdir: process.cwd()
  });
  
  // Track in state
  state.setClaudeCodeActive(result.sessionId, task);
  
  notifyGlenn(`⚙️ Claude Code is working. I'll monitor progress and update you.`);
  
  return {
    delegated: true,
    sessionId: result.sessionId,
    model: "claude-code",
    task
  };
}

module.exports = {
  delegateTask,
  spawnSubAgent,
  spawnClaudeCode
};
```

#### 1.4 Create Notification System

**File:** `lib/notifier.js`

```javascript
// notifier.js
const { message } = require('./openclaw-tools');
const state = require('./orchestration-state');

const LEVELS = {
  URGENT: { silent: false, priority: "high" },
  IMPORTANT: { silent: false, priority: "normal" },
  INFO: { silent: true, priority: "low" }
};

async function notifyGlenn(text, level = LEVELS.INFO) {
  const channel = state.state.glennActiveChannel || "telegram";
  
  await message({
    action: "send",
    target: process.env.GLENN_CHAT_ID || channel,
    message: text,
    silent: level.silent
  });
}

async function reportProgress(taskId, milestone) {
  const task = state.state.subAgents[taskId];
  if (!task) return;
  
  await notifyGlenn(`📊 ${task.task}: ${milestone}`, LEVELS.INFO);
}

async function reportCompletion(taskId, summary) {
  const task = state.state.subAgents[taskId];
  if (!task) return;
  
  const duration = Math.round((Date.now() - task.startTime) / 1000);
  
  await notifyGlenn(`
✅ Completed: ${task.task}
⏱️ Duration: ${duration}s
📝 ${summary}
  `.trim(), LEVELS.IMPORTANT);
}

async function reportError(taskId, error) {
  const task = state.state.subAgents[taskId];
  
  await notifyGlenn(`
🚨 Error in task: ${task?.task || taskId}
❌ ${error}
  `.trim(), LEVELS.URGENT);
}

module.exports = {
  notifyGlenn,
  reportProgress,
  reportCompletion,
  reportError,
  LEVELS
};
```

### Phase 2: Claude Code Monitoring (Week 1-2)

#### 2.1 Create Claude Code Monitor

**File:** `lib/claude-code-monitor.js`

```javascript
// claude-code-monitor.js
const { process } = require('./openclaw-tools');
const state = require('./orchestration-state');
const { notifyGlenn, LEVELS } = require('./notifier');

class ClaudeCodeMonitor {
  constructor() {
    this.checkInterval = 5 * 60 * 1000; // 5 minutes
  }
  
  async check() {
    const cc = state.state.claudeCode;
    
    if (!cc.active) return;
    
    try {
      // Read new logs
      const logs = await process({
        action: "log",
        sessionId: cc.sessionId,
        offset: cc.lastReadOffset || 0,
        limit: 1000
      });
      
      if (!logs || logs.length === 0) return;
      
      // Update offset
      cc.lastReadOffset = (cc.lastReadOffset || 0) + logs.length;
      cc.lastCheck = Date.now();
      state.save();
      
      // Parse for milestones
      const milestones = this.extractMilestones(logs);
      
      if (milestones.length > 0) {
        await notifyGlenn(`🔧 Claude Code progress:\n${milestones.join('\n')}`, LEVELS.INFO);
      }
      
      // Check for completion
      if (this.isComplete(logs)) {
        await this.handleCompletion(logs);
      }
      
      // Check for errors
      const errors = this.extractErrors(logs);
      if (errors.length > 0) {
        await notifyGlenn(`⚠️ Claude Code warnings:\n${errors.join('\n')}`, LEVELS.URGENT);
      }
      
    } catch (error) {
      console.error("Error monitoring Claude Code:", error);
    }
  }
  
  extractMilestones(logs) {
    const milestones = [];
    const logText = logs.join('\n');
    
    // Common milestone patterns
    const patterns = [
      /✅ .*/g,
      /Completed: .*/g,
      /Modified \d+ files?/g,
      /Created .*/g,
      /Tests passing/g
    ];
    
    patterns.forEach(pattern => {
      const matches = logText.match(pattern);
      if (matches) {
        milestones.push(...matches);
      }
    });
    
    return milestones.slice(0, 5); // Limit to 5 most recent
  }
  
  extractErrors(logs) {
    const errors = [];
    const logText = logs.join('\n');
    
    const errorPatterns = [
      /Error: .*/g,
      /Failed: .*/g,
      /❌ .*/g
    ];
    
    errorPatterns.forEach(pattern => {
      const matches = logText.match(pattern);
      if (matches) {
        errors.push(...matches);
      }
    });
    
    return errors.slice(0, 3);
  }
  
  isComplete(logs) {
    const logText = logs.join('\n');
    return logText.includes('Session complete') || 
           logText.includes('All tasks finished') ||
           logText.includes('Exiting');
  }
  
  async handleCompletion(logs) {
    const cc = state.state.claudeCode;
    
    // Archive logs
    const logFile = `memory/claude-code-${Date.now()}.log`;
    fs.writeFileSync(logFile, logs.join('\n'));
    
    // Parse summary
    const summary = this.parseSummary(logs);
    
    // Notify Glenn
    await notifyGlenn(`
✅ Claude Code completed: ${cc.task}

${summary}

Full logs: ${logFile}
    `.trim(), LEVELS.IMPORTANT);
    
    // Clear state
    cc.active = false;
    state.save();
  }
  
  parseSummary(logs) {
    const logText = logs.join('\n');
    
    // Extract key metrics
    const filesMatch = logText.match(/(\d+) files? modified/);
    const linesMatch = logText.match(/(\d+) lines? added/);
    const testsMatch = logText.match(/Tests: (passing|failing)/);
    
    return `
Files modified: ${filesMatch ? filesMatch[1] : 'unknown'}
Lines added: ${linesMatch ? linesMatch[1] : 'unknown'}
Tests: ${testsMatch ? testsMatch[1] : 'unknown'}
    `.trim();
  }
}

module.exports = new ClaudeCodeMonitor();
```

#### 2.2 Integrate into Heartbeat

**File:** `HEARTBEAT.md`

```markdown
# HEARTBEAT.md - Proactive Tasks

## Periodic Checks

### Every heartbeat (~30 min):
1. Check if Claude Code is active → monitor progress
2. Check active sub-agents → report if any completed
3. Check Glenn's calendar (next 2 hours)

### 2-3 times per day:
- Email check (important/urgent only)
- Weather forecast (if relevant)

## State Files
- `orchestration-state.json` - Current tasks and sessions
- `memory/heartbeat-state.json` - Last check timestamps

## Claude Code Monitoring
If `orchestration-state.json` shows `claudeCode.active = true`:
- Run `lib/claude-code-monitor.check()`
- Do NOT interrupt the session
- Report milestones to Glenn
```

### Phase 3: Testing & Validation (Week 2)

#### 3.1 Create Test Suite

**File:** `tests/orchestration-test.js`

```javascript
// orchestration-test.js

const { delegateTask } = require('../lib/delegator');
const { classifyTask } = require('../lib/task-classifier');

async function runTests() {
  console.log("🧪 Running Orchestration Tests\n");
  
  // Test 1: Task Classification
  console.log("Test 1: Task Classification");
  const testCases = [
    { input: "Hi there", expected: "trivial" },
    { input: "Read config.json and extract the API key", expected: "simple" },
    { input: "Debug why the login API is returning 500 errors", expected: "complex" },
    { input: "Refactor the entire auth system to use OAuth2", expected: "project" }
  ];
  
  testCases.forEach(({ input, expected }) => {
    const result = classifyTask(input);
    const pass = result.complexity === expected;
    console.log(`  ${pass ? '✅' : '❌'} "${input}" → ${result.complexity} (expected: ${expected})`);
  });
  
  // Test 2: Sub-agent Spawning (dry run)
  console.log("\nTest 2: Sub-agent Spawning");
  const delegationResult = await delegateTask("Search for Python 3.12 release date");
  console.log(`  ✅ Delegation returned:`, delegationResult);
  
  // Test 3: State Management
  console.log("\nTest 3: State Management");
  const state = require('../lib/orchestration-state');
  const before = state.state.lastTaskId;
  state.state.lastTaskId++;
  state.save();
  state.load();
  const after = state.state.lastTaskId;
  console.log(`  ${after > before ? '✅' : '❌'} State persists across save/load`);
  
  console.log("\n✅ All tests complete");
}

runTests().catch(console.error);
```

#### 3.2 Create Test Scenarios

**File:** `tests/scenarios.md`

```markdown
# Test Scenarios

## Scenario 1: Simple Task Delegation

**Glenn:** "Search for the latest Node.js LTS version"

**Expected:**
1. Nikoline classifies as SIMPLE → Haiku
2. Spawns Haiku sub-agent
3. Notifies Glenn: "🚀 Starting task: Search for the latest Node.js LTS... (haiku)"
4. Sub-agent completes
5. Notifies Glenn: "✅ Completed: ... Latest LTS is v22.x"

## Scenario 2: Complex Task Delegation

**Glenn:** "Debug why the API tests are failing"

**Expected:**
1. Nikoline classifies as COMPLEX → Sonnet
2. Spawns Sonnet sub-agent
3. Notifies Glenn: "🚀 Starting task: Debug why the API tests... (sonnet)"
4. Sub-agent investigates
5. Reports progress: "📊 Found 3 failing tests"
6. Completes with analysis and fix suggestions
7. Notifies Glenn with summary

## Scenario 3: Claude Code + Parallel Chat

**Glenn:** "Refactor the auth system to use JWT tokens"

**Expected:**
1. Nikoline classifies as PROJECT → Claude Code
2. Spawns Claude Code in PTY background
3. Notifies Glenn: "🔧 Starting Claude Code session..."

*While Claude Code runs:*

**Glenn:** "What's the weather today?"

**Expected:**
4. Nikoline responds immediately (trivial task, handles directly)
5. Returns weather without interrupting Claude Code

*5 minutes later:*

**Expected:**
6. Heartbeat triggers Claude Code monitor
7. Finds milestone: "✅ Completed auth/jwt.js"
8. Notifies Glenn: "🔧 Claude Code progress: Completed auth/jwt.js"

*20 minutes later:*

**Expected:**
9. Claude Code completes
10. Nikoline detects completion
11. Archives logs
12. Notifies Glenn: "✅ Claude Code completed: Refactor auth system... Files modified: 7..."

## Scenario 4: Cost Optimization

**Glenn:** "Read these 10 log files and extract all error messages"

**Expected:**
1. Nikoline recognizes batch task
2. Does NOT spawn 10 sub-agents
3. Spawns ONE Haiku sub-agent with all 10 files
4. Cost: ~$0.05 (vs $0.50 if done wrong)

## Scenario 5: Escalation

**Glenn:** "Why is the database connection failing?"

**Expected:**
1. Nikoline spawns Haiku sub-agent (try simple first)
2. Haiku reads logs, finds issue is complex (connection pooling bug)
3. Haiku reports back: "Needs deeper analysis"
4. Nikoline escalates to Sonnet sub-agent
5. Sonnet analyzes, finds root cause
6. Notifies Glenn with solution
```

### Phase 4: Documentation & Rollout (Week 2-3)

#### 4.1 Create User Guide for Glenn

**File:** `GLENN-GUIDE.md` (see separate file below)

#### 4.2 Create Internal Reference for Nikoline

**File:** `NIKOLINE-ORCHESTRATION.md` (see separate file below)

#### 4.3 Gradual Rollout

**Week 1:**
- Implement Phase 1 (core logic)
- Test with simple tasks only
- Monitor costs

**Week 2:**
- Add Phase 2 (Claude Code monitoring)
- Test complex tasks
- Test parallel chat + Claude Code

**Week 3:**
- Full deployment
- Monitor for 1 week
- Gather feedback from Glenn
- Tune decision tree based on actual usage

---

## Use Cases & Examples

### Example 1: "Build feature X"

**Glenn:** "Build a REST API for the blog system with CRUD operations"

#### Decision Tree Walkthrough

```
1. Nikoline receives message
   └─> Check: Is this trivial? NO (requires coding)
   └─> Check: Is this simple? NO (multi-file, complex logic)
   └─> Check: Is this complex? MAYBE (could be Sonnet)
   └─> Check: Is this a project? YES (multi-file, build system)
   
2. Classification: PROJECT → Claude Code

3. Nikoline spawns Claude Code:
   - Creates instruction file
   - Spawns via PTY (background, non-interactive)
   - Saves session ID to orchestration-state.json
   
4. Nikoline notifies Glenn:
   "🔧 Starting Claude Code session: Build a REST API for the blog system"
   
5. Claude Code runs (in background):
   - Creates files: api/blog.js, routes/blog.js, models/Blog.js
   - Sets up Express routes
   - Adds tests
   - Logs progress to stdout
   
6. Nikoline monitors (every 5 min):
   - Reads logs via process.log()
   - Finds: "✅ Created api/blog.js"
   - Notifies Glenn: "🔧 Claude Code progress: Created api/blog.js"
   
7. Meanwhile, Glenn asks:
   "What time is the team meeting?"
   
8. Nikoline responds immediately:
   (Checks calendar, responds - Claude Code unaffected)
   
9. Claude Code completes (30 min later):
   - Logs: "Session complete. 5 files created, tests passing."
   
10. Nikoline detects completion:
    - Archives logs to memory/claude-code-<timestamp>.log
    - Parses summary
    - Notifies Glenn:
      "✅ Claude Code completed: Build REST API
      Files created: 5
      Tests: passing
      Full logs: memory/claude-code-1234567890.log"
```

#### Cost Analysis

- Claude Code: $0 (included in Max plan)
- Nikoline monitoring: ~5K tokens × 6 checks = 30K tokens = $0.45
- **Total: $0.45** (vs ~$30 if done with Opus API)

---

### Example 2: "Debug problem Y"

**Glenn:** "The login page is broken in production but works locally"

#### Decision Tree Walkthrough

```
1. Nikoline receives message
   └─> Check: Is this trivial? NO (requires investigation)
   └─> Check: Is this simple? NO (debugging is complex)
   └─> Check: Is this complex? YES (multi-step debugging)
   └─> Check: Is this a project? NO (debugging, not building)
   
2. Classification: COMPLEX → Sonnet

3. Nikoline analyzes scope:
   - Debugging = Sonnet (good at reasoning)
   - Not multi-file project = no need for Claude Code
   
4. Nikoline spawns Sonnet sub-agent:
   - Task: "Debug login page issue: works locally, fails in production"
   - Model: Sonnet
   
5. Nikoline notifies Glenn:
   "🚀 Starting task: Debug login page issue (sonnet)"
   
6. Sonnet sub-agent investigates:
   - Reads login page code
   - Checks production logs
   - Compares local vs production configs
   - Finds: Environment variable OAUTH_CLIENT_ID is missing in production
   
7. Sonnet sub-agent completes:
   - Returns: "Root cause: Missing OAUTH_CLIENT_ID in production environment"
   
8. Nikoline receives result:
   - Updates orchestration-state.json
   - Notifies Glenn:
     "✅ Completed: Debug login page issue
     ⏱️ Duration: 3m
     📝 Root cause: Missing OAUTH_CLIENT_ID in production environment
     
     Fix: Add OAUTH_CLIENT_ID to production .env file"
```

#### Cost Analysis

- Sonnet sub-agent: ~50K tokens = $0.75
- **Total: $0.75**

---

### Example 3: Glenn asks question while Claude Code runs

**Setup:** Claude Code is refactoring the auth system (30 min task)

#### Timeline

**T+0 min:**
```
Glenn: "Refactor the auth system to use JWT"
Nikoline: 🔧 Starting Claude Code session...
[Claude Code spawned in background]
```

**T+5 min:**
```
Glenn: "What's the weather today?"
Nikoline: [Checks weather API]
Nikoline: "Currently 72°F and sunny in SF"
[Claude Code still running, unaffected]
```

**T+10 min:**
```
Glenn: "How's the refactor going?"
Nikoline: [Checks orchestration-state.json]
Nikoline: [Reads Claude Code logs via process.log()]
Nikoline: "🔧 Claude Code is working on auth system refactor.
Latest progress:
- ✅ Created auth/jwt.js
- ✅ Modified auth/middleware.js
- ⏳ Working on tests
Started 10 minutes ago."
```

**T+15 min:**
```
Glenn: "Can you search for JWT best practices?"
Nikoline: [Classifies as SIMPLE]
Nikoline: [Spawns Haiku sub-agent]
Nikoline: "🚀 Starting task: Search for JWT best practices (haiku)"
[Haiku completes in 30 seconds]
Nikoline: "✅ Completed: Search for JWT best practices
Found these resources:
- Use short expiration (15 min)
- Implement refresh tokens
- Store in httpOnly cookies
[Claude Code still running]
```

**T+20 min:**
```
[Heartbeat triggers]
Nikoline: [Checks Claude Code monitor]
Nikoline: [Finds milestone: "✅ All tests passing"]
Nikoline: "🔧 Claude Code progress: All tests passing"
```

**T+30 min:**
```
[Claude Code finishes]
Nikoline: [Detects completion in logs]
Nikoline: [Archives logs]
Nikoline: "✅ Claude Code completed: Refactor auth system

Files modified: 7
Lines added: 340
Tests: passing ✅

Changes:
- Created JWT token generation/validation
- Updated middleware to use JWT
- Added refresh token support
- All tests passing

Full logs: memory/claude-code-1234567890.log"
```

#### Key Points

1. **Glenn's messages go to Nikoline's main session** - never to Claude Code
2. **Nikoline can do multiple things at once:**
   - Answer trivial questions immediately
   - Spawn additional sub-agents
   - Monitor Claude Code progress
3. **No interruption risk** - session isolation prevents accidents
4. **Progress reporting** - automatic updates without Glenn asking

---

## Cost Analysis

### Scenario: One Day of Heavy Usage

#### Tasks:
1. Build REST API (Claude Code, 1 hour)
2. Debug 3 issues (Sonnet × 3)
3. Search for 10 things (Haiku × 10)
4. 20 chat messages (Nikoline direct)

#### Cost Breakdown:

```
Claude Code (1 hour):
  - $0 (included in Max plan)

Nikoline orchestration (20 messages):
  - Input: 20 × 4K tokens = 80K tokens = $1.20
  - Output: 20 × 500 tokens = 10K tokens = $0.15
  - Subtotal: $1.35

Debugging (3 × Sonnet sub-agents):
  - 3 × 50K tokens = 150K tokens = $2.25

Searching (10 × Haiku sub-agents):
  - 10 × 10K tokens = 100K tokens = $0.125

Monitoring (6 checks × 5K tokens):
  - 30K tokens (Sonnet) = $0.45

TOTAL: $4.30/day
```

#### Cost Comparison (vs doing everything with main agent):

**Without orchestration (everything via Sonnet):**
- Same tasks: ~500K tokens = $7.50/day

**Savings: $3.20/day = $96/month**

Plus Claude Code unlimited usage (would cost $100-500/month if API)

---

## Summary: What Gets Built

### Files to Create:

1. **lib/orchestration-state.js** - State management
2. **lib/task-classifier.js** - Task classification logic
3. **lib/delegator.js** - Sub-agent/Claude Code spawning
4. **lib/notifier.js** - Progress reporting to Glenn
5. **lib/claude-code-monitor.js** - Claude Code progress monitoring
6. **tests/orchestration-test.js** - Test suite
7. **tests/scenarios.md** - Test scenarios
8. **HEARTBEAT.md** - Update with monitoring tasks
9. **GLENN-GUIDE.md** - User guide for Glenn
10. **NIKOLINE-ORCHESTRATION.md** - Internal reference for Nikoline

### Configurations:

1. **Environment variables:**
   - `GLENN_CHAT_ID` - Glenn's Telegram/webchat ID
   - `CLAUDE_CODE_PATH` - Path to Claude Code CLI

2. **orchestration-state.json** - Runtime state

### Integration Points:

1. **Nikoline's main loop:**
   - Add task classification on every message
   - Add delegation logic
   - Add monitoring to heartbeat

2. **AGENTS.md updates:**
   - Add orchestration rules
   - Add delegation guidelines

---

## Next Steps

1. **Review this design with Glenn** - confirm approach
2. **Phase 1 implementation** - core orchestration (Week 1)
3. **Testing** - validate with simple tasks
4. **Phase 2 implementation** - Claude Code integration (Week 2)
5. **Full deployment** - gradual rollout (Week 3)
6. **Monitoring & tuning** - adjust based on real usage

---

**Status:** ✅ Design Complete - Ready for Glenn's Review
