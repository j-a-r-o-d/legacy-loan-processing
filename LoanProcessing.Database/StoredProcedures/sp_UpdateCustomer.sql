-- ============================================================================
-- Stored Procedure: sp_UpdateCustomer
-- Description: Updates an existing customer's information
-- Requirements: 1.2
-- ============================================================================

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
