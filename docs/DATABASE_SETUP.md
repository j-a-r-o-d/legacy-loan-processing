# Database Setup Guide

## Overview

This guide provides detailed instructions for setting up the LoanProcessing database, including schema creation, stored procedures, and sample data initialization.

## Prerequisites

- SQL Server 2016+ or SQL Server LocalDB
- SQL Server Management Studio (SSMS) or sqlcmd command-line tool
- Appropriate permissions to create databases

## Database Architecture

### Tables

1. **Customers** - Customer information with credit scores and income
2. **LoanApplications** - Loan application details and status
3. **LoanDecisions** - Approval/rejection decisions with risk assessment
4. **PaymentSchedules** - Amortization schedules for approved loans
5. **InterestRates** - Rate tables by loan type and credit tier

### Stored Procedures

1. **sp_CreateCustomer** - Create new customer with validation
2. **sp_UpdateCustomer** - Update customer information
3. **sp_GetCustomerById** - Retrieve customer details
4. **sp_SearchCustomers** - Search customers by name or SSN
5. **sp_SubmitLoanApplication** - Submit new loan application
6. **sp_EvaluateCredit** - Perform credit evaluation and risk scoring
7. **sp_ProcessLoanDecision** - Record loan approval/rejection
8. **sp_CalculatePaymentSchedule** - Generate amortization schedule
9. **sp_GeneratePortfolioReport** - Generate portfolio analytics

## Setup Methods

### Method 1: Automated Setup (Recommended)

Run the complete setup script that creates database, schema, and sample data:

```powershell
# Navigate to database scripts directory
cd LoanProcessing.Database\Scripts

# For LocalDB (Development)
sqlcmd -S (localdb)\MSSQLLocalDB -E -i CreateDatabase.sql
sqlcmd -S (localdb)\MSSQLLocalDB -E -d LoanProcessing -i InitializeSampleData.sql

# For SQL Server (Production)
sqlcmd -S YOUR_SERVER_NAME -E -i CreateDatabase.sql
sqlcmd -S YOUR_SERVER_NAME -E -d LoanProcessing -i InitializeSampleData.sql
```

### Method 2: SQL Server Management Studio (SSMS)

1. Open SQL Server Management Studio
2. Connect to your SQL Server instance
3. Open `LoanProcessing.Database\Scripts\CreateDatabase.sql`
4. Execute the script (F5 or click Execute)
5. Refresh the Databases folder to see the new database
6. Open `LoanProcessing.Database\Scripts\InitializeSampleData.sql`
7. Ensure you're connected to the `LoanProcessing` database
8. Execute the script (F5)


### Method 3: Visual Studio Database Project

1. Open `LoanProcessing.sln` in Visual Studio
2. Right-click on `LoanProcessing.Database` project
3. Select **Publish...**
4. Click **Edit...** to configure connection
5. Enter server name: `(localdb)\MSSQLLocalDB` or your SQL Server instance
6. Enter database name: `LoanProcessing`
7. Test connection
8. Click **Publish**
9. Review publish results

## Verification Steps

### Step 1: Verify Database Creation

```sql
-- Check database exists
SELECT name, database_id, create_date 
FROM sys.databases 
WHERE name = 'LoanProcessing';

-- Check database size
EXEC sp_spaceused;
```

### Step 2: Verify Tables

```sql
USE LoanProcessing;
GO

-- List all tables
SELECT TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Expected output:
-- Customers
-- InterestRates
-- LoanApplications
-- LoanDecisions
-- PaymentSchedules

-- Check table row counts
SELECT 
    t.name AS TableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
ORDER BY t.name;
```

### Step 3: Verify Stored Procedures

```sql
-- List all stored procedures
SELECT 
    ROUTINE_NAME,
    CREATED,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
    AND ROUTINE_SCHEMA = 'dbo'
ORDER BY ROUTINE_NAME;

-- Expected procedures:
-- sp_CalculatePaymentSchedule
-- sp_CreateCustomer
-- sp_EvaluateCredit
-- sp_GeneratePortfolioReport
-- sp_GetCustomerById
-- sp_ProcessLoanDecision
-- sp_SearchCustomers
-- sp_SubmitLoanApplication
-- sp_UpdateCustomer
```

### Step 4: Verify Constraints and Indexes

```sql
-- Check foreign keys
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY TableName;

-- Check indexes
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes i
WHERE i.object_id IN (
    SELECT object_id FROM sys.tables WHERE type = 'U'
)
ORDER BY TableName, IndexName;
```


## Sample Data Overview

The `InitializeSampleData.sql` script populates the database with realistic test data:

### Customers (13 records)

| Credit Score Range | Count | Annual Income Range |
|-------------------|-------|---------------------|
| Excellent (750+)  | 3     | $80K - $150K       |
| Good (700-749)    | 3     | $60K - $100K       |
| Fair (650-699)    | 3     | $45K - $75K        |
| Poor (600-649)    | 2     | $35K - $50K        |
| Bad (<600)        | 2     | $30K - $40K        |

### Interest Rates (60 records)

