# Orchestration System - Implementation Roadmap

**Timeline:** 3 weeks from design to production  
**Phases:** Foundation → Integration → Testing → Deployment

---

## Week 1: Foundation (Days 1-7)

### Day 1: Project Setup

**Goal:** Create project structure and dependencies

#### Tasks:
1. Create directory structure
2. Initialize package files
3. Set up environment variables

#### Commands:
```bash
# Create directories
mkdir -p lib
mkdir -p tests
mkdir -p memory
mkdir -p tasks

# Initialize (if needed)
npm init -y
npm install uuid  # For generating session IDs

# Create environment file
cat > .env << EOF
GLENN_CHAT_ID=your-telegram-id-here
CLAUDE_CODE_PATH=/usr/local/bin/claude
NODE_ENV=development
EOF
```

#### Files Created:
- `lib/` (empty, ready for code)
- `tests/` (empty, ready for tests)
- `.env` (environment config)

**Time:** 1 hour  
**Status:** Ready to code

---

### Day 2-3: Core Libraries (Part 1)

**Goal:** Build state management and classification

#### Task 1: State Management

**File:** `lib/orchestration-state.js`

```javascript
const fs = require('fs');
const path = require('path');

const STATE_FILE = path.join(process.cwd(), 'orchestration-state.json');

class OrchestrationState {
  constructor() {
    this.state = this.load();
  }
  
  load() {
    if (fs.existsSync(STATE_FILE)) {
      try {
        const data = fs.readFileSync(STATE_FILE, 'utf8');
        return JSON.parse(data);
      } catch (error) {
        console.error('State file corrupted, creating backup and resetting');
        fs.copyFileSync(STATE_FILE, STATE_FILE + '.backup');
        return this.getDefaultState();
      }
    }
    return this.getDefaultState();
  }
  
  getDefaultState() {
    return {
      subAgents: {},
      claudeCode: {
        active: false,
        sessionId: null,
        task: null,
        startTime: null,
        lastCheck: null,
        lastReadOffset: 0
      },
      glennActiveChannel: "telegram",
      lastTaskId: 0
    };
  }
  
  save() {
    try {
      fs.writeFileSync(STATE_FILE, JSON.stringify(this.state, null, 2));
    } catch (error) {
      console.error('Failed to save state:', error);
    }
  }
  
  addSubAgent(sessionId, task, model) {
    this.state.subAgents[sessionId] = {
      task,
      model,
      status: "running",
      startTime: Date.now()
    };
    this.state.lastTaskId++;
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
  
  failSubAgent(sessionId, error) {
    if (this.state.subAgents[sessionId]) {
      this.state.subAgents[sessionId].status = "failed";
      this.state.subAgents[sessionId].error = error;
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
  
  clearClaudeCode() {
    this.state.claudeCode = {
      active: false,
      sessionId: null,
      task: null,
      startTime: null,
      lastCheck: null,
      lastReadOffset: 0
    };
    this.save();
  }
  
  updateClaudeCodeCheck(newOffset) {
    if (this.state.claudeCode.active) {
      this.state.claudeCode.lastCheck = Date.now();
      this.state.claudeCode.lastReadOffset = newOffset;
      this.save();
    }
  }
  
  getActiveSubAgents() {
    return Object.entries(this.state.subAgents)
      .filter(([_, agent]) => agent.status === "running")
      .map(([id, agent]) => ({ id, ...agent }));
  }
  
  cleanOldTasks(maxAgeMs = 24 * 60 * 60 * 1000) {
    // Remove completed/failed tasks older than maxAge
    const now = Date.now();
    Object.entries(this.state.subAgents).forEach(([id, agent]) => {
      if (agent.completedAt && (now - agent.completedAt) > maxAgeMs) {
        delete this.state.subAgents[id];
      }
    });
    this.save();
  }
}

module.exports = new OrchestrationState();
```

**Test it:**
```javascript
// tests/test-state.js
const state = require('../lib/orchestration-state');

console.log('Initial state:', state.state);

state.addSubAgent('test-123', 'Test task', 'haiku');
console.log('After adding sub-agent:', state.state);

state.completeSubAgent('test-123', 'Task completed successfully');
console.log('After completion:', state.state);

state.setClaudeCodeActive('cc-456', 'Test Claude Code task');
console.log('After Claude Code start:', state.state);

state.clearClaudeCode();
console.log('After Claude Code clear:', state.state);
```

Run: `node tests/test-state.js`

**Time:** 4 hours  
**Checkpoint:** State management working

---

#### Task 2: Task Classifier

**File:** `lib/task-classifier.js`

```javascript
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
  const length = taskDescription.length;
  
  // Trivial - handle directly
  if (
    length < 20 ||
    /^(hi|hello|hey|yo|sup)\b/i.test(lower) ||
    /^what'?s up/i.test(lower) ||
    /\b(status|time|date|weather)\b/.test(lower)
  ) {
    return { 
      complexity: COMPLEXITY.TRIVIAL, 
      model: MODEL.SELF,
      reason: "Quick answer, no tools needed"
    };
  }
  
  // Project - Claude Code
  const projectKeywords = [
    'refactor', 'migrate', 'build system', 'entire project',
    'codebase', 'implement feature', 'implement system',
    'implement api', 'build api', 'build feature',
    'convert to', 'add typescript', 'add tests to all'
  ];
  
  if (projectKeywords.some(kw => lower.includes(kw))) {
    return { 
      complexity: COMPLEXITY.PROJECT, 
      model: MODEL.CLAUDE_CODE,
      reason: "Multi-file project, needs Claude Code"
    };
  }
  
  // Check for explicit file counts
  if (/\b(\d+)\s+files?\b/.test(lower)) {
    const match = lower.match(/\b(\d+)\s+files?\b/);
    const fileCount = parseInt(match[1]);
    if (fileCount >= 3) {
      return { 
        complexity: COMPLEXITY.PROJECT, 
        model: MODEL.CLAUDE_CODE,
        reason: `${fileCount} files - multi-file project`
      };
    }
  }
  
  // Complex - Sonnet
  const complexKeywords = [
    'debug', 'why', 'design', 'analyze', 'research',
    'compare', 'write code', 'write script', 'create script',
    'fix bug', 'investigate', 'figure out'
  ];
  
  if (complexKeywords.some(kw => lower.includes(kw))) {
    return { 
      complexity: COMPLEXITY.COMPLEX, 
      model: MODEL.SONNET,
      reason: "Requires reasoning/analysis"
    };
  }
  
  // Simple - Haiku
  const simpleKeywords = [
    'read', 'search', 'find', 'list', 'extract',
    'summarize', 'check if', 'get', 'fetch', 'look up'
  ];
  
  if (simpleKeywords.some(kw => lower.includes(kw))) {
    return { 
      complexity: COMPLEXITY.SIMPLE, 
      model: MODEL.HAIKU,
      reason: "Simple data task"
    };
  }
  
  // Default: Complex (Sonnet) - better to over-provision than under
  return { 
    complexity: COMPLEXITY.COMPLEX, 
    model: MODEL.SONNET,
    reason: "Default - unclear complexity"
  };
}

function selectModel(complexity, overrideModel = null) {
  if (overrideModel) {
    return MODEL[overrideModel.toUpperCase()] || MODEL.SONNET;
  }
  
  switch (complexity) {
    case COMPLEXITY.TRIVIAL:
      return MODEL.SELF;
    case COMPLEXITY.SIMPLE:
      return MODEL.HAIKU;
    case COMPLEXITY.COMPLEX:
      return MODEL.SONNET;
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

**Test it:**
```javascript
// tests/test-classifier.js
const { classifyTask } = require('../lib/task-classifier');

