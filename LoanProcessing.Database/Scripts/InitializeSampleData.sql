-- Sample Data Initialization Script for Task 2.3
-- This script inserts sample data for testing and demonstration purposes
-- Requirements: 10.5

USE LoanProcessing;
GO

PRINT 'Initializing sample data...';
PRINT '';

-- Clear existing sample data (in reverse order of dependencies)
PRINT 'Clearing existing sample data...';
DELETE FROM [dbo].[PaymentSchedules];
DELETE FROM [dbo].[LoanDecisions];
DELETE FROM [dbo].[LoanApplications];
DELETE FROM [dbo].[InterestRates];
DELETE FROM [dbo].[Customers];

-- Reset identity seeds
DBCC CHECKIDENT ('Customers', RESEED, 0);
DBCC CHECKIDENT ('LoanApplications', RESEED, 0);
DBCC CHECKIDENT ('LoanDecisions', RESEED, 0);
DBCC CHECKIDENT ('PaymentSchedules', RESEED, 0);
DBCC CHECKIDENT ('InterestRates', RESEED, 0);

PRINT '✓ Existing data cleared';
PRINT '';

-- ============================================================================
-- Insert Sample Customers with varying credit scores and incomes
-- ============================================================================
PRINT 'Inserting sample customers...';

INSERT INTO [dbo].[Customers] 
    ([FirstName], [LastName], [SSN], [DateOfBirth], [AnnualIncome], [CreditScore], [Email], [Phone], [Address], [CreatedDate])
VALUES
    -- Excellent Credit (750-850)
    ('John', 'Smith', '123-45-6789', '1985-03-15', 95000.00, 820, 'john.smith@email.com', '555-0101', '123 Main St, Seattle, WA 98101', GETDATE()),
    ('Sarah', 'Johnson', '234-56-7890', '1990-07-22', 125000.00, 780, 'sarah.johnson@email.com', '555-0102', '456 Oak Ave, Portland, OR 97201', GETDATE()),
    ('Michael', 'Williams', '345-67-8901', '1982-11-08', 110000.00, 795, 'michael.williams@email.com', '555-0103', '789 Pine Rd, San Francisco, CA 94102', GETDATE()),
    
    -- Good Credit (700-749)
    ('Emily', 'Brown', '456-78-9012', '1988-05-30', 75000.00, 735, 'emily.brown@email.com', '555-0104', '321 Elm St, Austin, TX 78701', GETDATE()),
    ('David', 'Jones', '567-89-0123', '1992-09-14', 68000.00, 715, 'david.jones@email.com', '555-0105', '654 Maple Dr, Denver, CO 80201', GETDATE()),
    ('Jennifer', 'Garcia', '678-90-1234', '1987-12-03', 82000.00, 728, 'jennifer.garcia@email.com', '555-0106', '987 Cedar Ln, Phoenix, AZ 85001', GETDATE()),
    
    -- Fair Credit (650-699)
    ('Robert', 'Martinez', '789-01-2345', '1991-02-18', 55000.00, 680, 'robert.martinez@email.com', '555-0107', '147 Birch Ct, Las Vegas, NV 89101', GETDATE()),
    ('Lisa', 'Rodriguez', '890-12-3456', '1986-08-25', 62000.00, 665, 'lisa.rodriguez@email.com', '555-0108', '258 Spruce Way, Miami, FL 33101', GETDATE()),
    ('James', 'Wilson', '901-23-4567', '1989-04-12', 58000.00, 692, 'james.wilson@email.com', '555-0109', '369 Willow Pl, Boston, MA 02101', GETDATE()),
    
    -- Poor Credit (600-649)
    ('Mary', 'Anderson', '012-34-5678', '1993-10-07', 45000.00, 635, 'mary.anderson@email.com', '555-0110', '741 Ash Blvd, Chicago, IL 60601', GETDATE()),
    ('William', 'Thomas', '123-45-6780', '1984-06-19', 48000.00, 618, 'william.thomas@email.com', '555-0111', '852 Poplar St, Detroit, MI 48201', GETDATE()),
    
    -- Very Poor Credit (300-599)
    ('Patricia', 'Taylor', '234-56-7891', '1995-01-28', 38000.00, 580, 'patricia.taylor@email.com', '555-0112', '963 Hickory Ave, Atlanta, GA 30301', GETDATE()),
    ('Christopher', 'Moore', '345-67-8902', '1990-11-15', 42000.00, 545, 'christopher.moore@email.com', '555-0113', '159 Walnut Rd, Houston, TX 77001', GETDATE());

