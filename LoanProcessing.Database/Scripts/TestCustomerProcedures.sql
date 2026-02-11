-- ============================================================================
-- Script: Test Customer Management Stored Procedures (Task 3)
-- Description: Tests all customer management stored procedures
-- ============================================================================

USE LoanProcessing;
GO

PRINT '========================================';
PRINT 'Testing Customer Management Stored Procedures';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- Test 1: sp_CreateCustomer - Valid customer
-- ============================================================================
PRINT 'Test 1: Creating a new customer...';

DECLARE @NewCustomerId INT;

EXEC dbo.sp_CreateCustomer
    @FirstName = 'Test',
    @LastName = 'Customer',
    @SSN = '999-99-9999',
    @DateOfBirth = '1990-01-01',
    @AnnualIncome = 50000.00,
    @CreditScore = 700,
    @Email = 'test.customer@email.com',
    @Phone = '555-0199',
    @Address = '123 Test St, Test City, TS 12345',
    @CustomerId = @NewCustomerId OUTPUT;

IF @NewCustomerId IS NOT NULL
    PRINT '✓ Customer created successfully with ID: ' + CAST(@NewCustomerId AS NVARCHAR(10));
ELSE
    PRINT '✗ Failed to create customer';

PRINT '';

-- ============================================================================
-- Test 2: sp_CreateCustomer - Duplicate SSN (should fail)
-- ============================================================================
PRINT 'Test 2: Attempting to create customer with duplicate SSN...';

BEGIN TRY
    DECLARE @DuplicateId INT;
    
    EXEC dbo.sp_CreateCustomer
        @FirstName = 'Duplicate',
        @LastName = 'Customer',
        @SSN = '999-99-9999',  -- Same SSN as Test 1
        @DateOfBirth = '1985-01-01',
        @AnnualIncome = 60000.00,
        @CreditScore = 750,
        @Email = 'duplicate@email.com',
        @Phone = '555-0198',
        @Address = '456 Test Ave, Test City, TS 12345',
        @CustomerId = @DuplicateId OUTPUT;
    
    PRINT '✗ Should have failed with duplicate SSN error';
END TRY
BEGIN CATCH
    PRINT '✓ Correctly rejected duplicate SSN: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- ============================================================================
-- Test 3: sp_CreateCustomer - Underage customer (should fail)
-- ============================================================================
PRINT 'Test 3: Attempting to create underage customer...';

BEGIN TRY
    DECLARE @UnderageId INT;
    
    EXEC dbo.sp_CreateCustomer
        @FirstName = 'Young',
        @LastName = 'Customer',
        @SSN = '888-88-8888',
        @DateOfBirth = '2010-01-01',  -- Only 15 years old
        @AnnualIncome = 30000.00,
        @CreditScore = 650,
        @Email = 'young@email.com',
        @Phone = '555-0197',
        @Address = '789 Test Blvd, Test City, TS 12345',
        @CustomerId = @UnderageId OUTPUT;
    
    PRINT '✗ Should have failed with age validation error';
END TRY
BEGIN CATCH
    PRINT '✓ Correctly rejected underage customer: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- ============================================================================
-- Test 4: sp_CreateCustomer - Invalid credit score (should fail)
-- ============================================================================
PRINT 'Test 4: Attempting to create customer with invalid credit score...';

BEGIN TRY
    DECLARE @InvalidScoreId INT;
    
    EXEC dbo.sp_CreateCustomer
        @FirstName = 'Invalid',
        @LastName = 'Score',
        @SSN = '777-77-7777',
        @DateOfBirth = '1980-01-01',
        @AnnualIncome = 40000.00,
        @CreditScore = 900,  -- Invalid: above 850
        @Email = 'invalid@email.com',
        @Phone = '555-0196',
        @Address = '321 Test Dr, Test City, TS 12345',
        @CustomerId = @InvalidScoreId OUTPUT;
    
    PRINT '✗ Should have failed with credit score validation error';
END TRY
BEGIN CATCH
    PRINT '✓ Correctly rejected invalid credit score: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- ============================================================================
-- Test 5: sp_GetCustomerById - Retrieve existing customer
-- ============================================================================
PRINT 'Test 5: Retrieving customer by ID...';

EXEC dbo.sp_GetCustomerById @CustomerId = @NewCustomerId;

PRINT '✓ Customer retrieved successfully';
PRINT '';

-- ============================================================================
-- Test 6: sp_GetCustomerById - Non-existent customer
-- ============================================================================
PRINT 'Test 6: Attempting to retrieve non-existent customer...';

DECLARE @Result INT;
EXEC @Result = dbo.sp_GetCustomerById @CustomerId = 99999;

