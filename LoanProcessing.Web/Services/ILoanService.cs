using System.Collections.Generic;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service interface for loan business operations.
    /// Provides a layer of abstraction over the repository with error handling and validation.
    /// </summary>
    public interface ILoanService
    {
        /// <summary>
        /// Retrieves all loan applications.
        /// </summary>
        /// <returns>A collection of all loan applications.</returns>
        IEnumerable<LoanApplication> GetAllApplications();

        /// <summary>
        /// Retrieves a loan application by its unique identifier.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve.</param>
        /// <returns>The loan application if found; otherwise, null.</returns>
        LoanApplication GetApplicationById(int applicationId);

        /// <summary>
        /// Submits a new loan application with validation and error handling.
        /// </summary>
        /// <param name="application">The loan application to submit.</param>
        /// <returns>The newly created application ID.</returns>
        int SubmitLoanApplication(LoanApplication application);

        /// <summary>
        /// Performs credit evaluation for a loan application.
        /// Calculates risk score, debt-to-income ratio, and determines appropriate interest rate.
        /// </summary>
        /// <param name="applicationId">The application ID to evaluate.</param>
        /// <returns>A LoanDecision object containing evaluation results.</returns>
        LoanDecision EvaluateCredit(int applicationId);

        /// <summary>
        /// Processes a loan decision (approval or rejection) with validation and error handling.
        /// </summary>
        /// <param name="applicationId">The application ID to process.</param>
        /// <param name="decision">The decision (Approved or Rejected).</param>
        /// <param name="comments">Optional comments about the decision.</param>
        /// <param name="decidedBy">The name of the person making the decision.</param>
        void ProcessLoanDecision(int applicationId, string decision, string comments, string decidedBy);

        /// <summary>
        /// Retrieves the payment schedule for an approved loan application.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve the payment schedule for.</param>
        /// <returns>A collection of payment schedule entries for the application.</returns>
        IEnumerable<PaymentSchedule> GetPaymentSchedule(int applicationId);
    }
}
