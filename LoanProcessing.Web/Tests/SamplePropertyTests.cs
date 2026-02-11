using System;
using FsCheck;
using LoanProcessing.Web.Models;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LoanProcessing.Web.Tests
{
    /// <summary>
    /// Sample property-based tests demonstrating FSCheck setup and usage.
    /// These tests validate that the generators produce valid data and demonstrate
    /// the property testing approach for the loan processing application.
    /// </summary>
    [TestClass]
    public class SamplePropertyTests : PropertyTestBase
    {
        /// <summary>
        /// Sample Property Test 1: Customer Generator Validity
        /// Validates that all generated customers satisfy business constraints.
        /// This is a meta-test that ensures our generators are working correctly.
        /// </summary>
        [TestMethod]
        [TestCategory("PropertyTest")]
        [TestCategory("Generator")]
        [Description("Validates that customer generator produces valid customers")]
        public void Property_CustomerGenerator_ProducesValidCustomers()
        {
            // Property: All generated customers must satisfy business constraints
            var property = Prop.ForAll(
                PropertyTestGenerators.ValidCustomer(),
                customer =>
                {
                    // Credit score must be between 300 and 850
                    var validCreditScore = InRange(customer.CreditScore, 300, 850);

                    // Age must be 18 or older
                    var age = DateTime.Now.Year - customer.DateOfBirth.Year;
                    var validAge = age >= 18 && age <= 100;

                    // Annual income must be positive
                    var validIncome = customer.AnnualIncome > 0;

                    // SSN must be in correct format (###-##-####)
                    var validSSN = !string.IsNullOrEmpty(customer.SSN) &&
                                   customer.SSN.Length == 11 &&
                                   customer.SSN[3] == '-' &&
                                   customer.SSN[6] == '-';

                    // Email must not be empty
                    var validEmail = !string.IsNullOrEmpty(customer.Email);

                    // All constraints must be satisfied
                    return validCreditScore && validAge && validIncome && validSSN && validEmail;
                });

            CheckProperty(property, "Customer Generator Validity");
        }

        /// <summary>
        /// Sample Property Test 2: Loan Application Generator Validity
        /// Validates that all generated loan applications satisfy business constraints.
        /// </summary>
        [TestMethod]
        [TestCategory("PropertyTest")]
        [TestCategory("Generator")]
        [Description("Validates that loan application generator produces valid applications")]
        public void Property_LoanApplicationGenerator_ProducesValidApplications()
        {
            // Property: All generated loan applications must satisfy business constraints
            var property = Prop.ForAll(
                PropertyTestGenerators.ValidLoanApplication(),
                application =>
                {
                    // Loan amount must be positive
                    var validAmount = application.RequestedAmount > 0;

                    // Term must be between 12 and 360 months
                    var validTerm = InRange(application.TermMonths, 12, 360);

                    // Loan type must be one of the valid types
                    var validType = application.LoanType == "Personal" ||
                                    application.LoanType == "Auto" ||
                                    application.LoanType == "Mortgage" ||
                                    application.LoanType == "Business";

                    // Amount must be within limits for loan type
                    var validAmountForType = true;
                    switch (application.LoanType)
                    {
                        case "Personal":
                            validAmountForType = application.RequestedAmount <= 50000;
                            break;
                        case "Auto":
                            validAmountForType = application.RequestedAmount <= 75000;
                            break;
                        case "Mortgage":
                            validAmountForType = application.RequestedAmount <= 500000;
                            break;
                        case "Business":
                            validAmountForType = application.RequestedAmount <= 250000;
                            break;
                    }

                    // Purpose must not be empty
                    var validPurpose = !string.IsNullOrEmpty(application.Purpose);

                    // All constraints must be satisfied
                    return validAmount && validTerm && validType && validAmountForType && validPurpose;
                });

            CheckProperty(property, "Loan Application Generator Validity");
        }

        /// <summary>
        /// Sample Property Test 3: Interest Rate Generator Validity
        /// Validates that all generated interest rates satisfy business constraints.
        /// </summary>
        [TestMethod]
        [TestCategory("PropertyTest")]
        [TestCategory("Generator")]
        [Description("Validates that interest rate generator produces valid rates")]
        public void Property_InterestRateGenerator_ProducesValidRates()
        {
            // Property: All generated interest rates must satisfy business constraints
            var property = Prop.ForAll(
                PropertyTestGenerators.ValidInterestRate(),
                rate =>
                {
                    // Credit score range must be valid
                    var validCreditScoreRange = rate.MinCreditScore >= 300 &&
                                                rate.MaxCreditScore <= 850 &&
                                                rate.MinCreditScore <= rate.MaxCreditScore;

                    // Term range must be valid
                    var validTermRange = rate.MinTermMonths >= 12 &&
                                         rate.MaxTermMonths <= 360 &&
                                         rate.MinTermMonths <= rate.MaxTermMonths;

                    // Rate must be positive and reasonable
                    var validRate = rate.Rate > 0 && rate.Rate <= 30.0m;

                    // Loan type must be valid
                    var validType = rate.LoanType == "Personal" ||
                                    rate.LoanType == "Auto" ||
                                    rate.LoanType == "Mortgage" ||
                                    rate.LoanType == "Business";

                    // Effective date must not be in the future
                    var validEffectiveDate = rate.EffectiveDate <= DateTime.Now.Date;

                    // All constraints must be satisfied
                    return validCreditScoreRange && validTermRange && validRate && validType && validEffectiveDate;
                });

            CheckProperty(property, "Interest Rate Generator Validity");
        }

        /// <summary>
        /// Sample Property Test 4: Payment Schedule Parameters Validity
        /// Validates that generated payment schedule parameters are valid.
        /// </summary>
        [TestMethod]
        [TestCategory("PropertyTest")]
        [TestCategory("Generator")]
        [Description("Validates that payment schedule parameter generator produces valid parameters")]
        public void Property_PaymentScheduleParametersGenerator_ProducesValidParameters()
        {
            // Property: All generated payment schedule parameters must be valid
            var property = Prop.ForAll(
                PropertyTestGenerators.ValidPaymentScheduleParameters(),
                parameters =>
                {
                    var (loanAmount, interestRate, termMonths) = parameters;

                    // Loan amount must be positive
                    var validAmount = loanAmount > 0;

                    // Interest rate must be positive and reasonable
                    var validRate = interestRate > 0 && interestRate <= 30.0m;

                    // Term must be between 12 and 360 months
                    var validTerm = InRange(termMonths, 12, 360);

                    // All constraints must be satisfied
                    return validAmount && validRate && validTerm;
                });

            CheckProperty(property, "Payment Schedule Parameters Generator Validity");
        }

        /// <summary>
        /// Sample Property Test 5: Loan Decision Generator Validity
        /// Validates that generated loan decisions satisfy business constraints.
        /// </summary>
        [TestMethod]
        [TestCategory("PropertyTest")]
        [TestCategory("Generator")]
        [Description("Validates that loan decision generator produces valid decisions")]
        public void Property_LoanDecisionGenerator_ProducesValidDecisions()
        {
            // Property: All generated loan decisions must satisfy business constraints
            var property = Prop.ForAll(
                PropertyTestGenerators.ValidLoanDecision(),
                decision =>
                {
                    // Decision must be either Approved or Rejected
                    var validDecision = decision.Decision == "Approved" || decision.Decision == "Rejected";

                    // Risk score must be between 0 and 100
                    var validRiskScore = decision.RiskScore.HasValue &&
                                         InRange(decision.RiskScore.Value, 0, 100);

                    // Debt-to-income ratio must be non-negative
                    var validDTI = decision.DebtToIncomeRatio.HasValue &&
                                   decision.DebtToIncomeRatio.Value >= 0;

                    // If approved, must have approved amount and interest rate
                    var validApprovalData = decision.Decision != "Approved" ||
                                            (decision.ApprovedAmount.HasValue &&
                                             decision.ApprovedAmount.Value > 0 &&
                                             decision.InterestRate.HasValue &&
                                             decision.InterestRate.Value > 0);

                    // DecisionBy must not be empty
                    var validDecisionBy = !string.IsNullOrEmpty(decision.DecisionBy);

                    // All constraints must be satisfied
                    return validDecision && validRiskScore && validDTI && validApprovalData && validDecisionBy;
                });

            CheckProperty(property, "Loan Decision Generator Validity");
        }

        /// <summary>
        /// Sample Property Test 6: Customer Credit Score Range Generator
        /// Validates that the credit score range generator works correctly.
        /// </summary>
        [TestMethod]
        [TestCategory("PropertyTest")]
        [TestCategory("Generator")]
        [Description("Validates that credit score range generator produces customers in specified range")]
        public void Property_CustomerCreditScoreRangeGenerator_ProducesCustomersInRange()
        {
            // Test with excellent credit range (750-850)
            var property = Prop.ForAll(
                PropertyTestGenerators.CustomerWithCreditScore(750, 850),
                customer =>
                {
                    // Credit score must be in the specified range
                    return InRange(customer.CreditScore, 750, 850);
                });

            CheckProperty(property, "Customer Credit Score Range Generator");
        }

        /// <summary>
        /// Sample Property Test 7: Loan Type Specific Generator
        /// Validates that loan type specific generators work correctly.
        /// </summary>
        [TestMethod]
        [TestCategory("PropertyTest")]
        [TestCategory("Generator")]
        [Description("Validates that loan type specific generator produces correct loan type")]
        public void Property_LoanTypeSpecificGenerator_ProducesCorrectType()
        {
            // Test with Mortgage loans
            var property = Prop.ForAll(
                PropertyTestGenerators.LoanApplicationOfType("Mortgage"),
                application =>
                {
                    // Loan type must be Mortgage
                    var correctType = application.LoanType == "Mortgage";

                    // Amount must be within Mortgage limits
                    var validAmount = application.RequestedAmount >= 50000 &&
                                      application.RequestedAmount <= 500000;

                    return correctType && validAmount;
                });

            CheckProperty(property, "Loan Type Specific Generator");
        }
    }
}
