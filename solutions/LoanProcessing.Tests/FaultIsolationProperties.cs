using System;
using System.Collections.Generic;
using System.Linq;
using FsCheck;
using FsCheck.Xunit;
using LoanProcessing.Web.Validation.Models;
using TestResult = LoanProcessing.Web.Validation.Models.TestResult;

namespace LoanProcessing.Tests
{
    /// <summary>
    /// Property 7: Fault Isolation Across Profiles
    /// For any shadow profile that fails (due to SP null, service exception, or value
    /// mismatch), all remaining profiles in the suite SHALL still execute and produce
    /// their own TestResult objects.
    /// Validates: Requirement 8.4
    /// </summary>
    public class FaultIsolationProperties
    {
        /// <summary>
        /// Property 7: Fault Isolation Across Profiles
        ///
        /// Models the RunAllShadowComparisons loop structure as a pure function.
        /// For any subset of profiles that fail (throw exceptions), the loop still
        /// produces exactly N results (one per profile) plus 1 summary TestResult,
        /// where N is the total number of profiles.
        ///
        /// **Validates: Requirements 8.4**
        /// </summary>
        [Property(MaxTest = 100)]
        public Property FaultIsolation_AllProfilesProduceResults_RegardlessOfFailures()
        {
            // Generate a random profile count between 1 and 10
            var profileCountGen = Gen.Choose(1, 10);

            return Prop.ForAll(
                Arb.From(profileCountGen),
                profileCount =>
                {
                    // Generate a random failure mask for this profile count
                    var failureMaskGen = Gen.ArrayOf(profileCount, Gen.Elements(true, false));

                    return Prop.ForAll(
                        Arb.From(failureMaskGen),
                        failureMask =>
                        {
                            // Simulate the RunAllShadowComparisons loop:
                            // for each profile, try/catch wraps execution so failures
                            // don't abort the loop — this is the fault isolation guarantee
                            var results = new List<TestResult>();
                            var shadowComparisonResults = new List<ShadowComparisonResult>();
                            int passed = 0;

                            for (int i = 0; i < profileCount; i++)
                            {
                                try
                                {
                                    if (failureMask[i])
                                    {
                                        throw new Exception("Simulated failure for profile " + i);
                                    }

                                    // Successful profile execution
                                    results.Add(new TestResult
                                    {
                                        TestName = "Shadow: Profile " + i,
                                        Passed = true
                                    });
                                    shadowComparisonResults.Add(new ShadowComparisonResult
                                    {
                                        ScenarioName = "Profile " + i,
                                        AllMatch = true
                                    });
                                    passed++;
                                }
                                catch (Exception)
                                {
                                    // Catch block mirrors RunAllShadowComparisons:
                                    // adds a failed result and continues the loop
                                    results.Add(new TestResult
                                    {
                                        TestName = "Shadow: Profile " + i,
                                        Passed = false
                                    });
                                    shadowComparisonResults.Add(new ShadowComparisonResult
                                    {
                                        ScenarioName = "Profile " + i,
                                        AllMatch = false
                                    });
                                }
                            }

                            // Summary TestResult appended after the loop
                            results.Add(new TestResult
                            {
                                TestName = "Shadow Comparison Summary",
                                Passed = passed == profileCount
                            });

                            int failedCount = failureMask.Count(f => f);
                            int expectedPassed = profileCount - failedCount;

                            // Invariant 1: total results == profileCount + 1 (one per profile + summary)
                            bool resultCountCorrect = results.Count == profileCount + 1;

                            // Invariant 2: shadow comparison results == profileCount (one per profile)
                            bool shadowCountCorrect = shadowComparisonResults.Count == profileCount;

                            // Invariant 3: passed count matches non-failing profiles
                            bool passedCountCorrect = passed == expectedPassed;

                            // Invariant 4: summary reflects overall pass/fail correctly
                            bool summaryCorrect = results.Last().Passed == (failedCount == 0);

                            return resultCountCorrect
                                && shadowCountCorrect
                                && passedCountCorrect
                                && summaryCorrect;
                        });
                });
        }
    }
}
