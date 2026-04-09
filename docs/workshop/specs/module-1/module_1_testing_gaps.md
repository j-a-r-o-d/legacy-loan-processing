# Module 1 Testing Gaps: Credit Evaluation Extraction

## User Story Context

> **As a developer, I want the extracted `CreditEvaluationService` to produce identical results to `sp_EvaluateCredit`, so that the migration introduces no regressions in credit or risk decisions.**

This directly maps to **Requirement 8: Maintain Behavioral Equivalence** from the Module 1 requirements spec. The acceptance criteria require that for all valid loan applications, the C# service produces the same RiskScore, DTI ratio, Recommendation, and InterestRate as the stored procedure for identical inputs. Meeting this requirement is the primary condition for customer confidence in the extraction.

---

## Overall Assessment

**Current coverage: approximately 40–50% of what a financial services migration requires.**

The pure calculation layer is reasonably tested. The orchestration layer, boundary conditions, and behavioral equivalence between the old and new code paths are not.

---

## What Is Currently Tested

### Property-Based Tests (`LoanProcessing.Tests/Properties/CreditEvaluationPropertyTests.cs`)
Five FsCheck properties with 100 iterations each covering `CreditEvaluationCalculator` static methods:

| Property | What It Covers |
|---|---|
| `DtiRatio_MatchesFormula` | DTI formula correctness over randomized inputs |
| `CreditScoreComponent_MapsToCorrectBracket` | Credit score bracket mapping [300, 850] |
| `DtiComponent_MapsToCorrectBracket` | DTI bracket mapping [0, 200] |
| `RiskScore_InRangeAndEqualsComponentSum` | Risk score clamped to [0, 100] |
| `Recommendation_ClassifiesCorrectly` | All three recommendation strings reachable |

### Integration Tests (`LoanProcessing.Web/Validation/Tests/`)
Four coarse behavioral tests run against a live database:

| Test | Input | Assertion |
|---|---|---|
| `TestHighCreditScore` | CreditScore=780 | `RiskScore <= 40` |
| `TestLowCreditScore` | CreditScore=550 | `RiskScore > 60` |
| `TestDebtToIncomeRatio` | Customer with prior approved loans | `DTI > 0` |
| `TestCreditEvaluation` (in `LoanProcessingTests`) | $25,000 / 36 months | `RiskScore` in [0,100], `Comments` non-empty |

---

## Gap 1: No Shadow / Parallel Run Tests

**Severity: Critical**
**Requirement: 8.1, 8.2, 8.3, 8.4**

There is no test that executes both `sp_EvaluateCredit` and `CreditEvaluationService.Evaluate` on the same inputs and compares their outputs. The design document specifies this as Property 7 but it was never implemented.

The existing integration tests only exercise the new C# path. They establish that the service *runs* but do not prove it is *equivalent* to the stored procedure. For a customer audience, this is the weakest point in the evidential chain: you cannot yet say "we ran both on the same data and they agreed."

**What needs to be built:** A test that, for a set of representative loan profiles, calls both paths and asserts identical `RiskScore`, `DebtToIncomeRatio`, `Recommendation`, and `InterestRate` on every case.

---

## Gap 2: Decimal Precision Divergence — Latent Behavioral Bug

**Severity: High**
**Requirement: 8.2, 8.3**

The stored procedure declares `@DebtToIncomeRatio DECIMAL(5,2)`, which rounds to two decimal places before applying recommendation thresholds. `CreditEvaluationCalculator.CalculateDtiRatio` returns a full-precision `decimal` with no rounding applied.

**Concrete example of divergence:**

| Scenario | SP Value | C# Value | SP Decision | C# Decision |
|---|---|---|---|---|
| DTI = 35.004 | 35.00 (rounded) | 35.004 | Recommended for Approval | Manual Review Required |
| DTI = 43.004 | 43.00 (rounded) | 43.004 | Manual Review Required | High Risk - Recommend Rejection |

These are not contrived edge cases — they occur naturally on moderate-income borrowers requesting amounts near the threshold. No currently existing test would catch this divergence.

**What needs to be built:** Either apply `Math.Round(dti, 2)` in `CalculateDtiRatio` to match SQL Server behavior, or add an explicit test proving that the precision difference cannot change a recommendation outcome.

---

## Gap 3: Threshold Boundary Values Not Deterministically Tested

**Severity: High**
**Requirement: 8.1, 8.3**

The approval thresholds controlling who gets approved, sent to manual review, or rejected are never tested with exact boundary values. These are the highest-stakes lines in the codebase.

| Boundary | Controls | Currently Tested? |
|---|---|---|
| CreditScore = 750 | Component 10 vs 20 | No (random sampling only) |
| CreditScore = 700 | Component 20 vs 35 | No (random sampling only) |
| CreditScore = 650 | Component 35 vs 50 | No (random sampling only) |
| CreditScore = 600 | Component 50 vs 75 | No (random sampling only) |
| DTI = 20.0 vs 20.01 | DTI component 0 vs 10 | No |
| DTI = 35.0 vs 35.01 | DTI component 10 vs 20; Recommendation switch | No |
| DTI = 43.0 vs 43.01 | DTI component 20 vs 30; Recommendation switch | No |
| RiskScore = 30 vs 31 | Approval vs Manual Review | No |
| RiskScore = 50 vs 51 | Manual Review vs Rejection | No |

The property tests use `Gen.Choose(300, 850)` and `Gen.Choose(0, 200)` — integer generators. Fractional DTI values near boundaries (e.g., 35.001) are never generated, and exact threshold values are hit only by chance, without shrinking to them on failure.

