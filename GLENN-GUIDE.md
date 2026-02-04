# Glenn's Guide to the Orchestration System

**TL;DR:** Just talk to Nikoline like always. She handles all the complexity.

---

## What Changed?

### Before:
- You had to decide when to use sub-agents
- You had to manage Claude Code sessions
- You had to remember model costs

### After:
- **You just ask Nikoline to do things**
- She decides what tool to use
- She reports back when done
- You can keep chatting while she works

---

## How It Works (Simple Version)

```
You: "Build a REST API for the blog"
Nikoline: 🔧 Starting Claude Code session...
[Claude Code works in background]

You: "What's the weather?"
Nikoline: "72°F and sunny"
[Claude Code still working]

You: "How's the API going?"
Nikoline: "🔧 Progress: Created 3 files, working on tests"

[30 minutes later]
Nikoline: ✅ Completed: Build REST API
          Files created: 5, Tests passing
```

**Key points:**
- You're never blocked waiting
- You can keep chatting normally
- Nikoline updates you automatically
- Everything happens in the background

---

## NEW: When Team Members Are Busy

Sometimes Nikoline's team is busy with other tasks. When this happens, you get to make a choice:

**Scenario 1: Harald is busy**

```
You: "Search for Python docs"
Nikoline: "Harald is busy for about 5 minutes. Options:
          1️⃣  Wait for Harald (cheaper)
          2️⃣  Use Sonny instead (faster, costs more)
          3️⃣  Spawn another Harald
          4️⃣  Cancel for now"

You: "I'll wait"
Nikoline: "✓ Queued. Harald will start in ~5 min"
[5 minutes later]
Nikoline: "🚀 Harald is working on it now..."
[2 minutes later]
Nikoline: "✅ Found docs! [results]"
```

**Scenario 2: Multiple tasks queued**

```
You: "Find 3 things AND debug the API AND build feature X"
Nikoline: "Got it. Starting multiple tasks:
          🚀 Task 1: Search (starting now with Harald)
          ⏳ Task 2: Debug (queued for Sonny, ~10 min wait)
          ⏳ Task 3: Build (queued for ClaudeCode, ~45 min wait)"

[Tasks start as agents become available]
```

**Scenario 3: Check status anytime**

```
You: "What's everyone working on?"
Nikoline: "📊 Current Status:

🔹 Currently Working:
  Harald: Searching for docs (2 min remaining)
  Sonny: Debugging API issue (8 min remaining)
  ClaudeCode: Building REST API (45 min remaining)

⏳ Queued:
  Harald queue: 1 task (5 min wait)
  Sonny queue: empty
  ClaudeCode queue: 2 tasks (avg 1h 15m wait)"
```

## What You'll See

### When you ask Nikoline to do something:

**Small tasks** - she just does them:
```
You: "What's my next meeting?"
Nikoline: "Team standup at 2pm"
```

**Medium tasks** - she spawns a helper:
```
You: "Search for Node.js security best practices"
Nikoline: 🚀 Starting task: Search for Node.js security... (haiku)
[30 seconds later]
Nikoline: ✅ Completed: Search for Node.js security...
          Found 5 key practices...
```

**Big tasks** - she starts Claude Code:
```
You: "Refactor the auth system"
Nikoline: 🔧 Starting Claude Code session: Refactor auth system
[Works for 30 minutes]
Nikoline: 🔧 Progress: Completed auth module
[More work]
Nikoline: ✅ Claude Code completed: Refactor auth system
          7 files modified, tests passing
```

### Notification Types:

- 🚀 **Started** - Task beginning
- 📊 **Progress** - Milestone reached
- ✅ **Complete** - Task finished
- 🚨 **Error** - Something went wrong

