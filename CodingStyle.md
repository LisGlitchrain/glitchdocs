---
title: CodingStyle
tags:
  - <project>-code
---

# Coding Style

## Goals

This document defines the C# source code conventions and the testing rules for **<Project>**.

The conventions should:

* make every file readable without the IDE;
* keep a predictable member order, so that people and AI assistants find members without searching;
* keep diffs small, so that formatting never hides a behavioural change;
* be enforced by the formatter and inspections, not by review comments.

The formatter and inspection settings are stored in the solution `.sln.DotSettings` file and are applied by Rider or ReSharper. That file is the executable form of this document. When the two disagree, the disagreement is a defect and is fixed in the same change.

Documentation conventions are defined separately in [DocumentationStyle.md](DocumentationStyle.md).

---

## Naming

### Rules

| Element                                  | Style                  | Example                     |
| ---------------------------------------- | ---------------------- | --------------------------- |
| Types, methods, properties, events       | `PascalCase`           | `ScoreBoard`, `Reset()`     |
| Private instance fields                  | `m_` + `PascalCase`    | `m_Elapsed`                 |
| Private static fields                    | `m_` + `PascalCase`    | `m_Instance`                |
| Serialized fields                        | `m_` + `PascalCase`    | `m_SpinDuration`            |
| Non-private fields                       | `m_` + `PascalCase`    | `m_Offset`                  |
| Constants, any access level              | `UPPER_SNAKE_CASE`     | `MAX_PLAYERS`               |
| Static readonly fields used as constants | `UPPER_SNAKE_CASE`     | `DEFAULT_COLOR`             |
| Enum members                             | `UPPER_SNAKE_CASE`     | `State.WAITING_FOR_BET`     |
| Parameters                               | `_` + `PascalCase`     | `_Duration`, `_Player`      |
| Local variables                          | `camelCase`            | `elapsedTime`               |
| Local constants                          | `camelCase`            | `retryCount`                |

The prefixes make the origin of every name visible at the use site:

* `m_` is a member of the type;
* `_` is a parameter of the current method;
* no prefix is a local variable, a property, or a type.

Preferred style:

```csharp
void SetDuration(float _Duration)
{
    float clamped = Math.Max(_Duration, MIN_DURATION);
    m_Duration = clamped;
}
```

Avoid:

```csharp
void SetDuration(float duration)
{
    var clamped = Math.Max(duration, minDuration);
    this.duration = clamped;
}
```

Readonly fields may use either `m_PascalCase` or `UPPER_SNAKE_CASE`. `UPPER_SNAKE_CASE` is used only when the field acts as a constant that cannot be declared `const`, such as a static readonly `Color` or array.

Non-private fields accept plain `PascalCase` as well, but new code should expose properties instead of non-private fields.

---

### Abbreviations

Abbreviations stay uppercase inside identifiers: `UIRoot`, `PlayerID`, `JSONParser`, `LoadURL`.

The list of recognized abbreviations is kept in the IDE settings. An abbreviation is added there before it is first used in an identifier, so that the naming inspection does not flag it.

Naming rules are not auto-detected from existing code. The configured rules are the only source.

---

### Framework Names

New types, namespaces, and folders must not reuse names already used by the engine or framework, such as `Random`, `Debug`, or `Editor`. Editor code is placed in an `EditorScripts` folder.

The rule and its only exception are defined in [ADR-0002](adr/ADR-0002-Namespaces-and-Assemblies.md).

---

## Types and Declarations

### Explicit Types

`var` is not used. Every local variable declares its type, for built-in, simple, and all other types.

Object creation names the type even when the declared type makes it evident. Target-typed `new()` is not used.

Bad:

```csharp
var players = new List<Player>();
List<Player> winners = new();
```

Good:

```csharp
List<Player> players = new List<Player>();
List<Player> winners = new List<Player>();
```

Reasons:

* The type is readable in a diff, in a code review tool, and inside a context bundle, where no IDE shows inferred types.
* One form for every declaration removes a style decision.

---

### Default Modifiers

Default access modifiers are omitted. `private` and `internal` are implied, not written.

Bad:

```csharp
private int m_Count;
internal class Wheel
```

Good:

```csharp
int m_Count;
class Wheel
```

Non-default modifiers, such as `public`, `protected`, and `sealed`, are always written.

---

### Named Constants

Magic numbers are not used. A value with a meaning is a named constant, and the name states the meaning.

Values that are repeated and mean the same thing are one constant. Changing that value then changes every use at once, and no use can be forgotten.

Bad:

```csharp
paddingLeft   = 8;
paddingRight  = 8;
paddingTop    = 8;
paddingBottom = 8;
```

Good:

```csharp
const int PADDING = 8;

paddingLeft   = PADDING;
paddingRight  = PADDING;
paddingTop    = PADDING;
paddingBottom = PADDING;
```

Values that are equal by coincidence are separate constants, because they change for different reasons:

```csharp
const int PADDING     = 8;
const int MAX_RETRIES = 8;
```

`0` and `1` used as a start index, an increment, or an identity value, such as `count + 1` or `sum = 0`, are not magic numbers.

---

### Namespaces

Namespaces use block-scoped bodies. File-scoped namespaces are reported as an error.

```csharp
namespace Example.Timing
{
    class Countdown
    {
    }
}
```

The namespace root and how namespaces follow folders are decided in [ADR-0003](adr/ADR-0003-Namespace-and-Test-Assembly-Layout.md).

---

## File Layout

### Member Order

Members are grouped into `#region` blocks in a fixed order. The IDE's **Reorder members** action removes existing regions, except generated ones, and rebuilds them in this order:

| Order | Region            | Contents                                                              |
| ----- | ----------------- | --------------------------------------------------------------------- |
| 1     | `factory methods` | Public static `Create` or `Instantiate` methods                       |
| 2     | `nested types`    | Nested classes, structs, and enums                                    |
| 3     | `constants`       | Constants                                                             |
| 4     | `events`          | Events                                                                |
| 5     | `attributes`      | Fields of any kind                                                    |
| 6     | `properties`      | Properties and indexers                                               |
| 7     | `construction`    | Constructors                                                          |
| 8     | `IDisposable`     | `Dispose` and other `IDisposable` members                             |
| 9     | `engine methods`  | Engine lifecycle methods and `DoAwake`, `DoStart`, `DoEnable`, `DoDisable`, `DoDestroy` |
| 10    | `public methods`  | Public instance methods                                               |
| 11    | `service methods` | All other instance methods                                            |
| 12    | `static methods`  | Remaining static methods                                              |

The `attributes` region holds fields. The name is historical and does not refer to C# attributes.

Empty regions are not written.

Example:

```csharp
namespace Example.Timing
{
    public sealed class Countdown : IDisposable
    {
        #region factory methods

        public static Countdown Create(float _Duration)
        {
            return new Countdown(_Duration);
        }

        #endregion

        #region constants

        const float MIN_DURATION = 0.1f;

        #endregion

        #region events

        public event Action Finished;

        #endregion

        #region attributes

        float m_Duration;
        float m_Elapsed;
        bool  m_Disposed;

        #endregion

        #region properties

        public bool IsRunning { get; private set; }

        #endregion

        #region construction

        Countdown(float _Duration)
        {
            m_Duration = Math.Max(_Duration, MIN_DURATION);
        }

        #endregion

        #region IDisposable

        public void Dispose()
        {
            m_Disposed = true;
            Finished   = null;
        }

        #endregion

        #region public methods

        public void Start()
        {
            m_Elapsed = 0f;
            IsRunning = true;
        }

        public void Tick(float _DeltaTime)
        {
            if (m_Disposed || !IsRunning)
                return;

            m_Elapsed += _DeltaTime;

            if (m_Elapsed >= m_Duration)
                Finish();
        }

        #endregion

        #region service methods

        void Finish()
        {
            IsRunning = false;
            Finished?.Invoke();
        }

        #endregion
    }
}
```

---

### Region Templates

Live templates insert each region by its name: typing `#region public methods` inserts an empty `public methods` region, or wraps the selected code in it.

---

### Observable Properties

Bindable layout properties use a backing field and `SetProperty`, which assigns the value and raises the change notification only when the value changes. The `propb` live template produces this form:

```csharp
float m_Spacing;
public float Spacing
{
    get => m_Spacing;
    set => SetProperty(ref m_Spacing, value);
}
```

---

## Formatting

### Indentation

* Indentation uses spaces.
* Preprocessor directives are indented with the surrounding code.
* Comments are indented with the surrounding code, including comments that start in the first column.

---

### Line Length and Wrapping

The line length limit is 200 characters.

Argument lists, parameter lists, and call chains stay on one line while they fit. When they do not, every element moves to its own line: the list breaks after the opening parenthesis and before the closing one.

```csharp
Result result = m_Service.Submit(
    _Request,
    _Timeout,
    _CancellationToken
);
```

A long call chain places each call on its own line, aligned under the first call.

---

### Embedded Statements

The body of `if`, `else`, `for`, `foreach`, and `while` is never placed on the same line as its header.

Bad:

```csharp
if (m_Disposed) return;
```

Good:

```csharp
if (m_Disposed)
    return;
```

An attribute on a property accessor is also placed on its own line.

---

### Alignment

Adjacent similar lines are aligned into columns. This applies to:

* field, property, and local variable declarations;
* assignments;
* method parameters and multi-line arguments;
* switch sections, nested ternary expressions, binary expressions, tuple components, and LINQ queries.

```csharp
int    m_Count;
string m_Title;
float  m_Speed;

m_Count       = 0;
m_Title       = _Title;
m_MaxDuration = _MaxDuration;
```

The formatter maintains the alignment. It is not edited by hand.

