using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository implementation for loan decision data access using ADO.NET and stored procedures.
    /// Demonstrates legacy pattern with manual parameter mapping and result set handling.
    /// </summary>
    public class LoanDecisionRepository : ILoanDecisionRepository
    {
        private readonly string _connectionString;

        /// <summary>
        /// Initializes a new instance of the LoanDecisionRepository class.
        /// </summary>
        /// <param name="connectionString">The database connection string.</param>
        public LoanDecisionRepository(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new ArgumentNullException(nameof(connectionString));
            }

            _connectionString = connectionString;
        }

        /// <summary>
        /// Initializes a new instance of the LoanDecisionRepository class using the default connection string.
        /// </summary>
        public LoanDecisionRepository()
            : this(ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString)
        {
        }

        /// <summary>
        /// Performs credit evaluation for a loan application.
        /// Calls sp_EvaluateCredit stored procedure which calculates risk score,
        /// debt-to-income ratio, and determines appropriate interest rate.
        /// </summary>
        /// <param name="applicationId">The application ID to evaluate.</param>
        /// <returns>A LoanDecision object containing evaluation results.</returns>
        /// <exception cref="SqlException">Thrown when database operation fails.</exception>
        public LoanDecision EvaluateCredit(int applicationId)
        {
            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_EvaluateCredit", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@ApplicationId", applicationId);

                connection.Open();
                using (var reader = command.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        // Map the evaluation results to a LoanDecision object
                        // Note: This is not a persisted decision yet, just evaluation results
                        return new LoanDecision
                        {
                            ApplicationId = reader.GetInt32(reader.GetOrdinal("ApplicationId")),
                            RiskScore = reader.IsDBNull(reader.GetOrdinal("RiskScore"))
                                ? (int?)null
                                : reader.GetInt32(reader.GetOrdinal("RiskScore")),
                            DebtToIncomeRatio = reader.IsDBNull(reader.GetOrdinal("DebtToIncomeRatio"))
                                ? (decimal?)null
                                : reader.GetDecimal(reader.GetOrdinal("DebtToIncomeRatio")),
                            InterestRate = reader.IsDBNull(reader.GetOrdinal("InterestRate"))
                                ? (decimal?)null
                                : reader.GetDecimal(reader.GetOrdinal("InterestRate")),
                            // Store recommendation in Comments field for display purposes
                            Comments = reader.GetString(reader.GetOrdinal("Recommendation"))
                        };
                    }
                }
            }

            return null;
        }

        /// <summary>
        /// Processes a loan decision (approval or rejection).
        /// Calls sp_ProcessLoanDecision stored procedure which records the decision,
        /// updates application status, and triggers payment schedule calculation if approved.
        /// </summary>
        /// <param name="applicationId">The application ID to process.</param>
        /// <param name="decision">The decision (Approved or Rejected).</param>
        /// <param name="decisionBy">The name of the person making the decision.</param>
        /// <param name="comments">Optional comments about the decision.</param>
        /// <param name="approvedAmount">The approved loan amount (optional, defaults to requested amount).</param>
        /// <param name="riskScore">Optional risk score from evaluation.</param>
        /// <param name="debtToIncomeRatio">Optional debt-to-income ratio from evaluation.</param>
        /// <exception cref="ArgumentException">Thrown when decision or decisionBy is null or empty.</exception>
        /// <exception cref="SqlException">Thrown when database operation fails.</exception>
        public void ProcessDecision(int applicationId, string decision, string decisionBy,
            string comments = null, decimal? approvedAmount = null,
            int? riskScore = null, decimal? debtToIncomeRatio = null)
        {
            if (string.IsNullOrWhiteSpace(decision))
            {
                throw new ArgumentException("Decision cannot be null or empty.", nameof(decision));
            }

            if (string.IsNullOrWhiteSpace(decisionBy))
            {
                throw new ArgumentException("DecisionBy cannot be null or empty.", nameof(decisionBy));
            }

            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_ProcessLoanDecision", connection))
            {
                command.CommandType = CommandType.StoredProcedure;

                // Manual parameter mapping - legacy pattern
                command.Parameters.AddWithValue("@ApplicationId", applicationId);
                command.Parameters.AddWithValue("@Decision", decision);
                command.Parameters.AddWithValue("@DecisionBy", decisionBy);
                command.Parameters.AddWithValue("@Comments",
                    string.IsNullOrWhiteSpace(comments) ? (object)DBNull.Value : comments);
                command.Parameters.AddWithValue("@ApprovedAmount",
                    approvedAmount.HasValue ? (object)approvedAmount.Value : DBNull.Value);
                command.Parameters.AddWithValue("@RiskScore",
                    riskScore.HasValue ? (object)riskScore.Value : DBNull.Value);
                command.Parameters.AddWithValue("@DebtToIncomeRatio",
                    debtToIncomeRatio.HasValue ? (object)debtToIncomeRatio.Value : DBNull.Value);

                connection.Open();
                command.ExecuteNonQuery();
            }
        }

        /// <summary>
        /// Retrieves all loan decisions for a specific application.
        /// Returns decision history including evaluation results and approval/rejection details.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve decisions for.</param>
        /// <returns>A collection of loan decisions for the application.</returns>
        public IEnumerable<LoanDecision> GetByApplication(int applicationId)
        {
            var decisions = new List<LoanDecision>();

            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand())
            {
                command.Connection = connection;
                command.CommandType = CommandType.Text;
                command.CommandText = @"
                    SELECT 
                        DecisionId,
                        ApplicationId,
                        Decision,
                        DecisionBy,
                        DecisionDate,
                        Comments,
                        ApprovedAmount,
                        InterestRate,
                        RiskScore,
                        DebtToIncomeRatio
                    FROM LoanDecisions
                    WHERE ApplicationId = @ApplicationId
                    ORDER BY DecisionDate DESC";

                command.Parameters.AddWithValue("@ApplicationId", applicationId);

                connection.Open();
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        decisions.Add(MapLoanDecisionFromReader(reader));
                    }
                }
            }

            return decisions;
        }

        /// <summary>
        /// Maps a SqlDataReader row to a LoanDecision object.
        /// Demonstrates manual result mapping pattern common in legacy applications.
        /// </summary>
        /// <param name="reader">The SqlDataReader positioned at a loan decision row.</param>
        /// <returns>A LoanDecision object populated from the reader.</returns>
        private LoanDecision MapLoanDecisionFromReader(SqlDataReader reader)
        {
            return new LoanDecision
            {
                DecisionId = reader.GetInt32(reader.GetOrdinal("DecisionId")),
                ApplicationId = reader.GetInt32(reader.GetOrdinal("ApplicationId")),
                Decision = reader.GetString(reader.GetOrdinal("Decision")),
                DecisionBy = reader.GetString(reader.GetOrdinal("DecisionBy")),
                DecisionDate = reader.GetDateTime(reader.GetOrdinal("DecisionDate")),
                Comments = reader.IsDBNull(reader.GetOrdinal("Comments"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("Comments")),
                ApprovedAmount = reader.IsDBNull(reader.GetOrdinal("ApprovedAmount"))
                    ? (decimal?)null
                    : reader.GetDecimal(reader.GetOrdinal("ApprovedAmount")),
                InterestRate = reader.IsDBNull(reader.GetOrdinal("InterestRate"))
                    ? (decimal?)null
                    : reader.GetDecimal(reader.GetOrdinal("InterestRate")),
                RiskScore = reader.IsDBNull(reader.GetOrdinal("RiskScore"))
                    ? (int?)null
                    : reader.GetInt32(reader.GetOrdinal("RiskScore")),
                DebtToIncomeRatio = reader.IsDBNull(reader.GetOrdinal("DebtToIncomeRatio"))
                    ? (decimal?)null
                    : reader.GetDecimal(reader.GetOrdinal("DebtToIncomeRatio"))
            };
        }
    }
}
