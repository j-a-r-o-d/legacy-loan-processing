# sp_GeneratePortfolioReport - Portfolio Reporting Stored Procedure

## Overview

The `sp_GeneratePortfolioReport` stored procedure generates comprehensive portfolio reports for loan management analysis. It provides three result sets containing portfolio summary statistics, loan type breakdown, and risk distribution analysis.

## Requirements Validated

- **Requirement 6.1**: Aggregate loan data for portfolio reporting
- **Requirement 6.2**: Calculate total outstanding loan balances by loan type and risk category
- **Requirement 6.3**: Filter loans by date range
- **Requirement 6.4**: Calculate portfolio metrics (average loan size, average interest rate)
- **Requirement 6.5**: Group loans by credit score ranges and calculate exposure percentages

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| @StartDate | DATE | No | Last 12 months | Start date for filtering loan applications |
| @EndDate | DATE | No | Current date | End date for filtering loan applications |
| @LoanType | NVARCHAR(20) | No | NULL (all types) | Filter by specific loan type (Personal, Auto, Mortgage, Business) |

## Result Sets

### Result Set 1: Portfolio Summary

Aggregate statistics across all loans in the specified date range.

| Column | Type | Description |
|--------|------|-------------|
| TotalLoans | INT | Total number of loan applications |
| ApprovedLoans | INT | Number of approved loans |
| RejectedLoans | INT | Number of rejected loans |
| PendingLoans | INT | Number of pending/under review loans |
| TotalApprovedAmount | DECIMAL(18,2) | Sum of all approved loan amounts |
| AverageApprovedAmount | DECIMAL(18,2) | Average approved loan amount |
| AverageInterestRate | DECIMAL(5,2) | Average interest rate for approved loans |
| AverageRiskScore | INT | Average risk score across all evaluated loans |

### Result Set 2: Breakdown by Loan Type

Statistics grouped by loan type (Personal, Auto, Mortgage, Business).

| Column | Type | Description |
|--------|------|-------------|
| LoanType | NVARCHAR(20) | Type of loan |
| TotalApplications | INT | Total applications for this loan type |
| ApprovedCount | INT | Number of approved loans |
| TotalAmount | DECIMAL(18,2) | Total approved amount for this loan type |
| AvgInterestRate | DECIMAL(5,2) | Average interest rate for this loan type |

Ordered by TotalAmount descending.

### Result Set 3: Risk Distribution

Statistics grouped by risk score ranges.

| Column | Type | Description |
|--------|------|-------------|
| RiskCategory | NVARCHAR(50) | Risk category label |
| LoanCount | INT | Number of loans in this risk category |
| TotalAmount | DECIMAL(18,2) | Total approved amount in this category |
| AvgInterestRate | DECIMAL(5,2) | Average interest rate for this category |

**Risk Categories:**
- Low Risk (0-20): Risk scores 0-20
- Medium Risk (21-40): Risk scores 21-40
- High Risk (41-60): Risk scores 41-60
- Very High Risk (61+): Risk scores 61 and above

Ordered by minimum risk score ascending.

## Usage Examples

### Example 1: Default Report (Last 12 Months)

```sql
EXEC sp_GeneratePortfolioReport;
```

Generates a report for all loan types from the last 12 months to current date.

### Example 2: Specific Date Range

```sql
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2026-01-01',
    @EndDate = '2026-12-31';
```

Generates a report for all loans in the year 2026.

### Example 3: Filter by Loan Type

```sql
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2026-01-01',
    @EndDate = '2026-12-31',
    @LoanType = 'Mortgage';
```

Generates a report for only Mortgage loans in 2026.

### Example 4: Recent Activity (Last 30 Days)

```sql
DECLARE @EndDate DATE = GETDATE();
DECLARE @StartDate DATE = DATEADD(DAY, -30, @EndDate);

EXEC sp_GeneratePortfolioReport 
    @StartDate = @StartDate,
    @EndDate = @EndDate;
```

Generates a report for the last 30 days of activity.

## Business Logic

### Date Range Filtering

- If @StartDate is NULL, defaults to 12 months before current date
- If @EndDate is NULL, defaults to current date
- Filters based on LoanApplications.ApplicationDate
- Date range is inclusive (BETWEEN @StartDate AND @EndDate)

### Portfolio Summary Calculations

