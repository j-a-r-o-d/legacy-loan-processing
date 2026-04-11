using System;
using System.Collections.Generic;
using System.Linq;

namespace LoanProcessing.Web.Validation.Models
{
    public class ValidationRunResult
    {
        public ModernizationStage DetectedStage { get; set; }
        public string StageName { get; set; }
        public string StageSummary { get; set; }
        public List<TestResult> Results { get; set; } = new List<TestResult>();
        public int TotalTests => Results.Count;
        public int PassedTests => Results.Count(r => r.Passed);
        public int FailedTests => Results.Count(r => !r.Passed);
        public bool AllPassed => Results.All(r => r.Passed);
        public TimeSpan TotalDuration { get; set; }
        public Dictionary<string, string> WhyThisMatters { get; set; } = new Dictionary<string, string>();
        public List<ShadowComparisonResult> ShadowComparisonResults { get; set; } = new List<ShadowComparisonResult>();
        public PbtRunSummary PbtSummary { get; set; }
    }
}
