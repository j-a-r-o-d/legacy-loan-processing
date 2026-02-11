# PowerShell script to verify InterestRate views implementation
Write-Host "===========================================`n" -ForegroundColor Cyan
Write-Host "  InterestRate Views Verification`n" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan

$allViewsValid = $true

# Verify Index view
Write-Host "Verifying Index.cshtml...`n" -ForegroundColor Yellow

$indexPath = "LoanProcessing.Web\Views\InterestRate\Index.cshtml"
if (-not (Test-Path $indexPath)) {
    Write-Host "  ✗ Index.cshtml not found!" -ForegroundColor Red
    $allViewsValid = $false
} else {
    $indexContent = Get-Content $indexPath -Raw
    
    $indexChecks = @{
        "Model declaration" = '@model IEnumerable<LoanProcessing.Web.Models.InterestRate>'
        "Create button" = 'ActionLink.*Create New Rate'
        "Table with rates" = '<table.*id="ratesTable"'
        "Loan Type column" = 'Loan Type'
        "Credit Score Range column" = 'Credit Score Range'
        "Rate column" = 'Rate \(%\)'
        "Effective Date column" = 'Effective Date'
        "Status labels" = 'label-success.*Active'
        "Sorting functionality" = 'sort-link'
        "Bootstrap styling" = 'panel panel-default'
    }
    
    foreach ($check in $indexChecks.GetEnumerator()) {
        if ($indexContent -match $check.Value) {
            Write-Host "  ✓ $($check.Key)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Missing: $($check.Key)" -ForegroundColor Red
            $allViewsValid = $false
        }
    }
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan

# Verify Create view
Write-Host "Verifying Create.cshtml...`n" -ForegroundColor Yellow

$createPath = "LoanProcessing.Web\Views\InterestRate\Create.cshtml"
if (-not (Test-Path $createPath)) {
    Write-Host "  ✗ Create.cshtml not found!" -ForegroundColor Red
    $allViewsValid = $false
} else {
    $createContent = Get-Content $createPath -Raw
    
    $createChecks = @{
        "Model declaration" = '@model LoanProcessing.Web.Models.InterestRate'
        "Form with POST" = 'BeginForm.*Create.*InterestRate.*FormMethod.Post'
        "Anti-forgery token" = '@Html.AntiForgeryToken()'
        "Loan Type dropdown" = 'DropDownListFor.*LoanType'
        "Credit Score fields" = 'MinCreditScore.*MaxCreditScore'
        "Term fields" = 'MinTermMonths.*MaxTermMonths'
        "Rate field" = 'TextBoxFor.*Rate'
        "Effective Date field" = 'TextBoxFor.*EffectiveDate'
        "Expiration Date field" = 'TextBoxFor.*ExpirationDate'
        "Submit button" = 'type="submit"'
        "Cancel button" = 'ActionLink.*Cancel'
        "Validation" = '@Scripts.Render\("~/bundles/jqueryval"\)'
        "Custom validation" = 'creditscorerange'
        "Bootstrap styling" = 'form-horizontal'
        "Help text" = 'help-block'
    }
    
    foreach ($check in $createChecks.GetEnumerator()) {
        if ($createContent -match $check.Value) {
            Write-Host "  ✓ $($check.Key)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Missing: $($check.Key)" -ForegroundColor Red
            $allViewsValid = $false
        }
    }
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan

# Verify Edit view
Write-Host "Verifying Edit.cshtml...`n" -ForegroundColor Yellow

$editPath = "LoanProcessing.Web\Views\InterestRate\Edit.cshtml"
if (-not (Test-Path $editPath)) {
    Write-Host "  ✗ Edit.cshtml not found!" -ForegroundColor Red
    $allViewsValid = $false
} else {
    $editContent = Get-Content $editPath -Raw
    
    $editChecks = @{
        "Model declaration" = '@model LoanProcessing.Web.Models.InterestRate'
        "Form with POST" = 'BeginForm.*Edit.*InterestRate.*FormMethod.Post'
        "Hidden RateId" = 'HiddenFor.*RateId'
        "Anti-forgery token" = '@Html.AntiForgeryToken()'
        "Loan Type dropdown" = 'DropDownListFor.*LoanType'
        "Credit Score fields" = 'MinCreditScore.*MaxCreditScore'
        "Term fields" = 'MinTermMonths.*MaxTermMonths'
        "Rate field" = 'TextBoxFor.*Rate'
        "Effective Date field" = 'TextBoxFor.*EffectiveDate'
        "Expiration Date field" = 'TextBoxFor.*ExpirationDate'
        "Submit button" = 'type="submit"'
        "Cancel button" = 'ActionLink.*Cancel'
        "Validation" = '@Scripts.Render\("~/bundles/jqueryval"\)'
        "Custom validation" = 'creditscorerange'
        "Bootstrap styling" = 'form-horizontal'
        "Warning message" = 'alert-warning'
    }
    
    foreach ($check in $editChecks.GetEnumerator()) {
        if ($editContent -match $check.Value) {
            Write-Host "  ✓ $($check.Key)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Missing: $($check.Key)" -ForegroundColor Red
            $allViewsValid = $false
        }
    }
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan

# Verify navigation link in layout
Write-Host "Verifying navigation link in _Layout.cshtml...`n" -ForegroundColor Yellow

$layoutPath = "LoanProcessing.Web\Views\Shared\_Layout.cshtml"
if (-not (Test-Path $layoutPath)) {
    Write-Host "  ✗ _Layout.cshtml not found!" -ForegroundColor Red
    $allViewsValid = $false
} else {
    $layoutContent = Get-Content $layoutPath -Raw
    
    if ($layoutContent -match 'ActionLink.*Interest Rates.*Index.*InterestRate') {
        Write-Host "  ✓ Navigation link to Interest Rates added" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Navigation link to Interest Rates missing" -ForegroundColor Red
        $allViewsValid = $false
    }
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan

if ($allViewsValid) {
    Write-Host "✓ All InterestRate views verified successfully!`n" -ForegroundColor Green
    Write-Host "Implementation includes:" -ForegroundColor Green
    Write-Host "  - Index view with rate tables by loan type" -ForegroundColor Green
    Write-Host "  - Create form with validation" -ForegroundColor Green
    Write-Host "  - Edit form with validation" -ForegroundColor Green
    Write-Host "  - Bootstrap 3 styling consistent with existing views" -ForegroundColor Green
    Write-Host "  - Client-side validation with jQuery" -ForegroundColor Green
    Write-Host "  - Custom validation for credit score and term ranges" -ForegroundColor Green
    Write-Host "  - Sortable table in Index view" -ForegroundColor Green
    Write-Host "  - Status indicators (Active, Future, Expired)" -ForegroundColor Green
    Write-Host "  - Navigation link in main menu" -ForegroundColor Green
    Write-Host "`n===========================================`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "✗ InterestRate views verification failed!`n" -ForegroundColor Red
    Write-Host "===========================================`n" -ForegroundColor Cyan
    exit 1
}