const testCases = [
  "Hi there!",
  "What's the weather?",
  "Search for Node.js documentation",
  "Read config.json and extract the API key",
  "Debug why the API is returning 500 errors",
  "Design a database schema for a blog",
  "Refactor the entire auth system to use OAuth",
  "Build a REST API for the blog with CRUD operations",
  "Write a script to process log files"
];

console.log("Classification Tests:\n");
testCases.forEach(test => {
  const result = classifyTask(test);
  console.log(`"${test}"`);
  console.log(`  → ${result.complexity} (${result.model})`);
  console.log(`  → Reason: ${result.reason}\n`);
});
```

Run: `node tests/test-classifier.js`

**Expected Output:**
```
"Hi there!"
  → trivial (self)
  → Reason: Quick answer, no tools needed

"What's the weather?"
  → trivial (self)
  → Reason: Quick answer, no tools needed

"Search for Node.js documentation"
  → simple (haiku)
  → Reason: Simple data task

"Read config.json and extract the API key"
  → simple (haiku)
  → Reason: Simple data task

"Debug why the API is returning 500 errors"
  → complex (sonnet)
  → Reason: Requires reasoning/analysis

"Design a database schema for a blog"
  → complex (sonnet)
  → Reason: Requires reasoning/analysis

"Refactor the entire auth system to use OAuth"
  → project (claude-code)
  → Reason: Multi-file project, needs Claude Code

"Build a REST API for the blog with CRUD operations"
  → project (claude-code)
  → Reason: Multi-file project, needs Claude Code

"Write a script to process log files"
  → complex (sonnet)
  → Reason: Requires reasoning/analysis
```

**Time:** 3 hours  
**Checkpoint:** Classification working accurately

---

### Day 4-5: Core Libraries (Part 2)

**Goal:** Build delegation and notification systems

#### Task 1: Notifier

**File:** `lib/notifier.js`

```javascript
// NOTE: This is a template. You'll need to integrate with OpenClaw's message tool
// For now, this logs to console. Nikoline will replace with actual message() calls.

const state = require('./orchestration-state');

const LEVELS = {
  URGENT: { 
    silent: false, 
    priority: "high",
    emoji: "🚨"
  },
  IMPORTANT: { 
    silent: false, 
    priority: "normal",
    emoji: "✅"
  },
  INFO: { 
    silent: true, 
    priority: "low",
    emoji: "📊"
  },
  START: {
    silent: false,
    priority: "normal",
    emoji: "🚀"
  },
  PROGRESS: {
    silent: true,
    priority: "low",
    emoji: "🔧"
  }
};

async function notifyGlenn(text, level = LEVELS.INFO) {
  const channel = state.state.glennActiveChannel || "telegram";
  const glennChatId = process.env.GLENN_CHAT_ID;
  
  if (!glennChatId) {
    console.warn("GLENN_CHAT_ID not set, logging to console instead");
    console.log(`[${level.emoji} ${level.priority}] ${text}`);
    return;
  }
  
  // This is where Nikoline will integrate with OpenClaw's message tool
  // For now, console log
  console.log(`[NOTIFY ${channel}] ${level.emoji} ${text}`);
  
  // TODO: Replace with actual message() call:
  // await message({
  //   action: "send",
  //   target: glennChatId,
  //   message: `${level.emoji} ${text}`,
  //   silent: level.silent
  // });
}

async function reportTaskStart(task, model) {
  const shortTask = task.substring(0, 60) + (task.length > 60 ? "..." : "");
  await notifyGlenn(
    `Starting task: ${shortTask} (${model})`,
    LEVELS.START
  );
}

async function reportProgress(taskId, milestone) {
  const task = state.state.subAgents[taskId];
  if (!task) return;
  
  await notifyGlenn(
    `${task.task}: ${milestone}`,
    LEVELS.PROGRESS
  );
}

async function reportCompletion(taskId, summary) {
  const task = state.state.subAgents[taskId];
  if (!task) return;
  
  const duration = Math.round((Date.now() - task.startTime) / 1000);
  const minutes = Math.floor(duration / 60);
  const seconds = duration % 60;
  const timeStr = minutes > 0 ? `${minutes}m ${seconds}s` : `${seconds}s`;
  
  await notifyGlenn(
    `Completed: ${task.task}\n⏱️ Duration: ${timeStr}\n📝 ${summary}`,
    LEVELS.IMPORTANT
  );
}

async function reportError(taskId, error) {
  const task = state.state.subAgents[taskId];
  const taskDesc = task ? task.task : taskId;
  
  await notifyGlenn(
    `Error in task: ${taskDesc}\n❌ ${error}`,
    LEVELS.URGENT
  );
}

module.exports = {
  notifyGlenn,
  reportTaskStart,
  reportProgress,
  reportCompletion,
  reportError,
  LEVELS
};
```

**Test it:**
```javascript
// tests/test-notifier.js
const { notifyGlenn, reportTaskStart, LEVELS } = require('../lib/notifier');

(async () => {
  await notifyGlenn("Test notification - info", LEVELS.INFO);
  await notifyGlenn("Test notification - important", LEVELS.IMPORTANT);
  await notifyGlenn("Test notification - urgent", LEVELS.URGENT);
  await reportTaskStart("Test task description", "haiku");
})();
```

Run: `node tests/test-notifier.js`

**Time:** 2 hours  
**Checkpoint:** Notifications working (console for now)

---

#### Task 2: Delegator (Simplified for Testing)

**File:** `lib/delegator.js`

```javascript
const { v4: uuidv4 } = require('uuid');
const state = require('./orchestration-state');
const { classifyTask, MODEL } = require('./task-classifier');
const { notifyGlenn, reportTaskStart, LEVELS } = require('./notifier');

async function delegateTask(taskDescription, overrideModel = null) {
  const classification = classifyTask(taskDescription);
  const model = overrideModel || classification.model;
  
  if (model === MODEL.SELF) {
    // Don't delegate, handle in current session
    return { 
      delegated: false, 
      reason: "Task is trivial, handling directly" 
    };
  }
  
  if (model === MODEL.CLAUDE_CODE) {
    return await spawnClaudeCode(taskDescription);
  }
  
  // Spawn sub-agent
  return await spawnSubAgent(taskDescription, model);
}

