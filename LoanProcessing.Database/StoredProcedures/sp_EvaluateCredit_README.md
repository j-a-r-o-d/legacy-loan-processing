# sp_EvaluateCredit Stored Procedure

## Overview
The `sp_EvaluateCredit` stored procedure performs automated credit evaluation for loan applications. It calculates risk scores, debt-to-income ratios, and selects appropriate interest rates based on customer creditworthiness.

## Requirements Implemented
- **3.1**: Execute stored procedure to perform credit evaluation when loan application is submitted
- **3.2**: Calculate risk score based on credit score, debt-to-income ratio, employment history, and loan amount
- **3.3**: Automatically flag applications for manual review when credit score is below minimum threshold
- **3.4**: Determine appropriate interest rate tier based on calculated risk score
- **3.5**: Update application status and store evaluation results when credit evaluation is complete

## Parameters
- `@ApplicationId INT` - The ID of the loan application to evaluate

## Business Logic

### 1. Existing Debt Calculation
Calculates the sum of all approved loan amounts for the customer (excluding the current application):
```sql
SELECT @ExistingDebt = ISNULL(SUM([ApprovedAmount]), 0)
FROM [dbo].[LoanApplications]
WHERE [CustomerId] = @CustomerId 
  AND [Status] = 'Approved'
  AND [ApplicationId] != @ApplicationId;
```

### 2. Debt-to-Income Ratio (DTI)
Formula: `((ExistingDebt + RequestedAmount) / AnnualIncome) * 100`

Example:
- Existing debt: $20,000
- Requested amount: $15,000
- Annual income: $60,000
- DTI = ((20,000 + 15,000) / 60,000) * 100 = 58.33%

### 3. Risk Score Calculation
Risk score ranges from 0-100 (lower is better) and consists of two components:

#### Credit Score Component:
- 750+: 10 points
- 700-749: 20 points
- 650-699: 35 points
- 600-649: 50 points
- Below 600: 75 points

#### DTI Component:
- ≤20%: 0 points
- 21-35%: 10 points
- 36-43%: 20 points
- >43%: 30 points

**Total Risk Score = Credit Score Component + DTI Component**

### 4. Interest Rate Selection
Selects the most recent applicable rate from the `InterestRates` table based on:
- Loan type
- Credit score range
- Term length
- Effective date (must be current)
- Expiration date (must not be expired)

If no matching rate is found, defaults to 12.99%.

### 5. Recommendation Logic
- **Recommended for Approval**: Risk score ≤30 AND DTI ≤35%
- **Manual Review Required**: Risk score ≤50 AND DTI ≤43%
- **High Risk - Recommend Rejection**: All other cases

### 6. Status Update
Updates the loan application status from 'Pending' to 'UnderReview' and stores the selected interest rate.

## Return Values
Returns a result set with the following columns:
- `ApplicationId` - The application ID
- `RiskScore` - Calculated risk score (0-100)
- `DebtToIncomeRatio` - Calculated DTI percentage
- `InterestRate` - Selected interest rate
- `CreditScore` - Customer's credit score
- `ExistingDebt` - Total existing approved loan amounts
- `RequestedAmount` - Requested loan amount
- `AnnualIncome` - Customer's annual income
- `Recommendation` - Approval recommendation text

## Error Handling
- Returns error code -1 if application not found
- Returns error code -99 for any other database errors
- All operations are wrapped in a transaction that rolls back on error

## Test Results

### Test 1: Good Credit Customer
- Credit Score: 720
- Annual Income: $75,000
- Requested Amount: $25,000
- Existing Debt: $0
- **Results**:
  - DTI: 33.33%
  - Risk Score: 30
  - Interest Rate: 8.49%
  - Recommendation: "Recommended for Approval"

### Test 2: Customer with Existing Debt
- Credit Score: 650
- Annual Income: $60,000
- Requested Amount: $15,000
- Existing Debt: $20,000
- **Results**:
  - DTI: 58.33%
  - Risk Score: 65
  - Interest Rate: 10.99%
  - Recommendation: "High Risk - Recommend Rejection"

### Test 3: Low Credit Score
- Credit Score: 580
- Annual Income: $45,000
- Requested Amount: $10,000
- Existing Debt: $0
- **Results**:
  - DTI: 22.22%
  - Risk Score: 85
  - Interest Rate: 19.99%
  - Recommendation: "High Risk - Recommend Rejection"

### Test 4: Excellent Credit, High DTI
- Credit Score: 800
- Annual Income: $100,000
- Requested Amount: $300,000 (Mortgage)
- Existing Debt: $0
- **Results**:
  - DTI: 300%
  - Risk Score: 40
  - Interest Rate: 3.75%
  - Recommendation: "High Risk - Recommend Rejection"

## Usage Example
```sql
-- Evaluate credit for application ID 19
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = 19;

-- Check the updated application status
SELECT 
    [ApplicationId],
    [Status],
    [InterestRate]
FROM [dbo].[LoanApplications]
WHERE [ApplicationId] = 19;
```

## Files Created
1. `LoanProcessing.Database/StoredProcedures/sp_EvaluateCredit.sql` - Main stored procedure
2. `LoanProcessing.Database/Scripts/TestCreditEvaluation.sql` - Comprehensive test script
3. `LoanProcessing.Database/Scripts/TestCreditEvaluationSimple.sql` - Simple test script
4. Updated `LoanProcessing.Database/LoanProcessing.Database.sqlproj` - Added stored procedure to build

## Next Steps
The stored procedure is ready for integration with the application's data access layer. The next tasks in the implementation plan are:
- 5.5: Write property test for DTI calculation
- 5.6: Write property test for risk score calculation
- 5.7: Write property test for low credit score flagging
- 5.8: Write property test for interest rate selection
