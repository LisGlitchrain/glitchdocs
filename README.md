# glitchdocs

A project-agnostic development harness: documentation rules, coding conventions, and architecture decisions for projects developed together with AI assistants.

## Goals

* Reuse the same documentation structure and development process across projects.
* Keep every document usable unchanged after the project name is substituted.
* Leave project-specific decisions explicitly open instead of guessing them.

## Contents

| File                                                                           | Purpose                                                                       |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| [Conventions.md](Conventions.md)                                               | One-sentence digest of the rules every task needs; tag `top-level`            |
| [DocumentationStyle.md](DocumentationStyle.md)                                 | How documentation is organized, tagged, and written; tag `documentation`      |
| [CodingStyle.md](CodingStyle.md)                                               | C# conventions for Rider or ReSharper, and testing rules; tag `code`          |
| [ADR-0001](adr/ADR-0001-AI-Friendly-Development-and-Forgiving-Architecture.md) | Modular architecture and documentation; accepted; tag `top-level`             |
| [ADR-0002](adr/ADR-0002-Namespaces-and-Assemblies.md)                          | Assembly boundaries, test compilation, name collisions; accepted; tag `code`  |
| [ADR-0003](adr/ADR-0003-Namespace-and-Test-Assembly-Layout.md)                 | Namespace and test assembly layout; proposed, with open questions; tag `code` |
| [combine-context.sh](combine-context.sh)                                       | Assembles tagged documents into one context bundle                            |

## Placeholders

* `<Project>` stands for the project name.
* `<project>` stands for its lowercase kebab-case slug, such as `yana-engine`. It prefixes every tag.

## Adopting in a Project

1. Copy the documents and `combine-context.sh` into the project's `docs/` directory. This README is not copied.
2. Replace `<Project>` and `<project>` in every document.
3. Create `.combine-context.conf` in the repository root with `docs/combine-context.sh --init`, and add the generated bundle to `.gitignore`.
4. Resolve the open questions of every `Proposed` ADR, such as ADR-0003, and have a person accept it. Accepted shared ADRs are kept unchanged.
5. Create the project documents listed below, and register the `code` and `documentation` tags in `Architecture.md` together with the module tags.
6. Keep the IDE settings, such as the `.sln.DotSettings` file, consistent with `CodingStyle.md`.

ADR numbers `0001` to `0099` are reserved for the ADRs of this repository. A project numbers its own ADRs from `0100`, so that new shared ADRs never collide with them.

## Project Documents

These documents are specific to each project and are written when it adopts the harness:

| Document          | Location        | Required | Contents                                                               |
| ----------------- | --------------- | -------- | ---------------------------------------------------------------------- |
| `README.md`       | Repository root | Yes      | The project's purpose, how to use it, how to build it, link to `docs/` |
| `Architecture.md` | `docs/`         | Yes      | Vision, modules, their tags, and their allowed dependencies            |
| `Roadmap.md`      | `docs/`         | No       | Milestones and future work                                             |

The project `README.md` replaces this one. It follows the README rules in [DocumentationStyle.md](DocumentationStyle.md).

`Roadmap.md` is useful for projects planned in milestones, but may be omitted. When it exists, it follows the Roadmap rules in [DocumentationStyle.md](DocumentationStyle.md).