**Notification settings:**
- 🚨 Errors - sound alert (urgent)
- ✅ Complete - notification (important)
- 📊 Progress - silent (info, won't buzz your phone)

---

## Tips & Tricks

### 1. You Can Keep Chatting

Even when Claude Code is running a 2-hour refactor, you can still:
- Ask Nikoline questions
- Start other tasks
- Check status
- Have normal conversations

**Everything is isolated.** Your messages never accidentally go to the wrong place.

### 2. Ask for Status Anytime

```
You: "What are you working on?"
Nikoline: "Currently:
- Claude Code: Refactoring auth (25 min, 60% done)
- Sub-agent: Searching for docs (just finished)
- Main: Available for chat"
```

### 3. Use "status" Command for Live Dashboard

Anytime you want to see what everyone is doing:

```
You: "status"
Nikoline: "📊 Current Status:

🔹 Currently Working:
  Harald: Extracting emails (1 min remaining)
  Sonny: Debugging API (6 min remaining)

⏳ Queued:
  Harald: 2 tasks waiting (5-10 min)
  ClaudeCode: 1 task waiting (1 hour)"
```

**Use cases:**
- "How long until Sonny is free?"
- "How many tasks are queued?"
- "Is anyone working on my thing?"

### 4. Override Decisions (If You Want)

Usually Nikoline picks the right tool. But you can override:

```
You: "Search for X" 
→ Nikoline would use Haiku

You: "Search for X, but use Sonnet for deeper analysis"
→ Nikoline uses Sonnet instead
```

### 4. Interrupt Claude Code (Rare)

If Claude Code is going wrong:

```
You: "Stop Claude Code and commit what it has"
Nikoline: ⚠️ Sending stop command to Claude Code...
          ✅ Changes committed to git
```

### 5. Check Costs

```
You: "How much have I spent today?"
Nikoline: "Today's costs:
- 3 Haiku sub-agents: $0.15
- 2 Sonnet sub-agents: $1.50
- Claude Code: $0 (Max plan)
- Total: $1.65"
```

---

## Common Scenarios

### Scenario: Quick Question

```
You: "What's the Node.js LTS version?"
Nikoline: [searches immediately]
Nikoline: "v22.x is the current LTS"
```

**What happened:** Nikoline handled it directly (trivial task)

---

### Scenario: Research Task

```
You: "Research JWT authentication best practices"
Nikoline: 🚀 Starting task: Research JWT... (haiku)
[1 minute later]
Nikoline: ✅ Completed: Research JWT...
          Key practices:
          - Short expiration (15 min)
          - Refresh tokens
          - httpOnly cookies
          - HTTPS only
```

**What happened:** Nikoline spawned a Haiku sub-agent (simple research)

---

### Scenario: Debugging

```
You: "Why is the API returning 500 errors?"
Nikoline: 🚀 Starting task: Debug API errors (sonnet)
[3 minutes later]
Nikoline: 📊 Found issue: Database connection pool exhausted
[2 more minutes]
Nikoline: ✅ Completed: Debug API errors
          Root cause: Connection pool config too small
          Fix: Increase max_connections from 10 to 50
          Location: config/database.js line 23
```

**What happened:** Nikoline spawned a Sonnet sub-agent (complex debugging)

---

### Scenario: Big Project

```
You: "Build a GraphQL API for the blog system"
Nikoline: 🔧 Starting Claude Code session: Build GraphQL API

[You go do something else]

[15 minutes later]
Nikoline: 🔧 Progress: Schema defined, 3 resolvers complete

[You check in]
You: "How's it going?"
Nikoline: "Going well! Claude Code is 60% done:
- ✅ Schema (blog, user, comment types)
- ✅ Queries (getBlog, listBlogs, getUser)
- ✅ Mutations (createBlog, updateBlog)
- ⏳ Working on: deleteBlog, auth middleware
- ⏳ TODO: Tests"

[30 more minutes]
Nikoline: ✅ Claude Code completed: Build GraphQL API
          Files created: 8
          Lines added: 650
          Tests: passing ✅
          
          Changes:
          - schema/blog.graphql
          - resolvers/blog.js
          - resolvers/user.js
          - middleware/auth.js
          - Tests for all operations
          
          Full logs: memory/claude-code-1234567890.log
```

**What happened:** Nikoline spawned Claude Code (multi-file project)

---

## FAQ

### Q: Do I need to learn anything new?

**A:** Nope. Just ask Nikoline to do things. She figures out how.

### Q: What if I want to use Claude Code directly?

**A:** You can say "Use Claude Code for this" and Nikoline will. But usually you don't need to.

### Q: Can I see what's happening in the background?

**A:** Yes! Ask "What are you working on?" or "Show me the Claude Code logs"

### Q: Will this cost more?

**A:** Actually less! Nikoline uses cheaper models when possible:
- Haiku ($1.25/M) for simple stuff
- Sonnet ($15/M) for complex stuff
- Claude Code (free with Max plan) for big projects

Before: everything used Sonnet = expensive
After: right tool for the job = 30-50% cheaper

### Q: What if something goes wrong?

**A:** Nikoline will alert you immediately:
```
🚨 Error in task: Debug API issue
❌ Failed to connect to database
```

Then you can decide what to do.

### Q: Can Nikoline do multiple things at once?

**A:** Yes! She can:
- Chat with you (always)
- Monitor Claude Code (background)
- Have 3 sub-agents working (parallel)
- Check your calendar (periodic)

All at the same time.

### Q: How do I know what's using what model?

**A:** Nikoline tells you when she starts tasks:
```
🚀 Starting task: Search for docs (haiku)
🚀 Starting task: Debug issue (sonnet)
🔧 Starting Claude Code session...
```

### Q: Can I disable automatic notifications?

**A:** Yes, configure in your preferences:
```
You: "Only notify me for completions and errors, not progress"
Nikoline: "Updated notification settings:
- Errors: notify (loud)
- Completions: notify (normal)
- Progress: silent (no notification)"
```

### Q: What happens when all the helpers are busy?

**A:** Nikoline gives you options:
```
You: "Search for Node docs"
Nikoline: "Harald is busy for 5 minutes. Options:
          1. Wait (cheaper, saves $0.50)
          2. Use Sonny now (faster)
          3. Cancel"

You: "I'll wait"
Nikoline: "✓ Queued. You're #1 in line, ~5 min wait"
```

This is **fair** - first come, first served. But if you're in a hurry, you can always use a different helper.

### Q: How do I know how long I'll wait?

**A:** Ask for status anytime:
```
You: "How's the queue?"
Nikoline: "Harald queue: 2 tasks
- Your task: #1 (starts in ~3 min)
- Other task: #2 (starts after yours)"
```

Nikoline also gives you an ETA:
```
Nikoline: "⏳ Task queued for Harald (ETA: 5 minutes)"
```

### Q: Can I prioritize my task?

**A:** Ask Nikoline to prioritize:
```
You: "This is urgent, make it high priority"
Nikoline: "✓ Prioritized. Moving ahead in queue..."
```

High-priority tasks jump the queue (but you'll be polite to others first).

---

## What's Different From Before?

### Old way:
```
You: "Build feature X"
You: [wait 30 minutes, can't chat]
Nikoline: "Done!"
```

### New way:
```
You: "Build feature X"
Nikoline: 🔧 Starting Claude Code...
You: "What's the weather?"
Nikoline: "72°F and sunny"
You: "How's feature X?"
Nikoline: "60% done, working on tests"
[later]
Nikoline: ✅ Feature X complete!
```

**Benefits:**
- ✅ Never blocked
- ✅ Stay informed
- ✅ Multi-task freely
- ✅ Lower costs
- ✅ Better tool selection

---

## Emergency Commands

If something goes really wrong:

```
You: "Stop all tasks"
Nikoline: ⚠️ Stopping:
- Claude Code session (killed)
- 2 sub-agents (terminated)
✅ All background work stopped
```

```
You: "Show me everything running"
Nikoline: "Active tasks:
1. Claude Code: Refactor auth (30 min, session: exec:pty:12345)
2. Sub-agent: Search docs (2 min, Haiku)
3. Sub-agent: Debug API (5 min, Sonnet)"
```

---

## Bottom Line

**You:** Just ask Nikoline for things, like always.

**Nikoline:** Figures out the best way to do it, does it in the background, keeps you updated.

**Result:** Faster, cheaper, and you're never blocked.

---

**Questions?** Just ask Nikoline: "How does the orchestration system work?" 😊
