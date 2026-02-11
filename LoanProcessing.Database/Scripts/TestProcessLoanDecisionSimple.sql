-- ============================================================================
-- Simple Test Script: sp_ProcessLoanDecision
-- Description: Simple tests for the loan decision processing stored procedure
-- ============================================================================

USE [LoanProcessing]
GO

PRINT '========================================';
PRINT 'Testing sp_ProcessLoanDecision';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- Test 1: Process approval decision with default approved amount
-- ============================================================================
PRINT 'Test 1: Process approval decision with default approved amount';
PRINT '----------------------------------------------------------------';

-- Find an existing application in UnderReview status or create one
DECLARE @TestAppId1 INT;
SELECT TOP 1 @TestAppId1 = [ApplicationId]
FROM [dbo].[LoanApplications]
WHERE [Status] = 'UnderReview'
ORDER BY [ApplicationId] DESC;

-- If no UnderReview application exists, find a Pending one and evaluate it
IF @TestAppId1 IS NULL
BEGIN
    SELECT TOP 1 @TestAppId1 = [ApplicationId]
    FROM [dbo].[LoanApplications]
    WHERE [Status] = 'Pending'
    ORDER BY [ApplicationId] DESC;
    
    IF @TestAppId1 IS NOT NULL
    BEGIN
        EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId1;
    END
END

IF @TestAppId1 IS NOT NULL
BEGIN
    -- Get the requested amount before processing
    DECLARE @RequestedAmt1 DECIMAL(18,2);
    SELECT @RequestedAmt1 = [RequestedAmount]
    FROM [dbo].[LoanApplications]
    WHERE [ApplicationId] = @TestAppId1;
    
    -- Process approval decision (no approved amount specified, should default to requested)
    EXEC [dbo].[sp_ProcessLoanDecision]
        @ApplicationId = @TestAppId1,
        @Decision = 'Approved',
        @DecisionBy = 'Test Underwriter',
        @Comments = 'Test approval with default amount';
    
    -- Verify results
    SELECT 
        'Test 1 - Application Status' AS TestCase,
        [ApplicationId],
        [Status],
        [ApprovedAmount],
        [RequestedAmount],
        CASE 
            WHEN [Status] = 'Approved' AND [ApprovedAmount] = [RequestedAmount] 
            THEN 'PASS' 
            ELSE 'FAIL' 
        END AS Result
    FROM [dbo].[LoanApplications]
    WHERE [ApplicationId] = @TestAppId1;
    
    SELECT 
        'Test 1 - Decision Record' AS TestCase,
        [DecisionId],
        [Decision],
        [DecisionBy],
        [ApprovedAmount],
        CASE 
            WHEN [Decision] = 'Approved' AND [ApprovedAmount] = @RequestedAmt1
            THEN 'PASS' 
            ELSE 'FAIL' 
        END AS Result
    FROM [dbo].[LoanDecisions]
    WHERE [ApplicationId] = @TestAppId1
    ORDER BY [DecisionDate] DESC;
END
ELSE
BEGIN
    PRINT 'Test 1 Result: SKIPPED - No suitable application found';
END

PRINT '';

-- ============================================================================
-- Test 2: Process approval decision with specific approved amount
-- ============================================================================
PRINT 'Test 2: Process approval decision with specific approved amount';
PRINT '----------------------------------------------------------------';

-- Find another application in UnderReview status
DECLARE @TestAppId2 INT;
SELECT TOP 1 @TestAppId2 = [ApplicationId]
FROM [dbo].[LoanApplications]
WHERE [Status] = 'UnderReview'
  AND [ApplicationId] != ISNULL(@TestAppId1, 0)
ORDER BY [ApplicationId] DESC;

