using System.Collections.Generic;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service interface for customer business operations.
    /// Provides a layer of abstraction over the repository with error handling and validation.
    /// </summary>
    public interface ICustomerService
    {
        /// <summary>
        /// Retrieves a customer by their unique identifier.
        /// </summary>
        /// <param name="customerId">The customer ID to retrieve.</param>
        /// <returns>The customer if found; otherwise, null.</returns>
        Customer GetById(int customerId);

        /// <summary>
        /// Searches for customers based on search criteria.
        /// </summary>
        /// <param name="searchTerm">Optional search term to match against customer names, SSN, or ID.</param>
        /// <returns>A collection of customers matching the search criteria.</returns>
        IEnumerable<Customer> Search(string searchTerm);

        /// <summary>
        /// Creates a new customer with validation and error handling.
        /// </summary>
        /// <param name="customer">The customer to create.</param>
        /// <returns>The newly created customer ID.</returns>
        int CreateCustomer(Customer customer);

        /// <summary>
        /// Updates an existing customer's information with validation and error handling.
        /// </summary>
        /// <param name="customer">The customer with updated information.</param>
        void UpdateCustomer(Customer customer);

        /// <summary>
        /// Searches for customers for autocomplete functionality.
        /// Returns up to 10 customers matching the search term.
        /// Searches by customer ID and SSN for numeric input, by first name and last name for alphabetic input,
        /// and across all fields for mixed alphanumeric input.
        /// SSN values in results are masked to show only the last 4 digits for privacy.
        /// </summary>
        /// <param name="searchTerm">The search term (minimum 2 characters, maximum 100 characters).</param>
        /// <returns>Collection of matching customers (maximum 10) with masked SSN values, ordered by relevance.</returns>
        /// <exception cref="System.ArgumentException">Thrown when search term exceeds maximum length.</exception>
        IEnumerable<Customer> SearchCustomersForAutocomplete(string searchTerm);
    }
}