Rate matrix covering:
- **Loan Types**: Personal, Auto, Mortgage, Business
- **Credit Tiers**: 5 tiers (750+, 700-749, 650-699, 600-649, <600)
- **Term Ranges**: Short (12-60), Medium (61-180), Long (181-360)

Sample rates:
- Personal loans: 5.99% - 18.99%
- Auto loans: 3.99% - 14.99%
- Mortgage loans: 3.50% - 9.99%
- Business loans: 6.50% - 19.99%

### Loan Applications (14 records)

| Status       | Count | Loan Types                    |
|-------------|-------|-------------------------------|
| Pending     | 4     | Personal, Auto, Mortgage      |
| UnderReview | 3     | Personal, Business            |
| Approved    | 5     | Personal, Auto, Mortgage      |
| Rejected    | 2     | Personal, Business            |

## Testing Stored Procedures

### Test Customer Creation

```sql
USE LoanProcessing;
GO

-- Test creating a new customer
DECLARE @CustomerId INT;

EXEC sp_CreateCustomer
    @FirstName = 'Test',
    @LastName = 'Customer',
    @SSN = '999-88-7777',
    @DateOfBirth = '1985-06-15',
    @AnnualIncome = 65000.00,
    @CreditScore = 720,
    @Email = 'test.customer@example.com',
    @Phone = '555-0123',
    @Address = '123 Test Street, Test City, TS 12345',
    @CustomerId = @CustomerId OUTPUT;

SELECT @CustomerId AS NewCustomerId;

-- Verify customer was created
SELECT * FROM Customers WHERE CustomerId = @CustomerId;

-- Clean up test data
DELETE FROM Customers WHERE SSN = '999-88-7777';
```

### Test Customer Search

```sql
-- Search by last name
EXEC sp_SearchCustomers @SearchTerm = 'Smith';

-- Search by SSN
EXEC sp_SearchCustomers @SearchTerm = '123-45-6789';

-- Search by partial name
EXEC sp_SearchCustomers @SearchTerm = 'John';
```

### Test Loan Application Submission

```sql
-- Submit a loan application
DECLARE @ApplicationId INT;

EXEC sp_SubmitLoanApplication
    @CustomerId = 1,
    @LoanType = 'Personal',
    @RequestedAmount = 15000.00,
    @TermMonths = 36,
    @Purpose = 'Debt consolidation',
    @ApplicationId = @ApplicationId OUTPUT;

SELECT @ApplicationId AS NewApplicationId;

-- View the application
SELECT * FROM LoanApplications WHERE ApplicationId = @ApplicationId;
```


### Test Credit Evaluation

```sql
-- Evaluate credit for an application
EXEC sp_EvaluateCredit @ApplicationId = 1;

-- View evaluation results
SELECT 
    la.ApplicationNumber,
    la.RequestedAmount,
    la.Status,
    la.InterestRate,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.CreditScore,
    c.AnnualIncome
FROM LoanApplications la
INNER JOIN Customers c ON la.CustomerId = c.CustomerId
WHERE la.ApplicationId = 1;
```

### Test Loan Decision Processing

```sql
-- Process an approval decision
EXEC sp_ProcessLoanDecision
    @ApplicationId = 1,
    @Decision = 'Approved',
    @DecisionBy = 'John Underwriter',
    @Comments = 'Strong credit profile, approved at requested amount',
    @ApprovedAmount = 15000.00;

-- View decision and payment schedule
SELECT * FROM LoanDecisions WHERE ApplicationId = 1;
SELECT * FROM PaymentSchedules WHERE ApplicationId = 1 ORDER BY PaymentNumber;
```

### Test Portfolio Report

```sql
-- Generate portfolio report for all loans
EXEC sp_GeneratePortfolioReport
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31',
    @LoanType = NULL;

-- Generate report for specific loan type
EXEC sp_GeneratePortfolioReport
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31',
    @LoanType = 'Personal';
```

## Common Issues and Solutions

### Issue: "Database already exists"

**Solution**: Drop and recreate the database

```sql
USE master;
GO

-- Close all connections
ALTER DATABASE LoanProcessing SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- Drop database
DROP DATABASE LoanProcessing;
GO

-- Now run CreateDatabase.sql again
```

### Issue: "Cannot drop database because it is currently in use"

**Solution**: Close all connections first

```sql
USE master;
GO

-- Kill all connections
DECLARE @kill varchar(8000) = '';
SELECT @kill = @kill + 'KILL ' + CONVERT(varchar(5), session_id) + ';'
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID('LoanProcessing');

EXEC(@kill);
GO

-- Now drop database
DROP DATABASE LoanProcessing;
GO
```

### Issue: "Stored procedure not found"

**Solution**: Verify stored procedures were created

```sql
-- Check if stored procedures exist
SELECT name FROM sys.procedures WHERE name LIKE 'sp_%';

-- If missing, run individual stored procedure scripts
-- Example:
-- :r LoanProcessing.Database\StoredProcedures\sp_CreateCustomer.sql
```