**What needs to be built:** Named, deterministic unit tests for every row in the table above, asserting the exact output at the boundary and one unit above/below it.

---

## Gap 4: Planned Unit Test Files Were Never Created

**Severity: High**
**Requirement: 2.1–2.4, 3.1–3.3, 4.1–4.3**

The design document specifies a `LoanProcessing.Tests/Unit/` directory with three files. None of them exist — the directory itself does not exist.

| Planned File | Purpose | Status |
|---|---|---|
| `Unit/CreditEvaluationCalculatorTests.cs` | Deterministic boundary tests for all calculator methods | Not created |
| `Unit/CreditEvaluationServiceTests.cs` | Orchestration layer tests with mocked repositories | Not created |
| `Unit/InterestRateLookupTests.cs` | Rate lookup correctness: multiple matches, expired rates, no-match fallback | Not created |

The `InterestRateLookupTests.cs` absence is especially notable. The rate lookup is the most complex query in the service — matching on loan type, credit score range, term range, and effective/expiration dates, with a tiebreak on most recent effective date. It has no test coverage at all.

**What needs to be built:** All three files per the design spec. `InterestRateLookupTests.cs` is highest priority given complexity.

---

## Gap 5: Interest Rate Lookup Has Zero Test Coverage

**Severity: High**
**Requirement: 3.1, 3.2, 3.3**

Design document Properties 6 and 7 are specified but not implemented. The `GetRateByCriteria` method — which embodies Requirement 3 in its entirety — has no tests of any kind.

Untested scenarios:

- Multiple rates match; most recent `EffectiveDate` should win
- A rate with a past `ExpirationDate` is present; must be excluded
- A rate for a different `LoanType` is present; must be excluded
- A rate where credit score is outside `[MinCreditScore, MaxCreditScore]`; must be excluded
- No matching rate exists; default 12.99% must be returned
- `DateTime.Now` vs SQL `GETDATE()` — the service passes `DateTime.Now` (line 68 of `CreditEvaluationService.cs`) but there is no clock abstraction, making time-sensitive tests unreliable at midnight or on systems with clock skew

**What needs to be built:** `InterestRateLookupTests.cs` with at least one named test per bullet point above, using an in-memory or test-database rate table.

---

## Gap 6: Application State After Evaluation Not Verified

**Severity: Medium**
**Requirement: 5.1, 5.2**

Requirement 5 states that after a successful evaluation, the loan application must be updated with status `"UnderReview"` and the determined `InterestRate`. No test verifies these side effects.

The integration tests assert only the returned `LoanDecision` object. If `UpdateStatusAndRate` were silently removed or contained a bug that updated only one of the two fields, all existing tests would still pass.

**What needs to be built:** A test that reads the loan application record from the database after calling `Evaluate()` and asserts `Status == "UnderReview"` and `InterestRate == expectedRate`.

---

## Gap 7: Error Paths Are Coded but Untested

**Severity: Medium**
**Requirement: 1.4, 6.3**

`CreditEvaluationService.Evaluate` has four defensive guard clauses (lines 38–51). All are coded correctly. None are tested.

| Guard | Condition | Exception Thrown | Test Exists? |
|---|---|---|---|
| Line 38 | `applicationId <= 0` | `ArgumentException` | No |
| Line 42 | Application not found | `InvalidOperationException` | No |
| Line 46 | Customer not found | `InvalidOperationException` | No |
| Line 51 | `AnnualIncome <= 0` | `InvalidOperationException` | No |

**What needs to be built:** Four unit tests in `CreditEvaluationServiceTests.cs`, one per guard, asserting the correct exception type and that no database write occurred.

---

## Gap 8: Integration Tests Are Fragile

**Severity: Low**
**Requirement: 8.5**

All three `CreditEvaluationTests` depend on `CustomerBusinessTests.LastCreatedCustomerId` being populated by a prior test in the same run. A failure in the customer creation test causes all credit evaluation tests to fail with a setup error, not a credit evaluation failure. This produces misleading results in CI pipelines.

**What needs to be built:** Each credit evaluation integration test should own its own customer setup (create + teardown), making it independently runnable and failure-isolating.

---

## Summary of Gaps by Priority

| Priority | Gap | Requirement(s) | Effort |
|---|---|---|---|
| P0 | Shadow/parallel run test (SP vs C# comparison) | 8.1–8.4 | Medium |
| P0 | Decimal precision divergence fix or proof | 8.2, 8.3 | Low |
| P1 | Boundary value unit tests for all thresholds | 2.1–2.4, 4.1–4.3 | Medium |
| P1 | `InterestRateLookupTests.cs` | 3.1–3.3 | Medium |
| P1 | `CreditEvaluationServiceTests.cs` with mocked repos | 1.1–1.4 | Medium |
| P2 | Application state persistence test | 5.1, 5.2 | Low |
| P2 | Error path unit tests | 1.4, 6.3 | Low |
| P3 | Decouple integration test setup from prior tests | 8.5 | Low |

---

## Recommended Acceptance Gate Before Customer Sign-Off

The following must all pass before claiming behavioral equivalence to `sp_EvaluateCredit`:

1. Shadow run test shows zero divergence across all representative loan profiles
2. Decimal precision behavior is documented and tested at both sides of every DTI threshold
3. Every threshold boundary has a named, deterministic test case
4. `GetRateByCriteria` has test coverage for all selection and exclusion rules
5. `UpdateStatusAndRate` persistence is verified by reading back the database record
6. All four error paths have tests asserting the correct exception type
