# Orchestration System V2 - Updates & New Features

**Updated:** 2026-02-04  
**Version:** 2.0  
**Status:** Design Complete - Ready for Implementation

---

## What's New in V2

Glenn's updated requirements add **team identity**, **conflict management**, and **smart resource allocation** to the orchestration system.

---

## 1. Team Naming System

### The Team

```
┌─────────────────────────────────────────────────────────────────┐
│                         THE TEAM                                 │
└─────────────────────────────────────────────────────────────────┘

👑 NIKOLINE (Orchestrator)
   Model: Claude Sonnet 4.5
   Role: Main agent, task router, team manager
   Session: agent:main:main
   Always available for Glenn

⚡ HARALD (Speed Specialist)
   Model: Claude Haiku
   Role: Quick tasks (read, search, extract, summarize)
   Session: agent:main:harald:<instance>
   Cost: $1.25/M tokens
   Specialty: Fast, cheap, simple

🧠 SONNY (Problem Solver)
   Model: Claude Sonnet
   Role: Complex tasks (debug, design, research, analysis)
   Session: agent:main:sonny:<instance>
   Cost: $15/M tokens
   Specialty: Reasoning, multi-step work

🔧 CLAUDECODE (Builder)
   Model: Claude Code (Max Plan)
   Role: Multi-file projects, refactoring, build systems
   Session: exec:pty:<pid>
   Cost: $0 (included in Max plan)
   Specialty: Heavy coding
```

### Why Named Agents?

1. **Personality** - Easier for Glenn to think "ask Harald to search for docs"
2. **Status clarity** - "Harald is busy" vs "Sub-agent 3 is running"
3. **Resource tracking** - Know which specialist is available
4. **Human-friendly** - More conversational than "spawn haiku sub-agent"

---

## 2. Conflict Detection & Resolution

### The Problem

```
Glenn: "Harald, search for Node.js docs"
  ↓
Nikoline: [Checks] Harald is already working on another task!
  ↓
What now?
```

### The Solution: Smart Conflict Management

```
┌─────────────────────────────────────────────────────────────────┐
│                   CONFLICT DETECTION FLOW                        │
└─────────────────────────────────────────────────────────────────┘

Task arrives → Classify → Select agent
                              ↓
                    Is that agent available?
                              ↓
                ┌─────────────┴─────────────┐
              YES                           NO
                │                            │
                ▼                            ▼
         Spawn normally          ┌──────────────────────┐
                                 │  CONFLICT DETECTED!  │
                                 │                      │
                                 │ Present 4 options:   │
                                 │ 1. Wait (with ETA)   │
                                 │ 2. Route to other    │
                                 │ 3. Spawn new instance│
                                 │ 4. Abort existing    │
                                 └──────────────────────┘
```

### Option 1: Wait for Completion

```
Nikoline: "Harald is currently busy working on: 'Search Python docs'
          Estimated time remaining: 8 minutes
          
          ⏱️ WAIT for Harald to finish? (8 min)
          📋 Your task will start automatically when Harald is free."
```

**When to suggest:**
- Current task almost done (ETA < 10 min)
- Task specifically requested that agent
- Queue is empty

### Option 2: Route to Another Agent

```
Nikoline: "Harald is busy (ETA 15 min).
          
          🔄 ROUTE to Sonny instead?
          ⚡ Sonny can handle this task (might be slower but more thorough)
          💰 Cost: ~$0.50 vs Harald's $0.05 (10x more expensive)"
```

**When to suggest:**
- Alternative agent is available
- Task is compatible with alternative
- Wait time is long (>10 min)

**Auto-routing rules:**
- Harald busy → Sonny (if available)
- Sonny busy → Harald (only if task is simple enough)
- ClaudeCode busy → Sonny (only for smaller coding tasks)

### Option 3: Spawn New Instance

```
Nikoline: "Harald is busy (ETA 15 min).
          
          🆕 SPAWN a second Harald instance?
          ✅ Task starts immediately
          ⚠️ Cost: Full instance cost (~$0.05 for this task)
          📊 Current: 1 Harald instance running
              After: 2 Harald instances (parallel)"
```

