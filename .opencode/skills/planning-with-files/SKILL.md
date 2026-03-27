---
name: planning-with-files
description: This skill should be used when an agent needs to plan, track, and execute multi-step tasks using persistent markdown files. Use when the task requires more than 3 steps, spans multiple files, or could benefit from structured planning before implementation. Provides the file-based planning methodology for creating task plans, tracking findings, and logging progress.
version: 1.0.0
---

# Planning with Files

A structured methodology for planning and executing complex tasks using persistent markdown files. The filesystem is your extended memory — anything important gets written to disk rather than relying on volatile context.

## Core Principle

> **Context window = RAM (volatile, limited). Filesystem = Disk (persistent, unlimited).**

Write plans, findings, and progress to files so work survives context resets, session boundaries, and long-running tasks.

## When to Use This Skill

- Task requires **3 or more distinct steps**
- Work spans **multiple files or components**
- Task involves **research before implementation**
- Work may **span multiple sessions** or context resets
- Task is complex enough to benefit from **human review before execution**
- You need to **resume interrupted work**

## When NOT to Use This Skill

- Single-file, obvious changes (rename a variable, fix a typo)
- Tasks completable in 1-2 steps
- Pure Q&A or explanation requests

---

## The Three-File System

All planning files live in a `.plan/` directory at the project root. Create it at the start of every planned task.

```
.plan/
├── task_plan.md      # What to do — phases, tasks, dependencies
├── findings.md       # What you learned — research, decisions, discoveries
└── progress.md       # What happened — actions taken, results, errors
```

### Why Three Files

| File | Purpose | Analogy |
|------|---------|---------|
| `task_plan.md` | Roadmap and checklist | The blueprint |
| `findings.md` | Research and decisions | The lab notebook |
| `progress.md` | Execution log | The build journal |

Keeping them separate prevents any single file from becoming unwieldy and lets each serve a focused purpose.

---

## File 1: task_plan.md

The plan is the primary artifact. It defines what needs to happen, in what order, and tracks completion.

### Template

```markdown
# Task Plan: [Short Title]

## Objective
[1-2 sentences: what does success look like?]

## Constraints
- [Time, scope, technology, or style constraints]
- [Files/areas that must NOT be modified]

## Phases

### Phase 1: [Name]
- [ ] Task 1.1: [Description] → `path/to/file.ts`
- [ ] Task 1.2: [Description] → `path/to/other.ts`

### Phase 2: [Name]
- [ ] Task 2.1: [Description]
  - [ ] 2.1a: [Subtask]
  - [ ] 2.1b: [Subtask]
- [ ] Task 2.2: [Description]

### Phase 3: Verification
- [ ] Run test suite
- [ ] Verify against acceptance criteria
- [ ] Clean up .plan/ directory

## Dependencies
- Task 2.1 depends on Task 1.2
- Phase 3 cannot start until Phase 2 is complete

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] All tests pass
```

### Rules for task_plan.md

1. **Create before writing any code.** The plan is the first file you create.
2. **One task at a time.** Only one task should be in progress. Complete it or note it as blocked before moving on.
3. **Mark tasks immediately.** Check off each task (`[x]`) as soon as it is done — never batch.
4. **Include file paths.** Every task that modifies a file should reference the target path.
5. **Keep tasks atomic.** Each task should be completable in a single focused action. If a task is too large, break it into subtasks.
6. **Dependency order.** Tasks within a phase should be listed in the order they must be executed. Cross-phase dependencies go in the Dependencies section.
7. **Re-read before acting.** Before starting any task, re-read `task_plan.md` from disk to ensure you have the current state.

### Status Symbols

Use standard markdown checkboxes for tool compatibility:

```
- [ ]  Not started
- [x]  Completed
- [-]  Blocked (add reason in findings.md)
```

For phases, use a header prefix:

```
### Phase 1: Setup [DONE]
### Phase 2: Implementation [IN PROGRESS]
### Phase 3: Verification [PENDING]
```

---

