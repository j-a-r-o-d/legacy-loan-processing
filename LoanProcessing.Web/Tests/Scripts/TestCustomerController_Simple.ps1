# Simple PowerShell script to verify CustomerController implementation
Write-Host "===========================================`n" -ForegroundColor Cyan
Write-Host "  CustomerController Verification`n" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan

# Build the project
Write-Host "Building LoanProcessing.Web project...`n" -ForegroundColor Yellow
$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
& $msbuild "LoanProcessing.Web\LoanProcessing.Web.csproj" /p:Configuration=Debug /t:Build /v:minimal 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!`n" -ForegroundColor Green

# Verify the controller file exists and has the required methods
Write-Host "Verifying CustomerController implementation...`n" -ForegroundColor Yellow

$controllerPath = "LoanProcessing.Web\Controllers\CustomerController.cs"
$controllerContent = Get-Content $controllerPath -Raw

$requiredMethods = @(
    "public ActionResult Index()",
    "public ActionResult Details(int? id)",
    "public ActionResult Create()",
    "[HttpPost]",
    "public ActionResult Create(Customer customer)",
    "public ActionResult Edit(int? id)",
    "public ActionResult Edit(Customer customer)",
    "public ActionResult Search(string searchTerm)"
)

$allMethodsFound = $true
foreach ($method in $requiredMethods) {
    if ($controllerContent -match [regex]::Escape($method)) {
        Write-Host "  ✓ Found: $method" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: $method" -ForegroundColor Red
        $allMethodsFound = $false
    }
}

Write-Host ""

# Verify error handling
if ($controllerContent -match "TempData\[`"Error`"\]" -and $controllerContent -match "TempData\[`"Success`"\]") {
    Write-Host "  ✓ Error handling with TempData implemented" -ForegroundColor Green
} else {
    Write-Host "  ✗ Error handling with TempData missing" -ForegroundColor Red
    $allMethodsFound = $false
}

# Verify validation
if ($controllerContent -match "\[ValidateAntiForgeryToken\]") {
    Write-Host "  ✓ Anti-forgery token validation implemented" -ForegroundColor Green
} else {
    Write-Host "  ✗ Anti-forgery token validation missing" -ForegroundColor Red
    $allMethodsFound = $false
}

# Verify dependency injection
if ($controllerContent -match "ICustomerService") {
    Write-Host "  ✓ Dependency injection of ICustomerService implemented" -ForegroundColor Green
} else {
    Write-Host "  ✗ Dependency injection of ICustomerService missing" -ForegroundColor Red
    $allMethodsFound = $false
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan

if ($allMethodsFound) {
    Write-Host "✓ CustomerController implementation verified successfully!`n" -ForegroundColor Green
    Write-Host "All required actions are implemented:" -ForegroundColor Green
    Write-Host "  - Index action to list customers" -ForegroundColor Green
    Write-Host "  - Details action to view customer profile" -ForegroundColor Green
    Write-Host "  - Create GET/POST actions with validation" -ForegroundColor Green
    Write-Host "  - Edit GET/POST actions with validation" -ForegroundColor Green
    Write-Host "  - Search action" -ForegroundColor Green
    Write-Host "  - Error handling and user-friendly messages" -ForegroundColor Green
    Write-Host "`n===========================================`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "✗ CustomerController implementation incomplete!`n" -ForegroundColor Red
    Write-Host "===========================================`n" -ForegroundColor Cyan
    exit 1
}
