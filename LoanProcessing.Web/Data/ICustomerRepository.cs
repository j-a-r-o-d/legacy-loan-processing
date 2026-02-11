using System.Collections.Generic;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository interface for customer data access operations.
    /// Encapsulates stored procedure calls for customer management.
    /// </summary>
    public interface ICustomerRepository
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
        /// <param name="searchTerm">Optional search term to match against customer names.</param>
        /// <returns>A collection of customers matching the search criteria.</returns>
        IEnumerable<Customer> Search(string searchTerm);

        /// <summary>
        /// Creates a new customer in the database.
        /// </summary>
        /// <param name="customer">The customer to create.</param>
        /// <returns>The newly created customer ID.</returns>
        int CreateCustomer(Customer customer);

        /// <summary>
        /// Updates an existing customer's information.
        /// </summary>
        /// <param name="customer">The customer with updated information.</param>
        void UpdateCustomer(Customer customer);

        /// <summary>
        /// Searches for customers for autocomplete functionality.
        /// Calls sp_SearchCustomersAutocomplete stored procedure.
        /// Returns up to 10 customers ordered by relevance (exact matches first, then partial matches).
        /// Supports searching by customer ID, SSN (last 4 digits), first name, and last name.
        /// </summary>
        /// <param name="searchTerm">The search term to match against customer data (minimum 2 characters).</param>
        /// <returns>A collection of matching customers (maximum 10 results).</returns>
        IEnumerable<Customer> SearchForAutocomplete(string searchTerm);
    }
}