## File 2: findings.md

A chronological log of everything learned during research and implementation. This is your persistent memory for decisions, discoveries, and error patterns.

### Template

```markdown
# Findings

## [Date/Timestamp] — [Topic]

**Context:** [Why you looked into this]

**Finding:** [What you discovered]

**Decision:** [What you decided to do and why]

**Impact:** [How this affects the plan]

---

## [Date/Timestamp] — [Topic]

...
```

### Rules for findings.md

1. **Write after every 2 research actions.** After every 2 file reads, searches, or web lookups, record what you found. This prevents knowledge loss if context resets.
2. **Record decisions with rationale.** Don't just record what you decided — record why. Future sessions (or other agents) need the reasoning.
3. **Log errors and their resolutions.** When something fails, document the error, the root cause, and the fix. This prevents repeating the same mistakes.
4. **Note rejected alternatives.** If you considered approach A but chose approach B, document why A was rejected. This prevents future re-evaluation of dead ends.
5. **Include code snippets.** When you discover a pattern, API signature, or configuration format, paste the relevant snippet directly into findings.

### Example Entry

```markdown
## 2026-03-27 — Auth Middleware Architecture

**Context:** Evaluating how to add JWT validation to the API routes.

**Finding:** The existing middleware chain in `src/middleware/index.ts` uses
a compose pattern. Auth must run before rate-limiting because rate limits
are per-user.

**Decision:** Insert auth middleware at position 0 in the chain. Use the
existing `verifyToken()` from `src/lib/jwt.ts` rather than a new library.

**Impact:** No new dependencies. Phase 1 Task 1.2 can reuse existing code.
Updating task estimate from 30min to 15min.
```

---

## File 3: progress.md

A session-oriented execution log. Records what was done, what succeeded, and what failed. This is the file that enables session recovery.

### Template

```markdown
# Progress

## Session: [Date/Time]

### Actions
1. [Action taken] → [Result]
2. [Action taken] → [Result]

### Files Modified
- `path/to/file.ts` — [What changed]
- `path/to/test.ts` — [What changed]

### Test Results
- [Test suite]: [PASS/FAIL] — [Details if failed]

### Errors Encountered
- [Error description] → [Resolution or workaround]

### Status at End of Session
- Phase 1: DONE
- Phase 2: IN PROGRESS (Task 2.3 next)
- Phase 3: PENDING

---

## Session: [Earlier Date/Time]

...
```

### Rules for progress.md

1. **Log every significant action.** File edits, test runs, git commits, commands executed.
2. **Record test results explicitly.** Include pass/fail status after every test run.
3. **Track files modified.** List every file changed in the session with a brief description.
4. **End-of-session status.** Always write a status summary at the end of each session showing phase completion and the next task to pick up.
5. **Errors get full context.** Include the error message, the file/line if applicable, and how it was resolved.

---

## Workflow

### Starting a New Task

```
1. Create .plan/ directory
2. Write task_plan.md with phases and tasks
3. Write initial findings.md header
4. Write initial progress.md header
5. STOP — Present the plan for review before proceeding
```

**Critical:** Do not write any code until the plan exists and has been reviewed. Planning before acting prevents assumption-driven bugs and wasted effort.

### Executing the Plan

```
For each task in task_plan.md:
  1. Re-read task_plan.md from disk
  2. Identify the next unchecked task
  3. Execute the task (edit code, run command, etc.)
  4. Mark the task as [x] in task_plan.md
  5. Log the action in progress.md
  6. If you learned something new → update findings.md
  7. If the plan needs to change → update task_plan.md, note the change in findings.md
```

### Handling Plan Changes (Replanning)

Plans are living documents. When new information requires changes:

1. **Don't silently change the plan.** Document what changed and why in `findings.md`.
2. **Add tasks, don't remove them.** If a task becomes unnecessary, mark it `[x] SKIPPED — [reason]` rather than deleting it. This preserves the decision trail.
3. **Note scope changes.** If the task is growing significantly, flag it in `progress.md` and consider splitting into a child plan.

