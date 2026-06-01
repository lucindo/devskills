## Language Profile — Java

Target: Java 21+ (LTS). Backend services, APIs, CLIs, systems tooling.

Apply these conventions to all Java code in this session.

### Toolchain

Build with Maven or Gradle — whichever the repo already uses; don't introduce a second build tool. Test with JUnit 5 (`mvn test` / `gradle test`). Format with a standard formatter (`google-java-format` via the Spotless plugin, or the build's configured one) and keep it wired into the build. Static analysis with `Error Prone` and/or the IDE/`javac -Xlint:all` warnings; treat warnings as errors where the project allows.

### Project Layout

Standard `src/main/java` / `src/test/java` source roots with the package tree mirrored under each. One public top-level type per file. Package by feature, not by layer (`orders/` over `services/` + `dtos/`); avoid `util`/`common`/`helpers` grab-bag packages. Keep packages cohesive and depend inward.

### Language & Idioms

- `record` for immutable data carriers; `sealed` interfaces/classes with exhaustive `switch` pattern matching for closed type hierarchies. Prefer `switch` expressions over statement chains.
- `var` for local variables where the type is obvious from the right-hand side; spell out the type when it aids readability.
- Favor immutability: `final` fields, unmodifiable collections (`List.of`, `Map.of`, `Collectors.toUnmodifiableList`). Don't expose internal mutable collections.
- Streams for transformation pipelines, but keep them readable — a plain loop beats a contorted stream. No side effects inside `map`/`filter`.
- `Optional` as a return type for "maybe absent"; never as a field or method parameter, and never call `.get()` without a presence check.

### Error Handling

- Checked exceptions for recoverable conditions the caller must handle; unchecked for programming errors. Don't wrap everything in `RuntimeException` to dodge the compiler.
- Never swallow an exception — no empty `catch` blocks. Preserve the cause: `throw new AppException("context", e)`. Don't log-and-rethrow the same exception at every layer.
- Catch the most specific exception type; never `catch (Exception e)` (or `Throwable`) as a catch-all unless re-raising.

### Resources & Concurrency

- Always close resources with try-with-resources; never rely on manual `finally` for `AutoCloseable`.
- Prefer the `java.util.concurrent` high-level constructs (`ExecutorService`, `CompletableFuture`, concurrent collections) over raw `Thread` and `synchronized`/`wait`/`notify`.
- Use virtual threads (`Executors.newVirtualThreadPerTaskExecutor()`) for I/O-bound fan-out; don't pool virtual threads. Every blocking call has a timeout.
- Guard shared mutable state explicitly; prefer immutable objects and `java.util.concurrent.atomic` over locks where possible.

### Testing

- JUnit 5 with `@ParameterizedTest` for input variants instead of copy-pasted cases; AssertJ (or the project's assertion library) for fluent, readable assertions.
- No real network or filesystem in unit tests — use fakes/mocks (Mockito where it fits) and JUnit's `@TempDir`. Assert on behavior through the public API.
- Test error paths with `assertThrows`, not just the happy path. No `Thread.sleep` to coordinate tests — await on latches/futures with a bounded timeout.

### Tiger Style

- Non-trivial methods validate their preconditions (`Objects.requireNonNull`, guard clauses, or `assert` for internal invariants); don't assert in trivial getters or thin wrappers.
- All loops over external input have explicit bounds; no unbounded recursion without provable termination.
- Keep methods under 70 lines; refactor past that without being asked.
