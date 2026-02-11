# sp_CalculatePaymentSchedule - Implementation Summary

## Overview
This stored procedure calculates and generates an amortization payment schedule for an approved loan application. It implements the standard loan amortization formula to calculate monthly payments and generates a complete payment schedule showing principal, interest, and remaining balance for each payment.

## Requirements Implemented
- **Requirement 4.2**: Calculate payment schedule when loan is approved
- **Requirement 5.1**: Execute stored procedure to generate amortization schedule
- **Requirement 5.2**: Calculate monthly payment amounts using loan amount, interest rate, and term
- **Requirement 5.3**: Calculate principal and interest portions for each payment
- **Requirement 5.4**: Calculate total interest paid over the life of the loan

## Parameters
- `@ApplicationId INT` - The ID of the approved loan application

## Business Logic

### 1. Monthly Interest Rate Calculation
Converts annual interest rate to monthly rate:
```
MonthlyRate = AnnualRate / 100 / 12
```

### 2. Monthly Payment Calculation
Uses the standard amortization formula:
```
P = L[c(1 + c)^n]/[(1 + c)^n - 1]

Where:
- P = Monthly payment
- L = Loan amount (approved amount)
- c = Monthly interest rate
- n = Number of payments (term in months)
```

### 3. Payment Schedule Generation
For each payment period (1 to n):
1. Calculate interest amount: `RemainingBalance × MonthlyRate`
2. Calculate principal amount: `MonthlyPayment - InterestAmount`
3. Update remaining balance: `RemainingBalance - PrincipalAmount`
4. Insert payment record with all calculated values

### 4. Final Payment Adjustment
The last payment is adjusted to ensure the remaining balance is exactly zero, accounting for rounding differences throughout the amortization schedule.

### 5. Schedule Replacement
Before generating a new schedule, any existing schedule for the application is deleted. This allows recalculation if loan terms are modified.

## Database Operations

### Reads From
- `LoanApplications` table (ApprovedAmount, InterestRate, TermMonths)

### Writes To
- `PaymentSchedules` table (all payment records)

### Deletes From
- `PaymentSchedules` table (existing schedule for the application)

## Transaction Handling
- Wrapped in a transaction with TRY/CATCH
- Rolls back on any error
- Commits only when all payments are successfully inserted

## Test Results

### Test 1: Basic 12-Month Loan
- **Loan Amount**: $10,000.00
- **Interest Rate**: 6.00%
- **Term**: 12 months
- **Monthly Payment**: $860.60 (final: $861.40)
- **Total Interest**: $328.00
- **Final Balance**: $0.00 ✓

### Test 2: 36-Month Auto Loan
- **Loan Amount**: $25,000.00
- **Interest Rate**: 4.50%
- **Term**: 36 months
- **Monthly Payment**: $743.67
- **Total Interest**: $1,772.19
- **Final Balance**: $0.00 ✓

### Test 3: Schedule Recalculation
- Successfully deletes existing schedule
- Generates new schedule with correct payment count ✓

### Test 4: High Interest Rate Loan
- **Loan Amount**: $5,000.00
- **Interest Rate**: 18.99%
- **Term**: 24 months
- **Monthly Payment**: $252.02
- **Total Interest**: $1,048.48
- **Final Balance**: $0.00 ✓

## Key Features

### ✓ Accurate Amortization
Uses the standard financial formula for loan amortization, ensuring accurate payment calculations.

### ✓ Rounding Handling
Properly handles rounding by adjusting the final payment to zero out the remaining balance exactly.

### ✓ Complete Payment Details
Each payment record includes:
- Payment number (1 to n)
- Due date (monthly intervals)
- Total payment amount
- Principal portion
- Interest portion
- Remaining balance after payment

### ✓ Idempotent Operation
Can be called multiple times for the same application - deletes old schedule before creating new one.

### ✓ Transaction Safety
All operations are wrapped in a transaction, ensuring data consistency even if errors occur.

## Integration

### Called By
- `sp_ProcessLoanDecision` - Automatically called when a loan is approved

### Can Be Called Directly
- To recalculate schedule if loan terms are modified
- For testing and verification purposes

## Usage Example

```sql
-- Calculate payment schedule for an approved loan
EXEC sp_CalculatePaymentSchedule @ApplicationId = 123;

-- View the generated schedule
SELECT 
    PaymentNumber,
    DueDate,
    PaymentAmount,
    PrincipalAmount,
    InterestAmount,
    RemainingBalance
FROM PaymentSchedules
WHERE ApplicationId = 123
ORDER BY PaymentNumber;
```

## Verification Queries

### Check Total Interest
```sql
SELECT 
    ApplicationId,
    SUM(InterestAmount) AS TotalInterest,
    SUM(PrincipalAmount) AS TotalPrincipal,
    SUM(PaymentAmount) AS TotalPayments
FROM PaymentSchedules
WHERE ApplicationId = 123
GROUP BY ApplicationId;
```

### Verify Final Balance is Zero
```sql
SELECT 
    ApplicationId,
    PaymentNumber,
    RemainingBalance
FROM PaymentSchedules
WHERE ApplicationId = 123
  AND PaymentNumber = (SELECT MAX(PaymentNumber) FROM PaymentSchedules WHERE ApplicationId = 123);
```

## Notes

### Amortization Formula
The formula ensures that:
1. Each payment is the same amount (except the final payment)
2. Interest is calculated on the remaining balance
3. Principal portion increases over time as balance decreases
4. The loan is fully paid off at the end of the term

### Date Calculation
Due dates are calculated as monthly intervals from the current date. In a production system, you might want to:
- Use the loan approval date instead of GETDATE()
- Handle specific day-of-month requirements
- Account for business days or holidays

### Precision
All monetary calculations use DECIMAL(18,2) for precision. The monthly rate uses DECIMAL(10,8) to maintain accuracy in the amortization formula.

## Task Completion
✅ Task 6.3: Create sp_CalculatePaymentSchedule stored procedure
- All requirements implemented
- All tests passing
- Integrated with sp_ProcessLoanDecision
- Ready for use in the application
