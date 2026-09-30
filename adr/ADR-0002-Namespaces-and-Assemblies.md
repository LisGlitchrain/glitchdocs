---
title: ADR-0002-Namespaces-and-Assemblies
tags:
  - <project>-code
---

# ADR-0002 — Namespaces and Assemblies

**Status:** Accepted

**Date:** 2026-09-30

---

## Context

C# keeps namespaces, folders, and assemblies independent of each other. A file can declare any namespace wherever it is stored, and any folder can hold an assembly definition.

In Unity, an assembly definition decides how its code is compiled: for which platforms, with which references, and under which compilation symbols.

These choices matter to **<Project>** for several reasons:

* [ADR-0001](ADR-0001-AI-Friendly-Development-and-Forgiving-Architecture.md) divides the project into modules that must not depend on each other's internals. Namespaces and assembly references make those dependencies visible.
* Every assembly adds a definition file, a reference list to maintain, and a project in the IDE solution. Hundreds of small assemblies make the solution slow to load and hard to navigate.
* Editor tools and tests must never be compiled into a player build.
* Unity stores the full type name, including the namespace, in data serialized through `[SerializeReference]`. Changing the namespace of such a type breaks that data unless the previous name is declared.
* The engine already uses many names, such as `Editor`, `Object`, `Random`, and `Debug`. A project type or namespace with the same name forces every file that uses both to qualify one of them.

The code organization should:

* keep the number of assemblies proportional to real differences in compilation;
* keep editor and test code out of player builds;
* avoid names that collide with the framework the project is based on;
* keep serialized data valid when types move.

---

## Decision

The project will split assemblies only by compilation conditions, compile tests only under the `TESTS` symbol, and avoid names already used by the framework it is based on.

The namespace root, the relation between namespaces and folders, and the layout of editor test assemblies are decided separately in [ADR-0003](ADR-0003-Namespace-and-Test-Assembly-Layout.md).

### Assembly Boundaries

An **assembly** separates code that must be compiled under different conditions.

Conditions are:

* target platforms, such as editor only or all platforms;
* compilation symbols the code requires, such as `TESTS`;
* references available only under those conditions, such as the editor API or the test framework.

A module or Unity package has one assembly for each set of conditions its code needs. Code compiled under the same conditions belongs to the same assembly.

Folders, features, and layers inside a module must not get their own assemblies.

A typical module:

```text
<Module>/
├── Runtime/          all platforms
├── EditorScripts/    editor only
├── Tests/            editor only, requires TESTS
└── RuntimeTests/     all platforms, requires TESTS
```

Runtime tests have their own assembly because they are compiled for players as well as for the editor, unlike editor tests.

Whether editor tests share one assembly per module is decided in ADR-0003.

---

### Test Compilation

Every test assembly requires the `TESTS` compilation symbol. In Unity, the symbol is a define constraint of the assembly definition.

Without the symbol, tests are neither compiled nor listed by the test runner. Everyday editor sessions and player builds do not pay for test compilation.

The symbol is defined in every environment that runs tests: CI, and the editor of a developer who runs them.

---

### Name Collisions

New namespaces, types, and folders that become namespace segments must not reuse a name already used by the engine or framework the project is based on.

In Unity, editor code is placed in an `EditorScripts` folder, not `Editor`, because:

* a namespace segment named `Editor` hides the `UnityEditor.Editor` class, the base class of every custom inspector;
* a folder named `Editor` has a special compilation meaning in Unity, which the assembly definition already expresses.

Types follow the same rule: a project type must not be named `Random`, `Debug`, or `Object`.

A collision is accepted only when the framework or third-party module that introduces the name is added after the project code that uses it was written. The project code is not renamed for that reason alone. Files that use both names qualify one of them.

---

### Moving Types

When the namespace of a type changes, every reference to it is updated in the same change.

A type referenced through `[SerializeReference]` receives `[MovedFrom]` with its previous namespace, so that existing serialized data keeps loading.

---

## Consequences

### Advantages

* The number of assemblies grows with modules and their compilation conditions, not with features or folders.
* Editor and test code cannot reach a player build.
* Tests cost no compilation time unless they are requested.
* New code never needs to qualify its own names against framework names.
* Rules that rarely change are separated from choices that may be revisited, so revisiting a choice supersedes ADR-0003 without touching this record.

### Disadvantages

* Assemblies do not enforce layering inside a module. Only review and the module boundaries of ADR-0001 do.
* A change anywhere in an assembly recompiles the whole assembly.
* When `TESTS` is not defined, the test runner shows no tests instead of failing. An environment that runs tests without the symbol silently runs nothing.
* `EditorScripts` differs from the usual Unity convention, so examples, third-party code, and assistants default to `Editor`.
* The collision rule requires knowing which names the framework already uses.
* The full picture of namespaces and assemblies needs two records instead of one.

These trade-offs are acceptable because a small, predictable set of assemblies and unambiguous names keep the code cheap to navigate for people and assistants, while the costs stay local and visible in review.

---

## Alternatives Considered

### Assembly per Feature or Folder

Rejected.

Advantages:

* Smaller recompilation after a change.
* The compiler enforces layering inside a module.

Rejected because:

* the project grows to hundreds of assemblies, each with a reference list to maintain;
* the solution becomes slow to load and hard to navigate;
* boundaries inside a module are not the boundaries ADR-0001 relies on.

---

### Unity's Built-In Test Symbol

Rejected.

The Unity test framework defines `UNITY_INCLUDE_TESTS` on its own, so tests would be compiled in every editor session. An explicit `TESTS` symbol compiles them only when they are requested.

---

### Folder Named Editor

Rejected.

It is the usual Unity convention, but a namespace segment named `Editor` hides `UnityEditor.Editor`, and the folder's special compilation meaning duplicates what the assembly definition already expresses.

---

### One Record With Open Questions

Rejected.

Keeping the undecided choices in this record would prevent it from being accepted until every choice is made, and changing one choice later would supersede the stable rules together with it.

---

## Future Considerations

* Running tests in CI with `TESTS` defined, failing when no tests are found
