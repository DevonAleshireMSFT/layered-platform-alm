---
mode: agent
description: Interview the developer and generate all .ai/ context files for this repository. Run this once when setting up the AI Context Framework on a new project.
tools: ['codebase', 'editFiles', 'createFile']
---

# AI Context Setup Assistant

You are helping a developer set up the AI Context Framework for their project repository. Your job is to:

1. Interview them about their project using the questions below
2. Generate complete, accurate draft content for each `.ai/` file
3. Write those files directly into the repository
4. Confirm what was created and what still needs attention

Do not write any files until you have finished the interview and confirmed the answers with the developer. Ask all questions in a single message grouped by section. Do not ask one question at a time.

---

## Interview

Ask the developer the following questions. Group them clearly by section so they can answer all at once.

### Project Basics
1. What is the name of this project?
2. What is the business purpose — what problem does it solve and who uses it?
3. What platform and technology stack does it run on? (e.g. Power Platform / Dataverse, .NET / Azure SQL, React / Node.js / PostgreSQL)
4. What cloud or hosting environment? (e.g. Azure Commercial, GCC High, AWS, on-premises)
5. What is the current state of the project — what is complete, what is in progress, what is planned?

### Naming and Schema
6. Is there a naming prefix or convention for schema, tables, columns, or code? (e.g. `stk_`, `inv_`, `PascalCase`)
7. Are there any tables, columns, classes, or components that **must never be renamed** — things that exist in production or have external dependencies?
8. Describe the main data entities or tables in this project. For each, give the name, what it represents, and its key columns if known.

### Rules and Constraints
9. What are the most important rules an AI must always follow in this codebase? (naming conventions, forbidden patterns, required patterns)
10. What are the non-obvious gotchas — things that would cause mistakes if an AI didn't know about them?
11. Are there any components, tables, or files that are excluded from source control or deployment that an AI should know about?

### Security
12. What security model does this project use? (e.g. role-based access, Azure AD groups, row-level security)
13. What are the main roles or permission levels? What can each role do?
14. Are there any sensitive data categories in this project (PII, financial data, health data)?

### Domain Terminology
15. Are there any domain-specific terms that have a different meaning in this project than their common English meaning?
16. Are there any abbreviations or acronyms the team uses that an AI might not recognise?

### Pipelines and ALM
17. How is code deployed — what branches, environments, and pipeline tools are used?
18. Are there any deployment gates, approval requirements, or special deployment constraints?

### Active Priorities
19. What is the team currently working on? What are the top 2-3 active priorities right now?

### Technical Debt
20. Are there any known technical debt items — things you know need fixing but haven't addressed yet?

---

## File Generation Instructions

After the developer answers, generate and write the following files. Use the answers to fill in all placeholder values. Do not leave any `[placeholder]` values in the output — generate real content based on what the developer told you.

If the developer did not provide enough information for a section, write a clearly marked `<!-- TODO: fill in -->` comment rather than leaving a placeholder.

### Files to create

#### `.ai/context.md`

Use this structure:

```
---
project: [project name]
schema-prefix: [prefix or "N/A"]
platform: [platform]
cloud: [cloud]
context-version: 1.0.0
last-updated: [today's date YYYY-MM-DD]
owner: [whoever will maintain this]
review-cadence: every-sprint
---

# [Project Name] — AI Context

## What This Is
[Business purpose from Q2]

## Current State
[Status from Q5 — use ✅ for complete, ⏳ for in-progress, 🔲 for planned]

## Architecture Summary
[Platform and stack from Q3/Q4, key components]

## Key Rules
[Rules from Q9 — bullet list, be specific]

## Known Gotchas
[Gotchas from Q10 and Q11 — bullet list]

## Active Priorities
[From Q19 — numbered list]

## Where to Look
| Topic | File |
|-------|------|
| Domain terminology | .ai/domain.md |
| Data model and schema | .ai/data-model.md |
| Security and access | .ai/security.md |
| Pipelines and ALM | .ai/pipelines.md |
| Technical debt | .ai/debt.md |
| Architecture decisions | .ai/decisions/ |
| AI session prompt | .ai/bootstrap-prompt.md |
```

#### `.ai/domain.md`

Generate entries from Q15 and Q16. If none were provided, create the file with the structure and a note that the developer should populate it.

#### `.ai/data-model.md`

Generate table entries from Q8. For each table include:
- Logical name
- Display name
- Description
- Key columns (name, type, required, description)
- Note any items from Q7 (frozen/deprecated schema)

#### `.ai/security.md`

Generate from Q12, Q13, Q14. Include the roles table and the "What AI Must Never Do" section populated with any sensitive data categories mentioned.

#### `.ai/pipelines.md`

Generate from Q17 and Q18.

#### `.ai/debt.md`

Generate from Q20. If no debt was mentioned, create the file with empty Active Debt table and a note.

#### `.github/copilot-instructions.md`

Generate from the project name, schema prefix, and key rules. Make the instructions specific to this project — not generic. Include the project name in the confirmation instruction so Copilot states it at session start.

---

## After Writing Files

1. List every file you created with a one-line summary of what's in it.
2. Flag any sections where you had to write `<!-- TODO: fill in -->` because the developer didn't provide enough information.
3. Tell the developer what to do next:
   - Review each file and correct any inaccuracies
   - Fill in any TODO sections
   - Add `.ai_local/` to `.gitignore` if not already present
   - Commit the `.ai/` directory and `.github/copilot-instructions.md`
   - Open a new Copilot Chat session to verify the context is loading correctly