PRINT '✓ Inserted 13 sample customers with varying credit scores and incomes';
PRINT '';

-- ============================================================================
-- Insert Interest Rate Tables for all loan types and credit tiers
-- ============================================================================
PRINT 'Inserting interest rate tables...';

-- Personal Loans (12-84 months, up to $50,000)
INSERT INTO [dbo].[InterestRates] 
    ([LoanType], [MinCreditScore], [MaxCreditScore], [MinTermMonths], [MaxTermMonths], [Rate], [EffectiveDate], [ExpirationDate])
VALUES
    -- Excellent Credit
    ('Personal', 750, 850, 12, 36, 5.99, '2024-01-01', NULL),
    ('Personal', 750, 850, 37, 60, 6.49, '2024-01-01', NULL),
    ('Personal', 750, 850, 61, 84, 6.99, '2024-01-01', NULL),
    
    -- Good Credit
    ('Personal', 700, 749, 12, 36, 7.99, '2024-01-01', NULL),
    ('Personal', 700, 749, 37, 60, 8.49, '2024-01-01', NULL),
    ('Personal', 700, 749, 61, 84, 8.99, '2024-01-01', NULL),
    
    -- Fair Credit
    ('Personal', 650, 699, 12, 36, 10.99, '2024-01-01', NULL),
    ('Personal', 650, 699, 37, 60, 11.49, '2024-01-01', NULL),
    ('Personal', 650, 699, 61, 84, 11.99, '2024-01-01', NULL),
    
    -- Poor Credit
    ('Personal', 600, 649, 12, 36, 14.99, '2024-01-01', NULL),
    ('Personal', 600, 649, 37, 60, 15.49, '2024-01-01', NULL),
    ('Personal', 600, 649, 61, 84, 15.99, '2024-01-01', NULL),
    
    -- Very Poor Credit
    ('Personal', 300, 599, 12, 36, 19.99, '2024-01-01', NULL),
    ('Personal', 300, 599, 37, 60, 20.49, '2024-01-01', NULL),
    ('Personal', 300, 599, 61, 84, 20.99, '2024-01-01', NULL);

-- Auto Loans (24-84 months, up to $75,000)
INSERT INTO [dbo].[InterestRates] 
    ([LoanType], [MinCreditScore], [MaxCreditScore], [MinTermMonths], [MaxTermMonths], [Rate], [EffectiveDate], [ExpirationDate])
VALUES
    -- Excellent Credit
    ('Auto', 750, 850, 24, 48, 3.99, '2024-01-01', NULL),
    ('Auto', 750, 850, 49, 72, 4.49, '2024-01-01', NULL),
    ('Auto', 750, 850, 73, 84, 4.99, '2024-01-01', NULL),
    
    -- Good Credit
    ('Auto', 700, 749, 24, 48, 5.49, '2024-01-01', NULL),
    ('Auto', 700, 749, 49, 72, 5.99, '2024-01-01', NULL),
    ('Auto', 700, 749, 73, 84, 6.49, '2024-01-01', NULL),
    
    -- Fair Credit
    ('Auto', 650, 699, 24, 48, 7.99, '2024-01-01', NULL),
    ('Auto', 650, 699, 49, 72, 8.49, '2024-01-01', NULL),
    ('Auto', 650, 699, 73, 84, 8.99, '2024-01-01', NULL),
    
    -- Poor Credit
    ('Auto', 600, 649, 24, 48, 11.99, '2024-01-01', NULL),
    ('Auto', 600, 649, 49, 72, 12.49, '2024-01-01', NULL),
    ('Auto', 600, 649, 73, 84, 12.99, '2024-01-01', NULL),
    
    -- Very Poor Credit
    ('Auto', 300, 599, 24, 48, 16.99, '2024-01-01', NULL),
    ('Auto', 300, 599, 49, 72, 17.49, '2024-01-01', NULL),
    ('Auto', 300, 599, 73, 84, 17.99, '2024-01-01', NULL);

-- Mortgage Loans (120-360 months, up to $500,000)
INSERT INTO [dbo].[InterestRates] 
    ([LoanType], [MinCreditScore], [MaxCreditScore], [MinTermMonths], [MaxTermMonths], [Rate], [EffectiveDate], [ExpirationDate])
