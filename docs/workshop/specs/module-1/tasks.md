# Implementation Plan: Credit Evaluation Extraction

## Overview

Extract the credit evaluation business logic from `sp_EvaluateCredit` into a C# service layer using the strangler pattern. The implementation proceeds bottom-up: pure calculation functions first, then repository extensions, then the service, then the wiring redirect. Each step compiles and the codebase remains functional throughout.

## Tasks

- [ ] 1. Create CreditEvaluationCalculator with pure computation functions
  - [ ] 1.1 Create `LoanProcessing.Web/Services/CreditEvaluationCalculator.cs` with static methods
    - Implement `CalculateDtiRatio(decimal existingDebt, decimal requestedAmount, decimal annualIncome)` returning `((existingDebt + requestedAmount) / annualIncome) * 100`
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

- [ ] 3. Create ICreditEvaluationService and CreditEvaluationService
  - [ ] 3.1 Create `LoanProcessing.Web/Services/ICreditEvaluationService.cs`
    - Define `LoanDecision Evaluate(int applicationId)` method
    - **IMPORTANT:** Add `<Compile Include="Services\ICreditEvaluationService.cs" />` to `LoanProcessing.Web/LoanProcessing.Web.csproj`
    - _Requirements: 9.1_

  - [ ] 3.2 Create `LoanProcessing.Web/Services/CreditEvaluationService.cs`
    - Constructor takes `ILoanApplicationRepository`, `ICustomerRepository`, `IInterestRateRepository`
    - **IMPORTANT:** Add `<Compile Include="Services\CreditEvaluationService.cs" />` to `LoanProcessing.Web/LoanProcessing.Web.csproj`
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

- [ ] 4. Redirect LoanDecisionRepository to use CreditEvaluationService
  - [ ] 4.1 Modify `LoanDecisionRepository` to accept and use `ICreditEvaluationService`
    - Add `using LoanProcessing.Web.Services;` to the file
    - Add `ICreditEvaluationService _creditEvalService` field
    - Add new constructor: `LoanDecisionRepository(string connectionString, ICreditEvaluationService creditEvalService)`
    - Update parameterless constructor to wire the full dependency chain: create `LoanApplicationRepository`, `CustomerRepository`, `InterestRateRepository`, then `CreditEvaluationService`, passing them in
    - Update `LoanDecisionRepository(string connectionString)` constructor to also wire the chain using the provided connection string
    - Replace `EvaluateCredit` body: remove all `sp_EvaluateCredit` ADO.NET code, delegate to `_creditEvalService.Evaluate(applicationId)`
    - Do NOT modify `ProcessDecision`, `GetByApplication`, or `MapLoanDecisionFromReader`
    - _Requirements: 7.1, 7.2, 7.3_

  - [ ] 4.2 Verify `ValidationService` and `LoanController` constructor wiring
    - Both create `new LoanDecisionRepository(connectionString)` — the updated constructor wires up the `CreditEvaluationService` chain internally, so no changes are needed
    - Verify `LoanService.cs` has zero modifications
    - No changes to `LoanService` constructor call or any other wiring
    - _Requirements: 7.3, 8.5_

- [ ] 5. Final validation
  - Verify `CreditEvaluationTests.cs` and `LoanProcessingTests.cs` have zero modifications
  - Verify `LoanService.cs` has zero modifications
  - Commit, push, and deploy via CodePipeline
  - Run validation tests from `/validation` endpoint — all tests must pass
  - _Requirements: 7.3, 8.5_

## Notes

- Each task references specific requirements for traceability
- The existing validation tests (`CreditEvaluationTests`, `LoanProcessingTests`) serve as the behavioral equivalence gate and must pass without modification
- The `sp_EvaluateCredit` stored procedure remains in the database unchanged for rollback purposes

### CRITICAL: .NET Framework .csproj File Inclusion

This is a .NET Framework 4.7.2 project. Unlike .NET Core/.NET 8+ projects that use wildcard globbing, .NET Framework projects require every `.cs` file to be explicitly listed in the `.csproj` file. When creating any new `.cs` file, you MUST also add a corresponding `<Compile Include="..." />` entry to `LoanProcessing.Web/LoanProcessing.Web.csproj`. Failure to do so will cause build failures — the file will exist on disk but MSBuild will not compile it.

Look for the existing `<Compile Include="Services\..." />` entries in the `.csproj` and add new entries in the same `<ItemGroup>` block.
