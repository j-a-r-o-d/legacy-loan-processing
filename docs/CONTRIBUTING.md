# Contributing to LoanProcessing

Thank you for your interest in contributing to the LoanProcessing application!

## Code of Conduct

- Be respectful and professional
- Focus on constructive feedback
- Help maintain code quality and documentation

## Getting Started

1. **Fork the repository** (if external contributor)
2. **Clone your fork** or the main repository
3. **Set up development environment**:
   ```powershell
   # Follow DATABASE_SETUP.md to create database
   # Open LoanProcessing.sln in Visual Studio
   # Restore NuGet packages
   # Build solution
   ```

## Development Workflow

### Branch Naming Convention

Use descriptive branch names with prefixes:

- `feature/` - New features (e.g., `feature/add-loan-calculator`)
- `bugfix/` - Bug fixes (e.g., `bugfix/fix-payment-calculation`)
- `hotfix/` - Critical production fixes (e.g., `hotfix/security-patch`)
- `refactor/` - Code refactoring (e.g., `refactor/extract-business-logic`)
- `docs/` - Documentation updates (e.g., `docs/update-deployment-guide`)

### Making Changes

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following code style guidelines

3. **Write tests** for new functionality:
   - Unit tests for business logic
   - Integration tests for data access
   - Property-based tests for correctness properties

4. **Update documentation** if needed:
   - Update README.md for major features
   - Update relevant .md files in docs/
   - Add inline code comments

5. **Commit your changes** with clear messages:
   ```bash
   git commit -m "Add loan calculator feature"
   ```

## Code Style Guidelines

### C# Code Style

Follow standard C# conventions:

```csharp
// Use PascalCase for classes, methods, properties
public class CustomerService
{
    public Customer GetById(int id) { }
}

// Use camelCase for local variables and parameters
public void ProcessLoan(int applicationId)
{
    var loanAmount = GetLoanAmount(applicationId);
}

// Use meaningful names
// Good
public decimal CalculateMonthlyPayment(decimal principal, decimal rate, int months)

// Bad
public decimal Calc(decimal p, decimal r, int m)

// Add XML documentation for public members
/// <summary>
/// Calculates the monthly payment for a loan.
/// </summary>
/// <param name="principal">The loan principal amount</param>
/// <param name="rate">The annual interest rate (as decimal, e.g., 0.05 for 5%)</param>
/// <param name="months">The loan term in months</param>
/// <returns>The monthly payment amount</returns>
public decimal CalculateMonthlyPayment(decimal principal, decimal rate, int months)
{
    // Implementation
}
```

### SQL Code Style

```sql
-- Use UPPERCASE for SQL keywords
-- Use PascalCase for table and column names
-- Indent nested queries

SELECT 
    c.CustomerId,
    c.FirstName,
    c.LastName,
    COUNT(la.ApplicationId) AS ApplicationCount
FROM Customers c
LEFT JOIN LoanApplications la ON c.CustomerId = la.CustomerId
WHERE c.CreditScore >= 700
GROUP BY c.CustomerId, c.FirstName, c.LastName
ORDER BY ApplicationCount DESC;
```

### JavaScript/jQuery Code Style

```javascript
// Use camelCase for variables and functions
var customerName = "John Smith";

function calculateTotal(amount, rate) {
    return amount * (1 + rate);
}

// Use jQuery selectors efficiently
$('#customerForm').on('submit', function(e) {
    e.preventDefault();
    // Handle form submission
});
```

## Testing Requirements

### Unit Tests

All new business logic must have unit tests:

```csharp
[TestMethod]
public void CalculateMonthlyPayment_ValidInputs_ReturnsCorrectAmount()
{
    // Arrange
    var calculator = new PaymentCalculator();
    decimal principal = 10000m;
    decimal rate = 0.05m;
    int months = 12;
    
    // Act
    var result = calculator.CalculateMonthlyPayment(principal, rate, months);
    
    // Assert
    Assert.IsTrue(result > 0);
    Assert.IsTrue(result < principal); // Monthly payment should be less than principal
}
```