**When to suggest:**
- Task is urgent
- Cost is acceptable (simple task, cheap agent)
- System resources available

**Limits:**
- Max 3 Harald instances
- Max 2 Sonny instances
- Max 1 ClaudeCode instance (for now)

### Option 4: Abort Existing Job

```
Nikoline: "Harald is busy working on: 'Search Python docs' (started 12 min ago)
          
          ⚠️ ABORT Harald's current job and start yours?
          🚨 This will kill the running task!
          📝 Current task progress will be lost.
          
          Are you sure? (This is usually not recommended)"
```

**When to suggest:**
- Only as last resort
- Glenn explicitly wants this
- Existing task is low-priority

---

## 3. Automatic Routing

### Smart Decision Engine

```javascript
function autoRoute(task, preferredAgent) {
  // Check if preferred agent is available
  const available = checkAgentAvailability(preferredAgent);
  
  if (available) {
    return { agent: preferredAgent, action: "spawn" };
  }
  
  // Conflict! Apply auto-routing rules
  const routing = getAutoRoutingRule(preferredAgent, task);
  
  if (routing.auto) {
    // Auto-route without asking
    notifyGlenn(`${preferredAgent} is busy. Auto-routing to ${routing.alternative}...`);
    return { agent: routing.alternative, action: "spawn" };
  } else {
    // Present options to Glenn
    return presentConflictOptions(preferredAgent, task);
  }
}
```

### Routing Rules Matrix

| Preferred | Busy? | Task Type | Auto-Route To | Notify Glenn? |
|-----------|-------|-----------|---------------|---------------|
| Harald | Yes | Simple | Sonny | Yes ("upgrading to Sonny") |
| Harald | Yes | Complex | Sonny | Yes ("routing to Sonny") |
| Sonny | Yes | Simple | Harald | Ask (might be too simple for queue) |
| Sonny | Yes | Complex | Queue | Ask (show options) |
| ClaudeCode | Yes | Any | Queue | Always ask (expensive alternatives) |

### Auto-Routing Examples

#### Example 1: Harald Busy, Simple Task

```
Glenn: "Search for JWT docs"
  ↓
Classify: SIMPLE → Harald
  ↓
Check: Harald busy (ETA 12 min)
  ↓
Auto-route: Harald → Sonny
  ↓
Nikoline: "Harald is busy searching Python docs (12 min remaining).
          ⚡ Auto-routing to Sonny for faster service.
          🚀 Starting task: Search for JWT docs (sonny)"
```

**Cost impact:** $0.05 (Harald) → $0.50 (Sonny) = $0.45 more, but immediate

#### Example 2: Sonny Busy, Complex Task

```
Glenn: "Debug the API timeout issue"
  ↓
Classify: COMPLEX → Sonny
  ↓
Check: Sonny busy (ETA 18 min)
  ↓
Options: Can't auto-route (task too complex for Harald)
  ↓
Nikoline: "Sonny is busy analyzing the database schema (18 min).
          
          Your options:
          1. ⏱️ WAIT 18 minutes (recommended)
          2. 📋 ADD TO QUEUE (starts when Sonny is free)
          3. 🆕 SPAWN second Sonny instance (+$1.50)
          4. ⚠️ ABORT Sonny's current task (not recommended)
          
          What would you like to do?"
```

#### Example 3: ClaudeCode Busy

```
Glenn: "Add TypeScript to the project"
  ↓
Classify: PROJECT → ClaudeCode
  ↓
Check: ClaudeCode busy (ETA 45 min)
  ↓
No auto-route (ClaudeCode unique)
  ↓
Nikoline: "ClaudeCode is busy refactoring the auth system (45 min).
          
          Your options:
          1. ⏱️ WAIT 45 minutes
          2. 📋 ADD TO QUEUE (high priority)
          3. 🔄 ROUTE to Sonny? (can handle small TS migration)
          
          Recommendation: Queue this task (it's a big job anyway)"
```

