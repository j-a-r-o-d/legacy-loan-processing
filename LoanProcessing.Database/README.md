# LoanProcessing Database Project

This SQL Server Database Project contains the schema for the Legacy .NET Framework Loan Processing Application.

## Database Schema Overview

The database consists of the following tables:

1. **Customers** - Stores customer information with SSN unique constraint and credit score validation
2. **LoanApplications** - Stores loan application details with foreign key to Customers
3. **LoanDecisions** - Stores loan approval/rejection decisions
4. **PaymentSchedules** - Stores payment schedule details for approved loans
5. **InterestRates** - Stores interest rate tables for different loan types and credit tiers
6. **ApplicationNumberSeq** - Sequence for generating unique application numbers

## Deployment Options

### Option 1: Using Visual Studio (Recommended)

1. Open `LoanProcessing.sln` in Visual Studio
2. Right-click on the `LoanProcessing.Database` project
3. Select "Publish..."
4. Configure the target database connection
5. Click "Publish" to deploy the schema

### Option 2: Using SQL Server Management Studio (SSMS)

1. Open SQL Server Management Studio
2. Connect to your SQL Server instance
3. Open and execute `Scripts/CreateDatabase.sql`
4. This will create the database and all tables with constraints

### Option 3: Using sqlcmd Command Line

```bash
sqlcmd -S (localdb)\MSSQLLocalDB -i Scripts\CreateDatabase.sql
```

Or for a full SQL Server instance:

```bash
sqlcmd -S localhost -E -i Scripts\CreateDatabase.sql
```

## Verification

After deployment, run the verification script to ensure all tables and constraints were created correctly:

```sql
-- In SSMS or sqlcmd
USE LoanProcessing;
GO
:r Scripts\VerifyTables.sql
```

Or using sqlcmd:

```bash
sqlcmd -S (localdb)\MSSQLLocalDB -d LoanProcessing -i Scripts\VerifyTables.sql
```

## Connection String

The application uses the following connection string (configured in `Web.config`):

```
Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=LoanProcessing;Integrated Security=True
```

For a full SQL Server instance, update the connection string to:

```
Server=localhost;Database=LoanProcessing;Trusted_Connection=True;
```

## Task 2.1 Completion

This completes Task 2.1: Create database tables with constraints

✓ Customers table with SSN unique constraint and credit score check
✓ LoanApplications table with foreign key to Customers and status check
✓ LoanDecisions table with foreign key to LoanApplications
✓ PaymentSchedules table with composite unique constraint
✓ InterestRates table with rate validation constraints
✓ Sequence for application number generation

## Next Steps

- Task 2.2: Create database indexes for performance (indexes already included in table definitions)
- Task 2.3: Create sample data initialization script
- Task 3.x: Create stored procedures for business logic