### Issue: "Foreign key constraint violation"

**Solution**: Ensure data is inserted in correct order

1. Customers (no dependencies)
2. InterestRates (no dependencies)
3. LoanApplications (depends on Customers)
4. LoanDecisions (depends on LoanApplications)
5. PaymentSchedules (depends on LoanApplications)


## Database Maintenance

### Backup Database

```sql
-- Full backup
BACKUP DATABASE LoanProcessing
TO DISK = 'C:\Backups\LoanProcessing_Full.bak'
WITH FORMAT, INIT, NAME = 'LoanProcessing Full Backup';

-- Differential backup
BACKUP DATABASE LoanProcessing
TO DISK = 'C:\Backups\LoanProcessing_Diff.bak'
WITH DIFFERENTIAL, NAME = 'LoanProcessing Differential Backup';
```

### Restore Database

```sql
-- Restore from backup
USE master;
GO

RESTORE DATABASE LoanProcessing
FROM DISK = 'C:\Backups\LoanProcessing_Full.bak'
WITH REPLACE, RECOVERY;
GO
```

### Update Statistics

```sql
USE LoanProcessing;
GO

-- Update statistics for all tables
EXEC sp_updatestats;

-- Update statistics for specific table
UPDATE STATISTICS Customers WITH FULLSCAN;
UPDATE STATISTICS LoanApplications WITH FULLSCAN;
```

### Rebuild Indexes

```sql
-- Rebuild all indexes
EXEC sp_MSforeachtable 'ALTER INDEX ALL ON ? REBUILD';

-- Rebuild indexes for specific table
ALTER INDEX ALL ON Customers REBUILD;
ALTER INDEX ALL ON LoanApplications REBUILD;
```

### Check Database Integrity

```sql
-- Check database consistency
DBCC CHECKDB (LoanProcessing) WITH NO_INFOMSGS;

-- Check specific table
DBCC CHECKTABLE (Customers) WITH NO_INFOMSGS;
```

## Performance Tuning

### Monitor Query Performance

```sql
-- Find slow queries
SELECT TOP 10
    qs.execution_count,
    qs.total_elapsed_time / 1000000.0 AS total_elapsed_time_sec,
    qs.total_elapsed_time / qs.execution_count / 1000000.0 AS avg_elapsed_time_sec,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%LoanProcessing%'
ORDER BY qs.total_elapsed_time DESC;
```

### Identify Missing Indexes

```sql
-- Find missing indexes
SELECT 
    migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS impact,
    mid.statement AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID('LoanProcessing')
ORDER BY impact DESC;
```

## Security Configuration

### Create Read-Only User

```sql
USE LoanProcessing;
GO

-- Create login
CREATE LOGIN LoanProcessingReader WITH PASSWORD = 'ReadOnlyPassword123!';

-- Create user
CREATE USER LoanProcessingReader FOR LOGIN LoanProcessingReader;

-- Grant read-only access
ALTER ROLE db_datareader ADD MEMBER LoanProcessingReader;
GO
```

### Create Application User

```sql
USE LoanProcessing;
GO

-- Create login
CREATE LOGIN LoanProcessingApp WITH PASSWORD = 'AppPassword123!';

-- Create user
CREATE USER LoanProcessingApp FOR LOGIN LoanProcessingApp;

-- Grant necessary permissions
GRANT EXECUTE TO LoanProcessingApp;
ALTER ROLE db_datareader ADD MEMBER LoanProcessingApp;
ALTER ROLE db_datawriter ADD MEMBER LoanProcessingApp;
GO
```

### Audit Configuration

```sql
-- Enable auditing
CREATE SERVER AUDIT LoanProcessingAudit
TO FILE (FILEPATH = 'C:\Audits\', MAXSIZE = 100 MB);

CREATE DATABASE AUDIT SPECIFICATION LoanProcessingAuditSpec
FOR SERVER AUDIT LoanProcessingAudit
ADD (SELECT, INSERT, UPDATE, DELETE ON DATABASE::LoanProcessing BY public);

ALTER SERVER AUDIT LoanProcessingAudit WITH (STATE = ON);
ALTER DATABASE AUDIT SPECIFICATION LoanProcessingAuditSpec WITH (STATE = ON);
```

## Next Steps

After completing database setup:

1. **Update Connection String**: Edit `LoanProcessing.Web\Web.config`
2. **Build Application**: Open solution in Visual Studio and build
3. **Run Application**: Press F5 to start the web application
4. **Test Functionality**: Navigate through the application features
5. **Review Logs**: Check for any errors in Event Viewer

## Additional Resources

- **SQL Server Documentation**: https://docs.microsoft.com/en-us/sql/
- **T-SQL Reference**: https://docs.microsoft.com/en-us/sql/t-sql/
- **Database Design Best Practices**: https://docs.microsoft.com/en-us/sql/relational-databases/
- **Project Documentation**: `.kiro/specs/legacy-dotnet-inventory-app/`

---

**Last Updated**: 2024  
**Database Version**: 1.0  
**SQL Server Compatibility**: 2016+