---

## 4. Sub-Agent Status Tracking

### Real-Time Status Display

```javascript
// orchestration-state.json structure (V2)
{
  "agents": {
    "harald": {
      "instances": [
        {
          "id": "harald-1704396000",
          "status": "busy",
          "task": "Search for Python 3.12 docs",
          "startTime": 1704396000,
          "estimatedDuration": 120000,  // 2 minutes in ms
          "progress": 0.65  // 65% complete
        }
      ],
      "maxInstances": 3
    },
    "sonny": {
      "instances": [
        {
          "id": "sonny-1704396120",
          "status": "busy",
          "task": "Debug API timeout issue",
          "startTime": 1704396120,
          "estimatedDuration": 600000,  // 10 minutes
          "progress": 0.30
        }
      ],
      "maxInstances": 2
    },
    "claudecode": {
      "instances": [
        {
          "id": "claudecode-1704396300",
          "status": "busy",
          "task": "Refactor auth system to JWT",
          "startTime": 1704396300,
          "estimatedDuration": 1800000,  // 30 minutes
          "progress": 0.15
        }
      ],
      "maxInstances": 1
    }
  },
  "queue": [
    {
      "id": "queued-task-1",
      "task": "Migrate database to Postgres",
      "preferredAgent": "claudecode",
      "priority": "high",
      "queuedAt": 1704396400
    }
  ]
}
```

### Status Command

Glenn can type **"status"** anytime:

```
Glenn: "status"
  ↓
Nikoline: 
"📊 TEAM STATUS

👑 NIKOLINE (Me)
   Status: Available 
   Ready to help!

⚡ HARALD (Speed Specialist)
   Instance 1: 🔴 BUSY - ETA 8 min
      Task: Search for Python 3.12 documentation
      Progress: ████████░░ 65%
      Started: 12 minutes ago
   
   Instance 2: 🟢 AVAILABLE
   Instance 3: 🟢 AVAILABLE

🧠 SONNY (Problem Solver)
   Instance 1: 🔴 BUSY - ETA 15 min
      Task: Debug API timeout issue
      Progress: ████░░░░░░ 30%
      Started: 5 minutes ago
   
   Instance 2: 🟢 AVAILABLE

🔧 CLAUDECODE (Builder)
   Status: 🔴 BUSY - ETA 42 min
      Task: Refactor auth system to JWT
      Progress: ███░░░░░░░ 15%
      Started: 18 minutes ago
      Last milestone: Created auth/jwt.js

📋 QUEUE: 1 task waiting
   • Migrate database to Postgres (priority: high)
     Waiting for: ClaudeCode

💰 COSTS TODAY: $8.45
   Harald: $0.35 (7 tasks)
   Sonny: $6.10 (3 tasks)
   ClaudeCode: $0 (Max plan)
   Nikoline: $2.00 (orchestration)"
```

### Automatic Status Updates

Nikoline sends status updates automatically:

**When task starts:**
```
🚀 Harald started: Search for Python docs (ETA 2 min)
```

**Progress milestones (every 25%):**
```
📊 Sonny progress: 25% complete (Debug API timeout)
📊 Sonny progress: 50% complete
📊 Sonny progress: 75% complete
```

**When ETA changes significantly:**
```
⏱️ Update: ClaudeCode ETA now 55 min (was 30 min)
   Reason: Task more complex than estimated
```

**When task completes:**
```
✅ Harald completed: Search for Python docs (2m 15s)
```

### ETA Calculation

