using System;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Web.Mvc;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;
using LoanProcessing.Web.Services;

namespace LoanProcessing.Web.Controllers
{
    /// <summary>
    /// Controller for report generation and viewing operations.
    /// Demonstrates legacy ASP.NET MVC 5 patterns with manual dependency injection.
    /// </summary>
    public class ReportController : Controller
    {
        private readonly IReportService _reportService;

        /// <summary>
        /// Initializes a new instance of the ReportController class.
        /// Uses manual dependency injection pattern typical of legacy applications.
        /// </summary>
        public ReportController()
        {
            // Manual dependency injection - typical legacy pattern
            var connectionString = ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString;
            var reportRepository = new ReportRepository(connectionString);
            _reportService = new ReportService(reportRepository);
        }

        /// <summary>
        /// Constructor for dependency injection (used in testing).
        /// </summary>
        /// <param name="reportService">The report service instance.</param>
        public ReportController(IReportService reportService)
        {
            _reportService = reportService ?? throw new ArgumentNullException(nameof(reportService));
        }

        /// <summary>
        /// GET: Report/Portfolio
        /// Displays the portfolio report with optional date range and loan type filters.
        /// </summary>
        /// <param name="startDate">Optional start date for filtering loan applications.</param>
        /// <param name="endDate">Optional end date for filtering loan applications.</param>
        /// <param name="loanType">Optional loan type filter (Personal, Auto, Mortgage, Business).</param>
        /// <param name="export">Optional flag to export report as CSV.</param>
        /// <returns>View with portfolio report data or CSV file download.</returns>
        public ActionResult Portfolio(DateTime? startDate, DateTime? endDate, string loanType, bool export = false)
        {
            try
            {
                // Generate the portfolio report
                var report = _reportService.GeneratePortfolioReport(startDate, endDate, loanType);

                if (report == null)
                {
                    TempData["Error"] = "Unable to generate portfolio report. No data available.";
                    return View();
                }

                // Store filter parameters in ViewBag for display
                ViewBag.StartDate = startDate;
                ViewBag.EndDate = endDate;
                ViewBag.LoanType = loanType;
                ViewBag.LoanTypes = new SelectList(new[] { "", "Personal", "Auto", "Mortgage", "Business" });

                // If export is requested, return CSV file
                if (export)
                {
                    return ExportPortfolioReportToCsv(report);
                }

                return View(report);
            }
            catch (ArgumentException ex)
            {
                TempData["Error"] = ex.Message;
                ViewBag.StartDate = startDate;
                ViewBag.EndDate = endDate;
                ViewBag.LoanType = loanType;
                ViewBag.LoanTypes = new SelectList(new[] { "", "Personal", "Auto", "Mortgage", "Business" });
                return View();
            }
            catch (InvalidOperationException ex)
            {
                TempData["Error"] = ex.Message;
                ViewBag.StartDate = startDate;
                ViewBag.EndDate = endDate;
                ViewBag.LoanType = loanType;
                ViewBag.LoanTypes = new SelectList(new[] { "", "Personal", "Auto", "Mortgage", "Business" });
                return View();
            }
            catch (Exception ex)
            {
                TempData["Error"] = "An unexpected error occurred while generating the report: " + ex.Message;
                ViewBag.StartDate = startDate;
                ViewBag.EndDate = endDate;
                ViewBag.LoanType = loanType;
                ViewBag.LoanTypes = new SelectList(new[] { "", "Personal", "Auto", "Mortgage", "Business" });
                return View();
            }
        }

        /// <summary>
        /// Exports the portfolio report to CSV format.
        /// Formats report data for display in spreadsheet applications.
        /// </summary>
        /// <param name="report">The portfolio report to export.</param>
        /// <returns>FileContentResult containing CSV data.</returns>
        private FileContentResult ExportPortfolioReportToCsv(PortfolioReport report)
        {
            var csv = new StringBuilder();

            // Add report header with filters
            csv.AppendLine("Portfolio Report");
            csv.AppendLine($"Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
            
            if (report.StartDate.HasValue || report.EndDate.HasValue)
            {
                var startDateStr = report.StartDate.HasValue ? report.StartDate.Value.ToString("yyyy-MM-dd") : "N/A";
                var endDateStr = report.EndDate.HasValue ? report.EndDate.Value.ToString("yyyy-MM-dd") : "N/A";
                csv.AppendLine($"Date Range: {startDateStr} to {endDateStr}");
            }
            
            if (!string.IsNullOrWhiteSpace(report.LoanType))
            {
                csv.AppendLine($"Loan Type Filter: {report.LoanType}");
            }
            
            csv.AppendLine();

            // Add portfolio summary section
            csv.AppendLine("Portfolio Summary");
            csv.AppendLine("Metric,Value");
            
            if (report.Summary != null)
            {
                csv.AppendLine($"Total Loans,{report.Summary.TotalLoans}");
                csv.AppendLine($"Approved Loans,{report.Summary.ApprovedLoans}");
                csv.AppendLine($"Rejected Loans,{report.Summary.RejectedLoans}");
                csv.AppendLine($"Pending Loans,{report.Summary.PendingLoans}");
                csv.AppendLine($"Total Approved Amount,\"{report.Summary.TotalApprovedAmount:C}\"");
                
                if (report.Summary.AverageApprovedAmount.HasValue)
                {
                    csv.AppendLine($"Average Approved Amount,\"{report.Summary.AverageApprovedAmount.Value:C}\"");
                }
                
                if (report.Summary.AverageInterestRate.HasValue)
                {
                    csv.AppendLine($"Average Interest Rate,{report.Summary.AverageInterestRate.Value:F2}%");
                }
                
                if (report.Summary.AverageRiskScore.HasValue)
                {
                    csv.AppendLine($"Average Risk Score,{report.Summary.AverageRiskScore.Value}");
                }
            }
            
            csv.AppendLine();

            // Add loan type breakdown section
            csv.AppendLine("Loan Type Breakdown");
            csv.AppendLine("Loan Type,Total Applications,Approved Count,Total Amount,Average Rate");
            
            if (report.LoanTypeBreakdown != null)
            {
                foreach (var breakdown in report.LoanTypeBreakdown)
                {
                    var avgRate = breakdown.AvgInterestRate.HasValue ? breakdown.AvgInterestRate.Value.ToString("F2") + "%" : "N/A";
                    csv.AppendLine($"{breakdown.LoanType},{breakdown.TotalApplications},{breakdown.ApprovedCount},\"{breakdown.TotalAmount:C}\",{avgRate}");
                }
            }
            
            csv.AppendLine();

            // Add risk distribution section
            csv.AppendLine("Risk Distribution");
            csv.AppendLine("Risk Category,Loan Count,Total Amount,Average Rate");
            
            if (report.RiskDistribution != null)
            {
                foreach (var risk in report.RiskDistribution)
                {
                    var avgRate = risk.AvgInterestRate.HasValue ? risk.AvgInterestRate.Value.ToString("F2") + "%" : "N/A";
                    csv.AppendLine($"{risk.RiskCategory},{risk.LoanCount},\"{risk.TotalAmount:C}\",{avgRate}");
                }
            }

            // Convert to bytes and return as file
            var bytes = Encoding.UTF8.GetBytes(csv.ToString());
            var fileName = $"PortfolioReport_{DateTime.Now:yyyyMMdd_HHmmss}.csv";
            
            return File(bytes, "text/csv", fileName);
        }

        /// <summary>
        /// GET: Report/Index
        /// Displays the main reports page with links to available reports.
        /// </summary>
        /// <returns>View with report navigation.</returns>
        public ActionResult Index()
        {
            return View();
        }
    }
}
