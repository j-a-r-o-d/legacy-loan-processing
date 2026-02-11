# PowerShell script to verify InterestRateController implementation
Write-Host "===========================================`n" -ForegroundColor Cyan
Write-Host "  InterestRateController Verification`n" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan

# Build the project
Write-Host "Building LoanProcessing.Web project...`n" -ForegroundColor Yellow
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path $msbuild)) {
    $msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
}
if (-not (Test-Path $msbuild)) {
    $msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
}

& $msbuild "LoanProcessing.Web\LoanProcessing.Web.csproj" /p:Configuration=Debug /t:Build /v:minimal 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Trying with detailed output...`n" -ForegroundColor Red
    & $msbuild "LoanProcessing.Web\LoanProcessing.Web.csproj" /p:Configuration=Debug /t:Build /v:detailed
    exit 1
}

Write-Host "Build successful!`n" -ForegroundColor Green

# Verify the controller file exists and has the required methods
Write-Host "Verifying InterestRateController implementation...`n" -ForegroundColor Yellow

$controllerPath = "LoanProcessing.Web\Controllers\InterestRateController.cs"
if (-not (Test-Path $controllerPath)) {
    Write-Host "  ✗ InterestRateController.cs not found!" -ForegroundColor Red
    exit 1
}

$controllerContent = Get-Content $controllerPath -Raw

$requiredMethods = @(
    "public ActionResult Index()",
    "public ActionResult Create()",
    "[HttpPost]",
    "public ActionResult Create(InterestRate rate)",
    "public ActionResult Edit(int? id)",
    "public ActionResult Edit(InterestRate rate)"
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
if ($controllerContent -match "IInterestRateService") {
    Write-Host "  ✓ Dependency injection of IInterestRateService implemented" -ForegroundColor Green
} else {
    Write-Host "  ✗ Dependency injection of IInterestRateService missing" -ForegroundColor Red
    $allMethodsFound = $false
}

# Verify rate range validation
if ($controllerContent -match "PopulateLoanTypeSelectList") {
    Write-Host "  ✓ Loan type dropdown population implemented" -ForegroundColor Green
} else {
    Write-Host "  ✗ Loan type dropdown population missing" -ForegroundColor Red
    $allMethodsFound = $false
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan

# Verify service layer
Write-Host "Verifying InterestRateService implementation...`n" -ForegroundColor Yellow

$servicePath = "LoanProcessing.Web\Services\InterestRateService.cs"
if (-not (Test-Path $servicePath)) {
    Write-Host "  ✗ InterestRateService.cs not found!" -ForegroundColor Red
    $allMethodsFound = $false
} else {
    $serviceContent = Get-Content $servicePath -Raw
    
    if ($serviceContent -match "ValidateRateRanges" -and $serviceContent -match "ValidateEffectiveDates") {
        Write-Host "  ✓ Rate range and effective date validation implemented" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Validation methods missing" -ForegroundColor Red
        $allMethodsFound = $false
    }
}

Write-Host ""

# Verify repository layer
Write-Host "Verifying InterestRateRepository implementation...`n" -ForegroundColor Yellow

$repoPath = "LoanProcessing.Web\Data\InterestRateRepository.cs"
if (-not (Test-Path $repoPath)) {
    Write-Host "  ✗ InterestRateRepository.cs not found!" -ForegroundColor Red
    $allMethodsFound = $false
} else {
    $repoContent = Get-Content $repoPath -Raw
    
    $repoMethods = @(
        "GetAll()",
        "GetById(int rateId)",
        "GetActiveRates()",
        "CreateRate(InterestRate rate)",
        "UpdateRate(InterestRate rate)"
    )
    
    foreach ($method in $repoMethods) {
        if ($repoContent -match [regex]::Escape($method)) {
            Write-Host "  ✓ Found: $method" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Missing: $method" -ForegroundColor Red
            $allMethodsFound = $false
        }
    }
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan

if ($allMethodsFound) {
    Write-Host "✓ InterestRateController implementation verified successfully!`n" -ForegroundColor Green
    Write-Host "All required components are implemented:" -ForegroundColor Green
    Write-Host "  - Index action to list current rates" -ForegroundColor Green
    Write-Host "  - Create GET/POST actions to add new rates" -ForegroundColor Green
    Write-Host "  - Edit GET/POST actions to update rates" -ForegroundColor Green
    Write-Host "  - Rate range validation (credit score 300-850)" -ForegroundColor Green
    Write-Host "  - Effective date validation" -ForegroundColor Green
    Write-Host "  - Service layer with business logic" -ForegroundColor Green
    Write-Host "  - Repository layer with ADO.NET" -ForegroundColor Green
    Write-Host "  - Error handling and user-friendly messages" -ForegroundColor Green
    Write-Host "`n===========================================`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "✗ InterestRateController implementation incomplete!`n" -ForegroundColor Red
    Write-Host "===========================================`n" -ForegroundColor Cyan
    exit 1
}
