# Deployment Guide: Legacy .NET Framework Loan Processing Application

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [Application Configuration](#application-configuration)
4. [Sample Data Initialization](#sample-data-initialization)
5. [Deployment Steps](#deployment-steps)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)
8. [Modernization Considerations](#modernization-considerations)

## Prerequisites

### Software Requirements

- **Operating System**: Windows Server 2016+ or Windows 10/11
- **.NET Framework**: 4.7.2 or higher
- **SQL Server**: 2016 or higher (or SQL Server LocalDB for development)
- **IIS**: 8.5 or higher (for production deployment)
- **Visual Studio**: 2017 or later (for development)

### Hardware Requirements

**Minimum**:
- CPU: 2 cores
- RAM: 4 GB
- Disk: 10 GB free space

**Recommended**:
- CPU: 4+ cores
- RAM: 8+ GB
- Disk: 20+ GB free space (SSD preferred)

### Network Requirements

- SQL Server port 1433 accessible (if using remote database)
- HTTP port 80 or HTTPS port 443 for web application
- Outbound internet access for NuGet package restore (during build)

## Database Setup

### Step 1: Create the Database

Choose one of the following methods:

#### Method A: Using SQL Server Management Studio (SSMS) - Recommended

1. Open SQL Server Management Studio
2. Connect to your SQL Server instance
3. Open the script: `LoanProcessing.Database/Scripts/CreateDatabase.sql`
4. Execute the script (F5)
5. Verify the database was created:
   ```sql
   SELECT name FROM sys.databases WHERE name = 'LoanProcessing';
   ```


#### Method B: Using sqlcmd Command Line

```powershell
# For LocalDB (development)
sqlcmd -S (localdb)\MSSQLLocalDB -E -i LoanProcessing.Database\Scripts\CreateDatabase.sql

# For SQL Server instance (production)
sqlcmd -S YOUR_SERVER_NAME -E -i LoanProcessing.Database\Scripts\CreateDatabase.sql
```

#### Method C: Using Visual Studio Database Project

1. Open `LoanProcessing.sln` in Visual Studio
2. Right-click on `LoanProcessing.Database` project
3. Select **Publish...**
4. Configure target database connection:
   - Server name: `(localdb)\MSSQLLocalDB` or your SQL Server instance
   - Database name: `LoanProcessing`
   - Authentication: Windows Authentication
5. Click **Publish**

### Step 2: Verify Database Schema

Run the verification script to ensure all tables and constraints were created:

```sql
USE LoanProcessing;
GO

-- Check tables
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Expected tables:
-- Customers
-- InterestRates
-- LoanApplications
-- LoanDecisions
-- PaymentSchedules

-- Check stored procedures
SELECT ROUTINE_NAME 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;
```

Expected stored procedures:
- `sp_CalculatePaymentSchedule`
- `sp_CreateCustomer`
- `sp_EvaluateCredit`
- `sp_GeneratePortfolioReport`
- `sp_GetCustomerById`
- `sp_ProcessLoanDecision`
- `sp_SearchCustomers`
- `sp_SubmitLoanApplication`
- `sp_UpdateCustomer`


### Step 3: Configure Database Security

#### For Development (LocalDB)

No additional configuration needed - uses Windows Authentication.

#### For Production (SQL Server)

1. **Create SQL Login** (if not using Windows Authentication):
   ```sql
   USE master;
   GO
   CREATE LOGIN LoanProcessingApp WITH PASSWORD = 'YourSecurePassword123!';
   GO
   ```

2. **Create Database User**:
   ```sql
   USE LoanProcessing;
   GO
   CREATE USER LoanProcessingApp FOR LOGIN LoanProcessingApp;
   GO
   ```

3. **Grant Permissions**:
   ```sql
   -- Grant execute permissions on stored procedures
   GRANT EXECUTE TO LoanProcessingApp;
   
   -- Grant read/write permissions on tables
   ALTER ROLE db_datareader ADD MEMBER LoanProcessingApp;
   ALTER ROLE db_datawriter ADD MEMBER LoanProcessingApp;
   GO
   ```

4. **Test Connection**:
   ```powershell
   sqlcmd -S YOUR_SERVER_NAME -U LoanProcessingApp -P YourSecurePassword123! -d LoanProcessing -Q "SELECT @@VERSION"
   ```

## Application Configuration

### Step 1: Update Connection String

Edit `LoanProcessing.Web\Web.config` and update the connection string:

#### For Development (LocalDB):
```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=LoanProcessing;Integrated Security=True;Connect Timeout=30;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

#### For Production (Windows Authentication):
```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Server=YOUR_SERVER_NAME;Database=LoanProcessing;Trusted_Connection=True;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```


#### For Production (SQL Authentication):
```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Server=YOUR_SERVER_NAME;Database=LoanProcessing;User Id=LoanProcessingApp;Password=YourSecurePassword123!;Connect Timeout=30;Encrypt=True;TrustServerCertificate=False;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

**Security Note**: For production, store sensitive connection strings in:
- Azure Key Vault
- Windows Credential Manager
- Encrypted configuration sections
- Environment variables

### Step 2: Configure Application Settings

Review and update application settings in `Web.config`:

```xml
<appSettings>
  <!-- Enable client-side validation -->
  <add key="ClientValidationEnabled" value="true" />
  <add key="UnobtrusiveJavaScriptEnabled" value="true" />
  
  <!-- Application-specific settings -->
  <add key="MaxLoanAmount_Personal" value="50000" />
  <add key="MaxLoanAmount_Auto" value="75000" />
  <add key="MaxLoanAmount_Mortgage" value="500000" />
  <add key="MaxLoanAmount_Business" value="250000" />
</appSettings>
```

### Step 3: Build the Application

#### Using Visual Studio:

1. Open `LoanProcessing.sln`
2. Right-click solution → **Restore NuGet Packages**
3. Build → **Build Solution** (Ctrl+Shift+B)
4. Verify no build errors in Output window

#### Using MSBuild Command Line:

```powershell
# Restore NuGet packages
nuget restore LoanProcessing.sln

# Build solution
msbuild LoanProcessing.sln /p:Configuration=Release /p:Platform="Any CPU"
```

### Step 4: Publish the Application

#### For IIS Deployment:

1. In Visual Studio, right-click `LoanProcessing.Web` project
2. Select **Publish...**
3. Choose **Folder** as publish target
4. Set target location: `C:\inetpub\wwwroot\LoanProcessing`
5. Click **Publish**

#### Using MSBuild:

```powershell
msbuild LoanProcessing.Web\LoanProcessing.Web.csproj /p:DeployOnBuild=true /p:PublishProfile=FolderProfile /p:Configuration=Release
```


## Sample Data Initialization

### Step 1: Initialize Sample Data

Run the sample data script to populate the database with test data:

```powershell
# Using sqlcmd
sqlcmd -S YOUR_SERVER_NAME -E -d LoanProcessing -i LoanProcessing.Database\Scripts\InitializeSampleData.sql
```

Or in SSMS:
1. Open `LoanProcessing.Database\Scripts\InitializeSampleData.sql`
2. Ensure you're connected to the `LoanProcessing` database
3. Execute the script (F5)

### Step 2: Verify Sample Data

Run the verification script:

```sql
USE LoanProcessing;
GO

-- Check customer count
SELECT COUNT(*) AS CustomerCount FROM Customers;
-- Expected: 13 customers

-- Check interest rates
SELECT COUNT(*) AS RateCount FROM InterestRates;
-- Expected: 60 rates (4 loan types × 5 credit tiers × 3 term ranges)

-- Check loan applications
SELECT COUNT(*) AS ApplicationCount FROM LoanApplications;
-- Expected: 14 applications

-- View sample data summary
SELECT 
    'Customers' AS TableName, COUNT(*) AS RecordCount FROM Customers
UNION ALL
SELECT 'InterestRates', COUNT(*) FROM InterestRates
UNION ALL
SELECT 'LoanApplications', COUNT(*) FROM LoanApplications
UNION ALL
SELECT 'LoanDecisions', COUNT(*) FROM LoanDecisions
UNION ALL
SELECT 'PaymentSchedules', COUNT(*) FROM PaymentSchedules;
```

### Sample Data Overview

The initialization script creates:

**Customers** (13 records):
- Mix of credit scores: Excellent (750+), Good (700-749), Fair (650-699), Poor (600-649), Bad (<600)
- Various income levels: $30K to $150K
- Different age groups and demographics

**Interest Rates** (60 records):
- 4 loan types: Personal, Auto, Mortgage, Business
- 5 credit score tiers: 750+, 700-749, 650-699, 600-649, <600
- 3 term ranges: Short (12-60 months), Medium (61-180 months), Long (181-360 months)
- Rates range from 3.5% to 18.99%

**Loan Applications** (14 records):
- Various statuses: Pending, UnderReview, Approved, Rejected
- Different loan types and amounts
- Realistic application scenarios


## Deployment Steps

### Development Environment

1. **Prerequisites Check**:
   ```powershell
   # Check .NET Framework version
   Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' | Get-ItemPropertyValue -Name Release | ForEach-Object { $_ -ge 461808 }
   # Should return True (461808 = .NET 4.7.2)
   
   # Check SQL Server LocalDB
   sqllocaldb info
   # Should list available instances
   ```

2. **Database Setup**:
   - Create database using Method A, B, or C (see Database Setup section)
   - Initialize sample data
   - Verify tables and stored procedures

3. **Application Configuration**:
   - Update connection string in `Web.config`
   - Restore NuGet packages
   - Build solution

4. **Run Application**:
   - Set `LoanProcessing.Web` as startup project
   - Press F5 to run with debugging
   - Application opens at `http://localhost:PORT/`

### Production Environment (IIS)

#### Step 1: Prepare IIS

1. **Install IIS** (if not already installed):
   ```powershell
   # Run as Administrator
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
   ```

2. **Install .NET Framework 4.7.2**:
   - Download from: https://dotnet.microsoft.com/download/dotnet-framework/net472
   - Run installer
   - Restart server if required

3. **Configure Application Pool**:
   ```powershell
   # Import IIS module
   Import-Module WebAdministration
   
   # Create application pool
   New-WebAppPool -Name "LoanProcessingAppPool"
   
   # Configure application pool
   Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name managedRuntimeVersion -Value "v4.0"
   Set-ItemProperty IIS:\AppPools\LoanProcessingAppPool -Name enable32BitAppOnWin64 -Value $false
   ```


#### Step 2: Deploy Application Files

1. **Copy Published Files**:
   ```powershell
   # Create deployment directory
   New-Item -Path "C:\inetpub\wwwroot\LoanProcessing" -ItemType Directory -Force
   
   # Copy published files
   Copy-Item -Path ".\LoanProcessing.Web\bin\Release\Publish\*" -Destination "C:\inetpub\wwwroot\LoanProcessing" -Recurse -Force
   ```

2. **Set Permissions**:
   ```powershell
   # Grant IIS_IUSRS read access
   $acl = Get-Acl "C:\inetpub\wwwroot\LoanProcessing"
   $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
   $acl.SetAccessRule($rule)
   Set-Acl "C:\inetpub\wwwroot\LoanProcessing" $acl
   ```

#### Step 3: Create IIS Website

```powershell
# Create website
New-Website -Name "LoanProcessing" `
            -PhysicalPath "C:\inetpub\wwwroot\LoanProcessing" `
            -ApplicationPool "LoanProcessingAppPool" `
            -Port 80

# Or bind to specific hostname
New-WebBinding -Name "LoanProcessing" -Protocol "http" -Port 80 -HostHeader "loanprocessing.yourdomain.com"
```

#### Step 4: Configure SSL (Recommended for Production)

```powershell
# Import SSL certificate
$cert = Import-PfxCertificate -FilePath "C:\Certificates\loanprocessing.pfx" `
                               -CertStoreLocation Cert:\LocalMachine\My `
                               -Password (ConvertTo-SecureString -String "CertPassword" -AsPlainText -Force)

# Add HTTPS binding
New-WebBinding -Name "LoanProcessing" -Protocol "https" -Port 443 -SslFlags 0
$binding = Get-WebBinding -Name "LoanProcessing" -Protocol "https"
$binding.AddSslCertificate($cert.Thumbprint, "My")
```

#### Step 5: Start Website

```powershell
# Start website
Start-Website -Name "LoanProcessing"

# Verify website is running
Get-Website -Name "LoanProcessing" | Select-Object Name, State, PhysicalPath
```


## Verification

### Step 1: Verify Database Connectivity

Test the connection from the application server:

```powershell
# Test SQL connection
$connectionString = "Server=YOUR_SERVER_NAME;Database=LoanProcessing;Trusted_Connection=True;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    Write-Host "✓ Database connection successful" -ForegroundColor Green
    $connection.Close()
} catch {
    Write-Host "✗ Database connection failed: $_" -ForegroundColor Red
}
```

### Step 2: Verify Application Functionality

1. **Access Home Page**:
   - Navigate to: `http://localhost/` or `http://your-server-name/`
   - Verify page loads without errors
   - Check navigation menu displays: Home, Customers, Loans, Reports

2. **Test Customer Management**:
   - Navigate to **Customers** → **Create New**
   - Fill in customer form with valid data
   - Click **Create** and verify success message
   - Verify customer appears in customer list

3. **Test Loan Application**:
   - Navigate to **Customers** and select a customer
   - Click **Apply for Loan**
   - Fill in loan application form
   - Submit and verify application is created

4. **Test Credit Evaluation**:
   - Navigate to **Loans** and select a pending application
   - Click **Evaluate Credit**
   - Verify risk score and recommendation are displayed

5. **Test Loan Decision**:
   - From evaluation page, click **Make Decision**
   - Approve or reject the loan
   - Verify decision is recorded and status updated

6. **Test Payment Schedule**:
   - For an approved loan, click **View Schedule**
   - Verify payment schedule is displayed with correct calculations

7. **Test Portfolio Report**:
   - Navigate to **Reports** → **Portfolio**
   - Verify report displays loan statistics
   - Test date range filtering

### Step 3: Verify Stored Procedures

Run test queries to verify stored procedures work correctly:

```sql
USE LoanProcessing;
GO

-- Test sp_CreateCustomer
DECLARE @CustomerId INT;
EXEC sp_CreateCustomer 
    @FirstName = 'Test', 
    @LastName = 'User',
    @SSN = '999-99-9999',
    @DateOfBirth = '1990-01-01',
    @AnnualIncome = 50000,
    @CreditScore = 720,
    @Email = 'test@example.com',
    @Phone = '555-1234',
    @Address = '123 Test St',
    @CustomerId = @CustomerId OUTPUT;
SELECT @CustomerId AS NewCustomerId;

-- Test sp_SearchCustomers
EXEC sp_SearchCustomers @SearchTerm = 'Smith';

-- Clean up test data
DELETE FROM Customers WHERE SSN = '999-99-9999';
```


## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Cannot open database 'LoanProcessing'"

**Symptoms**: Application throws SqlException when trying to connect

**Solutions**:
1. Verify database exists:
   ```sql
   SELECT name FROM sys.databases WHERE name = 'LoanProcessing';
   ```
2. Check connection string in `Web.config`
3. Verify SQL Server service is running:
   ```powershell
   Get-Service -Name MSSQLSERVER
   ```
4. Test connection with sqlcmd:
   ```powershell
   sqlcmd -S YOUR_SERVER_NAME -E -d LoanProcessing -Q "SELECT @@VERSION"
   ```

#### Issue 2: "Login failed for user"

**Symptoms**: Authentication error when connecting to database

**Solutions**:
1. For Windows Authentication:
   - Verify IIS Application Pool identity has database access
   - Grant permissions to `IIS APPPOOL\LoanProcessingAppPool`
   ```sql
   USE LoanProcessing;
   CREATE USER [IIS APPPOOL\LoanProcessingAppPool] FOR LOGIN [IIS APPPOOL\LoanProcessingAppPool];
   GRANT EXECUTE TO [IIS APPPOOL\LoanProcessingAppPool];
   ALTER ROLE db_datareader ADD MEMBER [IIS APPPOOL\LoanProcessingAppPool];
   ALTER ROLE db_datawriter ADD MEMBER [IIS APPPOOL\LoanProcessingAppPool];
   ```

2. For SQL Authentication:
   - Verify username and password in connection string
   - Check SQL Server allows SQL Authentication (not just Windows)
   - Verify login exists and has permissions

#### Issue 3: "Could not find stored procedure 'sp_CreateCustomer'"

**Symptoms**: Application throws error when calling stored procedures

**Solutions**:
1. Verify stored procedures exist:
   ```sql
   SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE';
   ```
2. Re-run stored procedure creation scripts:
   ```powershell
   sqlcmd -S YOUR_SERVER_NAME -E -d LoanProcessing -i LoanProcessing.Database\StoredProcedures\sp_CreateCustomer.sql
   ```
3. Check database context in connection string


#### Issue 4: "HTTP Error 500.19 - Internal Server Error"

**Symptoms**: IIS shows configuration error

**Solutions**:
1. Verify .NET Framework 4.7.2 is installed
2. Register ASP.NET with IIS:
   ```powershell
   C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -i
   ```
3. Check `Web.config` for syntax errors
4. Verify application pool is using .NET 4.0 (not .NET Core)

#### Issue 5: "The page cannot be displayed" or "Service Unavailable"

**Symptoms**: Website doesn't load

**Solutions**:
1. Check application pool is started:
   ```powershell
   Get-WebAppPoolState -Name "LoanProcessingAppPool"
   Start-WebAppPool -Name "LoanProcessingAppPool"
   ```
2. Check IIS website is started:
   ```powershell
   Get-Website -Name "LoanProcessing" | Select-Object Name, State
   Start-Website -Name "LoanProcessing"
   ```
3. Check Event Viewer for errors:
   - Windows Logs → Application
   - Look for errors from "ASP.NET" or "IIS"

#### Issue 6: "NuGet packages not restored"

**Symptoms**: Build errors about missing references

**Solutions**:
1. Enable NuGet Package Restore:
   ```powershell
   nuget restore LoanProcessing.sln
   ```
2. In Visual Studio: Tools → Options → NuGet Package Manager → Enable "Allow NuGet to download missing packages"
3. Clear NuGet cache:
   ```powershell
   nuget locals all -clear
   ```

#### Issue 7: "Payment schedule calculations incorrect"

**Symptoms**: Payment amounts don't match expected values

**Solutions**:
1. Verify interest rate data is populated:
   ```sql
   SELECT * FROM InterestRates WHERE LoanType = 'Personal';
   ```
2. Check `sp_CalculatePaymentSchedule` stored procedure logic
3. Verify decimal precision in calculations (use DECIMAL(18,2))


### Logging and Diagnostics

#### Enable Detailed Error Messages (Development Only)

In `Web.config`:
```xml
<system.web>
  <customErrors mode="Off" />
  <compilation debug="true" targetFramework="4.7.2" />
</system.web>
```

**Warning**: Never use `customErrors mode="Off"` in production!

#### Check Application Event Log

```powershell
# View recent application errors
Get-EventLog -LogName Application -Source "ASP.NET*" -Newest 20 | 
    Where-Object {$_.EntryType -eq "Error"} | 
    Format-Table TimeGenerated, Message -AutoSize
```

#### Enable SQL Server Profiler

For debugging database issues:
1. Open SQL Server Profiler
2. Connect to your SQL Server instance
3. Start a new trace with "Standard" template
4. Reproduce the issue in the application
5. Review captured SQL statements and errors

## Modernization Considerations

This application demonstrates legacy patterns that are common modernization targets. When planning to modernize this application, consider the following:

### Architecture Modernization

**Current State** (Legacy):
- Business logic in stored procedures
- Tight coupling to SQL Server
- Limited testability
- Manual ADO.NET data access

**Target State** (Modern):
- Business logic in application tier (C#)
- Database-agnostic design with repository pattern
- High testability with dependency injection
- Entity Framework Core with LINQ

### Technology Stack Upgrade Path

1. **Phase 1: Refactor Business Logic**
   - Extract stored procedure logic to C# service classes
   - Implement unit tests for business logic
   - Keep database schema unchanged

2. **Phase 2: Upgrade Framework**
   - Migrate from .NET Framework 4.7.2 to .NET 6/8
   - Upgrade ASP.NET MVC 5 to ASP.NET Core MVC
   - Replace Entity Framework 6 with EF Core

3. **Phase 3: Modernize Data Access**
   - Replace ADO.NET with Entity Framework Core
   - Implement CQRS pattern for complex queries
   - Add caching layer (Redis/Memory Cache)

4. **Phase 4: API-First Architecture**
   - Create RESTful API with ASP.NET Core Web API
   - Implement authentication/authorization (JWT)
   - Add API versioning and documentation (Swagger)

5. **Phase 5: Modern UI**
   - Replace Razor views with React/Angular/Vue.js SPA
   - Implement responsive design
   - Add real-time features (SignalR)


### Database Modernization Strategy

**Current Challenges**:
- Business logic in stored procedures (hard to test)
- Tight coupling to SQL Server
- Limited version control for database changes
- Complex deployment process

**Modernization Approaches**:

1. **Strangler Fig Pattern**:
   - Gradually replace stored procedures with application code
   - Keep both implementations running in parallel
   - Route traffic to new implementation incrementally
   - Retire old stored procedures once validated

2. **Database Refactoring**:
   - Use database migration tools (FluentMigrator, DbUp)
   - Version control all database changes
   - Implement automated database deployment
   - Add database unit tests

3. **CQRS (Command Query Responsibility Segregation)**:
   - Separate read and write operations
   - Use stored procedures for complex reports (read)
   - Use EF Core for transactional operations (write)
   - Optimize each side independently

### Testing Strategy for Modernization

**Current State**:
- Limited unit tests (due to database dependencies)
- Manual testing required
- Difficult to test stored procedure logic

**Target State**:
- Comprehensive unit test coverage (80%+)
- Integration tests for data access
- Property-based tests for business logic
- Automated regression testing

**Migration Steps**:
1. Add integration tests for current stored procedures
2. Extract business logic to C# classes
3. Add unit tests for extracted logic
4. Implement property-based tests (FSCheck)
5. Maintain integration tests as safety net

### Performance Considerations

**Current Strengths**:
- Stored procedures are pre-compiled and optimized
- Database-side calculations reduce network traffic
- Efficient for complex aggregations

**Modernization Trade-offs**:
- Application-tier logic may be slower initially
- More network round-trips
- Requires careful optimization

**Mitigation Strategies**:
- Implement caching (Redis, Memory Cache)
- Use async/await for I/O operations
- Batch database operations
- Profile and optimize hot paths
- Consider keeping complex reports in stored procedures


### Security Improvements for Modernization

**Current Security Concerns**:
- Connection strings in plain text
- Limited input validation
- No authentication/authorization framework
- SQL injection risk (mitigated by parameterized queries)

**Recommended Improvements**:
1. **Secrets Management**:
   - Use Azure Key Vault or AWS Secrets Manager
   - Implement configuration encryption
   - Rotate credentials regularly

2. **Authentication & Authorization**:
   - Implement ASP.NET Core Identity
   - Add role-based access control (RBAC)
   - Use JWT tokens for API authentication
   - Implement OAuth 2.0 / OpenID Connect

3. **Input Validation**:
   - Use Data Annotations for model validation
   - Implement FluentValidation for complex rules
   - Add CSRF protection
   - Sanitize all user inputs

4. **Security Headers**:
   - Add Content Security Policy (CSP)
   - Enable HSTS (HTTP Strict Transport Security)
   - Implement X-Frame-Options
   - Add X-Content-Type-Options

### Deployment Automation

**Current Process**:
- Manual deployment steps
- Manual database updates
- Configuration changes by hand

**Recommended CI/CD Pipeline**:

1. **Source Control**:
   - Git repository (GitHub, Azure DevOps, GitLab)
   - Branch strategy (GitFlow or trunk-based)
   - Pull request reviews

2. **Build Pipeline**:
   ```yaml
   # Example Azure DevOps pipeline
   trigger:
     - main
   
   pool:
     vmImage: 'windows-latest'
   
   steps:
   - task: NuGetCommand@2
     inputs:
       command: 'restore'
       restoreSolution: '**/*.sln'
   
   - task: VSBuild@1
     inputs:
       solution: '**/*.sln'
       configuration: 'Release'
   
   - task: VSTest@2
     inputs:
       testAssemblyVer2: '**\*test*.dll'
   ```

3. **Database Deployment**:
   - Use DACPAC for schema deployment
   - Implement database migrations
   - Automated rollback capability

4. **Infrastructure as Code**:
   - Use Terraform or ARM templates
   - Version control infrastructure
   - Automated environment provisioning


## Quick Reference

### Connection String Templates

```xml
<!-- LocalDB (Development) -->
<add name="LoanProcessingConnection" 
     connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=LoanProcessing;Integrated Security=True;" 
     providerName="System.Data.SqlClient" />

<!-- SQL Server - Windows Auth (Production) -->
<add name="LoanProcessingConnection" 
     connectionString="Server=SERVERNAME;Database=LoanProcessing;Trusted_Connection=True;Encrypt=True;" 
     providerName="System.Data.SqlClient" />

<!-- SQL Server - SQL Auth (Production) -->
<add name="LoanProcessingConnection" 
     connectionString="Server=SERVERNAME;Database=LoanProcessing;User Id=USERNAME;Password=PASSWORD;Encrypt=True;" 
     providerName="System.Data.SqlClient" />

<!-- Azure SQL Database -->
<add name="LoanProcessingConnection" 
     connectionString="Server=tcp:SERVERNAME.database.windows.net,1433;Database=LoanProcessing;User ID=USERNAME;Password=PASSWORD;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" 
     providerName="System.Data.SqlClient" />
```

### Essential Commands

```powershell
# Database Setup
sqlcmd -S SERVERNAME -E -i LoanProcessing.Database\Scripts\CreateDatabase.sql
sqlcmd -S SERVERNAME -E -d LoanProcessing -i LoanProcessing.Database\Scripts\InitializeSampleData.sql

# Build Application
nuget restore LoanProcessing.sln
msbuild LoanProcessing.sln /p:Configuration=Release

# IIS Management
New-WebAppPool -Name "LoanProcessingAppPool"
New-Website -Name "LoanProcessing" -PhysicalPath "C:\inetpub\wwwroot\LoanProcessing" -ApplicationPool "LoanProcessingAppPool" -Port 80
Start-Website -Name "LoanProcessing"

# Troubleshooting
Get-Website -Name "LoanProcessing" | Select-Object Name, State
Get-WebAppPoolState -Name "LoanProcessingAppPool"
Get-EventLog -LogName Application -Source "ASP.NET*" -Newest 20 | Where-Object {$_.EntryType -eq "Error"}
```

### File Locations

- **Application Files**: `C:\inetpub\wwwroot\LoanProcessing`
- **Configuration**: `C:\inetpub\wwwroot\LoanProcessing\Web.config`
- **Logs**: Windows Event Viewer → Application
- **IIS Config**: `C:\Windows\System32\inetsrv\config\applicationHost.config`

### Support Resources

- **Project Documentation**: `.kiro/specs/legacy-dotnet-inventory-app/`
- **Requirements**: `.kiro/specs/legacy-dotnet-inventory-app/requirements.md`
- **Design**: `.kiro/specs/legacy-dotnet-inventory-app/design.md`
- **Tasks**: `.kiro/specs/legacy-dotnet-inventory-app/tasks.md`
- **Database README**: `LoanProcessing.Database/README.md`

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Application Version**: 1.0.0  
**Target Framework**: .NET Framework 4.7.2

