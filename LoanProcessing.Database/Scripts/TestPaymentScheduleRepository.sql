-- =============================================
-- Test Script: PaymentScheduleRepository
-- Description: Tests the PaymentScheduleRepository implementation
-- Task: 10.4
-- =============================================

USE LoanProcessingDB;
GO

PRINT '========================================';
PRINT 'Testing PaymentScheduleRepository';
PRINT '========================================';
PRINT '';

-- Clean up test data
DELETE FROM PaymentSchedules WHERE ApplicationId IN (
    SELECT ApplicationId FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-PS-%'
);
DELETE FROM LoanDecisions WHERE ApplicationId IN (
    SELECT ApplicationId FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-PS-%'
);
DELETE FROM LoanApplications WHERE ApplicationNumber LIKE 'TEST-PS-%';
DELETE FROM Customers WHERE SSN IN ('999-88-7777', '999-88-7778');

-- Create test customers
DECLARE @CustomerId1 INT, @CustomerId2 INT;

INSERT INTO Customers (FirstName, LastName, SSN, DateOfBirth, AnnualIncome, CreditScore, Email, Phone, Address, CreatedDate)
VALUES ('Test', 'Customer1', '999-88-7777', '1985-01-01', 75000, 720, 'test1@example.com', '555-0001', '123 Test St', GETDATE());
SET @CustomerId1 = SCOPE_IDENTITY();

INSERT INTO Customers (FirstName, LastName, SSN, DateOfBirth, AnnualIncome, CreditScore, Email, Phone, Address, CreatedDate)
VALUES ('Test', 'Customer2', '999-88-7778', '1990-01-01', 60000, 680, 'test2@example.com', '555-0002', '456 Test Ave', GETDATE());
SET @CustomerId2 = SCOPE_IDENTITY();

PRINT 'Test customers created.';
PRINT '';

-- =============================================
-- Test 1: GetScheduleByApplication - Empty Schedule
-- =============================================
PRINT 'Test 1: GetScheduleByApplication - Empty Schedule';
PRINT '-------------------------------------------';

DECLARE @ApplicationId1 INT;

-- Create a loan application without a payment schedule
INSERT INTO LoanApplications (ApplicationNumber, CustomerId, LoanType, RequestedAmount, TermMonths, Purpose, Status, ApplicationDate, ApprovedAmount, InterestRate)
VALUES ('TEST-PS-001', @CustomerId1, 'Personal', 10000, 24, 'Test loan', 'Approved', GETDATE(), 10000, 8.5);
SET @ApplicationId1 = SCOPE_IDENTITY();

-- Query for payment schedule (should be empty)
SELECT COUNT(*) AS ScheduleCount
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId1;

PRINT 'Expected: 0 schedules';
PRINT '';

-- =============================================
-- Test 2: CalculateSchedule - Generate Payment Schedule
-- =============================================
PRINT 'Test 2: CalculateSchedule - Generate Payment Schedule';
PRINT '-------------------------------------------';

-- Call sp_CalculatePaymentSchedule
EXEC sp_CalculatePaymentSchedule @ApplicationId1;

-- Verify schedule was created
SELECT COUNT(*) AS ScheduleCount
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId1;

PRINT 'Expected: 24 schedules (24-month term)';
PRINT '';

-- =============================================
-- Test 3: GetScheduleByApplication - Retrieve Schedule
-- =============================================
PRINT 'Test 3: GetScheduleByApplication - Retrieve Schedule';
PRINT '-------------------------------------------';

-- Query for payment schedule
SELECT 
    ScheduleId,
    ApplicationId,
    PaymentNumber,
    DueDate,
    PaymentAmount,
    PrincipalAmount,
    InterestAmount,
    RemainingBalance
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId1
ORDER BY PaymentNumber;

PRINT 'Expected: 24 rows with payment details';
PRINT '';

-- =============================================
-- Test 4: Verify Payment Schedule Calculations
-- =============================================
PRINT 'Test 4: Verify Payment Schedule Calculations';
PRINT '-------------------------------------------';

-- Verify first payment
SELECT TOP 1
    PaymentNumber,
    PaymentAmount,
    PrincipalAmount,
    InterestAmount,
    RemainingBalance
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId1
ORDER BY PaymentNumber;

PRINT 'First payment should have highest interest amount';
PRINT '';

