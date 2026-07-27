---
layout: default
title: Enterprise Strategy — GCC High / DoD
nav_order: 8
permalink: /enterprise-strategy/
---

# Enterprise Strategy — GCC High / DoD

The enterprise governance strategy for large-scale Power Platform deployments in U.S. federal and DoD environments is maintained in **[GovFLOW](https://devonaleshiremsft.github.io/gov-flow/)** — the Government Federated Low-Code Operations Framework.

[View the Full Enterprise Strategy →](https://devonaleshiremsft.github.io/gov-flow/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 }

---

## What Is GovFLOW?

GovFLOW (Government Federated Low-Code Operations Framework) is an enterprise governance framework purpose-built for Microsoft Power Platform deployments in U.S. federal and DoD environments. It addresses the operational realities that commercial guidance ignores: ATO requirements, personnel churn, CUI handling, GCC High / IL5 constraints, and the need for centralized standards with decentralized execution across commands and programs.

GovFLOW covers the full governance stack — from tenant strategy and environment topology to security architecture, maker governance, leadership reporting, and DevSecOps maturity — designed for Army, Navy, USMC, and similar large-agency scale.

**LP-ALM is the ALM methodology layer within GovFLOW.** It governs how solutions are structured, versioned, and deployed within the environments and governance model that GovFLOW defines. The two frameworks are designed to be used together.

---

## How LP-ALM and GovFLOW Relate

| GovFLOW Covers | LP-ALM Covers |
|---|---|
| Tenant and environment strategy | Solution decomposition into five layers |
| Security architecture, RBAC, DLP | Security role design within a solution |
| Governance board and intake process | ALM pipeline and source control structure |
| Maker governance and fusion team model | Multi-developer workflow and branch strategy |
| Leadership reporting and CoE tooling | Per-solution deployment and rollback |
| Azure integration and shared services | `_Integration` layer extension pattern |

Use GovFLOW to design and govern the platform. Use LP-ALM to build and deploy within it.

---

## Getting Started

If you are adopting LP-ALM as part of a government Power Platform program:

1. **Read [GovFLOW](https://devonaleshiremsft.github.io/gov-flow/)** — understand the environment strategy, governance model, and security architecture your program will operate within
2. **Read [LP-ALM Methodology]({{ site.baseurl }}/methodology/)** — understand how your solutions will be structured, deployed, and maintained
3. **Follow the [Onboarding Checklist]({{ site.baseurl }}/onboarding/)** — environment setup, pipeline configuration, and first deployment

---

## LP-ALM Tier Model for Government Delivery

LP-ALM uses tiers so programs can right-size physical solution layers without weakening
the government control floor.

| Tier | Required Solutions | Use When |
|---|---|---|
| Minimum | `{ProjectCode}_Security`, `{ProjectCode}_Core`, `{ProjectCode}_UI_Operations` | Small applications with no external integrations, no cross-boundary or CUI movement, and no privileged admin UI |
| Standard | Minimum + `{ProjectCode}_Automation` | Automation exists, but integrations are not shared, cross-boundary, or independently governed |
| Enterprise | Standard + warranted optional layers such as `{ProjectCode}_Integration`, `{ProjectCode}_UI_Admin`, reporting, or test data | CUI exchange, shared connection references, cross-system orchestration, separately governed integrations, or external ATO dependencies exist |

Every tier still requires `_Security` first, schema only in `_Core`, schema-free UI
solutions, managed-only Test and Prod, service-account or other approved non-personal
connection bindings, GCC High URLs ending in `.crm.microsoftdynamics.us`, and PAC
authentication using `--cloud UsGovHigh`.

---

## Tier Selection Requires Justification

Tier selection must be recorded before implementation as an ADR-style decision. The
record must identify the selected tier, facts supporting the decision, rejected
alternatives, and where evidence will be kept for audit review.

- **Minimum** is allowed only when there are no external integrations, no cross-boundary
  or CUI data movement, and no privileged admin UI.
- **Standard** applies when automation exists but integrations are not shared,
  cross-boundary, or independently governed.
- **Enterprise** is required when CUI exchange, shared connection references,
  cross-system orchestration, separately governed integrations, or external ATO
  dependencies exist.

This rule prevents teams from selecting a smaller tier to avoid governance. Smaller
tiers reduce empty solutions; they do not reduce required controls.

---

## Auditor Evidence Model

When `_Config` is not used as a mandated solution, configuration governance is proven
through linked non-secret evidence:

| Evidence | Purpose |
|---|---|
| Environment Configuration Register | Authoritative metadata record for CM-2, CM-3, and CM-6: logical name, environment, owner, required/optional status, secret classification, source variable name / Key Vault reference, approval/change reference, and last-reviewed date |
| Azure Key Vault / Azure DevOps audit logs | Evidence that values and secrets are stored, accessed, and changed through approved systems without exposing raw values in source control |
| Approval and change records | Evidence of authorized configuration changes and tier decisions |
| Deployment run history | Evidence that managed solutions were deployed to Test and Prod through approved Azure DevOps pipelines and Config Gate checks |

The evidence model stores metadata and references only. It must never include client
secrets, passwords, API keys, connection strings, tenant secrets, or raw environment
variable values.

---

*LP-ALM is part of the [GovFLOW](https://devonaleshiremsft.github.io/gov-flow/) ecosystem.*
