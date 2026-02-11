-- ============================================================================
-- Script: Create sp_SearchCustomersAutocomplete Stored Procedure
-- Description: Creates the autocomplete search stored procedure for customer selection
-- Requirements: 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 3.3
-- ============================================================================

USE LoanProcessing;
GO

PRINT 'Creating sp_SearchCustomersAutocomplete stored procedure...';
PRINT '';

-- Drop existing procedure if it exists
IF OBJECT_ID('dbo.sp_SearchCustomersAutocomplete', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_SearchCustomersAutocomplete;
    PRINT '✓ Dropped existing sp_SearchCustomersAutocomplete';
END
GO

-- Create the stored procedure
PRINT 'Creating sp_SearchCustomersAutocomplete...';
GO

CREATE PROCEDURE [dbo].[sp_SearchCustomersAutocomplete]
    @SearchTerm NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate input
    IF @SearchTerm IS NULL OR LEN(LTRIM(RTRIM(@SearchTerm))) < 2
    BEGIN
        -- Return empty result set for invalid input
        SELECT TOP 0
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
        FROM [dbo].[Customers];
        RETURN 0;
    END
    
    DECLARE @IsNumeric BIT = 0;
    DECLARE @SearchTermTrimmed NVARCHAR(255) = LTRIM(RTRIM(@SearchTerm));
    DECLARE @SearchTermLower NVARCHAR(255) = LOWER(@SearchTermTrimmed);
    
    -- Check if search term is numeric (for ID or SSN search)
    -- ISNUMERIC returns 1 for numeric values, 0 otherwise
    IF ISNUMERIC(@SearchTermTrimmed) = 1
        SET @IsNumeric = 1;
    
    -- Return top 10 customers matching search criteria
    -- Ordered by relevance: exact matches first, then partial matches
    SELECT TOP 10
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
        -- Numeric search: Search by customer ID or SSN (last 4 digits)
        (@IsNumeric = 1 AND (
            -- Exact customer ID match
            [CustomerId] = TRY_CAST(@SearchTermTrimmed AS INT)
            OR
            -- SSN match (last 4 digits)
            RIGHT([SSN], 4) = RIGHT(@SearchTermTrimmed, 4)
        ))
        OR
        -- Alphabetic/mixed search: Search by name (partial match)
        (@IsNumeric = 0 AND (
            [FirstName] LIKE '%' + @SearchTermTrimmed + '%'
            OR [LastName] LIKE '%' + @SearchTermTrimmed + '%'
            OR ([FirstName] + ' ' + [LastName]) LIKE '%' + @SearchTermTrimmed + '%'
        ))
    ORDER BY 
        -- Relevance scoring: lower numbers = higher relevance
        CASE
            -- Exact customer ID match (highest priority)
            WHEN @IsNumeric = 1 AND [CustomerId] = TRY_CAST(@SearchTermTrimmed AS INT) THEN 1
            -- SSN match (last 4 digits)
            WHEN @IsNumeric = 1 AND RIGHT([SSN], 4) = RIGHT(@SearchTermTrimmed, 4) THEN 2
            -- Exact last name match (case-insensitive)
            WHEN @IsNumeric = 0 AND LOWER([LastName]) = @SearchTermLower THEN 3
            -- Exact first name match (case-insensitive)
            WHEN @IsNumeric = 0 AND LOWER([FirstName]) = @SearchTermLower THEN 4
            -- Last name starts with search term
            WHEN @IsNumeric = 0 AND LOWER([LastName]) LIKE @SearchTermLower + '%' THEN 5
            -- First name starts with search term
            WHEN @IsNumeric = 0 AND LOWER([FirstName]) LIKE @SearchTermLower + '%' THEN 6
            -- Full name contains search term
            WHEN @IsNumeric = 0 AND LOWER([FirstName] + ' ' + [LastName]) LIKE '%' + @SearchTermLower + '%' THEN 7
            -- Last name contains search term
            WHEN @IsNumeric = 0 AND LOWER([LastName]) LIKE '%' + @SearchTermLower + '%' THEN 8
            -- First name contains search term
            WHEN @IsNumeric = 0 AND LOWER([FirstName]) LIKE '%' + @SearchTermLower + '%' THEN 9
            -- Default (should not reach here due to WHERE clause)
            ELSE 10
        END,
        -- Secondary sort by name for consistent ordering within same relevance
        [LastName], 
        [FirstName];
    
    RETURN 0;
END
GO

PRINT '✓ sp_SearchCustomersAutocomplete created successfully';
PRINT '';

-- Verify the procedure was created
IF OBJECT_ID('dbo.sp_SearchCustomersAutocomplete', 'P') IS NOT NULL
BEGIN
    PRINT '========================================';
    PRINT 'SUCCESS: sp_SearchCustomersAutocomplete is ready!';
    PRINT '========================================';
    PRINT '';
    PRINT 'INDEXING RECOMMENDATIONS:';
    PRINT '  • CREATE INDEX IX_Customers_Names ON Customers(LastName, FirstName);';
    PRINT '  • Index IX_Customers_SSN already exists for SSN searches';
    PRINT '';
    PRINT 'Run TestSearchCustomersAutocomplete.sql to verify the procedure.';
END
ELSE
BEGIN
    PRINT 'ERROR: Failed to create sp_SearchCustomersAutocomplete';
END
GO
