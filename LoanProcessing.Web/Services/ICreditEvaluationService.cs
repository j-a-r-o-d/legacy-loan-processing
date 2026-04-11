using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service interface for credit evaluation.
    /// Pre-extraction: delegates to sp_EvaluateCredit.
    /// Post-extraction: uses CreditEvaluationCalculator with repository data access.
    /// </summary>
    public interface ICreditEvaluationService
    {
        /// <summary>
        /// Evaluates credit for a loan application.
        /// </summary>
        /// <param name="applicationId">The application ID to evaluate.</param>
        /// <returns>A LoanDecision with RiskScore, DTI, InterestRate, and Recommendation.</returns>
        LoanDecision Evaluate(int applicationId);
    }
}