### Session Recovery

When resuming work after a context reset or new session:

```
1. Read task_plan.md — understand the overall plan and what's done
2. Read progress.md — understand the last session's state and next task
3. Read findings.md — recover decisions and context
4. Continue from the next unchecked task
```

This is the primary value of file-based planning: the agent can fully recover its working state from disk.

### Completing the Task

```
1. All tasks in task_plan.md are checked
2. All acceptance criteria are met
3. Final entry written to progress.md with completion summary
4. Present results to the user
5. Ask whether to keep or remove .plan/ directory
```

---

## Scaling: Hierarchical Plans

For large tasks (more than ~20 tasks or 3 phases), use child plans:

```
.plan/
├── task_plan.md              # Parent plan — high-level phases only
├── findings.md
├── progress.md
├── auth-plan.md              # Child plan for Phase 1
└── dashboard-plan.md         # Child plan for Phase 2
```

The parent plan references child plans:

```markdown
### Phase 1: Authentication
See detailed plan: [auth-plan.md](auth-plan.md)
- [ ] All auth tasks complete (see child plan)
```

Each child plan follows the same template as `task_plan.md`.

---

## Git Integration

Use git commits as checkpoints throughout execution:

1. **Commit after each phase** — not after each task. This keeps the history meaningful.
2. **Reference the plan in commit messages** — e.g., "Phase 1 complete: auth middleware (see .plan/task_plan.md)"
3. **Commit the plan files themselves** if the project tracks them, or add `.plan/` to `.gitignore` if they're ephemeral working state.

---

## Platform-Specific Notes

### Claude Code
- Claude Code has a built-in `TodoWrite` tool for in-memory tasks. Use `.plan/` files as the **persistent** complement — TodoWrite for quick visibility, plan files for durability.
- Claude Code hooks can automate plan re-reading: a `PreToolUse` hook on `Edit`/`Write` tools can re-read `task_plan.md` before each code change.

### Cursor
- Cursor has a native Plan Mode (Shift+Tab). Use `.plan/` files when you need plans to persist beyond a single chat session or when working on multi-day features.
- Save Cursor-generated plans to `.plan/task_plan.md` using "Save to workspace" for persistence.

### OpenCode
- OpenCode's Plan agent writes to `.opencode/plans/`. The `.plan/` approach works alongside this — use `.plan/` for task-specific planning, `.opencode/plans/` for architectural analysis.

### Pi
- Pi uses AGENTS.md for project instructions. Reference `.plan/` files from AGENTS.md to give Pi context on in-progress work.
- Pi's extension system can wrap plan file reading/writing into custom tools.

### Gemini
- Gemini works best with explicit instructions to read and update plan files. Include "Read .plan/task_plan.md before making any code changes" in your system instructions.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Do This Instead |
|-------------|-------------|-----------------|
| Planning in context only | Lost on context reset | Write to `.plan/` files |
| One giant plan file | Becomes unwieldy, hard to parse | Use the three-file system |
| Updating the whole plan at once | Obscures what changed | Update one task at a time |
| Skipping the plan for "quick" tasks | Scope creep, missed steps | If 3+ steps, plan first |
| Never replanning | Plan becomes fiction | Update the plan as you learn |
| Deleting completed tasks | Loses decision trail | Mark `[x]`, never delete |
| Planning without file paths | Vague, unactionable tasks | Every code task names its file |
| Starting code before plan review | Wasted work if plan is wrong | Present plan, wait for approval |

---

## Quick Reference

```
START:
  mkdir .plan/
  write task_plan.md → present for review → wait

EXECUTE:
  re-read task_plan.md
  do next task → mark [x] → log in progress.md
  every 2 research actions → update findings.md
  repeat

REPLAN:
  document change in findings.md
  update task_plan.md
  continue

RECOVER:
  read task_plan.md → progress.md → findings.md
  continue from next unchecked task

FINISH:
  verify acceptance criteria
  write final progress entry
  present results
```
