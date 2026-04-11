using System;
using System.Collections.Generic;
using System.Diagnostics;
using LoanProcessing.Web.Models;
using LoanProcessing.Web.Services;
using LoanProcessing.Web.Validation.Helpers;
using LoanProcessing.Web.Validation.Models;

namespace LoanProcessing.Web.Validation.Tests
{
    public class CreditEvaluationTests : IValidationTestCategory
    {
        private readonly ILoanService _loanService;
        private readonly ICustomerService _customerService;
        private readonly TestDataCleanup _cleanup;
        private readonly CustomerBusinessTests _customerTests;
        private readonly DatabaseHelper _db;
        private readonly List<ShadowComparisonResult> _shadowComparisonResults = new List<ShadowComparisonResult>();

        public string CategoryName { get { return "BusinessLogic"; } }
        public List<ShadowComparisonResult> ShadowComparisonResults { get { return _shadowComparisonResults; } }

        private static readonly List<ShadowTestProfile> ShadowProfiles = new List<ShadowTestProfile>
        {
            new ShadowTestProfile
            {
                ScenarioName = "High Credit No Debt",
                CreditScore = 780, AnnualIncome = 120000m,
                LoanType = "Personal", RequestedAmount = 30000m, TermMonths = 36,
                ExpectedRecommendationCategory = "Approval"
            },
            new ShadowTestProfile
            {
                ScenarioName = "Low Credit High Amount",
                CreditScore = 550, AnnualIncome = 35000m,
                LoanType = "Personal", RequestedAmount = 50000m, TermMonths = 60,
                ExpectedRecommendationCategory = "Rejection"
            },
            new ShadowTestProfile
            {
                ScenarioName = "Borderline DTI 35%",
                CreditScore = 700, AnnualIncome = 80000m,
                LoanType = "Personal", RequestedAmount = 28000m, TermMonths = 36,
                ExpectedRecommendationCategory = "Review"
            },
            new ShadowTestProfile
            {
                ScenarioName = "Existing Approved Loans",
                CreditScore = 720, AnnualIncome = 90000m,
                LoanType = "Personal", RequestedAmount = 20000m, TermMonths = 36,
                ExpectedRecommendationCategory = "Depends"
            },
            new ShadowTestProfile
            {
                ScenarioName = "Auto Loan Rate Lookup",
                CreditScore = 680, AnnualIncome = 70000m,
                LoanType = "Auto", RequestedAmount = 25000m, TermMonths = 48,
                ExpectedRecommendationCategory = "Review"
            }
        };

        public CreditEvaluationTests(ILoanService loanService, ICustomerService customerService, TestDataCleanup cleanup, CustomerBusinessTests customerTests, DatabaseHelper databaseHelper = null)
        {
            _loanService = loanService;
            _customerService = customerService;
            _cleanup = cleanup;
            _customerTests = customerTests;
            _db = databaseHelper;
        }

        public List<TestResult> Run(ModernizationStage stage)
        {
            _shadowComparisonResults.Clear();
            var results = new List<TestResult>();
            results.Add(TestHighCreditScore(stage));
            results.Add(TestLowCreditScore(stage));
            results.Add(TestDebtToIncomeRatio(stage));

            // Boundary tests — verify exact threshold behavior
            results.Add(TestCreditScoreBoundaries(stage));
            results.Add(TestRecommendationBoundaries(stage));

            // Shadow tests — compare SP vs C# on same input (PreModernization only)
            if (stage == ModernizationStage.PreModernization && _db != null && !_db.IsPostgreSQL)
            {
                results.AddRange(RunAllShadowComparisons(stage));
            }

            // Final cleanup of all test data
            _cleanup.CleanupBySSNPrefix("999-");
            return results;
        }

        private void UpdateCustomerScore(int customerId, int creditScore, decimal annualIncome)
        {
            var customer = _customerService.GetById(customerId);
            customer.CreditScore = creditScore;
            customer.AnnualIncome = annualIncome;
            _customerService.UpdateCustomer(customer);
        }

