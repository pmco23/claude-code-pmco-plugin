# Testing Anti-Patterns

Five patterns that undermine TDD benefits even when tests are present.

---

## 1. Testing Mock Behaviour Instead of Real Behaviour

**What it looks like:** A test mocks a dependency and then asserts that the mock was called with specific arguments. The assertion proves the mock was called — it proves nothing about what the production code actually does with the result.

**Why it fails:** If the production code passes the wrong argument to a real implementation, the mock still passes. The test survives a regression it was supposed to catch.

**Fix:** Test the output of the unit under test, not the inputs it passes to its collaborators. Mock collaborators only to control their return values — never assert on how the mock was called unless the call itself is the behaviour under test (e.g., event publication).

---

## 2. Test-Only Methods Polluting Production Code

**What it looks like:** A method is added to a production class solely to make it testable: `getInternalState()`, `resetForTest()`, `setPrivateField()`. The method is never called in production.

**Why it fails:** The production API now carries dead code that exists only to satisfy tests. It signals the design is wrong — if internal state must be exposed for testing, the unit is doing too much or the boundary is in the wrong place.

**Fix:** Refactor the design so the behaviour is testable through the public interface. Extract the logic that needs testing into a smaller, focused unit with its own public API.

---

## 3. Mocking Without Understanding the Dependency Chain

**What it looks like:** A collaborator is mocked, but the mock does not reflect the real collaborator's contract. The mocked return value is a simplified or incorrect version of what the real dependency returns.

**Why it fails:** Tests pass in isolation. In integration, the real dependency returns a different shape, a different error type, or a different sequence — and the production code breaks in ways the tests never exercised.

**Fix:** Before mocking a dependency, read its actual interface. Confirm the return type, error cases, and field names. If the dependency is external (a library or API), use its real test utilities or a contract test instead of a hand-rolled mock.

---

## 4. Incomplete Mocks With Missing Fields

**What it looks like:** A mock object is created with only the fields the test author needed at the time: `{ id: 1, name: "Alice" }`. The production code is later updated to read a new field (`email`) — but the mock is not updated. The test passes because the code path using `email` is never reached in the mocked context.

**Why it fails:** The test stops exercising the real code path. It becomes a false negative — passing when the feature is broken.

**Fix:** Keep mock objects complete. When the real type gains a field, update all mocks that use that type. Use typed mock factories or builder helpers so the compiler or type checker enforces completeness.

---

## 5. Integration Tests Added After Implementation

**What it looks like:** Unit tests are written test-first, but integration tests (database, network, file system) are added at the end of the task — or skipped entirely because the feature "already has unit tests".

**Why it fails:** Unit tests verify logic in isolation. Integration tests verify that the pieces work together across boundaries. A system can have 100% unit-test coverage and completely fail at the integration seam (wrong SQL, wrong HTTP status handling, wrong file encoding).

**Fix:** Identify integration seams during planning (Task N.1). Write integration test stubs at the same time as unit tests. The stubs fail (RED) until the integration layer is implemented. Treat integration test coverage as a first-class acceptance criterion, not an afterthought.
