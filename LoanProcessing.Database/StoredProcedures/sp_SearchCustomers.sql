-- ============================================================================
-- Stored Procedure: sp_SearchCustomers
-- Description: Searches for customers by name, customer ID, or SSN
-- Requirements: 1.4
-- ============================================================================

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
        -- Return all customers if no search criteria provided
        (
            @CustomerId IS NULL 
            AND @SSN IS NULL 
            AND @SearchTerm IS NULL
        )
        OR
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
