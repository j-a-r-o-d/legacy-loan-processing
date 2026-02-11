using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository implementation for report generation using ADO.NET and stored procedures.
    /// Demonstrates legacy pattern with manual parameter mapping and multiple result set handling.
    /// </summary>
    public class ReportRepository : IReportRepository
    {
        private readonly string _connectionString;

        /// <summary>
        /// Initializes a new instance of the ReportRepository class.
        /// </summary>
        /// <param name="connectionString">The database connection string.</param>
        public ReportRepository(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new ArgumentNullException(nameof(connectionString));
            }

            _connectionString = connectionString;
        }

        /// <summary>
        /// Initializes a new instance of the ReportRepository class using the default connection string.
        /// </summary>
        public ReportRepository()
            : this(ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString)
        {
        }

        /// <summary>
        /// Generates a comprehensive portfolio report with summary statistics,
        /// loan type breakdown, and risk distribution.
        /// Calls sp_GeneratePortfolioReport stored procedure and maps three result sets.
        /// </summary>
        /// <param name="startDate">Optional start date for filtering loan applications. Defaults to 12 months ago if null.</param>
        /// <param name="endDate">Optional end date for filtering loan applications. Defaults to current date if null.</param>
        /// <param name="loanType">Optional loan type filter (Personal, Auto, Mortgage, Business). Includes all types if null.</param>
        /// <returns>A PortfolioReport containing summary, loan type breakdown, and risk distribution.</returns>
        /// <exception cref="SqlException">Thrown when database operation fails.</exception>
        public PortfolioReport GeneratePortfolioReport(DateTime? startDate, DateTime? endDate, string loanType)
        {
            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_GeneratePortfolioReport", connection))
            {
                command.CommandType = CommandType.StoredProcedure;

                // Add parameters - use DBNull.Value for null values (legacy pattern)
                if (startDate.HasValue)
                {
                    command.Parameters.AddWithValue("@StartDate", startDate.Value);
                }
                else
                {
                    command.Parameters.AddWithValue("@StartDate", DBNull.Value);
                }

                if (endDate.HasValue)
                {
                    command.Parameters.AddWithValue("@EndDate", endDate.Value);
                }
                else
                {
                    command.Parameters.AddWithValue("@EndDate", DBNull.Value);
                }

                if (!string.IsNullOrWhiteSpace(loanType))
                {
                    command.Parameters.AddWithValue("@LoanType", loanType);
                }
                else
                {
                    command.Parameters.AddWithValue("@LoanType", DBNull.Value);
                }

                connection.Open();

                using (var reader = command.ExecuteReader())
                {
                    // Read result set 1: Portfolio summary
                    var summary = ReadPortfolioSummary(reader);

                    // Move to result set 2: Loan type breakdown
                    reader.NextResult();
                    var loanTypeBreakdown = ReadLoanTypeBreakdown(reader);

                    // Move to result set 3: Risk distribution
                    reader.NextResult();
                    var riskDistribution = ReadRiskDistribution(reader);

                    // Create and return the complete report
                    return new PortfolioReport
                    {
                        Summary = summary,
                        LoanTypeBreakdown = loanTypeBreakdown,
                        RiskDistribution = riskDistribution,
                        StartDate = startDate,
                        EndDate = endDate,
                        LoanType = loanType
                    };
                }
            }
        }

        /// <summary>
        /// Reads the portfolio summary from the first result set.
        /// Maps aggregate statistics including total loans, approved amounts, and averages.
        /// </summary>
        /// <param name="reader">The SqlDataReader positioned at the first result set.</param>
        /// <returns>A PortfolioSummary object populated from the reader.</returns>
        private PortfolioSummary ReadPortfolioSummary(SqlDataReader reader)
        {
            if (reader.Read())
            {
                return new PortfolioSummary
                {
                    TotalLoans = reader.GetInt32(reader.GetOrdinal("TotalLoans")),
                    ApprovedLoans = reader.GetInt32(reader.GetOrdinal("ApprovedLoans")),
                    RejectedLoans = reader.GetInt32(reader.GetOrdinal("RejectedLoans")),
                    PendingLoans = reader.GetInt32(reader.GetOrdinal("PendingLoans")),
                    TotalApprovedAmount = reader.GetDecimal(reader.GetOrdinal("TotalApprovedAmount")),
                    AverageApprovedAmount = reader.IsDBNull(reader.GetOrdinal("AverageApprovedAmount"))
                        ? (decimal?)null
                        : reader.GetDecimal(reader.GetOrdinal("AverageApprovedAmount")),
                    AverageInterestRate = reader.IsDBNull(reader.GetOrdinal("AverageInterestRate"))
                        ? (decimal?)null
                        : reader.GetDecimal(reader.GetOrdinal("AverageInterestRate")),
                    AverageRiskScore = reader.IsDBNull(reader.GetOrdinal("AverageRiskScore"))
                        ? (int?)null
                        : reader.GetInt32(reader.GetOrdinal("AverageRiskScore"))
                };
            }

            // Return empty summary if no data
            return new PortfolioSummary();
        }

        /// <summary>
        /// Reads the loan type breakdown from the second result set.
        /// Maps statistics grouped by loan type (Personal, Auto, Mortgage, Business).
        /// </summary>
        /// <param name="reader">The SqlDataReader positioned at the second result set.</param>
        /// <returns>A collection of LoanTypeBreakdown objects populated from the reader.</returns>
        private IEnumerable<LoanTypeBreakdown> ReadLoanTypeBreakdown(SqlDataReader reader)
        {
            var breakdown = new List<LoanTypeBreakdown>();

            while (reader.Read())
            {
                breakdown.Add(new LoanTypeBreakdown
                {
                    LoanType = reader.GetString(reader.GetOrdinal("LoanType")),
                    TotalApplications = reader.GetInt32(reader.GetOrdinal("TotalApplications")),
                    ApprovedCount = reader.GetInt32(reader.GetOrdinal("ApprovedCount")),
                    TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalAmount")),
                    AvgInterestRate = reader.IsDBNull(reader.GetOrdinal("AvgInterestRate"))
                        ? (decimal?)null
                        : reader.GetDecimal(reader.GetOrdinal("AvgInterestRate"))
                });
            }

            return breakdown;
        }

        /// <summary>
        /// Reads the risk distribution from the third result set.
        /// Maps statistics grouped by risk score ranges (Low, Medium, High, Very High).
        /// </summary>
        /// <param name="reader">The SqlDataReader positioned at the third result set.</param>
        /// <returns>A collection of RiskDistribution objects populated from the reader.</returns>
        private IEnumerable<RiskDistribution> ReadRiskDistribution(SqlDataReader reader)
        {
            var distribution = new List<RiskDistribution>();

            while (reader.Read())
            {
                distribution.Add(new RiskDistribution
                {
                    RiskCategory = reader.GetString(reader.GetOrdinal("RiskCategory")),
                    LoanCount = reader.GetInt32(reader.GetOrdinal("LoanCount")),
                    TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalAmount")),
                    AvgInterestRate = reader.IsDBNull(reader.GetOrdinal("AvgInterestRate"))
                        ? (decimal?)null
                        : reader.GetDecimal(reader.GetOrdinal("AvgInterestRate"))
                });
            }

            return distribution;
        }
    }
}
