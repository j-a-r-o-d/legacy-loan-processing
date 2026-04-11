namespace LoanProcessing.Web.Validation.Models
{
    public class ShadowTestProfile
    {
        public string ScenarioName { get; set; }
        public int CreditScore { get; set; }
        public decimal AnnualIncome { get; set; }
        public string LoanType { get; set; }
        public decimal RequestedAmount { get; set; }
        public int TermMonths { get; set; }
        public string ExpectedRecommendationCategory { get; set; }
    }
}
