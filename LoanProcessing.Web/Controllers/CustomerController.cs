using System;
using System.Configuration;
using System.Web.Mvc;
using LoanProcessing.Web.Data;
using LoanProcessing.Web.Models;
using LoanProcessing.Web.Services;

namespace LoanProcessing.Web.Controllers
{
    /// <summary>
    /// Controller for customer management operations.
    /// Demonstrates legacy ASP.NET MVC 5 patterns with manual dependency injection.
    /// </summary>
    public class CustomerController : Controller
    {
        private readonly ICustomerService _customerService;

        /// <summary>
        /// Initializes a new instance of the CustomerController class.
        /// Uses manual dependency injection pattern typical of legacy applications.
        /// </summary>
        public CustomerController()
        {
            // Manual dependency injection - typical legacy pattern
            var connectionString = ConfigurationManager.ConnectionStrings["LoanProcessingConnection"].ConnectionString;
            var customerRepository = new CustomerRepository(connectionString);
            _customerService = new CustomerService(customerRepository);
        }

        /// <summary>
        /// Constructor for dependency injection (used in testing).
        /// </summary>
        /// <param name="customerService">The customer service instance.</param>
        public CustomerController(ICustomerService customerService)
        {
            _customerService = customerService ?? throw new ArgumentNullException(nameof(customerService));
        }

        /// <summary>
        /// GET: Customer/Index
        /// Displays a list of all customers.
        /// </summary>
        /// <returns>View with list of customers.</returns>
        public ActionResult Index()
        {
            try
            {
                var customers = _customerService.Search(null);
                return View(customers);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading customers: " + ex.Message;
                return View();
            }
        }

        /// <summary>
        /// GET: Customer/Details/5
        /// Displays detailed information for a specific customer.
        /// </summary>
        /// <param name="id">The customer ID.</param>
        /// <returns>View with customer details.</returns>
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                TempData["Error"] = "Customer ID is required.";
                return RedirectToAction("Index");
            }

            try
            {
                var customer = _customerService.GetById(id.Value);
                if (customer == null)
                {
                    TempData["Error"] = $"Customer with ID {id} not found.";
                    return RedirectToAction("Index");
                }

                return View(customer);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading customer details: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// GET: Customer/Create
        /// Displays the form to create a new customer.
        /// </summary>
        /// <returns>View with empty customer form.</returns>
        public ActionResult Create()
        {
            return View(new Customer());
        }

        /// <summary>
        /// POST: Customer/Create
        /// Processes the creation of a new customer.
        /// </summary>
        /// <param name="customer">The customer data from the form.</param>
        /// <returns>Redirect to Index on success, or View with errors on failure.</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(Customer customer)
        {
            if (!ModelState.IsValid)
            {
                return View(customer);
            }

            try
            {
                int customerId = _customerService.CreateCustomer(customer);
                TempData["Success"] = $"Customer {customer.FirstName} {customer.LastName} created successfully.";
                return RedirectToAction("Details", new { id = customerId });
            }
            catch (ArgumentException ex)
            {
                ModelState.AddModelError("", ex.Message);
                return View(customer);
            }
            catch (InvalidOperationException ex)
            {
                ModelState.AddModelError("", ex.Message);
                return View(customer);
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "An unexpected error occurred: " + ex.Message);
                return View(customer);
            }
        }

        /// <summary>
        /// GET: Customer/Edit/5
        /// Displays the form to edit an existing customer.
        /// </summary>
        /// <param name="id">The customer ID.</param>
        /// <returns>View with customer data for editing.</returns>
        public ActionResult Edit(int? id)
        {
            if (id == null)
            {
                TempData["Error"] = "Customer ID is required.";
                return RedirectToAction("Index");
            }

            try
            {
                var customer = _customerService.GetById(id.Value);
                if (customer == null)
                {
                    TempData["Error"] = $"Customer with ID {id} not found.";
                    return RedirectToAction("Index");
                }

                return View(customer);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error loading customer for editing: " + ex.Message;
                return RedirectToAction("Index");
            }
        }

        /// <summary>
        /// POST: Customer/Edit/5
        /// Processes the update of an existing customer.
        /// </summary>
        /// <param name="customer">The updated customer data from the form.</param>
        /// <returns>Redirect to Details on success, or View with errors on failure.</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(Customer customer)
        {
            if (!ModelState.IsValid)
            {
                return View(customer);
            }

            try
            {
                _customerService.UpdateCustomer(customer);
                TempData["Success"] = $"Customer {customer.FirstName} {customer.LastName} updated successfully.";
                return RedirectToAction("Details", new { id = customer.CustomerId });
            }
            catch (ArgumentException ex)
            {
                ModelState.AddModelError("", ex.Message);
                return View(customer);
            }
            catch (InvalidOperationException ex)
            {
                ModelState.AddModelError("", ex.Message);
                return View(customer);
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "An unexpected error occurred: " + ex.Message);
                return View(customer);
            }
        }

        /// <summary>
        /// GET: Customer/Search
        /// Searches for customers based on search criteria.
        /// </summary>
        /// <param name="searchTerm">The search term to filter customers.</param>
        /// <returns>View with filtered list of customers.</returns>
        public ActionResult Search(string searchTerm)
        {
            try
            {
                var customers = _customerService.Search(searchTerm);
                ViewBag.SearchTerm = searchTerm;
                return View("Index", customers);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Error searching customers: " + ex.Message;
                return RedirectToAction("Index");
            }
        }
    }
}
