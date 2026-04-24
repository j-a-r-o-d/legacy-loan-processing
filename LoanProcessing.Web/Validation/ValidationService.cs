using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Web.Script.Serialization;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Services;
using LoanProcessing.Web.Validation.Helpers;
using LoanProcessing.Web.Validation.Models;
using LoanProcessing.Web.Validation.Tests;

namespace LoanProcessing.Web.Validation
{
    /// <summary>
    /// Orchestrates validation test execution across all categories.
    /// Uses the app's own services and database connection — zero external configuration.
    /// Thread-safe: only one test run executes at a time via a simple lock.
    /// </summary>
    public class ValidationService
    {
        private readonly string _connectionString;
        private readonly StageDetector _stageDetector;
        private readonly DatabaseHelper _databaseHelper;
        private readonly TestDataCleanup _cleanup;

        private readonly SmokeTests _smokeTests;
        private readonly DataIntegrityTests _dataIntegrityTests;
        private readonly CustomerBusinessTests _customerBusinessTests;
        private readonly LoanProcessingTests _loanProcessingTests;
        private readonly CreditEvaluationTests _creditEvaluationTests;

        private readonly object _runLock = new object();
        private bool _baselineCaptured;

        /// <summary>
        /// Creates a new ValidationService using the given connection string.
        /// Instantiates all dependencies manually (legacy pattern — no DI container).
        /// </summary>
        public ValidationService(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new ArgumentException("Connection string cannot be null or empty.", "connectionString");
            }

            _connectionString = connectionString;
            _stageDetector = new StageDetector();
            _databaseHelper = new DatabaseHelper(connectionString);
            _cleanup = new TestDataCleanup(_databaseHelper);

            // Repositories — all take a connection string
            var customerRepo = new CustomerRepository(connectionString);
            var loanAppRepo = new LoanApplicationRepository(connectionString);
            var loanDecisionRepo = new LoanDecisionRepository(connectionString);
            var paymentScheduleRepo = new PaymentScheduleRepository(connectionString);
            var reportRepo = new ReportRepository(connectionString);

            // Services — wired with their repository dependencies
            ICustomerService customerService = new CustomerService(customerRepo);
            ILoanService loanService = new LoanService(loanAppRepo, loanDecisionRepo, paymentScheduleRepo);
            IReportService reportService = new ReportService(reportRepo);

            // Load baseline snapshot (may be null if not yet captured)
            string baselinePath = BaselineManager.GetBaselineFilePath();
            BaselineSnapshot baseline = BaselineManager.LoadBaseline(baselinePath);

            // Check if baseline file already exists to track capture state
            _baselineCaptured = baseline != null;

            // Test categories
            _smokeTests = new SmokeTests();
            _dataIntegrityTests = new DataIntegrityTests(_databaseHelper, baseline);
            _customerBusinessTests = new CustomerBusinessTests(customerService, _cleanup);
            _loanProcessingTests = new LoanProcessingTests(loanService, reportService, _customerBusinessTests);
            _creditEvaluationTests = new CreditEvaluationTests(loanService, customerService, _cleanup, _customerBusinessTests, _databaseHelper, new CreditEvaluationService(connectionString));
        }

