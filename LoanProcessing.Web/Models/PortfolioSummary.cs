using System;

namespace LoanProcessing.Web.Models
{
    /// <summary>
    /// Represents the portfolio summary statistics from the first result set of sp_GeneratePortfolioReport.
    /// Contains aggregate metrics across all loans in the specified date range.
    /// </summary>
    public class PortfolioSummary
    {
        /// <summary>
        /// Total number of loan applications in the date range.
        /// </summary>
        public int TotalLoans { get; set; }

        /// <summary>
        /// Number of approved loan applications.
        /// </summary>
        public int ApprovedLoans { get; set; }

        /// <summary>
        /// Number of rejected loan applications.
        /// </summary>
        public int RejectedLoans { get; set; }

        /// <summary>
        /// Number of pending or under review loan applications.
        /// </summary>
        public int PendingLoans { get; set; }

        /// <summary>
        /// Sum of all approved loan amounts.
        /// </summary>
        public decimal TotalApprovedAmount { get; set; }

        /// <summary>
        /// Average approved loan amount.
        /// </summary>
        public decimal? AverageApprovedAmount { get; set; }

        /// <summary>
        /// Average interest rate for approved loans.
        /// </summary>
        public decimal? AverageInterestRate { get; set; }

        /// <summary>
        /// Average risk score across all evaluated loans.
        /// </summary>
        public int? AverageRiskScore { get; set; }
    }
}