```javascript
function calculateETA(task, agent) {
  const complexity = classifyTask(task).complexity;
  const baseEstimates = {
    harald: {
      trivial: 30000,   // 30 seconds
      simple: 120000,   // 2 minutes
      complex: 300000   // 5 minutes (shouldn't happen)
    },
    sonny: {
      simple: 300000,    // 5 minutes
      complex: 600000,   // 10 minutes
      project: 1800000   // 30 minutes
    },
    claudecode: {
      project: 1800000,      // 30 minutes (small)
      largeProject: 5400000  // 90 minutes (large)
    }
  };
  
  let estimate = baseEstimates[agent][complexity];
  
  // Adjust based on historical data
  const history = getAgentHistory(agent, complexity);
  if (history.length > 5) {
    const avgActual = history.reduce((sum, h) => sum + h.duration, 0) / history.length;
    estimate = (estimate + avgActual) / 2;  // Blend estimate with reality
  }
  
  return estimate;
}

function updateProgress(agentId) {
  const instance = getAgentInstance(agentId);
  const elapsed = Date.now() - instance.startTime;
  const progress = Math.min(elapsed / instance.estimatedDuration, 0.95);
  
  instance.progress = progress;
  
  // Update ETA based on progress
  if (progress > 0.5 && !instance.etaAdjusted) {
    const actualHalfTime = elapsed;
    const estimatedTotal = actualHalfTime * 2;
    
    if (Math.abs(estimatedTotal - instance.estimatedDuration) > 300000) {
      // More than 5 min difference, update ETA
      instance.estimatedDuration = estimatedTotal;
      instance.etaAdjusted = true;
      
      notifyGlenn(`⏱️ ETA updated: ${formatDuration(estimatedTotal - elapsed)}`);
    }
  }
  
  saveState();
}
```

---

## 5. Queue System

### Queue Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          TASK QUEUE                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ HIGH PRIORITY                                             │  │
│  │ 1. Migrate database to Postgres [ClaudeCode] (30 min)    │  │
│  │ 2. Fix login bug [Sonny] (10 min)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ NORMAL PRIORITY                                           │  │
│  │ 3. Search for React 18 docs [Harald] (2 min)             │  │
│  │ 4. Analyze error logs [Sonny] (15 min)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ LOW PRIORITY                                              │  │
│  │ 5. Summarize meeting notes [Harald] (5 min)              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Queue Modes

**1. FIFO (First In, First Out)**
- Default mode
- Tasks execute in order received
- Fair, predictable

**2. Priority-Based**
- High priority tasks jump the queue
- Glenn can mark tasks as urgent
- Useful for emergencies

**3. Shortest Job First**
- Quick tasks go first
- Minimizes average wait time
- Optional mode

### Queue Operations

#### Adding to Queue

```
Glenn: "Queue: Migrate database to Postgres"
  ↓
Nikoline: "📋 Added to queue: Migrate database to Postgres
          Assigned to: ClaudeCode
          Priority: Normal
          Position: #3 in queue
          Estimated wait: 45 minutes
          Will start when: ClaudeCode finishes current task
          
          Want to make this high priority? Reply 'priority high'"
```

#### Checking Queue

```
Glenn: "queue status"
  ↓
Nikoline: "📋 CURRENT QUEUE (3 tasks)

HIGH PRIORITY:
  1. Fix login bug
     Agent: Sonny
     ETA: Starts in 8 min (when Sonny free)
     Duration: ~10 min

NORMAL:
  2. Migrate database
     Agent: ClaudeCode
     ETA: Starts in 42 min
     Duration: ~30 min
  
  3. Analyze error logs
     Agent: Sonny
     ETA: Starts in 18 min (after #1)
     Duration: ~15 min

Total wait for last task: ~55 minutes"
```

#### Queue Notifications

**When task moves up:**
```
📋 Your task 'Analyze error logs' moved up in queue
   New position: #2 (was #4)
   ETA: Starts in 15 min (was 30 min)
```

**When task starts:**
```
🚀 Queue: Starting your task 'Fix login bug'
   Agent: Sonny
   ETA: 10 minutes
```

**When queue is empty:**
```
✅ Queue is now empty! All tasks complete.
   All agents available.
```

---

## Updated Architecture Diagram

