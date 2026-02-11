# Database Scripts

This folder contains SQL scripts for database setup, initialization, and verification.

## Scripts Overview

### Database Setup

1. **CreateDatabase.sql** (Task 2.1)
   - Creates the LoanProcessing database
   - Creates all tables with constraints
   - Creates indexes for performance
   - Creates the ApplicationNumberSeq sequence
   - **Run this first** to set up the database schema

2. **VerifyTables.sql** (Task 2.1)
   - Verifies all tables exist
   - Checks all constraints are properly created
   - Validates indexes
   - Provides ✓/✗ output for each check

3. **VerifyIndexes.sql** (Task 2.2)
   - Verifies all performance indexes exist
   - Shows index details and columns
   - Confirms Task 2.2 completion

### Sample Data

4. **InitializeSampleData.sql** (Task 2.3)
   - Inserts comprehensive sample data for testing
   - Clears existing data first (safe to run multiple times)
   - Inserts:
     - 13 customers with varying credit scores (545-820)
     - 60 interest rate records (all loan types and credit tiers)
     - 14 loan applications (Pending, Under Review, Approved, Rejected)
     - 8 loan decisions (5 approved, 3 rejected)
   - **Run this after CreateDatabase.sql** to populate test data

5. **VerifySampleData.sql** (Task 2.3)
   - Verifies sample data was loaded correctly
   - Shows data distribution statistics
   - Displays credit score distribution, rate coverage, application status
   - Provides summary of all data

## Quick Start

### Option 1: SQL Server Management Studio (SSMS)

```sql
-- 1. Open SSMS and connect to your SQL Server instance
-- 2. Open and execute scripts in this order:

-- Step 1: Create database and schema
File → Open → CreateDatabase.sql
Execute (F5)

-- Step 2: Verify schema
File → Open → VerifyTables.sql
Execute (F5)

-- Step 3: Load sample data
File → Open → InitializeSampleData.sql
Execute (F5)

-- Step 4: Verify sample data
File → Open → VerifySampleData.sql
Execute (F5)
```

### Option 2: sqlcmd Command Line

```bash
# Navigate to the Scripts folder
cd LoanProcessing.Database\Scripts

# Step 1: Create database and schema
sqlcmd -S localhost -E -i CreateDatabase.sql

# Step 2: Verify schema
sqlcmd -S localhost -d LoanProcessing -E -i VerifyTables.sql

# Step 3: Load sample data
sqlcmd -S localhost -d LoanProcessing -E -i InitializeSampleData.sql

# Step 4: Verify sample data
sqlcmd -S localhost -d LoanProcessing -E -i VerifySampleData.sql
```

### Option 3: PowerShell

```powershell
# Navigate to the Scripts folder
cd LoanProcessing.Database\Scripts

# Step 1: Create database and schema
Invoke-Sqlcmd -ServerInstance "localhost" -InputFile "CreateDatabase.sql"

# Step 2: Verify schema
Invoke-Sqlcmd -ServerInstance "localhost" -Database "LoanProcessing" -InputFile "VerifyTables.sql"

# Step 3: Load sample data
Invoke-Sqlcmd -ServerInstance "localhost" -Database "LoanProcessing" -InputFile "InitializeSampleData.sql"

# Step 4: Verify sample data
Invoke-Sqlcmd -ServerInstance "localhost" -Database "LoanProcessing" -InputFile "VerifySampleData.sql"
```

## Script Execution Order

**Important**: Execute scripts in this order:

1. ✅ **CreateDatabase.sql** - Creates database and schema
2. ✅ **VerifyTables.sql** - Confirms schema is correct
3. ✅ **InitializeSampleData.sql** - Loads test data
4. ✅ **VerifySampleData.sql** - Confirms data is loaded

## Sample Data Details

### Customers (13 records)
- **Excellent Credit (750-850)**: 3 customers
- **Good Credit (700-749)**: 3 customers
- **Fair Credit (650-699)**: 3 customers
- **Poor Credit (600-649)**: 2 customers
- **Very Poor Credit (300-599)**: 2 customers

### Interest Rates (60 records)
- **Personal Loans**: 15 rates (12-84 months, up to $50K)
- **Auto Loans**: 15 rates (24-84 months, up to $75K)
- **Mortgage Loans**: 15 rates (120-360 months, up to $500K)
- **Business Loans**: 15 rates (12-120 months, up to $250K)

### Loan Applications (14 records)
- **Pending**: 3 applications
- **Under Review**: 3 applications
- **Approved**: 5 applications
- **Rejected**: 3 applications

### Loan Decisions (8 records)
- **Approved**: 5 decisions (risk scores 8-38, DTI 12-33%)
- **Rejected**: 3 decisions (risk scores 68-88, DTI 48-61%)

## Resetting the Database

To completely reset the database:

```sql
-- Option 1: Drop and recreate
USE master;
DROP DATABASE LoanProcessing;
GO

-- Then run CreateDatabase.sql and InitializeSampleData.sql

-- Option 2: Just reload sample data
-- Run InitializeSampleData.sql (it clears existing data first)
```

## Troubleshooting

### "Database already exists"
- This is normal - the script checks and skips creation if it exists
- To start fresh, drop the database first

### "Table already exists"
- This is normal - the script checks and skips creation if it exists
- Tables are created with IF NOT EXISTS checks

### "Cannot insert duplicate key"
- Run InitializeSampleData.sql - it clears existing data first
- Or manually delete data: `DELETE FROM [table_name]`

### "Foreign key constraint violation"
- Ensure you run InitializeSampleData.sql (not manual inserts)
- The script inserts data in the correct dependency order

### "sqlcmd not recognized"
- Install SQL Server Command Line Utilities
- Or use SSMS or PowerShell instead

## Connection String

The application uses this connection string (from Web.config):

```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=LoanProcessing;Integrated Security=True" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

## Next Steps

After running these scripts:

1. ✅ Database schema is created (Tasks 2.1, 2.2)
2. ✅ Sample data is loaded (Task 2.3)
3. ➡️ Ready to create stored procedures (Tasks 3-7)
4. ➡️ Ready to test application layer (Tasks 9-16)

## Additional Resources

- **Task Summaries**: See TASK_2.1_SUMMARY.md, TASK_2.2_SUMMARY.md, TASK_2.3_SUMMARY.md
- **Design Document**: .kiro/specs/legacy-dotnet-inventory-app/design.md
- **Requirements**: .kiro/specs/legacy-dotnet-inventory-app/requirements.md
- **Database Project**: LoanProcessing.Database/LoanProcessing.Database.sqlproj

## Support

For issues or questions:
1. Check the task summary documents
2. Review the design document
3. Verify connection string in Web.config
4. Ensure SQL Server is running
5. Check SQL Server error logs

---

**Last Updated**: January 2024
**Tasks Completed**: 2.1, 2.2, 2.3
**Status**: ✅ Database setup and sample data ready
