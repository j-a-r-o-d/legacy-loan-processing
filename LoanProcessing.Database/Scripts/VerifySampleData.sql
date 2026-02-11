-- Verification script for sample data initialization (Task 2.3)
-- This script verifies that sample data has been loaded correctly

USE LoanProcessing;
GO

PRINT '========================================';
PRINT 'Verifying Sample Data (Task 2.3)';
PRINT '========================================';
PRINT '';

-- Check Customers
DECLARE @CustomerCount INT;
SELECT @CustomerCount = COUNT(*) FROM [dbo].[Customers];
PRINT 'Customers Table:';
PRINT '  Total records: ' + CAST(@CustomerCount AS NVARCHAR(10));

IF @CustomerCount >= 13
BEGIN
    PRINT '  ✓ Sample customers loaded';
    
    -- Show credit score distribution
    PRINT '';
    PRINT '  Credit Score Distribution:';
    SELECT 
        CASE 
            WHEN CreditScore >= 750 THEN '  Excellent (750-850)'
            WHEN CreditScore >= 700 THEN '  Good (700-749)'
            WHEN CreditScore >= 650 THEN '  Fair (650-699)'
            WHEN CreditScore >= 600 THEN '  Poor (600-649)'
            ELSE '  Very Poor (300-599)'
        END AS CreditTier,
        COUNT(*) AS CustomerCount,
        MIN(CreditScore) AS MinScore,
        MAX(CreditScore) AS MaxScore,
        AVG(AnnualIncome) AS AvgIncome
    FROM [dbo].[Customers]
    GROUP BY 
        CASE 
            WHEN CreditScore >= 750 THEN '  Excellent (750-850)'
            WHEN CreditScore >= 700 THEN '  Good (700-749)'
            WHEN CreditScore >= 650 THEN '  Fair (650-699)'
            WHEN CreditScore >= 600 THEN '  Poor (600-649)'
            ELSE '  Very Poor (300-599)'
        END
    ORDER BY MIN(CreditScore) DESC;
END
ELSE
BEGIN
    PRINT '  ✗ Expected at least 13 customers, found ' + CAST(@CustomerCount AS NVARCHAR(10));
END
PRINT '';

-- Check InterestRates
DECLARE @RateCount INT;
SELECT @RateCount = COUNT(*) FROM [dbo].[InterestRates];
PRINT 'InterestRates Table:';
PRINT '  Total records: ' + CAST(@RateCount AS NVARCHAR(10));

IF @RateCount >= 60
BEGIN
    PRINT '  ✓ Interest rate tables loaded';
    
    -- Show rate distribution by loan type
    PRINT '';
    PRINT '  Rate Distribution by Loan Type:';
    SELECT 
        '  ' + LoanType AS LoanType,
        COUNT(*) AS RateRecords,
        MIN(Rate) AS MinRate,
        MAX(Rate) AS MaxRate
    FROM [dbo].[InterestRates]
    GROUP BY LoanType
    ORDER BY LoanType;
END
ELSE
BEGIN
    PRINT '  ✗ Expected at least 60 rate records, found ' + CAST(@RateCount AS NVARCHAR(10));
END
PRINT '';

-- Check LoanApplications
DECLARE @AppCount INT;
SELECT @AppCount = COUNT(*) FROM [dbo].[LoanApplications];
PRINT 'LoanApplications Table:';
PRINT '  Total records: ' + CAST(@AppCount AS NVARCHAR(10));

IF @AppCount >= 14
BEGIN
    PRINT '  ✓ Sample loan applications loaded';
    
    -- Show application status distribution
    PRINT '';
    PRINT '  Application Status Distribution:';
    SELECT 
        '  ' + Status AS Status,
        COUNT(*) AS ApplicationCount,
        SUM(RequestedAmount) AS TotalRequested,
        AVG(RequestedAmount) AS AvgRequested
    FROM [dbo].[LoanApplications]
    GROUP BY Status
    ORDER BY 
        CASE Status
            WHEN 'Pending' THEN 1
            WHEN 'UnderReview' THEN 2
            WHEN 'Approved' THEN 3
            WHEN 'Rejected' THEN 4
        END;
    
    -- Show loan type distribution
    PRINT '';
    PRINT '  Loan Type Distribution:';
    SELECT 
        '  ' + LoanType AS LoanType,
        COUNT(*) AS ApplicationCount,
        AVG(RequestedAmount) AS AvgAmount
    FROM [dbo].[LoanApplications]
    GROUP BY LoanType
    ORDER BY LoanType;
END
ELSE
BEGIN
    PRINT '  ✗ Expected at least 14 applications, found ' + CAST(@AppCount AS NVARCHAR(10));
END
PRINT '';

-- Check LoanDecisions
DECLARE @DecisionCount INT;
SELECT @DecisionCount = COUNT(*) FROM [dbo].[LoanDecisions];
PRINT 'LoanDecisions Table:';
PRINT '  Total records: ' + CAST(@DecisionCount AS NVARCHAR(10));

IF @DecisionCount >= 8
BEGIN
    PRINT '  ✓ Sample loan decisions loaded';
    
    -- Show decision distribution
    PRINT '';
    PRINT '  Decision Distribution:';
    SELECT 
        '  ' + Decision AS Decision,
        COUNT(*) AS DecisionCount,
        AVG(RiskScore) AS AvgRiskScore,
        AVG(DebtToIncomeRatio) AS AvgDTI
    FROM [dbo].[LoanDecisions]
    GROUP BY Decision
    ORDER BY Decision;
END
ELSE
BEGIN
    PRINT '  ✗ Expected at least 8 decisions, found ' + CAST(@DecisionCount AS NVARCHAR(10));
END
PRINT '';

-- Summary
PRINT '========================================';
PRINT 'Verification Summary:';
PRINT '========================================';

DECLARE @AllChecksPass BIT = 1;

IF @CustomerCount < 13 SET @AllChecksPass = 0;
IF @RateCount < 60 SET @AllChecksPass = 0;
IF @AppCount < 14 SET @AllChecksPass = 0;
IF @DecisionCount < 8 SET @AllChecksPass = 0;

IF @AllChecksPass = 1
BEGIN
    PRINT '✓ All sample data verification checks passed!';
    PRINT '';
    PRINT 'Task 2.3 Complete: Sample data successfully initialized.';
    PRINT '';
    PRINT 'You can now:';
    PRINT '  • Test stored procedures with realistic data';
    PRINT '  • Process pending applications';
    PRINT '  • Generate portfolio reports';
    PRINT '  • Test the web application';
END
ELSE
BEGIN
    PRINT '✗ Some verification checks failed.';
    PRINT 'Please run InitializeSampleData.sql to load sample data.';
END

PRINT '========================================';
GO
