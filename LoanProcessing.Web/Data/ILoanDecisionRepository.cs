using System.Collections.Generic;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository interface for loan decision data access operations.
    /// Encapsulates stored procedure calls for credit evaluation and loan decision processing.
    /// </summary>
    public interface ILoanDecisionRepository
    {
        /// <summary>
        /// Performs credit evaluation for a loan application.
        /// Calls sp_EvaluateCredit stored procedure which calculates risk score,
        /// debt-to-income ratio, and determines appropriate interest rate.
        /// </summary>
        /// <param name="applicationId">The application ID to evaluate.</param>
        /// <returns>A LoanDecision object containing evaluation results.</returns>
        LoanDecision EvaluateCredit(int applicationId);

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
        void ProcessDecision(int applicationId, string decision, string decisionBy, 
            string comments = null, decimal? approvedAmount = null, 
            int? riskScore = null, decimal? debtToIncomeRatio = null);

        /// <summary>
        /// Retrieves all loan decisions for a specific application.
        /// Returns decision history including evaluation results and approval/rejection details.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve decisions for.</param>
        /// <returns>A collection of loan decisions for the application.</returns>
        IEnumerable<LoanDecision> GetByApplication(int applicationId);
    }
}
