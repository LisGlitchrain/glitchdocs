---
title: ADR-0001-AI-Friendly-Development-and-Forgiving-Architecture
tags:
  - <project>-top-level
---

# ADR-0001 — AI-Friendly Development and Forgiving Architecture

**Status:** Accepted

**Date:** 2026-09-11

---

## Context

**<Project>** is developed with AI assistants as regular participants. They read documentation, write code, and draft documents.

An AI assistant works within a limited context. It knows only what the current session provides.

This creates two opposite risks:

* with too little context, the assistant invents constraints or re-decides settled questions;
* with all documentation loaded, relevant constraints are diluted by unrelated ones, sessions become slower and more expensive, and the approach stops scaling as the project grows.

The project is also expected to make architectural mistakes.

It is long-term and evolving. Some early decisions will prove incomplete or wrong, whether they were made by a person or suggested by an assistant.

Both problems have the same remedy: boundaries.

A part of the system that can be understood from its own documentation is cheap to load into context.

A part of the system that is isolated behind an explicit interface is cheap to replace.

The architecture and the documentation should therefore:

* divide the project into modules that can be understood and changed independently;
* keep the cost of a wrong decision local to the module where it was made;
* let the context for any task be assembled from a small, predictable set of documents;
* record decisions so that neither people nor assistants re-decide them unknowingly.

---

## Decision

**<Project>** adopts a **forgiving architecture** and **modular documentation** that follows the same boundaries.

Together they allow any task to be completed with partial knowledge of the project.

### Modules

The project is divided into **modules**.

A module has:

* one responsibility;
* an explicit public interface;
* declared dependencies that point in one direction;
* its own documentation and its own tag.

A module must not depend on the internals of another module.

Dependency cycles between modules are not allowed.

The list of modules, their tags, and their allowed dependencies is maintained in `Architecture.md`.

---

### Forgiving Architecture

A **forgiving architecture** is one in which a wrong decision is cheap to correct.

It is achieved by:

* separating what work is needed from how, when, and by whom it is performed;
* placing interfaces where uncertainty is highest, so that the uncertain part can be replaced without changing its users;
* preferring a simple implementation behind a stable boundary over a sophisticated implementation without one;
* replacing a failed implementation instead of patching its consequences across the codebase.

Example:

```text
Poor scheduler implementation
        ↓
replace the scheduler
        ↓
modules keep submitting the same work
```

Forgiving does not mean abstract everywhere.

An interface is introduced where a decision is uncertain or likely to change, not around every class. Stable, well-understood code stays direct.

---

### Modular Documentation

Documentation is divided along the same boundaries as the code.

Every document in `docs/` starts with front matter containing its `title` and `tags`:

```markdown
---
title: ADR-0007-Renderer-Frame-Graph
tags:
  - <project>-renderer
---
```

Tags identify the module or concern a document belongs to. Documents that every task needs carry `<project>-top-level`.

The context for a task is assembled from tags:

```text
<project>-top-level      project-wide principles and conventions
        +
<project>-<module>       the module being changed
        ↓
context bundle
```

The top-level documents and the documents of one module must be sufficient to work on that module.

When they are not, the module boundary or its documentation is incomplete, and fixing it is part of the task.

The rules for front matter, tags, and writing documents that remain understandable inside a bundle are defined in [DocumentationStyle.md](../DocumentationStyle.md), tagged `<project>-documentation`.

---

### One Source for People and Assistants

People and AI assistants read the same documents.

There is no separate AI-only documentation.

Tool-specific entry files, such as `CLAUDE.md` or `AGENTS.md`, may exist. They point to the documentation and describe how to assemble context, but they contain no architectural decisions or conventions of their own.

---

### Recorded Decisions

Every architectural decision is recorded as an ADR, including the alternatives that were rejected.

Rejected alternatives are part of the context an assistant receives. They record which "improvements" were already considered and why they were not adopted.

---

### Ownership of Decisions

AI assistants may propose changes, write code, and draft ADRs.

A person owns every decision:

* an ADR becomes `Accepted` only when a person accepts it;
* every change is reviewed by a person before it is merged.

Changes made with an assistant follow the same workflow as any other change: small, focused, one issue per change, with documentation updated in the same change.

---

## Consequences

### Advantages

* The context for a task is small, focused, and predictable.
* Assistants receive the constraints that apply to their task and few that do not.
* Settled decisions are less likely to be re-decided.
* Architectural mistakes remain local and can be corrected by replacing one module.
* Modules can be developed in parallel by different people or assistant sessions.
* New contributors can start with one module instead of the whole project.
* One structure keeps both the code and the documentation modular.

### Disadvantages

* Interfaces add indirection and some initial implementation cost.
* A boundary placed in the wrong location is itself expensive to move.
* Front matter and tags must be maintained. A missing or misspelled tag silently hides a document.
* Self-contained documents require short restatements of constraints defined elsewhere.
* Deciding what belongs in top-level context requires ongoing judgement.
* Human review limits how much change assistants can contribute.

These trade-offs are acceptable because the cost of indirection is predictable, while the cost of an unrecoverable architectural mistake, or of an assistant working from the wrong context, is not.

---

## Alternatives Considered

### Load All Documentation Into Every Session

Rejected.

It is simple while the project is small, but its cost grows with every document, and the constraints that matter are diluted by those that do not.

---

### Semantic Search Instead of Tags

Deferred.

Advantages:

* No manual tagging.
* Finds relevant documents that were not tagged for the task.

Deferred because:

* results are not deterministic;
* the selection cannot be reviewed in a diff;
* it requires additional infrastructure.

Explicit tags are sufficient for now. Semantic search may later be added on top of them.

---

### Separate Documentation Written for AI

Rejected.

A second set of documents duplicates the first and drifts from it. Assistants would then work from a description of the project that people no longer read.

---

### Design the Architecture Correctly Up Front

Rejected.

The project is evolving and partly exploratory. Mistakes are expected, and the architecture must make them affordable rather than assume they will not happen.

---

### Abstract Every Component

Rejected.

Interfaces everywhere make the code harder to read and navigate, for people and assistants alike. Boundaries are placed where uncertainty justifies them.

---

## Future Considerations

* Validation of front matter and registered tags in CI
* A size budget for top-level context
* Automated checks that module dependencies follow the declared direction
* A generated index of tags and the documents they select

---

## Decision Summary

**<Project>** is built so that any task can be completed with partial knowledge of the project.

* Code is divided into modules with explicit interfaces and one-directional dependencies.
* Interfaces are placed where decisions are uncertain, so that mistakes stay local.
* Documentation follows module boundaries and is selected by front matter tags.
* Top-level context plus the documents of one module is enough to work on that module.
* People and assistants share one set of documents; people own the decisions.