```
                         ┌─────────────────┐
                         │     GLENN       │
                         └────────┬────────┘
                                  │
                                  ▼
                    ┌──────────────────────────┐
                    │   NIKOLINE (Orchestrator)│
                    │   • Classify tasks       │
                    │   • Detect conflicts     │
                    │   • Manage queue         │
                    │   • Track status         │
                    │   • Auto-route           │
                    └──────────┬───────────────┘
                               │
                               │ Checks availability
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
    ┌─────────────────┐ ┌──────────────┐ ┌────────────────┐
    │ HARALD          │ │    SONNY     │ │  CLAUDECODE    │
    │ (Haiku)         │ │   (Sonnet)   │ │  (Max Plan)    │
    │                 │ │              │ │                │
    │ Max 3 instances │ │ Max 2        │ │  Max 1         │
    │                 │ │ instances    │ │  instance      │
    │                 │ │              │ │                │
    │ Status tracked  │ │ Status       │ │  Status        │
    │ ETA calculated  │ │ tracked      │ │  tracked       │
    └─────────────────┘ └──────────────┘ └────────────────┘
              │                │                │
              │                │                │
              └────────────────┴────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   TASK QUEUE         │
                    │   • Priority-based   │
                    │   • ETA tracking     │
                    │   • Auto-start       │
                    └──────────────────────┘
```

---

## Implementation Updates

### New Libraries

**lib/agent-manager.js** - Agent availability and conflict detection
```javascript
class AgentManager {
  constructor() {
    this.agents = {
      harald: { maxInstances: 3, instances: [] },
      sonny: { maxInstances: 2, instances: [] },
      claudecode: { maxInstances: 1, instances: [] }
    };
  }
  
  isAvailable(agentName) {
    const agent = this.agents[agentName];
    return agent.instances.length < agent.maxInstances;
  }
  
  getAvailableInstance(agentName) {
    if (this.isAvailable(agentName)) {
      return this.createInstance(agentName);
    }
    return null;
  }
  
  detectConflict(agentName, task) {
    if (!this.isAvailable(agentName)) {
      return {
        conflict: true,
        currentTasks: this.agents[agentName].instances.map(i => i.task),
        eta: this.calculateETA(agentName),
        options: this.generateOptions(agentName, task)
      };
    }
    return { conflict: false };
  }
  
  generateOptions(agentName, task) {
    const options = [];
    
    // Option 1: Wait
    const eta = this.calculateETA(agentName);
    options.push({
      type: 'wait',
      description: `Wait ${formatDuration(eta)} for ${agentName} to finish`,
      eta: eta,
      cost: 0
    });
    
    // Option 2: Route to alternative
    const alternative = this.getAlternative(agentName, task);
    if (alternative) {
      options.push({
        type: 'route',
        description: `Route to ${alternative.name} instead`,
        agent: alternative.name,
        cost: alternative.costDelta
      });
    }
    
    // Option 3: Spawn new instance
    if (this.canSpawnNew(agentName)) {
      options.push({
        type: 'spawn',
        description: `Spawn new ${agentName} instance`,
        cost: this.estimateCost(agentName, task)
      });
    }
    
    // Option 4: Abort (always last resort)
    options.push({
      type: 'abort',
      description: `Abort current task and start yours (not recommended)`,
      risk: 'high'
    });
    
    return options;
  }
  
  calculateETA(agentName) {
    const instances = this.agents[agentName].instances;
    if (instances.length === 0) return 0;
    
    // Find instance with shortest remaining time
    const etas = instances.map(i => {
      const elapsed = Date.now() - i.startTime;
      const remaining = i.estimatedDuration - elapsed;
      return Math.max(remaining, 0);
    });
    
    return Math.min(...etas);
  }
  
  getAlternative(agentName, task) {
    const complexity = classifyTask(task).complexity;
    
    if (agentName === 'harald') {
      if (this.isAvailable('sonny')) {
        return { 
          name: 'sonny', 
          costDelta: 0.45  // ~$0.50 vs $0.05
        };
      }
    }
    
    if (agentName === 'sonny') {
      if (complexity === 'simple' && this.isAvailable('harald')) {
        return { 
          name: 'harald', 
          costDelta: -0.45  // Cheaper!
        };
      }
    }
    
    return null;
  }
}
```