-- Verify last payment
SELECT TOP 1
    PaymentNumber,
    PaymentAmount,
    PrincipalAmount,
    InterestAmount,
    RemainingBalance
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId1
ORDER BY PaymentNumber DESC;

PRINT 'Last payment should have remaining balance = 0';
PRINT '';

-- Verify total payments equal loan amount + interest
SELECT 
    SUM(PrincipalAmount) AS TotalPrincipal,
    SUM(InterestAmount) AS TotalInterest,
    SUM(PaymentAmount) AS TotalPayments
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId1;

PRINT 'Total principal should equal approved amount ($10,000)';
PRINT '';

-- =============================================
-- Test 5: CalculateSchedule - Recalculate Schedule
-- =============================================
PRINT 'Test 5: CalculateSchedule - Recalculate Schedule';
PRINT '-------------------------------------------';

-- Get count before recalculation
DECLARE @CountBefore INT;
SELECT @CountBefore = COUNT(*) FROM PaymentSchedules WHERE ApplicationId = @ApplicationId1;

-- Recalculate schedule (should delete old and create new)
EXEC sp_CalculatePaymentSchedule @ApplicationId1;

-- Get count after recalculation
DECLARE @CountAfter INT;
SELECT @CountAfter = COUNT(*) FROM PaymentSchedules WHERE ApplicationId = @ApplicationId1;

PRINT 'Count before: ' + CAST(@CountBefore AS VARCHAR);
PRINT 'Count after: ' + CAST(@CountAfter AS VARCHAR);
PRINT 'Expected: Both should be 24';
PRINT '';

-- =============================================
-- Test 6: GetScheduleByApplication - Different Loan Terms
-- =============================================
PRINT 'Test 6: GetScheduleByApplication - Different Loan Terms';
PRINT '-------------------------------------------';

DECLARE @ApplicationId2 INT;

-- Create a 12-month loan
INSERT INTO LoanApplications (ApplicationNumber, CustomerId, LoanType, RequestedAmount, TermMonths, Purpose, Status, ApplicationDate, ApprovedAmount, InterestRate)
VALUES ('TEST-PS-002', @CustomerId2, 'Auto', 20000, 12, 'Test auto loan', 'Approved', GETDATE(), 20000, 6.5);
SET @ApplicationId2 = SCOPE_IDENTITY();

-- Calculate schedule
EXEC sp_CalculatePaymentSchedule @ApplicationId2;

-- Verify schedule count
SELECT COUNT(*) AS ScheduleCount
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId2;

PRINT 'Expected: 12 schedules (12-month term)';
PRINT '';

-- =============================================
-- Test 7: Verify Schedule Ordering
-- =============================================
PRINT 'Test 7: Verify Schedule Ordering';
PRINT '-------------------------------------------';

-- Verify payment numbers are sequential
SELECT 
    PaymentNumber,
    DueDate
FROM PaymentSchedules
WHERE ApplicationId = @ApplicationId1
ORDER BY PaymentNumber;

PRINT 'Expected: Payment numbers 1-24 in order, due dates one month apart';
PRINT '';

-- =============================================
-- Test 8: Verify No Cross-Application Contamination
-- =============================================
PRINT 'Test 8: Verify No Cross-Application Contamination';
PRINT '-------------------------------------------';

-- Verify each application has its own schedule
SELECT 
    ApplicationId,
    COUNT(*) AS ScheduleCount
FROM PaymentSchedules
WHERE ApplicationId IN (@ApplicationId1, @ApplicationId2)
GROUP BY ApplicationId
ORDER BY ApplicationId;

PRINT 'Expected: Application 1 has 24, Application 2 has 12';
PRINT '';

-- =============================================
-- Clean up test data
-- =============================================
PRINT 'Cleaning up test data...';

DELETE FROM PaymentSchedules WHERE ApplicationId IN (@ApplicationId1, @ApplicationId2);
DELETE FROM LoanApplications WHERE ApplicationId IN (@ApplicationId1, @ApplicationId2);
DELETE FROM Customers WHERE CustomerId IN (@CustomerId1, @CustomerId2);

PRINT 'Test data cleaned up.';
PRINT '';

PRINT '========================================';
PRINT 'PaymentScheduleRepository Tests Complete';
PRINT '========================================';
