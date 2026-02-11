using System;
using FsCheck;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Tests
{
    /// <summary>
    /// FSCheck generators for creating valid test data for property-based testing.
    /// These generators create randomized but valid domain objects that satisfy business constraints.
    /// </summary>
    public static class PropertyTestGenerators
    {
        #region Customer Generators

        /// <summary>
        /// Generates a valid Customer with all required fields and business constraints satisfied.
        /// - Credit score: 300-850
        /// - Age: 18-100 years old
        /// - Annual income: $10,000 - $500,000
        /// - SSN: Valid format (###-##-####)
        /// </summary>
        public static Arbitrary<Customer> ValidCustomer()
        {
            return Arb.From(
                from firstName in Gen.Elements("John", "Jane", "Michael", "Sarah", "David", "Emily", "Robert", "Lisa")
                from lastName in Gen.Elements("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis")
                from ssnPart1 in Gen.Choose(100, 999)
                from ssnPart2 in Gen.Choose(10, 99)
                from ssnPart3 in Gen.Choose(1000, 9999)
                from birthYear in Gen.Choose(DateTime.Now.Year - 100, DateTime.Now.Year - 18)
                from birthMonth in Gen.Choose(1, 12)
                from birthDay in Gen.Choose(1, 28) // Use 28 to avoid invalid dates
                from annualIncome in Gen.Choose(10000, 500000).Select(x => (decimal)x)
                from creditScore in Gen.Choose(300, 850)
                from emailPrefix in Gen.Elements("test", "user", "customer", "client")
                from phoneArea in Gen.Choose(200, 999)
                from phoneExchange in Gen.Choose(200, 999)
                from phoneNumber in Gen.Choose(1000, 9999)
                from streetNumber in Gen.Choose(1, 9999)
                from streetName in Gen.Elements("Main", "Oak", "Maple", "Cedar", "Pine", "Elm")
                select new Customer
                {
                    FirstName = firstName,
                    LastName = lastName,
                    SSN = $"{ssnPart1:D3}-{ssnPart2:D2}-{ssnPart3:D4}",
                    DateOfBirth = new DateTime(birthYear, birthMonth, birthDay),
                    AnnualIncome = annualIncome,
                    CreditScore = creditScore,
                    Email = $"{emailPrefix}.{lastName.ToLower()}@example.com",
                    Phone = $"{phoneArea:D3}-{phoneExchange:D3}-{phoneNumber:D4}",
                    Address = $"{streetNumber} {streetName} St",
                    CreatedDate = DateTime.Now
                });
        }

        /// <summary>
        /// Generates a Customer with a specific credit score range.
        /// Useful for testing credit-score-dependent logic.
        /// </summary>
        public static Arbitrary<Customer> CustomerWithCreditScore(int minScore, int maxScore)
        {
            return Arb.From(
                from customer in ValidCustomer().Generator
                from creditScore in Gen.Choose(Math.Max(300, minScore), Math.Min(850, maxScore))
                select new Customer
                {
                    CustomerId = customer.CustomerId,
                    FirstName = customer.FirstName,
                    LastName = customer.LastName,
                    SSN = customer.SSN,
                    DateOfBirth = customer.DateOfBirth,
                    AnnualIncome = customer.AnnualIncome,
                    CreditScore = creditScore,
                    Email = customer.Email,
                    Phone = customer.Phone,
                    Address = customer.Address,
                    CreatedDate = customer.CreatedDate
                });
        }

        #endregion

        #region Loan Application Generators

        /// <summary>
        /// Generates a valid LoanApplication with appropriate constraints:
        /// - Personal loans: $1,000 - $50,000
        /// - Auto loans: $5,000 - $75,000
        /// - Mortgage loans: $50,000 - $500,000
        /// - Business loans: $10,000 - $250,000
        /// - Term: 12-360 months
        /// </summary>
        public static Arbitrary<LoanApplication> ValidLoanApplication()
        {
            return Arb.From(
                from loanType in Gen.Elements("Personal", "Auto", "Mortgage", "Business")
                from customerId in Gen.Choose(1, 1000)
                from requestedAmount in GenerateLoanAmountForType(loanType)
                from termMonths in Gen.Choose(12, 360)
                from purpose in Gen.Elements(
                    "Debt consolidation",
                    "Home improvement",
                    "Vehicle purchase",
                    "Business expansion",
                    "Education",
                    "Medical expenses",
                    "Wedding",
                    "Vacation")
                select new LoanApplication
                {
                    CustomerId = customerId,
                    LoanType = loanType,
                    RequestedAmount = requestedAmount,
                    TermMonths = termMonths,
                    Purpose = purpose,
                    Status = "Pending",
                    ApplicationDate = DateTime.Now
                });
        }

        /// <summary>
        /// Generates a loan amount appropriate for the given loan type.
        /// </summary>
        private static Gen<decimal> GenerateLoanAmountForType(string loanType)
        {
            switch (loanType)
            {
                case "Personal":
                    return Gen.Choose(1000, 50000).Select(x => (decimal)x);
                case "Auto":
                    return Gen.Choose(5000, 75000).Select(x => (decimal)x);
                case "Mortgage":
                    return Gen.Choose(50000, 500000).Select(x => (decimal)x);
                case "Business":
                    return Gen.Choose(10000, 250000).Select(x => (decimal)x);
                default:
                    return Gen.Choose(1000, 50000).Select(x => (decimal)x);
            }
        }

        /// <summary>
        /// Generates a LoanApplication with a specific loan type.
        /// </summary>
        public static Arbitrary<LoanApplication> LoanApplicationOfType(string loanType)
        {
            return Arb.From(
                from application in ValidLoanApplication().Generator
                from requestedAmount in GenerateLoanAmountForType(loanType)
                select new LoanApplication
                {
                    ApplicationId = application.ApplicationId,
                    ApplicationNumber = application.ApplicationNumber,
                    CustomerId = application.CustomerId,
                    LoanType = loanType,
                    RequestedAmount = requestedAmount,
                    TermMonths = application.TermMonths,
                    Purpose = application.Purpose,
                    Status = application.Status,
                    ApplicationDate = application.ApplicationDate
                });
        }

        #endregion

        #region Interest Rate Generators

        /// <summary>
        /// Generates a valid InterestRate with appropriate constraints:
        /// - Credit score ranges: 300-850 (non-overlapping ranges)
        /// - Term ranges: 12-360 months
        /// - Rate: 3.0% - 25.0%
        /// - Effective date: within last year
        /// </summary>
        public static Arbitrary<InterestRate> ValidInterestRate()
        {
            return Arb.From(
                from loanType in Gen.Elements("Personal", "Auto", "Mortgage", "Business")
                from minCreditScore in Gen.Choose(300, 750).Select(x => (x / 50) * 50) // Round to nearest 50
                from creditScoreRange in Gen.Choose(50, 150)
                from minTermMonths in Gen.Choose(12, 300).Select(x => (x / 12) * 12) // Round to nearest 12
                from termRange in Gen.Choose(12, 120)
                from rate in Gen.Choose(300, 2500).Select(x => (decimal)x / 100) // 3.00% to 25.00%
                from daysAgo in Gen.Choose(0, 365)
                select new InterestRate
                {
                    LoanType = loanType,
                    MinCreditScore = minCreditScore,
                    MaxCreditScore = Math.Min(850, minCreditScore + creditScoreRange),
                    MinTermMonths = minTermMonths,
                    MaxTermMonths = Math.Min(360, minTermMonths + termRange),
                    Rate = rate,
                    EffectiveDate = DateTime.Now.AddDays(-daysAgo).Date,
                    ExpirationDate = null
                });
        }

        /// <summary>
        /// Generates an InterestRate for a specific loan type and credit score range.
        /// </summary>
        public static Arbitrary<InterestRate> InterestRateForTypeAndScore(string loanType, int minScore, int maxScore)
        {
            return Arb.From(
                from rate in ValidInterestRate().Generator
                from actualRate in Gen.Choose(300, 2500).Select(x => (decimal)x / 100)
                select new InterestRate
                {
                    RateId = rate.RateId,
                    LoanType = loanType,
                    MinCreditScore = minScore,
                    MaxCreditScore = maxScore,
                    MinTermMonths = rate.MinTermMonths,
                    MaxTermMonths = rate.MaxTermMonths,
                    Rate = actualRate,
                    EffectiveDate = rate.EffectiveDate,
                    ExpirationDate = rate.ExpirationDate
                });
        }

        #endregion

        #region Loan Decision Generators

        /// <summary>
        /// Generates a valid LoanDecision with appropriate constraints.
        /// </summary>
        public static Arbitrary<LoanDecision> ValidLoanDecision()
        {
            return Arb.From(
                from applicationId in Gen.Choose(1, 1000)
                from decision in Gen.Elements("Approved", "Rejected")
                from decisionBy in Gen.Elements("John Underwriter", "Jane Analyst", "Mike Manager", "Sarah Director")
                from riskScore in Gen.Choose(0, 100)
                from debtToIncomeRatio in Gen.Choose(0, 100).Select(x => (decimal)x)
                from interestRate in Gen.Choose(300, 2500).Select(x => (decimal)x / 100)
                from approvedAmount in Gen.Choose(1000, 500000).Select(x => (decimal)x)
                from comments in Gen.Elements(
                    "Good credit history",
                    "Stable income",
                    "High debt-to-income ratio",
                    "Insufficient income",
                    "Excellent credit score",
                    "Manual review required")
                select new LoanDecision
                {
                    ApplicationId = applicationId,
                    Decision = decision,
                    DecisionBy = decisionBy,
                    DecisionDate = DateTime.Now,
                    Comments = comments,
                    ApprovedAmount = decision == "Approved" ? (decimal?)approvedAmount : null,
                    InterestRate = decision == "Approved" ? (decimal?)interestRate : null,
                    RiskScore = riskScore,
                    DebtToIncomeRatio = debtToIncomeRatio
                });
        }

        #endregion

        #region Payment Schedule Generators

        /// <summary>
        /// Generates valid payment schedule parameters for testing amortization calculations.
        /// </summary>
        public static Arbitrary<(decimal loanAmount, decimal interestRate, int termMonths)> ValidPaymentScheduleParameters()
        {
            return Arb.From(
                from loanAmount in Gen.Choose(1000, 500000).Select(x => (decimal)x)
                from interestRate in Gen.Choose(100, 2500).Select(x => (decimal)x / 100) // 1.00% to 25.00%
                from termMonths in Gen.Choose(12, 360)
                select (loanAmount, interestRate, termMonths));
        }

        /// <summary>
        /// Generates a valid PaymentSchedule entry.
        /// </summary>
        public static Arbitrary<PaymentSchedule> ValidPaymentSchedule()
        {
            return Arb.From(
                from applicationId in Gen.Choose(1, 1000)
                from paymentNumber in Gen.Choose(1, 360)
                from paymentAmount in Gen.Choose(100, 10000).Select(x => (decimal)x)
                from principalAmount in Gen.Choose(50, 9000).Select(x => (decimal)x)
                from interestAmount in Gen.Choose(10, 1000).Select(x => (decimal)x)
                from remainingBalance in Gen.Choose(0, 500000).Select(x => (decimal)x)
                select new PaymentSchedule
                {
                    ApplicationId = applicationId,
                    PaymentNumber = paymentNumber,
                    DueDate = DateTime.Now.AddMonths(paymentNumber),
                    PaymentAmount = paymentAmount,
                    PrincipalAmount = principalAmount,
                    InterestAmount = interestAmount,
                    RemainingBalance = remainingBalance
                });
        }

        #endregion

        #region Helper Methods

        /// <summary>
        /// Generates a random date within a specified range.
        /// </summary>
        public static Gen<DateTime> DateBetween(DateTime start, DateTime end)
        {
            int daysDiff = (end - start).Days;
            return Gen.Choose(0, daysDiff).Select(days => start.AddDays(days));
        }

        /// <summary>
        /// Generates a positive decimal value within a range.
        /// </summary>
        public static Gen<decimal> DecimalBetween(decimal min, decimal max)
        {
            return Gen.Choose((int)(min * 100), (int)(max * 100))
                .Select(x => (decimal)x / 100);
        }

        #endregion
    }
}