**lib/queue-manager.js** - Task queue management
```javascript
class QueueManager {
  constructor() {
    this.queue = [];
    this.mode = 'fifo';  // or 'priority' or 'sjf'
  }
  
  add(task, priority = 'normal') {
    const queueItem = {
      id: generateId(),
      task: task,
      priority: priority,
      queuedAt: Date.now(),
      preferredAgent: classifyTask(task).model,
      estimatedDuration: estimateDuration(task)
    };
    
    this.queue.push(queueItem);
    this.sort();
    
    return {
      position: this.queue.indexOf(queueItem) + 1,
      eta: this.calculateWaitTime(queueItem)
    };
  }
  
  sort() {
    if (this.mode === 'priority') {
      this.queue.sort((a, b) => {
        const priorityOrder = { high: 0, normal: 1, low: 2 };
        return priorityOrder[a.priority] - priorityOrder[b.priority];
      });
    } else if (this.mode === 'sjf') {
      this.queue.sort((a, b) => a.estimatedDuration - b.estimatedDuration);
    }
    // FIFO: no sorting needed
  }
  
  next(agentName) {
    // Find first task that wants this agent
    const index = this.queue.findIndex(item => item.preferredAgent === agentName);
    
    if (index !== -1) {
      return this.queue.splice(index, 1)[0];
    }
    
    return null;
  }
  
  remove(taskId) {
    const index = this.queue.findIndex(item => item.id === taskId);
    if (index !== -1) {
      this.queue.splice(index, 1);
      return true;
    }
    return false;
  }
  
  calculateWaitTime(queueItem) {
    const position = this.queue.indexOf(queueItem);
    let waitTime = 0;
    
    // Add up estimated durations of all tasks before this one
    for (let i = 0; i < position; i++) {
      waitTime += this.queue[i].estimatedDuration;
    }
    
    return waitTime;
  }
  
  getStatus() {
    return {
      count: this.queue.length,
      mode: this.mode,
      tasks: this.queue.map((item, index) => ({
        position: index + 1,
        task: item.task,
        priority: item.priority,
        agent: item.preferredAgent,
        eta: this.calculateWaitTime(item)
      }))
    };
  }
}
```

**lib/eta-calculator.js** - ETA estimation and tracking
```javascript
class ETACalculator {
  constructor() {
    this.history = this.loadHistory();
  }
  
  estimate(task, agent) {
    const complexity = classifyTask(task).complexity;
    const baseEstimate = this.getBaseEstimate(agent, complexity);
    
    // Adjust based on historical data
    const historicalAvg = this.getHistoricalAverage(agent, complexity);
    
    if (historicalAvg) {
      // Blend: 70% historical, 30% base estimate
      return (historicalAvg * 0.7) + (baseEstimate * 0.3);
    }
    
    return baseEstimate;
  }
  
  getBaseEstimate(agent, complexity) {
    const estimates = {
      harald: {
        trivial: 30 * 1000,      // 30 seconds
        simple: 2 * 60 * 1000,   // 2 minutes
        complex: 5 * 60 * 1000   // 5 minutes
      },
      sonny: {
        simple: 5 * 60 * 1000,   // 5 minutes
        complex: 10 * 60 * 1000, // 10 minutes
        project: 30 * 60 * 1000  // 30 minutes
      },
      claudecode: {
        project: 30 * 60 * 1000,       // 30 minutes
        largeProject: 90 * 60 * 1000   // 90 minutes
      }
    };
    
    return estimates[agent][complexity] || 10 * 60 * 1000;
  }
  
  updateProgress(instanceId) {
    const instance = getAgentInstance(instanceId);
    const elapsed = Date.now() - instance.startTime;
    const progress = Math.min(elapsed / instance.estimatedDuration, 0.95);
    
    instance.progress = progress;
    
    // Recalculate ETA at 50% mark
    if (progress >= 0.5 && !instance.etaRecalculated) {
      const actualHalfTime = elapsed;
      const projectedTotal = actualHalfTime * 2;
      
      if (Math.abs(projectedTotal - instance.estimatedDuration) > 5 * 60 * 1000) {
        // Difference > 5 minutes, update
        instance.estimatedDuration = projectedTotal;
        instance.etaRecalculated = true;
        
        const remaining = projectedTotal - elapsed;
        notifyGlenn(`⏱️ ETA updated: ${formatDuration(remaining)}`);
      }
    }
    
    return {
      progress: progress,
      eta: instance.estimatedDuration - elapsed
    };
  }
  
  recordCompletion(agent, complexity, actualDuration) {
    if (!this.history[agent]) {
      this.history[agent] = {};
    }
    
    if (!this.history[agent][complexity]) {
      this.history[agent][complexity] = [];
    }
    
    this.history[agent][complexity].push({
      duration: actualDuration,
      timestamp: Date.now()
    });
    
    // Keep only last 20 entries
    if (this.history[agent][complexity].length > 20) {
      this.history[agent][complexity].shift();
    }
    
    this.saveHistory();
  }
  
  getHistoricalAverage(agent, complexity) {
    if (!this.history[agent] || !this.history[agent][complexity]) {
      return null;
    }
    
    const entries = this.history[agent][complexity];
    if (entries.length < 3) return null;
    
    const sum = entries.reduce((acc, entry) => acc + entry.duration, 0);
    return sum / entries.length;
  }
}
```

