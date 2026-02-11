using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using LoanProcessing.Web.Models;

namespace LoanProcessing.Web.Data
{
    /// <summary>
    /// Repository implementation for payment schedule data access using ADO.NET and stored procedures.
    /// Demonstrates legacy pattern with manual parameter mapping and result set handling.
    /// </summary>
    public class PaymentScheduleRepository : IPaymentScheduleRepository
    {
        private readonly string _connectionString;

        /// <summary>
        /// Initializes a new instance of the PaymentScheduleRepository class.
        /// </summary>
        /// <param name="connectionString">The database connection string.</param>
        public PaymentScheduleRepository(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new ArgumentNullException(nameof(connectionString));
            }

            _connectionString = connectionString;
        }

        /// <summary>
        /// Initializes a new instance of the PaymentScheduleRepository class using the default connection string.
        /// </summary>
        public PaymentScheduleRepository()
            : this(ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString)
        {
        }

        /// <summary>
        /// Retrieves the payment schedule for a specific loan application.
        /// Returns all scheduled payments including principal, interest, and remaining balance.
        /// </summary>
        /// <param name="applicationId">The application ID to retrieve the payment schedule for.</param>
        /// <returns>A collection of payment schedule entries for the application.</returns>
        public IEnumerable<PaymentSchedule> GetScheduleByApplication(int applicationId)
        {
            var schedules = new List<PaymentSchedule>();

            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand())
            {
                command.Connection = connection;
                command.CommandType = CommandType.Text;
                command.CommandText = @"
                    SELECT 
                        ScheduleId,
                        ApplicationId,
                        PaymentNumber,
                        DueDate,
                        PaymentAmount,
                        PrincipalAmount,
                        InterestAmount,
                        RemainingBalance
                    FROM PaymentSchedules
                    WHERE ApplicationId = @ApplicationId
                    ORDER BY PaymentNumber";

                command.Parameters.AddWithValue("@ApplicationId", applicationId);

                connection.Open();
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        schedules.Add(MapPaymentScheduleFromReader(reader));
                    }
                }
            }

            return schedules;
        }

        /// <summary>
        /// Calculates and generates a payment schedule for an approved loan.
        /// Calls sp_CalculatePaymentSchedule stored procedure which creates an amortization schedule
        /// with monthly payments including principal and interest breakdown.
        /// </summary>
        /// <param name="applicationId">The application ID to calculate the payment schedule for.</param>
        /// <exception cref="SqlException">Thrown when database operation fails.</exception>
        public void CalculateSchedule(int applicationId)
        {
            using (var connection = new SqlConnection(_connectionString))
            using (var command = new SqlCommand("sp_CalculatePaymentSchedule", connection))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@ApplicationId", applicationId);

                connection.Open();
                command.ExecuteNonQuery();
            }
        }

        /// <summary>
        /// Maps a SqlDataReader row to a PaymentSchedule object.
        /// Demonstrates manual result mapping pattern common in legacy applications.
        /// </summary>
        /// <param name="reader">The SqlDataReader positioned at a payment schedule row.</param>
        /// <returns>A PaymentSchedule object populated from the reader.</returns>
        private PaymentSchedule MapPaymentScheduleFromReader(SqlDataReader reader)
        {
            return new PaymentSchedule
            {
                ScheduleId = reader.GetInt32(reader.GetOrdinal("ScheduleId")),
                ApplicationId = reader.GetInt32(reader.GetOrdinal("ApplicationId")),
                PaymentNumber = reader.GetInt32(reader.GetOrdinal("PaymentNumber")),
                DueDate = reader.GetDateTime(reader.GetOrdinal("DueDate")),
                PaymentAmount = reader.GetDecimal(reader.GetOrdinal("PaymentAmount")),
                PrincipalAmount = reader.GetDecimal(reader.GetOrdinal("PrincipalAmount")),
                InterestAmount = reader.GetDecimal(reader.GetOrdinal("InterestAmount")),
                RemainingBalance = reader.GetDecimal(reader.GetOrdinal("RemainingBalance"))
            };
        }
    }
}
