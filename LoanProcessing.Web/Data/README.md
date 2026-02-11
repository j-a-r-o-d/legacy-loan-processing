# Data Access Layer

This folder contains the Entity Framework DbContext for the Loan Processing application.

## LoanProcessingContext

The `LoanProcessingContext` class is the Entity Framework DbContext that provides access to the database entities. It is configured to use the `LoanProcessingConnection` connection string from Web.config.

### Key Features

- **Connection String**: Uses `LoanProcessingConnection` from Web.config
- **Lazy Loading**: Disabled for better performance and explicit control
- **Proxy Creation**: Disabled to avoid serialization issues
- **Entity Mappings**: Configured using Fluent API in `OnModelCreating` method

### Entities

The DbContext provides access to the following entities:

- **Customers**: Customer information including credit scores and income
- **LoanApplications**: Loan application details with status tracking
- **LoanDecisions**: Loan approval/rejection decisions with risk scores
- **PaymentSchedules**: Amortization schedules for approved loans
- **InterestRates**: Interest rate tables based on credit scores and loan types

### Entity Relationships

- **LoanApplication → Customer**: Required relationship (many-to-one)
- **LoanDecision → LoanApplication**: Required relationship (many-to-one)
- **PaymentSchedule → LoanApplication**: Required relationship (many-to-one)

All relationships are configured with `WillCascadeOnDelete(false)` to prevent accidental data loss.

### Primary Keys and Foreign Keys

All entities use identity columns for primary keys:
- `CustomerId` (Customers)
- `ApplicationId` (LoanApplications)
- `DecisionId` (LoanDecisions)
- `ScheduleId` (PaymentSchedules)
- `RateId` (InterestRates)

Foreign key relationships:
- `LoanApplications.CustomerId` → `Customers.CustomerId`
- `LoanDecisions.ApplicationId` → `LoanApplications.ApplicationId`
- `PaymentSchedules.ApplicationId` → `LoanApplications.ApplicationId`

### Unique Constraints

- **Customers.SSN**: Unique index to prevent duplicate SSNs
- **LoanApplications.ApplicationNumber**: Unique index for application numbers
- **PaymentSchedules (ApplicationId, PaymentNumber)**: Composite unique index

### Indexes

The following indexes are configured for performance:
- `Customers.SSN` (unique)
- `LoanApplications.ApplicationNumber` (unique)
- `PaymentSchedules (ApplicationId, PaymentNumber)` (unique, composite)
- `InterestRates (LoanType, MinCreditScore, MaxCreditScore, EffectiveDate)` (composite)

### Usage Example

```csharp
// Basic CRUD operations
using (var context = new LoanProcessingContext())
{
    // Read a customer
    var customer = context.Customers.Find(customerId);
    
    // Query loan applications
    var applications = context.LoanApplications
        .Where(a => a.CustomerId == customerId)
        .ToList();
    
    // Add a new interest rate
    var rate = new InterestRate
    {
        LoanType = "Personal",
        MinCreditScore = 700,
        MaxCreditScore = 749,
        MinTermMonths = 12,
        MaxTermMonths = 60,
        Rate = 8.99m,
        EffectiveDate = DateTime.Now
    };
    context.InterestRates.Add(rate);
    context.SaveChanges();
}
```

### Important Notes

1. **Business Logic**: The DbContext is used only for basic CRUD operations. Business logic operations (credit evaluation, payment calculation, etc.) are handled through stored procedures via ADO.NET in the Repository layer.

2. **Lazy Loading**: Lazy loading is disabled. Use explicit loading or eager loading (`.Include()`) when you need related entities.

3. **Proxy Creation**: Proxy creation is disabled to avoid issues with serialization in MVC controllers.

4. **Connection Management**: The DbContext should be disposed after use. Use `using` statements or dependency injection with proper lifetime management.

5. **Migrations**: This application uses a database-first approach with SQL scripts. Entity Framework migrations are not used.

### Configuration

The connection string is configured in Web.config:

```xml
<connectionStrings>
  <add name="LoanProcessingConnection" 
       connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=LoanProcessing;Integrated Security=True;..." 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

### Testing

To verify the DbContext is working correctly:

1. Ensure the database is created and initialized with the schema
2. Run the initialization scripts from `LoanProcessing.Database`
3. Use the DbContext to query entities and verify data access

### Next Steps

After creating the DbContext, the next steps are:
1. Create Repository interfaces and implementations (Task 10.x)
2. Implement Service layer (Task 11.x)
3. Create MVC Controllers (Task 13.x)
