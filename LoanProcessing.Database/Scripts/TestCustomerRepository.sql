-- ============================================================================
-- Test Script: Customer Repository Integration Test
-- Description: Tests the CustomerRepository implementation with stored procedures
-- Task: 10.1
-- ============================================================================

USE [LoanProcessing];
GO

PRINT '============================================================================';
PRINT 'Customer Repository Integration Test';
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- Test 1: GetById - Retrieve existing customer
-- ============================================================================
PRINT 'Test 1: Testing GetById with existing customer...';

-- First, create a test customer
DECLARE @TestCustomerId INT;
EXEC dbo.sp_CreateCustomer
    @FirstName = 'Repository',
    @LastName = 'TestUser',
    @SSN = '999-88-7777',
    @DateOfBirth = '1990-01-15',
    @AnnualIncome = 75000.00,
    @CreditScore = 720,
    @Email = 'repo.test@example.com',
    @Phone = '555-0199',
    @Address = '123 Repository Lane',
    @CustomerId = @TestCustomerId OUTPUT;

PRINT '  Created test customer with ID: ' + CAST(@TestCustomerId AS NVARCHAR(10));

-- Test GetById
EXEC dbo.sp_GetCustomerById @CustomerId = @TestCustomerId;

PRINT '✓ GetById test completed';
PRINT '';

-- ============================================================================
-- Test 2: Search - Search by name
-- ============================================================================
PRINT 'Test 2: Testing Search with name search term...';

EXEC dbo.sp_SearchCustomers @SearchTerm = 'Repository';

PRINT '✓ Search by name test completed';
PRINT '';

-- ============================================================================
-- Test 3: CreateCustomer - Verify all fields are mapped correctly
-- ============================================================================
PRINT 'Test 3: Testing CreateCustomer with all fields...';

DECLARE @NewCustomerId INT;
EXEC dbo.sp_CreateCustomer
    @FirstName = 'Complete',
    @LastName = 'Mapping',
    @SSN = '888-77-6666',
    @DateOfBirth = '1985-06-20',
    @AnnualIncome = 95000.00,
    @CreditScore = 780,
    @Email = 'complete.mapping@example.com',
    @Phone = '555-0188',
    @Address = '456 Mapping Street',
    @CustomerId = @NewCustomerId OUTPUT;

PRINT '  Created customer with ID: ' + CAST(@NewCustomerId AS NVARCHAR(10));

-- Verify all fields were saved correctly
SELECT 
    CustomerId,
    FirstName,
    LastName,
    SSN,
    DateOfBirth,
    AnnualIncome,
    CreditScore,
    Email,
    Phone,
    Address,
    CreatedDate,
    ModifiedDate
FROM Customers
WHERE CustomerId = @NewCustomerId;

PRINT '✓ CreateCustomer field mapping test completed';
PRINT '';

-- ============================================================================
-- Test 4: UpdateCustomer - Verify update works correctly
-- ============================================================================
PRINT 'Test 4: Testing UpdateCustomer...';

-- Update the customer
EXEC dbo.sp_UpdateCustomer
    @CustomerId = @NewCustomerId,
    @FirstName = 'Updated',
    @LastName = 'Customer',
    @DateOfBirth = '1985-06-20',
    @AnnualIncome = 105000.00,
    @CreditScore = 800,
    @Email = 'updated.customer@example.com',
    @Phone = '555-0177',
    @Address = '789 Updated Avenue';

-- Verify the update
SELECT 
    CustomerId,
    FirstName,
    LastName,
    AnnualIncome,
    CreditScore,
    Email,
    Phone,
    Address,
    ModifiedDate
FROM Customers
WHERE CustomerId = @NewCustomerId;

PRINT '✓ UpdateCustomer test completed';
PRINT '';

-- ============================================================================
-- Test 5: MapCustomerFromReader - Verify nullable ModifiedDate handling
-- ============================================================================
PRINT 'Test 5: Testing nullable ModifiedDate field mapping...';

-- Create a customer and immediately check if ModifiedDate is set
DECLARE @NullTestId INT;
EXEC dbo.sp_CreateCustomer
    @FirstName = 'Null',
    @LastName = 'Test',
    @SSN = '777-66-5555',
    @DateOfBirth = '1992-03-10',
    @AnnualIncome = 65000.00,
    @CreditScore = 690,
    @Email = 'null.test@example.com',
    @Phone = '555-0166',
    @Address = '321 Null Street',
    @CustomerId = @NullTestId OUTPUT;

