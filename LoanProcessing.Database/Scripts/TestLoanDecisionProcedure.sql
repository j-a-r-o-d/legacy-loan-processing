-- ============================================================================
-- Test Script: sp_ProcessLoanDecision
-- Description: Tests the loan decision processing stored procedure
-- ============================================================================

USE [LoanProcessing]
GO

PRINT '========================================';
PRINT 'Testing sp_ProcessLoanDecision';
PRINT '========================================';
PRINT '';

-- Clean up any existing test data
DELETE FROM [dbo].[LoanDecisions] WHERE [ApplicationId] IN (
    SELECT [ApplicationId] FROM [dbo].[LoanApplications] 
    WHERE [ApplicationNumber] LIKE 'TEST-DECISION%'
);
DELETE FROM [dbo].[LoanApplications] WHERE [ApplicationNumber] LIKE 'TEST-DECISION%';
DELETE FROM [dbo].[Customers] WHERE [SSN] LIKE '999-88-7%';
GO

-- ============================================================================
-- Test 1: Process approval decision with default approved amount
-- ============================================================================
PRINT 'Test 1: Process approval decision with default approved amount';
PRINT '----------------------------------------------------------------';

-- Create test customer
DECLARE @TestCustomerId1 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'John',
    @LastName = 'Approver',
    @SSN = '999-88-7001',
    @DateOfBirth = '1985-05-15',
    @AnnualIncome = 75000.00,
    @CreditScore = 720,
    @Email = 'john.approver@test.com',
    @Phone = '555-0101',
    @Address = '123 Approval St',
    @CustomerId = @TestCustomerId1 OUTPUT;

-- Create test application
DECLARE @TestAppId1 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId1,
    @LoanType = 'Personal',
    @RequestedAmount = 15000.00,
    @TermMonths = 36,
    @Purpose = 'Test approval decision',
    @ApplicationId = @TestAppId1 OUTPUT;

-- Evaluate credit to set interest rate
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId1;

-- Process approval decision (no approved amount specified, should default to requested)
EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = @TestAppId1,
    @Decision = 'Approved',
    @DecisionBy = 'Test Underwriter',
    @Comments = 'Test approval with default amount';

-- Verify results
SELECT 
    'Test 1 - Application Status' AS TestCase,
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
    [Decision],
    [DecisionBy],
    [ApprovedAmount],
    [Comments],
    CASE 
        WHEN [Decision] = 'Approved' AND [ApprovedAmount] = 15000.00 
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS Result
FROM [dbo].[LoanDecisions]
WHERE [ApplicationId] = @TestAppId1;

PRINT '';

-- ============================================================================
-- Test 2: Process approval decision with specific approved amount
-- ============================================================================
PRINT 'Test 2: Process approval decision with specific approved amount';
PRINT '----------------------------------------------------------------';

-- Create test customer
DECLARE @TestCustomerId2 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Jane',
    @LastName = 'Partial',
    @SSN = '999-88-7002',
    @DateOfBirth = '1990-08-20',
    @AnnualIncome = 60000.00,
    @CreditScore = 680,
    @Email = 'jane.partial@test.com',
    @Phone = '555-0102',
    @Address = '456 Partial Ave',
    @CustomerId = @TestCustomerId2 OUTPUT;

-- Create test application
DECLARE @TestAppId2 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId2,
    @LoanType = 'Auto',
    @RequestedAmount = 25000.00,
    @TermMonths = 60,
    @Purpose = 'Test partial approval',
    @ApplicationId = @TestAppId2 OUTPUT;

-- Evaluate credit
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId2;

-- Process approval with lower amount
EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = @TestAppId2,
    @Decision = 'Approved',
    @DecisionBy = 'Test Underwriter',
    @Comments = 'Approved for lower amount due to DTI',
    @ApprovedAmount = 20000.00;

-- Verify results
SELECT 
    'Test 2 - Partial Approval' AS TestCase,
    [Status],
    [ApprovedAmount],
    [RequestedAmount],
    CASE 
        WHEN [Status] = 'Approved' AND [ApprovedAmount] = 20000.00 AND [RequestedAmount] = 25000.00
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS Result
FROM [dbo].[LoanApplications]
WHERE [ApplicationId] = @TestAppId2;

PRINT '';

-- ============================================================================
-- Test 3: Process rejection decision
-- ============================================================================
PRINT 'Test 3: Process rejection decision';
PRINT '----------------------------------------------------------------';

-- Create test customer
DECLARE @TestCustomerId3 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Bob',
    @LastName = 'Rejected',
    @SSN = '999-88-7003',
    @DateOfBirth = '1988-03-10',
    @AnnualIncome = 35000.00,
    @CreditScore = 580,
    @Email = 'bob.rejected@test.com',
    @Phone = '555-0103',
    @Address = '789 Rejection Rd',
    @CustomerId = @TestCustomerId3 OUTPUT;

-- Create test application
DECLARE @TestAppId3 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId3,
    @LoanType = 'Personal',
    @RequestedAmount = 30000.00,
    @TermMonths = 48,
    @Purpose = 'Test rejection',
    @ApplicationId = @TestAppId3 OUTPUT;

-- Evaluate credit
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId3;

-- Process rejection
EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = @TestAppId3,
    @Decision = 'Rejected',
    @DecisionBy = 'Test Underwriter',
    @Comments = 'Insufficient credit score and high DTI ratio';

