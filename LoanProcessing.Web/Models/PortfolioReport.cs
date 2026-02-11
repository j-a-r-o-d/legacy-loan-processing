using System;
using System.Collections.Generic;

namespace LoanProcessing.Web.Models
{
    /// <summary>
    /// Represents a complete portfolio report containing summary statistics,
    /// loan type breakdown, and risk distribution.
    /// Aggregates all three result sets from sp_GeneratePortfolioReport.
    /// </summary>
    public class PortfolioReport
    {
        /// <summary>
        /// Portfolio summary statistics (first result set).
        /// </summary>
        public PortfolioSummary Summary { get; set; }

        /// <summary>
        /// Breakdown of loans by type (second result set).
        /// </summary>
        public IEnumerable<LoanTypeBreakdown> LoanTypeBreakdown { get; set; }

        /// <summary>
        /// Distribution of loans by risk category (third result set).
        /// </summary>
        public IEnumerable<RiskDistribution> RiskDistribution { get; set; }

        /// <summary>
        /// Start date of the report period.
        /// </summary>
        public DateTime? StartDate { get; set; }

        /// <summary>
        /// End date of the report period.
        /// </summary>
        public DateTime? EndDate { get; set; }

        /// <summary>
        /// Optional loan type filter applied to the report.
        /// </summary>
        public string LoanType { get; set; }
    }
}
