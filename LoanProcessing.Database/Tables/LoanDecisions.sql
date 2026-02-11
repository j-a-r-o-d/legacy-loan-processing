-- LoanDecisions table definition
-- Stores loan decision information including approval/rejection details
-- Requirements: 10.1, 10.2, 10.4

CREATE TABLE [dbo].[LoanDecisions] (
    [DecisionId] INT PRIMARY KEY IDENTITY(1,1),
    [ApplicationId] INT NOT NULL,
    [Decision] NVARCHAR(20) NOT NULL,
    [DecisionBy] NVARCHAR(100) NOT NULL,
    [DecisionDate] DATETIME NOT NULL DEFAULT GETDATE(),
    [Comments] NVARCHAR(1000) NULL,
    [ApprovedAmount] DECIMAL(18,2) NULL,
    [InterestRate] DECIMAL(5,2) NULL,
    [RiskScore] INT NULL,
    [DebtToIncomeRatio] DECIMAL(5,2) NULL,
    
    -- Constraints
    CONSTRAINT [FK_LoanDecisions_Applications] FOREIGN KEY ([ApplicationId]) 
        REFERENCES [dbo].[LoanApplications]([ApplicationId]),
    CONSTRAINT [CK_LoanDecisions_Decision] CHECK ([Decision] IN ('Approved', 'Rejected')),
    CONSTRAINT [CK_LoanDecisions_RiskScore] CHECK ([RiskScore] IS NULL OR [RiskScore] BETWEEN 0 AND 100)
);
GO

-- Indexes for performance
CREATE INDEX [IX_LoanDecisions_Application] ON [dbo].[LoanDecisions]([ApplicationId]);
GO
