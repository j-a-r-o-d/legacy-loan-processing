using System;
using System.ComponentModel.DataAnnotations;
using System.Configuration;
using System.Linq;
using System.Web.Mvc;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;
using LoanProcessing.Web.Services;

namespace LoanProcessing.Web.Controllers
{
    /// <summary>
    /// Controller for loan application management operations.
    /// Demonstrates legacy ASP.NET MVC 5 patterns with manual dependency injection.
    /// </summary>
    public class LoanController : Controller
    {
        private readonly ILoanService _loanService;
        private readonly ICustomerService _customerService;

        /// <summary>
        /// Initializes a new instance of the LoanController class.
        /// Uses manual dependency injection pattern typical of legacy applications.
        /// </summary>
        public LoanController()
        {
            // Manual dependency injection - typical legacy pattern
            var connectionString = ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString;
            var loanRepo = new LoanApplicationRepository(connectionString);
            var decisionRepo = new LoanDecisionRepository(connectionString);
            var scheduleRepo = new PaymentScheduleRepository(connectionString);
            var customerRepo = new CustomerRepository(connectionString);
            
            _loanService = new LoanService(loanRepo, decisionRepo, scheduleRepo);
            _customerService = new CustomerService(customerRepo);
        }

        /// <summary>
        /// Constructor for dependency injection (used in testing).
        /// </summary>
        /// <param name="loanService">The loan service instance.</param>
        /// <param name="customerService">The customer service instance.</param>
        public LoanController(ILoanService loanService, ICustomerService customerService)
        {
            _loanService = loanService ?? throw new ArgumentNullException(nameof(loanService));
            _customerService = customerService ?? throw new ArgumentNullException(nameof(customerService));
        }

        /// <summary>
        /// GET: Loan/Index
        /// Displays a list of all loan applications.
        /// </summary>
        /// <returns>View with list of loan applications.</returns>
        public ActionResult Index()
        {
            try
            {
                var applications = _loanService.GetAllApplications();
                return View(applications);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading loan applications: " + ex.Message;
                return View();
            }
        }

        /// <summary>
        /// GET: Loan/Details/5
        /// Displays detailed information for a specific loan application.
        /// </summary>
        /// <param name="id">The application ID.</param>
        /// <returns>View with loan application details.</returns>
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                TempData["Error"] = "Application ID is required.";
                return RedirectToAction("Index");
            }

