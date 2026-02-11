using System;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository interface for report generation operations.
    /// Provides methods for generating portfolio and analytical reports.
    /// </summary>
    public interface IReportRepository
    {
        /// <summary>
        /// Generates a comprehensive portfolio report with summary statistics,
        /// loan type breakdown, and risk distribution.
        /// Calls sp_GeneratePortfolioReport stored procedure.
        /// </summary>
        /// <param name="startDate">Optional start date for filtering loan applications. Defaults to 12 months ago if null.</param>
        /// <param name="endDate">Optional end date for filtering loan applications. Defaults to current date if null.</param>
        /// <param name="loanType">Optional loan type filter (Personal, Auto, Mortgage, Business). Includes all types if null.</param>
        /// <returns>A PortfolioReport containing summary, loan type breakdown, and risk distribution.</returns>
        PortfolioReport GeneratePortfolioReport(DateTime? startDate, DateTime? endDate, string loanType);
    }
}
