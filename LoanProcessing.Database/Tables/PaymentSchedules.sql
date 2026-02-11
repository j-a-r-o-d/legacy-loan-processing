-- PaymentSchedules table definition
-- Stores payment schedule details for approved loans
-- Requirements: 10.1, 10.2, 10.4

CREATE TABLE [dbo].[PaymentSchedules] (
    [ScheduleId] INT PRIMARY KEY IDENTITY(1,1),
    [ApplicationId] INT NOT NULL,
    [PaymentNumber] INT NOT NULL,
    [DueDate] DATE NOT NULL,
    [PaymentAmount] DECIMAL(18,2) NOT NULL,
    [PrincipalAmount] DECIMAL(18,2) NOT NULL,
    [InterestAmount] DECIMAL(18,2) NOT NULL,
    [RemainingBalance] DECIMAL(18,2) NOT NULL,
    
    -- Constraints
    CONSTRAINT [FK_PaymentSchedules_Applications] FOREIGN KEY ([ApplicationId]) 
        REFERENCES [dbo].[LoanApplications]([ApplicationId]),
    CONSTRAINT [UQ_PaymentSchedule] UNIQUE ([ApplicationId], [PaymentNumber])
);
GO

-- Indexes for performance
CREATE INDEX [IX_PaymentSchedules_Application] ON [dbo].[PaymentSchedules]([ApplicationId]);
GO