        private TestResult TestHighCreditScore(ModernizationStage stage)
        {
            var sw = Stopwatch.StartNew();
            try
            {
                int customerId = _customerTests.LastCreatedCustomerId;
                if (customerId <= 0) return Fail(sw, "High Credit Score Risk Assessment", "Evaluates credit for a high credit score customer", "RiskScore < 40", "Create Customer test must pass first", stage);

                // Customer already has CreditScore=780 from the Update test
                var app = new LoanApplication { CustomerId = customerId, LoanType = "Personal", RequestedAmount = 30000m, TermMonths = 36, Purpose = "Validation - high credit score" };
                int appId = _loanService.SubmitLoanApplication(app);
                LoanDecision decision = _loanService.EvaluateCredit(appId);
                sw.Stop();

                if (decision == null || !decision.RiskScore.HasValue)
                    return Fail(sw, "High Credit Score Risk Assessment", "Evaluates credit for a high credit score customer", "RiskScore <= 40", "RiskScore is null", stage);

                bool passed = decision.RiskScore.Value <= 40;
                return new TestResult { TestName = "High Credit Score Risk Assessment", Category = CategoryName, Description = "Evaluates credit for a customer with a high credit score (780) and verifies the risk score is at or below 40, confirming low-risk classification", Passed = passed, Expected = "RiskScore <= 40", Actual = "RiskScore = " + decision.RiskScore.Value, WhatToCheck = passed ? string.Empty : GetHint(stage), Duration = sw.Elapsed };
            }
            catch (Exception ex) { sw.Stop(); return Fail(sw, "High Credit Score Risk Assessment", "Evaluates credit for a high credit score customer", "RiskScore < 40", "Exception: " + ex.Message, stage); }
        }

        private TestResult TestLowCreditScore(ModernizationStage stage)
        {
            var sw = Stopwatch.StartNew();
            try
            {
                int customerId = _customerTests.LastCreatedCustomerId;
                if (customerId <= 0) return Fail(sw, "Low Credit Score Risk Assessment", "Evaluates credit for a low credit score customer", "RiskScore > 60", "Create Customer test must pass first", stage);

                // Update to low credit score
                UpdateCustomerScore(customerId, 550, 35000m);

                var app = new LoanApplication { CustomerId = customerId, LoanType = "Personal", RequestedAmount = 15000m, TermMonths = 24, Purpose = "Validation - low credit score" };
                int appId = _loanService.SubmitLoanApplication(app);
                LoanDecision decision = _loanService.EvaluateCredit(appId);
                sw.Stop();

                if (decision == null || !decision.RiskScore.HasValue)
                    return Fail(sw, "Low Credit Score Risk Assessment", "Evaluates credit for a low credit score customer", "RiskScore > 60", "RiskScore is null", stage);

                bool passed = decision.RiskScore.Value > 60;
                return new TestResult { TestName = "Low Credit Score Risk Assessment", Category = CategoryName, Description = "Evaluates credit for a customer with a low credit score (550) and verifies the risk score is above 60, confirming high-risk classification", Passed = passed, Expected = "RiskScore > 60", Actual = "RiskScore = " + decision.RiskScore.Value, WhatToCheck = passed ? string.Empty : GetHint(stage), Duration = sw.Elapsed };
            }
            catch (Exception ex) { sw.Stop(); return Fail(sw, "Low Credit Score Risk Assessment", "Evaluates credit for a low credit score customer", "RiskScore > 60", "Exception: " + ex.Message, stage); }
        }