-- If no UnderReview application exists, find a Pending one and evaluate it
IF @TestAppId2 IS NULL
BEGIN
    SELECT TOP 1 @TestAppId2 = [ApplicationId]
    FROM [dbo].[LoanApplications]
    WHERE [Status] = 'Pending'
      AND [ApplicationId] != ISNULL(@TestAppId1, 0)
    ORDER BY [ApplicationId] DESC;
    
    IF @TestAppId2 IS NOT NULL
    BEGIN
        EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId2;
    END
END

IF @TestAppId2 IS NOT NULL
BEGIN
    -- Get the requested amount
    DECLARE @RequestedAmt2 DECIMAL(18,2);
    DECLARE @PartialAmt2 DECIMAL(18,2);
    SELECT @RequestedAmt2 = [RequestedAmount]
    FROM [dbo].[LoanApplications]
    WHERE [ApplicationId] = @TestAppId2;
    
    -- Approve for 80% of requested amount
    SET @PartialAmt2 = @RequestedAmt2 * 0.8;
    
    -- Process approval with lower amount
    EXEC [dbo].[sp_ProcessLoanDecision]
        @ApplicationId = @TestAppId2,
        @Decision = 'Approved',
        @DecisionBy = 'Test Underwriter',
        @Comments = 'Approved for lower amount due to DTI',
        @ApprovedAmount = @PartialAmt2;
    
    -- Verify results
    SELECT 
        'Test 2 - Partial Approval' AS TestCase,
        [ApplicationId],
        [Status],
        [ApprovedAmount],
        [RequestedAmount],
        CASE 
            WHEN [Status] = 'Approved' AND [ApprovedAmount] = @PartialAmt2 AND [RequestedAmount] = @RequestedAmt2
            THEN 'PASS' 
            ELSE 'FAIL' 
        END AS Result
    FROM [dbo].[LoanApplications]
    WHERE [ApplicationId] = @TestAppId2;
END
ELSE
BEGIN
    PRINT 'Test 2 Result: SKIPPED - No suitable application found';
END

PRINT '';

-- ============================================================================
-- Test 3: Process rejection decision
-- ============================================================================
PRINT 'Test 3: Process rejection decision';
PRINT '----------------------------------------------------------------';

-- Find another application in UnderReview status
DECLARE @TestAppId3 INT;
SELECT TOP 1 @TestAppId3 = [ApplicationId]
FROM [dbo].[LoanApplications]
WHERE [Status] = 'UnderReview'
  AND [ApplicationId] NOT IN (ISNULL(@TestAppId1, 0), ISNULL(@TestAppId2, 0))
ORDER BY [ApplicationId] DESC;

-- If no UnderReview application exists, find a Pending one and evaluate it
IF @TestAppId3 IS NULL
BEGIN
    SELECT TOP 1 @TestAppId3 = [ApplicationId]
    FROM [dbo].[LoanApplications]
    WHERE [Status] = 'Pending'
      AND [ApplicationId] NOT IN (ISNULL(@TestAppId1, 0), ISNULL(@TestAppId2, 0))
    ORDER BY [ApplicationId] DESC;
    
    IF @TestAppId3 IS NOT NULL
    BEGIN
        EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId3;
    END
END

IF @TestAppId3 IS NOT NULL
BEGIN
    -- Process rejection
    EXEC [dbo].[sp_ProcessLoanDecision]
        @ApplicationId = @TestAppId3,
        @Decision = 'Rejected',
        @DecisionBy = 'Test Underwriter',
        @Comments = 'Insufficient credit score and high DTI ratio';
    
    -- Verify results
    SELECT 
        'Test 3 - Rejection' AS TestCase,
        [ApplicationId],
        [Status],
        [ApprovedAmount],
        CASE 
            WHEN [Status] = 'Rejected' AND [ApprovedAmount] IS NULL
            THEN 'PASS' 
            ELSE 'FAIL' 
        END AS Result
    FROM [dbo].[LoanApplications]
    WHERE [ApplicationId] = @TestAppId3;
    
    SELECT 
        'Test 3 - Rejection Record' AS TestCase,
        [DecisionId],
        [Decision],
        [Comments],
        CASE 
            WHEN [Decision] = 'Rejected' AND [Comments] IS NOT NULL
            THEN 'PASS' 
            ELSE 'FAIL' 
        END AS Result
    FROM [dbo].[LoanDecisions]
    WHERE [ApplicationId] = @TestAppId3
    ORDER BY [DecisionDate] DESC;
