-- ============================================================================
-- Stored Procedure: sp_SearchCustomersAutocomplete
-- Description: Searches for customers for autocomplete functionality with 
--              relevance scoring and result limiting
-- Requirements: 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 3.3
-- ============================================================================
-- 
-- INDEXING RECOMMENDATIONS:
-- For optimal performance with large customer databases (100,000+ records):
-- 
-- 1. Composite index for name searches:
--    CREATE INDEX IX_Customers_Names ON Customers(LastName, FirstName);
--    This index supports the most common search pattern (name-based searches)
--    and improves ORDER BY performance.
--
-- 2. Index for SSN searches (already exists):
--    CREATE INDEX IX_Customers_SSN ON Customers(SSN);
--    Supports numeric searches by last 4 digits of SSN.
--
-- 3. Consider full-text index for advanced name searching:
--    CREATE FULLTEXT INDEX ON Customers(FirstName, LastName)
--    KEY INDEX PK_Customers;
--    This provides better performance for complex name searches but requires
--    additional setup and maintenance.
--
-- PERFORMANCE NOTES:
-- - The stored procedure uses CASE expressions for relevance scoring
-- - TOP 10 limit ensures fast response times even with large result sets
-- - ISNUMERIC check determines search strategy (numeric vs alphabetic)
-- - All string comparisons use LOWER() for case-insensitive matching
-- ============================================================================

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
