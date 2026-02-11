using System.Collections.Generic;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository interface for payment schedule data access operations.
    /// Encapsulates stored procedure calls for payment schedule management.
    /// </summary>
    public interface IPaymentScheduleRepository
    {
        /// <summary>
        /// Retrieves the payment schedule for a specific loan application.
        /// Returns all scheduled payments including principal, interest, and remaining balance.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve the payment schedule for.</param>
        /// <returns>A collection of payment schedule entries for the application.</returns>
        IEnumerable<PaymentSchedule> GetScheduleByApplication(int applicationId);

        /// <summary>
        /// Calculates and generates a payment schedule for an approved loan.
        /// Calls sp_CalculatePaymentSchedule stored procedure which creates an amortization schedule
        /// with monthly payments including principal and interest breakdown.
        /// </summary>
        /// <param name="applicationId">The application ID to calculate the payment schedule for.</param>
        void CalculateSchedule(int applicationId);
    }
}
