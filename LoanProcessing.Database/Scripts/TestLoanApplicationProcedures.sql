-- ============================================================================
-- Test Script: sp_SubmitLoanApplication
-- Description: Tests the loan application submission stored procedure
-- ============================================================================

USE [LoanProcessing]
GO

PRINT '========================================';
PRINT 'Testing sp_SubmitLoanApplication';
PRINT '========================================';
PRINT '';

-- Test 1: Valid Personal loan application
PRINT 'Test 1: Valid Personal loan application';
DECLARE @AppId1 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 1,
    @LoanType = 'Personal',
    @RequestedAmount = 25000.00,
    @TermMonths = 60,
    @Purpose = 'Debt consolidation',
    @ApplicationId = @AppId1 OUTPUT;

IF @AppId1 IS NOT NULL
    PRINT 'SUCCESS: Application created with ID: ' + CAST(@AppId1 AS NVARCHAR);
ELSE
    PRINT 'FAILED: Application was not created';

-- Verify the application
SELECT 
    [ApplicationId],
    [ApplicationNumber],
    [CustomerId],
    [LoanType],
    [RequestedAmount],
    [TermMonths],
    [Purpose],
    [Status],
    [ApplicationDate]
FROM [dbo].[LoanApplications]
WHERE [ApplicationId] = @AppId1;
PRINT '';

-- Test 2: Valid Auto loan application
PRINT 'Test 2: Valid Auto loan application';
DECLARE @AppId2 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 2,
    @LoanType = 'Auto',
    @RequestedAmount = 35000.00,
    @TermMonths = 72,
    @Purpose = 'Vehicle purchase',
    @ApplicationId = @AppId2 OUTPUT;

IF @AppId2 IS NOT NULL
    PRINT 'SUCCESS: Application created with ID: ' + CAST(@AppId2 AS NVARCHAR);
ELSE
    PRINT 'FAILED: Application was not created';
PRINT '';

-- Test 3: Valid Mortgage loan application
PRINT 'Test 3: Valid Mortgage loan application';
DECLARE @AppId3 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 3,
    @LoanType = 'Mortgage',
    @RequestedAmount = 350000.00,
    @TermMonths = 360,
    @Purpose = 'Home purchase',
    @ApplicationId = @AppId3 OUTPUT;

IF @AppId3 IS NOT NULL
    PRINT 'SUCCESS: Application created with ID: ' + CAST(@AppId3 AS NVARCHAR);
ELSE
    PRINT 'FAILED: Application was not created';
PRINT '';

-- Test 4: Valid Business loan application
PRINT 'Test 4: Valid Business loan application';
DECLARE @AppId4 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 4,
    @LoanType = 'Business',
    @RequestedAmount = 150000.00,
    @TermMonths = 120,
    @Purpose = 'Business expansion',
    @ApplicationId = @AppId4 OUTPUT;

IF @AppId4 IS NOT NULL
    PRINT 'SUCCESS: Application created with ID: ' + CAST(@AppId4 AS NVARCHAR);
ELSE
    PRINT 'FAILED: Application was not created';
PRINT '';

-- Test 5: Invalid customer (should fail)
PRINT 'Test 5: Invalid customer (should fail)';
BEGIN TRY
    DECLARE @AppId5 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 99999,
        @LoanType = 'Personal',
        @RequestedAmount = 10000.00,
        @TermMonths = 36,
        @Purpose = 'Test',
        @ApplicationId = @AppId5 OUTPUT;
    PRINT 'FAILED: Should have raised an error for invalid customer';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected invalid customer - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 6: Loan amount exceeds Personal loan maximum (should fail)
PRINT 'Test 6: Loan amount exceeds Personal loan maximum (should fail)';
BEGIN TRY
    DECLARE @AppId6 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Personal',
        @RequestedAmount = 75000.00,
        @TermMonths = 60,
        @Purpose = 'Test',
        @ApplicationId = @AppId6 OUTPUT;
    PRINT 'FAILED: Should have raised an error for exceeding maximum';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected excessive amount - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 7: Loan amount exceeds Auto loan maximum (should fail)
PRINT 'Test 7: Loan amount exceeds Auto loan maximum (should fail)';
BEGIN TRY
    DECLARE @AppId7 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Auto',
        @RequestedAmount = 100000.00,
        @TermMonths = 60,
        @Purpose = 'Test',
        @ApplicationId = @AppId7 OUTPUT;
    PRINT 'FAILED: Should have raised an error for exceeding maximum';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected excessive amount - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 8: Loan amount exceeds Mortgage loan maximum (should fail)
PRINT 'Test 8: Loan amount exceeds Mortgage loan maximum (should fail)';
BEGIN TRY
    DECLARE @AppId8 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Mortgage',
        @RequestedAmount = 600000.00,
        @TermMonths = 360,
        @Purpose = 'Test',
        @ApplicationId = @AppId8 OUTPUT;
    PRINT 'FAILED: Should have raised an error for exceeding maximum';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected excessive amount - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 9: Loan amount exceeds Business loan maximum (should fail)