async function spawnSubAgent(task, model) {
  const sessionId = `subagent-${Date.now()}-${uuidv4().substring(0, 8)}`;
  const label = task.substring(0, 50);
  
  // Report to Glenn
  await reportTaskStart(task, model);
  
  // Track in state
  state.addSubAgent(sessionId, task, model);
  
  // TODO: This is where Nikoline will spawn actual sub-agent via OpenClaw
  // For now, simulate
  console.log(`[SPAWN SUB-AGENT] ${model} - ${label}`);
  console.log(`  Session ID: ${sessionId}`);
  console.log(`  Command: openclaw agent spawn --label "${label}" --model anthropic/claude-${model} --task "${task}"`);
  
  // Simulate completion after 5 seconds (for testing)
  if (process.env.NODE_ENV === 'development') {
    setTimeout(() => {
      simulateCompletion(sessionId, `Mock result for: ${task}`);
    }, 5000);
  }
  
  return {
    delegated: true,
    sessionId,
    model,
    task
  };
}

async function spawnClaudeCode(task) {
  const sessionId = `claude-code-${Date.now()}`;
  
  await notifyGlenn(
    `Starting Claude Code session: ${task}`,
    LEVELS.START
  );
  
  // Track in state
  state.setClaudeCodeActive(sessionId, task);
  
  // TODO: This is where Nikoline will spawn actual Claude Code via PTY
  console.log(`[SPAWN CLAUDE CODE] ${task}`);
  console.log(`  Session ID: ${sessionId}`);
  console.log(`  Command: claude-code --instructions "<task>" --non-interactive`);
  
  await notifyGlenn(
    `⚙️ Claude Code is working. I'll monitor progress and update you.`,
    LEVELS.INFO
  );
  
  return {
    delegated: true,
    sessionId,
    model: MODEL.CLAUDE_CODE,
    task
  };
}

// Test helper - simulate completion
function simulateCompletion(sessionId, result) {
  const task = state.state.subAgents[sessionId];
  if (!task) return;
  
  state.completeSubAgent(sessionId, result);
  
  const { reportCompletion } = require('./notifier');
  reportCompletion(sessionId, result);
}

module.exports = {
  delegateTask,
  spawnSubAgent,
  spawnClaudeCode
};
```

**Test it:**
```javascript
// tests/test-delegator.js
const { delegateTask } = require('../lib/delegator');

(async () => {
  console.log("=== Test 1: Trivial task ===");
  let result = await delegateTask("Hi there");
  console.log("Result:", result);
  
  console.log("\n=== Test 2: Simple task ===");
  result = await delegateTask("Search for Node.js LTS version");
  console.log("Result:", result);
  
  console.log("\n=== Test 3: Complex task ===");
  result = await delegateTask("Debug why the API is failing");
  console.log("Result:", result);
  
  console.log("\n=== Test 4: Project task ===");
  result = await delegateTask("Refactor the auth system");
  console.log("Result:", result);
  
  // Wait for simulated completions
  console.log("\nWaiting for simulated completions...");
  setTimeout(() => {
    console.log("\nTests complete!");
    process.exit(0);
  }, 6000);
})();
```

Run: `NODE_ENV=development node tests/test-delegator.js`

**Time:** 3 hours  
**Checkpoint:** Delegation logic working (mock spawns)

---

### Day 6-7: Integration & Testing

**Goal:** Integrate all components and test end-to-end

#### Integration Test

**File:** `tests/integration-test.js`

```javascript
const { delegateTask } = require('../lib/delegator');
const state = require('../lib/orchestration-state');
const { classifyTask } = require('../lib/task-classifier');

async function runIntegrationTests() {
  console.log("🧪 Running Integration Tests\n");
  console.log("=" ."=".repeat(60) + "\n");
  
  // Test 1: Classification
  console.log("Test 1: Classification");
  const tests = [
    "Hi",
    "Read file.txt",
    "Debug API issue",
    "Build REST API"
  ];
  
  tests.forEach(test => {
    const result = classifyTask(test);
    console.log(`  ✓ "${test}" → ${result.model}`);
  });
  
  // Test 2: State Management
  console.log("\nTest 2: State Management");
  const initialState = JSON.parse(JSON.stringify(state.state));
  state.addSubAgent("test-123", "Test task", "haiku");
  console.log("  ✓ Sub-agent added");
  state.completeSubAgent("test-123", "Done");
  console.log("  ✓ Sub-agent completed");
  state.setClaudeCodeActive("cc-456", "Test CC");
  console.log("  ✓ Claude Code activated");
  state.clearClaudeCode();
  console.log("  ✓ Claude Code cleared");
  
  // Test 3: Delegation
  console.log("\nTest 3: Delegation");
  const simple = await delegateTask("Search for docs");
  console.log(`  ✓ Simple task delegated to ${simple.model}`);
  
  const complex = await delegateTask("Debug issue");
  console.log(`  ✓ Complex task delegated to ${complex.model}`);
  
  // Test 4: Active Tasks
  console.log("\nTest 4: Active Tasks");
  const active = state.getActiveSubAgents();
  console.log(`  ✓ Found ${active.length} active sub-agents`);
  
  console.log("\n" + "=".repeat(60));
  console.log("✅ All integration tests passed!\n");
  
  // Wait for simulated completions
  setTimeout(() => {
    console.log("Final state:");
    console.log(JSON.stringify(state.state, null, 2));
    process.exit(0);
  }, 6000);
}

runIntegrationTests().catch(error => {
  console.error("❌ Integration test failed:", error);
  process.exit(1);
});
```

Run: `NODE_ENV=development node tests/integration-test.js`

**Time:** 4 hours (includes fixing any issues found)  
**Checkpoint:** All core components working together

---

## Week 2: Claude Code Integration (Days 8-14)

### Day 8-9: Claude Code Monitor

**Goal:** Build monitoring system for Claude Code sessions

**File:** `lib/claude-code-monitor.js`

```javascript
const fs = require('fs');
const path = require('path');
const state = require('./orchestration-state');
const { notifyGlenn, LEVELS } = require('./notifier');

class ClaudeCodeMonitor {
  constructor() {
    this.checkInterval = 5 * 60 * 1000; // 5 minutes
  }
  