---

## Updated Workflow

### Complete Flow with New Features

```
1. Glenn: "Harald, search for Node.js docs"
   ↓
2. Nikoline classifies: SIMPLE → Harald
   ↓
3. Check availability: AgentManager.isAvailable('harald')
   ↓
4a. If available:
    → Spawn Harald
    → Calculate ETA
    → Notify Glenn: "🚀 Harald started... (ETA 2 min)"
   
4b. If conflict:
    → Detect conflict: AgentManager.detectConflict('harald', task)
    → Generate options
    → Present to Glenn:
       "Harald is busy (ETA 8 min). Options:
        1. ⏱️ Wait 8 min
        2. 🔄 Route to Sonny (+$0.45)
        3. 🆕 Spawn 2nd Harald
        4. ⚠️ Abort current task"
    → Wait for Glenn's choice
   
5. Task executes
   ↓
6. Progress tracking (every 30 seconds):
   → ETACalculator.updateProgress(instanceId)
   → Update progress bar
   → Recalculate ETA at 50%
   ↓
7. Milestones reported (25%, 50%, 75%)
   ↓
8. Task completes
   → Record actual duration
   → Update historical data
   → Notify Glenn: "✅ Harald completed (2m 15s)"
   → Check queue for next task
   ↓
9. If queue has tasks:
   → Pop next task for Harald
   → Auto-start
   → Notify Glenn: "🚀 Queue: Starting next task..."
```

---

## Status Report Example

