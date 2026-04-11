# Module 1: Business Logic Extraction (Strangler Pattern)

## 1. Overview

### What You Will Accomplish

In this module, you will extract the credit evaluation business logic from the `sp_EvaluateCredit` SQL Server stored procedure into the .NET service layer using the strangler pattern. You will use Kiro's spec-driven development workflow to plan, implement, and validate the extraction — then fast-forward the remaining stored procedure extractions using pre-built code. By the end, all business logic lives in testable C# code, and the database is reduced to a pure data store.

### Why This Matters

- Business logic locked in stored procedures can't be unit tested, can't run without SQL Server, and can't be exposed as an API or agent tool
- After extraction, the same logic is testable, database-agnostic, and shaped like a future microservice or AI agent tool
- The validation framework proves nothing broke — zero regressions across the entire application

### Estimated Time

60–90 minutes

### Tools Used

- Kiro (spec-driven development, AI-assisted code generation)
- Validation Test Framework (built into the application)

---

## 2. Prerequisites

### Expected Starting State

- EC2 Windows Server instance running IIS with the LoanProcessing .NET Framework 4.7.2 MVC application
- SQL Server database with 5 tables and 9 stored procedures
- Application Load Balancer routing traffic to the EC2 instance
- Application is accessible and all pages render correctly
- Validation tests pass (run from `/validation` endpoint)

### Verification

Open the application in your browser and navigate to the `/validation` page. Click "Run All Tests" and confirm all tests pass with a green status. This establishes your baseline.

---

## 3. Architecture

### Before — Business Logic in Stored Procedures

```
Browser → ALB → IIS (.NET 4.7.2)
                    │
                    ├── LoanController
                    │       └── LoanService.EvaluateCredit()
                    │               └── LoanDecisionRepository.EvaluateCredit()
                    │                       └── SQL Server: EXEC sp_EvaluateCredit
                    │                           (risk scoring, DTI calc, rate lookup,
                    │                            recommendation — all in T-SQL)
                    │
                    └── SQL Server: 9 stored procedures with business logic
```

### After — Business Logic in .NET Service Layer

```
Browser → ALB → IIS (.NET 4.7.2)
                    │
                    ├── LoanController
                    │       └── LoanService.EvaluateCredit()
                    │               └── LoanDecisionRepository.EvaluateCredit()
                    │                       └── CreditEvaluationService.Evaluate()
                    │                           ├── CustomerRepository (data only)
                    │                           ├── LoanApplicationRepository (data only)
                    │                           ├── InterestRateRepository (data only)
                    │                           └── CreditEvaluationCalculator (pure C#)
                    │
                    └── SQL Server: tables + data only (stored procedures unused)
```

---

## 4. Explore the Current Architecture (10–15 min)

Before changing anything, understand what you're working with.

### 4.1 — Examine the Stored Procedure

Open `LoanProcessing.Database/StoredProcedures/sp_EvaluateCredit.sql` and read through it. Notice:

- It pulls customer data (credit score, annual income) by joining LoanApplications to Customers
- It calculates existing debt by summing approved loan amounts for the same customer
- It computes a DTI ratio: `((ExistingDebt + RequestedAmount) / AnnualIncome) * 100`
- It scores risk using bracket-based rules on credit score and DTI
- It looks up an interest rate from the InterestRates table
- It updates the application status to "UnderReview"
- It returns a result set with the evaluation data

This is a self-contained business operation — perfect for extraction.

### 4.2 — Trace the Call Chain

Follow the code path from controller to database:

1. `LoanProcessing.Web/Controllers/LoanController.cs` — calls `_loanService.EvaluateCredit(id)`
2. `LoanProcessing.Web/Services/LoanService.cs` — calls `_decisionRepo.EvaluateCredit(applicationId)`
3. `LoanProcessing.Web/Data/LoanDecisionRepository.cs` — executes `sp_EvaluateCredit` via ADO.NET

The repository is the integration point. Everything above it (controller, service) doesn't know or care whether the logic runs in SQL or C#. That's the strangler pattern — we redirect at the repository level.

Also notice:

