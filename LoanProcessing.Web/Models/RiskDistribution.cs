using System;

namespace LoanProcessing.Web.Models
{
    /// <summary>
    /// Represents loan statistics grouped by risk score ranges from the third result set of sp_GeneratePortfolioReport.
    /// Provides risk distribution analysis across different risk categories.
    /// </summary>
    public class RiskDistribution
    {
        /// <summary>
        /// Risk category label (e.g., "Low Risk (0-20)", "Medium Risk (21-40)").
        /// </summary>
        public string RiskCategory { get; set; }

        /// <summary>
        /// Number of loans in this risk category.
        /// </summary>
        public int LoanCount { get; set; }

        /// <summary>
        /// Total approved amount in this risk category.
        /// </summary>
        public decimal TotalAmount { get; set; }

        /// <summary>
        /// Average interest rate for loans in this risk category.
        /// </summary>
        public decimal? AvgInterestRate { get; set; }
    }
}
