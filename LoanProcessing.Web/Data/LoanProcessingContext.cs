using System.Data.Entity;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Entity Framework DbContext for the Loan Processing application.
    /// Used for basic CRUD operations on reference data.
    /// Business logic operations are handled through stored procedures via ADO.NET.
    /// </summary>
    public class LoanProcessingContext : DbContext
    {
        /// <summary>
        /// Initializes a new instance of the LoanProcessingContext class.
        /// Uses the "LoanProcessingConnection" connection string from Web.config.
        /// </summary>
        public LoanProcessingContext() : base("name=LoanProcessingConnection")
        {
            // Disable lazy loading for better performance and explicit control
            Configuration.LazyLoadingEnabled = false;
            
            // Disable proxy creation to avoid issues with serialization
            Configuration.ProxyCreationEnabled = false;
        }

        /// <summary>
        /// Gets or sets the Customers DbSet.
        /// </summary>
        public DbSet<Customer> Customers { get; set; }

        /// <summary>
        /// Gets or sets the LoanApplications DbSet.
        /// </summary>
        public DbSet<LoanApplication> LoanApplications { get; set; }

        /// <summary>
        /// Gets or sets the LoanDecisions DbSet.
        /// </summary>
        public DbSet<LoanDecision> LoanDecisions { get; set; }

        /// <summary>
        /// Gets or sets the PaymentSchedules DbSet.
        /// </summary>
        public DbSet<PaymentSchedule> PaymentSchedules { get; set; }

        /// <summary>
        /// Gets or sets the InterestRates DbSet.
        /// </summary>
        public DbSet<InterestRate> InterestRates { get; set; }

        /// <summary>
        /// Configures the entity mappings and relationships using Fluent API.
        /// </summary>
        /// <param name="modelBuilder">The model builder used to configure entities.</param>
        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Customer entity
            modelBuilder.Entity<Customer>()
                .HasKey(c => c.CustomerId);

            modelBuilder.Entity<Customer>()
                .Property(c => c.CustomerId)
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

            modelBuilder.Entity<Customer>()
                .Property(c => c.FirstName)
                .IsRequired()
                .HasMaxLength(50);

            modelBuilder.Entity<Customer>()
                .Property(c => c.LastName)
                .IsRequired()
                .HasMaxLength(50);

            modelBuilder.Entity<Customer>()
                .Property(c => c.SSN)
                .IsRequired()
                .HasMaxLength(11);

            modelBuilder.Entity<Customer>()
                .HasIndex(c => c.SSN)
                .IsUnique();

            modelBuilder.Entity<Customer>()
                .Property(c => c.Email)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Customer>()
                .Property(c => c.Phone)
                .IsRequired()
                .HasMaxLength(20);

            modelBuilder.Entity<Customer>()
                .Property(c => c.Address)
                .IsRequired()
                .HasMaxLength(200);

            modelBuilder.Entity<Customer>()
                .Property(c => c.AnnualIncome)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Customer>()
                .Property(c => c.CreatedDate)
                .IsRequired();

            // Configure LoanApplication entity
            modelBuilder.Entity<LoanApplication>()
                .HasKey(l => l.ApplicationId);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.ApplicationId)
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.ApplicationNumber)
                .IsRequired()
                .HasMaxLength(20);

            modelBuilder.Entity<LoanApplication>()
                .HasIndex(l => l.ApplicationNumber)
                .IsUnique();

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.LoanType)
                .IsRequired()
                .HasMaxLength(20);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.RequestedAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.ApprovedAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.InterestRate)
                .HasPrecision(5, 2);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.Purpose)
                .IsRequired()
                .HasMaxLength(500);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.Status)
                .IsRequired()
                .HasMaxLength(20);

            modelBuilder.Entity<LoanApplication>()
                .Property(l => l.ApplicationDate)
                .IsRequired();

            // Configure relationship: LoanApplication -> Customer
            modelBuilder.Entity<LoanApplication>()
                .HasRequired(l => l.Customer)
                .WithMany()
                .HasForeignKey(l => l.CustomerId)
                .WillCascadeOnDelete(false);

            // Configure LoanDecision entity
            modelBuilder.Entity<LoanDecision>()
                .HasKey(d => d.DecisionId);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.DecisionId)
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.Decision)
                .IsRequired()
                .HasMaxLength(20);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.DecisionBy)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.Comments)
                .HasMaxLength(1000);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.ApprovedAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.InterestRate)
                .HasPrecision(5, 2);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.DebtToIncomeRatio)
                .HasPrecision(5, 2);

            modelBuilder.Entity<LoanDecision>()
                .Property(d => d.DecisionDate)
                .IsRequired();

            // Configure relationship: LoanDecision -> LoanApplication
            modelBuilder.Entity<LoanDecision>()
                .HasRequired(d => d.LoanApplication)
                .WithMany()
                .HasForeignKey(d => d.ApplicationId)
                .WillCascadeOnDelete(false);

            // Configure PaymentSchedule entity
            modelBuilder.Entity<PaymentSchedule>()
                .HasKey(p => p.ScheduleId);

            modelBuilder.Entity<PaymentSchedule>()
                .Property(p => p.ScheduleId)
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

            modelBuilder.Entity<PaymentSchedule>()
                .Property(p => p.PaymentAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<PaymentSchedule>()
                .Property(p => p.PrincipalAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<PaymentSchedule>()
                .Property(p => p.InterestAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<PaymentSchedule>()
                .Property(p => p.RemainingBalance)
                .HasPrecision(18, 2);

            modelBuilder.Entity<PaymentSchedule>()
                .Property(p => p.DueDate)
                .IsRequired();

            // Configure relationship: PaymentSchedule -> LoanApplication
            modelBuilder.Entity<PaymentSchedule>()
                .HasRequired(p => p.LoanApplication)
                .WithMany()
                .HasForeignKey(p => p.ApplicationId)
                .WillCascadeOnDelete(false);

            // Configure composite unique constraint for PaymentSchedule
            modelBuilder.Entity<PaymentSchedule>()
                .HasIndex(p => new { p.ApplicationId, p.PaymentNumber })
                .IsUnique();

            // Configure InterestRate entity
            modelBuilder.Entity<InterestRate>()
                .HasKey(r => r.RateId);

            modelBuilder.Entity<InterestRate>()
                .Property(r => r.RateId)
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

            modelBuilder.Entity<InterestRate>()
                .Property(r => r.LoanType)
                .IsRequired()
                .HasMaxLength(20);

            modelBuilder.Entity<InterestRate>()
                .Property(r => r.Rate)
                .HasPrecision(5, 2);

            modelBuilder.Entity<InterestRate>()
                .Property(r => r.EffectiveDate)
                .IsRequired();

            // Configure index for InterestRate lookups
            modelBuilder.Entity<InterestRate>()
                .HasIndex(r => new { r.LoanType, r.MinCreditScore, r.MaxCreditScore, r.EffectiveDate });
        }
    }
}
