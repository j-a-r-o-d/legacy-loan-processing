using System;
using System.Collections.Generic;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository interface for interest rate data access operations.
    /// </summary>
    public interface IInterestRateRepository
    {
        /// <summary>
        /// Gets all interest rates.
        /// </summary>
        /// <returns>Collection of all interest rates.</returns>
        IEnumerable<InterestRate> GetAll();

        /// <summary>
        /// Gets an interest rate by ID.
        /// </summary>
        /// <param name="rateId">The rate ID.</param>
        /// <returns>The interest rate, or null if not found.</returns>
        InterestRate GetById(int rateId);

        /// <summary>
        /// Gets all active interest rates (not expired).
        /// </summary>
        /// <returns>Collection of active interest rates.</returns>
        IEnumerable<InterestRate> GetActiveRates();

        /// <summary>
        /// Creates a new interest rate.
        /// </summary>
        /// <param name="rate">The interest rate to create.</param>
        /// <returns>The ID of the newly created rate.</returns>
        int CreateRate(InterestRate rate);

        /// <summary>
        /// Updates an existing interest rate.
        /// </summary>
        /// <param name="rate">The interest rate to update.</param>
        void UpdateRate(InterestRate rate);
    }
}
