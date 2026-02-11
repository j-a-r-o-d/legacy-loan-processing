-- Verification script for Task 2.2: Database Indexes
-- This script verifies that all required performance indexes exist

USE LoanProcessing;
GO

PRINT 'Verifying database indexes for Task 2.2...';
PRINT '';

-- Function to check if an index exists
DECLARE @IndexCount INT = 0;
DECLARE @TotalRequired INT = 8;

-- Check Customers indexes
PRINT 'Checking Customers table indexes:';
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Customers_SSN' AND object_id = OBJECT_ID('dbo.Customers'))
BEGIN
    PRINT '  ✓ IX_Customers_SSN exists';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_Customers_SSN MISSING';

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Customers_CreditScore' AND object_id = OBJECT_ID('dbo.Customers'))
BEGIN
    PRINT '  ✓ IX_Customers_CreditScore exists';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_Customers_CreditScore MISSING';

PRINT '';

-- Check LoanApplications indexes
PRINT 'Checking LoanApplications table indexes:';
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanApplications_Customer' AND object_id = OBJECT_ID('dbo.LoanApplications'))
BEGIN
    PRINT '  ✓ IX_LoanApplications_Customer exists';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_LoanApplications_Customer MISSING';

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanApplications_Status' AND object_id = OBJECT_ID('dbo.LoanApplications'))
BEGIN
    PRINT '  ✓ IX_LoanApplications_Status exists';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_LoanApplications_Status MISSING';

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanApplications_Date' AND object_id = OBJECT_ID('dbo.LoanApplications'))
BEGIN
    PRINT '  ✓ IX_LoanApplications_Date exists';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_LoanApplications_Date MISSING';

PRINT '';

-- Check LoanDecisions indexes
PRINT 'Checking LoanDecisions table indexes:';
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanDecisions_Application' AND object_id = OBJECT_ID('dbo.LoanDecisions'))
BEGIN
    PRINT '  ✓ IX_LoanDecisions_Application exists';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_LoanDecisions_Application MISSING';

PRINT '';

-- Check PaymentSchedules indexes
PRINT 'Checking PaymentSchedules table indexes:';
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PaymentSchedules_Application' AND object_id = OBJECT_ID('dbo.PaymentSchedules'))
BEGIN
    PRINT '  ✓ IX_PaymentSchedules_Application exists';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_PaymentSchedules_Application MISSING';

PRINT '';

-- Check InterestRates indexes
PRINT 'Checking InterestRates table indexes:';
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_InterestRates_Lookup' AND object_id = OBJECT_ID('dbo.InterestRates'))
BEGIN
    PRINT '  ✓ IX_InterestRates_Lookup exists (covers LoanType, credit score ranges, EffectiveDate)';
    SET @IndexCount = @IndexCount + 1;
END
ELSE
    PRINT '  ✗ IX_InterestRates_Lookup MISSING';

PRINT '';
PRINT '========================================';
PRINT 'Index Verification Summary:';
PRINT CONCAT('  Required indexes: ', @TotalRequired);
PRINT CONCAT('  Found indexes: ', @IndexCount);

IF @IndexCount = @TotalRequired
BEGIN
    PRINT '  Status: ✓ ALL INDEXES PRESENT';
    PRINT '';
    PRINT 'Task 2.2 Complete: All required performance indexes exist.';
END
ELSE
BEGIN
    PRINT CONCAT('  Status: ✗ MISSING ', (@TotalRequired - @IndexCount), ' INDEX(ES)');
    PRINT '';
    PRINT 'Task 2.2 Incomplete: Some indexes are missing.';
END
PRINT '========================================';
PRINT '';

-- Display detailed index information
PRINT 'Detailed Index Information:';
PRINT '';

SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexedColumns
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name IN ('Customers', 'LoanApplications', 'LoanDecisions', 'PaymentSchedules', 'InterestRates')
  AND i.name IS NOT NULL
  AND i.name LIKE 'IX_%'
GROUP BY t.name, i.name, i.type_desc
ORDER BY t.name, i.name;