  async check() {
    const cc = state.state.claudeCode;
    
    if (!cc.active) {
      return { active: false };
    }
    
    try {
      // TODO: Replace with actual process.log() call
      // For now, simulate by reading a test log file
      const logs = await this.readLogs(cc.sessionId, cc.lastReadOffset);
      
      if (!logs || logs.length === 0) {
        return { active: true, newLogs: 0 };
      }
      
      // Update offset
      const newOffset = cc.lastReadOffset + logs.length;
      state.updateClaudeCodeCheck(newOffset);
      
      // Parse logs
      const milestones = this.extractMilestones(logs);
      const errors = this.extractErrors(logs);
      const isComplete = this.isComplete(logs);
      
      // Report milestones
      if (milestones.length > 0) {
        await notifyGlenn(
          `Claude Code progress:\n${milestones.join('\n')}`,
          LEVELS.PROGRESS
        );
      }
      
      // Report errors
      if (errors.length > 0) {
        await notifyGlenn(
          `⚠️ Claude Code warnings:\n${errors.join('\n')}`,
          LEVELS.URGENT
        );
      }
      
      // Handle completion
      if (isComplete) {
        await this.handleCompletion(logs);
      }
      
      return {
        active: !isComplete,
        newLogs: logs.length,
        milestones: milestones.length,
        errors: errors.length
      };
      
    } catch (error) {
      console.error("Error monitoring Claude Code:", error);
      return { active: true, error: error.message };
    }
  }
  
  async readLogs(sessionId, offset) {
    // TODO: Replace with actual process({ action: "log", sessionId, offset })
    // For testing, simulate
    if (process.env.NODE_ENV === 'development') {
      return [
        "Starting Claude Code session...",
        "Analyzing codebase...",
        "✅ Created auth/jwt.js",
        "✅ Modified auth/middleware.js",
        "Working on tests...",
        "✅ All tests passing",
        "Session complete."
      ].slice(offset);
    }
    
    return [];
  }
  
  extractMilestones(logs) {
    const milestones = [];
    const logText = logs.join('\n');
    
    // Patterns for milestones
    const patterns = [
      /✅[^\n]+/g,
      /Completed:[^\n]+/g,
      /Created [^\n]+/g,
      /Modified [^\n]+/g,
      /Tests passing/g,
      /\d+ files? (created|modified|updated)/g
    ];
    
    patterns.forEach(pattern => {
      const matches = logText.match(pattern);
      if (matches) {
        milestones.push(...matches.map(m => m.trim()));
      }
    });
    
    // Deduplicate and limit
    return [...new Set(milestones)].slice(0, 5);
  }
  
  extractErrors(logs) {
    const errors = [];
    const logText = logs.join('\n');
    
    const errorPatterns = [
      /Error:[^\n]+/g,
      /Failed:[^\n]+/g,
      /❌[^\n]+/g,
      /Exception:[^\n]+/g
    ];
    
    errorPatterns.forEach(pattern => {
      const matches = logText.match(pattern);
      if (matches) {
        errors.push(...matches.map(m => m.trim()));
      }
    });
    
    return [...new Set(errors)].slice(0, 3);
  }
  
  isComplete(logs) {
    const logText = logs.join('\n').toLowerCase();
    return (
      logText.includes('session complete') ||
      logText.includes('all tasks finished') ||
      logText.includes('exiting') ||
      logText.includes('done!')
    );
  }
  
  async handleCompletion(logs) {
    const cc = state.state.claudeCode;
    
    // Archive logs
    const logFile = path.join('memory', `claude-code-${Date.now()}.log`);
    fs.writeFileSync(logFile, logs.join('\n'));
    
    // Parse summary
    const summary = this.parseSummary(logs);
    
    // Notify Glenn
    await notifyGlenn(
      `Claude Code completed: ${cc.task}\n\n${summary}\n\nFull logs: ${logFile}`,
      LEVELS.IMPORTANT
    );
    
    // Clear state
    state.clearClaudeCode();
  }
  
  parseSummary(logs) {
    const logText = logs.join('\n');
    
    // Extract metrics
    const filesMatch = logText.match(/(\d+) files? (modified|created|updated)/);
    const linesMatch = logText.match(/(\d+) lines? added/);
    const testsMatch = logText.match(/tests:?\s*(passing|failing|pass|fail)/i);
    
    const parts = [];
    
    if (filesMatch) {
      parts.push(`Files ${filesMatch[2]}: ${filesMatch[1]}`);
    }
    
    if (linesMatch) {
      parts.push(`Lines added: ${linesMatch[1]}`);
    }
    
    if (testsMatch) {
      const status = testsMatch[1].toLowerCase().includes('pass') ? '✅ passing' : '❌ failing';
      parts.push(`Tests: ${status}`);
    }
    
    return parts.length > 0 ? parts.join('\n') : 'Completed successfully';
  }
}

module.exports = new ClaudeCodeMonitor();
```

**Test it:**
```javascript
// tests/test-claude-monitor.js
const monitor = require('../lib/claude-code-monitor');
const state = require('../lib/orchestration-state');

(async () => {
  // Set up test state
  state.setClaudeCodeActive("test-cc-123", "Test refactoring");
  
  console.log("Initial check (will read all logs):");
  let result = await monitor.check();
  console.log(result);
  
  setTimeout(async () => {
    console.log("\nSecond check (should detect completion):");
    result = await monitor.check();
    console.log(result);
    
    console.log("\nFinal state:");
    console.log(state.state.claudeCode);
  }, 2000);
})();
```

Run: `NODE_ENV=development node tests/test-claude-monitor.js`

**Time:** 6 hours  
**Checkpoint:** Claude Code monitoring working

---

### Day 10-11: Heartbeat Integration

**Goal:** Integrate monitoring into heartbeat system

**File:** Update `HEARTBEAT.md`

```markdown
# HEARTBEAT.md - Proactive Tasks

Read this file on every heartbeat poll.

## Every Heartbeat (~30 min)

### 1. Check Claude Code Progress

```javascript
const state = require('./lib/orchestration-state');
const monitor = require('./lib/claude-code-monitor');

if (state.state.claudeCode.active) {
  await monitor.check();
}
```

### 2. Check Sub-Agent Status

```javascript
const active = state.getActiveSubAgents();

// Alert if any task running > 30 min
active.forEach(agent => {
  const elapsed = Date.now() - agent.startTime;
  const minutes = Math.round(elapsed / 60000);
  
  if (minutes > 30) {
    notifyGlenn(`⚠️ Long-running task: ${agent.task} (${minutes} min)`, LEVELS.INFO);
  }
});
```

### 3. Clean Old Tasks

```javascript
// Once per day
const now = new Date();
if (now.getHours() === 3 && now.getMinutes() < 30) {
  state.cleanOldTasks(24 * 60 * 60 * 1000); // Remove tasks > 24h old
}
```

### 4. Regular Heartbeat Tasks

- Check Glenn's calendar (next 2 hours)
- Check important emails (2-3 times per day)
- Weather (if relevant)

## State Files

- `orchestration-state.json` - Current tasks and sessions
- `memory/heartbeat-state.json` - Last check timestamps

## Notes

- Don't interrupt Claude Code sessions
- Use process.log() for monitoring (read-only)
- Report milestones, not every log line
```

**File:** Create heartbeat handler

`lib/heartbeat-handler.js`

```javascript
const state = require('./orchestration-state');
const claudeCodeMonitor = require('./claude-code-monitor');
const { notifyGlenn, LEVELS } = require('./notifier');
const fs = require('fs');
const path = require('path');