-- Verify results
SELECT 
    'Test 3 - Rejection' AS TestCase,
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
    [Decision],
    [Comments],
    CASE 
        WHEN [Decision] = 'Rejected' AND [Comments] IS NOT NULL
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS Result
FROM [dbo].[LoanDecisions]
WHERE [ApplicationId] = @TestAppId3;

PRINT '';

-- ============================================================================
-- Test 4: Validation - Approved amount exceeds requested amount (should fail)
-- ============================================================================
PRINT 'Test 4: Validation - Approved amount exceeds requested amount';
PRINT '----------------------------------------------------------------';

-- Create test customer
DECLARE @TestCustomerId4 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Alice',
    @LastName = 'Overapproved',
    @SSN = '999-88-7004',
    @DateOfBirth = '1992-11-25',
    @AnnualIncome = 80000.00,
    @CreditScore = 750,
    @Email = 'alice.over@test.com',
    @Phone = '555-0104',
    @Address = '321 Over St',
    @CustomerId = @TestCustomerId4 OUTPUT;

-- Create test application
DECLARE @TestAppId4 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId4,
    @LoanType = 'Personal',
    @RequestedAmount = 10000.00,
    @TermMonths = 24,
    @Purpose = 'Test over-approval validation',
    @ApplicationId = @TestAppId4 OUTPUT;

-- Evaluate credit
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId4;

-- Try to approve for more than requested (should fail)
BEGIN TRY
    EXEC [dbo].[sp_ProcessLoanDecision]
        @ApplicationId = @TestAppId4,
        @Decision = 'Approved',
        @DecisionBy = 'Test Underwriter',
        @Comments = 'Test over-approval',
        @ApprovedAmount = 15000.00;
    
    PRINT 'Test 4 Result: FAIL - Should have raised error for approved amount exceeding requested';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE '%cannot exceed requested amount%'
        PRINT 'Test 4 Result: PASS - Correctly rejected over-approval';
    ELSE
        PRINT 'Test 4 Result: FAIL - Wrong error: ' + ERROR_MESSAGE();
END CATCH

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
-- Test 6: Verify evaluation data is preserved in decision record
-- ============================================================================
PRINT 'Test 6: Verify evaluation data is preserved in decision record';
PRINT '----------------------------------------------------------------';

-- Create test customer
DECLARE @TestCustomerId6 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Charlie',
    @LastName = 'Evaluator',
    @SSN = '999-88-7006',
    @DateOfBirth = '1987-07-15',
    @AnnualIncome = 90000.00,
    @CreditScore = 780,
    @Email = 'charlie.eval@test.com',
    @Phone = '555-0106',
    @Address = '654 Eval Blvd',
    @CustomerId = @TestCustomerId6 OUTPUT;

-- Create test application
DECLARE @TestAppId6 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId6,
    @LoanType = 'Auto',
    @RequestedAmount = 30000.00,
    @TermMonths = 48,
    @Purpose = 'Test evaluation data preservation',
    @ApplicationId = @TestAppId6 OUTPUT;

-- Evaluate credit (this calculates RiskScore and DTI but doesn't store in LoanDecisions)
DECLARE @EvalResults TABLE (
    ApplicationId INT,
    RiskScore INT,
    DebtToIncomeRatio DECIMAL(5,2),
    InterestRate DECIMAL(5,2),
    CreditScore INT,
    ExistingDebt DECIMAL(18,2),
    RequestedAmount DECIMAL(18,2),
    AnnualIncome DECIMAL(18,2),
    Recommendation NVARCHAR(100)
);

INSERT INTO @EvalResults
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId6;

-- Process approval
EXEC [dbo].[sp_ProcessLoanDecision]
    @ApplicationId = @TestAppId6,
    @Decision = 'Approved',
    @DecisionBy = 'Test Underwriter',
    @Comments = 'Test evaluation data preservation';

-- Verify that InterestRate is preserved in decision record
SELECT 
    'Test 6 - Evaluation Data' AS TestCase,
    ld.[InterestRate],
    la.[InterestRate] AS AppInterestRate,
    CASE 
        WHEN ld.[InterestRate] = la.[InterestRate] AND ld.[InterestRate] IS NOT NULL
        THEN 'PASS' 
        ELSE 'FAIL' 
    END AS Result
FROM [dbo].[LoanDecisions] ld
INNER JOIN [dbo].[LoanApplications] la ON ld.[ApplicationId] = la.[ApplicationId]
WHERE ld.[ApplicationId] = @TestAppId6;

PRINT '';

-- ============================================================================
-- Summary
-- ============================================================================
PRINT '========================================';
PRINT 'Test Summary';
PRINT '========================================';
PRINT 'All tests completed. Review results above.';
PRINT '';

-- Clean up test data
PRINT 'Cleaning up test data...';
DELETE FROM [dbo].[LoanDecisions] WHERE [ApplicationId] IN (
    SELECT [ApplicationId] FROM [dbo].[LoanApplications] 
    WHERE [ApplicationNumber] LIKE 'TEST-DECISION%'
);
DELETE FROM [dbo].[LoanApplications] WHERE [ApplicationNumber] LIKE 'TEST-DECISION%';
DELETE FROM [dbo].[Customers] WHERE [SSN] LIKE '999-88-7%';
PRINT 'Test data cleaned up.';
PRINT '';

