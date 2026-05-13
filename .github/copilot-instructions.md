# GitHub Copilot Instructions — CPE C2IN System Tracker (SYSTRK)
#
# This file is automatically read by GitHub Copilot in every chat session
# in this repository.
#
# PROJECT: CPE C2IN System Tracker
# PLATFORM: Power Platform / Dataverse — GCC High (armyeitaas)
# PUBLISHER PREFIX: stk_ (legacy: mnpoc_ — never rename)
# -----------------------------------------------------------------------

## Project Context

Before answering any question or generating any code in this repository,
read `.ai/context.md`. It defines what this project is, its current state,
and the rules that must always be followed.

## Rules That Always Apply

- All net-new schema uses the `stk_` prefix. The `mnpoc_` prefix is legacy —
  **never suggest renaming any mnpoc_ schema**.
- The primary column schema name is always `stk_name`. Never suggest a custom
  schema name for a primary column — only the display name changes.
- `SYSTRK_Config` is **never committed to source control** and never included
  in a deployment pipeline. It is always deployed manually per environment.
- `stk_hardware` is the hardware catalog table. Do not suggest renaming it.
- Tables are created in the maker portal first, then exported and unpacked via
  PAC CLI. Do not suggest creating tables via code or direct import.
- GCC High org URLs use `.crm.microsoftdynamics.us` — not `.crm.dynamics.com`.
- Append and Append To privileges must always be set in security role definitions.
- Dataverse teams must use "Direct User (Basic) access level and Team privileges".
- "System" means a physical fielded asset. "System Profile" means the digital
  blueprint. These are different entities — do not conflate them.

## Where to Find More Context

If you are uncertain about any of the following topics, read the
corresponding file before generating a response:

| Topic | File |
|-------|------|
| Domain terminology (System, Profile, Fielding, Component) | `.ai/domain.md` |
| Table definitions, relationships, column inventory | `.ai/data-model.md` |
| Security roles, privilege matrices, AAD groups | `.ai/security.md` |
| Pipeline, PAC CLI workflow, deployment standards | `.ai/pipelines.md` |
| Technical debt and deferred decisions | `.ai/debt.md` |
| Architecture decisions and rationale | `.ai/decisions/` |

## What You Must Never Do

- Generate, suggest, or output credentials, connection strings, API keys,
  or secrets in any form.
- Rename any `mnpoc_` table, column, or component.
- Rename `stk_hardware` to `stk_partnumber` or any other name.
- Include `SYSTRK_Config` in any pipeline, script, or deployment instruction.
- Suggest custom schema names for primary columns — always leave as `stk_name`.
- Treat `.ai/` documents as the authoritative source of truth — they are
  working context documents derived from committed source files.

## After Making Changes

After completing any set of file changes, always provide a recommended git
commit message following the Conventional Commits format:

  <type>(scope): <short summary>

  <body — bullet list of what changed and why>

Use these types: feat, fix, docs, chore, ci, refactor, style, test
Use the solution or layer as the scope where applicable
  (e.g. core, security, ui, automation, pipelines, ai-context)

## Confirming Context at Session Start

When a user starts a new conversation, confirm you have read `.ai/context.md`
by briefly stating: "CPE C2IN System Tracker (SYSTRK)" and one active Key Rule
from the context file. This confirms grounding before the first response.