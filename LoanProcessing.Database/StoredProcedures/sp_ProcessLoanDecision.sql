-- ============================================================================
-- Stored Procedure: sp_ProcessLoanDecision
-- Description: Processes loan approval or rejection decision
-- Requirements: 4.1, 4.3, 4.5
-- ============================================================================

CREATE PROCEDURE [dbo].[sp_ProcessLoanDecision]
    @ApplicationId INT,
    @Decision NVARCHAR(20),
    @DecisionBy NVARCHAR(100),
    @Comments NVARCHAR(1000) = NULL,
    @ApprovedAmount DECIMAL(18,2) = NULL,
    @RiskScore INT = NULL,
    @DebtToIncomeRatio DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @RequestedAmount DECIMAL(18,2), @InterestRate DECIMAL(5,2);
        DECLARE @TermMonths INT;
        
        -- Validation: Check if application exists (Requirement 4.1)
        IF NOT EXISTS (SELECT 1 FROM [dbo].[LoanApplications] WHERE [ApplicationId] = @ApplicationId)
        BEGIN
            RAISERROR('Loan application not found.', 16, 1);
            RETURN -1;
        END
        
        -- Get application details (Requirement 4.1)
        SELECT @RequestedAmount = [RequestedAmount],
               @InterestRate = [InterestRate],
               @TermMonths = [TermMonths]
        FROM [dbo].[LoanApplications]
        WHERE [ApplicationId] = @ApplicationId;
        
        -- Get evaluation results if they were not provided and exist from previous evaluation
        -- This retrieves RiskScore and DebtToIncomeRatio from the most recent evaluation
        IF @RiskScore IS NULL OR @DebtToIncomeRatio IS NULL
        BEGIN
            SELECT TOP 1 
                @RiskScore = ISNULL(@RiskScore, [RiskScore]),
                @DebtToIncomeRatio = ISNULL(@DebtToIncomeRatio, [DebtToIncomeRatio])
            FROM [dbo].[LoanDecisions]
            WHERE [ApplicationId] = @ApplicationId
            ORDER BY [DecisionDate] DESC;
        END
        
        -- Validation: If approved, set amount to requested if not specified (Requirement 4.1)
        IF @Decision = 'Approved' AND @ApprovedAmount IS NULL
        BEGIN
            SET @ApprovedAmount = @RequestedAmount;
        END
        
        -- Validation: Approved amount cannot exceed requested amount (Requirement 4.1)
        IF @Decision = 'Approved' AND @ApprovedAmount > @RequestedAmount
        BEGIN
            RAISERROR('Approved amount cannot exceed requested amount.', 16, 1);
            RETURN -2;
        END
        
        -- Validation: Approved amount must be positive
        IF @Decision = 'Approved' AND @ApprovedAmount <= 0
        BEGIN
            RAISERROR('Approved amount must be greater than zero.', 16, 1);
            RETURN -3;
        END
        
        -- Insert decision record with all evaluation data (Requirement 4.1)
        INSERT INTO [dbo].[LoanDecisions] (
            [ApplicationId],
            [Decision],
            [DecisionBy],
            [DecisionDate],
            [Comments],
            [ApprovedAmount],
            [InterestRate],
            [RiskScore],
            [DebtToIncomeRatio]
        )
        VALUES (
            @ApplicationId,
            @Decision,
            @DecisionBy,
            GETDATE(),
            @Comments,
            @ApprovedAmount,
            @InterestRate,
            @RiskScore,
            @DebtToIncomeRatio
        );
        
        -- Update application status to 'Approved' or 'Rejected' (Requirement 4.3)
        UPDATE [dbo].[LoanApplications]
        SET [Status] = @Decision,
            [ApprovedAmount] = @ApprovedAmount
        WHERE [ApplicationId] = @ApplicationId;
        
        -- If approved, call sp_CalculatePaymentSchedule (Requirement 4.5)
        IF @Decision = 'Approved'
        BEGIN
            -- Note: sp_CalculatePaymentSchedule will be created in task 6.3
            -- For now, we check if it exists before calling
            IF OBJECT_ID('[dbo].[sp_CalculatePaymentSchedule]', 'P') IS NOT NULL
            BEGIN
                EXEC [dbo].[sp_CalculatePaymentSchedule] @ApplicationId;
            END
        END
        
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

