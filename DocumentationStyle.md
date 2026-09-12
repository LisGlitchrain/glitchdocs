---
title: DocumentationStyle
tags:
  - <project>-documentation
---

# Documentation Style

## Purpose

This document defines how documentation is organized, written, and maintained.

It is project-agnostic. It can be copied into the `docs/` directory of any repository; `<Project>` stands for the project name and `<project>` for its lowercase kebab-case slug, such as `yana-engine`.

The reasons behind this organization are recorded in [ADR-0001 — AI-Friendly Development and Forgiving Architecture](adr/ADR-0001-AI-Friendly-Development-and-Forgiving-Architecture.md).

This document follows its own rules.

---

## Principles

* Documentation is part of the project, not an afterthought.
* Documentation grows together with the implementation and is updated in the same change.
* Record **why**, not only **what**.
* Every trade-off is written down, including the disadvantages.
* Decisions are deliberate but not permanent.
* History is preserved: decisions are superseded, never silently rewritten.
* Future work is named explicitly and deferred until it becomes necessary.
* Non-goals are stated as clearly as goals.
* Documentation is modular like the code: a task needs only the documents of the modules it touches.
* People and AI assistants read the same documents. There is no separate AI-only documentation.
* Each document has one scope and links to other documents instead of repeating them.
* Documents are written for a new contributor, for an AI assistant with partial context, and for the author's future self.

---

## Layout

```text
README.md                        Entry point: what the project is, how to build it
.combine-context.conf            Project settings for context assembly
docs/
├── combine-context.sh           Context assembly script, identical in every project
├── Architecture.md              Vision, modules, tags, high-level structure
├── CodingStyle.md               Source code conventions
├── DocumentationStyle.md        This document
├── Philosophy.md                Goals and guiding preferences
├── Roadmap.md                   Milestones and future work
├── adr/
│   ├── ArchitectureDecisionRecords.md
│   └── ADR-NNNN-<Subject>.md    Architecture Decision Records
└── guides/
    └── <Topic>.md               How to work on the project
```

Every document belongs to exactly one category:

| Category        | Location        | Answers                                     | Lifetime             | Front matter | Record fields |
| --------------- | --------------- | ------------------------------------------- | -------------------- | ------------ | ------------- |
| README          | Repository root | What is this and how is it built?           | Living               | None         | None          |
| Reference       | `docs/`         | What is the project and what are its rules? | Living               | Required     | None          |
| Guide           | `docs/guides/`  | How is work done on the project?            | Living               | Required     | None          |
| Decision record | `docs/adr/`     | Why was this chosen?                        | Frozen once accepted | Required     | Required      |

New categories should not be introduced unless an existing one clearly cannot hold the content.

---

## File Naming

* Document names use PascalCase: `CodingStyle.md`, `DevelopmentEnvironment.md`.
* Acronyms stay uppercase and are joined to the next word with a hyphen: `VCS-Workflow.md`.
* ADR names use a zero-padded four-digit number followed by the Title Case subject, words separated by hyphens: `ADR-0002-Build-System.md`.
* The file name matches the H1 title: `CodingStyle.md` → `# Coding Style`.
* The file name without `.md` is the front matter `title`.
* `README.md` is the only exception to PascalCase.

---

## Document Structure

### Title and Headings

* Every document in `docs/` starts with front matter. The first line after it is the document's only H1.
* Major sections use `##`, subsections use `###`. Levels are never skipped.
* Headings use Title Case.
* Numbered or labelled headings separate the label from the name with an em dash: `## Milestone 1 — Development Environment`, `### Layer 1 — Generic Time Utilities`.

### Opening Section

Every document frames its scope before any detail.

| Category        | Opening                                     |
| --------------- | ------------------------------------------- |
| Reference       | `## Vision`, `## Goals`, or `## Philosophy` |
| Guide           | `## Purpose`                                |
| Decision record | Record fields, then `## Context`            |

