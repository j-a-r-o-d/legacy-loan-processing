using System;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service interface for report generation operations.
    /// Provides a layer of abstraction over the repository with error handling and validation.
    /// </summary>
    public interface IReportService
    {
        /// <summary>
        /// Generates a comprehensive portfolio report with summary statistics,
        /// loan type breakdown, and risk distribution.
        /// </summary>
        /// <param name="startDate">Optional start date for filtering loan applications. Defaults to 12 months ago if null.</param>
        /// <param name="endDate">Optional end date for filtering loan applications. Defaults to current date if null.</param>
        /// <param name="loanType">Optional loan type filter (Personal, Auto, Mortgage, Business). Includes all types if null.</param>
        /// <returns>A PortfolioReport containing summary, loan type breakdown, and risk distribution.</returns>
        PortfolioReport GeneratePortfolioReport(DateTime? startDate, DateTime? endDate, string loanType);
    }
}
