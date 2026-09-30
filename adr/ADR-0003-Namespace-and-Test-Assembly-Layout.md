---
title: ADR-0003-Namespace-and-Test-Assembly-Layout
tags:
  - <project>-code
---

# ADR-0003 — Namespace and Test Assembly Layout

**Status:** Proposed

**Date:** 2026-09-30

---

## Context

[ADR-0002](ADR-0002-Namespaces-and-Assemblies.md) decides how **<Project>** splits assemblies, compiles tests, and avoids framework names. It leaves three choices to this record:

* how every namespace starts;
* whether namespaces follow the folder path;
* whether editor tests share one assembly per module.

The constraints from ADR-0002 that apply here:

* Assemblies separate only code compiled under different conditions. A module has at most one assembly per set of conditions.
* Runtime tests always have their own assembly.
* Editor code is placed in `EditorScripts`, and no name may collide with a name of the framework.

A namespace is how a reader locates a type. When it follows a predictable rule, a file can be found from a `using` directive without an IDE, including inside a context bundle.

The layout should:

* make the owning module visible in every type's full name;
* let a reader find a file from its namespace without an IDE;
* keep moving a file within a module cheap;
* be checked by the IDE inspection, not by review.

---

## Decision

(To be decided.)

The chosen options from Open Questions are stated here, one `###` subsection per question.

---

## Open Questions

Each question lists its options. When a question is resolved, the chosen option moves to Decision, and the other options move to Alternatives Considered with the reasons they were not chosen.

### Question 1 — Namespace Root

> "Does every namespace start with the project name, or with the module or package name?"

The chosen form is the **root namespace** of a module, referred to as `<Root>` below.

#### Option A — Project Prefix

Namespaces start with `<Project>.<Module>`, such as `Example.Timing`.

Advantages:

* Project namespaces never collide with the namespaces of the framework or third-party packages.
* All project code sorts together in the IDE and in `using` directives.

Disadvantages:

* Every namespace is longer.
* A module or package shared with another project carries the name of the project it came from, or is renamed when it moves.

#### Option B — Module or Package Prefix

Namespaces start with the module or package name, such as `Timing`.

Advantages:

* Names are shorter.
* A module or package moves between projects without renaming.

Disadvantages:

* Module names are more likely to collide with the namespaces of the framework or third-party packages, which the Name Collisions rule of ADR-0002 then forbids.
* Nothing in a name distinguishes project code from third-party code.

---

### Question 2 — Namespaces and Folders

> "Does the namespace follow the folder path?"

#### Option A — Root Namespace Plus Folder Segments

Every type is declared in its module's `<Root>`, followed by one segment per folder inside the module:

```text
<Module>/Runtime/Countdown.cs                     <Root>
<Module>/Runtime/Scheduling/FrameScheduler.cs     <Root>.Scheduling
<Module>/Tests/TestCountdown.cs                   <Root>
```

Folders that hold an assembly definition or group files by kind, such as `Runtime`, `EditorScripts`, `Tests`, `RuntimeTests`, and `Scripts`, do not add a segment. They are marked as not being namespace providers in the solution settings.

The `CheckNamespace` inspection is enabled with severity `WARNING`.

Advantages:

* A file can be found from its namespace without an IDE, including by an assistant reading a context bundle.
* The inspection reports mismatches automatically.

Disadvantages:

* Moving a file to another folder changes its namespace and every `using` directive that refers to it.
* The list of folders that are not namespace providers must be maintained.

#### Option B — One Namespace per Module

All types of a module are declared directly in its `<Root>`.

Advantages:

* Moving a file inside a module never changes its namespace.
* The rule needs no settings.

Disadvantages:

* Large modules end up with one flat namespace and more name collisions inside it.
* Inside a module, a file cannot be located from its namespace.

#### Option C — Namespace Independent of Folders

Namespaces start with `<Root>`. Below it, segments are chosen freely.

Advantages:

* Files move freely without touching any other file.
* Related types stored in different folders may share a namespace.

Disadvantages:

* A file cannot be located from its namespace.
* Nothing keeps namespaces consistent as the project grows.
* The `CheckNamespace` inspection stays disabled.

---

### Question 3 — Editor Test Assemblies

> "Do the editor tests of a module share one assembly, or does each tested assembly get its own?"

#### Option A — Common Test Assembly

A module or Unity package has a single common assembly for all its editor tests, next to the assembly for runtime tests:

```text
<Module>/
├── Tests/            tests for Runtime and EditorScripts
└── RuntimeTests/     runtime tests
```

Advantages:

* It follows the Assembly Boundaries rule of ADR-0002: all editor tests are compiled under the same conditions.
* Fewer assemblies. Shared fakes and fixtures live in one place.

Disadvantages:

* The test assembly references every assembly of the module, including editor code, so tests of runtime code may accidentally depend on the editor API.
* A compile error in any test blocks all editor tests of the module.

#### Option B — Test Assembly per Tested Assembly

Each production assembly has its own test assembly:

```text
<Module>/
├── Tests/                  tests for Runtime
├── EditorScriptsTests/     tests for EditorScripts
└── RuntimeTests/           runtime tests
```

Advantages:

* The test structure mirrors the production structure.
* Each test assembly references only the assembly it tests.

Disadvantages:

* It is an exception to the Assembly Boundaries rule of ADR-0002: `Tests` and `EditorScriptsTests` are compiled under the same conditions.
* More assemblies. Fakes shared by both test assemblies need another assembly or are duplicated.

---

## Consequences

(To be filled when the open questions are resolved.)

### Advantages

(To be decided.)

### Disadvantages

(To be decided.)

---

## Alternatives Considered

### Namespace Matches the Full Folder Path

Rejected.

Assembly and grouping folders would appear in every name, such as `Assets.Scripts.Runtime.Timing`.

---

## Future Considerations

* Migration of existing code to the chosen namespace layout, one module per change
* Running the namespace inspection in CI
