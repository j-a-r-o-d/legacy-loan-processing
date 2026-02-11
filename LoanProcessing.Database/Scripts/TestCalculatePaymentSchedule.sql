-- =============================================
-- Test Script: sp_CalculatePaymentSchedule
-- Description: Tests the payment schedule calculation stored procedure
-- =============================================

-- Clean up test data
DELETE FROM PaymentSchedules WHERE ApplicationId IN (SELECT ApplicationId FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-CALC%');
DELETE FROM LoanDecisions WHERE ApplicationId IN (SELECT ApplicationId FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-CALC%');
DELETE FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-CALC%';
DELETE FROM Customers WHERE SSN LIKE '999-99-9%';

PRINT '=== Test 1: Basic Payment Schedule Calculation ===';
PRINT 'Creating test customer and loan application...';

-- Create test customer
DECLARE @CustomerId INT;
EXEC sp_CreateCustomer 
    @FirstName = 'John',
    @LastName = 'Doe',
    @SSN = '999-99-9001',
    @DateOfBirth = '1985-01-15',
    @AnnualIncome = 75000,
    @CreditScore = 720,
    @Email = 'john.doe@test.com',
    @Phone = '555-0101',
    @Address = '123 Test St',
    @CustomerId = @CustomerId OUTPUT;

PRINT 'Customer created with ID: ' + CAST(@CustomerId AS NVARCHAR);

-- Create test loan application
INSERT INTO LoanApplications (ApplicationNumber, CustomerId, LoanType, RequestedAmount, TermMonths, Purpose, Status, ApplicationDate, ApprovedAmount, InterestRate)
VALUES ('TEST-CALC-001', @CustomerId, 'Personal', 10000.00, 12, 'Test loan for payment schedule', 'Approved', GETDATE(), 10000.00, 6.00);

DECLARE @ApplicationId INT = SCOPE_IDENTITY();
PRINT 'Loan application created with ID: ' + CAST(@ApplicationId AS NVARCHAR);

-- Calculate payment schedule
PRINT 'Calculating payment schedule...';
EXEC sp_CalculatePaymentSchedule @ApplicationId;

-- Verify results
PRINT '';
PRINT '=== Payment Schedule Results ===';
SELECT 
    PaymentNumber,
    DueDate,
    PaymentAmount,
    PrincipalAmount,
    InterestAmount,
    RemainingBalance
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId
ORDER BY PaymentNumber;

-- Verify totals
PRINT '';
PRINT '=== Verification ===';
DECLARE @TotalPayments DECIMAL(18,2), @TotalPrincipal DECIMAL(18,2), @TotalInterest DECIMAL(18,2);
DECLARE @FinalBalance DECIMAL(18,2), @PaymentCount INT;

SELECT 
    @TotalPayments = SUM(PaymentAmount),
    @TotalPrincipal = SUM(PrincipalAmount),
    @TotalInterest = SUM(InterestAmount),
    @FinalBalance = MIN(CASE WHEN PaymentNumber = 12 THEN RemainingBalance END),
    @PaymentCount = COUNT(*)
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId;

PRINT 'Number of payments: ' + CAST(@PaymentCount AS NVARCHAR);
PRINT 'Total payments: $' + CAST(@TotalPayments AS NVARCHAR);
PRINT 'Total principal: $' + CAST(@TotalPrincipal AS NVARCHAR);
PRINT 'Total interest: $' + CAST(@TotalInterest AS NVARCHAR);
PRINT 'Final remaining balance: $' + CAST(@FinalBalance AS NVARCHAR);

IF @PaymentCount = 12
    PRINT 'PASS: Correct number of payments generated';
ELSE
    PRINT 'FAIL: Expected 12 payments, got ' + CAST(@PaymentCount AS NVARCHAR);

IF ABS(@TotalPrincipal - 10000.00) < 0.01
    PRINT 'PASS: Total principal equals loan amount';
ELSE
    PRINT 'FAIL: Total principal does not equal loan amount';

IF ABS(@FinalBalance) < 0.01
    PRINT 'PASS: Final balance is zero';
ELSE
    PRINT 'FAIL: Final balance is not zero: $' + CAST(@FinalBalance AS NVARCHAR);

PRINT '';
PRINT '=== Test 2: Longer Term Loan (36 months) ===';

-- Create another test loan
INSERT INTO LoanApplications (ApplicationNumber, CustomerId, LoanType, RequestedAmount, TermMonths, Purpose, Status, ApplicationDate, ApprovedAmount, InterestRate)
VALUES ('TEST-CALC-002', @CustomerId, 'Auto', 25000.00, 36, 'Test auto loan', 'Approved', GETDATE(), 25000.00, 4.50);

DECLARE @ApplicationId2 INT = SCOPE_IDENTITY();
PRINT 'Loan application created with ID: ' + CAST(@ApplicationId2 AS NVARCHAR);

-- Calculate payment schedule
EXEC sp_CalculatePaymentSchedule @ApplicationId2;

-- Verify results
SELECT 
    @TotalPayments = SUM(PaymentAmount),
    @TotalPrincipal = SUM(PrincipalAmount),
    @TotalInterest = SUM(InterestAmount),
    @FinalBalance = MIN(CASE WHEN PaymentNumber = 36 THEN RemainingBalance END),
    @PaymentCount = COUNT(*)
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId2;

PRINT 'Number of payments: ' + CAST(@PaymentCount AS NVARCHAR);
PRINT 'Total payments: $' + CAST(@TotalPayments AS NVARCHAR);
PRINT 'Total principal: $' + CAST(@TotalPrincipal AS NVARCHAR);
PRINT 'Total interest: $' + CAST(@TotalInterest AS NVARCHAR);
PRINT 'Final remaining balance: $' + CAST(@FinalBalance AS NVARCHAR);

IF @PaymentCount = 36
    PRINT 'PASS: Correct number of payments generated';
ELSE
    PRINT 'FAIL: Expected 36 payments, got ' + CAST(@PaymentCount AS NVARCHAR);

IF ABS(@TotalPrincipal - 25000.00) < 0.01
    PRINT 'PASS: Total principal equals loan amount';
ELSE
    PRINT 'FAIL: Total principal does not equal loan amount';

IF ABS(@FinalBalance) < 0.01
    PRINT 'PASS: Final balance is zero';
ELSE
    PRINT 'FAIL: Final balance is not zero: $' + CAST(@FinalBalance AS NVARCHAR);

PRINT '';
PRINT '=== Test 3: Recalculation (Delete and Regenerate) ===';

-- Recalculate the first loan's schedule
PRINT 'Recalculating payment schedule for first loan...';
EXEC sp_CalculatePaymentSchedule @ApplicationId;

-- Verify old schedule was deleted and new one created
SELECT @PaymentCount = COUNT(*)
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId;

IF @PaymentCount = 12
    PRINT 'PASS: Schedule recalculated correctly (12 payments)';
ELSE
    PRINT 'FAIL: Expected 12 payments after recalculation, got ' + CAST(@PaymentCount AS NVARCHAR);

PRINT '';
PRINT '=== Test 4: High Interest Rate Loan ===';

-- Create high interest rate loan
INSERT INTO LoanApplications (ApplicationNumber, CustomerId, LoanType, RequestedAmount, TermMonths, Purpose, Status, ApplicationDate, ApprovedAmount, InterestRate)
VALUES ('TEST-CALC-003', @CustomerId, 'Personal', 5000.00, 24, 'Test high rate loan', 'Approved', GETDATE(), 5000.00, 18.99);

DECLARE @ApplicationId3 INT = SCOPE_IDENTITY();
PRINT 'High interest loan created with ID: ' + CAST(@ApplicationId3 AS NVARCHAR);

-- Calculate payment schedule
EXEC sp_CalculatePaymentSchedule @ApplicationId3;

-- Verify results
SELECT 
    @TotalPayments = SUM(PaymentAmount),
    @TotalPrincipal = SUM(PrincipalAmount),
    @TotalInterest = SUM(InterestAmount),
    @FinalBalance = MIN(CASE WHEN PaymentNumber = 24 THEN RemainingBalance END),
    @PaymentCount = COUNT(*)
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId3;

PRINT 'Number of payments: ' + CAST(@PaymentCount AS NVARCHAR);
PRINT 'Total payments: $' + CAST(@TotalPayments AS NVARCHAR);
PRINT 'Total principal: $' + CAST(@TotalPrincipal AS NVARCHAR);
PRINT 'Total interest: $' + CAST(@TotalInterest AS NVARCHAR);
PRINT 'Final remaining balance: $' + CAST(@FinalBalance AS NVARCHAR);

IF @PaymentCount = 24
    PRINT 'PASS: Correct number of payments generated';
ELSE
    PRINT 'FAIL: Expected 24 payments, got ' + CAST(@PaymentCount AS NVARCHAR);

IF ABS(@TotalPrincipal - 5000.00) < 0.01
    PRINT 'PASS: Total principal equals loan amount';
ELSE
    PRINT 'FAIL: Total principal does not equal loan amount';

IF ABS(@FinalBalance) < 0.01
    PRINT 'PASS: Final balance is zero';
ELSE
    PRINT 'FAIL: Final balance is not zero: $' + CAST(@FinalBalance AS NVARCHAR);

PRINT '';
PRINT '=== All Tests Complete ===';

-- Clean up test data
PRINT 'Cleaning up test data...';
DELETE FROM PaymentSchedules WHERE ApplicationId IN (SELECT ApplicationId FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-CALC%');
DELETE FROM LoanDecisions WHERE ApplicationId IN (SELECT ApplicationId FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-CALC%');
DELETE FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-CALC%';
DELETE FROM Customers WHERE SSN LIKE '999-99-9%';

PRINT 'Test data cleaned up.';
