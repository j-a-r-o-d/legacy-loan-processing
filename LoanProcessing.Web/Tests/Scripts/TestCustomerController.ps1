# PowerShell script to test CustomerController
# This script compiles and runs the controller tests

Write-Host "===========================================`n" -ForegroundColor Cyan
Write-Host "  CustomerController Test Runner`n" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan

# Build the project first
Write-Host "Building LoanProcessing.Web project...`n" -ForegroundColor Yellow
$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
& $msbuild "LoanProcessing.Web\LoanProcessing.Web.csproj" /p:Configuration=Debug /t:Build /v:minimal

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBuild failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild successful!`n" -ForegroundColor Green

# Create a simple C# test runner
$testRunnerCode = @"
using System;
using LoanProcessing.Web.Controllers;

class TestRunner
{
    static void Main()
    {
        CustomerControllerTest.RunAllTests();
    }
}
"@

# Save the test runner
$testRunnerPath = "TestRunner.cs"
$testRunnerCode | Out-File -FilePath $testRunnerPath -Encoding UTF8

Write-Host "Compiling test runner...`n" -ForegroundColor Yellow

# Compile the test runner with references to the web project
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$webDll = "LoanProcessing.Web\bin\LoanProcessing.Web.dll"
$systemWeb = "C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.7.2\System.Web.dll"
$systemWebMvc = "packages\Microsoft.AspNet.Mvc.5.2.7\lib\net45\System.Web.Mvc.dll"

& $csc /target:exe /out:TestRunner.exe /reference:$webDll /reference:$systemWeb /reference:$systemWebMvc $testRunnerPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nTest runner compilation failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "Running tests...`n" -ForegroundColor Yellow
Write-Host "===========================================`n" -ForegroundColor Cyan

# Run the tests
& .\TestRunner.exe

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nTests failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n===========================================`n" -ForegroundColor Cyan
Write-Host "All tests passed successfully!`n" -ForegroundColor Green
Write-Host "===========================================`n" -ForegroundColor Cyan

# Cleanup
Remove-Item TestRunner.cs -ErrorAction SilentlyContinue
Remove-Item TestRunner.exe -ErrorAction SilentlyContinue
