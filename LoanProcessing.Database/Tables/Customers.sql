-- Customers table definition
-- Stores customer information for loan processing
-- Requirements: 10.1, 10.2, 10.4

CREATE TABLE [dbo].[Customers] (
    [CustomerId] INT PRIMARY KEY IDENTITY(1,1),
    [FirstName] NVARCHAR(50) NOT NULL,
    [LastName] NVARCHAR(50) NOT NULL,
    [SSN] NVARCHAR(11) NOT NULL,
    [DateOfBirth] DATE NOT NULL,
    [AnnualIncome] DECIMAL(18,2) NOT NULL,
    [CreditScore] INT NOT NULL,
    [Email] NVARCHAR(100) NOT NULL,
    [Phone] NVARCHAR(20) NOT NULL,
    [Address] NVARCHAR(200) NOT NULL,
    [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] DATETIME NULL,
    
    -- Constraints
    CONSTRAINT [UQ_Customers_SSN] UNIQUE ([SSN]),
    CONSTRAINT [CK_Customers_CreditScore] CHECK ([CreditScore] BETWEEN 300 AND 850),
    CONSTRAINT [CK_Customers_Income] CHECK ([AnnualIncome] >= 0)
);
GO

-- Indexes for performance
CREATE INDEX [IX_Customers_SSN] ON [dbo].[Customers]([SSN]);
GO

CREATE INDEX [IX_Customers_CreditScore] ON [dbo].[Customers]([CreditScore]);
GO