            try
            {
                var application = _loanService.GetApplicationById(id.Value);
                if (application == null)
                {
                    TempData["Error"] = $"Loan application with ID {id} not found.";
                    return RedirectToAction("Index");
                }

                // Get payment schedule if application is approved
                if (application.Status == "Approved")
                {
                    ViewBag.PaymentSchedule = _loanService.GetPaymentSchedule(id.Value);
                }

                return View(application);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading loan application details: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// GET: Loan/SearchCustomers
        /// AJAX endpoint for customer autocomplete search.
        /// Returns JSON array of matching customers in jQuery UI autocomplete format.
        /// </summary>
        /// <param name="term">The search term entered by the user (minimum 2 characters).</param>
        /// <returns>JSON array of customer objects with id, label, value, and customerId properties.</returns>
        [HttpGet]
        public JsonResult SearchCustomers(string term)
        {
            // Validate input - return empty array for invalid input
            if (string.IsNullOrWhiteSpace(term) || term.Length < 2)
            {
                // Log invalid search attempt (Requirement 7.2)
                System.Diagnostics.Debug.WriteLine($"[SearchCustomers] Invalid search term: term is null, empty, or less than 2 characters");
                return Json(new object[] { }, JsonRequestBehavior.AllowGet);
            }

            // Log search request with masked search term (Requirement 7.2)
            // Mask any potential SSN values in the search term for privacy
            string maskedTerm = MaskSearchTermForLogging(term);
            System.Diagnostics.Debug.WriteLine($"[SearchCustomers] Search request received: term='{maskedTerm}'");

            // Start performance monitoring (Requirement 3.1)
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                // Call service to search customers (service handles SSN masking)
                var customers = _customerService.SearchCustomersForAutocomplete(term);
                
                // Transform to jQuery UI autocomplete format
                // Format: { id, label, value, customerId }
                var results = customers.Select(c => new
                {
                    id = c.CustomerId,
                    label = $"{c.LastName}, {c.FirstName} (ID: {c.CustomerId}, SSN: {MaskSSN(c.SSN)})",
                    value = $"{c.FirstName} {c.LastName}",
                    customerId = c.CustomerId
                }).ToList();

                // Stop performance monitoring and log execution time (Requirement 3.1)
                stopwatch.Stop();
                long executionTimeMs = stopwatch.ElapsedMilliseconds;

                // Log search result count and execution time (Requirement 7.2, 3.1)
                System.Diagnostics.Debug.WriteLine($"[SearchCustomers] Search completed: term='{maskedTerm}', resultCount={results.Count}, executionTime={executionTimeMs}ms");

                // Add warning for slow queries (>500ms) (Requirement 3.1)
                if (executionTimeMs > 500)
                {
                    System.Diagnostics.Debug.WriteLine($"[SearchCustomers] WARNING: Slow query detected: term='{maskedTerm}', executionTime={executionTimeMs}ms exceeds 500ms threshold");
                }

                return Json(results, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                // Stop performance monitoring on error
                stopwatch.Stop();
                long executionTimeMs = stopwatch.ElapsedMilliseconds;

                // Log error with full exception details and execution time (Requirement 7.2, 3.1)
                System.Diagnostics.Debug.WriteLine($"[SearchCustomers] Error searching customers: term='{maskedTerm}', executionTime={executionTimeMs}ms, error='{ex.Message}', stackTrace='{ex.StackTrace}'");
                
                // Return empty array on error to gracefully handle failures
                return Json(new object[] { }, JsonRequestBehavior.AllowGet);
            }
        }

        /// <summary>
        /// GET: Loan/Apply
        /// Displays the form to apply for a new loan.
        /// Modified to support autocomplete instead of dropdown.
        /// </summary>
        /// <param name="customerId">Optional customer ID to pre-populate the form.</param>
        /// <returns>View with loan application form.</returns>
        public ActionResult Apply(int? customerId)
        {
            try
            {
                var model = new LoanApplication();

                if (customerId.HasValue)
                {
                    // Existing pre-selected customer workflow
                    var customer = _customerService.GetById(customerId.Value);
                    if (customer == null)
                    {
                        TempData["Error"] = $"Customer with ID {customerId} not found.";
                        return RedirectToAction("Index", "Customer");
                    }

                    model.CustomerId = customerId.Value;
                    ViewBag.CustomerName = $"{customer.FirstName} {customer.LastName}";
                    ViewBag.IsPreSelected = true;
                }
                else
                {
                    // New autocomplete workflow - no longer load all customers
                    ViewBag.IsPreSelected = false;
                }

                // Populate loan types for dropdown
                ViewBag.LoanTypes = new SelectList(new[] { "Personal", "Auto", "Mortgage", "Business" });

                return View(model);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading loan application form: " + ex.Message;
                return RedirectToAction("Index", "Customer");
            }
        }

        /// <summary>
        /// POST: Loan/Apply
        /// Processes the submission of a new loan application.
        /// </summary>
        /// <param name="application">The loan application data from the form.</param>
        /// <returns>Redirect to Details on success, or View with errors on failure.</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Apply(LoanApplication application)
        {
            if (!ModelState.IsValid)
            {
                // Repopulate dropdown
                ViewBag.LoanTypes = new SelectList(new[] { "Personal", "Auto", "Mortgage", "Business" });
                return View(application);
            }

            try
            {
                // Validate that the customer exists (Requirement 4.4)
                var customer = _customerService.GetById(application.CustomerId);
                if (customer == null)
                {
                    ModelState.AddModelError("CustomerId", $"Customer with ID {application.CustomerId} not found.");
                    ViewBag.LoanTypes = new SelectList(new[] { "Personal", "Auto", "Mortgage", "Business" });
                    return View(application);
                }

                int applicationId = _loanService.SubmitLoanApplication(application);
                TempData["Success"] = "Loan application submitted successfully.";
                return RedirectToAction("Details", new { id = applicationId });
            }
            catch (ArgumentException ex)
            {
                ModelState.AddModelError("", ex.Message);
                ViewBag.LoanTypes = new SelectList(new[] { "Personal", "Auto", "Mortgage", "Business" });
                return View(application);
            }
            catch (InvalidOperationException ex)
            {
                ModelState.AddModelError("", ex.Message);
                ViewBag.LoanTypes = new SelectList(new[] { "Personal", "Auto", "Mortgage", "Business" });
                return View(application);
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "An unexpected error occurred: " + ex.Message);
                ViewBag.LoanTypes = new SelectList(new[] { "Personal", "Auto", "Mortgage", "Business" });
                return View(application);
            }
        }

