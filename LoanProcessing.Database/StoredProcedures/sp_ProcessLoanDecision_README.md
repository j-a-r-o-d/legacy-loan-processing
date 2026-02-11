# sp_ProcessLoanDecision Stored Procedure

## Overview

The `sp_ProcessLoanDecision` stored procedure processes loan approval or rejection decisions for loan applications. It validates the decision, records it in the database, updates the application status, and triggers payment schedule calculation for approved loans.

## Requirements

- **Requirement 4.1**: Validate and record loan decisions with all evaluation data
- **Requirement 4.3**: Update application status to 'Approved' or 'Rejected'
- **Requirement 4.5**: Call sp_CalculatePaymentSchedule if approved

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `@ApplicationId` | INT | Yes | The ID of the loan application to process |
| `@Decision` | NVARCHAR(20) | Yes | The decision: 'Approved' or 'Rejected' |
| `@DecisionBy` | NVARCHAR(100) | Yes | Name/ID of the person making the decision |
| `@Comments` | NVARCHAR(1000) | No | Comments or notes about the decision |
| `@ApprovedAmount` | DECIMAL(18,2) | No | Amount approved (defaults to requested amount if not specified for approvals) |
| `@RiskScore` | INT | No | Risk score from credit evaluation (0-100) |
| `@DebtToIncomeRatio` | DECIMAL(5,2) | No | Debt-to-income ratio from credit evaluation |

## Return Values

- `0`: Success
- `-1`: Application not found
- `-2`: Approved amount exceeds requested amount
- `-3`: Approved amount must be positive
- `-99`: Other error (see error message)

## Business Logic

### Validation Rules

1. **Application Existence**: Validates that the application exists in the database
2. **Approved Amount Validation**: 
   - If decision is 'Approved' and no amount is specified, defaults to the requested amount
   - Approved amount cannot exceed the requested amount
   - Approved amount must be greater than zero

### Decision Processing

1. **Retrieve Application Details**: Gets requested amount, interest rate, and term from the application
2. **Retrieve Evaluation Data**: 
   - Uses provided RiskScore and DebtToIncomeRatio parameters if supplied
   - Otherwise, attempts to retrieve from the most recent LoanDecisions record for this application
   - If neither source provides the data, these fields will be NULL in the decision record
3. **Insert Decision Record**: Creates a new record in LoanDecisions with:
   - Application ID
   - Decision (Approved/Rejected)
   - Decision maker
   - Decision date (current timestamp)
   - Comments
   - Approved amount (if applicable)
   - Interest rate from application
   - Risk score (if available)
   - Debt-to-income ratio (if available)
4. **Update Application Status**: Sets the application status to the decision value and updates the approved amount
5. **Trigger Payment Schedule**: If approved, calls `sp_CalculatePaymentSchedule` to generate the payment schedule

## Usage Examples

### Example 1: Approve with Default Amount

```sql
-- Approve a loan for the full requested amount
EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = 123,
    @Decision = 'Approved',
    @DecisionBy = 'John Smith',
    @Comments = 'Excellent credit history and stable income';
```

### Example 2: Approve with Partial Amount

```sql
-- Approve a loan for less than the requested amount
EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = 124,
    @Decision = 'Approved',
    @DecisionBy = 'Jane Doe',
    @Comments = 'Approved for lower amount due to DTI ratio',
    @ApprovedAmount = 15000.00;
```

### Example 3: Reject Application

```sql
-- Reject a loan application
EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = 125,
    @Decision = 'Rejected',
    @DecisionBy = 'Bob Johnson',
    @Comments = 'Insufficient credit score and high debt-to-income ratio';
```

### Example 4: Approve with Evaluation Data

```sql
-- Approve with evaluation data from sp_EvaluateCredit
DECLARE @RiskScore INT = 25;
DECLARE @DTI DECIMAL(5,2) = 32.50;

EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = 126,
    @Decision = 'Approved',
    @DecisionBy = 'Alice Williams',
    @Comments = 'Good credit profile',
    @RiskScore = @RiskScore,
    @DebtToIncomeRatio = @DTI;
```

## Typical Workflow

The typical workflow for processing a loan decision is:

1. **Submit Application**: Use `sp_SubmitLoanApplication` to create a new loan application
2. **Evaluate Credit**: Call `sp_EvaluateCredit` to perform credit evaluation and get risk assessment
3. **Make Decision**: Call `sp_ProcessLoanDecision` with the decision and optionally pass evaluation data
4. **View Schedule**: If approved, query PaymentSchedules table to see the payment schedule

## Error Handling

The procedure uses transaction management to ensure data consistency:

- All operations are wrapped in a transaction
- If any error occurs, the transaction is rolled back
- Errors are re-thrown with descriptive messages
- The procedure returns specific error codes for different failure scenarios

## Dependencies

- **Tables**: 
  - `LoanApplications` (read/write)
  - `LoanDecisions` (write)
- **Stored Procedures**: 
  - `sp_CalculatePaymentSchedule` (called for approved loans)

## Notes

- The procedure checks if `sp_CalculatePaymentSchedule` exists before calling it, allowing for graceful handling if the procedure hasn't been created yet
- Evaluation data (RiskScore and DebtToIncomeRatio) can be provided as parameters or retrieved from previous decisions
- For the first decision on an application, if evaluation data is not provided as parameters, these fields will be NULL
- The interest rate is always taken from the LoanApplications table (set by sp_EvaluateCredit)

## Testing

Test scripts are available:
- `TestProcessLoanDecisionSimple.sql` - Basic functionality tests
- `TestProcessLoanDecisionWithEvalData.sql` - Tests with evaluation data parameters

## Version History

- **v1.0** (2026-02-09): Initial implementation
  - Basic decision processing
  - Validation rules
  - Payment schedule trigger
  - Optional evaluation data parameters

