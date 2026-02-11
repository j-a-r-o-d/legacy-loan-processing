-- ============================================================================
-- Script: Create Customer Management Stored Procedures (Task 3)
-- Description: Creates all stored procedures for customer management
-- ============================================================================

USE LoanProcessing;
GO

PRINT 'Creating customer management stored procedures...';
PRINT '';

-- Drop existing procedures if they exist
IF OBJECT_ID('dbo.sp_GetCustomerById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetCustomerById;
GO

IF OBJECT_ID('dbo.sp_UpdateCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateCustomer;
GO

IF OBJECT_ID('dbo.sp_SearchCustomers', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_SearchCustomers;
GO

IF OBJECT_ID('dbo.sp_CreateCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateCustomer;
GO

PRINT '✓ Dropped existing procedures (if any)';
PRINT '';

-- Create sp_GetCustomerById
PRINT 'Creating sp_GetCustomerById...';
GO

CREATE PROCEDURE [dbo].[sp_GetCustomerById]
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Return customer details
    SELECT 
        [CustomerId],
        [FirstName],
        [LastName],
        [SSN],
        [DateOfBirth],
        [AnnualIncome],
        [CreditScore],
        [Email],
        [Phone],
        [Address],
        [CreatedDate],
        [ModifiedDate]
    FROM 
        [dbo].[Customers]
    WHERE 
        [CustomerId] = @CustomerId;
    
    -- Return 0 if found, -1 if not found
    IF @@ROWCOUNT = 0
        RETURN -1;
    ELSE
        RETURN 0;
END
GO

PRINT '✓ sp_GetCustomerById created';
PRINT '';

-- Create sp_UpdateCustomer
PRINT 'Creating sp_UpdateCustomer...';
GO

CREATE PROCEDURE [dbo].[sp_UpdateCustomer]
    @CustomerId INT,
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @DateOfBirth DATE,
    @AnnualIncome DECIMAL(18,2),
    @CreditScore INT,
    @Email NVARCHAR(255),
    @Phone NVARCHAR(20),
    @Address NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check if customer exists
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Customers] WHERE [CustomerId] = @CustomerId)
    BEGIN
        RAISERROR('Customer not found.', 16, 1);
        RETURN -1;
    END
    
    -- Validation: Check age (must be 18 or older)
    IF DATEDIFF(YEAR, @DateOfBirth, GETDATE()) < 18
    BEGIN
        RAISERROR('Customer must be at least 18 years old.', 16, 1);
        RETURN -2;
    END
    
    -- Validation: Check credit score range (300-850)
    IF @CreditScore < 300 OR @CreditScore > 850
    BEGIN
        RAISERROR('Credit score must be between 300 and 850.', 16, 1);
        RETURN -3;
    END
    
    -- Validation: Check annual income is positive
    IF @AnnualIncome < 0
    BEGIN
        RAISERROR('Annual income must be a positive value.', 16, 1);
        RETURN -4;
    END
    
    -- Update customer (SSN cannot be changed)
    UPDATE [dbo].[Customers]
    SET 
        [FirstName] = @FirstName,
        [LastName] = @LastName,
        [DateOfBirth] = @DateOfBirth,
        [AnnualIncome] = @AnnualIncome,
        [CreditScore] = @CreditScore,
        [Email] = @Email,
        [Phone] = @Phone,
        [Address] = @Address,
        [ModifiedDate] = GETDATE()
    WHERE 
        [CustomerId] = @CustomerId;
    
    RETURN 0;
END
GO

PRINT '✓ sp_UpdateCustomer created';
PRINT '';

-- Create sp_SearchCustomers
PRINT 'Creating sp_SearchCustomers...';
GO

CREATE PROCEDURE [dbo].[sp_SearchCustomers]
    @SearchTerm NVARCHAR(255) = NULL,
    @CustomerId INT = NULL,
    @SSN NVARCHAR(11) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Return customers matching search criteria
    SELECT 
        [CustomerId],
        [FirstName],
        [LastName],
        [SSN],
        [DateOfBirth],
        [AnnualIncome],
        [CreditScore],
        [Email],
        [Phone],
        [Address],
        [CreatedDate],
        [ModifiedDate]
    FROM 
        [dbo].[Customers]
    WHERE 
        -- Search by CustomerId if provided
        (@CustomerId IS NOT NULL AND [CustomerId] = @CustomerId)
        OR
        -- Search by exact SSN if provided
        (@SSN IS NOT NULL AND [SSN] = @SSN)
        OR
        -- Search by name (partial match) if SearchTerm provided
        (@SearchTerm IS NOT NULL AND (
            [FirstName] LIKE '%' + @SearchTerm + '%'
            OR [LastName] LIKE '%' + @SearchTerm + '%'
            OR ([FirstName] + ' ' + [LastName]) LIKE '%' + @SearchTerm + '%'
        ))
    ORDER BY 
        [LastName], [FirstName];
    
    RETURN 0;
END
GO

PRINT '✓ sp_SearchCustomers created';
PRINT '';

-- Create sp_CreateCustomer
PRINT 'Creating sp_CreateCustomer...';
GO

CREATE PROCEDURE [dbo].[sp_CreateCustomer]
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @SSN NVARCHAR(11),
    @DateOfBirth DATE,
    @AnnualIncome DECIMAL(18,2),
    @CreditScore INT,
    @Email NVARCHAR(255),
    @Phone NVARCHAR(20),
    @Address NVARCHAR(500),
    @CustomerId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check if SSN already exists
    IF EXISTS (SELECT 1 FROM [dbo].[Customers] WHERE [SSN] = @SSN)
    BEGIN
        RAISERROR('A customer with this SSN already exists.', 16, 1);
        RETURN -1;
    END
    
    -- Validation: Check age (must be 18 or older)
    IF DATEDIFF(YEAR, @DateOfBirth, GETDATE()) < 18
    BEGIN
        RAISERROR('Customer must be at least 18 years old.', 16, 1);
        RETURN -2;
    END
    
    -- Validation: Check credit score range (300-850)
    IF @CreditScore < 300 OR @CreditScore > 850
    BEGIN
        RAISERROR('Credit score must be between 300 and 850.', 16, 1);
        RETURN -3;
    END
    
    -- Validation: Check annual income is positive
    IF @AnnualIncome < 0
    BEGIN
        RAISERROR('Annual income must be a positive value.', 16, 1);
        RETURN -4;
    END
    
    -- Insert new customer
    INSERT INTO [dbo].[Customers] (
        [FirstName],
        [LastName],
        [SSN],
        [DateOfBirth],
        [AnnualIncome],
        [CreditScore],
        [Email],
        [Phone],
        [Address],
        [CreatedDate],
        [ModifiedDate]
    )
    VALUES (
        @FirstName,
        @LastName,
        @SSN,
        @DateOfBirth,
        @AnnualIncome,
        @CreditScore,
        @Email,
        @Phone,
        @Address,
        GETDATE(),
        GETDATE()
    );
    
    -- Return the new CustomerId
    SET @CustomerId = SCOPE_IDENTITY();
    
    RETURN 0;
END
GO

PRINT '✓ sp_CreateCustomer created';
PRINT '';

-- Summary
PRINT '========================================';
PRINT 'Customer Management Stored Procedures Created!';
PRINT '========================================';
PRINT '';
PRINT 'Created procedures:';
PRINT '  • sp_CreateCustomer - Create new customers with validation';
PRINT '  • sp_UpdateCustomer - Update existing customer information';
PRINT '  • sp_GetCustomerById - Retrieve customer by ID';
PRINT '  • sp_SearchCustomers - Search customers by name, ID, or SSN';
PRINT '';
PRINT 'Run TestCustomerProcedures.sql to verify the procedures.';
GO