VALUES
    -- Excellent Credit
    ('Mortgage', 750, 850, 120, 180, 3.25, '2024-01-01', NULL),
    ('Mortgage', 750, 850, 181, 240, 3.50, '2024-01-01', NULL),
    ('Mortgage', 750, 850, 241, 360, 3.75, '2024-01-01', NULL),
    
    -- Good Credit
    ('Mortgage', 700, 749, 120, 180, 3.75, '2024-01-01', NULL),
    ('Mortgage', 700, 749, 181, 240, 4.00, '2024-01-01', NULL),
    ('Mortgage', 700, 749, 241, 360, 4.25, '2024-01-01', NULL),
    
    -- Fair Credit
    ('Mortgage', 650, 699, 120, 180, 4.50, '2024-01-01', NULL),
    ('Mortgage', 650, 699, 181, 240, 4.75, '2024-01-01', NULL),
    ('Mortgage', 650, 699, 241, 360, 5.00, '2024-01-01', NULL),
    
    -- Poor Credit
    ('Mortgage', 600, 649, 120, 180, 5.50, '2024-01-01', NULL),
    ('Mortgage', 600, 649, 181, 240, 5.75, '2024-01-01', NULL),
    ('Mortgage', 600, 649, 241, 360, 6.00, '2024-01-01', NULL),
    
    -- Very Poor Credit
    ('Mortgage', 300, 599, 120, 180, 7.00, '2024-01-01', NULL),
    ('Mortgage', 300, 599, 181, 240, 7.25, '2024-01-01', NULL),
    ('Mortgage', 300, 599, 241, 360, 7.50, '2024-01-01', NULL);

-- Business Loans (12-120 months, up to $250,000)
INSERT INTO [dbo].[InterestRates] 
    ([LoanType], [MinCreditScore], [MaxCreditScore], [MinTermMonths], [MaxTermMonths], [Rate], [EffectiveDate], [ExpirationDate])
VALUES
    -- Excellent Credit
    ('Business', 750, 850, 12, 36, 5.49, '2024-01-01', NULL),
    ('Business', 750, 850, 37, 60, 5.99, '2024-01-01', NULL),
    ('Business', 750, 850, 61, 120, 6.49, '2024-01-01', NULL),
    
    -- Good Credit
    ('Business', 700, 749, 12, 36, 7.49, '2024-01-01', NULL),
    ('Business', 700, 749, 37, 60, 7.99, '2024-01-01', NULL),
    ('Business', 700, 749, 61, 120, 8.49, '2024-01-01', NULL),
    
    -- Fair Credit
    ('Business', 650, 699, 12, 36, 9.99, '2024-01-01', NULL),
    ('Business', 650, 699, 37, 60, 10.49, '2024-01-01', NULL),
    ('Business', 650, 699, 61, 120, 10.99, '2024-01-01', NULL),
    
    -- Poor Credit
    ('Business', 600, 649, 12, 36, 13.99, '2024-01-01', NULL),
    ('Business', 600, 649, 37, 60, 14.49, '2024-01-01', NULL),
    ('Business', 600, 649, 61, 120, 14.99, '2024-01-01', NULL),
    
    -- Very Poor Credit
    ('Business', 300, 599, 12, 36, 18.99, '2024-01-01', NULL),
    ('Business', 300, 599, 37, 60, 19.49, '2024-01-01', NULL),
    ('Business', 300, 599, 61, 120, 19.99, '2024-01-01', NULL);

PRINT '✓ Inserted 60 interest rate records (4 loan types × 5 credit tiers × 3 term ranges)';
PRINT '';

-- ============================================================================
-- Insert Sample Loan Applications in various statuses
-- ============================================================================
PRINT 'Inserting sample loan applications...';

-- Reset the sequence to start from 1
ALTER SEQUENCE [dbo].[ApplicationNumberSeq] RESTART WITH 1;

-- Pending Applications
INSERT INTO [dbo].[LoanApplications] 
    ([ApplicationNumber], [CustomerId], [LoanType], [RequestedAmount], [TermMonths], [Purpose], [Status], [ApplicationDate], [ApprovedAmount], [InterestRate])
