-- ============================================================================
-- Simple Test Script: sp_EvaluateCredit
-- Description: Simple test of the credit evaluation stored procedure
-- ============================================================================

USE [LoanProcessing];
GO

PRINT '========================================';
PRINT 'Testing sp_EvaluateCredit';
PRINT '========================================';
PRINT '';

-- Reset the sequence to avoid conflicts
ALTER SEQUENCE [dbo].[ApplicationNumberSeq] RESTART WITH 10000;
GO

-- Test 1: Evaluate credit for a pending application with good credit
PRINT 'Test 1: Good credit customer';
PRINT '----------------------------------------';

DECLARE @CustomerId1 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Alice',
    @LastName = 'GoodCredit',
    @SSN = '111-22-3333',
    @DateOfBirth = '1985-05-15',
    @AnnualIncome = 75000.00,
    @CreditScore = 720,
    @Email = 'alice.good@example.com',
    @Phone = '555-1111',
    @Address = '123 Good St',
    @CustomerId = @CustomerId1 OUTPUT;

DECLARE @ApplicationId1 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @CustomerId1,
    @LoanType = 'Personal',
    @RequestedAmount = 25000.00,
    @TermMonths = 60,
    @Purpose = 'Debt consolidation',
    @ApplicationId = @ApplicationId1 OUTPUT;

PRINT 'Evaluating credit for Application ID: ' + CAST(@ApplicationId1 AS NVARCHAR);
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @ApplicationId1;

PRINT '';
PRINT 'Checking application status after evaluation:';
SELECT 
    [ApplicationId],
    [ApplicationNumber],
    [Status],
    [InterestRate],
    [RequestedAmount]
FROM [dbo].[LoanApplications]
WHERE [ApplicationId] = @ApplicationId1;

PRINT '';
PRINT '========================================';
PRINT '';

-- Test 2: Evaluate credit for customer with existing debt
PRINT 'Test 2: Customer with existing debt';
PRINT '----------------------------------------';

DECLARE @CustomerId2 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Bob',
    @LastName = 'HasDebt',
    @SSN = '222-33-4444',
    @DateOfBirth = '1980-03-20',
    @AnnualIncome = 60000.00,
    @CreditScore = 650,
    @Email = 'bob.debt@example.com',
    @Phone = '555-2222',
    @Address = '456 Debt Ave',
    @CustomerId = @CustomerId2 OUTPUT;

-- Create first approved loan
DECLARE @FirstLoanId INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @CustomerId2,
    @LoanType = 'Auto',
    @RequestedAmount = 20000.00,
    @TermMonths = 48,
    @Purpose = 'Car purchase',
    @ApplicationId = @FirstLoanId OUTPUT;

-- Manually approve the first loan
UPDATE [dbo].[LoanApplications]
SET [Status] = 'Approved',
    [ApprovedAmount] = 20000.00
WHERE [ApplicationId] = @FirstLoanId;

-- Submit second loan
DECLARE @SecondLoanId INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @CustomerId2,
    @LoanType = 'Personal',
    @RequestedAmount = 15000.00,
    @TermMonths = 36,
    @Purpose = 'Home improvement',
    @ApplicationId = @SecondLoanId OUTPUT;

PRINT 'Evaluating credit for Application ID: ' + CAST(@SecondLoanId AS NVARCHAR);
PRINT 'Customer has existing approved loan of $20,000';
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @SecondLoanId;

PRINT '';
PRINT '========================================';
PRINT '';

-- Test 3: Low credit score customer
PRINT 'Test 3: Low credit score customer';
PRINT '----------------------------------------';

DECLARE @CustomerId3 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Charlie',
    @LastName = 'LowCredit',
    @SSN = '333-44-5555',
    @DateOfBirth = '1990-08-10',
    @AnnualIncome = 45000.00,
    @CreditScore = 580,
    @Email = 'charlie.low@example.com',
    @Phone = '555-3333',
    @Address = '789 Risk Rd',
    @CustomerId = @CustomerId3 OUTPUT;

DECLARE @ApplicationId3 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @CustomerId3,
    @LoanType = 'Personal',
    @RequestedAmount = 10000.00,
    @TermMonths = 24,
    @Purpose = 'Emergency expenses',
    @ApplicationId = @ApplicationId3 OUTPUT;

PRINT 'Evaluating credit for Application ID: ' + CAST(@ApplicationId3 AS NVARCHAR);
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @ApplicationId3;

PRINT '';
PRINT '========================================';
PRINT '';

-- Test 4: Excellent credit customer
PRINT 'Test 4: Excellent credit customer';
PRINT '----------------------------------------';

DECLARE @CustomerId4 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Diana',
    @LastName = 'Excellent',
    @SSN = '444-55-6666',
    @DateOfBirth = '1988-12-05',
    @AnnualIncome = 100000.00,
    @CreditScore = 800,
    @Email = 'diana.excellent@example.com',
    @Phone = '555-4444',
    @Address = '321 Prime St',
    @CustomerId = @CustomerId4 OUTPUT;

DECLARE @ApplicationId4 INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @CustomerId4,
    @LoanType = 'Mortgage',
    @RequestedAmount = 300000.00,
    @TermMonths = 360,
    @Purpose = 'Home purchase',
    @ApplicationId = @ApplicationId4 OUTPUT;

PRINT 'Evaluating credit for Application ID: ' + CAST(@ApplicationId4 AS NVARCHAR);
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @ApplicationId4;

PRINT '';
PRINT '========================================';
PRINT 'All tests completed successfully!';
PRINT '========================================';
GO