        /// <summary>
        /// Runs all validation tests (smoke, data integrity, business logic).
        /// Only one run executes at a time. Returns a complete ValidationRunResult.
        /// </summary>
        public ValidationRunResult RunAllTests()
        {
            lock (_runLock)
            {
                var overallStopwatch = Stopwatch.StartNew();

                // Clean up any leftover test data from previous runs
                _cleanup.CleanupBySSNPrefix("999-");

                // Detect current modernization stage
                ModernizationStage stage = _stageDetector.Detect(_connectionString);

                var allResults = new List<TestResult>();

                // Execute each test category, catching exceptions per category
                allResults.AddRange(RunCategorySafe(_smokeTests, stage));
                allResults.AddRange(RunCategorySafe(_dataIntegrityTests, stage));
                allResults.AddRange(RunCategorySafe(_customerBusinessTests, stage));
                allResults.AddRange(RunCategorySafe(_loanProcessingTests, stage));
                allResults.AddRange(RunCategorySafe(_creditEvaluationTests, stage));

                overallStopwatch.Stop();

                var result = new ValidationRunResult
                {
                    DetectedStage = stage,
                    StageName = GetStageName(stage),
                    StageSummary = GetStageSummary(stage),
                    Results = allResults,
                    TotalDuration = overallStopwatch.Elapsed,
                    WhyThisMatters = GetWhyThisMatters(),
                    ShadowComparisonResults = _creditEvaluationTests.ShadowComparisonResults,
                    PbtSummary = LoadPbtSummary()
                };

                // On first successful Pre-Modernization run where all tests pass, capture baseline
                if (stage == ModernizationStage.PreModernization && result.AllPassed && !_baselineCaptured)
                {
                    try
                    {
                        var snapshot = BaselineManager.CaptureBaseline(_databaseHelper);
                        string baselinePath = BaselineManager.GetBaselineFilePath();
                        BaselineManager.SaveBaseline(snapshot, baselinePath);
                        _baselineCaptured = true;
                    }
                    catch
                    {
                        // Baseline capture failure should not fail the test run
                    }
                }

                return result;
            }
        }

        /// <summary>
        /// Runs tests in a single category by name.
        /// Valid names: "Smoke", "DataIntegrity", "BusinessLogic".
        /// BusinessLogic runs all three business logic sub-categories.
        /// </summary>
        public ValidationRunResult RunCategory(string category)
        {
            lock (_runLock)
            {
                var overallStopwatch = Stopwatch.StartNew();
                ModernizationStage stage = _stageDetector.Detect(_connectionString);

                var allResults = new List<TestResult>();

                if (string.Equals(category, "Smoke", StringComparison.OrdinalIgnoreCase))
                {
                    allResults.AddRange(RunCategorySafe(_smokeTests, stage));
                }
                else if (string.Equals(category, "DataIntegrity", StringComparison.OrdinalIgnoreCase))
                {
                    allResults.AddRange(RunCategorySafe(_dataIntegrityTests, stage));
                }
                else if (string.Equals(category, "BusinessLogic", StringComparison.OrdinalIgnoreCase))
                {
                    allResults.AddRange(RunCategorySafe(_customerBusinessTests, stage));
                    allResults.AddRange(RunCategorySafe(_loanProcessingTests, stage));
                    allResults.AddRange(RunCategorySafe(_creditEvaluationTests, stage));
                }
                else
                {
                    allResults.Add(new TestResult
                    {
                        TestName = "Unknown Category",
                        Category = category ?? "null",
                        Description = "The requested test category was not recognized",
                        Passed = false,
                        Expected = "Valid category: Smoke, DataIntegrity, or BusinessLogic",
                        Actual = "Category '" + (category ?? "null") + "' not found",
                        WhatToCheck = "Use one of the valid category names: Smoke, DataIntegrity, BusinessLogic",
                        Duration = TimeSpan.Zero
                    });
                }

                overallStopwatch.Stop();

                return new ValidationRunResult
                {
                    DetectedStage = stage,
                    StageName = GetStageName(stage),
                    StageSummary = GetStageSummary(stage),
                    Results = allResults,
                    TotalDuration = overallStopwatch.Elapsed,
                    WhyThisMatters = GetWhyThisMatters()
                };
            }
        }

