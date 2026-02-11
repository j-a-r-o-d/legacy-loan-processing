-- =============================================
-- Stored Procedure: sp_CalculatePaymentSchedule
-- Description: Calculates and generates an amortization payment schedule for an approved loan
-- Requirements: 4.2, 5.1, 5.2, 5.3, 5.4
-- =============================================
CREATE PROCEDURE sp_CalculatePaymentSchedule
    @ApplicationId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @LoanAmount DECIMAL(18,2), @InterestRate DECIMAL(5,2);
        DECLARE @TermMonths INT, @MonthlyRate DECIMAL(10,8);
        DECLARE @MonthlyPayment DECIMAL(18,2), @RemainingBalance DECIMAL(18,2);
        DECLARE @PaymentNumber INT, @InterestAmount DECIMAL(18,2);
        DECLARE @PrincipalAmount DECIMAL(18,2), @DueDate DATE;
        
        -- Get loan details
        SELECT @LoanAmount = ApprovedAmount,
               @InterestRate = InterestRate,
               @TermMonths = TermMonths
        FROM LoanApplications
        WHERE ApplicationId = @ApplicationId;
        
        -- Calculate monthly interest rate from annual rate
        SET @MonthlyRate = @InterestRate / 100 / 12;
        
        -- Calculate monthly payment using amortization formula
        -- P = L[c(1 + c)^n]/[(1 + c)^n - 1]
        -- Where: P = monthly payment, L = loan amount, c = monthly rate, n = number of payments
        SET @MonthlyPayment = @LoanAmount * 
            (@MonthlyRate * POWER(1 + @MonthlyRate, @TermMonths)) /
            (POWER(1 + @MonthlyRate, @TermMonths) - 1);
        
        -- Round to 2 decimal places
        SET @MonthlyPayment = ROUND(@MonthlyPayment, 2);
        
        -- Initialize variables
        SET @RemainingBalance = @LoanAmount;
        SET @PaymentNumber = 1;
        SET @DueDate = DATEADD(MONTH, 1, GETDATE());
        
        -- Delete existing schedule before inserting new one
        DELETE FROM PaymentSchedules WHERE ApplicationId = @ApplicationId;
        
        -- Generate payment schedule with payment number, due date, and amounts
        WHILE @PaymentNumber <= @TermMonths
        BEGIN
            -- Calculate interest for this payment period
            SET @InterestAmount = ROUND(@RemainingBalance * @MonthlyRate, 2);
            
            -- Calculate principal for this payment period
            SET @PrincipalAmount = @MonthlyPayment - @InterestAmount;
            
            -- Adjust final payment to zero out remaining balance
            IF @PaymentNumber = @TermMonths
            BEGIN
                SET @PrincipalAmount = @RemainingBalance;
                SET @MonthlyPayment = @PrincipalAmount + @InterestAmount;
            END
            
            -- Update remaining balance
            SET @RemainingBalance = @RemainingBalance - @PrincipalAmount;
            
            -- Insert payment record
            INSERT INTO PaymentSchedules (ApplicationId, PaymentNumber, DueDate,
                                         PaymentAmount, PrincipalAmount, 
                                         InterestAmount, RemainingBalance)
            VALUES (@ApplicationId, @PaymentNumber, @DueDate,
                    @MonthlyPayment, @PrincipalAmount,
                    @InterestAmount, @RemainingBalance);
            
            -- Move to next payment
            SET @PaymentNumber = @PaymentNumber + 1;
            SET @DueDate = DATEADD(MONTH, 1, @DueDate);
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
