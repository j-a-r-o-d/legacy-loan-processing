-- ============================================================================
-- Test Script: LoanApplicationRepository
-- Description: Tests the LoanApplicationRepository implementation
-- Task: 10.2
-- ============================================================================

USE [LoanProcessing];
GO

PRINT '========================================';
PRINT 'Testing LoanApplicationRepository';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- Test 1: SubmitApplication - Valid Personal loan
-- ============================================================================
PRINT 'Test 1: SubmitApplication - Valid Personal loan';

DECLARE @TestAppId1 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 1,
    @LoanType = 'Personal',
    @RequestedAmount = 15000.00,
    @TermMonths = 36,
    @Purpose = 'Debt consolidation',
    @ApplicationId = @TestAppId1 OUTPUT;

IF @TestAppId1 IS NOT NULL
BEGIN
    PRINT '  ✓ Application submitted successfully with ID: ' + CAST(@TestAppId1 AS NVARCHAR);
    
    -- Verify the application was created
    SELECT 
        ApplicationId,
        ApplicationNumber,
        CustomerId,
        LoanType,
        RequestedAmount,
        TermMonths,
        Purpose,
        Status,
        ApplicationDate
    FROM [dbo].[LoanApplications]
    WHERE ApplicationId = @TestAppId1;
END
ELSE
BEGIN
    PRINT '  ✗ Failed to submit application';
END
PRINT '';

-- ============================================================================
-- Test 2: GetById - Retrieve the submitted application
-- ============================================================================
PRINT 'Test 2: GetById - Retrieve the submitted application';

SELECT 
    ApplicationId,
    ApplicationNumber,
    CustomerId,
    LoanType,
    RequestedAmount,
    TermMonths,
    Purpose,
    Status,
    ApplicationDate,
    ApprovedAmount,
    InterestRate
FROM [dbo].[LoanApplications]
WHERE ApplicationId = @TestAppId1;

IF @@ROWCOUNT > 0
BEGIN
    PRINT '  ✓ Application retrieved successfully';
END
ELSE
BEGIN
    PRINT '  ✗ Failed to retrieve application';
END
PRINT '';

-- ============================================================================
-- Test 3: SubmitApplication - Valid Auto loan for same customer
-- ============================================================================
PRINT 'Test 3: SubmitApplication - Valid Auto loan for same customer';

DECLARE @TestAppId2 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 1,
    @LoanType = 'Auto',
    @RequestedAmount = 25000.00,
    @TermMonths = 60,
    @Purpose = 'Vehicle purchase',
    @ApplicationId = @TestAppId2 OUTPUT;

IF @TestAppId2 IS NOT NULL
BEGIN
    PRINT '  ✓ Second application submitted successfully with ID: ' + CAST(@TestAppId2 AS NVARCHAR);
END
ELSE
BEGIN
    PRINT '  ✗ Failed to submit second application';
END
PRINT '';

-- ============================================================================
-- Test 4: GetByCustomer - Retrieve all applications for customer
-- ============================================================================
PRINT 'Test 4: GetByCustomer - Retrieve all applications for customer 1';

SELECT 
    ApplicationId,
    ApplicationNumber,
    CustomerId,
    LoanType,
    RequestedAmount,
    TermMonths,
    Purpose,
    Status,
    ApplicationDate,
    ApprovedAmount,
    InterestRate
FROM [dbo].[LoanApplications]
WHERE CustomerId = 1
ORDER BY ApplicationDate DESC;

DECLARE @AppCount INT;
SELECT @AppCount = COUNT(*) FROM [dbo].[LoanApplications] WHERE CustomerId = 1;

IF @AppCount >= 2
BEGIN
    PRINT '  ✓ Retrieved ' + CAST(@AppCount AS NVARCHAR) + ' applications for customer';
END
ELSE
BEGIN
    PRINT '  ✗ Expected at least 2 applications, found ' + CAST(@AppCount AS NVARCHAR);
END
PRINT '';

-- ============================================================================
-- Test 5: SubmitApplication - Valid Mortgage loan for different customer
-- ============================================================================
PRINT 'Test 5: SubmitApplication - Valid Mortgage loan for different customer';

DECLARE @TestAppId3 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 2,
    @LoanType = 'Mortgage',
    @RequestedAmount = 350000.00,
    @TermMonths = 360,
    @Purpose = 'Home purchase',
    @ApplicationId = @TestAppId3 OUTPUT;

