---
title: Conventions
tags:
  - <project>-top-level
---

# Conventions

## Goals

This document lists the rules every task on **<Project>** needs, one sentence each, with a link to the document that defines them and explains why.

It keeps the context included in every task small. The full rules are selected by concern tags only when a task touches them.

When a rule here and its source disagree, the source is correct, and this document is fixed in the same change.

---

## Context Assembly

| Tag                       | Included when                                                   |
| ------------------------- | --------------------------------------------------------------- |
| `<project>-top-level`     | Always                                                          |
| `<project>-<module>`      | The task changes that module                                    |
| `<project>-code`          | The task changes source code                                    |
| `<project>-documentation` | The task creates or restructures documents, or drafts an ADR    |

A bundle for a code change in one module:

```bash
docs/combine-context.sh --tag top-level --tag code --tag renderer
```

A code task that only updates existing documents needs no `<project>-documentation` bundle. The rules below are sufficient for it.

---

## Architecture

Defined in [ADR-0001](adr/ADR-0001-AI-Friendly-Development-and-Forgiving-Architecture.md).

* The project is divided into modules, each with one responsibility, an explicit public interface, and one-directional dependencies.
* A module must not depend on the internals of another module, and dependency cycles between modules are not allowed.
* Interfaces are placed where a decision is uncertain or likely to change, not around every class.
* The modules, their tags, and their allowed dependencies are listed in `Architecture.md`.
* The top-level documents, the concern documents a task touches, and the documents of one module are sufficient to work on that module. When they are not, fixing them is part of the task.

---

## Changes and Decisions

Defined in [ADR-0001](adr/ADR-0001-AI-Friendly-Development-and-Forgiving-Architecture.md) and [DocumentationStyle.md](DocumentationStyle.md).

* Every change is small, focused, covers one issue, and is reviewed by a person before it is merged.
* Documentation is updated in the same change as the code it describes.
* Every architectural decision is recorded as an ADR, including the alternatives that were rejected.
* Rejected alternatives record which improvements were already considered and why they were not adopted.
* An ADR becomes `Accepted` only when a person accepts it. An assistant's draft stays `Proposed`.
* The body of an accepted ADR is not rewritten. A changed decision is a new ADR that supersedes the old one.
* ADR numbers `0001` to `0099` are reserved for shared records. Project records start at `0100`.

---

## Documents

Defined in [DocumentationStyle.md](DocumentationStyle.md).

* Every document in `docs/` starts on line 1 with front matter containing `title`, equal to the file name without `.md`, and `tags`.
* Tags are lowercase kebab-case, start with `<project>-`, are written as a block list, and are registered in `Architecture.md` before first use.
* A document is read inside a bundle without its neighbours, so it names the project and the module explicitly.
* References use file names and ADR numbers, never "the previous ADR", "the new approach", or "recently".
* A constraint defined elsewhere is restated in one sentence with a link to its source. This is the only accepted repetition.
* One document covers one module or one concern.
* Unfinished sections keep an explicit placeholder, such as `(To be decided.)`.
* Headings use Title Case, `##` sections are separated by `---`, and every code fence has a language tag.
* Diagrams are plain text inside `text` fences.

---

## Code

Defined in [CodingStyle.md](CodingStyle.md), [ADR-0002](adr/ADR-0002-Namespaces-and-Assemblies.md), and [ADR-0003](adr/ADR-0003-Namespace-and-Test-Assembly-Layout.md).

* Fields use `m_PascalCase`, parameters use `_PascalCase`, constants and enum members use `UPPER_SNAKE_CASE`, and local variables use `camelCase`.
* `var` and target-typed `new()` are not used.
* The default access modifiers `private` and `internal` are omitted.
* Namespaces use block-scoped bodies. Their root and their relation to folders are decided in ADR-0003.
* Members are grouped into `#region` blocks in the fixed order defined in CodingStyle.md.
* The body of `if`, `else`, `for`, `foreach`, and `while` never shares a line with its header.
* The formatter owns alignment and wrapping. The line length limit is 200 characters.
* An assembly separates only code compiled under different conditions, such as editor-only code or tests.
* New names must not collide with names of the engine or framework. Unity editor code is placed in `EditorScripts`.
* A type referenced through `[SerializeReference]` receives `[MovedFrom]` when its namespace changes.

---

## Tests

Defined in [CodingStyle.md](CodingStyle.md) and [ADR-0002](adr/ADR-0002-Namespaces-and-Assemblies.md).

* A change includes tests when it changes behaviour visible through a public interface, introduces an interface around an uncertain decision, or fixes a bug.
* A bug fix includes a test that fails before the fix.
* Tests use only the public interface of the module under test.
* Time, randomness, and external services are passed in through interfaces and replaced with deterministic fakes in tests.
* Test classes are named `Test<Subject>`. Test methods are named `<Member>_<Expected>_<Condition>`.
* Test assemblies are compiled only when the `TESTS` symbol is defined. Runtime tests have their own assembly.
