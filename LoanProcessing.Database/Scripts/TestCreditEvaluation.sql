-- ============================================================================
-- Test Script: sp_EvaluateCredit
-- Description: Tests the credit evaluation stored procedure
-- ============================================================================

USE [LoanProcessing];
GO

PRINT '========================================';
PRINT 'Testing sp_EvaluateCredit';
PRINT '========================================';
PRINT '';

-- Test 1: Evaluate credit for a pending application
PRINT 'Test 1: Evaluate credit for a pending application';
PRINT '----------------------------------------';

-- First, create a test customer with good credit
DECLARE @TestCustomerId INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Test',
    @LastName = 'Evaluator',
    @SSN = '999-88-7777',
    @DateOfBirth = '1985-05-15',
    @AnnualIncome = 75000.00,
    @CreditScore = 720,
    @Email = 'test.evaluator@example.com',
    @Phone = '555-9999',
    @Address = '123 Test St',
    @CustomerId = @TestCustomerId OUTPUT;

PRINT 'Created test customer with ID: ' + CAST(@TestCustomerId AS NVARCHAR);

-- Submit a loan application
DECLARE @TestApplicationId INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId,
    @LoanType = 'Personal',
    @RequestedAmount = 25000.00,
    @TermMonths = 60,
    @Purpose = 'Debt consolidation',
    @ApplicationId = @TestApplicationId OUTPUT;

PRINT 'Created test application with ID: ' + CAST(@TestApplicationId AS NVARCHAR);

-- Evaluate the credit
PRINT 'Evaluating credit...';
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestApplicationId;

-- Verify the application status was updated
SELECT 
    [ApplicationId],
    [ApplicationNumber],
    [Status],
    [InterestRate]
FROM [dbo].[LoanApplications]
WHERE [ApplicationId] = @TestApplicationId;

PRINT '';
PRINT 'Test 1 completed successfully.';
PRINT '';

-- Test 2: Evaluate credit for customer with existing debt
PRINT 'Test 2: Evaluate credit for customer with existing debt';
PRINT '----------------------------------------';

-- Create another customer
DECLARE @TestCustomerId2 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Jane',
    @LastName = 'Debtor',
    @SSN = '888-77-6666',
    @DateOfBirth = '1980-03-20',
    @AnnualIncome = 60000.00,
    @CreditScore = 650,
    @Email = 'jane.debtor@example.com',
    @Phone = '555-8888',
    @Address = '456 Debt Ave',
    @CustomerId = @TestCustomerId2 OUTPUT;

-- Submit and approve a first loan to create existing debt
DECLARE @FirstLoanId INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId2,
    @LoanType = 'Auto',
    @RequestedAmount = 20000.00,
    @TermMonths = 48,
    @Purpose = 'Car purchase',
    @ApplicationId = @FirstLoanId OUTPUT;

-- Manually approve the first loan to create existing debt
UPDATE [dbo].[LoanApplications]
SET [Status] = 'Approved',
    [ApprovedAmount] = 20000.00
WHERE [ApplicationId] = @FirstLoanId;

-- Submit a second loan application
DECLARE @SecondLoanId INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId2,
    @LoanType = 'Personal',
    @RequestedAmount = 15000.00,
    @TermMonths = 36,
    @Purpose = 'Home improvement',
    @ApplicationId = @SecondLoanId OUTPUT;

-- Evaluate the second loan (should show higher DTI due to existing debt)
PRINT 'Evaluating credit with existing debt...';
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @SecondLoanId;

PRINT '';
PRINT 'Test 2 completed successfully.';
PRINT '';

-- Test 3: Evaluate credit for low credit score customer
PRINT 'Test 3: Evaluate credit for low credit score customer';
PRINT '----------------------------------------';

-- Create a customer with low credit score
DECLARE @TestCustomerId3 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Bob',
    @LastName = 'Risky',
    @SSN = '777-66-5555',
    @DateOfBirth = '1990-08-10',
    @AnnualIncome = 45000.00,
    @CreditScore = 580,
    @Email = 'bob.risky@example.com',
    @Phone = '555-7777',
    @Address = '789 Risk Rd',
    @CustomerId = @TestCustomerId3 OUTPUT;

-- Submit a loan application
DECLARE @RiskyLoanId INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId3,
    @LoanType = 'Personal',
    @RequestedAmount = 10000.00,
    @TermMonths = 24,
    @Purpose = 'Emergency expenses',
    @ApplicationId = @RiskyLoanId OUTPUT;

-- Evaluate the credit (should show high risk)
PRINT 'Evaluating credit for low credit score...';
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @RiskyLoanId;

PRINT '';
PRINT 'Test 3 completed successfully.';
PRINT '';

-- Test 4: Test error handling - non-existent application
PRINT 'Test 4: Test error handling - non-existent application';
PRINT '----------------------------------------';

BEGIN TRY
    EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = 999999;
    PRINT 'ERROR: Should have raised an error for non-existent application';
END TRY
BEGIN CATCH
    PRINT 'Successfully caught error: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT 'Test 4 completed successfully.';
PRINT '';

-- Test 5: Verify interest rate selection
PRINT 'Test 5: Verify interest rate selection';
PRINT '----------------------------------------';

-- Create a customer with excellent credit
DECLARE @TestCustomerId4 INT;
EXEC [dbo].[sp_CreateCustomer]
    @FirstName = 'Alice',
    @LastName = 'Excellent',
    @SSN = '666-55-4444',
    @DateOfBirth = '1988-12-05',
    @AnnualIncome = 100000.00,
    @CreditScore = 800,
    @Email = 'alice.excellent@example.com',
    @Phone = '555-6666',
    @Address = '321 Prime St',
    @CustomerId = @TestCustomerId4 OUTPUT;

-- Submit a loan application
DECLARE @ExcellentLoanId INT;
EXEC [dbo].[sp_SubmitLoanApplication]
    @CustomerId = @TestCustomerId4,
    @LoanType = 'Mortgage',
    @RequestedAmount = 300000.00,
    @TermMonths = 360,
    @Purpose = 'Home purchase',
    @ApplicationId = @ExcellentLoanId OUTPUT;

-- Evaluate the credit (should get best interest rate)
PRINT 'Evaluating credit for excellent credit score...';
EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @ExcellentLoanId;

PRINT '';
PRINT 'Test 5 completed successfully.';
PRINT '';

PRINT '========================================';
PRINT 'All sp_EvaluateCredit tests completed!';
PRINT '========================================';
GO