        private TestResult TestDebtToIncomeRatio(ModernizationStage stage)
        {
            var sw = Stopwatch.StartNew();
            try
            {
                int customerId = _customerTests.LastCreatedCustomerId;
                if (customerId <= 0) return Fail(sw, "Debt-to-Income Ratio Calculation", "Evaluates credit with existing loans", "DebtToIncomeRatio > 0", "Create Customer test must pass first", stage);

                // Update to moderate credit score for DTI test
                UpdateCustomerScore(customerId, 700, 80000m);

                // Customer already has approved loans from earlier tests — DTI should be calculated
                var loan = new LoanApplication { CustomerId = customerId, LoanType = "Personal", RequestedAmount = 15000m, TermMonths = 24, Purpose = "Validation - DTI evaluation" };
                int loanId = _loanService.SubmitLoanApplication(loan);
                LoanDecision decision = _loanService.EvaluateCredit(loanId);
                sw.Stop();

                if (decision == null)
                    return Fail(sw, "Debt-to-Income Ratio Calculation", "Evaluates credit with existing approved loans and verifies DTI is calculated", "DebtToIncomeRatio > 0", "LoanDecision is null", stage);

                if (!decision.DebtToIncomeRatio.HasValue)
                    return Fail(sw, "Debt-to-Income Ratio Calculation", "Evaluates credit with existing approved loans and verifies DTI is calculated", "DebtToIncomeRatio > 0", "DebtToIncomeRatio is null", stage);

                bool passed = decision.DebtToIncomeRatio.Value > 0;
                return new TestResult { TestName = "Debt-to-Income Ratio Calculation", Category = CategoryName, Description = "Evaluates credit for a customer with an existing approved loan and verifies the debt-to-income ratio is calculated and included in the decision", Passed = passed, Expected = "DebtToIncomeRatio > 0", Actual = "DebtToIncomeRatio = " + decision.DebtToIncomeRatio.Value, WhatToCheck = passed ? string.Empty : GetHint(stage), Duration = sw.Elapsed };
            }
            catch (Exception ex) { sw.Stop(); return Fail(sw, "Debt-to-Income Ratio Calculation", "Evaluates credit with existing loans", "DebtToIncomeRatio > 0", "Exception: " + ex.Message, stage); }
        }

        private TestResult TestCreditScoreBoundaries(ModernizationStage stage)
        {
            var sw = Stopwatch.StartNew();
            try
            {
                // Test exact boundary values for credit score component
                var issues = new List<string>();

                // 750 boundary: should yield component 10
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(750) != 10)
                    issues.Add("CreditScore=750 expected component 10, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(750));
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(749) != 20)
                    issues.Add("CreditScore=749 expected component 20, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(749));

                // 700 boundary
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(700) != 20)
                    issues.Add("CreditScore=700 expected component 20, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(700));
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(699) != 35)
                    issues.Add("CreditScore=699 expected component 35, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(699));

                // 650 boundary
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(650) != 35)
                    issues.Add("CreditScore=650 expected component 35, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(650));
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(649) != 50)
                    issues.Add("CreditScore=649 expected component 50, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(649));

                // 600 boundary
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(600) != 50)
                    issues.Add("CreditScore=600 expected component 50, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(600));
                if (CreditEvaluationCalculator.CalculateCreditScoreComponent(599) != 75)
                    issues.Add("CreditScore=599 expected component 75, got " + CreditEvaluationCalculator.CalculateCreditScoreComponent(599));

                // DTI boundaries
                if (CreditEvaluationCalculator.CalculateDtiComponent(20.00m) != 0)
                    issues.Add("DTI=20.00 expected component 0, got " + CreditEvaluationCalculator.CalculateDtiComponent(20.00m));
                if (CreditEvaluationCalculator.CalculateDtiComponent(20.01m) != 10)
                    issues.Add("DTI=20.01 expected component 10, got " + CreditEvaluationCalculator.CalculateDtiComponent(20.01m));
                if (CreditEvaluationCalculator.CalculateDtiComponent(35.00m) != 10)
                    issues.Add("DTI=35.00 expected component 10, got " + CreditEvaluationCalculator.CalculateDtiComponent(35.00m));
                if (CreditEvaluationCalculator.CalculateDtiComponent(35.01m) != 20)
                    issues.Add("DTI=35.01 expected component 20, got " + CreditEvaluationCalculator.CalculateDtiComponent(35.01m));
                if (CreditEvaluationCalculator.CalculateDtiComponent(43.00m) != 20)
                    issues.Add("DTI=43.00 expected component 20, got " + CreditEvaluationCalculator.CalculateDtiComponent(43.00m));
                if (CreditEvaluationCalculator.CalculateDtiComponent(43.01m) != 30)
                    issues.Add("DTI=43.01 expected component 30, got " + CreditEvaluationCalculator.CalculateDtiComponent(43.01m));

                sw.Stop();
                bool passed = issues.Count == 0;
                return new TestResult
                {
                    TestName = "Credit Score & DTI Boundary Values",
                    Category = CategoryName,
                    Description = "Tests exact boundary values for credit score brackets (750/749, 700/699, 650/649, 600/599) and DTI brackets (20.00/20.01, 35.00/35.01, 43.00/43.01) to verify threshold behavior",
                    Passed = passed,
                    Expected = "All 14 boundary checks pass",
                    Actual = passed ? "All 14 boundary checks pass" : string.Join("; ", issues),
                    WhatToCheck = passed ? string.Empty : GetHint(stage),
                    Duration = sw.Elapsed
                };
            }
            catch (Exception ex) { sw.Stop(); return Fail(sw, "Credit Score & DTI Boundary Values", "Tests boundary values for scoring brackets", "All boundaries correct", "Exception: " + ex.Message, stage); }
        }