A guide's Purpose starts with:

```text
This document describes <subject> for **<Project>**.
```

### Closing Section

Guides end with the principle that ties them together, under `## Philosophy` or `## Guiding Principle`.

It is one or two short paragraphs describing the intended outcome, not a summary of the sections above.

### Separators

* A horizontal rule `---` separates every `##` section.
* A horizontal rule also separates sibling `###` blocks that are independent entries, such as alternatives or component responsibilities.
* A horizontal rule is always preceded and followed by a blank line. Without the blank line above, Markdown turns the previous line into a heading.
* The two `---` lines of the front matter are delimiters, not separators.

### Placeholders

Unfinished sections stay visible with an explicit placeholder in parentheses instead of being omitted.

Examples:

```text
(To be decided.)

(To be filled as <Project> evolves.)
```

A placeholder may list the open options as questions.

---

## Metadata

Documents carry two kinds of metadata for two kinds of readers:

| Kind          | Reader                        | Location                | Documents                 |
| ------------- | ----------------------------- | ----------------------- | ------------------------- |
| Front matter  | Tools and AI context assembly | YAML block on line 1    | Every document in `docs/` |
| Record fields | People                        | Bold lines below the H1 | Decision records          |

The two never duplicate each other. Information a reader needs is never placed only in front matter, because most Markdown viewers hide it.

### Front Matter

```markdown
---
title: ADR-0003-Top-Level-Structure
tags:
  - <project>-top-level
  - <project>-application
---

# ADR-0003 — Top-Level Structure
```

Rules:

* The opening `---` is the first line of the file. Nothing precedes it: no blank line, no comment, no byte-order mark. Tools recognize front matter only on line 1.
* The closing `---` is followed by a blank line and the H1.
* The keys are `title` and `tags`, in this order. Both are required.
* Other keys are added only when a tool reads them.

### Title

* `title` is the file name without `.md`: `CodingStyle`, `VCS-Workflow`, `ADR-0002-Build-System`.
* It is unique across the documentation and changes only when the file is renamed.

### Tag Syntax

* `tags` is a block list: one tag per line, indented by two spaces, introduced by `- `.
* Tags are lowercase kebab-case.
* Every tag starts with the project slug: `<project>-`. The prefix keeps tags unique when the documentation of several projects or libraries is combined.
* Inline lists and tags in HTML comments are not used, even where tooling accepts them. A single form keeps every tag findable with a plain text search for `- <project>-<tag>`.

### Tag Vocabulary

| Tag                   | Selects                                                                                       |
| --------------------- | --------------------------------------------------------------------------------------------- |
| `<project>-top-level` | Context needed for any task: vision, philosophy, conventions, decisions that span all modules |
| `<project>-<module>`  | Documents needed to work inside one module                                                    |
| `<project>-<concern>` | A cross-cutting concern that spans modules, such as threading or documentation                |
| `<project>-archive`   | Inactive decision records                                                                     |

The list of module and concern tags is kept in `Architecture.md`, next to the module structure. A tag is added there before it is first used.

### Tagging Rules

* Every document has at least one tag. An untagged document is invisible to context assembly.
* A document is tagged for the tasks that need it, not for every topic it mentions.
* A document may carry several tags. A decision about the boundary between two modules carries both module tags.
* `<project>-top-level` is kept small. It is included in every context bundle, so every document tagged with it costs context in every task.
* When a decision record becomes `Rejected`, `Deprecated`, or `Superseded`, its tags are replaced with `<project>-archive`. Bundles then contain only current decisions, while the history remains selectable on purpose.

### Record Fields

Decision records carry visible bold key–value lines directly below the H1. They render identically in every Markdown viewer and read as part of the document.

```markdown
# ADR-0005 — Asset Pipeline

**Status:** Accepted

**Date:** 2026-08-02

---
```

Rules:

* The key and its colon are bold together: `**Status:**`, followed by one space and the value.
* Each field is a separate paragraph, separated by a blank line. Consecutive lines without a blank line render as a single line.
* Fields appear in the order listed below.
* The block ends with `---`.
* Dates use ISO 8601: `YYYY-MM-DD`.

| Field           | Required        | Value                                             |
| --------------- | --------------- | ------------------------------------------------- |
| `Status`        | Yes             | One of the statuses below                         |
| `Date`          | Yes             | Date the decision was recorded; not changed later |
| `Supersedes`    | When applicable | Link to the ADR this record replaces              |
| `Superseded by` | When applicable | Link to the ADR that replaces this record         |

### Statuses

| Status       | Meaning                                             |
| ------------ | --------------------------------------------------- |
| `Proposed`   | Under discussion. The body may change freely.       |
| `Accepted`   | The current decision. The body is frozen.           |
| `Rejected`   | Considered and not adopted. Kept for its reasoning. |
| `Deprecated` | No longer applies and has no replacement.           |
| `Superseded` | Replaced by a newer ADR named in `Superseded by`.   |

A record becomes `Accepted` only when a person accepts it. An AI assistant may draft a record, but it stays `Proposed` until then.

### Changing a Decision

The body of an accepted ADR is not rewritten.

Allowed edits are limited to typo fixes, broken links, record fields, and front matter.

A changed decision is recorded as a new ADR that names the old one in `Supersedes`. The old ADR receives `Status: Superseded`, a `Superseded by` link, and the `<project>-archive` tag.

---

## Context Assembly

Tags exist so that a working context can be assembled from only the documents a task needs.

```text
<project>-top-level      always
        +
<project>-<module>       the module being changed
        +
<project>-<concern>      when the task touches it
        ↓
context bundle
```

### Tooling

Bundles are produced by `docs/combine-context.sh`.

The script is copied between projects unchanged. Project-specific settings, such as the project name, the tag prefix, and the output file, live in `.combine-context.conf` in the repository root. It is created once per project:

```bash
docs/combine-context.sh --init
```

A bundle for work on one module:

```bash
docs/combine-context.sh --tag top-level --tag renderer
```

A tag passed without the project prefix also matches its prefixed form, so `renderer` selects documents tagged `<project>-renderer`.

The generated bundle is a build artifact and is listed in `.gitignore`. The config file is committed.

### Writing for Assembly

A document inside a bundle is read without the documents around it.

* The top-level documents and the documents of one module are sufficient to work on that module. When they are not, the module boundary or its documentation is incomplete, and fixing it is part of the task.
* Each document names the project and the module explicitly instead of writing "this module" or "the system above".
* References use stable identifiers such as file names and ADR numbers, never "the previous ADR", "the new approach", or "recently".
* When a document depends on a constraint defined elsewhere, it states the constraint in one sentence and links to the source for the reasoning. This is the only accepted repetition.
* Terms are defined in the document that introduces them or in a top-level document.
* One document covers one module or one concern, so that bundles stay small.

---

## Decision Records

### Numbering and Titles

* Numbers are sequential, start at `0001`, and are never reused, even for rejected records.
* The title is `# ADR-NNNN — <Subject>`, with an em dash.
* The subject names the problem area, not the outcome: `Build System`, not `Use CMake`.

### Sections

Required, in this order:

1. `## Context`
2. `## Decision`
3. `## Consequences`
4. `## Alternatives Considered`

Optional:

* `## Rationale` — after Decision, when the reasons are not obvious. Subsections may be phrased as questions: `### Why not a global static Time class?`
* Topic sections — after Decision, for major aspects of the decision: `## Live Editing and Reload`.
* `## Evolution Policy` — how and when the decision may be revisited.
* `## Future Considerations` — after Consequences or Alternatives, for directions the decision leaves open.
* `## Decision Summary` — at the end of long records: one sentence and a short recap list.
* `## Notes` — always last.