        /// <summary>
        /// GET: Loan/Evaluate/5
        /// Triggers credit evaluation for a loan application and displays the results.
        /// </summary>
        /// <param name="id">The application ID to evaluate.</param>
        /// <returns>View with credit evaluation results.</returns>
        public ActionResult Evaluate(int? id)
        {
            if (id == null)
            {
                TempData["Error"] = "Application ID is required.";
                return RedirectToAction("Index");
            }

            try
            {
                var evaluation = _loanService.EvaluateCredit(id.Value);
                if (evaluation == null)
                {
                    TempData["Error"] = $"Unable to evaluate loan application with ID {id}.";
                    return RedirectToAction("Index");
                }

                // Get the application details for context
                var application = _loanService.GetApplicationById(id.Value);
                ViewBag.Application = application;

                TempData["Success"] = "Credit evaluation completed successfully.";
                return View(evaluation);
            }
            catch (ArgumentException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Details", new { id });
            }
            catch (InvalidOperationException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Details", new { id });
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error evaluating credit: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// GET: Loan/Decide/5
        /// Displays the form to make a decision on a loan application.
        /// </summary>
        /// <param name="id">The application ID to decide on.</param>
        /// <returns>View with loan decision form.</returns>
        public ActionResult Decide(int? id)
        {
            if (id == null)
            {
                TempData["Error"] = "Application ID is required.";
                return RedirectToAction("Index");
            }

            try
            {
                var application = _loanService.GetApplicationById(id.Value);
                if (application == null)
                {
                    TempData["Error"] = $"Loan application with ID {id} not found.";
                    return RedirectToAction("Index");
                }

                // Check if application is in a valid state for decision
                if (application.Status != "Pending" && application.Status != "UnderReview")
                {
                    TempData["Error"] = $"Cannot make a decision on an application with status '{application.Status}'.";
                    return RedirectToAction("Details", new { id });
                }

                ViewBag.Application = application;
                ViewBag.Decisions = new SelectList(new[] { "Approved", "Rejected" });

                return View(new LoanDecisionViewModel
                {
                    ApplicationId = id.Value,
                    ApprovedAmount = application.RequestedAmount
                });
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading loan decision form: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// POST: Loan/Decide
        /// Processes a loan decision (approval or rejection).
        /// </summary>
        /// <param name="model">The loan decision data from the form.</param>
        /// <returns>Redirect to Details on success, or View with errors on failure.</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Decide(LoanDecisionViewModel model)
        {
            if (!ModelState.IsValid)
            {
                var application = _loanService.GetApplicationById(model.ApplicationId);
                ViewBag.Application = application;
                ViewBag.Decisions = new SelectList(new[] { "Approved", "Rejected" });
                return View(model);
            }

            try
            {
                // Validate rejection reason
                if (model.Decision == "Rejected" && string.IsNullOrWhiteSpace(model.Comments))
                {
                    ModelState.AddModelError("Comments", "Comments are required when rejecting a loan application.");
                    var application = _loanService.GetApplicationById(model.ApplicationId);
                    ViewBag.Application = application;
                    ViewBag.Decisions = new SelectList(new[] { "Approved", "Rejected" });
                    return View(model);
                }

                _loanService.ProcessLoanDecision(
                    model.ApplicationId,
                    model.Decision,
                    model.Comments,
                    model.DecisionBy ?? "System"
                );

                TempData["Success"] = $"Loan application {model.Decision.ToLower()} successfully.";
                return RedirectToAction("Details", new { id = model.ApplicationId });
            }
            catch (ArgumentException ex)
            {
                ModelState.AddModelError("", ex.Message);
                var application = _loanService.GetApplicationById(model.ApplicationId);
                ViewBag.Application = application;
                ViewBag.Decisions = new SelectList(new[] { "Approved", "Rejected" });
                return View(model);
            }
            catch (InvalidOperationException ex)
            {
                ModelState.AddModelError("", ex.Message);
                var application = _loanService.GetApplicationById(model.ApplicationId);
                ViewBag.Application = application;
                ViewBag.Decisions = new SelectList(new[] { "Approved", "Rejected" });
                return View(model);
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "An unexpected error occurred: " + ex.Message);
                var application = _loanService.GetApplicationById(model.ApplicationId);
                ViewBag.Application = application;
                ViewBag.Decisions = new SelectList(new[] { "Approved", "Rejected" });
                return View(model);
            }
        }

        /// <summary>
        /// GET: Loan/Schedule/5
        /// Displays the payment schedule for an approved loan application.
        /// </summary>
        /// <param name="id">The application ID to view the payment schedule for.</param>
        /// <returns>View with payment schedule.</returns>
        public ActionResult Schedule(int? id)
        {
            if (id == null)
            {
                TempData["Error"] = "Application ID is required.";
                return RedirectToAction("Index");
            }

            try
            {
                var application = _loanService.GetApplicationById(id.Value);
                if (application == null)
                {
                    TempData["Error"] = $"Loan application with ID {id} not found.";
                    return RedirectToAction("Index");
                }

                if (application.Status != "Approved")
                {
                    TempData["Error"] = "Payment schedule is only available for approved loan applications.";
                    return RedirectToAction("Details", new { id });
                }

                var schedule = _loanService.GetPaymentSchedule(id.Value);
                if (schedule == null || !schedule.Any())
                {
                    TempData["Error"] = "Payment schedule not found for this loan application.";
                    return RedirectToAction("Details", new { id });
                }

                ViewBag.Application = application;
                return View(schedule);
            }
            catch (ArgumentException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Details", new { id });
            }
            catch (InvalidOperationException ex)
            {
                TempData["Error"] = ex.Message;
                return RedirectToAction("Details", new { id });
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading payment schedule: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// Masks SSN to show only last 4 digits in the format ***-**-XXXX.
        /// Handles null/empty SSN values by returning a fully masked format.
        /// </summary>
        /// <param name="ssn">The SSN to mask.</param>
        /// <returns>Masked SSN string in format ***-**-XXXX.</returns>
        private string MaskSSN(string ssn)
        {
            // Handle null or empty SSN
            if (string.IsNullOrEmpty(ssn))
            {
                return "***-**-****";
            }

            // Handle SSN with less than 4 characters
            if (ssn.Length < 4)
            {
                return "***-**-****";
            }

            // Return masked SSN with last 4 digits visible
            return "***-**-" + ssn.Substring(ssn.Length - 4);
        }

        /// <summary>
        /// Masks search terms for logging to protect privacy (Requirement 7.2).
        /// If the search term looks like an SSN (9 digits with or without dashes),
        /// it will be masked to show only the last 4 digits.
        /// </summary>
        /// <param name="searchTerm">The search term to mask.</param>
        /// <returns>Masked search term safe for logging.</returns>
        private string MaskSearchTermForLogging(string searchTerm)
        {
            if (string.IsNullOrEmpty(searchTerm))
            {
                return "[empty]";
            }

            // Remove any dashes or spaces to check if it's a potential SSN
            string digitsOnly = new string(searchTerm.Where(char.IsDigit).ToArray());

            // If the search term contains 9 digits, treat it as a potential SSN and mask it
            if (digitsOnly.Length == 9)
            {
                // Mask all but last 4 digits
                return "***-**-" + digitsOnly.Substring(5);
            }

            // If the search term contains 4 or more digits (could be last 4 of SSN), mask it
            if (digitsOnly.Length >= 4 && digitsOnly.Length < 9)
            {
                // Mask to show it's a numeric search without revealing the actual digits
                return $"[numeric:{digitsOnly.Length}digits]";
            }

            // For non-SSN searches (names, etc.), return as-is
            // Limit length to prevent log flooding
            return searchTerm.Length > 50 ? searchTerm.Substring(0, 50) + "..." : searchTerm;
        }
    }

    /// <summary>
    /// View model for loan decision form.
    /// </summary>
    public class LoanDecisionViewModel
    {
        public int ApplicationId { get; set; }
        
        [Required(ErrorMessage = "Decision is required")]
        public string Decision { get; set; }
        
        public string DecisionBy { get; set; }
        
        public string Comments { get; set; }
        
        [Range(0.01, double.MaxValue, ErrorMessage = "Approved amount must be greater than zero")]
        public decimal? ApprovedAmount { get; set; }
    }
}
