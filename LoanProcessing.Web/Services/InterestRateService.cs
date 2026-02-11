using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service for interest rate business operations.
    /// Provides validation and error handling on top of repository operations.
    /// </summary>
    public class InterestRateService : IInterestRateService
    {
        private readonly IInterestRateRepository _rateRepository;

        /// <summary>
        /// Initializes a new instance of the InterestRateService class.
        /// </summary>
        /// <param name="rateRepository">The interest rate repository.</param>
        public InterestRateService(IInterestRateRepository rateRepository)
        {
            _rateRepository = rateRepository ?? throw new ArgumentNullException(nameof(rateRepository));
        }

        /// <summary>
        /// Gets all interest rates.
        /// </summary>
        /// <returns>Collection of all interest rates.</returns>
        public IEnumerable<InterestRate> GetAll()
        {
            try
            {
                return _rateRepository.GetAll();
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException("Error retrieving interest rates from database.", ex);
            }
        }

        /// <summary>
        /// Gets an interest rate by ID.
        /// </summary>
        /// <param name="rateId">The rate ID.</param>
        /// <returns>The interest rate, or null if not found.</returns>
        public InterestRate GetById(int rateId)
        {
            if (rateId <= 0)
            {
                throw new ArgumentException("Rate ID must be positive.", nameof(rateId));
            }

            try
            {
                return _rateRepository.GetById(rateId);
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException($"Error retrieving interest rate with ID {rateId}.", ex);
            }
        }

        /// <summary>
        /// Gets all active interest rates (not expired).
        /// </summary>
        /// <returns>Collection of active interest rates.</returns>
        public IEnumerable<InterestRate> GetActiveRates()
        {
            try
            {
                return _rateRepository.GetActiveRates();
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException("Error retrieving active interest rates from database.", ex);
            }
        }

        /// <summary>
        /// Creates a new interest rate with validation.
        /// </summary>
        /// <param name="rate">The interest rate to create.</param>
        /// <returns>The ID of the newly created rate.</returns>
        public int CreateRate(InterestRate rate)
        {
            if (rate == null)
            {
                throw new ArgumentNullException(nameof(rate));
            }

            // Validate rate ranges
            ValidateRateRanges(rate);

            // Validate effective dates
            ValidateEffectiveDates(rate);

            try
            {
                return _rateRepository.CreateRate(rate);
            }
            catch (SqlException ex)
            {
                // Check for constraint violations
                if (ex.Number == 547) // Foreign key violation
                {
                    throw new InvalidOperationException("Invalid loan type specified.", ex);
                }
                else if (ex.Number == 2627 || ex.Number == 2601) // Unique constraint violation
                {
                    throw new InvalidOperationException("A rate with these parameters already exists.", ex);
                }
                else
                {
                    throw new InvalidOperationException("Error creating interest rate.", ex);
                }
            }
        }

        /// <summary>
        /// Updates an existing interest rate with validation.
        /// </summary>
        /// <param name="rate">The interest rate to update.</param>
        public void UpdateRate(InterestRate rate)
        {
            if (rate == null)
            {
                throw new ArgumentNullException(nameof(rate));
            }

            if (rate.RateId <= 0)
            {
                throw new ArgumentException("Rate ID must be positive.", nameof(rate));
            }

            // Validate rate ranges
            ValidateRateRanges(rate);

            // Validate effective dates
            ValidateEffectiveDates(rate);

            try
            {
                _rateRepository.UpdateRate(rate);
            }
            catch (SqlException ex)
            {
                // Check for constraint violations
                if (ex.Number == 547) // Foreign key violation
                {
                    throw new InvalidOperationException("Invalid loan type specified.", ex);
                }
                else if (ex.Number == 2627 || ex.Number == 2601) // Unique constraint violation
                {
                    throw new InvalidOperationException("A rate with these parameters already exists.", ex);
                }
                else
                {
                    throw new InvalidOperationException($"Error updating interest rate with ID {rate.RateId}.", ex);
                }
            }
        }

        /// <summary>
        /// Validates rate ranges (credit score and term ranges).
        /// </summary>
        /// <param name="rate">The interest rate to validate.</param>
        private void ValidateRateRanges(InterestRate rate)
        {
            // Validate credit score range
            if (rate.MinCreditScore < 300 || rate.MinCreditScore > 850)
            {
                throw new ArgumentException("Minimum credit score must be between 300 and 850.", nameof(rate));
            }

            if (rate.MaxCreditScore < 300 || rate.MaxCreditScore > 850)
            {
                throw new ArgumentException("Maximum credit score must be between 300 and 850.", nameof(rate));
            }

            if (rate.MinCreditScore > rate.MaxCreditScore)
            {
                throw new ArgumentException("Minimum credit score cannot be greater than maximum credit score.", nameof(rate));
            }

            // Validate term range
            if (rate.MinTermMonths <= 0)
            {
                throw new ArgumentException("Minimum term months must be positive.", nameof(rate));
            }

            if (rate.MaxTermMonths <= 0)
            {
                throw new ArgumentException("Maximum term months must be positive.", nameof(rate));
            }

            if (rate.MinTermMonths > rate.MaxTermMonths)
            {
                throw new ArgumentException("Minimum term months cannot be greater than maximum term months.", nameof(rate));
            }

            // Validate rate value
            if (rate.Rate <= 0 || rate.Rate > 100)
            {
                throw new ArgumentException("Rate must be between 0.01 and 100.", nameof(rate));
            }

            // Validate loan type
            if (string.IsNullOrWhiteSpace(rate.LoanType))
            {
                throw new ArgumentException("Loan type is required.", nameof(rate));
            }

            var validLoanTypes = new[] { "Personal", "Auto", "Mortgage", "Business" };
            if (Array.IndexOf(validLoanTypes, rate.LoanType) == -1)
            {
                throw new ArgumentException("Loan type must be one of: Personal, Auto, Mortgage, Business.", nameof(rate));
            }
        }

        /// <summary>
        /// Validates effective dates.
        /// </summary>
        /// <param name="rate">The interest rate to validate.</param>
        private void ValidateEffectiveDates(InterestRate rate)
        {
            // Effective date is required
            if (rate.EffectiveDate == default(DateTime))
            {
                throw new ArgumentException("Effective date is required.", nameof(rate));
            }

            // If expiration date is set, it must be after effective date
            if (rate.ExpirationDate.HasValue && rate.ExpirationDate.Value <= rate.EffectiveDate)
            {
                throw new ArgumentException("Expiration date must be after effective date.", nameof(rate));
            }
        }
    }
}
