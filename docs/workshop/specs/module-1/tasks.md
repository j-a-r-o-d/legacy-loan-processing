# Implementation Plan: Credit Evaluation Extraction

## Overview

Extract the credit evaluation business logic from `sp_EvaluateCredit` into the C# service layer using the strangler pattern. The codebase already has an SP-backed `CreditEvaluationService` stub (created during the shadow-comparison-validation phase) that calls the stored procedure directly. This extraction replaces the stub's internals with pure C# computation via a new `CreditEvaluationCalculator`, extended repository methods, and then redirects the production `LoanDecisionRepository` to use the service instead of calling the SP directly.

The shadow comparison test infrastructure is already in place and will validate behavioral equivalence between the SP and the new C# implementation. Boundary tests and FsCheck property-based tests are currently gated — they will be enabled as part of this extraction once the calculator exists.

Reference implementations are available in the `solutions/` folder if needed.

## Starting State

- `ICreditEvaluationService` and `CreditEvaluationService` already exist — the service currently delegates to `sp_EvaluateCredit` via SqlCommand (SP-backed stub)
- `LoanDecisionRepository.EvaluateCredit` still calls `sp_EvaluateCredit` directly (production path unchanged)
- Shadow comparison tests call the service stub directly and compare against the SP — currently passes trivially (both hit the SP)
- Boundary tests (`TestCreditScoreBoundaries`, `TestRecommendationBoundaries`) are commented out — they require `CreditEvaluationCalculator` which doesn't exist yet
- FsCheck CI step is gated in `buildspec.yml` — skipped when `LoanProcessing.Tests.csproj` doesn't exist
- `LoanProcessing.Tests` project is in `solutions/` as a reference

## Tasks

- [ ] 1. Create CreditEvaluationCalculator with pure computation functions
  - [ ] 1.1 Create `LoanProcessing.Web/Services/CreditEvaluationCalculator.cs` with static methods
    - Implement `CalculateDtiRatio(decimal existingDebt, decimal requestedAmount, decimal annualIncome)` returning `Math.Round(((existingDebt + requestedAmount) / annualIncome) * 100, 4)` — rounded to 4 decimal places to match SQL Server DECIMAL(18,4)
    - Implement `CalculateCreditScoreComponent(int creditScore)` with bracket mapping: ≥750→10, ≥700→20, ≥650→35, ≥600→50, <600→75
    - Implement `CalculateDtiComponent(decimal dtiRatio)` with bracket mapping: ≤20→0, ≤35→10, ≤43→20, >43→30
    - Implement `CalculateRiskScore(int creditScore, decimal dtiRatio)` as sum of components clamped to [0, 100]
    - Implement `DetermineRecommendation(int riskScore, decimal dtiRatio)` returning one of three recommendation strings
    - Define `DefaultInterestRate = 12.99m` constant
    - **IMPORTANT:** Add `<Compile Include="Services\CreditEvaluationCalculator.cs" />` to `LoanProcessing.Web/LoanProcessing.Web.csproj` in the ItemGroup with the other Services entries
    - _Requirements: 1.3, 2.1, 2.2, 2.3, 2.4, 4.1, 4.2, 4.3_

- [ ] 2. Extend repository interfaces and implementations with new methods
  - [ ] 2.1 Add `GetRateByCriteria` to `IInterestRateRepository` and implement in `InterestRateRepository`
    - Add method `InterestRate GetRateByCriteria(string loanType, int creditScore, int termMonths, DateTime asOfDate)` to the interface
    - Implement with SQL query: `SELECT TOP 1 ... WHERE LoanType = @LoanType AND @CreditScore BETWEEN MinCreditScore AND MaxCreditScore AND @TermMonths BETWEEN MinTermMonths AND MaxTermMonths AND EffectiveDate <= @AsOfDate AND (ExpirationDate IS NULL OR ExpirationDate >= @AsOfDate) ORDER BY EffectiveDate DESC`
    - Return null if no match found
    - _Requirements: 3.1, 3.2_

  - [ ] 2.2 Add `GetApprovedAmountsByCustomer` and `UpdateStatusAndRate` to `ILoanApplicationRepository` and implement in `LoanApplicationRepository`
    - Add `decimal GetApprovedAmountsByCustomer(int customerId, int excludeApplicationId)` — returns SUM of ApprovedAmount for approved applications excluding the given app
    - Add `void UpdateStatusAndRate(int applicationId, string status, decimal interestRate)` — updates Status and InterestRate columns
    - Implement both with direct SQL queries matching the stored procedure's behavior
    - _Requirements: 1.2, 5.1, 5.2_

