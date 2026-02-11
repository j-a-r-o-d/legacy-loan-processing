# Test script for ReportController
# Compiles and runs the ReportControllerTest program

Write-Host "=== ReportController Test Script ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build the test
Write-Host "Step 1: Building ReportControllerTest..." -ForegroundColor Yellow
$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
$buildResult = & $msbuild /t:Build /p:Configuration=Debug /p:StartupObject=LoanProcessing.Web.Controllers.ReportControllerTest LoanProcessing.Web/LoanProcessing.Web.csproj 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Build failed" -ForegroundColor Red
    Write-Host $buildResult
    exit 1
}

Write-Host "✓ Build succeeded" -ForegroundColor Green
Write-Host ""

# Step 2: Run the test
Write-Host "Step 2: Running ReportControllerTest..." -ForegroundColor Yellow
Write-Host ""

# Use csc to compile a standalone executable
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$testFile = "LoanProcessing.Web\Controllers\ReportControllerTest.cs"
$outputExe = "LoanProcessing.Web\bin\ReportControllerTest.exe"

# Get all necessary references
$refs = @(
    "LoanProcessing.Web\bin\LoanProcessing.Web.dll",
    "System.dll",
    "System.Core.dll",
    "System.Configuration.dll",
    "System.Web.dll",
    "System.Web.Mvc.dll"
)

$refArgs = $refs | ForEach-Object { "/r:$_" }

Write-Host "Compiling standalone test executable..." -ForegroundColor Yellow
$compileResult = & $csc /out:$outputExe /target:exe $refArgs $testFile 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Compilation failed" -ForegroundColor Red
    Write-Host $compileResult
    exit 1
}

Write-Host "✓ Compilation succeeded" -ForegroundColor Green
Write-Host ""

# Run the test
Write-Host "Executing test..." -ForegroundColor Yellow
Write-Host ""
& $outputExe

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "✗ Test execution failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== All Tests Completed Successfully ===" -ForegroundColor Green
