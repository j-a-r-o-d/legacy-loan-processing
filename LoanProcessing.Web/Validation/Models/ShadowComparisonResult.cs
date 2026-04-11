namespace LoanProcessing.Web.Validation.Models
{
    public class ShadowComparisonResult
    {
        public string ScenarioName { get; set; }
        public int? SpRiskScore { get; set; }
        public int? SvcRiskScore { get; set; }
        public decimal? SpDti { get; set; }
        public decimal? SvcDti { get; set; }
        public decimal? SpInterestRate { get; set; }
        public decimal? SvcInterestRate { get; set; }
        public string SpRecommendation { get; set; }
        public string SvcRecommendation { get; set; }
        public bool AllMatch { get; set; }
    }
}
