-- ============================================================================
-- Stored Procedure: sp_SubmitLoanApplication
-- Description: Submits a new loan application with validation
-- Requirements: 2.1, 2.2, 2.5
-- ============================================================================

CREATE PROCEDURE [dbo].[sp_SubmitLoanApplication]
    @CustomerId INT,
    @LoanType NVARCHAR(20),
    @RequestedAmount DECIMAL(18,2),
    @TermMonths INT,
    @Purpose NVARCHAR(500),
    @ApplicationId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validation: Check if customer exists (Requirement 2.1)
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Customers] WHERE [CustomerId] = @CustomerId)
        BEGIN
            RAISERROR('Customer not found.', 16, 1);
            RETURN -1;
        END
        
        -- Validation: Check loan amount limits by type (Requirement 2.2)
        DECLARE @MaxAmount DECIMAL(18,2);
        SET @MaxAmount = CASE @LoanType
            WHEN 'Personal' THEN 50000
            WHEN 'Auto' THEN 75000
            WHEN 'Mortgage' THEN 500000
            WHEN 'Business' THEN 250000
            ELSE 0
        END;
        
        IF @MaxAmount = 0
        BEGIN
            RAISERROR('Invalid loan type. Must be Personal, Auto, Mortgage, or Business.', 16, 1);
            RETURN -2;
        END
        
        IF @RequestedAmount > @MaxAmount
        BEGIN
            RAISERROR('Requested amount exceeds maximum for loan type.', 16, 1);
            RETURN -3;
        END
        
        IF @RequestedAmount <= 0
        BEGIN
            RAISERROR('Requested amount must be greater than zero.', 16, 1);
            RETURN -4;
        END
        
        -- Validation: Check term limits (12 to 360 months)
        IF @TermMonths < 12 OR @TermMonths > 360
        BEGIN
            RAISERROR('Loan term must be between 12 and 360 months.', 16, 1);
            RETURN -5;
        END
        
        -- Generate unique application number using sequence (Requirement 2.5)
        DECLARE @SeqNumber INT;
        SET @SeqNumber = NEXT VALUE FOR [dbo].[ApplicationNumberSeq];
        
        DECLARE @AppNumber NVARCHAR(20);
        SET @AppNumber = 'LN' + FORMAT(GETDATE(), 'yyyyMMdd') + 
                        RIGHT('00000' + CAST(@SeqNumber AS NVARCHAR), 5);
        
        -- Insert loan application with status 'Pending' (Requirement 2.5)
        INSERT INTO [dbo].[LoanApplications] (
            [ApplicationNumber],
            [CustomerId],
            [LoanType],
            [RequestedAmount],
            [TermMonths],
            [Purpose],
            [Status],
            [ApplicationDate]
        )
        VALUES (
            @AppNumber,
            @CustomerId,
            @LoanType,
            @RequestedAmount,
            @TermMonths,
            @Purpose,
            'Pending',
            GETDATE()
        );
        
        -- Return the new ApplicationId (Requirement 2.5)
        SET @ApplicationId = SCOPE_IDENTITY();
        
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
