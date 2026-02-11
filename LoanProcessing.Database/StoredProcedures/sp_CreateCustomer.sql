-- ============================================================================
-- Stored Procedure: sp_CreateCustomer
-- Description: Creates a new customer with validation
-- Requirements: 1.1, 1.5
-- ============================================================================

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