```
Glenn: "status"

Nikoline:
"📊 TEAM STATUS (Updated 5 seconds ago)

👑 NIKOLINE (Orchestrator)
   Status: 🟢 Online
   Handling: Your requests
   Uptime: 3 hours 42 minutes

⚡ HARALD (Speed Specialist - Haiku)
   Instance 1: 🔴 BUSY
      Task: Search for Python 3.12 release notes
      Started: 1 minute 32 seconds ago
      Progress: ████████░░ 76%
      ETA: 28 seconds
      
   Instance 2: 🟢 IDLE (ready)
   Instance 3: 🟢 IDLE (ready)
   
   Today: 12 tasks completed (avg 1m 45s each)
   Cost: $0.42

🧠 SONNY (Problem Solver - Sonnet)
   Instance 1: 🔴 BUSY
      Task: Debug API timeout in production
      Started: 6 minutes 18 seconds ago
      Progress: ████░░░░░░ 42%
      ETA: 8 minutes 12 seconds
      Last update: Analyzing database queries
      
   Instance 2: 🟡 QUEUED
      Next task: Analyze error logs (starts in 8 min)
   
   Today: 4 tasks completed (avg 12m 30s each)
   Cost: $7.20

🔧 CLAUDECODE (Builder - Max Plan)
   Status: 🟢 IDLE (ready)
   Last task: Refactor auth to JWT (completed 45 min ago)
   
   Today: 1 task completed (took 38 minutes)
   Cost: $0 (included in Max plan)

📋 TASK QUEUE: 2 tasks
   
   HIGH PRIORITY:
   #1. Fix login bug on mobile [Sonny]
       Queued: 3 minutes ago
       Will start: In ~8 minutes (when Sonny free)
       Est. duration: 15 minutes
   
   NORMAL:
   #2. Migrate database schema [ClaudeCode]
       Queued: 1 minute ago
       Will start: Immediately (ClaudeCode is free!)
       Est. duration: 45 minutes
       
   💡 Tip: Task #2 can start now! Want me to begin?

💰 COSTS TODAY: $7.62
   • Harald: $0.42 (12 tasks)
   • Sonny: $7.20 (4 tasks)
   • ClaudeCode: $0 (Max plan, 1 task)
   • Nikoline: $0 (orchestration included)
   
   Budget: $7.62 / $50 daily limit (15% used)

⚡ SYSTEM HEALTH
   • Uptime: 99.9%
   • Avg response: 1.2s
   • Queue wait: 8m avg
   • Task success: 96%"
```

---

## Configuration

### New Environment Variables

```bash
# Team configuration
HARALD_MAX_INSTANCES=3
SONNY_MAX_INSTANCES=2
CLAUDECODE_MAX_INSTANCES=1

# Queue settings
QUEUE_MODE=priority  # fifo, priority, or sjf
QUEUE_MAX_SIZE=20

# Notification preferences
AUTO_ROUTE_NOTIFY=true
PROGRESS_UPDATES=true
PROGRESS_INTERVAL=30000  # 30 seconds

# Cost limits
DAILY_COST_LIMIT=50
TASK_COST_WARN_THRESHOLD=5
```

---

## Testing New Features

### Test 1: Conflict Detection

```bash
# Start Harald on task 1
Glenn: "Harald, search for Python docs"
# Wait 30 seconds

# Try to use Harald again
Glenn: "Harald, search for Node docs"

Expected:
"Harald is busy searching Python docs (ETA 90 seconds).
 Options:
 1. Wait
 2. Route to Sonny
 3. Spawn 2nd Harald
 4. Abort"
```

### Test 2: Auto-Routing

```bash
# Occupy Harald
Glenn: "Harald, read all log files"
# Wait, then simple task

Glenn: "Search for React docs"

Expected:
"Harald is busy (ETA 5 min).
 ⚡ Auto-routing to Sonny for faster service..."
```

### Test 3: Queue System

```bash
# Occupy ClaudeCode
Glenn: "ClaudeCode, refactor auth"

# Queue another project
Glenn: "queue: Migrate to TypeScript"

Expected:
"📋 Added to queue: Migrate to TypeScript
 Position: #1
 Will start when: ClaudeCode finishes (ETA 35 min)"
```

---

## Summary of V2 Changes

### New Features
✅ Named agents (Harald, Sonny, ClaudeCode)  
✅ Conflict detection before spawn  
✅ 4-option conflict resolution  
✅ Automatic routing (Harald busy → Sonny)  
✅ Real-time status tracking with ETA  
✅ Progress bars and updates  
✅ Task queue (FIFO/priority/SJF)  
✅ Multi-instance support (3 Harald, 2 Sonny, 1 ClaudeCode)  
✅ "status" command for Glenn  
✅ Historical ETA learning  

### New Libraries
- `lib/agent-manager.js` - Availability, conflicts, options
- `lib/queue-manager.js` - Queue management
- `lib/eta-calculator.js` - ETA estimation and tracking

### Updated Libraries
- `lib/delegator.js` - Add conflict checking
- `lib/notifier.js` - Add progress updates
- `lib/orchestration-state.js` - Add instance tracking
- `HEARTBEAT.md` - Add progress polling

---

**Status: ✅ V2 Design Complete - Ready for Review**
