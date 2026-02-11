# Property-Based Testing with FSCheck

This directory contains property-based tests for the Loan Processing application using FSCheck.

## Overview

Property-based testing verifies universal correctness properties across randomized inputs, complementing traditional unit tests that verify specific examples. FSCheck generates hundreds of test cases automatically, helping discover edge cases that manual testing might miss.

## Setup

### NuGet Packages

The following packages have been installed:

- **FsCheck 2.16.6** - Property-based testing library for .NET
- **FSharp.Core 4.2.3** - Required dependency for FSCheck
- **MSTest.TestFramework 2.2.10** - Test framework
- **MSTest.TestAdapter 2.2.10** - Test adapter for Visual Studio
- **Moq 4.18.4** - Mocking framework for unit tests

### Project Configuration

All packages are referenced in:
- `packages.config` - NuGet package configuration
- `LoanProcessing.Web.csproj` - Project file with assembly references

## File Structure

```
Tests/
├── README.md                    # This file
├── PropertyTestBase.cs          # Base class for all property tests
├── PropertyTestGenerators.cs    # FSCheck generators for domain models
└── SamplePropertyTests.cs       # Sample tests demonstrating setup
```

## Key Components

### PropertyTestBase.cs

Base class providing:
- **DefaultConfig**: 100 iterations per property (as per design spec)
- **VerboseConfig**: Detailed output for debugging
- **QuickConfig**: 10 iterations for rapid development
- **Helper methods**: `CheckProperty`, `ApproximatelyEqual`, `InRange`

### PropertyTestGenerators.cs

Generators for creating valid test data:

#### Customer Generators
- `ValidCustomer()` - Generates customers with valid constraints
  - Credit score: 300-850
  - Age: 18-100 years
  - Annual income: $10,000-$500,000
  - Valid SSN format (###-##-####)
  
- `CustomerWithCreditScore(min, max)` - Generates customers in specific credit score range

#### Loan Application Generators
- `ValidLoanApplication()` - Generates valid loan applications
  - Personal: $1,000-$50,000
  - Auto: $5,000-$75,000
  - Mortgage: $50,000-$500,000
  - Business: $10,000-$250,000
  - Term: 12-360 months
  
- `LoanApplicationOfType(type)` - Generates applications for specific loan type

#### Interest Rate Generators
- `ValidInterestRate()` - Generates valid interest rates
  - Credit score ranges: 300-850
  - Term ranges: 12-360 months
  - Rate: 3.0%-25.0%
  
- `InterestRateForTypeAndScore(type, min, max)` - Generates rates for specific criteria

#### Payment Schedule Generators
- `ValidPaymentScheduleParameters()` - Generates valid amortization parameters
- `ValidPaymentSchedule()` - Generates individual payment schedule entries

#### Loan Decision Generators
- `ValidLoanDecision()` - Generates valid loan decisions with risk scores and DTI ratios

## Writing Property Tests

### Basic Structure

```csharp
[TestMethod]
[TestCategory("PropertyTest")]
[Description("Feature: legacy-dotnet-inventory-app, Property X: Description")]
public void Property_FeatureName_PropertyDescription()
{
    var property = Prop.ForAll(
        PropertyTestGenerators.ValidCustomer(),
        customer =>
        {
            // Test your property here
            return /* boolean expression */;
        });
    
    CheckProperty(property, "Property Name");
}
```

### Example: Testing Customer Creation

```csharp
[TestMethod]
[TestCategory("PropertyTest")]
[Description("Feature: legacy-dotnet-inventory-app, Property 1: Customer Data Round-Trip Consistency")]
public void Property_CustomerCreation_DataRoundTrip()
{
    var property = Prop.ForAll(
        PropertyTestGenerators.ValidCustomer(),
        customer =>
        {
            // Create customer in database
            int customerId = _repository.CreateCustomer(customer);
            
            // Retrieve customer
            var retrieved = _repository.GetById(customerId);
            
            // Verify all fields match
            return retrieved.FirstName == customer.FirstName &&
                   retrieved.LastName == customer.LastName &&
                   retrieved.SSN == customer.SSN &&
                   retrieved.CreditScore == customer.CreditScore;
        });
    
    CheckProperty(property, "Customer Data Round-Trip");
}
```

## Running Tests

### Visual Studio Test Explorer

1. Build the solution
2. Open Test Explorer (Test → Test Explorer)
3. Run all tests or filter by category:
   - `TestCategory:PropertyTest` - All property tests
   - `TestCategory:Generator` - Generator validation tests

### Command Line

```powershell
# Run all tests
dotnet test

# Run only property tests
dotnet test --filter TestCategory=PropertyTest

# Run with verbose output
dotnet test --logger "console;verbosity=detailed"
```

### MSTest Command Line

```powershell
# Using vstest.console.exe
vstest.console.exe LoanProcessing.Web.dll /TestCaseFilter:"TestCategory=PropertyTest"
```

## Property Test Guidelines

### From Design Document

1. **Minimum 100 iterations** per property test (configured in `DefaultConfig`)
2. **Tag format**: `Feature: legacy-dotnet-inventory-app, Property {number}: {description}`
3. **Reference requirements**: Each test should validate specific acceptance criteria
4. **Report failures**: FSCheck automatically reports the failing input that caused the test to fail

### Best Practices

1. **Keep properties simple**: Test one invariant per property
2. **Use appropriate generators**: Choose generators that match your constraints
3. **Handle edge cases**: Generators should produce valid but diverse inputs
4. **Document properties**: Use clear descriptions explaining what property is being tested
5. **Avoid database dependencies**: Use mocks where possible for faster tests
6. **Test generators first**: Validate that generators produce valid data (see `SamplePropertyTests.cs`)

## Troubleshooting

### Common Issues

**Issue**: Tests fail with "FsCheck not found"
- **Solution**: Rebuild the solution to restore NuGet packages

**Issue**: Tests timeout or run slowly
- **Solution**: Use `QuickConfig` during development, or reduce database operations

**Issue**: Generator produces invalid data
- **Solution**: Add validation tests for generators (see `SamplePropertyTests.cs`)

**Issue**: Property fails intermittently
- **Solution**: FSCheck will report the failing seed - use `Configuration.WithReplay()` to reproduce

### Debugging Failed Properties

When a property fails, FSCheck reports:
1. The failing input that caused the failure
2. The seed used for random generation
3. The number of tests passed before failure

Example output:
```
Falsifiable, after 42 tests (0 shrinks):
Customer { FirstName = "John", LastName = "Smith", CreditScore = 299, ... }
```

To reproduce:
```csharp
var config = DefaultConfig.WithReplay(Replay.NewReplay(42, 0));
CheckProperty(config, property, "Property Name");
```

## Next Steps

After completing Task 17.1 (FSCheck setup), the following property tests need to be implemented:

- **Task 3.2**: Property 1 - Customer Data Round-Trip Consistency
- **Task 3.4**: Property 2 - Customer Update Preservation
- **Task 5.2**: Property 4 - Loan Amount Validation by Type
- **Task 5.3**: Property 6 - Application Number Uniqueness
- **Task 5.5**: Property 5 - Debt-to-Income Ratio Calculation
- **Task 5.6**: Property 7 - Risk Score Calculation Consistency
- **Task 5.7**: Property 8 - Low Credit Score Flagging
- **Task 5.8**: Property 9 - Interest Rate Selection Accuracy
- **Task 6.2**: Property 11 - Rejection Reason Requirement
- **Task 6.4**: Property 10 - Payment Schedule Amortization Correctness
- **Task 7.2**: Property 14 - Portfolio Aggregation Accuracy
- **Task 7.3**: Property 15 - Date Range Filtering Correctness
- **Task 7.4**: Property 16 - Risk Distribution Percentage Totals
- **Task 9.3**: Property 19 - Database Result Mapping Completeness
- **Task 10.7**: Property 20 - Database Constraint Enforcement
- **Task 16.3**: Property 17 - Interest Rate Historical Preservation
- **Task 16.4**: Property 18 - Rate Change Temporal Isolation

## References

- [FSCheck Documentation](https://fscheck.github.io/FsCheck/)
- [Property-Based Testing Guide](https://fsharpforfunandprofit.com/posts/property-based-testing/)
- Design Document: `.kiro/specs/legacy-dotnet-inventory-app/design.md` (Testing Strategy section)
- Requirements Document: `.kiro/specs/legacy-dotnet-inventory-app/requirements.md`