- **TotalLoans**: COUNT(DISTINCT ApplicationId) - all applications in date range
- **ApprovedLoans**: COUNT where Status = 'Approved'
- **RejectedLoans**: COUNT where Status = 'Rejected'
- **PendingLoans**: COUNT where Status IN ('Pending', 'UnderReview')
- **TotalApprovedAmount**: SUM of ApprovedAmount for approved loans
- **AverageApprovedAmount**: AVG of ApprovedAmount for approved loans
- **AverageInterestRate**: AVG of InterestRate for approved loans
- **AverageRiskScore**: AVG of RiskScore from LoanDecisions (where available)

### Loan Type Breakdown

- Groups by LoanType
- Counts total applications and approved applications
- Sums approved amounts
- Calculates average interest rate for approved loans
- Ordered by total amount descending (highest volume first)

### Risk Distribution

- Only includes approved loans with decision records
- Groups by risk score ranges (0-20, 21-40, 41-60, 61+)
- Counts loans in each category
- Sums approved amounts per category
- Calculates average interest rate per category
- Ordered by minimum risk score (lowest risk first)

## Performance Considerations

### Indexes Used

- **IX_LoanApplications_Date**: Optimizes date range filtering
- **IX_LoanApplications_Status**: Optimizes status filtering
- **IX_LoanDecisions_Application**: Optimizes join to LoanDecisions

### Query Optimization

- Uses LEFT JOIN for LoanDecisions to include applications without decisions
- Uses INNER JOIN for risk distribution (only approved loans with decisions)
- Applies date range filter early in WHERE clause
- Uses CASE expressions for conditional aggregation

## Testing

Run the test script to verify functionality:

```bash
sqlcmd -S YOUR_SERVER_NAME -E -d LoanProcessing -i "LoanProcessing.Database/Scripts/TestGeneratePortfolioReport.sql"
```

The test script validates:
1. Default date range behavior
2. Specific date range filtering
3. Loan type filtering (Personal, Mortgage, Auto)
4. Result set structure and data types
5. Calculation accuracy against raw data
6. Risk distribution categories
7. Loan type breakdown

## Sample Output

```
TotalLoans  ApprovedLoans RejectedLoans PendingLoans TotalApprovedAmount  AverageApprovedAmount  AverageInterestRate  AverageRiskScore
----------- ------------- ------------- ------------ -------------------- ---------------------- -------------------- ----------------
         11             6             2            3            625000.00              104166.67                 4.50               40

LoanType    TotalApplications ApprovedCount TotalAmount    AvgInterestRate
----------- ----------------- ------------- -------------- ---------------
Mortgage                    2             2      550000.00            3.75
Auto                        3             2       50000.00            NULL
Personal                    5             2       25000.00            5.99
Business                    1             0            .00            NULL

RiskCategory         LoanCount   TotalAmount    AvgInterestRate
-------------------- ----------- -------------- ---------------
Medium Risk (21-40)            1      350000.00            3.75
Very High Risk (61+)           5      275000.00            4.87
```

## Integration Points

### Application Layer

The stored procedure is called by:
- **IReportRepository.GeneratePortfolioReport()**: Data access layer
- **ReportService.GeneratePortfolioReport()**: Service layer
- **ReportController.Portfolio()**: MVC controller

### Report Views

The three result sets are mapped to:
- **PortfolioSummaryViewModel**: First result set
- **LoanTypeBreakdownViewModel**: Second result set
- **RiskDistributionViewModel**: Third result set

## Error Handling

The stored procedure uses:
- SET NOCOUNT ON to suppress row count messages
- No explicit error handling (relies on SQL Server default behavior)
- Returns empty result sets if no data matches criteria

## Maintenance Notes

### Adding New Loan Types

If new loan types are added to the system:
1. No changes needed to this stored procedure
2. New types will automatically appear in the loan type breakdown
3. Ensure the LoanApplications.LoanType CHECK constraint is updated

### Modifying Risk Categories

To change risk score ranges:
1. Update the CASE expressions in the risk distribution query
2. Update the ORDER BY clause if category ordering changes
3. Update this documentation with new ranges

### Performance Tuning

If performance degrades with large datasets:
1. Verify indexes are present and being used
2. Consider adding filtered indexes for specific date ranges
3. Consider materialized views for frequently-run reports
4. Monitor query execution plans

## Related Stored Procedures

- **sp_EvaluateCredit**: Calculates risk scores used in risk distribution
- **sp_ProcessLoanDecision**: Creates decision records used in reporting
- **sp_SubmitLoanApplication**: Creates applications included in reports

## Version History

- **v1.0** (2026-02-09): Initial implementation
  - Portfolio summary with 8 metrics
  - Loan type breakdown with 4 metrics
  - Risk distribution with 4 categories
  - Date range and loan type filtering
