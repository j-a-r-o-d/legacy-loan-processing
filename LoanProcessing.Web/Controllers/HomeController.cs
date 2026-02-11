using System.Web.Mvc;

namespace LoanProcessing.Web.Controllers
{
    /// <summary>
    /// Home controller for the loan processing application.
    /// </summary>
    public class HomeController : Controller
    {
        /// <summary>
        /// GET: Home/Index
        /// Displays the application home page.
        /// </summary>
        /// <returns>View with application home page.</returns>
        public ActionResult Index()
        {
            return View();
        }
    }
}
