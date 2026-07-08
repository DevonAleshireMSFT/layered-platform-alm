# GitHub Copilot Instructions — Layered Platform ALM (LP-ALM)
#
# This file is automatically read by GitHub Copilot in every chat session
# in this repository.
#
# PROJECT: LP-ALM — Layered Platform ALM Methodology
# PLATFORM: Microsoft Power Platform / Dataverse
# TARGET: Enterprise and Government (GCC High / FedRAMP) deployments
# -----------------------------------------------------------------------

## Project Context

Before answering any question or generating any code in this repository,
read `.ai/context.md`. It defines the LP-ALM methodology, the five-layer
architecture, and the rules that must always be followed.

This repository is a **methodology reference and template** — not a live
Power Platform project. It contains:
- The complete LP-ALM methodology document (`LP-ALM.md`)
- Azure DevOps pipeline templates (`pipelines/`)
- AI context files for project grounding (`.ai/`)
- Documentation templates (`docs/`)

When this repo is used as the foundation for an actual project, the
placeholder values (`{ProjectCode}`, `{prefix}`, `{org}`) must be
replaced with real values. The `.ai/` files are the first place to update.

## Rules That Always Apply

- **`_Config` is never committed to source control and never included in
  any pipeline.** This is the foundational security rule of LP-ALM. It
  applies to this methodology repo and to every project that adopts it.
- **`_Security` deploys first.** Always. In every environment. Never
  suggest reversing or skipping this order.
- **`_UI` cannot contain schema** (tables, columns, relationships). If
  a component defines data structure, it belongs in `_Core`.
- **Upper environments (Test, Prod) receive managed solutions only.**
  Dev receives unmanaged. Do not suggest deploying managed to Dev.
- **Connection references must use service accounts, not personal
  credentials.** No personal email addresses in connection bindings.
- **GCC High org URLs use `.crm.microsoftdynamics.us`** — not
  `.crm.dynamics.com`. All pipeline environment URLs must use the
  correct sovereign cloud domain.
- **The pipeline service principal requires the built-in System
  Administrator role** to deploy security roles (`prvWriteRole`
  requirement). This cannot be granted to a custom role.
- **Append and Append To privileges must always be explicitly set**
  in every security role for every relationship a role traverses.
- **Dataverse Owner Teams use "Direct User (Basic) access level and
  Team privileges"** — not Business Unit level.
- **Never generate, suggest, or output credentials, secrets, API keys,
  or connection strings in any form.**
- **"Pipeline" always means Azure DevOps (ADO) YAML pipeline.** LP-ALM
  does not use Power Platform Pipelines (the in-product admin center
  feature). Never suggest Power Platform Pipelines as an alternative to
  or replacement for the ADO pipeline architecture defined here.

## Where to Find More Context

If you are uncertain about any of the following topics, read the
corresponding file before generating a response:

| Topic | File |
|-------|------|
| Layer definitions, component placement rules | `.ai/layers.md` |
| Naming conventions, prefixes, solution names | `.ai/conventions.md` |
| Table and column inventory (project-specific) | `.ai/schema.md` |
| Full methodology (all 11 sections) | `LP-ALM.md` |
| Security role privilege matrix | `docs/security-role-matrix-template.md` |
| Where does component X go? | `docs/component-placement-decision-tree.md` |
| Environment URLs, service principals, teams | `docs/environment-register-template.md` |
| New project or developer onboarding | `docs/onboarding-checklist.md` |
| Enterprise strategy — GCC High / DoD scale | `docs/enterprise-strategy-gcc-high.md` |

## What You Must Never Do

- Generate, suggest, or output credentials, connection strings, API keys,
  or secrets in any form.
- Suggest committing `_Config` (or any `*_Config*` solution artifact) to
  source control or including it in a pipeline.
- Suggest deploying `_Automation` or `_UI` before `_Security` and `_Core`.
- Suggest adding schema (tables, columns) to the `_UI` solution.
- Suggest using personal credentials in a connection reference.
- Suggest deploying a managed solution to the Dev environment.
- Suggest using Power Platform Pipelines (the admin center feature) in
  place of the ADO YAML pipelines that LP-ALM requires.
- Treat `.ai/` documents as the authoritative source of truth — they are
  working context documents maintained alongside the methodology.

## When Working on Pipeline YAML Files

- All pipeline YAML files reference `SYSTRK` and `SYSTRK-*` variable
  groups as illustrative placeholders. When helping adapt these for a
  real project, replace `SYSTRK` with the actual `{ProjectCode}`.
- The `--cloud UsGovHigh` flag must be present in all `pac auth create`
  commands targeting GCC High environments.
- `_Config` must never appear in any pipeline step, variable, or artifact
  reference — not even as a comment suggesting it could be added.

## After Making Changes

After completing any set of file changes, always provide a recommended git
commit message following the Conventional Commits format:

  <type>(scope): <short summary>

  <body — bullet list of what changed and why>

Use these types: feat, fix, docs, chore, ci, refactor, style, test
Use the layer or repo area as the scope where applicable
  (e.g. methodology, pipelines, ai-context, docs, security, core)

## Confirming Context at Session Start

When a user starts a new conversation, confirm you have read `.ai/context.md`
by briefly stating: "LP-ALM Methodology Repository" and one active rule
from the Rules That Always Apply section above. This confirms grounding
before the first response.