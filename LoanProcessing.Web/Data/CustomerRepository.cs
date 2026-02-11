using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository implementation for customer data access using ADO.NET and stored procedures.
    /// Demonstrates legacy pattern with manual parameter mapping and result set handling.
    /// </summary>
    public class CustomerRepository : ICustomerRepository
    {
        private readonly string _connectionString;

        /// <summary>
        /// Initializes a new instance of the CustomerRepository class.
        /// </summary>
        /// <param name="connectionString">The database connection string.</param>
        public CustomerRepository(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new ArgumentNullException(nameof(connectionString));
            }

            _connectionString = connectionString;
        }

        /// <summary>
        /// Initializes a new instance of the CustomerRepository class using the default connection string.
        /// </summary>
        public CustomerRepository()
            : this(ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString)
        {
        }

        /// <summary>
        /// Retrieves a customer by their unique identifier.
        /// Calls sp_GetCustomerById stored procedure.
        /// </summary>
        /// <param name="customerId">The customer ID to retrieve.</param>
        /// <returns>The customer if found; otherwise, null.</returns>
        public Customer GetById(int customerId)
        {
            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_GetCustomerById", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@CustomerId", customerId);

                connection.Open();
                using (var reader = command.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        return MapCustomerFromReader(reader);
                    }
                }
            }

            return null;
        }

        /// <summary>
        /// Searches for customers based on search criteria.
        /// Calls sp_SearchCustomers stored procedure.
        /// </summary>
        /// <param name="searchTerm">Optional search term to match against customer names.</param>
        /// <returns>A collection of customers matching the search criteria.</returns>
        public IEnumerable<Customer> Search(string searchTerm)
        {
            var customers = new List<Customer>();

            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_SearchCustomers", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                
                // Add parameters - use DBNull.Value for null values
                command.Parameters.AddWithValue("@SearchTerm", 
                    string.IsNullOrWhiteSpace(searchTerm) ? (object)DBNull.Value : searchTerm);
                command.Parameters.AddWithValue("@CustomerId", DBNull.Value);
                command.Parameters.AddWithValue("@SSN", DBNull.Value);

                connection.Open();
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        customers.Add(MapCustomerFromReader(reader));
                    }
                }
            }

            return customers;
        }

        /// <summary>
        /// Creates a new customer in the database.
        /// Calls sp_CreateCustomer stored procedure with manual parameter mapping.
        /// </summary>
        /// <param name="customer">The customer to create.</param>
        /// <returns>The newly created customer ID.</returns>
        /// <exception cref="ArgumentNullException">Thrown when customer is null.</exception>
        /// <exception cref="SqlException">Thrown when database operation fails.</exception>
        public int CreateCustomer(Customer customer)
        {
            if (customer == null)
            {
                throw new ArgumentNullException(nameof(customer));
            }

            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_CreateCustomer", connection))
            {
                command.CommandType = CommandType.StoredProcedure;

                // Manual parameter mapping - legacy pattern
                command.Parameters.AddWithValue("@FirstName", customer.FirstName);
                command.Parameters.AddWithValue("@LastName", customer.LastName);
                command.Parameters.AddWithValue("@SSN", customer.SSN);
                command.Parameters.AddWithValue("@DateOfBirth", customer.DateOfBirth);
                command.Parameters.AddWithValue("@AnnualIncome", customer.AnnualIncome);
                command.Parameters.AddWithValue("@CreditScore", customer.CreditScore);
                command.Parameters.AddWithValue("@Email", customer.Email);
                command.Parameters.AddWithValue("@Phone", customer.Phone);
                command.Parameters.AddWithValue("@Address", customer.Address);

                // Output parameter for the new customer ID
                var outputParam = new SqlParameter("@CustomerId", SqlDbType.Int)
                {
                    Direction = ParameterDirection.Output
                };
                command.Parameters.Add(outputParam);

                connection.Open();
                command.ExecuteNonQuery();

                return (int)outputParam.Value;
            }
        }

        /// <summary>
        /// Updates an existing customer's information.
        /// Calls sp_UpdateCustomer stored procedure with manual parameter mapping.
        /// </summary>
        /// <param name="customer">The customer with updated information.</param>
        /// <exception cref="ArgumentNullException">Thrown when customer is null.</exception>
        /// <exception cref="SqlException">Thrown when database operation fails.</exception>
        public void UpdateCustomer(Customer customer)
        {
            if (customer == null)
            {
                throw new ArgumentNullException(nameof(customer));
            }

            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_UpdateCustomer", connection))
            {
                command.CommandType = CommandType.StoredProcedure;

                // Manual parameter mapping - legacy pattern
                command.Parameters.AddWithValue("@CustomerId", customer.CustomerId);
                command.Parameters.AddWithValue("@FirstName", customer.FirstName);
                command.Parameters.AddWithValue("@LastName", customer.LastName);
                command.Parameters.AddWithValue("@DateOfBirth", customer.DateOfBirth);
                command.Parameters.AddWithValue("@AnnualIncome", customer.AnnualIncome);
                command.Parameters.AddWithValue("@CreditScore", customer.CreditScore);
                command.Parameters.AddWithValue("@Email", customer.Email);
                command.Parameters.AddWithValue("@Phone", customer.Phone);
                command.Parameters.AddWithValue("@Address", customer.Address);

                connection.Open();
                command.ExecuteNonQuery();
            }
        }

        /// <summary>
        /// Searches for customers for autocomplete functionality.
        /// Calls sp_SearchCustomersAutocomplete stored procedure.
        /// Returns up to 10 customers ordered by relevance.
        /// </summary>
        /// <param name="searchTerm">The search term to match.</param>
        /// <returns>Collection of matching customers (max 10).</returns>
        /// <exception cref="SqlException">Thrown when database operation fails.</exception>
        public IEnumerable<Customer> SearchForAutocomplete(string searchTerm)
        {
            var customers = new List<Customer>();

            try
            {
                using (var connection = new SqlConnection(_connectionString))
                using (var command = new SqlCommand("sp_SearchCustomersAutocomplete", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.AddWithValue("@SearchTerm", searchTerm ?? string.Empty);

                    connection.Open();
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            customers.Add(MapCustomerFromReader(reader));
                        }
                    }
                }
            }
            catch (SqlException ex)
            {
                // Log the exception and rethrow to allow higher layers to handle
                // In a production system, this would use a proper logging framework
                System.Diagnostics.Debug.WriteLine($"Database error in SearchForAutocomplete: {ex.Message}");
                throw;
            }

            return customers;
        }

        /// <summary>
        /// Maps a SqlDataReader row to a Customer object.
        /// Demonstrates manual result mapping pattern common in legacy applications.
        /// </summary>
        /// <param name="reader">The SqlDataReader positioned at a customer row.</param>
        /// <returns>A Customer object populated from the reader.</returns>
        private Customer MapCustomerFromReader(SqlDataReader reader)
        {
            return new Customer
            {
                CustomerId = reader.GetInt32(reader.GetOrdinal("CustomerId")),
                FirstName = reader.GetString(reader.GetOrdinal("FirstName")),
                LastName = reader.GetString(reader.GetOrdinal("LastName")),
                SSN = reader.GetString(reader.GetOrdinal("SSN")),
                DateOfBirth = reader.GetDateTime(reader.GetOrdinal("DateOfBirth")),
                AnnualIncome = reader.GetDecimal(reader.GetOrdinal("AnnualIncome")),
                CreditScore = reader.GetInt32(reader.GetOrdinal("CreditScore")),
                Email = reader.GetString(reader.GetOrdinal("Email")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                Address = reader.GetString(reader.GetOrdinal("Address")),
                CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                ModifiedDate = reader.IsDBNull(reader.GetOrdinal("ModifiedDate")) 
                    ? (DateTime?)null 
                    : reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
            };
        }
    }
}
