-- Manual database creation script for Task 2.1
-- This script creates the LoanProcessing database and all tables with constraints
-- Run this script if you need to manually set up the database

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'LoanProcessing')
BEGIN
    CREATE DATABASE LoanProcessing;
    PRINT 'Database LoanProcessing created successfully';
END
ELSE
BEGIN
    PRINT 'Database LoanProcessing already exists';
END
GO

USE LoanProcessing;
GO

PRINT 'Creating database schema...';
PRINT '';

-- Create Customers table
IF OBJECT_ID('dbo.Customers', 'U') IS NULL
BEGIN
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
        
        CONSTRAINT [UQ_Customers_SSN] UNIQUE ([SSN]),
        CONSTRAINT [CK_Customers_CreditScore] CHECK ([CreditScore] BETWEEN 300 AND 850),
        CONSTRAINT [CK_Customers_Income] CHECK ([AnnualIncome] >= 0)
    );
    
    CREATE INDEX [IX_Customers_SSN] ON [dbo].[Customers]([SSN]);
    CREATE INDEX [IX_Customers_CreditScore] ON [dbo].[Customers]([CreditScore]);
    
    PRINT '✓ Customers table created';
END
ELSE
    PRINT '- Customers table already exists';
GO

-- Create ApplicationNumberSeq sequence
IF OBJECT_ID('dbo.ApplicationNumberSeq', 'SO') IS NULL
BEGIN
    CREATE SEQUENCE [dbo].[ApplicationNumberSeq]
        AS INT
        START WITH 1
        INCREMENT BY 1
        MINVALUE 1
        MAXVALUE 99999
        CYCLE
        CACHE 10;
    
    PRINT '✓ ApplicationNumberSeq sequence created';
END
ELSE
    PRINT '- ApplicationNumberSeq sequence already exists';
GO

-- Create LoanApplications table
IF OBJECT_ID('dbo.LoanApplications', 'U') IS NULL
BEGIN
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
        
        CONSTRAINT [UQ_LoanApplications_ApplicationNumber] UNIQUE ([ApplicationNumber]),
        CONSTRAINT [FK_LoanApplications_Customers] FOREIGN KEY ([CustomerId]) 
            REFERENCES [dbo].[Customers]([CustomerId]),
        CONSTRAINT [CK_LoanApplications_LoanType] CHECK ([LoanType] IN ('Personal', 'Auto', 'Mortgage', 'Business')),
        CONSTRAINT [CK_LoanApplications_Status] CHECK ([Status] IN ('Pending', 'UnderReview', 'Approved', 'Rejected')),
        CONSTRAINT [CK_LoanApplications_Amount] CHECK ([RequestedAmount] > 0),
        CONSTRAINT [CK_LoanApplications_Term] CHECK ([TermMonths] > 0)
    );
    
    CREATE INDEX [IX_LoanApplications_Customer] ON [dbo].[LoanApplications]([CustomerId]);
    CREATE INDEX [IX_LoanApplications_Status] ON [dbo].[LoanApplications]([Status]);
    CREATE INDEX [IX_LoanApplications_Date] ON [dbo].[LoanApplications]([ApplicationDate]);
    
    PRINT '✓ LoanApplications table created';
END
ELSE
    PRINT '- LoanApplications table already exists';
GO

-- Create LoanDecisions table
IF OBJECT_ID('dbo.LoanDecisions', 'U') IS NULL
BEGIN
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
        
        CONSTRAINT [FK_LoanDecisions_Applications] FOREIGN KEY ([ApplicationId]) 
            REFERENCES [dbo].[LoanApplications]([ApplicationId]),
        CONSTRAINT [CK_LoanDecisions_Decision] CHECK ([Decision] IN ('Approved', 'Rejected')),
        CONSTRAINT [CK_LoanDecisions_RiskScore] CHECK ([RiskScore] IS NULL OR [RiskScore] BETWEEN 0 AND 100)
    );
    
    CREATE INDEX [IX_LoanDecisions_Application] ON [dbo].[LoanDecisions]([ApplicationId]);
    
    PRINT '✓ LoanDecisions table created';
END
ELSE
    PRINT '- LoanDecisions table already exists';
GO

-- Create PaymentSchedules table
IF OBJECT_ID('dbo.PaymentSchedules', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[PaymentSchedules] (
        [ScheduleId] INT PRIMARY KEY IDENTITY(1,1),
        [ApplicationId] INT NOT NULL,
        [PaymentNumber] INT NOT NULL,
        [DueDate] DATE NOT NULL,
        [PaymentAmount] DECIMAL(18,2) NOT NULL,
        [PrincipalAmount] DECIMAL(18,2) NOT NULL,
        [InterestAmount] DECIMAL(18,2) NOT NULL,
        [RemainingBalance] DECIMAL(18,2) NOT NULL,
        
        CONSTRAINT [FK_PaymentSchedules_Applications] FOREIGN KEY ([ApplicationId]) 
            REFERENCES [dbo].[LoanApplications]([ApplicationId]),
        CONSTRAINT [UQ_PaymentSchedule] UNIQUE ([ApplicationId], [PaymentNumber])
    );
    
    CREATE INDEX [IX_PaymentSchedules_Application] ON [dbo].[PaymentSchedules]([ApplicationId]);
    
    PRINT '✓ PaymentSchedules table created';
END
ELSE
    PRINT '- PaymentSchedules table already exists';
GO

-- Create InterestRates table
IF OBJECT_ID('dbo.InterestRates', 'U') IS NULL
BEGIN
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
        
        CONSTRAINT [CK_InterestRates_CreditScore] CHECK ([MinCreditScore] <= [MaxCreditScore]),
        CONSTRAINT [CK_InterestRates_Term] CHECK ([MinTermMonths] <= [MaxTermMonths]),
        CONSTRAINT [CK_InterestRates_Rate] CHECK ([Rate] > 0)
    );
    
    CREATE INDEX [IX_InterestRates_Lookup] ON [dbo].[InterestRates]([LoanType], [MinCreditScore], [MaxCreditScore], [EffectiveDate]);
    
    PRINT '✓ InterestRates table created';
END
ELSE
    PRINT '- InterestRates table already exists';
GO

PRINT '';
PRINT 'Database schema creation complete!';
PRINT 'Run VerifyTables.sql to verify all tables and constraints.';
