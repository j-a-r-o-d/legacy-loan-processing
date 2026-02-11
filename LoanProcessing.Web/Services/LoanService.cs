using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service implementation for loan business operations.
    /// Wraps repository calls with validation and error handling, providing meaningful error messages.
    /// Demonstrates legacy service layer pattern with business context added to exceptions.
    /// </summary>
    public class LoanService : ILoanService
    {
        private readonly ILoanApplicationRepository _loanRepo;
        private readonly ILoanDecisionRepository _decisionRepo;
        private readonly IPaymentScheduleRepository _scheduleRepo;

        /// <summary>
        /// Initializes a new instance of the LoanService class.
        /// </summary>
        /// <param name="loanRepo">The loan application repository for data access.</param>
        /// <param name="decisionRepo">The loan decision repository for data access.</param>
        /// <param name="scheduleRepo">The payment schedule repository for data access.</param>
        public LoanService(
            ILoanApplicationRepository loanRepo,
            ILoanDecisionRepository decisionRepo,
            IPaymentScheduleRepository scheduleRepo)
        {
            if (loanRepo == null)
            {
                throw new ArgumentNullException(nameof(loanRepo));
            }

            if (decisionRepo == null)
            {
                throw new ArgumentNullException(nameof(decisionRepo));
            }

            if (scheduleRepo == null)
            {
                throw new ArgumentNullException(nameof(scheduleRepo));
            }

            _loanRepo = loanRepo;
            _decisionRepo = decisionRepo;
            _scheduleRepo = scheduleRepo;
        }

        /// <summary>
        /// Retrieves all loan applications.
        /// </summary>
        /// <returns>A collection of all loan applications.</returns>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public IEnumerable<LoanApplication> GetAllApplications()
        {
            try
            {
                return _loanRepo.GetAll();
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException(
                    "Failed to retrieve loan applications. Database error occurred.", ex);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    "An unexpected error occurred while retrieving loan applications.", ex);
            }
        }

        /// <summary>
        /// Retrieves a loan application by its unique identifier.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve.</param>
        /// <returns>The loan application if found; otherwise, null.</returns>
        /// <exception cref="ArgumentException">Thrown when applicationId is invalid.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public LoanApplication GetApplicationById(int applicationId)
        {
            try
            {
                if (applicationId <= 0)
                {
                    throw new ArgumentException("Application ID must be greater than zero.", nameof(applicationId));
                }

                return _loanRepo.GetById(applicationId);
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException(
                    $"Failed to retrieve loan application with ID {applicationId}. Database error occurred.", ex);
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    $"An unexpected error occurred while retrieving loan application with ID {applicationId}.", ex);
            }
        }

        /// <summary>
        /// Submits a new loan application with validation and error handling.
        /// Validation happens in stored procedure.
        /// </summary>
        /// <param name="application">The loan application to submit.</param>
        /// <returns>The newly created application ID.</returns>
        /// <exception cref="ArgumentNullException">Thrown when application is null.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public int SubmitLoanApplication(LoanApplication application)
        {
            if (application == null)
            {
                throw new ArgumentNullException(nameof(application));
            }

            try
            {
                return _loanRepo.SubmitApplication(application);
            }
            catch (SqlException ex)
            {
                // Translate database errors to business-friendly messages
                if (ex.Message.Contains("Customer not found"))
                {
                    throw new InvalidOperationException(
                        $"Customer with ID {application.CustomerId} was not found in the system.", ex);
                }
                else if (ex.Message.Contains("exceeds maximum"))
                {
                    throw new InvalidOperationException(
                        $"The requested loan amount of {application.RequestedAmount:C} exceeds the maximum allowed for {application.LoanType} loans.", ex);
                }
                else if (ex.Message.Contains("Loan term must be"))
                {
                    throw new InvalidOperationException(
                        $"The loan term of {application.TermMonths} months is invalid. Loan term must be between 12 and 360 months.", ex);
                }
                else
                {
                    throw new InvalidOperationException(
                        "Failed to submit loan application. Database error occurred.", ex);
                }
            }
            catch (ArgumentNullException)
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
                    "An unexpected error occurred while submitting the loan application.", ex);
            }
        }

        /// <summary>
        /// Performs credit evaluation for a loan application.
        /// Credit evaluation logic is implemented in stored procedure.
        /// </summary>
        /// <param name="applicationId">The application ID to evaluate.</param>
        /// <returns>A LoanDecision object containing evaluation results.</returns>
        /// <exception cref="ArgumentException">Thrown when applicationId is invalid.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public LoanDecision EvaluateCredit(int applicationId)
        {
            try
            {
                if (applicationId <= 0)
                {
                    throw new ArgumentException("Application ID must be greater than zero.", nameof(applicationId));
                }

                var result = _decisionRepo.EvaluateCredit(applicationId);

                if (result == null)
                {
                    throw new InvalidOperationException(
                        $"Loan application with ID {applicationId} was not found or could not be evaluated.");
                }

                return result;
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException(
                    $"Failed to evaluate credit for loan application {applicationId}. Database error occurred.", ex);
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
                    $"An unexpected error occurred while evaluating credit for loan application {applicationId}.", ex);
            }
        }

        /// <summary>
        /// Processes a loan decision (approval or rejection) with validation and error handling.
        /// Decision processing and payment schedule generation happen in stored procedure.
        /// </summary>
        /// <param name="applicationId">The application ID to process.</param>
        /// <param name="decision">The decision (Approved or Rejected).</param>
        /// <param name="comments">Optional comments about the decision.</param>
        /// <param name="decidedBy">The name of the person making the decision.</param>
        /// <exception cref="ArgumentException">Thrown when parameters are invalid.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public void ProcessLoanDecision(int applicationId, string decision, string comments, string decidedBy)
        {
            try
            {
                if (applicationId <= 0)
                {
                    throw new ArgumentException("Application ID must be greater than zero.", nameof(applicationId));
                }

                if (string.IsNullOrWhiteSpace(decision))
                {
                    throw new ArgumentException("Decision cannot be null or empty.", nameof(decision));
                }

                if (string.IsNullOrWhiteSpace(decidedBy))
                {
                    throw new ArgumentException("DecidedBy cannot be null or empty.", nameof(decidedBy));
                }

                // Validate decision value
                if (decision != "Approved" && decision != "Rejected")
                {
                    throw new ArgumentException("Decision must be either 'Approved' or 'Rejected'.", nameof(decision));
                }

                _decisionRepo.ProcessDecision(applicationId, decision, decidedBy, comments);
            }
            catch (SqlException ex)
            {
                // Translate database errors to business-friendly messages
                if (ex.Message.Contains("not found") || ex.Message.Contains("does not exist"))
                {
                    throw new InvalidOperationException(
                        $"Loan application with ID {applicationId} was not found in the system.", ex);
                }
                else if (ex.Message.Contains("exceeds requested amount"))
                {
                    throw new InvalidOperationException(
                        "The approved amount cannot exceed the requested loan amount.", ex);
                }
                else
                {
                    throw new InvalidOperationException(
                        $"Failed to process loan decision for application {applicationId}. Database error occurred.", ex);
                }
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
                    $"An unexpected error occurred while processing loan decision for application {applicationId}.", ex);
            }
        }

        /// <summary>
        /// Retrieves the payment schedule for an approved loan application.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve the payment schedule for.</param>
        /// <returns>A collection of payment schedule entries for the application.</returns>
        /// <exception cref="ArgumentException">Thrown when applicationId is invalid.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public IEnumerable<PaymentSchedule> GetPaymentSchedule(int applicationId)
        {
            try
            {
                if (applicationId <= 0)
                {
                    throw new ArgumentException("Application ID must be greater than zero.", nameof(applicationId));
                }

                return _scheduleRepo.GetScheduleByApplication(applicationId);
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException(
                    $"Failed to retrieve payment schedule for loan application {applicationId}. Database error occurred.", ex);
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
                    $"An unexpected error occurred while retrieving payment schedule for loan application {applicationId}.", ex);
            }
        }
    }
}
