using System;
using System.ComponentModel.DataAnnotations;

namespace LoanProcessing.Web.Models
{
    public class LoanDecision
    {
        public int DecisionId { get; set; }

        [Required]
        public int ApplicationId { get; set; }

        [Required]
        [StringLength(20)]
        public string Decision { get; set; } // Approved, Rejected

        [Required]
        [StringLength(100)]
        public string DecisionBy { get; set; }

        public DateTime DecisionDate { get; set; }

        [StringLength(1000)]
        public string Comments { get; set; }

        public decimal? ApprovedAmount { get; set; }

        public decimal? InterestRate { get; set; }

        [Range(0, 100, ErrorMessage = "Risk score must be between 0 and 100")]
        public int? RiskScore { get; set; }

        public decimal? DebtToIncomeRatio { get; set; }

        // Navigation properties
        public virtual LoanApplication LoanApplication { get; set; }
    }
}