- [ ] 3. Replace CreditEvaluationService internals with calculator and repository logic
  - [ ] 3.1 Update `CreditEvaluationService` to use calculator and repositories instead of SP
    - Replace the SP-backed stub implementation with the real extraction logic
    - Change constructor to take `ILoanApplicationRepository`, `ICustomerRepository`, `IInterestRateRepository` (replacing the connection string constructor)
    - Keep the `ICreditEvaluationService` interface unchanged — `LoanDecision Evaluate(int applicationId)` stays the same
    - Implement `Evaluate(int applicationId)`:
      1. Validate applicationId > 0, throw `ArgumentException` if not
      2. Load application via `_loanAppRepo.GetById(applicationId)`, throw `InvalidOperationException` if null
      3. Load customer via `_customerRepo.GetById(application.CustomerId)`, throw `InvalidOperationException` if null
      4. Validate customer.AnnualIncome > 0, throw `InvalidOperationException` if not
      5. Get existing debt via `_loanAppRepo.GetApprovedAmountsByCustomer(customerId, applicationId)`
      6. Calculate DTI, risk score, recommendation via `CreditEvaluationCalculator`
      7. Look up rate via `_rateRepo.GetRateByCriteria(...)`, default to 12.99% if null
      8. Update application via `_loanAppRepo.UpdateStatusAndRate(applicationId, "UnderReview", rate)`
      9. Return populated `LoanDecision` with ApplicationId, RiskScore, DebtToIncomeRatio, InterestRate, Comments (recommendation)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.3, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 9.2, 9.3_

  - [ ] 3.2 Update `ValidationService` and `CreditEvaluationTests` to pass repositories to `CreditEvaluationService`
    - Update the `CreditEvaluationService` instantiation in `ValidationService` constructor to pass the required repository instances instead of using the parameterless constructor
    - **⚠️ IMPORTANT:** In `CreditEvaluationTests.cs`, the constructor has a fallback `creditEvalService ?? new CreditEvaluationService()`. Since the parameterless constructor no longer exists, remove the `?? new CreditEvaluationService()` fallback — change it to `_creditEvalService = creditEvalService;`. This will cause a compile error if missed.
    - _Requirements: 9.1, 9.2_

- [ ] 4. Redirect LoanDecisionRepository to use CreditEvaluationService
  - [ ] 4.1 Modify `LoanDecisionRepository` to accept and use `ICreditEvaluationService`
    - Add `using LoanProcessing.Web.Services;` to the top of `LoanDecisionRepository.cs` (this file is in the `Data` namespace and does not currently reference the `Services` namespace)
    - Add `ICreditEvaluationService _creditEvalService` field
    - Add new constructor: `LoanDecisionRepository(string connectionString, ICreditEvaluationService creditEvalService)`
    - Update `LoanDecisionRepository(string connectionString)` constructor to wire the full dependency chain: create `LoanApplicationRepository`, `CustomerRepository`, `InterestRateRepository`, then `CreditEvaluationService`, passing them in
    - Replace `EvaluateCredit` body: remove all `sp_EvaluateCredit` ADO.NET code, delegate to `_creditEvalService.Evaluate(applicationId)`
    - Do NOT modify `ProcessDecision`, `GetByApplication`, or `MapLoanDecisionFromReader`
    - _Requirements: 7.1, 7.2, 7.3_

  - [ ] 4.2 Verify `LoanController` and `LoanService` are unchanged
    - `LoanController` creates `new LoanDecisionRepository(connectionString)` — the updated constructor wires up the `CreditEvaluationService` chain internally, so no changes are needed
    - Verify `LoanService.cs` has zero modifications
    - _Requirements: 7.3, 8.5_