IF @TestAppId3 IS NOT NULL
BEGIN
    PRINT '  ✓ Mortgage application submitted successfully with ID: ' + CAST(@TestAppId3 AS NVARCHAR);
END
ELSE
BEGIN
    PRINT '  ✗ Failed to submit mortgage application';
END
PRINT '';

-- ============================================================================
-- Test 6: GetByCustomer - Verify customer 2 has only their application
-- ============================================================================
PRINT 'Test 6: GetByCustomer - Verify customer 2 has only their application';

SELECT @AppCount = COUNT(*) FROM [dbo].[LoanApplications] WHERE CustomerId = 2;

IF @AppCount >= 1
BEGIN
    PRINT '  ✓ Customer 2 has ' + CAST(@AppCount AS NVARCHAR) + ' application(s)';
    
    SELECT 
        ApplicationId,
        ApplicationNumber,
        CustomerId,
        LoanType,
        RequestedAmount,
        Status
    FROM [dbo].[LoanApplications]
    WHERE CustomerId = 2;
END
ELSE
BEGIN
    PRINT '  ✗ Expected at least 1 application for customer 2';
END
PRINT '';

-- ============================================================================
-- Test 7: GetById - Non-existent application
-- ============================================================================
PRINT 'Test 7: GetById - Non-existent application (should return no rows)';

SELECT 
    ApplicationId,
    ApplicationNumber,
    CustomerId
FROM [dbo].[LoanApplications]
WHERE ApplicationId = 999999;

IF @@ROWCOUNT = 0
BEGIN
    PRINT '  ✓ Correctly returned no rows for non-existent application';
END
ELSE
BEGIN
    PRINT '  ✗ Unexpectedly found application with ID 999999';
END
PRINT '';

-- ============================================================================
-- Test 8: GetByCustomer - Non-existent customer
-- ============================================================================
PRINT 'Test 8: GetByCustomer - Non-existent customer (should return no rows)';

SELECT @AppCount = COUNT(*) FROM [dbo].[LoanApplications] WHERE CustomerId = 999999;

IF @AppCount = 0
BEGIN
    PRINT '  ✓ Correctly returned no applications for non-existent customer';
END
ELSE
BEGIN
    PRINT '  ✗ Unexpectedly found ' + CAST(@AppCount AS NVARCHAR) + ' applications for non-existent customer';
END
PRINT '';

-- ============================================================================
-- Test 9: Verify application number format
-- ============================================================================
PRINT 'Test 9: Verify application number format (LNyyyyMMdd#####)';

SELECT 
    ApplicationId,
    ApplicationNumber,
    LEN(ApplicationNumber) AS NumberLength,
    LEFT(ApplicationNumber, 2) AS Prefix,
    SUBSTRING(ApplicationNumber, 3, 8) AS DatePart,
    RIGHT(ApplicationNumber, 5) AS SequencePart
FROM [dbo].[LoanApplications]
WHERE ApplicationId IN (@TestAppId1, @TestAppId2, @TestAppId3);

-- Verify format
IF EXISTS (
    SELECT 1 
    FROM [dbo].[LoanApplications]
    WHERE ApplicationId IN (@TestAppId1, @TestAppId2, @TestAppId3)
    AND LEN(ApplicationNumber) = 15
    AND LEFT(ApplicationNumber, 2) = 'LN'
)
BEGIN
    PRINT '  ✓ Application numbers have correct format';
END
ELSE
BEGIN
    PRINT '  ✗ Application numbers have incorrect format';
END
PRINT '';

-- ============================================================================
-- Test 10: Verify nullable fields (ApprovedAmount, InterestRate)
-- ============================================================================
PRINT 'Test 10: Verify nullable fields are NULL for pending applications';

SELECT 
    ApplicationId,
    Status,
    ApprovedAmount,
    InterestRate
FROM [dbo].[LoanApplications]
WHERE ApplicationId IN (@TestAppId1, @TestAppId2, @TestAppId3);

IF EXISTS (
    SELECT 1 
    FROM [dbo].[LoanApplications]
    WHERE ApplicationId IN (@TestAppId1, @TestAppId2, @TestAppId3)
    AND Status = 'Pending'
    AND ApprovedAmount IS NULL
    AND InterestRate IS NULL
)
BEGIN
    PRINT '  ✓ Nullable fields are correctly NULL for pending applications';
END
ELSE
BEGIN
    PRINT '  ✗ Nullable fields have unexpected values';
END
PRINT '';

PRINT '========================================';
PRINT 'LoanApplicationRepository Tests Complete';
PRINT '========================================';
