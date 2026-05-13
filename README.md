# Layered Power Platform ALM (LP-ALM)

[![GitHub Pages](https://img.shields.io/badge/docs-GitHub%20Pages-blue?logo=github)](https://DevonAleshireMSFT.github.io/layered-platform-alm)

**[LP-ALM Methodology Site → DevonAleshireMSFT.github.io/layered-platform-alm](https://DevonAleshireMSFT.github.io/layered-platform-alm)**

A security-first decomposition framework for Microsoft Power Platform solutions in enterprise and government (GCC High / FedRAMP) environments.

---

## What Is This?

This repository contains the complete **LP-ALM methodology** — a structured approach to building and deploying Power Platform solutions as five discrete, ordered layers instead of a single monolithic solution.

**The five layers, in deployment order:**

| # | Layer | Purpose | Source Control | Pipeline |
|---|---|---|---|---|
| 1 | `_Security` | Security roles, field security profiles | ✅ Yes | ✅ Yes |
| 2 | `_Core` | All Dataverse schema (tables, columns, views, forms) | ✅ Yes | ✅ Yes |
| 3 | `_Config` | Environment variable values | ❌ **Never** | ❌ **Never** |
| 4 | `_Automation` | Power Automate flows, connection references | ✅ Yes | ✅ Yes |
| 5 | `_UI` | Model-driven apps, canvas apps, site maps | ✅ Yes | ✅ Yes |

---

## Key Architecture Principles

- **Security deploys first.** Access control structures exist before any data schema is created — in every environment, always.
- **`_Config` is permanently excluded from source control and pipelines.** Zero secrets in the repository. No exceptions.
- **Upper environments (Test, Prod) receive managed solutions only.** Changes go through the pipeline. Ad-hoc customization is blocked.
- **Connection references use service accounts, not personal credentials.** Required for GCC High; best practice everywhere.
- **`_UI` cannot introduce schema.** All tables and columns belong in `_Core`. The PR validation pipeline enforces this.

---

## Repository Structure

```
.ai/                        ← AI context for GitHub Copilot and AI assistants
  context.md                   Project identity, environment list, rules
  layers.md                    Quick layer decision reference
  schema.md                    Table/column inventory
  conventions.md               Naming conventions
.gitignore                  ← Power Platform exclusions (includes _Config)
LP-ALM.md                   ← Full methodology document (all 11 sections)
README.md                   ← This file
docs/
  security-role-matrix-template.md    Role privilege matrix template
  component-placement-decision-tree.md  Where does X go?
  environment-register-template.md    Environment inventory (no secrets)
  onboarding-checklist.md             New team/project setup checklist
pipelines/
  deploy-all.yml              Full orchestration pipeline (all 4 layers in order)
  deploy-security.yml         Individual _Security layer pipeline
  deploy-core.yml             Individual _Core layer pipeline
  deploy-automation.yml       Individual _Automation layer pipeline
  deploy-ui.yml               Individual _UI layer pipeline
  pr-validation.yml           PR build validation (pack + schema contamination check)
solutions/
  {ProjectCode}_Security/     Unpacked _Security solution source
  {ProjectCode}_Core/         Unpacked _Core solution source
  {ProjectCode}_Automation/   Unpacked _Automation solution source
  {ProjectCode}_UI/           Unpacked _UI solution source
  (no _Config directory)
```

---

## Getting Started

**New to this project?** Start here:
1. Read [.ai/context.md](.ai/context.md) — project identity and rules
2. Read [.ai/layers.md](.ai/layers.md) — where does a given component go?
3. Follow [docs/onboarding-checklist.md](docs/onboarding-checklist.md) — tools, access, first PR

**Setting up a new project using LP-ALM?**
1. Read [LP-ALM.md](LP-ALM.md) — the full methodology (especially Sections 2, 4, 6, 7, 10)
2. Follow the onboarding checklist Part 2 (new project setup)
3. Update `.ai/context.md` and `.ai/conventions.md` with your project code and prefix
4. Update all pipeline YAML files with your project code and variable group names

**Not sure where a component goes?** See [docs/component-placement-decision-tree.md](docs/component-placement-decision-tree.md).

---

## Quick Reference: PAC CLI Export Cycle

```bash
# Export and unpack a layer from Dev (repeat per layer)
pac solution export --name {ProjectCode}_Security --path ./exports/{ProjectCode}_Security.zip --managed false --overwrite true
pac solution unpack --zipfile ./exports/{ProjectCode}_Security.zip --folder ./solutions/{ProjectCode}_Security/src --packagetype Unmanaged --allowDelete true --allowWrite true --clobber true

# Review diff, commit, push, open PR
git diff
git add solutions/{ProjectCode}_Security/
git commit -m "feat(security): add Contributor role for asset management"
git push origin feature/my-branch
```

> `_Config` is never exported to this repository. See [LP-ALM.md](LP-ALM.md) Section 6.3 for the `_Config` protocol.

---

## Methodology Reference

The complete LP-ALM methodology is in [LP-ALM.md](LP-ALM.md). It covers:

1. Executive Summary
2. Layer Definitions (all five layers, with decision rules)
3. Security Architecture Rationale (NIST 800-53 mapping, GCC High requirements)
4. Publisher and Naming Conventions
5. Source Control Structure
6. PAC CLI Workflow
7. Azure DevOps Pipeline Architecture
8. Security Role Design Guidance
9. Environment Strategy
10. Onboarding Guide for New Teams
11. Methodology Positioning (how to present LP-ALM to executives, technical teams, and security officers)
12. Platform Prerequisites & Complementary Guidance (framework alignment, platform admin dependencies)

---

## Framework Alignment

LP-ALM is designed to sit **inside** Microsoft's broader platform governance frameworks, not alongside them. It governs what is inside a solution artifact and how it moves between environments. Platform-layer concerns — environment provisioning, DLP policies, monitoring, BCDR — are out of scope by design.

| Framework | Relationship to LP-ALM |
|---|---|
| [Power Platform Well-Architected](https://learn.microsoft.com/en-us/power-platform/well-architected/) | LP-ALM directly implements the **Security** and **Operational Excellence** pillars at the solution layer. Use Well-Architected to evaluate the full workload across all five pillars. |
| [Power Platform Landing Zones](https://github.com/microsoft/industry/tree/main/foundations/powerPlatform) | Landing Zones governs environment provisioning, DLP, and IAM. LP-ALM governs solution deployment within those environments. Both apply to enterprise deployments. |
| [Microsoft Power Platform CoE Starter Kit](https://learn.microsoft.com/en-us/power-platform/guidance/coe/starter-kit) | Compatible. CoE Starter Kit addresses tenant governance and citizen developer management. LP-ALM addresses pro-developer solution ALM. |

See [LP-ALM.md Section 12](LP-ALM.md#12-platform-prerequisites--complementary-guidance) for the full alignment mapping and recommended reading order.

---

*LP-ALM v1.0 | May 2026*