VALUES
    ('LN' + FORMAT(GETDATE(), 'yyyyMMdd') + '00001', 1, 'Personal', 15000.00, 36, 'Debt consolidation', 'Pending', DATEADD(DAY, -2, GETDATE()), NULL, NULL),
    ('LN' + FORMAT(GETDATE(), 'yyyyMMdd') + '00002', 4, 'Auto', 28000.00, 60, 'New car purchase', 'Pending', DATEADD(DAY, -1, GETDATE()), NULL, NULL),
    ('LN' + FORMAT(GETDATE(), 'yyyyMMdd') + '00003', 7, 'Personal', 8000.00, 24, 'Home improvement', 'Pending', GETDATE(), NULL, NULL);

-- Under Review Applications
INSERT INTO [dbo].[LoanApplications] 
    ([ApplicationNumber], [CustomerId], [LoanType], [RequestedAmount], [TermMonths], [Purpose], [Status], [ApplicationDate], [ApprovedAmount], [InterestRate])
VALUES
    ('LN' + FORMAT(GETDATE(), 'yyyyMMdd') + '00004', 2, 'Mortgage', 350000.00, 360, 'Primary residence purchase', 'UnderReview', DATEADD(DAY, -5, GETDATE()), NULL, 3.75),
    ('LN' + FORMAT(GETDATE(), 'yyyyMMdd') + '00005', 5, 'Business', 75000.00, 60, 'Equipment purchase', 'UnderReview', DATEADD(DAY, -4, GETDATE()), NULL, 7.99),
    ('LN' + FORMAT(GETDATE(), 'yyyyMMdd') + '00006', 8, 'Auto', 22000.00, 48, 'Used car purchase', 'UnderReview', DATEADD(DAY, -3, GETDATE()), NULL, 8.49);

-- Approved Applications
INSERT INTO [dbo].[LoanApplications] 
    ([ApplicationNumber], [CustomerId], [LoanType], [RequestedAmount], [TermMonths], [Purpose], [Status], [ApplicationDate], [ApprovedAmount], [InterestRate])
VALUES
    ('LN' + FORMAT(DATEADD(DAY, -30, GETDATE()), 'yyyyMMdd') + '00007', 1, 'Auto', 32000.00, 60, 'New car purchase', 'Approved', DATEADD(DAY, -30, GETDATE()), 32000.00, 4.49),
    ('LN' + FORMAT(DATEADD(DAY, -25, GETDATE()), 'yyyyMMdd') + '00008', 3, 'Personal', 20000.00, 48, 'Home renovation', 'Approved', DATEADD(DAY, -25, GETDATE()), 20000.00, 6.49),
    ('LN' + FORMAT(DATEADD(DAY, -20, GETDATE()), 'yyyyMMdd') + '00009', 6, 'Business', 50000.00, 48, 'Business expansion', 'Approved', DATEADD(DAY, -20, GETDATE()), 50000.00, 7.99),
    ('LN' + FORMAT(DATEADD(DAY, -15, GETDATE()), 'yyyyMMdd') + '00010', 2, 'Personal', 10000.00, 36, 'Medical expenses', 'Approved', DATEADD(DAY, -15, GETDATE()), 10000.00, 5.99),
    ('LN' + FORMAT(DATEADD(DAY, -10, GETDATE()), 'yyyyMMdd') + '00011', 9, 'Auto', 18000.00, 48, 'Used car purchase', 'Approved', DATEADD(DAY, -10, GETDATE()), 18000.00, 8.99);

-- Rejected Applications
INSERT INTO [dbo].[LoanApplications] 
    ([ApplicationNumber], [CustomerId], [LoanType], [RequestedAmount], [TermMonths], [Purpose], [Status], [ApplicationDate], [ApprovedAmount], [InterestRate])
VALUES
    ('LN' + FORMAT(DATEADD(DAY, -12, GETDATE()), 'yyyyMMdd') + '00012', 10, 'Mortgage', 280000.00, 360, 'Home purchase', 'Rejected', DATEADD(DAY, -12, GETDATE()), NULL, NULL),
    ('LN' + FORMAT(DATEADD(DAY, -8, GETDATE()), 'yyyyMMdd') + '00013', 12, 'Business', 100000.00, 60, 'Business startup', 'Rejected', DATEADD(DAY, -8, GETDATE()), NULL, NULL),
    ('LN' + FORMAT(DATEADD(DAY, -6, GETDATE()), 'yyyyMMdd') + '00014', 13, 'Personal', 25000.00, 48, 'Debt consolidation', 'Rejected', DATEADD(DAY, -6, GETDATE()), NULL, NULL);

