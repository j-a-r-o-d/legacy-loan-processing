using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Services
{
    /// <summary>
    /// Service implementation for customer business operations.
    /// Wraps repository calls with validation and error handling, providing meaningful error messages.
    /// Demonstrates legacy service layer pattern with business context added to exceptions.
    /// </summary>
    public class CustomerService : ICustomerService
    {
        private readonly ICustomerRepository _customerRepository;

        /// <summary>
        /// Initializes a new instance of the CustomerService class.
        /// </summary>
        /// <param name="customerRepository">The customer repository for data access.</param>
        public CustomerService(ICustomerRepository customerRepository)
        {
            if (customerRepository == null)
            {
                throw new ArgumentNullException(nameof(customerRepository));
            }

            _customerRepository = customerRepository;
        }

        /// <summary>
        /// Retrieves a customer by their unique identifier.
        /// </summary>
        /// <param name="customerId">The customer ID to retrieve.</param>
        /// <returns>The customer if found; otherwise, null.</returns>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public Customer GetById(int customerId)
        {
            try
            {
                if (customerId <= 0)
                {
                    throw new ArgumentException("Customer ID must be greater than zero.", nameof(customerId));
                }

                return _customerRepository.GetById(customerId);
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException(
                    $"Failed to retrieve customer with ID {customerId}. Database error occurred.", ex);
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    $"An unexpected error occurred while retrieving customer with ID {customerId}.", ex);
            }
        }

        /// <summary>
        /// Searches for customers based on search criteria.
        /// </summary>
        /// <param name="searchTerm">Optional search term to match against customer names, SSN, or ID.</param>
        /// <returns>A collection of customers matching the search criteria.</returns>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public IEnumerable<Customer> Search(string searchTerm)
        {
            try
            {
                return _customerRepository.Search(searchTerm);
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException(
                    "Failed to search for customers. Database error occurred.", ex);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    "An unexpected error occurred while searching for customers.", ex);
            }
        }

        /// <summary>
        /// Creates a new customer with validation and error handling.
        /// </summary>
        /// <param name="customer">The customer to create.</param>
        /// <returns>The newly created customer ID.</returns>
        /// <exception cref="ArgumentNullException">Thrown when customer is null.</exception>
        /// <exception cref="ArgumentException">Thrown when customer data is invalid.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public int CreateCustomer(Customer customer)
        {
            if (customer == null)
            {
                throw new ArgumentNullException(nameof(customer));
            }

            try
            {
                // Basic validation before calling repository
                ValidateCustomer(customer);

                return _customerRepository.CreateCustomer(customer);
            }
            catch (ArgumentNullException)
            {
                throw;
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (SqlException ex)
            {
                // Translate database errors to business-friendly messages
                if (ex.Message.Contains("SSN already exists"))
                {
                    throw new InvalidOperationException(
                        $"A customer with SSN {customer.SSN} already exists in the system.", ex);
                }
                else if (ex.Message.Contains("18 years old"))
                {
                    throw new InvalidOperationException(
                        "Customer must be at least 18 years old to be registered in the system.", ex);
                }
                else if (ex.Message.Contains("Credit score"))
                {
                    throw new InvalidOperationException(
                        "Credit score must be between 300 and 850.", ex);
                }
                else
                {
                    throw new InvalidOperationException(
                        "Failed to create customer. Database error occurred.", ex);
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    "An unexpected error occurred while creating the customer.", ex);
            }
        }

        /// <summary>
        /// Updates an existing customer's information with validation and error handling.
        /// </summary>
        /// <param name="customer">The customer with updated information.</param>
        /// <exception cref="ArgumentNullException">Thrown when customer is null.</exception>
        /// <exception cref="ArgumentException">Thrown when customer data is invalid.</exception>
        /// <exception cref="InvalidOperationException">Thrown when database operation fails.</exception>
        public void UpdateCustomer(Customer customer)
        {
            if (customer == null)
            {
                throw new ArgumentNullException(nameof(customer));
            }

            try
            {
                // Basic validation before calling repository
                if (customer.CustomerId <= 0)
                {
                    throw new ArgumentException("Customer ID must be greater than zero.", nameof(customer));
                }

                ValidateCustomer(customer);

                _customerRepository.UpdateCustomer(customer);
            }
            catch (ArgumentNullException)
            {
                throw;
            }
            catch (ArgumentException)
            {
                throw;
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (SqlException ex)
            {
                // Translate database errors to business-friendly messages
                if (ex.Message.Contains("not found") || ex.Message.Contains("does not exist"))
                {
                    throw new InvalidOperationException(
                        $"Customer with ID {customer.CustomerId} was not found in the system.", ex);
                }
                else if (ex.Message.Contains("Credit score"))
                {
                    throw new InvalidOperationException(
                        "Credit score must be between 300 and 850.", ex);
                }
                else
                {
                    throw new InvalidOperationException(
                        $"Failed to update customer with ID {customer.CustomerId}. Database error occurred.", ex);
                }
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    $"An unexpected error occurred while updating customer with ID {customer.CustomerId}.", ex);
            }
        }

        /// <summary>
        /// Searches for customers for autocomplete functionality.
        /// Returns up to 10 customers matching the search term.
        /// Searches by customer ID and SSN for numeric input, by first name and last name for alphabetic input,
        /// and across all fields for mixed alphanumeric input.
        /// SSN values in results are masked to show only the last 4 digits for privacy.
        /// </summary>
        /// <param name="searchTerm">The search term (minimum 2 characters, maximum 100 characters).</param>
        /// <returns>Collection of matching customers (maximum 10) with masked SSN values, ordered by relevance.</returns>
        /// <exception cref="ArgumentException">Thrown when search term exceeds maximum length.</exception>
        public IEnumerable<Customer> SearchCustomersForAutocomplete(string searchTerm)
        {
            // Return empty collection for invalid input (null, empty, or less than 2 characters)
            if (string.IsNullOrWhiteSpace(searchTerm) || searchTerm.Length < 2)
            {
                return new List<Customer>();
            }

            // Validate search term length to prevent performance issues
            if (searchTerm.Length > 100)
            {
                throw new ArgumentException("Search term cannot exceed 100 characters.", nameof(searchTerm));
            }

            try
            {
                // Call repository with search term
                var customers = _customerRepository.SearchForAutocomplete(searchTerm);

                // Mask SSN in results for privacy
                var result = new List<Customer>();
                foreach (var customer in customers)
                {
                    // Create a copy to avoid modifying the original object
                    var maskedCustomer = new Customer
                    {
                        CustomerId = customer.CustomerId,
                        FirstName = customer.FirstName,
                        LastName = customer.LastName,
                        SSN = MaskSSN(customer.SSN),
                        DateOfBirth = customer.DateOfBirth,
                        AnnualIncome = customer.AnnualIncome,
                        CreditScore = customer.CreditScore,
                        Email = customer.Email,
                        Phone = customer.Phone,
                        Address = customer.Address,
                        CreatedDate = customer.CreatedDate,
                        ModifiedDate = customer.ModifiedDate
                    };
                    result.Add(maskedCustomer);
                }

                return result;
            }
            catch (SqlException ex)
            {
                throw new InvalidOperationException(
                    "Failed to search for customers. Database error occurred.", ex);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    "An unexpected error occurred while searching for customers.", ex);
            }
        }

        /// <summary>
        /// Masks SSN to show only last 4 digits.
        /// </summary>
        /// <param name="ssn">The SSN to mask.</param>
        /// <returns>Masked SSN in format ***-**-XXXX.</returns>
        private string MaskSSN(string ssn)
        {
            if (string.IsNullOrEmpty(ssn) || ssn.Length < 4)
            {
                return "***-**-****";
            }

            return "***-**-" + ssn.Substring(ssn.Length - 4);
        }

        /// <summary>
        /// Validates customer data before database operations.
        /// </summary>
        /// <param name="customer">The customer to validate.</param>
        /// <exception cref="ArgumentException">Thrown when customer data is invalid.</exception>
        private void ValidateCustomer(Customer customer)
        {
            if (string.IsNullOrWhiteSpace(customer.FirstName))
            {
                throw new ArgumentException("First name is required.", nameof(customer));
            }

            if (string.IsNullOrWhiteSpace(customer.LastName))
            {
                throw new ArgumentException("Last name is required.", nameof(customer));
            }

            if (string.IsNullOrWhiteSpace(customer.SSN))
            {
                throw new ArgumentException("SSN is required.", nameof(customer));
            }

            if (customer.DateOfBirth == default(DateTime))
            {
                throw new ArgumentException("Date of birth is required.", nameof(customer));
            }

            if (customer.AnnualIncome < 0)
            {
                throw new ArgumentException("Annual income cannot be negative.", nameof(customer));
            }

            if (customer.CreditScore < 300 || customer.CreditScore > 850)
            {
                throw new ArgumentException("Credit score must be between 300 and 850.", nameof(customer));
            }

            if (string.IsNullOrWhiteSpace(customer.Email))
            {
                throw new ArgumentException("Email is required.", nameof(customer));
            }

            if (string.IsNullOrWhiteSpace(customer.Phone))
            {
                throw new ArgumentException("Phone is required.", nameof(customer));
            }

            if (string.IsNullOrWhiteSpace(customer.Address))
            {
                throw new ArgumentException("Address is required.", nameof(customer));
            }
        }
    }
}