END
ELSE
BEGIN
    PRINT 'Test 3 Result: SKIPPED - No suitable application found';
END

PRINT '';

-- ============================================================================
-- Test 4: Validation - Approved amount exceeds requested amount (should fail)
-- ============================================================================
PRINT 'Test 4: Validation - Approved amount exceeds requested amount';
PRINT '----------------------------------------------------------------';

-- Find another application in UnderReview status
DECLARE @TestAppId4 INT;
SELECT TOP 1 @TestAppId4 = [ApplicationId]
FROM [dbo].[LoanApplications]
WHERE [Status] = 'UnderReview'
  AND [ApplicationId] NOT IN (ISNULL(@TestAppId1, 0), ISNULL(@TestAppId2, 0), ISNULL(@TestAppId3, 0))
ORDER BY [ApplicationId] DESC;

-- If no UnderReview application exists, find a Pending one and evaluate it
IF @TestAppId4 IS NULL
BEGIN
    SELECT TOP 1 @TestAppId4 = [ApplicationId]
    FROM [dbo].[LoanApplications]
    WHERE [Status] = 'Pending'
      AND [ApplicationId] NOT IN (ISNULL(@TestAppId1, 0), ISNULL(@TestAppId2, 0), ISNULL(@TestAppId3, 0))
    ORDER BY [ApplicationId] DESC;
    
    IF @TestAppId4 IS NOT NULL
    BEGIN
        EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId4;
    END
END

IF @TestAppId4 IS NOT NULL
BEGIN
    -- Get the requested amount
    DECLARE @RequestedAmt4 DECIMAL(18,2);
    DECLARE @OverAmt4 DECIMAL(18,2);
    SELECT @RequestedAmt4 = [RequestedAmount]
    FROM [dbo].[LoanApplications]
    WHERE [ApplicationId] = @TestAppId4;
    
    SET @OverAmt4 = @RequestedAmt4 * 1.5;
    
    -- Try to approve for more than requested (should fail)
    BEGIN TRY
        EXEC [dbo].[sp_ProcessLoanDecision]
            @ApplicationId = @TestAppId4,
            @Decision = 'Approved',
            @DecisionBy = 'Test Underwriter',
            @Comments = 'Test over-approval',
            @ApprovedAmount = @OverAmt4;
        
        PRINT 'Test 4 Result: FAIL - Should have raised error for approved amount exceeding requested';
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE '%cannot exceed requested amount%'
            PRINT 'Test 4 Result: PASS - Correctly rejected over-approval';
        ELSE
            PRINT 'Test 4 Result: FAIL - Wrong error: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT 'Test 4 Result: SKIPPED - No suitable application found';
END

PRINT '';

-- ============================================================================
-- Test 5: Validation - Application not found (should fail)
-- ============================================================================
PRINT 'Test 5: Validation - Application not found';
PRINT '----------------------------------------------------------------';

BEGIN TRY
    EXEC [dbo].[sp_ProcessLoanDecision]
        @ApplicationId = 999999,
        @Decision = 'Approved',
        @DecisionBy = 'Test Underwriter',
        @Comments = 'Test non-existent application';
    
    PRINT 'Test 5 Result: FAIL - Should have raised error for non-existent application';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%not found%'
        PRINT 'Test 5 Result: PASS - Correctly rejected non-existent application';
    ELSE
        PRINT 'Test 5 Result: FAIL - Wrong error: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- ============================================================================
-- Summary
-- ============================================================================
PRINT '========================================';
PRINT 'Test Summary';
PRINT '========================================';
PRINT 'All tests completed. Review results above.';
PRINT '';