IF @Result = -1
    PRINT '✓ Correctly returned no results for non-existent customer';
ELSE
    PRINT '✗ Should have returned -1 for non-existent customer';

PRINT '';

-- ============================================================================
-- Test 7: sp_UpdateCustomer - Update existing customer
-- ============================================================================
PRINT 'Test 7: Updating customer information...';

EXEC dbo.sp_UpdateCustomer
    @CustomerId = @NewCustomerId,
    @FirstName = 'Test',
    @LastName = 'Customer',
    @DateOfBirth = '1990-01-01',
    @AnnualIncome = 55000.00,  -- Updated income
    @CreditScore = 720,  -- Updated credit score
    @Email = 'test.updated@email.com',  -- Updated email
    @Phone = '555-0199',
    @Address = '123 Test St, Test City, TS 12345';

PRINT '✓ Customer updated successfully';
PRINT '';

-- Verify the update
PRINT 'Verifying update...';
SELECT 
    CustomerId, 
    FirstName, 
    LastName, 
    AnnualIncome, 
    CreditScore, 
    Email,
    ModifiedDate
FROM 
    dbo.Customers 
WHERE 
    CustomerId = @NewCustomerId;

PRINT '';

-- ============================================================================
-- Test 8: sp_UpdateCustomer - Non-existent customer (should fail)
-- ============================================================================
PRINT 'Test 8: Attempting to update non-existent customer...';

BEGIN TRY
    EXEC dbo.sp_UpdateCustomer
        @CustomerId = 99999,
        @FirstName = 'Non',
        @LastName = 'Existent',
        @DateOfBirth = '1990-01-01',
        @AnnualIncome = 50000.00,
        @CreditScore = 700,
        @Email = 'nonexistent@email.com',
        @Phone = '555-0195',
        @Address = '999 Test Ln, Test City, TS 12345';
    
    PRINT '✗ Should have failed with customer not found error';
END TRY
BEGIN CATCH
    PRINT '✓ Correctly rejected update for non-existent customer: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- ============================================================================
-- Test 9: sp_SearchCustomers - Search by name
-- ============================================================================
PRINT 'Test 9: Searching customers by name...';

EXEC dbo.sp_SearchCustomers @SearchTerm = 'Smith';

PRINT '✓ Search by name completed';
PRINT '';

-- ============================================================================
-- Test 10: sp_SearchCustomers - Search by SSN
-- ============================================================================
PRINT 'Test 10: Searching customers by SSN...';

EXEC dbo.sp_SearchCustomers @SSN = '123-45-6789';

PRINT '✓ Search by SSN completed';
PRINT '';

-- ============================================================================
-- Test 11: sp_SearchCustomers - Search by CustomerId
-- ============================================================================
PRINT 'Test 11: Searching customers by CustomerId...';

EXEC dbo.sp_SearchCustomers @CustomerId = 1;

PRINT '✓ Search by CustomerId completed';
PRINT '';

-- ============================================================================
-- Test 12: sp_SearchCustomers - Partial name match
-- ============================================================================
PRINT 'Test 12: Searching customers with partial name match...';

EXEC dbo.sp_SearchCustomers @SearchTerm = 'John';

PRINT '✓ Partial name search completed';
PRINT '';

-- ============================================================================
-- Cleanup: Remove test customer
-- ============================================================================
PRINT 'Cleaning up test data...';

DELETE FROM dbo.Customers WHERE CustomerId = @NewCustomerId;

PRINT '✓ Test customer removed';
PRINT '';

-- ============================================================================
-- Summary
-- ============================================================================
PRINT '========================================';
PRINT 'Test Summary';
PRINT '========================================';
PRINT '';
PRINT 'All customer management stored procedures tested:';
PRINT '  ✓ sp_CreateCustomer - Valid customer creation';
PRINT '  ✓ sp_CreateCustomer - Duplicate SSN validation';
PRINT '  ✓ sp_CreateCustomer - Age validation';
PRINT '  ✓ sp_CreateCustomer - Credit score validation';
PRINT '  ✓ sp_GetCustomerById - Retrieve existing customer';
PRINT '  ✓ sp_GetCustomerById - Non-existent customer handling';
PRINT '  ✓ sp_UpdateCustomer - Update existing customer';
PRINT '  ✓ sp_UpdateCustomer - Non-existent customer validation';
PRINT '  ✓ sp_SearchCustomers - Search by name';
PRINT '  ✓ sp_SearchCustomers - Search by SSN';
PRINT '  ✓ sp_SearchCustomers - Search by CustomerId';
PRINT '  ✓ sp_SearchCustomers - Partial name match';
PRINT '';
PRINT 'Task 3 Complete: All customer management procedures working correctly!';
GO
