using System;
using System.Configuration;
using System.Web.Mvc;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;
using LoanProcessing.Web.Services;

namespace LoanProcessing.Web.Controllers
{
    /// <summary>
    /// Controller for interest rate management operations.
    /// Demonstrates legacy ASP.NET MVC 5 patterns with manual dependency injection.
    /// </summary>
    public class InterestRateController : Controller
    {
        private readonly IInterestRateService _rateService;

        /// <summary>
        /// Initializes a new instance of the InterestRateController class.
        /// Uses manual dependency injection pattern typical of legacy applications.
        /// </summary>
        public InterestRateController()
        {
            // Manual dependency injection - typical legacy pattern
            var connectionString = ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString;
            var rateRepository = new InterestRateRepository(connectionString);
            _rateService = new InterestRateService(rateRepository);
        }

        /// <summary>
        /// Constructor for dependency injection (used in testing).
        /// </summary>
        /// <param name="rateService">The interest rate service instance.</param>
        public InterestRateController(IInterestRateService rateService)
        {
            _rateService = rateService ?? throw new ArgumentNullException(nameof(rateService));
        }

        /// <summary>
        /// GET: InterestRate/Index
        /// Displays a list of all interest rates.
        /// </summary>
        /// <returns>View with list of interest rates.</returns>
        public ActionResult Index()
        {
            try
            {
                var rates = _rateService.GetAll();
                return View(rates);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading interest rates: " + ex.Message;
                return View();
            }
        }

        /// <summary>
        /// GET: InterestRate/Create
        /// Displays the form to create a new interest rate.
        /// </summary>
        /// <returns>View with empty interest rate form.</returns>
        public ActionResult Create()
        {
            var rate = new InterestRate
            {
                EffectiveDate = DateTime.Today
            };
            PopulateLoanTypeSelectList();
            return View(rate);
        }

        /// <summary>
        /// POST: InterestRate/Create
        /// Processes the creation of a new interest rate.
        /// </summary>
        /// <param name="rate">The interest rate data from the form.</param>
        /// <returns>Redirect to Index on success, or View with errors on failure.</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(InterestRate rate)
        {
            if (!ModelState.IsValid)
            {
                PopulateLoanTypeSelectList();
                return View(rate);
            }

            try
            {
                int rateId = _rateService.CreateRate(rate);
                TempData["Success"] = $"Interest rate for {rate.LoanType} loans created successfully.";
                return RedirectToAction("Index");
            }
            catch (ArgumentException ex)
            {
                ModelState.AddModelError("", ex.Message);
                PopulateLoanTypeSelectList();
                return View(rate);
            }
            catch (InvalidOperationException ex)
            {
                ModelState.AddModelError("", ex.Message);
                PopulateLoanTypeSelectList();
                return View(rate);
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "An unexpected error occurred: " + ex.Message);
                PopulateLoanTypeSelectList();
                return View(rate);
            }
        }

        /// <summary>
        /// GET: InterestRate/Edit/5
        /// Displays the form to edit an existing interest rate.
        /// </summary>
        /// <param name="id">The rate ID.</param>
        /// <returns>View with interest rate data for editing.</returns>
        public ActionResult Edit(int? id)
        {
            if (id == null)
            {
                TempData["Error"] = "Rate ID is required.";
                return RedirectToAction("Index");
            }

            try
            {
                var rate = _rateService.GetById(id.Value);
                if (rate == null)
                {
                    TempData["Error"] = $"Interest rate with ID {id} not found.";
                    return RedirectToAction("Index");
                }

                PopulateLoanTypeSelectList(rate.LoanType);
                return View(rate);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading interest rate for editing: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// POST: InterestRate/Edit/5
        /// Processes the update of an existing interest rate.
        /// </summary>
        /// <param name="rate">The updated interest rate data from the form.</param>
        /// <returns>Redirect to Index on success, or View with errors on failure.</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(InterestRate rate)
        {
            if (!ModelState.IsValid)
            {
                PopulateLoanTypeSelectList(rate.LoanType);
                return View(rate);
            }

            try
            {
                _rateService.UpdateRate(rate);
                TempData["Success"] = $"Interest rate for {rate.LoanType} loans updated successfully.";
                return RedirectToAction("Index");
            }
            catch (ArgumentException ex)
            {
                ModelState.AddModelError("", ex.Message);
                PopulateLoanTypeSelectList(rate.LoanType);
                return View(rate);
            }
            catch (InvalidOperationException ex)
            {
                ModelState.AddModelError("", ex.Message);
                PopulateLoanTypeSelectList(rate.LoanType);
                return View(rate);
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "An unexpected error occurred: " + ex.Message);
                PopulateLoanTypeSelectList(rate.LoanType);
                return View(rate);
            }
        }

        /// <summary>
        /// Populates the ViewBag with loan type options for dropdown.
        /// </summary>
        /// <param name="selectedValue">The currently selected loan type.</param>
        private void PopulateLoanTypeSelectList(string selectedValue = null)
        {
            ViewBag.LoanTypes = new SelectList(
                new[] { "Personal", "Auto", "Mortgage", "Business" },
                selectedValue
            );
        }
    }
}
