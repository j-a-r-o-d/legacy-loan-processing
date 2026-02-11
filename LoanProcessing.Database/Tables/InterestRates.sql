-- InterestRates table definition
-- Stores interest rate tables for different loan types and credit score ranges
-- Requirements: 10.1, 10.2, 10.4

CREATE TABLE [dbo].[InterestRates] (
    [RateId] INT PRIMARY KEY IDENTITY(1,1),
    [LoanType] NVARCHAR(20) NOT NULL,
    [MinCreditScore] INT NOT NULL,
    [MaxCreditScore] INT NOT NULL,
    [MinTermMonths] INT NOT NULL,
    [MaxTermMonths] INT NOT NULL,
    [Rate] DECIMAL(5,2) NOT NULL,
    [EffectiveDate] DATE NOT NULL,
    [ExpirationDate] DATE NULL,
    
    -- Constraints
    CONSTRAINT [CK_InterestRates_CreditScore] CHECK ([MinCreditScore] <= [MaxCreditScore]),
    CONSTRAINT [CK_InterestRates_Term] CHECK ([MinTermMonths] <= [MaxTermMonths]),
    CONSTRAINT [CK_InterestRates_Rate] CHECK ([Rate] > 0)
);
GO

-- Indexes for performance
CREATE INDEX [IX_InterestRates_Lookup] ON [dbo].[InterestRates]([LoanType], [MinCreditScore], [MaxCreditScore], [EffectiveDate]);
GO
