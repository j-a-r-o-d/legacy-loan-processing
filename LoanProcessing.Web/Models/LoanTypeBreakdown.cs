using System;

namespace LoanProcessing.Web.Models
{
    /// <summary>
    /// Represents loan statistics grouped by loan type from the second result set of sp_GeneratePortfolioReport.
    /// Provides breakdown of applications, approvals, and amounts by loan type.
    /// </summary>
    public class LoanTypeBreakdown
    {
        /// <summary>
        /// Type of loan (Personal, Auto, Mortgage, Business).
        /// </summary>
        public string LoanType { get; set; }

        /// <summary>
        /// Total number of applications for this loan type.
        /// </summary>
        public int TotalApplications { get; set; }

        /// <summary>
        /// Number of approved applications for this loan type.
        /// </summary>
        public int ApprovedCount { get; set; }

        /// <summary>
        /// Total approved amount for this loan type.
        /// </summary>
        public decimal TotalAmount { get; set; }

        /// <summary>
        /// Average interest rate for approved loans of this type.
        /// </summary>
        public decimal? AvgInterestRate { get; set; }
    }
}
