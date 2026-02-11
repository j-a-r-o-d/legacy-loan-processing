-- ============================================================================
-- Test Script: sp_ProcessLoanDecision with Evaluation Data
-- Description: Tests passing evaluation data to the decision procedure
-- ============================================================================

USE [LoanProcessing]
GO

PRINT '========================================';
PRINT 'Testing sp_ProcessLoanDecision with Evaluation Data';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- Test: Process approval with evaluation data passed as parameters
-- ============================================================================
PRINT 'Test: Process approval with evaluation data passed as parameters';
PRINT '----------------------------------------------------------------';

-- Find a Pending application
DECLARE @TestAppId INT;
SELECT TOP 1 @TestAppId = [ApplicationId]
FROM [dbo].[LoanApplications]
WHERE [Status] = 'Pending'
ORDER BY [ApplicationId] DESC;

IF @TestAppId IS NOT NULL
BEGIN
    -- Evaluate credit and capture the results
    DECLARE @EvalResults TABLE (
        ApplicationId INT,
        RiskScore INT,
        DebtToIncomeRatio DECIMAL(5,2),
        InterestRate DECIMAL(5,2),
        CreditScore INT,
        ExistingDebt DECIMAL(18,2),
        RequestedAmount DECIMAL(18,2),
        AnnualIncome DECIMAL(18,2),
        Recommendation NVARCHAR(100)
    );
    
    INSERT INTO @EvalResults
    EXEC [dbo].[sp_EvaluateCredit] @ApplicationId = @TestAppId;
    
    -- Get the evaluation data
    DECLARE @RiskScore INT;
    DECLARE @DTI DECIMAL(5,2);
    DECLARE @RequestedAmt DECIMAL(18,2);
    
    SELECT 
        @RiskScore = RiskScore,
        @DTI = DebtToIncomeRatio,
        @RequestedAmt = RequestedAmount
    FROM @EvalResults;
    
    PRINT 'Evaluation Results:';
    SELECT * FROM @EvalResults;
    PRINT '';
    
    -- Process approval decision with evaluation data
    EXEC [dbo].[sp_ProcessLoanDecision]
        @ApplicationId = @TestAppId,
        @Decision = 'Approved',
        @DecisionBy = 'Test Underwriter with Eval Data',
        @Comments = 'Approved with evaluation data passed',
        @RiskScore = @RiskScore,
        @DebtToIncomeRatio = @DTI;
    
    -- Verify results
    PRINT 'Decision Record with Evaluation Data:';
    SELECT 
        [DecisionId],
        [ApplicationId],
        [Decision],
        [DecisionBy],
        [ApprovedAmount],
        [InterestRate],
        [RiskScore],
        [DebtToIncomeRatio],
        [Comments],
        CASE 
            WHEN [RiskScore] IS NOT NULL AND [DebtToIncomeRatio] IS NOT NULL
            THEN 'PASS - Evaluation data preserved'
            ELSE 'FAIL - Evaluation data missing'
        END AS Result
    FROM [dbo].[LoanDecisions]
    WHERE [ApplicationId] = @TestAppId
    ORDER BY [DecisionDate] DESC;
    
    PRINT '';
    PRINT 'Application Status:';
    SELECT 
        [ApplicationId],
        [Status],
        [ApprovedAmount],
        [RequestedAmount],
        [InterestRate]
    FROM [dbo].[LoanApplications]
    WHERE [ApplicationId] = @TestAppId;
END
ELSE
BEGIN
    PRINT 'Test Result: SKIPPED - No suitable application found';
END

PRINT '';
PRINT '========================================';
PRINT 'Test Complete';
PRINT '========================================';

