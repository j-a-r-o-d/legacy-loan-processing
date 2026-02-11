-- ============================================================================
-- Stored Procedure: sp_GetCustomerById
-- Description: Retrieves a customer by their ID
-- Requirements: 1.3
-- ============================================================================

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
