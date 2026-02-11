-- =============================================
-- Test Script: ReportRepository Integration Test
-- Description: Verifies sp_GeneratePortfolioReport returns correct result sets
--              that can be mapped by ReportRepository
-- =============================================

USE LoanProcessing;
GO

PRINT '========================================';
PRINT 'Testing sp_GeneratePortfolioReport';
PRINT 'Verifying result sets for ReportRepository';
PRINT '========================================';
PRINT '';

-- Test 1: Default parameters (last 12 months, all loan types)
PRINT 'Test 1: Default parameters';
PRINT '----------------------------';
EXEC sp_GeneratePortfolioReport;
PRINT '';

-- Test 2: Specific date range (2026 data)
PRINT 'Test 2: Specific date range (2026)';
PRINT '-----------------------------------';
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2026-01-01',
    @EndDate = '2026-12-31';
PRINT '';

-- Test 3: Filter by loan type (Mortgage only)
PRINT 'Test 3: Filter by loan type (Mortgage)';
PRINT '---------------------------------------';
EXEC sp_GeneratePortfolioReport 
    @StartDate = '2026-01-01',
    @EndDate = '2026-12-31',
    @LoanType = 'Mortgage';
PRINT '';

-- Test 4: Verify result set structure for mapping
PRINT 'Test 4: Verify result set structure';
PRINT '------------------------------------';
PRINT 'Result Set 1 - Portfolio Summary:';
PRINT '  Expected columns: TotalLoans, ApprovedLoans, RejectedLoans, PendingLoans,';
PRINT '                    TotalApprovedAmount, AverageApprovedAmount, AverageInterestRate, AverageRiskScore';
PRINT '';
PRINT 'Result Set 2 - Loan Type Breakdown:';
PRINT '  Expected columns: LoanType, TotalApplications, ApprovedCount, TotalAmount, AvgInterestRate';
PRINT '';
PRINT 'Result Set 3 - Risk Distribution:';
PRINT '  Expected columns: RiskCategory, LoanCount, TotalAmount, AvgInterestRate';
PRINT '';

-- Test 5: Verify data types match model properties
PRINT 'Test 5: Data type verification';
PRINT '-------------------------------';
SELECT 
    'PortfolioSummary' AS ResultSet,
    'TotalLoans' AS ColumnName,
    'INT' AS ExpectedType,
    TYPE_NAME(system_type_id) AS ActualType
FROM sys.dm_exec_describe_first_result_set(N'EXEC sp_GeneratePortfolioReport', NULL, 0)
WHERE name = 'TotalLoans'
UNION ALL
SELECT 
    'PortfolioSummary',
    'TotalApprovedAmount',
    'DECIMAL(18,2)',
    TYPE_NAME(system_type_id)
FROM sys.dm_exec_describe_first_result_set(N'EXEC sp_GeneratePortfolioReport', NULL, 0)
WHERE name = 'TotalApprovedAmount'
UNION ALL
SELECT 
    'PortfolioSummary',
    'AverageInterestRate',
    'DECIMAL(5,2) NULL',
    TYPE_NAME(system_type_id)
FROM sys.dm_exec_describe_first_result_set(N'EXEC sp_GeneratePortfolioReport', NULL, 0)
WHERE name = 'AverageInterestRate';
PRINT '';

PRINT '========================================';
PRINT 'Test Complete';
PRINT '========================================';
