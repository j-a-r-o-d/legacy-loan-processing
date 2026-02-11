-- LoanApplications table definition
-- Stores loan application information
-- Requirements: 10.1, 10.2, 10.4

CREATE TABLE [dbo].[LoanApplications] (
    [ApplicationId] INT PRIMARY KEY IDENTITY(1,1),
    [ApplicationNumber] NVARCHAR(20) NOT NULL,
    [CustomerId] INT NOT NULL,
    [LoanType] NVARCHAR(20) NOT NULL,
    [RequestedAmount] DECIMAL(18,2) NOT NULL,
    [TermMonths] INT NOT NULL,
    [Purpose] NVARCHAR(500) NOT NULL,
    [Status] NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    [ApplicationDate] DATETIME NOT NULL DEFAULT GETDATE(),
    [ApprovedAmount] DECIMAL(18,2) NULL,
    [InterestRate] DECIMAL(5,2) NULL,
    
    -- Constraints
    CONSTRAINT [UQ_LoanApplications_ApplicationNumber] UNIQUE ([ApplicationNumber]),
    CONSTRAINT [FK_LoanApplications_Customers] FOREIGN KEY ([CustomerId]) 
        REFERENCES [dbo].[Customers]([CustomerId]),
    CONSTRAINT [CK_LoanApplications_LoanType] CHECK ([LoanType] IN ('Personal', 'Auto', 'Mortgage', 'Business')),
    CONSTRAINT [CK_LoanApplications_Status] CHECK ([Status] IN ('Pending', 'UnderReview', 'Approved', 'Rejected')),
    CONSTRAINT [CK_LoanApplications_Amount] CHECK ([RequestedAmount] > 0),
    CONSTRAINT [CK_LoanApplications_Term] CHECK ([TermMonths] > 0)
);
GO

-- Indexes for performance
CREATE INDEX [IX_LoanApplications_Customer] ON [dbo].[LoanApplications]([CustomerId]);
GO

CREATE INDEX [IX_LoanApplications_Status] ON [dbo].[LoanApplications]([Status]);
GO

CREATE INDEX [IX_LoanApplications_Date] ON [dbo].[LoanApplications]([ApplicationDate]);
GO
