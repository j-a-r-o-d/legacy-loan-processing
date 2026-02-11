using System;
using System.ComponentModel.DataAnnotations;

namespace LoanProcessing.Web.Models
{
    public class PaymentSchedule
    {
        public int ScheduleId { get; set; }

        [Required]
        public int ApplicationId { get; set; }

        [Required]
        public int PaymentNumber { get; set; }

        [Required]
        [DataType(DataType.Date)]
        public DateTime DueDate { get; set; }

        [Required]
        [Range(0, double.MaxValue, ErrorMessage = "Payment amount must be positive")]
        public decimal PaymentAmount { get; set; }

        [Required]
        [Range(0, double.MaxValue, ErrorMessage = "Principal amount must be positive")]
        public decimal PrincipalAmount { get; set; }

        [Required]
        [Range(0, double.MaxValue, ErrorMessage = "Interest amount must be positive")]
        public decimal InterestAmount { get; set; }

        [Required]
        [Range(0, double.MaxValue, ErrorMessage = "Remaining balance must be positive")]
        public decimal RemainingBalance { get; set; }

        // Navigation properties
        public virtual LoanApplication LoanApplication { get; set; }
    }
}
