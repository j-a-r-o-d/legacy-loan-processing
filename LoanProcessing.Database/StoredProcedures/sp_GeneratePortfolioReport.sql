-- =============================================
-- Stored Procedure: sp_GeneratePortfolioReport
-- Description: Generates comprehensive portfolio report with summary statistics,
--              loan type breakdown, and risk distribution
-- Requirements: 6.1, 6.2, 6.3, 6.4, 6.5
-- =============================================
CREATE PROCEDURE sp_GeneratePortfolioReport
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @LoanType NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default date range to last 12 months if not specified
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(YEAR, -1, GETDATE());
    
    IF @EndDate IS NULL
        SET @EndDate = GETDATE();
    
    -- Portfolio summary
    -- Returns aggregate statistics across all loans in the date range
    SELECT 
        COUNT(DISTINCT la.ApplicationId) AS TotalLoans,
        COUNT(DISTINCT CASE WHEN la.Status = 'Approved' THEN la.ApplicationId END) AS ApprovedLoans,
        COUNT(DISTINCT CASE WHEN la.Status = 'Rejected' THEN la.ApplicationId END) AS RejectedLoans,
        COUNT(DISTINCT CASE WHEN la.Status IN ('Pending', 'UnderReview') THEN la.ApplicationId END) AS PendingLoans,
        SUM(CASE WHEN la.Status = 'Approved' THEN la.ApprovedAmount ELSE 0 END) AS TotalApprovedAmount,
        AVG(CASE WHEN la.Status = 'Approved' THEN la.ApprovedAmount END) AS AverageApprovedAmount,
        AVG(CASE WHEN la.Status = 'Approved' THEN la.InterestRate END) AS AverageInterestRate,
        AVG(CASE WHEN ld.RiskScore IS NOT NULL THEN ld.RiskScore END) AS AverageRiskScore
    FROM LoanApplications la
    LEFT JOIN LoanDecisions ld ON la.ApplicationId = ld.ApplicationId
    WHERE la.ApplicationDate BETWEEN @StartDate AND @EndDate
      AND (@LoanType IS NULL OR la.LoanType = @LoanType);
    
    -- Breakdown by loan type
    -- Returns statistics grouped by loan type (Personal, Auto, Mortgage, Business)
    SELECT 
        la.LoanType,
        COUNT(DISTINCT la.ApplicationId) AS TotalApplications,
        COUNT(DISTINCT CASE WHEN la.Status = 'Approved' THEN la.ApplicationId END) AS ApprovedCount,
        SUM(CASE WHEN la.Status = 'Approved' THEN la.ApprovedAmount ELSE 0 END) AS TotalAmount,
        AVG(CASE WHEN la.Status = 'Approved' THEN la.InterestRate END) AS AvgInterestRate
    FROM LoanApplications la
    WHERE la.ApplicationDate BETWEEN @StartDate AND @EndDate
      AND (@LoanType IS NULL OR la.LoanType = @LoanType)
    GROUP BY la.LoanType
    ORDER BY TotalAmount DESC;
    
    -- Risk distribution
    -- Returns statistics grouped by risk score ranges
    SELECT 
        CASE 
            WHEN ld.RiskScore <= 20 THEN 'Low Risk (0-20)'
            WHEN ld.RiskScore <= 40 THEN 'Medium Risk (21-40)'
            WHEN ld.RiskScore <= 60 THEN 'High Risk (41-60)'
            ELSE 'Very High Risk (61+)'
        END AS RiskCategory,
        COUNT(*) AS LoanCount,
        SUM(la.ApprovedAmount) AS TotalAmount,
        AVG(la.InterestRate) AS AvgInterestRate
    FROM LoanApplications la
    INNER JOIN LoanDecisions ld ON la.ApplicationId = ld.ApplicationId
    WHERE la.Status = 'Approved'
      AND la.ApplicationDate BETWEEN @StartDate AND @EndDate
      AND (@LoanType IS NULL OR la.LoanType = @LoanType)
    GROUP BY CASE 
        WHEN ld.RiskScore <= 20 THEN 'Low Risk (0-20)'
        WHEN ld.RiskScore <= 40 THEN 'Medium Risk (21-40)'
        WHEN ld.RiskScore <= 60 THEN 'High Risk (41-60)'
        ELSE 'Very High Risk (61+)'
    END
    ORDER BY MIN(ld.RiskScore);
END
GO