Adding a longer name realigns the whole block, which widens the diff. The alignment is kept because it makes groups of related declarations easier to scan.

---

### Spacing

* A space follows a cast: `(int) _Value`.
* Single-line array initializers have spaces inside the braces: `int[] steps = { 1, 2, 4 };`.

---

## Tests

### Philosophy

A test states the behaviour that a module promises through its public interface.

Tests make the forgiving architecture of [ADR-0001](adr/ADR-0001-AI-Friendly-Development-and-Forgiving-Architecture.md) safe to use: an implementation behind an interface can be replaced only when tests prove that the replacement keeps the same contract.

Tests are part of the change they verify. They are written or updated in the same change as the code, and reviewed with it.

---

### Required Tests

A change must include tests when it:

* adds or changes behaviour visible through a module's public interface;
* introduces an interface placed around an uncertain decision;
* fixes a bug. The test fails before the fix and passes after it.

A change may omit tests only when it does not change behaviour, such as a rename, a formatting change, or a documentation change. The reason is stated in the change description.

---

### Contract Tests

Every interface introduced to isolate an uncertain decision has a contract test fixture.

The fixture is abstract and creates its subject through a factory method. Every implementation of the interface has a derived fixture, so all implementations are verified against the same tests.

```csharp
abstract class TestSchedulerContract
{
    #region public methods

    [Test]
    public void Submit_TaskIsRun_WhenTickPasses()
    {
        IScheduler scheduler = CreateSubject();
        bool       wasRun    = false;

        scheduler.Submit(() => wasRun = true);
        scheduler.Tick();

        Assert.That(wasRun, Is.True);
    }

    #endregion

    #region service methods

    protected abstract IScheduler CreateSubject();

    #endregion
}

sealed class TestFrameScheduler : TestSchedulerContract
{
    #region service methods

    protected override IScheduler CreateSubject()
    {
        return new FrameScheduler();
    }

    #endregion
}
```

A new implementation is accepted when its derived fixture passes. No existing test is changed to make it pass.

---

### Test Boundaries

Tests must use only the public interface of the module under test.

Tests must not:

* use `InternalsVisibleTo` or reflection to reach private or internal members;
* depend on the internals of another module;
* depend on wall-clock time, real randomness, the network, or the file system outside a temporary directory.

Time, random number generation, and external services are passed in through interfaces, so that tests replace them with deterministic fakes. Random number generators receive a fixed seed.

---

### Organization

* Editor tests may share a single common test assembly per module or Unity package, or use one test assembly per tested assembly. The choice is made in [ADR-0003](adr/ADR-0003-Namespace-and-Test-Assembly-Layout.md).
* Runtime tests always have their own assembly, because they are compiled for players as well as for the editor.
* Test assemblies are compiled only when the `TESTS` compilation symbol is defined. Without it, tests are neither built nor listed by the test runner. See [ADR-0002](adr/ADR-0002-Namespaces-and-Assemblies.md).
* Editor tests are preferred over runtime tests. Runtime tests are slower and are used only when the behaviour depends on the engine lifecycle.
* A test class is named after its subject with the `Test` prefix: `TestCountdown`. Test classes then sort together and are never confused with their subjects in search results.
* A test method is named `<Member>_<Expected>_<Condition>`: `Tick_RaisesFinished_WhenDurationElapses`.
* Test classes follow the same naming and file layout rules as production code, except for test method names.

The method naming inspection reports underscores in test method names. These warnings are accepted in test assemblies and are not suppressed one by one. Every other naming warning in a test file is fixed as in production code.

---

### Test Structure

* A test verifies one behaviour.
* The arrange, act, and assert steps are separated by blank lines. Comments naming the steps are not needed.
* Assertions use the NUnit constraint model: `Assert.That(actual, Is.EqualTo(expected))`.
* Test data that matters to the outcome is written inside the test. Shared setup is limited to creating the subject and its fakes.
* Play mode tests wait on conditions or frames, not on fixed durations.

Bad:

```csharp
[Test]
public void Test1()
{
    Countdown countdown = Countdown.Create(1f);
    countdown.Start();
    countdown.Tick(0.5f);
    Assert.IsTrue(countdown.IsRunning);
    countdown.Tick(0.5f);
    Assert.IsFalse(countdown.IsRunning);
}
```

Good:

```csharp
[Test]
public void Tick_StopsRunning_WhenDurationElapses()
{
    Countdown countdown = Countdown.Create(1f);
    countdown.Start();

    countdown.Tick(1f);

    Assert.That(countdown.IsRunning, Is.False);
}
```

---

### Running Tests

Tests are run locally before a change is submitted for review.

(To be decided: running tests in CI and blocking merges on failure.)

---

## Guiding Principle

Code should read the same regardless of who, or what, wrote it.

The formatter owns layout, the naming rules own identifiers, and tests own behaviour, so that review can focus on whether the change is right.