### Context

Context explains why a decision is needed now and what it affects.

Requirements are written as a continuation list:

```markdown
The build system should:

* support multiple compilers;
* integrate well with modern IDEs;
* remain maintainable for many years.
```

Context may compare how other projects solve the same problem.

### Decision

* The section opens with a direct statement: "The project will use **CMake** as its build system."
* Each concept is a `###` subsection. Its name is bold where it is first defined: "The **Host** is the executable entry point."
* Responsibilities are listed after "It is responsible for:".
* Boundaries are stated as `must not` rules: "The Engine must not depend on editor code."
* Concrete examples follow: a directory tree, a code snippet, a naming pattern.
* The question a component answers may be quoted as a blockquote:

```markdown
> "How much time elapsed since this timer started?"
```

### Consequences

```markdown
## Consequences

### Advantages

* Clear separation of responsibilities.

### Disadvantages

* Some folders remain empty during early development.

These trade-offs are acceptable for a long-term project.
```

* Both lists are always present. A decision without disadvantages has not been examined.
* The section ends with a sentence that explicitly weighs the trade-offs.

### Alternatives Considered

Each alternative is a `###` subsection named after the option, separated from the next by `---`.

It starts with a one-word verdict paragraph:

* `Rejected.`
* `Deferred.` — may be adopted later.

The reason follows in one or two short paragraphs. An alternative with real merit lists its advantages first, followed by a `Rejected because:` list.

Rejected alternatives are part of the context an assistant receives. They record which "improvements" were already considered and why they were not adopted.

---

## Reference Documents

### Architecture

Opens with `## Vision`: what the project is, its goals, and one explicit non-goal.

Follows with `## Design Principles` as a list of short imperative statements, then the high-level structure as a text diagram.

Lists every module with its tag and its allowed dependencies.

Decisions are not duplicated here. The document links to the relevant ADRs.

### Roadmap

Opens with `## Philosophy`: how milestones are sized.

Each milestone is a `## Milestone N — <Name>` section containing a list of deliverables. Every milestone leaves the project in a working state.

A final `## Future` section lists work that is planned but not scheduled.

### Style Documents

Open with `## Goals`, then one section per topic.

Rules are demonstrated with paired examples labelled `Bad:` and `Good:`, or `Preferred style:` and `Avoid:`.

### README

Kept short: a one-sentence description, goals, target platforms, requirements, build commands, and a link to `docs/`.

Build commands are shown in a `bash` fence.

The README has no front matter, because repository hosts render it as the landing page.

---

## Writing Style

### Voice

* Declarative and impersonal: "The project uses", "The Engine owns".
* Present tense describes the current state. `will` describes decided work that is not implemented yet.
* Readability is preferred over completeness.

### Normative Words

| Word                   | Meaning                                          |
| ---------------------- | ------------------------------------------------ |
| `must`, `must not`     | Hard rule. A violation is a defect.              |
| `should`, `should not` | Default expectation. A deviation needs a reason. |
| `may`                  | Allowed and optional.                            |
| `prefer X over Y`      | Tie-breaker when both options are acceptable.    |

### Paragraphs

* One idea per paragraph, usually one to three sentences.
* Single-sentence paragraphs are normal.
* The key statement comes first; reasons follow.

### Emphasis

* **Bold** marks the project name in Purpose, a concept at its definition, the chosen option in a Decision, and rare critical words: "explain **why**, not **what**".
* Bold is never applied to a whole paragraph.
* Italics are not used.
* `Inline code` marks everything literal: file and directory names, identifiers, commands, flags, branch names, tags, and configuration keys.

### Lists

The bullet marker is `*`.

Lists are introduced by a sentence ending with a colon or by a label line: `Examples:`, `Reasons:`, `Guidelines:`, `Advantages:`.

Two forms are used:

* **Continuation lists** complete the introducing sentence. Items are lowercase, end with `;`, and the last item ends with `.`.
* **Standalone lists** contain independent items. Items are capitalized. Sentence items end with `.`; term items have no terminal punctuation.

Examples:

```markdown
The structure should:

* separate engine code from applications;
* remain easy to navigate.

Reasons:

* Excellent diagnostics
* First-class tooling
```

Numbered lists are used only when order matters, such as a sequence of steps.

### Code Blocks

* Every fence has a language tag.
* `text` is used for directory trees, diagrams, naming patterns, and lists of names or messages.
* Code uses its language: `cpp`, `cmake`, `json`, `yaml`.
* Shell commands use `bash`, without a `$` prompt.
* Snippets are minimal and show one idea.

### Diagrams

Diagrams are plain text inside `text` fences. They render everywhere, need no image files, diff cleanly, and remain readable inside a context bundle.

Hierarchies use box-drawing characters:

```text
Engine
│
├── Core
├── Platform
└── Renderer
```

Flows are vertical:

```text
Compiler
    ↓
Static analysis
    ↓
Debugger
```

### Tables

Tables are used for items with two or more attributes, such as a tool and its purpose.

Columns are padded so that the table is readable in source form.

Tables are not used for prose.

### Cross-References

A topic is documented in one place. Other documents link to it with a relative Markdown link:

```markdown
General conventions are described separately in [CodingStyle.md](CodingStyle.md).

See [ADR-0003](adr/ADR-0003-Top-Level-Structure.md).
```

### Encoding

* Files are UTF-8 with LF line endings and a final newline.
* Unicode is used where it improves reading: `—`, `→`, `↓`, `├──`.

---

## Templates

### Guide

````markdown
---
title: <FileName>
tags:
  - <project>-<module-or-concern>
---

# <Title>

## Purpose

This document describes <subject> for **<Project>**.

<Scope, or the primary choice, in one or two sentences.>

---

## Philosophy

<The rule behind everything in this guide.>

---

## <Topic>

<Policy or choice.>

Reasons:

* <Reason>

---

## Future <Topic>

<Intentionally deferred items.>

These will be introduced only when they become necessary.

---

## Guiding Principle

<The intended outcome.>
````

### Decision Record

````markdown
---
title: ADR-NNNN-<Subject>
tags:
  - <project>-<module-or-concern>
---

# ADR-NNNN — <Subject>

**Status:** Proposed

**Date:** YYYY-MM-DD

---

## Context

<Why is a decision needed now? What does it affect?>

The <solution> should:

* <requirement>;
* <requirement>.

---

## Decision

The project will <decision>.

---

## Rationale

<Optional. Why this option was chosen.>

---

## Consequences

### Advantages

* <Benefit>.

### Disadvantages

* <Cost>.

These trade-offs are acceptable because <reason>.

---

## Alternatives Considered

### <Option>

Rejected.

<Reason.>

---

## Future Considerations

<Optional. Directions this decision leaves open.>
````

---

## Checklist

Before a documentation change is merged:

* [ ] Front matter starts on line 1, `title` equals the file name, and every tag is registered in `Architecture.md`.
* [ ] `<project>-top-level` is used only for documents every task needs.
* [ ] The file name matches the only H1.
* [ ] The document opens with its framing section.
* [ ] `##` sections are separated by `---`.
* [ ] Decision records have record fields `Status` and `Date`, one field per paragraph.
* [ ] Decision records list disadvantages and alternatives.
* [ ] Accepted decision records are unchanged; changed decisions are new records, and inactive records are tagged `<project>-archive`.
* [ ] The document is understandable inside a context bundle, without the documents it links to.
* [ ] Every code fence has a language tag.
* [ ] Related documents are linked, not duplicated.
* [ ] Unfinished sections have an explicit placeholder.

---

## Guiding Principle

A reader, human or AI, should be able to open any document months or years later, with only the context its tags provide, and understand what was decided, why it was decided, and what it cost.