        /// <summary>
        /// Executes a test category's Run method inside a try/catch.
        /// Exceptions become a single failed TestResult for that category.
        /// </summary>
        private static List<TestResult> RunCategorySafe(IValidationTestCategory testCategory, ModernizationStage stage)
        {
            try
            {
                return testCategory.Run(stage);
            }
            catch (Exception ex)
            {
                return new List<TestResult>
                {
                    new TestResult
                    {
                        TestName = testCategory.CategoryName + " Tests",
                        Category = testCategory.CategoryName,
                        Description = "An unexpected error occurred while running " + testCategory.CategoryName + " tests",
                        Passed = false,
                        Expected = testCategory.CategoryName + " tests execute successfully",
                        Actual = "Exception: " + ex.Message,
                        WhatToCheck = "Check the application logs for details. The error may indicate a configuration or connectivity issue.",
                        Duration = TimeSpan.Zero
                    }
                };
            }
        }

        private static PbtRunSummary LoadPbtSummary()
        {
            try
            {
                string basePath = AppDomain.CurrentDomain.BaseDirectory;
                string pbtPath = Path.Combine(basePath, "pbt-results.json");
                if (!File.Exists(pbtPath)) return null;
                string json = File.ReadAllText(pbtPath);
                var serializer = new JavaScriptSerializer();
                return serializer.Deserialize<PbtRunSummary>(json);
            }
            catch
            {
                return null;
            }
        }

        #region Stage Metadata

        private static string GetStageName(ModernizationStage stage)
        {
            switch (stage)
            {
                case ModernizationStage.PreModernization:
                    bool spExtracted = Type.GetType("LoanProcessing.Web.Services.CreditEvaluationCalculator, LoanProcessing.Web") != null;
                    return spExtracted
                        ? "Post-SP-Extraction (.NET Framework 4.7.2 + SQL Server — SPs Extracted)"
                        : "Pre-Modernization (.NET Framework 4.7.2 + SQL Server)";
                case ModernizationStage.PostModule1:
                    return "Post-Module-1 (Aurora PostgreSQL)";
                case ModernizationStage.PostModule2:
                    return "Post-Module-2 (.NET 8)";
                case ModernizationStage.PostModule3:
                    return "Post-Module-3 (Containerized)";
                default:
                    return "Unknown Stage";
            }
        }

        private static string GetStageSummary(ModernizationStage stage)
        {
            switch (stage)
            {
                case ModernizationStage.PreModernization:
                    return "This is the original application state. The application runs on .NET Framework 4.7.2 with SQL Server on IIS/EC2. These tests establish the baseline that all subsequent modernization stages will be compared against.";
                case ModernizationStage.PostModule1:
                    return "You completed Module 1: Database Modernization. The database was migrated from SQL Server to Aurora PostgreSQL using AWS DMS. These tests verify that all data was preserved and the application functions correctly with the new database engine.";
                case ModernizationStage.PostModule2:
                    return "You completed Module 2: Application Modernization. The application was migrated from .NET Framework 4.7.2 to .NET 8 with EF Core. These tests verify that the application stack modernization preserved all functionality.";
                case ModernizationStage.PostModule3:
                    return "You completed Module 3: Compute Modernization. The application was containerized and deployed to a container platform. These tests verify that the containerized deployment preserved all functionality and connectivity.";
                default:
                    return "Stage detection was inconclusive. Tests are running against the current application state.";
            }
        }

        private static Dictionary<string, string> GetWhyThisMatters()
        {
            return new Dictionary<string, string>
            {
                {
                    "Smoke",
                    "These tests confirm the web tier is functional. Every application page should load and render correctly regardless of which modernization stage you are at. A failure here means the application itself is not serving requests properly."
                },
                {
                    "DataIntegrity",
                    "These tests confirm that data was preserved during migration. Row counts, constraints, and sample records are compared against the pre-modernization baseline. A failure here means data may have been lost or corrupted during the migration process."
                },
                {
                    "BusinessLogic",
                    "These tests confirm that business operations work correctly after modernization. Customer management, loan processing, credit evaluation, and reporting are exercised through the service layer. A failure here means business logic may have changed during the modernization."
                }
            };
        }

        #endregion
    }
}