        private TestResult TestRecommendationBoundaries(ModernizationStage stage)
        {
            var sw = Stopwatch.StartNew();
            try
            {
                var issues = new List<string>();

                // Approval boundary: RiskScore=30, DTI=35 → Approved
                string rec = CreditEvaluationCalculator.DetermineRecommendation(30, 35.00m);
                if (rec != "Recommended for Approval")
                    issues.Add("RiskScore=30,DTI=35.00 expected 'Recommended for Approval', got '" + rec + "'");

                // Just over approval → Manual Review: RiskScore=31, DTI=35
                rec = CreditEvaluationCalculator.DetermineRecommendation(31, 35.00m);
                if (rec != "Manual Review Required")
                    issues.Add("RiskScore=31,DTI=35.00 expected 'Manual Review Required', got '" + rec + "'");

                // Approval DTI boundary: RiskScore=30, DTI=35.01 → Manual Review
                rec = CreditEvaluationCalculator.DetermineRecommendation(30, 35.01m);
                if (rec != "Manual Review Required")
                    issues.Add("RiskScore=30,DTI=35.01 expected 'Manual Review Required', got '" + rec + "'");

                // Manual Review boundary: RiskScore=50, DTI=43 → Manual Review
                rec = CreditEvaluationCalculator.DetermineRecommendation(50, 43.00m);
                if (rec != "Manual Review Required")
                    issues.Add("RiskScore=50,DTI=43.00 expected 'Manual Review Required', got '" + rec + "'");

                // Just over Manual Review → Rejection: RiskScore=51, DTI=43
                rec = CreditEvaluationCalculator.DetermineRecommendation(51, 43.00m);
                if (rec != "High Risk - Recommend Rejection")
                    issues.Add("RiskScore=51,DTI=43.00 expected 'High Risk - Recommend Rejection', got '" + rec + "'");

                // Manual Review DTI boundary: RiskScore=50, DTI=43.01 → Rejection
                rec = CreditEvaluationCalculator.DetermineRecommendation(50, 43.01m);
                if (rec != "High Risk - Recommend Rejection")
                    issues.Add("RiskScore=50,DTI=43.01 expected 'High Risk - Recommend Rejection', got '" + rec + "'");

                sw.Stop();
                bool passed = issues.Count == 0;
                return new TestResult
                {
                    TestName = "Recommendation Threshold Boundaries",
                    Category = CategoryName,
                    Description = "Tests exact boundary values for recommendation classification: Approval (RiskScore≤30 AND DTI≤35), Manual Review (RiskScore≤50 AND DTI≤43), and Rejection thresholds",
                    Passed = passed,
                    Expected = "All 6 recommendation boundary checks pass",
                    Actual = passed ? "All 6 recommendation boundary checks pass" : string.Join("; ", issues),
                    WhatToCheck = passed ? string.Empty : GetHint(stage),
                    Duration = sw.Elapsed
                };
            }
            catch (Exception ex) { sw.Stop(); return Fail(sw, "Recommendation Threshold Boundaries", "Tests recommendation boundary values", "All boundaries correct", "Exception: " + ex.Message, stage); }
        }