4. `LoanProcessing.Web/Services/CreditEvaluationService.cs` — this already exists as an SP-backed stub. It calls `sp_EvaluateCredit` via SqlCommand, producing identical results to the repository. The shadow comparison tests use this service directly. During extraction, you'll replace its internals with pure C# logic.
5. `LoanProcessing.Web/Services/ICreditEvaluationService.cs` — the interface is already defined. The extraction doesn't change the contract, only the implementation.

### 4.3 — Run the Validation Baseline

Navigate to `/validation` in your browser and click "Run All Tests." Note the results:

- Smoke tests: all pages load
- Data integrity: row counts and constraints verified
- Business logic: customer CRUD, loan processing, credit evaluation, portfolio reports
- Shadow comparison: SP vs Service — all 5 profiles should show ✅ (both paths currently hit the SP, so they match trivially)

These tests will be your proof that the extraction didn't break anything. After extraction, the shadow comparison becomes meaningful — it will compare the SP output against your new C# implementation.


---

## 5. Review the Spec (10–15 min)

The extraction is driven by a Kiro spec. The spec files are provided in `docs/workshop/specs/module-1/`. Before starting, copy them into your Kiro specs directory:

```bash
mkdir -p .kiro/specs/credit-evaluation-extraction
cp docs/workshop/specs/module-1/requirements.md .kiro/specs/credit-evaluation-extraction/
cp docs/workshop/specs/module-1/design.md .kiro/specs/credit-evaluation-extraction/
cp docs/workshop/specs/module-1/tasks.md .kiro/specs/credit-evaluation-extraction/
```

Open and review each document to understand the plan before executing it.

### 5.1 — Requirements Document

Open `.kiro/specs/credit-evaluation-extraction/requirements.md`

This document defines 9 requirements covering:
- DTI ratio calculation
- Risk score computation
- Interest rate lookup
- Recommendation generation
- Application status updates
- Behavioral equivalence with the stored procedure
- The repeatable pattern for future extractions

Notice how each requirement maps to a specific piece of the stored procedure logic. The strangler pattern works because we can verify each piece independently.

### 5.2 — Design Document

Open `.kiro/specs/credit-evaluation-extraction/design.md`

Key design decisions to discuss:

- **CreditEvaluationCalculator** — Pure static functions for DTI, risk score, and recommendation. No database dependencies. These are trivially unit-testable. Notice how they're shaped like agent tools — clear inputs, deterministic outputs. This class doesn't exist yet — you'll build it in Task 1.

- **CreditEvaluationService** — Already exists as an SP-backed stub that calls `sp_EvaluateCredit` directly. During extraction, you'll replace its internals with calculator + repository logic. The interface stays the same. Notice it depends only on interfaces, not concrete classes.

- **Repository redirect** — `LoanDecisionRepository.EvaluateCredit` is the single point of change. It stops calling `sp_EvaluateCredit` and delegates to `CreditEvaluationService.Evaluate` instead. `LoanService` is completely untouched.

- **Shadow comparison** — The test infrastructure already compares SP output against the service output for 5 curated profiles. Pre-extraction, this is trivially SP-vs-SP. Post-extraction, it becomes a real equivalence check.

### 5.3 — Implementation Tasks

Open `.kiro/specs/credit-evaluation-extraction/tasks.md`