PRINT 'Test 9: Loan amount exceeds Business loan maximum (should fail)';
BEGIN TRY
    DECLARE @AppId9 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Business',
        @RequestedAmount = 300000.00,
        @TermMonths = 120,
        @Purpose = 'Test',
        @ApplicationId = @AppId9 OUTPUT;
    PRINT 'FAILED: Should have raised an error for exceeding maximum';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected excessive amount - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 10: Term too short (should fail)
PRINT 'Test 10: Term too short (should fail)';
BEGIN TRY
    DECLARE @AppId10 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Personal',
        @RequestedAmount = 10000.00,
        @TermMonths = 6,
        @Purpose = 'Test',
        @ApplicationId = @AppId10 OUTPUT;
    PRINT 'FAILED: Should have raised an error for term too short';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected short term - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 11: Term too long (should fail)
PRINT 'Test 11: Term too long (should fail)';
BEGIN TRY
    DECLARE @AppId11 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Personal',
        @RequestedAmount = 10000.00,
        @TermMonths = 400,
        @Purpose = 'Test',
        @ApplicationId = @AppId11 OUTPUT;
    PRINT 'FAILED: Should have raised an error for term too long';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected long term - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 12: Minimum valid term (12 months)
PRINT 'Test 12: Minimum valid term (12 months)';
DECLARE @AppId12 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 1,
    @LoanType = 'Personal',
    @RequestedAmount = 5000.00,
    @TermMonths = 12,
    @Purpose = 'Short term loan',
    @ApplicationId = @AppId12 OUTPUT;

IF @AppId12 IS NOT NULL
    PRINT 'SUCCESS: Application created with minimum term';
ELSE
    PRINT 'FAILED: Application with minimum term was not created';
PRINT '';

-- Test 13: Maximum valid term (360 months)
PRINT 'Test 13: Maximum valid term (360 months)';
DECLARE @AppId13 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = 2,
    @LoanType = 'Mortgage',
    @RequestedAmount = 250000.00,
    @TermMonths = 360,
    @Purpose = 'Long term mortgage',
    @ApplicationId = @AppId13 OUTPUT;

IF @AppId13 IS NOT NULL
    PRINT 'SUCCESS: Application created with maximum term';
ELSE
    PRINT 'FAILED: Application with maximum term was not created';
PRINT '';

-- Test 14: Invalid loan type (should fail)
PRINT 'Test 14: Invalid loan type (should fail)';
BEGIN TRY
    DECLARE @AppId14 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'InvalidType',
        @RequestedAmount = 10000.00,
        @TermMonths = 36,
        @Purpose = 'Test',
        @ApplicationId = @AppId14 OUTPUT;
    PRINT 'FAILED: Should have raised an error for invalid loan type';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected invalid loan type - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 15: Zero amount (should fail)
PRINT 'Test 15: Zero amount (should fail)';
BEGIN TRY
    DECLARE @AppId15 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Personal',
        @RequestedAmount = 0.00,
        @TermMonths = 36,
        @Purpose = 'Test',
        @ApplicationId = @AppId15 OUTPUT;
    PRINT 'FAILED: Should have raised an error for zero amount';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected zero amount - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 16: Negative amount (should fail)
PRINT 'Test 16: Negative amount (should fail)';
BEGIN TRY
    DECLARE @AppId16 INT;
    EXEC [dbo].[sp_SubmitLoanApplication]
        @CustomerId = 1,
        @LoanType = 'Personal',
        @RequestedAmount = -1000.00,
        @TermMonths = 36,
        @Purpose = 'Test',
        @ApplicationId = @AppId16 OUTPUT;
    PRINT 'FAILED: Should have raised an error for negative amount';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Correctly rejected negative amount - ' + ERROR_MESSAGE();
END CATCH
PRINT '';

-- Test 17: Verify application number uniqueness
PRINT 'Test 17: Verify application number uniqueness';
SELECT 
    [ApplicationNumber],
    COUNT(*) AS [Count]
FROM [dbo].[LoanApplications]
GROUP BY [ApplicationNumber]
HAVING COUNT(*) > 1;

IF @@ROWCOUNT = 0
    PRINT 'SUCCESS: All application numbers are unique';
ELSE
    PRINT 'FAILED: Duplicate application numbers found';
PRINT '';

-- Test 18: Verify all applications have status 'Pending'
PRINT 'Test 18: Verify all applications have status ''Pending''';
SELECT 
    [ApplicationId],
    [ApplicationNumber],
    [Status]
FROM [dbo].[LoanApplications]
WHERE [Status] != 'Pending';

IF @@ROWCOUNT = 0
    PRINT 'SUCCESS: All new applications have status ''Pending''';
ELSE
    PRINT 'FAILED: Some applications do not have status ''Pending''';
PRINT '';

PRINT '========================================';
PRINT 'Test Summary';
PRINT '========================================';
SELECT 
    COUNT(*) AS [TotalApplications],
    COUNT(DISTINCT [ApplicationNumber]) AS [UniqueApplicationNumbers],
    COUNT(CASE WHEN [Status] = 'Pending' THEN 1 END) AS [PendingApplications]
FROM [dbo].[LoanApplications];

PRINT '';
PRINT 'Testing complete!';
GO