const HEARTBEAT_STATE_FILE = path.join('memory', 'heartbeat-state.json');

class HeartbeatHandler {
  constructor() {
    this.lastState = this.loadState();
  }
  
  loadState() {
    if (fs.existsSync(HEARTBEAT_STATE_FILE)) {
      return JSON.parse(fs.readFileSync(HEARTBEAT_STATE_FILE, 'utf8'));
    }
    return {
      lastChecks: {
        claudeCode: null,
        subAgents: null,
        cleanup: null
      }
    };
  }
  
  saveState() {
    fs.writeFileSync(HEARTBEAT_STATE_FILE, JSON.stringify(this.lastState, null, 2));
  }
  
  async handleHeartbeat() {
    const now = Date.now();
    const tasks = [];
    
    // 1. Claude Code monitoring
    if (state.state.claudeCode.active) {
      tasks.push(this.checkClaudeCode());
    }
    
    // 2. Sub-agent status
    tasks.push(this.checkSubAgents());
    
    // 3. Cleanup (once per day)
    const hoursSinceCleanup = this.lastState.lastChecks.cleanup 
      ? (now - this.lastState.lastChecks.cleanup) / (60 * 60 * 1000)
      : 99;
    
    if (hoursSinceCleanup > 24) {
      tasks.push(this.cleanup());
    }
    
    // Run all tasks
    await Promise.all(tasks);
    
    // Save state
    this.saveState();
    
    return "HEARTBEAT_OK";
  }
  
  async checkClaudeCode() {
    this.lastState.lastChecks.claudeCode = Date.now();
    await claudeCodeMonitor.check();
  }
  
  async checkSubAgents() {
    this.lastState.lastChecks.subAgents = Date.now();
    
    const active = state.getActiveSubAgents();
    
    active.forEach(agent => {
      const elapsed = Date.now() - agent.startTime;
      const minutes = Math.round(elapsed / 60000);
      
      if (minutes > 30 && minutes % 10 === 0) {
        // Report every 10 min after 30 min
        notifyGlenn(
          `Long-running task: ${agent.task} (${minutes} min)`,
          LEVELS.INFO
        );
      }
    });
  }
  
  async cleanup() {
    this.lastState.lastChecks.cleanup = Date.now();
    
    // Clean tasks older than 24h
    state.cleanOldTasks(24 * 60 * 60 * 1000);
    
    console.log("Heartbeat: Cleaned old tasks");
  }
}

module.exports = new HeartbeatHandler();
```

**Test it:**
```javascript
// tests/test-heartbeat.js
const heartbeat = require('../lib/heartbeat-handler');

(async () => {
  console.log("Running heartbeat handler...");
  const result = await heartbeat.handleHeartbeat();
  console.log("Result:", result);
})();
```

**Time:** 4 hours  
**Checkpoint:** Heartbeat integration complete

---

### Day 12-14: Real Integration with OpenClaw

**Goal:** Replace mock functions with real OpenClaw tool calls

#### Update Delegator with Real Spawning

```javascript
// lib/delegator.js - Update spawnSubAgent()

async function spawnSubAgent(task, model) {
  const sessionId = `subagent-${Date.now()}-${uuidv4().substring(0, 8)}`;
  const label = task.substring(0, 50);
  
  // Report to Glenn
  await reportTaskStart(task, model);
  
  // Track in state
  state.addSubAgent(sessionId, task, model);
  
  // REAL OPENCLAW SPAWN (replace mock):
  try {
    // Note: exec is available via OpenClaw tools in actual agent session
    // This assumes exec function is imported from openclaw-tools
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
    
    console.log(`Spawned sub-agent: ${result.sessionId}`);
    
    return {
      delegated: true,
      sessionId: result.sessionId,
      model,
      task
    };
    
  } catch (error) {
    console.error(`Failed to spawn sub-agent:`, error);
    state.failSubAgent(sessionId, error.message);
    throw error;
  }
}
```

#### Update Claude Code Spawning

```javascript
// lib/delegator.js - Update spawnClaudeCode()

async function spawnClaudeCode(task) {
  const sessionId = `claude-code-${Date.now()}`;
  
  await notifyGlenn(
    `Starting Claude Code session: ${task}`,
    LEVELS.START
  );
  
  // Track in state
  state.setClaudeCodeActive(sessionId, task);
  
  // Create instruction file
  const instructionFile = path.join('/tmp', `claude-instructions-${Date.now()}.txt`);
  fs.writeFileSync(instructionFile, task);
  
  try {
    // REAL OPENCLAW PTY SPAWN:
    const result = await exec({
      command: process.env.CLAUDE_CODE_PATH || "claude",
      args: ["--instructions", instructionFile, "--non-interactive"],
      pty: true,
      background: true,
      yieldMs: 2000,
      workdir: process.cwd()
    });
    
    console.log(`Spawned Claude Code: ${result.sessionId}`);
    
    await notifyGlenn(
      `⚙️ Claude Code is working. I'll monitor progress and update you.`,
      LEVELS.INFO
    );
    
    return {
      delegated: true,
      sessionId: result.sessionId,
      model: MODEL.CLAUDE_CODE,
      task
    };
    
  } catch (error) {
    console.error(`Failed to spawn Claude Code:`, error);
    state.clearClaudeCode();
    throw error;
  }
}
```

#### Update Monitor with Real Logs

```javascript
// lib/claude-code-monitor.js - Update readLogs()

async function readLogs(sessionId, offset) {
  try {
    // REAL OPENCLAW PROCESS LOG:
    const result = await process({
      action: "log",
      sessionId: sessionId,
      offset: offset || 0,
      limit: 1000
    });
    
    return result.split('\n').filter(line => line.trim());
    
  } catch (error) {
    console.error(`Failed to read logs for ${sessionId}:`, error);
    return [];
  }
}
```

#### Update Notifier with Real Messages

```javascript
// lib/notifier.js - Update notifyGlenn()

async function notifyGlenn(text, level = LEVELS.INFO) {
  const channel = state.state.glennActiveChannel || "telegram";
  const glennChatId = process.env.GLENN_CHAT_ID;
  
  if (!glennChatId) {
    console.warn("GLENN_CHAT_ID not set");
    return;
  }
  
  try {
    // REAL OPENCLAW MESSAGE:
    await message({
      action: "send",
      target: glennChatId,
      message: `${level.emoji} ${text}`,
      silent: level.silent
    });
    
  } catch (error) {
    console.error(`Failed to notify Glenn:`, error);
  }
}
```

**Time:** 6 hours (including testing with real OpenClaw)  
**Checkpoint:** Fully integrated with OpenClaw

---

## Week 3: Testing & Deployment (Days 15-21)

### Day 15-16: End-to-End Testing

**Create comprehensive test plan:**

**File:** `tests/e2e-test-plan.md`

```markdown
# End-to-End Test Plan

