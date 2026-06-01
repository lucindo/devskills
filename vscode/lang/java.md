### Java

- `record` for immutable data; `sealed` types with exhaustive `switch` pattern matching; `var` for obvious locals.
- Never swallow exceptions; preserve the cause (`new AppException("ctx", e)`). Catch the most specific type.
- Close `AutoCloseable` with try-with-resources. Virtual threads for I/O-bound fan-out; every blocking call has a timeout.
- JUnit 5 with `@ParameterizedTest`; `assertThrows` for error paths; no `Thread.sleep` in tests.
