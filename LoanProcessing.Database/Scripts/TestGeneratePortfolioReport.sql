-- =============================================
-- Test Script: sp_GeneratePortfolioReport
-- Description: Tests the portfolio report generation stored procedure
-- =============================================

USE LoanProcessing;
GO

PRINT '========================================';
PRINT 'Testing sp_GeneratePortfolioReport';
PRINT '========================================';
PRINT '';

-- Test 1: Generate report for all loans (default date range - last 12 months)
PRINT 'Test 1: Portfolio report with default date range (last 12 months)';
PRINT '-------------------------------------------------------------------';
EXEC sp_GeneratePortfolioReport;
PRINT '';

-- Test 2: Generate report with specific date range
PRINT 'Test 2: Portfolio report with specific date range (2024-01-01 to 2024-12-31)';
PRINT '-----------------------------------------------------------------------------';
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31';
PRINT '';

-- Test 3: Generate report filtered by loan type (Personal)
PRINT 'Test 3: Portfolio report filtered by Personal loans';
PRINT '----------------------------------------------------';
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31',
    @LoanType = 'Personal';
PRINT '';

-- Test 4: Generate report filtered by loan type (Mortgage)
PRINT 'Test 4: Portfolio report filtered by Mortgage loans';
PRINT '----------------------------------------------------';
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31',
    @LoanType = 'Mortgage';
PRINT '';

-- Test 5: Generate report filtered by loan type (Auto)
PRINT 'Test 5: Portfolio report filtered by Auto loans';
PRINT '------------------------------------------------';
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31',
    @LoanType = 'Auto';
PRINT '';

-- Test 6: Generate report for a narrow date range
PRINT 'Test 6: Portfolio report for narrow date range (last 30 days)';
PRINT '--------------------------------------------------------------';
DECLARE @EndDate DATE = GETDATE();
DECLARE @StartDate DATE = DATEADD(DAY, -30, @EndDate);
EXEC sp_GeneratePortfolioReport 
    @StartDate = @StartDate,
    @EndDate = @EndDate;
PRINT '';

-- Test 7: Verify result set structure
PRINT 'Test 7: Verify result set structure and data types';
PRINT '---------------------------------------------------';
PRINT 'Expected Result Set 1 (Portfolio Summary):';
PRINT '  - TotalLoans (int)';
PRINT '  - ApprovedLoans (int)';
PRINT '  - RejectedLoans (int)';
PRINT '  - PendingLoans (int)';
PRINT '  - TotalApprovedAmount (decimal)';
PRINT '  - AverageApprovedAmount (decimal)';
PRINT '  - AverageInterestRate (decimal)';
PRINT '  - AverageRiskScore (decimal)';
PRINT '';
PRINT 'Expected Result Set 2 (Breakdown by Loan Type):';
PRINT '  - LoanType (nvarchar)';
PRINT '  - TotalApplications (int)';
PRINT '  - ApprovedCount (int)';
PRINT '  - TotalAmount (decimal)';
PRINT '  - AvgInterestRate (decimal)';
PRINT '';
PRINT 'Expected Result Set 3 (Risk Distribution):';
PRINT '  - RiskCategory (nvarchar)';
PRINT '  - LoanCount (int)';
PRINT '  - TotalAmount (decimal)';
PRINT '  - AvgInterestRate (decimal)';
PRINT '';

-- Test 8: Verify calculations with known data
PRINT 'Test 8: Verify calculations with sample data';
PRINT '---------------------------------------------';
PRINT 'Checking approved loans count and total amount...';
SELECT 
    COUNT(*) AS ExpectedApprovedCount,
    SUM(ApprovedAmount) AS ExpectedTotalAmount,
    AVG(ApprovedAmount) AS ExpectedAvgAmount,
    AVG(InterestRate) AS ExpectedAvgRate
FROM LoanApplications
WHERE Status = 'Approved'
  AND ApplicationDate >= DATEADD(YEAR, -1, GETDATE());
PRINT '';

-- Test 9: Verify risk distribution categories
PRINT 'Test 9: Verify risk distribution categories';
PRINT '--------------------------------------------';
SELECT 
    CASE 
        WHEN ld.RiskScore <= 20 THEN 'Low Risk (0-20)'
        WHEN ld.RiskScore <= 40 THEN 'Medium Risk (21-40)'
        WHEN ld.RiskScore <= 60 THEN 'High Risk (41-60)'
        ELSE 'Very High Risk (61+)'
    END AS RiskCategory,
    COUNT(*) AS ExpectedCount,
    MIN(ld.RiskScore) AS MinRiskScore,
    MAX(ld.RiskScore) AS MaxRiskScore
FROM LoanApplications la
INNER JOIN LoanDecisions ld ON la.ApplicationId = ld.ApplicationId
WHERE la.Status = 'Approved'
  AND la.ApplicationDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY CASE 
    WHEN ld.RiskScore <= 20 THEN 'Low Risk (0-20)'
    WHEN ld.RiskScore <= 40 THEN 'Medium Risk (21-40)'
    WHEN ld.RiskScore <= 60 THEN 'High Risk (41-60)'
    ELSE 'Very High Risk (61+)'
END
ORDER BY MIN(ld.RiskScore);
PRINT '';

-- Test 10: Verify loan type breakdown
PRINT 'Test 10: Verify loan type breakdown';
PRINT '------------------------------------';
SELECT 
    LoanType,
    COUNT(*) AS ExpectedTotalApplications,
    COUNT(CASE WHEN Status = 'Approved' THEN 1 END) AS ExpectedApprovedCount,
    SUM(CASE WHEN Status = 'Approved' THEN ApprovedAmount ELSE 0 END) AS ExpectedTotalAmount
FROM LoanApplications
WHERE ApplicationDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY LoanType
ORDER BY ExpectedTotalAmount DESC;
PRINT '';

PRINT '========================================';
PRINT 'All tests completed';
PRINT '========================================';
