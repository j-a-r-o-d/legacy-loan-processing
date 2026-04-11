using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Credit evaluation service.
    /// Pre-extraction stub: delegates to sp_EvaluateCredit via SqlCommand.
    /// This will be replaced with C# calculator + repository logic during extraction.
    /// </summary>
    public class CreditEvaluationService : ICreditEvaluationService
    {
        private readonly string _connectionString;

        public CreditEvaluationService(string connectionString)
        {
            _connectionString = connectionString;
        }

        public CreditEvaluationService()
        {
            _connectionString = ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString;
        }

        public LoanDecision Evaluate(int applicationId)
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
                            Comments = reader.GetString(reader.GetOrdinal("Recommendation"))
                        };
                    }
                }
            }

            return null;
        }
    }
}
