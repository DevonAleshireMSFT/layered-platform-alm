---
layout: home
title: Home
nav_order: 1
description: "Layered Power Platform ALM — A security-first decomposition framework for Microsoft Power Platform"
permalink: /
---

# Layered Power Platform ALM
{: .fs-9 }

A security-first decomposition framework for Microsoft Power Platform in enterprise and government deployments.
{: .fs-6 .fw-300 }

[Read the Methodology]({{ site.baseurl }}/methodology/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/DevonAleshireMSFT/layered-platform-alm){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## What Is LP-ALM?

LP-ALM decomposes Power Platform solutions into five discrete, ordered deployment layers instead of a single monolithic solution. Each layer has a defined scope, deployment method, and dependency contract with the layers around it.

The result: smaller deployment blast radius, security controls that precede schema, zero secrets in source control, and independent team ownership of each layer.

---

## The Five Layers

| # | Layer | Purpose | Source Control | Pipeline |
|---|---|---|---|---|
| 1 | `_Security` | Security roles, field security profiles | ✅ | ✅ |
| 2 | `_Core` | All Dataverse schema — tables, columns, views, forms | ✅ | ✅ |
| 3 | `_Config` | Environment variable values | **Never** | **Never** |
| 4 | `_Automation` | Power Automate flows, connection references | ✅ | ✅ |
| 5 | `_UI` | Model-driven apps, canvas apps, site maps | ✅ | ✅ |

`_Config` is the controlled exception: it carries environment-specific values and is always deployed manually. It is permanently excluded from source control and pipelines — a zero-secrets-in-repo guarantee.

---

## Core Principles

**Security deploys first — always.**
Access control structures exist before any data schema is created. This is a structural control, not a process rule.

**`_UI` cannot introduce schema.**
Tables and columns belong in `_Core`. The PR validation pipeline enforces this with an automated schema contamination check.

**Managed solutions in upper environments.**
Test and Prod receive managed solutions only. Ad-hoc customization is blocked by the platform.

**Service accounts, not personal credentials.**
Connection references are bound to service accounts in every environment. Required for GCC High; best practice everywhere.

---

## NIST 800-53 Alignment

LP-ALM is designed for FedRAMP and GCC High deployments and maps directly to NIST 800-53 controls:

| Control | Implementation |
|---|---|
| AC-2 Account Management | Service principal application users per environment; no personal credentials |
| AC-3 Access Enforcement | `_Security` deploys before schema; managed solutions prevent unauthorized change |
| AC-6 Least Privilege | Per-persona security roles; pipeline SP uses System Administrator only where required (`prvWriteRole`) |
| CM-2 Baseline Configuration | Four committed layers are the authoritative baseline; `_Config` tracked in environment register |
| CM-3 Configuration Change Control | All changes via PR + pipeline; managed solutions block direct environment modification |
| SA-3 System Development Life Cycle | Structured Dev → Test → Prod lifecycle with independent layer sequencing and rollback |

---

## What's in This Repository

| Document | Description |
|---|---|
| [LP-ALM Methodology]({{ site.baseurl }}/methodology/) | Complete 11-section methodology reference |
| [Onboarding Checklist]({{ site.baseurl }}/onboarding/) | New team and new project setup steps |
| [Component Placement]({{ site.baseurl }}/component-placement/) | Decision tree: where does this component go? |
| [Security Role Matrix]({{ site.baseurl }}/security-roles/) | Privilege matrix template with Append/Append To guidance |
| [Environment Register]({{ site.baseurl }}/environment-register/) | Environment inventory template |

---

## Suitable For

- Enterprise Power Platform teams managing multi-environment deployments
- Government and regulated-industry projects (FedRAMP, CMMC, FISMA, HIPAA)
- Architects building repeatable delivery pipelines with Azure DevOps and PAC CLI
- Consulting teams needing a documented, defensible ALM methodology

LP-ALM is **not** appropriate for single-environment prototypes, citizen developer projects without a dedicated ALM team, or solutions that will never leave a development environment.