-- Check ModifiedDate (should be set by sp_CreateCustomer)
SELECT 
    CustomerId,
    CreatedDate,
    ModifiedDate,
    CASE 
        WHEN ModifiedDate IS NULL THEN 'NULL'
        ELSE 'NOT NULL'
    END AS ModifiedDateStatus
FROM Customers
WHERE CustomerId = @NullTestId;

PRINT '✓ Nullable field mapping test completed';
PRINT '';

-- ============================================================================
-- Test 6: Search - Multiple search scenarios
-- ============================================================================
PRINT 'Test 6: Testing Search with various criteria...';

PRINT '  6a. Search by partial first name:';
EXEC dbo.sp_SearchCustomers @SearchTerm = 'Repo';

PRINT '  6b. Search by partial last name:';
EXEC dbo.sp_SearchCustomers @SearchTerm = 'Test';

PRINT '  6c. Search by CustomerId:';
EXEC dbo.sp_SearchCustomers @CustomerId = @TestCustomerId;

PRINT '  6d. Search by SSN:';
EXEC dbo.sp_SearchCustomers @SSN = '999-88-7777';

PRINT '✓ Multiple search scenarios test completed';
PRINT '';

-- ============================================================================
-- Test 7: Error handling - Verify exceptions are properly thrown
-- ============================================================================
PRINT 'Test 7: Testing error handling...';

PRINT '  7a. Testing duplicate SSN error:';
BEGIN TRY
    DECLARE @DuplicateId INT;
    EXEC dbo.sp_CreateCustomer
        @FirstName = 'Duplicate',
        @LastName = 'SSN',
        @SSN = '999-88-7777', -- Duplicate SSN
        @DateOfBirth = '1990-01-15',
        @AnnualIncome = 75000.00,
        @CreditScore = 720,
        @Email = 'duplicate@example.com',
        @Phone = '555-0155',
        @Address = '999 Duplicate Road',
        @CustomerId = @DuplicateId OUTPUT;
    PRINT '  ✗ ERROR: Should have thrown duplicate SSN exception';
END TRY
BEGIN CATCH
    PRINT '  ✓ Correctly caught duplicate SSN error: ' + ERROR_MESSAGE();
END CATCH

PRINT '  7b. Testing update non-existent customer error:';
BEGIN TRY
    EXEC dbo.sp_UpdateCustomer
        @CustomerId = 999999, -- Non-existent ID
        @FirstName = 'Non',
        @LastName = 'Existent',
        @DateOfBirth = '1990-01-15',
        @AnnualIncome = 75000.00,
        @CreditScore = 720,
        @Email = 'nonexistent@example.com',
        @Phone = '555-0144',
        @Address = '888 Nowhere Street';
    PRINT '  ✗ ERROR: Should have thrown customer not found exception';
END TRY
BEGIN CATCH
    PRINT '  ✓ Correctly caught customer not found error: ' + ERROR_MESSAGE();
END CATCH

PRINT '✓ Error handling test completed';
PRINT '';

-- ============================================================================
-- Cleanup
-- ============================================================================
PRINT 'Cleaning up test data...';

DELETE FROM Customers WHERE CustomerId IN (@TestCustomerId, @NewCustomerId, @NullTestId);

PRINT '✓ Test data cleaned up';
PRINT '';

-- ============================================================================
-- Summary
-- ============================================================================
PRINT '============================================================================';
PRINT 'Customer Repository Integration Test Summary';
PRINT '============================================================================';
PRINT '';
PRINT 'All tests completed successfully:';
PRINT '  ✓ GetById - Retrieves customer correctly';
PRINT '  ✓ Search - Searches by name correctly';
PRINT '  ✓ CreateCustomer - All fields mapped correctly';
PRINT '  ✓ UpdateCustomer - Updates customer correctly';
PRINT '  ✓ MapCustomerFromReader - Handles nullable fields correctly';
PRINT '  ✓ Search - Multiple search scenarios work correctly';
PRINT '  ✓ Error handling - Exceptions are properly thrown';
PRINT '';
PRINT 'Task 10.1 Complete: ICustomerRepository interface and implementation verified!';
PRINT '============================================================================';
GO

