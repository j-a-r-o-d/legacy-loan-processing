# Quick Start Guide

Get the LoanProcessing application running in 5 minutes.

## Prerequisites Check

```powershell
# Check .NET Framework version (should be 4.7.2+)
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' | 
    Get-ItemPropertyValue -Name Release | 
    ForEach-Object { $_ -ge 461808 }
# Should return True

# Check SQL Server LocalDB
sqllocaldb info
# Should list available instances
```

## Setup Steps

### 1. Create Database (2 minutes)

```powershell
# Navigate to project directory
cd LoanProcessing

# Create database
sqlcmd -S (localdb)\MSSQLLocalDB -E -i LoanProcessing.Database\Scripts\CreateDatabase.sql

# Initialize sample data
sqlcmd -S (localdb)\MSSQLLocalDB -E -d LoanProcessing -i LoanProcessing.Database\Scripts\InitializeSampleData.sql
```

### 2. Build Application (1 minute)

```powershell
# Restore NuGet packages
nuget restore LoanProcessing.sln

# Build solution
msbuild LoanProcessing.sln /p:Configuration=Debug
```

Or in Visual Studio:
1. Open `LoanProcessing.sln`
2. Right-click solution → Restore NuGet Packages
3. Press Ctrl+Shift+B to build

### 3. Run Application (1 minute)

In Visual Studio:
1. Set `LoanProcessing.Web` as startup project
2. Press F5 to run

Or from command line:
```powershell
# Start IIS Express
"C:\Program Files\IIS Express\iisexpress.exe" /path:"$PWD\LoanProcessing.Web" /port:51234
```

### 4. Verify (1 minute)

Open browser to `http://localhost:51234/`

Test the application:
1. Click **Customers** → View sample customers
2. Click **Loans** → View sample loan applications
3. Click **Reports** → View portfolio report
4. Click **Interest Rates** → View rate tables

## Sample Data

The database includes:
- **13 customers** with varying credit scores (300-850)
- **60 interest rates** covering all loan types and credit tiers
- **14 loan applications** in various statuses

## Common Issues

### "Cannot open database 'LoanProcessing'"

**Solution**: Verify database was created
```powershell
sqlcmd -S (localdb)\MSSQLLocalDB -E -Q "SELECT name FROM sys.databases WHERE name = 'LoanProcessing'"
```

### "Build failed - missing references"

**Solution**: Restore NuGet packages
```powershell
nuget restore LoanProcessing.sln
```

### "Port 51234 already in use"

**Solution**: Change port in project properties or kill existing process
```powershell
# Find process using port
netstat -ano | findstr :51234

# Kill process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

## Next Steps

### For Development
- Read [CONTRIBUTING.md](CONTRIBUTING.md) for code guidelines
- Review [requirements.md](../.kiro/specs/legacy-dotnet-inventory-app/requirements.md) for business rules
- Check [design.md](../.kiro/specs/legacy-dotnet-inventory-app/design.md) for architecture

### For Deployment
- Follow [DEPLOYMENT.md](../DEPLOYMENT.md) for production deployment
- Review [APPLICATION_CONFIGURATION.md](../APPLICATION_CONFIGURATION.md) for settings
- Check [DATABASE_SETUP.md](../DATABASE_SETUP.md) for database configuration

### For Testing
- Run existing tests: `dotnet test`
- Review [LoanProcessing.Web/Tests/README.md](../LoanProcessing.Web/Tests/README.md) for testing guide
- Add new tests following [CONTRIBUTING.md](CONTRIBUTING.md) guidelines

## Documentation

- **README.md** - Project overview and modernization roadmap
- **DEPLOYMENT.md** - Complete deployment guide
- **DATABASE_SETUP.md** - Database setup and maintenance
- **APPLICATION_CONFIGURATION.md** - Configuration reference
- **CONTRIBUTING.md** - Contribution guidelines
- **CHANGELOG.md** - Version history

## Support

Need help? Check:
1. [DOCUMENTATION_GUIDE.md](DOCUMENTATION_GUIDE.md) - Documentation organization
2. [DEPLOYMENT.md](../DEPLOYMENT.md) - Troubleshooting section
3. Project issues in repository

---

**Time to first run**: ~5 minutes  
**Sample data**: Included  
**Authentication**: None (demo application)