- [ ] 5. Enable boundary tests and PBT
  - [ ] 5.1 Enable boundary tests in `CreditEvaluationTests.cs`
    - Uncomment `results.Add(TestCreditScoreBoundaries(stage));` and `results.Add(TestRecommendationBoundaries(stage));` in the `Run` method
    - Replace the commented-out `/* Boundary tests ... */` block with real implementations of `TestCreditScoreBoundaries` and `TestRecommendationBoundaries`
    - `TestCreditScoreBoundaries` should test credit score bracket boundaries (750, 749, 700, 699, 650, 649, 600, 599) and DTI bracket boundaries (20, 20.0001, 35, 35.0001, 43, 43.0001) using `CreditEvaluationCalculator` static methods directly
    - `TestRecommendationBoundaries` should test recommendation thresholds at exact boundary values: (risk=30,dti=35), (risk=31,dti=35), (risk=30,dti=35.01), (risk=50,dti=43), (risk=51,dti=43), (risk=50,dti=43.01)
    - Follow the same `TestResult` return pattern used by the existing test methods (e.g., `TestHighCreditScore`)
    - These tests validate the calculator's bracket mappings and recommendation thresholds
    - _Requirements: 2.1, 2.2, 4.1, 4.2, 4.3, 8.1_

  - [ ] 5.2 Create `LoanProcessing.Tests` project with FsCheck property-based tests
    - Create `LoanProcessing.Tests/LoanProcessing.Tests.csproj` as a .NET Framework 4.7.2 class library referencing FsCheck (2.16.6), FsCheck.Xunit, xunit, xunit.runner.visualstudio, and a project reference to `LoanProcessing.Web`
    - Create `LoanProcessing.Tests/CreditEvaluationCalculatorProperties.cs` with 5 FsCheck.Xunit property tests (each decorated with `[Property(MaxTest = 100)]`):
      1. `DtiRatio_MatchesFormula`: for all `annualIncome > 0`, verify DTI formula correctness
      2. `CreditScoreComponent_ReturnsValidBracket`: for all `creditScore` in [300, 850], verify result is one of {10, 20, 35, 50, 75}
      3. `DtiComponent_ReturnsValidBracket`: for all `dtiRatio` in [0, 200], verify result is one of {0, 10, 20, 30}
      4. `RiskScore_InRangeAndEqualsComponentSum`: for all valid inputs, verify result is in [0, 100] and equals clamped component sum
      5. `Recommendation_ReturnsValidCategory`: for all valid inputs, verify result is one of three valid strings
    - Add `LoanProcessing.Tests` to `LoanProcessing.sln` with project and configuration entries
    - Reference implementation available in `solutions/LoanProcessing.Tests/` if needed
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [ ] 5.3 Verify `buildspec.yml` PBT gate activates
    - The `buildspec.yml` already checks for `LoanProcessing.Tests.csproj` existence — once the project is created, the FsCheck tests will automatically build and run in CI
    - Verify `pbt-results.json` is generated and included in the deployment package
    - _Requirements: 8.5_

- [ ] 6. Final validation (Guide Section 7)
  - Run validation tests from `/validation` endpoint — all tests must pass including:
    - Integration tests (high/low credit score, DTI)
    - Shadow comparison (SP vs C# service — should now show real comparison, not trivial SP-vs-SP)
    - Boundary tests (credit score brackets, DTI brackets, recommendation thresholds)
  - Verify `LoanService.cs` has zero modifications
  - Verify `sp_EvaluateCredit` remains in the database unchanged
  - Commit, push, and deploy via CodePipeline
  - _Requirements: 7.3, 8.5_

## Notes

- Each task references specific requirements for traceability
- The existing shadow comparison tests serve as the behavioral equivalence gate — after Task 3, the shadow comparison becomes a real SP-vs-C# comparison instead of the current trivial SP-vs-SP comparison
- The `sp_EvaluateCredit` stored procedure remains in the database unchanged for rollback purposes
- Reference implementations are available in `solutions/` — `solutions/CreditEvaluationCalculator.cs` and `solutions/LoanProcessing.Tests/`

### CRITICAL: .NET Framework .csproj File Inclusion

This is a .NET Framework 4.7.2 project. Unlike .NET Core/.NET 8+ projects that use wildcard globbing, .NET Framework projects require every `.cs` file to be explicitly listed in the `.csproj` file. When creating any new `.cs` file, you MUST also add a corresponding `<Compile Include="..." />` entry to `LoanProcessing.Web/LoanProcessing.Web.csproj`. Failure to do so will cause build failures — the file will exist on disk but MSBuild will not compile it.

Look for the existing `<Compile Include="Services\..." />` entries in the `.csproj` and add new entries in the same `<ItemGroup>` block.