The tasks are ordered so the codebase compiles at every step:
1. Pure calculator functions (no dependencies — this is the main deliverable)
2. Repository interface extensions (new data access methods)
3. Replace service internals (swap the SP-backed stub with calculator + repository logic)
4. Repository redirect (the strangler switch — production now uses the C# service)
5. Enable boundary tests and PBT (turn on the tests that validate the new code)
6. Final validation (deploy and run `/validation`)

Note that `ICreditEvaluationService` and `CreditEvaluationService` already exist as an SP-backed stub. You don't need to create them from scratch — you're replacing the implementation. Reference implementations are available in the `solutions/` folder if you get stuck.

---

## 6. Execute the Extraction with Kiro (20–25 min)

Now execute the spec tasks using Kiro. Open the tasks file in Kiro and begin executing tasks.

### What to Watch For

As Kiro implements each task, pay attention to:

**After Task 1 — CreditEvaluationCalculator:**
Kiro creates `LoanProcessing.Web/Services/CreditEvaluationCalculator.cs`. This is the core extraction — pure C# functions that replicate the stored procedure's business logic. Verify the extracted logic matches the stored procedure by asking Kiro to generate a comparison:

> **🤖 Kiro Prompt:** "Compare the business logic in `LoanProcessing.Web/Services/CreditEvaluationCalculator.cs` with the T-SQL in `LoanProcessing.Database/StoredProcedures/sp_EvaluateCredit.sql`. Create a side-by-side comparison table showing each calculation rule (DTI ratio formula, credit score brackets, DTI brackets, risk score formula, recommendation thresholds, default interest rate) and confirm they are functionally identical. Flag any differences."

Review the comparison Kiro produces. The key things that must match exactly:
- Credit score bracket thresholds and return values (750→10, 700→20, 650→35, 600→50, <600→75)
- DTI bracket thresholds and boundary behavior (≤20→0, ≤35→10, ≤43→20, >43→30 — note ≤ not <)
- DTI formula: `Math.Round(((existingDebt + requestedAmount) / annualIncome) * 100, 4)` — rounded to 4 decimal places to match SQL Server's DECIMAL(18,4)
- Recommendation strings must be exact: "Recommended for Approval", "Manual Review Required", "High Risk - Recommend Rejection"
- Default interest rate: 12.99

If anything doesn't match, the validation tests will catch it later — but it's better to spot discrepancies now. A reference implementation is available in `solutions/CreditEvaluationCalculator.cs`.

**After Task 2 — Repository Extensions:**
Notice the new methods added to `IInterestRateRepository` and `ILoanApplicationRepository`. These push data filtering to the database (matching what the stored procedure did) rather than loading everything into memory.

**After Task 3 — Service Replacement (The Key Moment):**
This is where the strangler pattern comes alive. `CreditEvaluationService` goes from calling `sp_EvaluateCredit` to using the calculator + repositories. The interface stays the same — `LoanDecision Evaluate(int applicationId)` — but the implementation is now pure C#. The shadow comparison test will now compare SP output against C# output for real.

> **⚠️ Watch out:** `CreditEvaluationTests.cs` has a fallback `new CreditEvaluationService()` that will fail to compile once the parameterless constructor is removed. The tasks file covers this — make sure Kiro updates both `ValidationService.cs` and `CreditEvaluationTests.cs`.

**After Task 4 — The Production Redirect:**
`LoanDecisionRepository.EvaluateCredit` stops calling `sp_EvaluateCredit` and delegates to `CreditEvaluationService.Evaluate`. The stored procedure still exists in the database — it's just no longer called. This is the strangler pattern in action. Note that `LoanDecisionRepository` (in the `Data` namespace) now needs `using LoanProcessing.Web.Services;` since it references `ICreditEvaluationService`.

**After Task 5 — Tests Enabled:**
The boundary test calls in `CreditEvaluationTests.Run()` are uncommented, and the boundary test methods are implemented (the starter code has placeholder stubs that must be replaced with real implementations following the same `TestResult` pattern as the existing tests). The FsCheck property-based test project is created and runs in CI, testing the calculator with 100 random inputs per property. The PBT results appear on the validation page.

> **Note:** The PBT project must use the same package versions as the existing project: xunit 2.4.2 (matching `xunit.runner.console.2.4.2` in `buildspec.yml`), FSharp.Core 4.2.3 (matching `LoanProcessing.Web/packages.config`), and FsCheck 2.16.6. A reference implementation is available in `solutions/LoanProcessing.Tests/`.

### Checkpoints

After Task 3: The service internals are replaced. All new code compiles. The shadow comparison now shows a real SP-vs-C# comparison.

After Task 4: Commit and push your changes. CodePipeline will deploy to EC2. Once deployed, run the validation tests from `/validation`. All tests should pass.

After Task 5: PBT tests run in CI. The validation page shows boundary test results and the CI PBT summary.

---

## 7. Validate the Extraction (5–10 min)

### 7.1 — Run the Validation Dashboard

Navigate to `/validation` and click "Run All Tests."

> **Tip:** After CodeDeploy completes, wait a few seconds and refresh the page before running tests. The ALB may briefly serve the previous version during the deployment transition.

All tests should pass with green status. The key tests to verify:

- **High Credit Score Risk Assessment** — credit score 780, expects RiskScore ≤ 40
- **Low Credit Score Risk Assessment** — credit score 550, expects RiskScore > 60
- **Debt-to-Income Ratio Calculation** — expects DTI > 0
- **Credit Score & DTI Boundary Values** — tests exact bracket thresholds (enabled after Task 5)
- **Recommendation Threshold Boundaries** — tests recommendation classification boundaries (enabled after Task 5)
- **Shadow Comparison: SP vs Service** — all 5 profiles should show ✅, now comparing SP output against your C# implementation
- **CI Property-Based Test Summary** — shows FsCheck results from the latest CI build (enabled after Task 5)

These tests exercise the exact same code paths as before — but now the logic runs in your .NET service layer instead of SQL Server. The shadow comparison proves behavioral equivalence across 5 curated loan profiles.

### 7.2 — Verify the Stored Procedure is Unused

The `sp_EvaluateCredit` stored procedure still exists in the database. You can verify it's no longer being called by checking that `LoanDecisionRepository.EvaluateCredit` now delegates to `CreditEvaluationService.Evaluate` instead of containing `SqlCommand` or `sp_EvaluateCredit` references.

---

## 8. Fast-Forward Remaining Extractions (5 min)

The pattern you just applied to `sp_EvaluateCredit` works for all remaining stored procedures. Rather than repeating the process 8 more times, deploy the pre-built extractions.

> **Instructor Note:** Provide participants with the branch containing all completed extractions. Participants merge or checkout this branch.

After deploying the fast-forward code, run the validation dashboard again. All tests should still pass — confirming that every stored procedure extraction maintained behavioral equivalence.

### What Was Extracted

| Stored Procedure | Extracted To | Status |
|---|---|---|
| sp_EvaluateCredit | CreditEvaluationService | ✅ Hands-on |
| sp_ProcessLoanDecision | LoanDecisionService | ✅ Fast-forward |
| sp_CalculatePaymentSchedule | PaymentScheduleService | ✅ Fast-forward |
| sp_GeneratePortfolioReport | ReportService (enhanced) | ✅ Fast-forward |
| sp_CreateCustomer | CustomerRepository (inline SQL) | ✅ Fast-forward |
| sp_UpdateCustomer | CustomerRepository (inline SQL) | ✅ Fast-forward |
| sp_GetCustomerById | CustomerRepository (inline SQL) | ✅ Fast-forward |
| sp_SearchCustomers | CustomerRepository (inline SQL) | ✅ Fast-forward |
| sp_SearchCustomersAutocomplete | CustomerRepository (inline SQL) | ✅ Fast-forward |

---

## 9. Key Takeaways

**The strangler pattern** lets you migrate business logic incrementally — one stored procedure at a time — without a big-bang rewrite. Each extraction is independently deployable and verifiable. The SP-backed service stub gave you a safe seam to work with — production stayed on the SP until you were ready to flip the switch.

**The shadow comparison** proves behavioral equivalence. Before extraction, both paths hit the SP (trivial pass). After extraction, the comparison is real — SP vs C# logic across 5 curated profiles. If anything diverges, you see it immediately.

**Property-based testing** becomes possible only after extraction. When business logic is trapped in a stored procedure, you can't test individual calculation steps in isolation. Once extracted into pure C# functions, FsCheck validates the math across hundreds of random inputs — catching edge cases that hand-written tests miss.

**The validation framework** is your safety net. It proves behavioral equivalence at every step, giving you confidence to proceed to the next module.

**The interfaces are agent-tool-shaped.** `ICreditEvaluationService.Evaluate(applicationId)` has a clear input, a deterministic output, and no side-channel dependencies. In a future module, this becomes a Lambda function, a container endpoint, or an AI agent tool with minimal refactoring.

**The database is now a pure data store.** No business logic remains in stored procedures. This makes the database migration in Module 2 dramatically simpler — it's just schema and data, no T-SQL to PL/pgSQL conversion needed.

---

## 10. What's Next

In **Module 2**, you will migrate the database from SQL Server to Aurora PostgreSQL using AWS SCT and DMS. Because all business logic now lives in the .NET service layer, the migration is a pure data operation — no stored procedure conversion required.