        private List<TestResult> RunAllShadowComparisons(ModernizationStage stage)
        {
            var results = new List<TestResult>();

            // Pre-clean orphaned 999- data from a previous run
            _cleanup.CleanupBySSNPrefix("999-");

            int passed = 0;
            int total = ShadowProfiles.Count;
            var overallSw = Stopwatch.StartNew();

            for (int i = 0; i < ShadowProfiles.Count; i++)
            {
                var profile = ShadowProfiles[i];
                try
                {
                    var result = RunShadowComparisonForProfile(profile, stage, i);
                    results.Add(result);
                    if (result.Passed) passed++;
                }
                catch (Exception ex)
                {
                    var sw = Stopwatch.StartNew();
                    sw.Stop();
                    results.Add(Fail(sw, "Shadow: " + profile.ScenarioName, "Shadow comparison for " + profile.ScenarioName, "SP and Service produce identical outputs", "Exception: " + ex.Message, stage));
                    _shadowComparisonResults.Add(new ShadowComparisonResult
                    {
                        ScenarioName = profile.ScenarioName,
                        AllMatch = false
                    });
                }
            }

            overallSw.Stop();

            // Append summary TestResult
            bool allPassed = passed == total;
            results.Add(new TestResult
            {
                TestName = "Shadow Comparison Summary",
                Category = CategoryName,
                Description = "Summary of all " + total + " shadow comparison profiles: SP vs Service equivalence",
                Passed = allPassed,
                Expected = total + "/" + total + " profiles match",
                Actual = passed + "/" + total + " profiles match",
                WhatToCheck = allPassed ? string.Empty : "One or more shadow profiles showed divergence between SP and service. Check individual profile results above.",
                Duration = overallSw.Elapsed
            });

            return results;
        }

