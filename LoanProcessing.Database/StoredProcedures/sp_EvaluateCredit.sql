-- ============================================================================
-- Stored Procedure: sp_EvaluateCredit
-- Description: Performs credit evaluation for a loan application
-- Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
-- ============================================================================

IF OBJECT_ID('dbo.sp_EvaluateCredit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_EvaluateCredit;
GO

CREATE PROCEDURE [dbo].[sp_EvaluateCredit]
    @ApplicationId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Declare variables for application and customer data
        DECLARE @CustomerId INT, @CreditScore INT, @AnnualIncome DECIMAL(18,2);
        DECLARE @RequestedAmount DECIMAL(18,2), @LoanType NVARCHAR(20);
        DECLARE @RiskScore INT, @DebtToIncomeRatio DECIMAL(18,4);
        DECLARE @InterestRate DECIMAL(5,2), @TermMonths INT;
        
        -- Validation: Check if application exists
        IF NOT EXISTS (SELECT 1 FROM [dbo].[LoanApplications] WHERE [ApplicationId] = @ApplicationId)
        BEGIN
            RAISERROR('Loan application not found.', 16, 1);
            RETURN -1;
        END
        
        -- Get application and customer details (Requirement 3.1)
        SELECT @CustomerId = la.[CustomerId],
               @RequestedAmount = la.[RequestedAmount],
               @LoanType = la.[LoanType],
               @TermMonths = la.[TermMonths],
               @CreditScore = c.[CreditScore],
               @AnnualIncome = c.[AnnualIncome]
        FROM [dbo].[LoanApplications] la
        INNER JOIN [dbo].[Customers] c ON la.[CustomerId] = c.[CustomerId]
        WHERE la.[ApplicationId] = @ApplicationId;
        
        -- Calculate existing debt obligations from approved loans (Requirement 3.1)
        DECLARE @ExistingDebt DECIMAL(18,2);
        SELECT @ExistingDebt = ISNULL(SUM([ApprovedAmount]), 0)
        FROM [dbo].[LoanApplications]
        WHERE [CustomerId] = @CustomerId 
          AND [Status] = 'Approved'
          AND [ApplicationId] != @ApplicationId;
        
        -- Calculate debt-to-income ratio: ((existing + requested) / income) * 100 (Requirement 3.1, 3.2)
        SET @DebtToIncomeRatio = ((@ExistingDebt + @RequestedAmount) / @AnnualIncome) * 100;
        
        -- Calculate risk score based on credit score and DTI (0-100, lower is better) (Requirement 3.2)
        -- Credit score component
        DECLARE @CreditScoreComponent INT;
        SET @CreditScoreComponent = 
            CASE 
                WHEN @CreditScore >= 750 THEN 10
                WHEN @CreditScore >= 700 THEN 20
                WHEN @CreditScore >= 650 THEN 35
                WHEN @CreditScore >= 600 THEN 50
                ELSE 75
            END;
        
        -- DTI component
        DECLARE @DTIComponent INT;
        SET @DTIComponent = 
            CASE 
                WHEN @DebtToIncomeRatio <= 20 THEN 0
                WHEN @DebtToIncomeRatio <= 35 THEN 10
                WHEN @DebtToIncomeRatio <= 43 THEN 20
                ELSE 30
            END;
        
        -- Total risk score
        SET @RiskScore = @CreditScoreComponent + @DTIComponent;
        
        -- Select appropriate interest rate from InterestRates table (Requirement 3.4)
        SELECT TOP 1 @InterestRate = [Rate]
        FROM [dbo].[InterestRates]
        WHERE [LoanType] = @LoanType
          AND @CreditScore BETWEEN [MinCreditScore] AND [MaxCreditScore]
          AND @TermMonths BETWEEN [MinTermMonths] AND [MaxTermMonths]
          AND [EffectiveDate] <= GETDATE()
          AND ([ExpirationDate] IS NULL OR [ExpirationDate] >= GETDATE())
        ORDER BY [EffectiveDate] DESC;
        
        -- If no rate found, use default rate (Requirement 3.4)
        IF @InterestRate IS NULL
        BEGIN
            SET @InterestRate = 12.99; -- Default rate
        END
        
        -- Update application status to 'UnderReview' (Requirement 3.5)
        UPDATE [dbo].[LoanApplications]
        SET [Status] = 'UnderReview',
            [InterestRate] = @InterestRate
        WHERE [ApplicationId] = @ApplicationId;
        
        -- Return evaluation results (risk score, DTI, rate, recommendation) (Requirement 3.5)
        SELECT @ApplicationId AS ApplicationId,
               @RiskScore AS RiskScore,
               @DebtToIncomeRatio AS DebtToIncomeRatio,
               @InterestRate AS InterestRate,
               @CreditScore AS CreditScore,
               @ExistingDebt AS ExistingDebt,
               @RequestedAmount AS RequestedAmount,
               @AnnualIncome AS AnnualIncome,
               CASE 
                   WHEN @RiskScore <= 30 AND @DebtToIncomeRatio <= 35 THEN 'Recommended for Approval'
                   WHEN @RiskScore <= 50 AND @DebtToIncomeRatio <= 43 THEN 'Manual Review Required'
                   ELSE 'High Risk - Recommend Rejection'
               END AS Recommendation;
        
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        -- Re-throw the error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -99;
    END CATCH
END
GO