### Property-Based Tests

For critical business logic, add property-based tests:

```csharp
[TestMethod]
[TestCategory("PropertyTest")]
public void Property_PaymentSchedule_SumOfPaymentsEqualsLoanAmount()
{
    var property = Prop.ForAll(
        PropertyTestGenerators.ValidPaymentScheduleParameters(),
        parameters =>
        {
            var (loanAmount, rate, months) = parameters;
            var schedule = _calculator.GenerateSchedule(loanAmount, rate, months);
            var totalPrincipal = schedule.Sum(p => p.PrincipalAmount);
            
            return ApproximatelyEqual(totalPrincipal, loanAmount, 0.01m);
        });
    
    CheckProperty(property, "Payment Schedule Sum Equals Loan Amount");
}
```

### Running Tests

```powershell
# Run all tests
dotnet test

# Run specific test category
dotnet test --filter TestCategory=PropertyTest

# Run tests with verbose output
dotnet test --logger "console;verbosity=detailed"
```

## Pull Request Process

1. **Ensure all tests pass**:
   ```powershell
   dotnet test
   ```

2. **Update documentation** if needed

3. **Create pull request** with:
   - Clear title describing the change
   - Description of what changed and why
   - Reference to any related issues
   - Screenshots (if UI changes)

4. **Pull request template**:
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] Unit tests added/updated
   - [ ] Integration tests added/updated
   - [ ] Manual testing completed
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] No new warnings
   ```

5. **Address review feedback** promptly

6. **Squash commits** if requested before merge

## Database Changes

### Schema Changes

1. **Create migration script** in `LoanProcessing.Database/Scripts/Migrations/`
2. **Name format**: `YYYYMMDD_Description.sql`
3. **Include rollback script**: `YYYYMMDD_Description_Rollback.sql`

Example:
```sql
-- 20240115_AddCustomerEmailIndex.sql
CREATE INDEX IX_Customers_Email ON Customers(Email);
GO

-- 20240115_AddCustomerEmailIndex_Rollback.sql
DROP INDEX IX_Customers_Email ON Customers;
GO
```

### Stored Procedure Changes

1. **Update stored procedure** in `LoanProcessing.Database/StoredProcedures/`
2. **Update documentation** in corresponding `*_README.md` file
3. **Update tests** in `LoanProcessing.Database/Scripts/Test*.sql`

## Documentation Updates

### When to Update Documentation

- **README.md**: Major features, technology changes
- **DEPLOYMENT.md**: Deployment process changes
- **DATABASE_SETUP.md**: Database setup changes
- **APPLICATION_CONFIGURATION.md**: New configuration settings
- **CHANGELOG.md**: Every release

### Documentation Style

- Use clear, concise language
- Include code examples
- Add screenshots for UI changes
- Keep formatting consistent
- Test all commands and scripts

## Release Process

1. **Update version number** in:
   - `LoanProcessing.Web/Properties/AssemblyInfo.cs`
   - `README.md`
   - `CHANGELOG.md`

2. **Update CHANGELOG.md** with:
   - Version number and date
   - New features
   - Bug fixes
   - Breaking changes

3. **Create Git tag**:
   ```bash
   git tag -a v1.1.0 -m "Release version 1.1.0"
   git push origin v1.1.0
   ```

4. **Build release**:
   ```powershell
   msbuild LoanProcessing.sln /p:Configuration=Release
   ```

5. **Test deployment** in staging environment

6. **Deploy to production** following DEPLOYMENT.md

## Getting Help

- **Documentation**: Check docs/ directory
- **Issues**: Search existing issues before creating new ones
- **Questions**: Ask in team chat or create discussion issue

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for significant contributions
- Project documentation
- Release notes

Thank you for contributing to LoanProcessing!