PRINT '✓ Inserted 14 sample loan applications:';
PRINT '  - 3 Pending';
PRINT '  - 3 Under Review';
PRINT '  - 5 Approved';
PRINT '  - 3 Rejected';
PRINT '';

-- ============================================================================
-- Insert Sample Loan Decisions for approved and rejected applications
-- ============================================================================
PRINT 'Inserting sample loan decisions...';

-- Get the ApplicationId values for the approved and rejected applications
-- Since we reset identity, they will be sequential starting from 1
DECLARE @App7 INT = 7;  -- First approved application (Auto loan for John Smith)
DECLARE @App8 INT = 8;  -- Second approved application (Personal loan for Michael Williams)
DECLARE @App9 INT = 9;  -- Third approved application (Business loan for Jennifer Garcia)
DECLARE @App10 INT = 10; -- Fourth approved application (Personal loan for Sarah Johnson)
DECLARE @App11 INT = 11; -- Fifth approved application (Auto loan for James Wilson)
DECLARE @App12 INT = 12; -- First rejected application (Mortgage for Mary Anderson)
DECLARE @App13 INT = 13; -- Second rejected application (Business for Patricia Taylor)
DECLARE @App14 INT = 14; -- Third rejected application (Personal for Christopher Moore)

-- Decisions for Approved Applications
INSERT INTO [dbo].[LoanDecisions] 
    ([ApplicationId], [Decision], [DecisionBy], [DecisionDate], [Comments], [ApprovedAmount], [InterestRate], [RiskScore], [DebtToIncomeRatio])
VALUES
    (@App7, 'Approved', 'Jane Underwriter', DATEADD(DAY, -28, GETDATE()), 'Excellent credit history, stable income', 32000.00, 4.49, 15, 18.50),
    (@App8, 'Approved', 'John Underwriter', DATEADD(DAY, -23, GETDATE()), 'Strong credit profile, low debt-to-income ratio', 20000.00, 6.49, 12, 15.20),
    (@App9, 'Approved', 'Jane Underwriter', DATEADD(DAY, -18, GETDATE()), 'Good credit, established business', 50000.00, 7.99, 22, 28.30),
    (@App10, 'Approved', 'Mike Underwriter', DATEADD(DAY, -13, GETDATE()), 'Excellent credit, high income', 10000.00, 5.99, 8, 12.10),
    (@App11, 'Approved', 'Jane Underwriter', DATEADD(DAY, -8, GETDATE()), 'Acceptable credit, reasonable request', 18000.00, 8.99, 38, 32.50);

-- Decisions for Rejected Applications
INSERT INTO [dbo].[LoanDecisions] 
    ([ApplicationId], [Decision], [DecisionBy], [DecisionDate], [Comments], [ApprovedAmount], [InterestRate], [RiskScore], [DebtToIncomeRatio])
VALUES
    (@App12, 'Rejected', 'John Underwriter', DATEADD(DAY, -10, GETDATE()), 'Insufficient income for requested amount, high debt-to-income ratio', NULL, NULL, 68, 52.30),
    (@App13, 'Rejected', 'Mike Underwriter', DATEADD(DAY, -6, GETDATE()), 'Poor credit history, insufficient business documentation', NULL, NULL, 82, 48.70),
    (@App14, 'Rejected', 'Jane Underwriter', DATEADD(DAY, -4, GETDATE()), 'Very poor credit score, recent delinquencies', NULL, NULL, 88, 61.20);

PRINT '✓ Inserted 8 sample loan decisions:';
PRINT '  - 5 Approved';
PRINT '  - 3 Rejected';
PRINT '';

-- ============================================================================
-- Summary
-- ============================================================================
PRINT '========================================';
PRINT 'Sample Data Initialization Complete!';
PRINT '========================================';
PRINT '';
PRINT 'Summary:';
PRINT '  • 13 Customers (varying credit scores: 545-820)';
PRINT '  • 60 Interest Rate records (all loan types and credit tiers)';
PRINT '  • 14 Loan Applications (Pending: 3, Under Review: 3, Approved: 5, Rejected: 3)';
PRINT '  • 8 Loan Decisions (Approved: 5, Rejected: 3)';
PRINT '';
PRINT 'You can now test the application with this sample data.';
PRINT 'Use the stored procedures to process the pending applications.';
GO