## Phase 1: Simple Tasks (Day 15)

1. **Test:** "Search for Node.js LTS version"
   - Expected: Haiku sub-agent spawned
   - Verify: Notification sent, task tracked, completion reported

2. **Test:** "Read package.json and show dependencies"
   - Expected: Haiku sub-agent
   - Verify: File read correctly, results returned

3. **Test:** "Summarize README.md"
   - Expected: Haiku sub-agent
   - Verify: Summary accurate

## Phase 2: Complex Tasks (Day 15-16)

4. **Test:** "Debug why npm install fails"
   - Expected: Sonnet sub-agent
   - Verify: Error analysis provided

5. **Test:** "Design a REST API for a todo app"
   - Expected: Sonnet sub-agent
   - Verify: Schema and endpoints designed

## Phase 3: Claude Code (Day 16)

6. **Test:** "Create a simple Express API with 3 routes"
   - Expected: Claude Code spawned
   - Verify: Files created, monitoring works, completion detected

## Phase 4: Parallel Work (Day 16)

7. **Test:** Start Claude Code task, then ask "What's the weather?"
   - Expected: Weather response immediate, Claude Code unaffected

8. **Test:** Start 2 Haiku tasks in parallel
   - Expected: Both run simultaneously

## Phase 5: Monitoring (Day 16)

9. **Test:** While Claude Code runs, ask "How's it going?"
   - Expected: Status report with current progress

10. **Test:** Heartbeat triggers during Claude Code session
    - Expected: Progress milestones reported

## Success Criteria

- [ ] All 10 tests pass
- [ ] No interruptions to Claude Code
- [ ] Notifications arrive correctly
- [ ] State persists across restarts
- [ ] Costs tracked accurately
```

**Run tests manually, document results.**

**Time:** 8 hours  
**Checkpoint:** All tests passing

---

### Day 17-18: Performance & Cost Optimization

**Tasks:**
1. Review logs from test runs
2. Identify any unnecessary API calls
3. Optimize token usage
4. Test caching effectiveness
5. Document actual costs vs estimates

**Create cost tracking:**

**File:** `lib/cost-tracker.js`

```javascript
const fs = require('fs');
const path = require('path');

const COST_FILE = path.join('memory', 'costs.json');

const PRICES = {
  haiku: {
    input: 1.25 / 1000000,   // per token
    output: 6.25 / 1000000
  },
  sonnet: {
    input: 15 / 1000000,
    output: 75 / 1000000
  },
  opus: {
    input: 75 / 1000000,
    output: 375 / 1000000
  }
};

class CostTracker {
  constructor() {
    this.costs = this.load();
  }
  
  load() {
    if (fs.existsSync(COST_FILE)) {
      return JSON.parse(fs.readFileSync(COST_FILE, 'utf8'));
    }
    return {
      daily: {},
      total: 0
    };
  }
  
  save() {
    fs.writeFileSync(COST_FILE, JSON.stringify(this.costs, null, 2));
  }
  
  track(model, inputTokens, outputTokens) {
    const cost = 
      (inputTokens * PRICES[model].input) +
      (outputTokens * PRICES[model].output);
    
    const today = new Date().toISOString().split('T')[0];
    
    if (!this.costs.daily[today]) {
      this.costs.daily[today] = 0;
    }
    
    this.costs.daily[today] += cost;
    this.costs.total += cost;
    
    this.save();
    
    return cost;
  }
  
  getToday() {
    const today = new Date().toISOString().split('T')[0];
    return this.costs.daily[today] || 0;
  }
  
  getTotal() {
    return this.costs.total;
  }
}

module.exports = new CostTracker();
```

**Time:** 6 hours  
**Checkpoint:** Costs optimized and tracked

---

### Day 19-20: Documentation & Training

**Tasks:**
1. Review all documentation
2. Create quick-start guide
3. Record demo video (optional)
4. Train Glenn on new system

**File:** `QUICKSTART.md`

```markdown
# Orchestration System - Quick Start

## For Glenn

Just use Nikoline like normal. That's it.

```
You: "Build a REST API"
Nikoline: 🔧 Starting Claude Code...
[later]
Nikoline: ✅ Complete!
```

## For Nikoline

On every message from Glenn:

1. Read the message
2. Call: `const { delegateTask } = require('./lib/delegator')`
3. Call: `await delegateTask(glennMessage)`
4. Continue listening (don't block)

On every heartbeat:

1. Call: `const heartbeat = require('./lib/heartbeat-handler')`
2. Call: `await heartbeat.handleHeartbeat()`

That's it!

## Files You Need

- `lib/orchestration-state.js`
- `lib/task-classifier.js`
- `lib/delegator.js`
- `lib/notifier.js`
- `lib/claude-code-monitor.js`
- `lib/heartbeat-handler.js`

## Environment Variables

```bash
GLENN_CHAT_ID=your-telegram-id
CLAUDE_CODE_PATH=/path/to/claude
```

## Testing

```bash
node tests/integration-test.js
```

## Monitoring

Check state:
```javascript
const state = require('./lib/orchestration-state');
console.log(state.state);
```

## Troubleshooting

**Problem:** Tasks not spawning
- Check: OpenClaw agent spawn command works manually
- Check: Environment variables set

**Problem:** No notifications
- Check: GLENN_CHAT_ID is correct
- Check: Message tool working

**Problem:** Claude Code not monitored
- Check: Heartbeat running
- Check: process.log() works

## Support

Read: ORCHESTRATION.md (full architecture)
Read: NIKOLINE-ORCHESTRATION.md (your reference)
```

**Time:** 6 hours  
**Checkpoint:** Documentation complete

---

### Day 21: Deployment & Monitoring

**Tasks:**
1. Deploy to production (Nikoline's workspace)
2. Monitor first day of real usage
3. Gather Glenn's feedback
4. Make any immediate fixes

**Deployment checklist:**

```markdown
# Deployment Checklist

- [ ] All lib/ files copied to workspace
- [ ] All tests passing
- [ ] Environment variables set
- [ ] HEARTBEAT.md updated
- [ ] AGENTS.md mentions orchestration
- [ ] State file initialized
- [ ] Memory/ directory exists
- [ ] Glenn notified system is live
- [ ] First task tested end-to-end
- [ ] Monitoring confirmed working
```

**Time:** 4 hours (+ monitoring)  
**Checkpoint:** Live in production

---

## Post-Launch (Week 4+)

### Week 4: Monitoring & Tuning

**Daily tasks:**
- Review orchestration-state.json
- Check cost-tracker
- Review task classifications (any wrong decisions?)
- Gather Glenn's feedback

**Tuning:**
- Adjust classification keywords based on real usage
- Optimize model selection
- Fine-tune notification frequency
- Update decision tree

### Week 5+: Iteration

**Potential improvements:**
- Add more sophisticated classification (ML-based?)
- Implement automatic escalation (Haiku fails → retry with Sonnet)
- Add task priorities
- Implement task queuing
- Add analytics dashboard

---

## V2 FEATURES: Agent Conflict Management & Queue System

**NEW (Glenn's Requirements): Add these critical features**

### Conflict Detection & Resolution

**What it does:**
- Check if assigned agent is busy before spawning
- Offer Glenn 4 options when conflict detected
- Auto-route with notification if Glenn doesn't respond

**Implementation:**

```javascript
// lib/agent-manager.js (NEW FILE)

class AgentManager {
  // Check if agent can take task
  async canAssignTask(agentName, taskComplexity) {
    const state = require('./orchestration-state');
    const agent = state.getAgentStatus(agentName);
    
    if (agent.busy) {
      return {
        canAssign: false,
        eta: agent.eta,
        queueLength: agent.queue.length
      };
    }
    
    return { canAssign: true };
  }
  
  // Handle conflict - offer Glenn choices
  async handleConflict(agentName, task, eta) {
    const { notifyGlenn } = require('./notifier');
    
    const choices = {
      1: `⏱️ Wait for ${agentName} (ETA: ${Math.ceil(eta/60)} min)`,
      2: `🔄 Route to fallback agent (cost increase)`,
      3: `🆕 Spawn new instance (not recommended)`,
      4: `⚠️ Cancel this task`
    };
    
    await notifyGlenn(`
${agentName} is busy. Choose:
${Object.entries(choices).map(([k,v]) => `${k}. ${v}`).join('\n')}
    `, LEVELS.IMPORTANT);
    
    // Wait for Glenn's choice (5 min timeout)
    const choice = await waitForChoice(5 * 60 * 1000);
    return this.executeChoice(choice, task);
  }
  
  // Automatic routing (if Glenn doesn't respond)
  async autoRoute(agentName, task) {
    // If Harald busy → route to Sonny
    if (agentName === 'harald') {
      return { agent: 'sonny', reason: 'Harald busy' };
    }
    
    // If Sonny busy → offer queue or Opus
    if (agentName === 'sonny') {
      return { action: 'queue', eta: calculateETA() };
    }
    
    // If ClaudeCode busy → queue with priority
    if (agentName === 'claudecode') {
      return { action: 'queue', priority: task.priority || 'normal' };
    }
  }
}

module.exports = new AgentManager();
```

**Test scenarios:**
```javascript
// tests/conflict-detection-test.js

const manager = require('../lib/agent-manager');

// Test 1: Agent available
let result = await manager.canAssignTask('harald', 'simple');
assert(result.canAssign === true);

// Test 2: Agent busy
// (Manually set agent to busy in state)
result = await manager.canAssignTask('harald', 'simple');
assert(result.canAssign === false);
assert(result.eta > 0);

// Test 3: Auto-routing Harald busy
const routed = await manager.autoRoute('harald', taskObj);
assert(routed.agent === 'sonny');
```

### Task Queue System

**What it does:**
- Queue tasks when agent is busy
- FIFO + priority-based ordering
- Auto-escalation if wait > 10 min
- ETA calculation per task

**Implementation:**

```javascript
// lib/queue-manager.js (NEW FILE)

class QueueManager {
  constructor() {
    this.queues = {
      'harald': [],
      'sonny': [],
      'claudecode': []
    };
  }
  
  // Enqueue a task
  async enqueue(agentName, task, priority = 'normal') {
    const queueItem = {
      id: generateUUID(),
      task,
      priority,
      createdAt: Date.now(),
      eta: this.calculateETA(agentName)
    };
    
    // Insert based on priority
    if (priority === 'high') {
      // Insert after other high-priority items
      const lastHighIdx = this.queues[agentName]
        .findLastIndex(item => item.priority === 'high');
      this.queues[agentName].splice(lastHighIdx + 1, 0, queueItem);
    } else {
      this.queues[agentName].push(queueItem);
    }
    
    return queueItem;
  }
  
  // Dequeue next task
  dequeue(agentName) {
    return this.queues[agentName].shift();
  }
  
  // Calculate ETA for task
  calculateETA(agentName) {
    const state = require('./orchestration-state');
    const agent = state.getAgentStatus(agentName);
    
    if (!agent.busy) return 0; // Ready now
    
    // Agent is busy (ETA) + queue length × avg task time
    const avgTaskTime = this.getAverageTaskTime(agentName);
    const queueWait = this.queues[agentName].length * avgTaskTime;
    const currentTaskWait = Math.max(0, agent.eta - Date.now());
    
    return currentTaskWait + queueWait;
  }
  
  // Get queue status for Glenn
  getQueueStatus(agentName) {
    const queue = this.queues[agentName];
    const eta = this.calculateETA(agentName);
    
    return {
      length: queue.length,
      eta: eta,
      items: queue.map(q => ({ task: q.task.substring(0, 50), priority: q.priority }))
    };
  }
  
  // Auto-escalate if waiting too long
  async checkEscalation() {
    for (const [agentName, queue] of Object.entries(this.queues)) {
      queue.forEach(async (item) => {
        const waitTime = Date.now() - item.createdAt;
        if (waitTime > 10 * 60 * 1000) { // 10 min
          const { notifyGlenn } = require('./notifier');
          await notifyGlenn(`
⏳ Task waiting for ${agentName} for 10+ minutes
Options:
1. Continue waiting
2. Route to different agent
3. Cancel
          `, LEVELS.IMPORTANT);
        }
      });
    }
  }
  
  getAverageTaskTime(agentName) {
    // Estimate based on agent type
    const times = {
      'harald': 2 * 60 * 1000, // 2 min avg
      'sonny': 15 * 60 * 1000, // 15 min avg
      'claudecode': 45 * 60 * 1000 // 45 min avg
    };
    return times[agentName] || 10 * 60 * 1000;
  }
}

module.exports = new QueueManager();
```

**Test scenarios:**
```javascript
// tests/queue-test.js

const queueMgr = require('../lib/queue-manager');

// Test 1: Enqueue task
let item = await queueMgr.enqueue('harald', 'Search docs', 'normal');
assert(item.id);
assert(queueMgr.queues['harald'].length === 1);

// Test 2: Priority ordering
await queueMgr.enqueue('harald', 'High priority', 'high');
assert(queueMgr.queues['harald'][0].priority === 'high');

// Test 3: ETA calculation
let eta = queueMgr.calculateETA('harald');
assert(eta > 0);

// Test 4: Get queue status
let status = queueMgr.getQueueStatus('harald');
assert(status.length === 2);
```

### Sub-Agent Status Tracking

**What it does:**
- Glenn can check status anytime: "status"
- Live ETA for each agent and queued tasks
- Real-time progress updates

**Implementation:**

```javascript
// lib/status-tracker.js (NEW FILE)

class StatusTracker {
  // Get status for all agents
  getAllStatus() {
    const state = require('./orchestration-state');
    const queueMgr = require('./queue-manager');
    
    const status = {
      agents: {},
      queues: {},
      lastUpdate: Date.now()
    };
    
    ['harald', 'sonny', 'claudecode'].forEach(agent => {
      const agentStatus = state.getAgentStatus(agent);
      status.agents[agent] = {
        busy: agentStatus.busy,
        currentTask: agentStatus.task,
        eta: agentStatus.eta
      };
      
      status.queues[agent] = queueMgr.getQueueStatus(agent);
    });
    
    return status;
  }
  
  // Format for Glenn
  formatStatusForGlenn() {
    const status = this.getAllStatus();
    let output = '📊 Current Status:\n\n';
    
    // Active tasks
    output += '🔹 Currently Working:\n';
    ['harald', 'sonny', 'claudecode'].forEach(agent => {
      if (status.agents[agent].busy) {
        const eta = Math.ceil(status.agents[agent].eta / 60);
        output += `  ${agent}: ${status.agents[agent].currentTask.substring(0, 40)}... (${eta} min)\n`;
      }
    });
    
    // Queued tasks
    output += '\n⏳ Queued:\n';
    ['harald', 'sonny', 'claudecode'].forEach(agent => {
      const queue = status.queues[agent];
      if (queue.length > 0) {
        output += `  ${agent}: ${queue.length} task(s) waiting (avg ETA: ${Math.ceil(queue.eta / 60)} min)\n`;
      }
    });
    
    return output;
  }
}

module.exports = new StatusTracker();
```

### Integration with Nikoline

**Update `lib/delegator.js`:**

```javascript
// Add conflict checking before delegation
async function delegateTask(taskDescription, overrideModel = null) {
  const classification = classifyTask(taskDescription);
  const agentName = mapModelToAgent(overrideModel || classification.model);
  
  // NEW: Check if agent is available
  const manager = require('./agent-manager');
  const canAssign = await manager.canAssignTask(agentName, classification.complexity);
  
  if (!canAssign.canAssign) {
    // NEW: Handle conflict
    const resolution = await manager.handleConflict(agentName, taskDescription, canAssign.eta);
    
    if (resolution === 'queue') {
      // NEW: Queue the task
      const queueMgr = require('./queue-manager');
      const queuedItem = await queueMgr.enqueue(agentName, taskDescription);
      
      await notifyGlenn(`
⏳ Task queued for ${agentName}
Position: ${queueMgr.getQueueStatus(agentName).length}
Estimated wait: ${Math.ceil(queuedItem.eta / 60)} minutes
      `, LEVELS.INFO);
      
      return { queued: true, itemId: queuedItem.id };
    }
    
    if (resolution === 'escalate') {
      // Route to different agent
      agentName = getEscalationTarget(agentName);
      await notifyGlenn(`Harald is busy. Routing to ${agentName} instead.`, LEVELS.INFO);
    }
  }
  
  // Standard delegation continues...
  return await spawnAgent(agentName, taskDescription);
}
```

### Tests

```javascript
// tests/v2-integration-test.js

describe('V2: Conflict Management & Queue', () => {
  
  it('detects when agent is busy', async () => {
    // Simulate Harald is busy
    state.setBusy('harald', true, 300);
    
    const result = await manager.canAssignTask('harald', 'simple');
    assert(!result.canAssign);
  });
  
  it('offers Glenn 4 choices', async () => {
    // Should prompt Glenn
    // Mock response: choice 1 (wait)
    const result = await manager.handleConflict('harald', task, 300);
    assert(result.action === 'wait');
  });
  
  it('auto-routes to Sonny if Harald busy', async () => {
    // 5 min timeout without Glenn response
    const result = await manager.autoRoute('harald', task);
    assert(result.agent === 'sonny');
  });
  
  it('queues tasks properly', async () => {
    const item1 = await queue.enqueue('harald', 'task1', 'normal');
    const item2 = await queue.enqueue('harald', 'task2', 'high');
    
    // High priority should be first
    assert(queue.dequeue('harald').id === item2.id);
  });
  
  it('calculates ETA for queued tasks', async () => {
    await queue.enqueue('harald', 'task1');
    await queue.enqueue('harald', 'task2');
    
    const eta = queue.calculateETA('harald');
    assert(eta > 0);
    assert(eta < 30 * 60 * 1000); // Should be < 30 min
  });
});
```

---

## Summary: What Gets Built

### V1: Core Libraries (Week 1)
1. ✅ `lib/orchestration-state.js` - State management
2. ✅ `lib/task-classifier.js` - Task classification
3. ✅ `lib/delegator.js` - Task delegation
4. ✅ `lib/notifier.js` - Glenn notifications
5. ✅ `lib/cost-tracker.js` - Cost tracking

### V1: Monitoring (Week 2)
6. ✅ `lib/claude-code-monitor.js` - ClaudeCode monitoring
7. ✅ `lib/heartbeat-handler.js` - Heartbeat integration

### V2: Conflict Management & Queue (NEW! Week 2)
8. ✅ `lib/agent-manager.js` - Conflict detection & resolution
9. ✅ `lib/queue-manager.js` - Task queuing (FIFO + priority)
10. ✅ `lib/status-tracker.js` - Live status with ETA tracking
11. ✅ Updated `lib/delegator.js` - Conflict-aware delegation

### Testing
12. ✅ `tests/integration-test.js` - V1 integration tests
13. ✅ `tests/conflict-detection-test.js` - V2 conflict tests
14. ✅ `tests/queue-test.js` - V2 queue tests
15. ✅ `tests/v2-integration-test.js` - Full V2 integration
16. ✅ `tests/e2e-test-plan.md` - E2E test plan

### Documentation (All versions integrated)
17. ✅ `ORCHESTRATION.md` - Full architecture (V1 + V2)
18. ✅ `ORCHESTRATION-DIAGRAMS.md` - Architecture diagrams (with V2)
19. ✅ `NIKOLINE-ORCHESTRATION.md` - Your reference (with V2)
20. ✅ `ORCHESTRATION-DECISION-MATRIX.md` - Quick reference (with V2)
21. ✅ `ORCHESTRATION-SUMMARY.md` - Executive overview (with V2)
22. ✅ `ORCHESTRATION-INDEX.md` - Documentation index (with V2)
23. ✅ `ORCHESTRATION-IMPLEMENTATION-ROADMAP.md` - This file (V1 + V2)
24. ✅ `GLENN-GUIDE.md` - User guide (updated for V2)

### Total Time Estimate
- **V1 (Week 1-2): 75 hours**
  - Core orchestration
  - ClaudeCode monitoring
  
- **V2 (Week 2): 40 hours**
  - Conflict detection
  - Queue management
  - Status tracking
  - Integration & testing

- **Total: ~115 hours** (13-14 days full-time, or 3-4 weeks part-time)

---

**Status:** ✅ Implementation roadmap complete - ready to build!
