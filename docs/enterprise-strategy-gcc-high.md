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

*LP-ALM is part of the [GovFLOW](https://devonaleshiremsft.github.io/gov-flow/) ecosystem.*
