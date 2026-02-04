# HEARTBEAT.md

## Kanban Task Polling (via GitHub Gist)

Check for new tasks from the Kanban dashboard every ~30 minutes using `gh gist view`:

1. Fetch Gist content: `gh gist view f9ccd3ba6fbf6f04f69deef9e6cb3beb --filename kanban-tasks.json --raw`
2. Parse JSON and look for tasks with `"assignee": "nikoline"` in columns: `backlog`, `todo`, `in-progress`
3. If found unprocessed tasks:
   - Acknowledge the task(s)
   - Add to my work queue
   - Report back to Glenn
4. If no new tasks, reply HEARTBEAT_OK

**Note:** Do NOT modify the Gist during polling - it's read-only for Nikoline. Glenn controls task assignment from the dashboard.

Rotate checks:
- Kanban tasks (every 2-4 heartbeats)
- Email check (when Gmail is set up)
- Calendar events (when calendar is integrated)
