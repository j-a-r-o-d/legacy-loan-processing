using System;
using System.ComponentModel.DataAnnotations;

namespace LoanProcessing.Web.Models
{
    public class InterestRate
    {
        public int RateId { get; set; }

        [Required]
        [StringLength(20)]
        public string LoanType { get; set; }

        [Required]
        [Range(300, 850, ErrorMessage = "Minimum credit score must be between 300 and 850")]
        public int MinCreditScore { get; set; }

        [Required]
        [Range(300, 850, ErrorMessage = "Maximum credit score must be between 300 and 850")]
        public int MaxCreditScore { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Minimum term months must be positive")]
        public int MinTermMonths { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Maximum term months must be positive")]
        public int MaxTermMonths { get; set; }

        [Required]
        [Range(0.01, 100, ErrorMessage = "Rate must be between 0.01 and 100")]
        public decimal Rate { get; set; }

        [Required]
        [DataType(DataType.Date)]
        public DateTime EffectiveDate { get; set; }

        [DataType(DataType.Date)]
        public DateTime? ExpirationDate { get; set; }
    }
}
