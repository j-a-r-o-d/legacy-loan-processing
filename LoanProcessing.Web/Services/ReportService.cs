using System;
using System.Data.SqlClient;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service implementation for report generation operations.
    /// Wraps repository calls with validation and error handling, providing meaningful error messages.
    /// Demonstrates legacy service layer pattern with business context added to exceptions.
    /// </summary>
    public class ReportService : IReportService
    {
        private readonly IReportRepository _reportRepository;

        /// <summary>
        /// Initializes a new instance of the ReportService class.
        /// </summary>
        /// <param name="reportRepository">The report repository for data access.</param>
        public ReportService(IReportRepository reportRepository)
        {
            if (reportRepository == null)
            {
                throw new ArgumentNullException(nameof(reportRepository));
            }

            _reportRepository = reportRepository;
        }

        /// <summary>
        /// Generates a comprehensive portfolio report with summary statistics,
        /// loan type breakdown, and risk distribution.
        /// Formats report data for presentation with validation and error handling.
        /// </summary>
        /// <param name="startDate">Optional start date for filtering loan applications. Defaults to 12 months ago if null.</param>
        /// <param name="endDate">Optional end date for filtering loan applications. Defaults to current date if null.</param>
        /// <param name="loanType">Optional loan type filter (Personal, Auto, Mortgage, Business). Includes all types if null.</param>
        /// <returns>A PortfolioReport containing summary, loan type breakdown, and risk distribution.</returns>
        /// <exception cref="ArgumentException">Thrown when date range or loan type parameters are invalid.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public PortfolioReport GeneratePortfolioReport(DateTime? startDate, DateTime? endDate, string loanType)
        {
            try
            {
                // Validate date range if both dates are provided
                if (startDate.HasValue && endDate.HasValue && startDate.Value > endDate.Value)
                {
                    throw new ArgumentException("Start date cannot be after end date.", nameof(startDate));
                }

                // Validate loan type if provided
                if (!string.IsNullOrWhiteSpace(loanType))
                {
                    var validLoanTypes = new[] { "Personal", "Auto", "Mortgage", "Business" };
                    var isValid = false;
                    foreach (var validType in validLoanTypes)
                    {
                        if (string.Equals(loanType, validType, StringComparison.OrdinalIgnoreCase))
                        {
                            isValid = true;
                            break;
                        }
                    }

                    if (!isValid)
                    {
                        throw new ArgumentException(
                            "Loan type must be one of: Personal, Auto, Mortgage, Business.", nameof(loanType));
                    }
                }

                // Call repository to generate report
                var report = _reportRepository.GeneratePortfolioReport(startDate, endDate, loanType);

                if (report == null)
                {
                    throw new InvalidOperationException("Failed to generate portfolio report. No data returned from repository.");
                }

                // Format report data for presentation
                FormatReportData(report);

                return report;
            }
            catch (SqlException ex)
            {
                // Translate database errors to business-friendly messages
                var dateRangeInfo = startDate.HasValue && endDate.HasValue
                    ? $" for date range {startDate.Value:yyyy-MM-dd} to {endDate.Value:yyyy-MM-dd}"
                    : "";
                var loanTypeInfo = !string.IsNullOrWhiteSpace(loanType) ? $" for loan type '{loanType}'" : "";

                throw new InvalidOperationException(
                    $"Failed to generate portfolio report{dateRangeInfo}{loanTypeInfo}. Database error occurred.", ex);
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    "An unexpected error occurred while generating the portfolio report.", ex);
            }
        }

        /// <summary>
        /// Formats report data for presentation by ensuring proper initialization of collections
        /// and handling null values appropriately.
        /// </summary>
        /// <param name="report">The portfolio report to format.</param>
        private void FormatReportData(PortfolioReport report)
        {
            if (report == null)
            {
                return;
            }

            // Ensure summary is initialized
            if (report.Summary == null)
            {
                report.Summary = new PortfolioSummary();
            }

            // Ensure loan type breakdown collection is initialized
            if (report.LoanTypeBreakdown == null)
            {
                report.LoanTypeBreakdown = new System.Collections.Generic.List<LoanTypeBreakdown>();
            }

            // Ensure risk distribution collection is initialized
            if (report.RiskDistribution == null)
            {
                report.RiskDistribution = new System.Collections.Generic.List<RiskDistribution>();
            }
        }
    }
}
