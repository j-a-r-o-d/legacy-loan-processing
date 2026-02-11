using System.Collections.Generic;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository interface for loan application data access operations.
    /// Encapsulates stored procedure calls for loan application management.
    /// </summary>
    public interface ILoanApplicationRepository
    {
        /// <summary>
        /// Retrieves all loan applications.
        /// </summary>
        /// <returns>A collection of all loan applications.</returns>
        IEnumerable<LoanApplication> GetAll();

        /// <summary>
        /// Submits a new loan application to the database.
        /// Calls sp_SubmitLoanApplication stored procedure.
        /// </summary>
        /// <param name="application">The loan application to submit.</param>
        /// <returns>The newly created application ID.</returns>
        int SubmitApplication(LoanApplication application);

        /// <summary>
        /// Retrieves a loan application by its unique identifier.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve.</param>
        /// <returns>The loan application if found; otherwise, null.</returns>
        LoanApplication GetById(int applicationId);

        /// <summary>
        /// Retrieves all loan applications for a specific customer.
        /// </summary>
        /// <param name="customerId">The customer ID to retrieve applications for.</param>
        /// <returns>A collection of loan applications for the customer.</returns>
        IEnumerable<LoanApplication> GetByCustomer(int customerId);
    }
}