        private TestResult RunShadowComparisonForProfile(ShadowTestProfile profile, ModernizationStage stage, int profileIndex)
        {
            var sw = Stopwatch.StartNew();
            try
            {
                // Step 1: Create a fresh test customer with unique SSN
                string ssn = "999-00-000" + (profileIndex + 1);
                var customer = new Customer
                {
                    FirstName = "Shadow",
                    LastName = profile.ScenarioName,
                    SSN = ssn,
                    CreditScore = profile.CreditScore,
                    AnnualIncome = profile.AnnualIncome,
                    DateOfBirth = new DateTime(1985, 6, 15),
                    Email = "shadow" + (profileIndex + 1) + "@test.com",
                    Phone = "555-000-000" + (profileIndex + 1),
                    Address = "1 Shadow Test Lane"
                };
                int customerId = _customerService.CreateCustomer(customer);

                // Step 2: For Profile 4 ("Existing Approved Loans"), submit and approve a preliminary loan first
                if (profile.ScenarioName == "Existing Approved Loans")
                {
                    var prelimApp = new LoanApplication
                    {
                        CustomerId = customerId,
                        LoanType = "Personal",
                        RequestedAmount = 15000m,
                        TermMonths = 24,
                        Purpose = "Shadow comparison - preliminary loan for existing debt"
                    };
                    int prelimAppId = _loanService.SubmitLoanApplication(prelimApp);
                    _loanService.EvaluateCredit(prelimAppId);
                    _loanService.ProcessLoanDecision(prelimAppId, "Approved", "Preliminary loan for shadow test", "ValidationSystem");
                }

                // Step 3: Submit the loan application for shadow comparison
                var app = new LoanApplication
                {
                    CustomerId = customerId,
                    LoanType = profile.LoanType,
                    RequestedAmount = profile.RequestedAmount,
                    TermMonths = profile.TermMonths,
                    Purpose = "Shadow comparison - " + profile.ScenarioName
                };
                int appId = _loanService.SubmitLoanApplication(app);

                // Step 4: Call sp_EvaluateCredit directly via SqlCommand
                LoanDecision spResult = CallStoredProcedureDirectly(appId);

                // Step 5: Reset application state
                ResetApplicationState(appId);

                // Step 6: Call CreditEvaluationService via the normal service path
                LoanDecision svcResult = _loanService.EvaluateCredit(appId);

                sw.Stop();

                if (spResult == null)
                {
                    _shadowComparisonResults.Add(new ShadowComparisonResult
                    {
                        ScenarioName = profile.ScenarioName,
                        SvcRiskScore = svcResult != null ? svcResult.RiskScore : null,
                        SvcDti = svcResult != null ? svcResult.DebtToIncomeRatio : null,
                        SvcInterestRate = svcResult != null ? svcResult.InterestRate : null,
                        SvcRecommendation = svcResult != null ? svcResult.Comments : null,
                        AllMatch = false
                    });
                    return Fail(sw, "Shadow: " + profile.ScenarioName, "Shadow comparison for " + profile.ScenarioName, "SP returns result", "SP returned null", stage);
                }

                // Step 7: Compare the four values
                var mismatches = new List<string>();
                if (spResult.RiskScore != svcResult.RiskScore)
                    mismatches.Add("RiskScore: SP=" + spResult.RiskScore + " vs Svc=" + svcResult.RiskScore);
                if (spResult.DebtToIncomeRatio != svcResult.DebtToIncomeRatio)
                    mismatches.Add("DTI: SP=" + spResult.DebtToIncomeRatio + " vs Svc=" + svcResult.DebtToIncomeRatio);
                if (spResult.InterestRate != svcResult.InterestRate)
                    mismatches.Add("Rate: SP=" + spResult.InterestRate + " vs Svc=" + svcResult.InterestRate);
                if (spResult.Comments != svcResult.Comments)
                    mismatches.Add("Rec: SP='" + spResult.Comments + "' vs Svc='" + svcResult.Comments + "'");

                bool passed = mismatches.Count == 0;

                // Step 8: Store comparison result for view rendering
                _shadowComparisonResults.Add(new ShadowComparisonResult
                {
                    ScenarioName = profile.ScenarioName,
                    SpRiskScore = spResult.RiskScore,
                    SvcRiskScore = svcResult.RiskScore,
                    SpDti = spResult.DebtToIncomeRatio,
                    SvcDti = svcResult.DebtToIncomeRatio,
                    SpInterestRate = spResult.InterestRate,
                    SvcInterestRate = svcResult.InterestRate,
                    SpRecommendation = spResult.Comments,
                    SvcRecommendation = svcResult.Comments,
                    AllMatch = passed
                });

                string actual = passed
                    ? "RiskScore=" + svcResult.RiskScore + ", DTI=" + svcResult.DebtToIncomeRatio + ", Rate=" + svcResult.InterestRate + ", Rec='" + svcResult.Comments + "'"
                    : string.Join("; ", mismatches);

                return new TestResult
                {
                    TestName = "Shadow: " + profile.ScenarioName,
                    Category = CategoryName,
                    Description = "Runs both sp_EvaluateCredit and CreditEvaluationService on the same loan application (" + profile.ScenarioName + ") and compares RiskScore, DTI, InterestRate, and Recommendation",
                    Passed = passed,
                    Expected = "SP and Service produce identical outputs",
                    Actual = actual,
                    WhatToCheck = passed ? string.Empty : "The stored procedure and C# service produced different results for " + profile.ScenarioName + ". Check the extraction logic in CreditEvaluationCalculator and CreditEvaluationService.",
                    Duration = sw.Elapsed
                };
            }
            catch (Exception ex)
            {
                sw.Stop();
                _shadowComparisonResults.Add(new ShadowComparisonResult
                {
                    ScenarioName = profile.ScenarioName,
                    AllMatch = false
                });
                return Fail(sw, "Shadow: " + profile.ScenarioName, "Shadow comparison for " + profile.ScenarioName, "SP and Service produce identical outputs", "Exception: " + ex.Message, stage);
            }
        }

