-- Verification script for Task 2.1
-- This script verifies that all tables and constraints have been created correctly

PRINT 'Verifying database schema for Task 2.1...'
PRINT ''

-- Check if Customers table exists
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL
    PRINT '✓ Customers table exists'
ELSE
    PRINT '✗ Customers table NOT found'

-- Check if LoanApplications table exists
IF OBJECT_ID('dbo.LoanApplications', 'U') IS NOT NULL
    PRINT '✓ LoanApplications table exists'
ELSE
    PRINT '✗ LoanApplications table NOT found'

-- Check if LoanDecisions table exists
IF OBJECT_ID('dbo.LoanDecisions', 'U') IS NOT NULL
    PRINT '✓ LoanDecisions table exists'
ELSE
    PRINT '✗ LoanDecisions table NOT found'

-- Check if PaymentSchedules table exists
IF OBJECT_ID('dbo.PaymentSchedules', 'U') IS NOT NULL
    PRINT '✓ PaymentSchedules table exists'
ELSE
    PRINT '✗ PaymentSchedules table NOT found'

-- Check if InterestRates table exists
IF OBJECT_ID('dbo.InterestRates', 'U') IS NOT NULL
    PRINT '✓ InterestRates table exists'
ELSE
    PRINT '✗ InterestRates table NOT found'

-- Check if ApplicationNumberSeq sequence exists
IF OBJECT_ID('dbo.ApplicationNumberSeq', 'SO') IS NOT NULL
    PRINT '✓ ApplicationNumberSeq sequence exists'
ELSE
    PRINT '✗ ApplicationNumberSeq sequence NOT found'

PRINT ''
PRINT 'Verifying constraints...'
PRINT ''

-- Check Customers constraints
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Customers_SSN' AND object_id = OBJECT_ID('dbo.Customers'))
    PRINT '✓ Customers SSN unique constraint exists'
ELSE
    PRINT '✗ Customers SSN unique constraint NOT found'

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Customers_CreditScore' AND parent_object_id = OBJECT_ID('dbo.Customers'))
    PRINT '✓ Customers credit score check constraint exists'
ELSE
    PRINT '✗ Customers credit score check constraint NOT found'

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Customers_Income' AND parent_object_id = OBJECT_ID('dbo.Customers'))
    PRINT '✓ Customers income check constraint exists'
ELSE
    PRINT '✗ Customers income check constraint NOT found'

-- Check LoanApplications constraints
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LoanApplications_Customers' AND parent_object_id = OBJECT_ID('dbo.LoanApplications'))
    PRINT '✓ LoanApplications foreign key to Customers exists'
ELSE
    PRINT '✗ LoanApplications foreign key to Customers NOT found'

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoanApplications_LoanType' AND parent_object_id = OBJECT_ID('dbo.LoanApplications'))
    PRINT '✓ LoanApplications loan type check constraint exists'
ELSE
    PRINT '✗ LoanApplications loan type check constraint NOT found'

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoanApplications_Status' AND parent_object_id = OBJECT_ID('dbo.LoanApplications'))
    PRINT '✓ LoanApplications status check constraint exists'
ELSE
    PRINT '✗ LoanApplications status check constraint NOT found'

-- Check LoanDecisions constraints
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LoanDecisions_Applications' AND parent_object_id = OBJECT_ID('dbo.LoanDecisions'))
    PRINT '✓ LoanDecisions foreign key to LoanApplications exists'
ELSE
    PRINT '✗ LoanDecisions foreign key to LoanApplications NOT found'

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_LoanDecisions_Decision' AND parent_object_id = OBJECT_ID('dbo.LoanDecisions'))
    PRINT '✓ LoanDecisions decision check constraint exists'
ELSE
    PRINT '✗ LoanDecisions decision check constraint NOT found'

-- Check PaymentSchedules constraints
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PaymentSchedules_Applications' AND parent_object_id = OBJECT_ID('dbo.PaymentSchedules'))
    PRINT '✓ PaymentSchedules foreign key to LoanApplications exists'
ELSE
    PRINT '✗ PaymentSchedules foreign key to LoanApplications NOT found'

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_PaymentSchedule' AND object_id = OBJECT_ID('dbo.PaymentSchedules'))
    PRINT '✓ PaymentSchedules composite unique constraint exists'
ELSE
    PRINT '✗ PaymentSchedules composite unique constraint NOT found'

-- Check InterestRates constraints
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_InterestRates_CreditScore' AND parent_object_id = OBJECT_ID('dbo.InterestRates'))
    PRINT '✓ InterestRates credit score check constraint exists'
ELSE
    PRINT '✗ InterestRates credit score check constraint NOT found'

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_InterestRates_Term' AND parent_object_id = OBJECT_ID('dbo.InterestRates'))
    PRINT '✓ InterestRates term check constraint exists'
ELSE
    PRINT '✗ InterestRates term check constraint NOT found'

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_InterestRates_Rate' AND parent_object_id = OBJECT_ID('dbo.InterestRates'))
    PRINT '✓ InterestRates rate validation constraint exists'
ELSE
    PRINT '✗ InterestRates rate validation constraint NOT found'

PRINT ''
PRINT 'Verification complete!'
