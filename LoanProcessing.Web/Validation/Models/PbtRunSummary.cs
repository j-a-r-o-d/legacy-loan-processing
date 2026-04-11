using System;

namespace LoanProcessing.Web.Validation.Models
{
    public class PbtRunSummary
    {
        public int TotalProperties { get; set; }
        public int PassedProperties { get; set; }
        public DateTime RunTimestamp { get; set; }
        public string BuildId { get; set; }
    }
}