        private void ResetApplicationState(int appId)
        {
            using (var connection = new System.Data.SqlClient.SqlConnection(GetConnectionString()))
            {
                connection.Open();
                using (var cmd = new System.Data.SqlClient.SqlCommand(
                    "DELETE FROM LoanDecisions WHERE ApplicationId = @AppId", connection))
                {
                    cmd.Parameters.AddWithValue("@AppId", appId);
                    cmd.ExecuteNonQuery();
                }
                using (var cmd = new System.Data.SqlClient.SqlCommand(
                    "UPDATE LoanApplications SET Status = 'Pending', InterestRate = NULL WHERE ApplicationId = @AppId", connection))
                {
                    cmd.Parameters.AddWithValue("@AppId", appId);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private LoanDecision CallStoredProcedureDirectly(int appId)
        {
            using (var connection = new System.Data.SqlClient.SqlConnection(GetConnectionString()))
            {
                connection.Open();
                using (var command = new System.Data.SqlClient.SqlCommand("sp_EvaluateCredit", connection))
                {
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.AddWithValue("@ApplicationId", appId);
                    using (var reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new LoanDecision
                            {
                                ApplicationId = reader.GetInt32(reader.GetOrdinal("ApplicationId")),
                                RiskScore = reader.IsDBNull(reader.GetOrdinal("RiskScore")) ? (int?)null : reader.GetInt32(reader.GetOrdinal("RiskScore")),
                                DebtToIncomeRatio = reader.IsDBNull(reader.GetOrdinal("DebtToIncomeRatio")) ? (decimal?)null : reader.GetDecimal(reader.GetOrdinal("DebtToIncomeRatio")),
                                InterestRate = reader.IsDBNull(reader.GetOrdinal("InterestRate")) ? (decimal?)null : reader.GetDecimal(reader.GetOrdinal("InterestRate")),
                                Comments = reader.GetString(reader.GetOrdinal("Recommendation"))
                            };
                        }
                    }
                }
            }
            return null;
        }

        private string GetConnectionString()
        {
            return System.Configuration.ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString;
        }

        private TestResult Fail(Stopwatch sw, string name, string desc, string expected, string actual, ModernizationStage stage)
        {
            return new TestResult { TestName = name, Category = CategoryName, Description = desc, Passed = false, Expected = expected, Actual = actual, WhatToCheck = GetHint(stage), Duration = sw.Elapsed };
        }

        private static string GetHint(ModernizationStage stage)
        {
            switch (stage)
            {
                case ModernizationStage.PreModernization: return "Check that SQL Server stored procedures for credit evaluation are accessible and return correct risk scores";
                case ModernizationStage.PostModule1: return "Check that credit evaluation logic works with Aurora PostgreSQL";
                case ModernizationStage.PostModule2: return "Check that credit evaluation business rules were correctly ported to the .NET 8 service layer";
                case ModernizationStage.PostModule3: return "Check that the container can reach Aurora PostgreSQL and credit evaluation services are functioning";
                default: return "Check that the credit evaluation service and database connection are configured correctly";
            }
        }
    }
}
