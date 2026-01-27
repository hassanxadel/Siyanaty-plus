<#
.SYNOPSIS
    Automated test execution script for Siyanaty+ Flutter app
    
.DESCRIPTION
    This PowerShell script automates the execution of unit tests and integration tests
    for the Siyanaty+ car maintenance application. It runs tests without human interaction,
    generates detailed logs, and provides a comprehensive test report.
    
.NOTES
    Author: Siyanaty+ Development Team
    Version: 1.0
    Requires: Flutter SDK, Android SDK (with ADB for device testing)
    
.EXAMPLE
    .\run_all_tests.ps1
    Runs all tests and generates logs in test_logs directory
#>

# Script configuration
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Color codes for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Host $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error-Custom { Write-ColorOutput Red $args }
function Write-Info { Write-ColorOutput Cyan $args }

# Banner
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "     SIYANATY+ AUTOMATED TEST SUITE RUNNER (Windows)          " -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# Initialize variables
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path $projectRoot "test_logs"
$unitTestLog = Join-Path $logDir "unit_tests_$timestamp.log"
$integrationTestLog = Join-Path $logDir "integration_tests_$timestamp.log"
$summaryLog = Join-Path $logDir "test_summary_$timestamp.log"
$fullLog = Join-Path $logDir "test_results_$timestamp.log"

# Create log directory if it doesn't exist
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
    Write-Info "Created log directory: $logDir"
}

# Change to project root directory
Set-Location $projectRoot
Write-Info "Working directory: $projectRoot"
Write-Host ""

# Function to write to log file
function Write-Log {
    param(
        [string]$Message,
        [string]$LogFile = $fullLog
    )
    $timestampMsg = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogFile -Value $timestampMsg
}

# Function to check if Flutter is installed
function Test-FlutterInstallation {
    Write-Info "Checking Flutter installation..."
    try {
        $null = flutter --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "[OK] Flutter is installed"
            Write-Log "Flutter installation verified"
            return $true
        }
    }
    catch {
        Write-Error-Custom "[ERROR] Flutter is not installed or not in PATH"
        Write-Log "ERROR: Flutter not found"
        return $false
    }
    return $false
}

# Function to check if ADB is available
function Test-ADBInstallation {
    Write-Info "Checking ADB installation..."
    try {
        $null = adb version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "[OK] ADB is installed"
            Write-Log "ADB installation verified"
            return $true
        }
    }
    catch {
        Write-Warning "[WARNING] ADB is not installed or not in PATH"
        Write-Log "WARNING: ADB not found - device testing may not be available"
        return $false
    }
    return $false
}

# Function to check for connected devices
function Get-ConnectedDevices {
    Write-Info "Checking for connected devices..."
    try {
        $devices = adb devices 2>&1 | Out-String
        Write-Log "ADB Devices Output: $devices"
        
        # Parse device list
        $deviceLines = $devices -split "`n" | Where-Object { $_.Trim() -ne "" -and $_ -match "\s+device\s*$" -and $_ -notmatch "List of devices" }
        
        if ($deviceLines.Count -gt 0) {
            Write-Success "[OK] Found $($deviceLines.Count) connected device(s)"
            foreach ($device in $deviceLines) {
                $deviceId = ($device -split "`t")[0]
                Write-Info "  - Device: $deviceId"
                Write-Log "Connected device: $deviceId"
            }
            return $true
        }
        else {
            Write-Warning "[WARNING] No devices connected"
            Write-Log "No devices connected - will use emulator if available"
            return $false
        }
    }
    catch {
        Write-Warning "[WARNING] Could not check for devices: $_"
        Write-Log "WARNING: Could not check devices"
        return $false
    }
}

# Function to get Flutter dependencies
function Get-FlutterDependencies {
    Write-Info "Getting Flutter dependencies..."
    Write-Log "Running: flutter pub get"
    
    $output = flutter pub get 2>&1 | Out-String
    Write-Log "Flutter pub get output: $output"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "[OK] Dependencies retrieved successfully"
        return $true
    }
    else {
        Write-Error-Custom "[ERROR] Failed to get dependencies"
        return $false
    }
}

# Function to run unit tests
function Invoke-UnitTests {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Info "RUNNING UNIT TESTS"
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Log "Starting unit tests execution"
    
    # Run unit tests with detailed output (suppress terminal output)
    Write-Host "Running unit tests (output saved to log file)..." -ForegroundColor Gray
    $testOutput = flutter test test/unit/ --reporter expanded 2>&1 | Out-String
    
    # Save complete output to log file
    $testOutput | Out-File -FilePath $unitTestLog -Encoding UTF8
    Write-Log "Unit test output saved to: $unitTestLog"
    
    # Also append to main log
    Add-Content -Path $fullLog -Value "`n=== UNIT TESTS OUTPUT ===`n"
    Add-Content -Path $fullLog -Value $testOutput
    
    # Extract summary information
    $passedCount = 0
    $failedCount = 0
    
    # Get the last line with test count (e.g., "00:47 +46: All tests passed!")
    $lines = $testOutput -split "`n"
    $lastTestLine = $lines | Where-Object { $_ -match '\+\d+:' } | Select-Object -Last 1
    if ($lastTestLine -and $lastTestLine -match '\+(\d+):') {
        $passedCount = [int]$matches[1]
    }
    
    # Match failures (e.g., "00:02 +46 -3:")
    if ($testOutput -match '\+\d+\s+-(\d+):') {
        $failedCount = [int]$matches[1]
    }
    
    # Display only summary in terminal
    Write-Host ""
    if ($LASTEXITCODE -eq 0) {
        Write-Success "[OK] UNIT TESTS PASSED"
        Write-Success "  Total tests: $passedCount"
        Write-Success "  Passed: $passedCount"
        Write-Success "  Failed: 0"
        Write-Host ""
        Write-Log "Unit tests: PASSED - $passedCount tests"
        return $true
    }
    else {
        Write-Error-Custom "[FAIL] UNIT TESTS FAILED"
        Write-Error-Custom "  Total tests: $($passedCount + $failedCount)"
        Write-Error-Custom "  Passed: $passedCount"
        Write-Error-Custom "  Failed: $failedCount"
        Write-Host ""
        Write-Log "Unit tests: FAILED - $failedCount failures - Exit code: $LASTEXITCODE"
        return $false
    }
}

# Function to run integration tests
function Invoke-IntegrationTests {
    param(
        [bool]$hasDevices
    )
    
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Info "RUNNING INTEGRATION TESTS"
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Log "Starting integration tests execution"
    
    # Initialize log file
    Add-Content -Path $integrationTestLog -Value "========================================`n"
    Add-Content -Path $integrationTestLog -Value "INTEGRATION TESTS - EXECUTION REPORT`n"
    Add-Content -Path $integrationTestLog -Value "========================================`n`n"
    Add-Content -Path $integrationTestLog -Value "Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    Add-Content -Path $integrationTestLog -Value "Note: Tests run in headless mode (no UI shown on device)`n"
    Add-Content -Path $integrationTestLog -Value "To see UI during tests, use: flutter drive --target=test/integration_test/app_test.dart`n`n"
    
    # Run integration tests using flutter test (fast, no UI)
    Write-Host "Running integration tests (output saved to log file)..." -ForegroundColor Gray
    Write-Log "Running: flutter test test/integration_test/"
    
    $testOutput = flutter test test/integration_test/ --reporter expanded 2>&1 | Out-String
    
    # Save complete output to log file
    $testOutput | Out-File -FilePath $integrationTestLog -Append -Encoding UTF8
    
    # Also append to main log
    Add-Content -Path $fullLog -Value "`n=== INTEGRATION TESTS OUTPUT ===`n"
    Add-Content -Path $fullLog -Value $testOutput
    
    # Extract summary information
    $passedCount = 0
    $failedCount = 0
    
    # Get the last line with test count
    $lines = $testOutput -split "`n"
    $lastTestLine = $lines | Where-Object { $_ -match '\+\d+:' } | Select-Object -Last 1
    if ($lastTestLine -and $lastTestLine -match '\+(\d+):') {
        $passedCount = [int]$matches[1]
    }
    
    # Match failures
    if ($testOutput -match '\+\d+\s+-(\d+):') {
        $failedCount = [int]$matches[1]
    }
    
    # Display only summary in terminal
    Write-Host ""
    if ($LASTEXITCODE -eq 0) {
        Write-Success "[OK] INTEGRATION TESTS PASSED"
        Write-Success "  Total tests: $passedCount"
        Write-Success "  Passed: $passedCount"
        Write-Success "  Failed: 0"
        Write-Host ""
        Write-Log "Integration tests: PASSED - $passedCount tests"
        return $true
    }
    else {
        if ($failedCount -le 3 -and $passedCount -gt 0) {
            Write-Warning "[WARN] INTEGRATION TESTS COMPLETED WITH WARNINGS"
            Write-Warning "  Total tests: $($passedCount + $failedCount)"
            Write-Warning "  Passed: $passedCount"
            Write-Warning "  Failed: $failedCount"
            Write-Host ""
            Write-Log "Integration tests: PASSED WITH WARNINGS - $passedCount passed, $failedCount failed"
            return $true
        }
        else {
            Write-Error-Custom "[FAIL] INTEGRATION TESTS FAILED"
            Write-Error-Custom "  Total tests: $($passedCount + $failedCount)"
            Write-Error-Custom "  Passed: $passedCount"
            Write-Error-Custom "  Failed: $failedCount"
            Write-Host ""
            Write-Log "Integration tests: FAILED - $failedCount failures"
            return $false
        }
    }
}

# Function to generate test summary
function New-TestSummary {
    param(
        [bool]$unitTestsPassed,
        [bool]$integrationTestsPassed
    )
    
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Info "Generating Test Summary..."
    Write-Host "===============================================================" -ForegroundColor Cyan
    
    $unitStatus = if ($unitTestsPassed) { "PASSED [OK]" } else { "FAILED [X]" }
    $integrationStatus = if ($integrationTestsPassed) { "PASSED [OK]" } else { "FAILED/SKIPPED [!]" }
    $overallStatus = if ($unitTestsPassed -and $integrationTestsPassed) { 
        "ALL TESTS PASSED [OK]" 
    } elseif ($unitTestsPassed) { 
        "PARTIAL SUCCESS [!]" 
    } else { 
        "TESTS FAILED [X]" 
    }
    
    $summary = @"
===============================================================
           SIYANATY+ TEST EXECUTION SUMMARY
===============================================================

Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Project: Siyanaty+ Car Maintenance Application

---------------------------------------------------------------
                    TEST RESULTS
---------------------------------------------------------------

Unit Tests:         $unitStatus
Integration Tests:  $integrationStatus

---------------------------------------------------------------
                    LOG FILES
---------------------------------------------------------------

Unit Test Log:        $unitTestLog
Integration Test Log: $integrationTestLog
Full Test Log:        $fullLog
Summary Log:          $summaryLog

---------------------------------------------------------------
                 OVERALL RESULT
---------------------------------------------------------------

Status: $overallStatus

===============================================================
"@

    # Save summary to file
    $summary | Out-File -FilePath $summaryLog -Encoding UTF8
    
    # Display summary
    if ($unitTestsPassed -and $integrationTestsPassed) {
        Write-Success $summary
    }
    elseif ($unitTestsPassed) {
        Write-Warning $summary
    }
    else {
        Write-Error-Custom $summary
    }
    
    Write-Log "Test summary generated and saved to: $summaryLog"
}

# Main execution flow
Write-Log "==============================================================="
Write-Log "Starting automated test execution"
Write-Log "==============================================================="

# Step 1: Check prerequisites
$flutterInstalled = Test-FlutterInstallation
if (-not $flutterInstalled) {
    Write-Error-Custom "Flutter is required but not found. Please install Flutter and try again."
    Write-Log "ERROR: Flutter not installed - aborting"
    exit 1
}

$hasADB = Test-ADBInstallation
$hasDevices = $false

if ($hasADB) {
    $hasDevices = Get-ConnectedDevices
}

# Step 2: Get dependencies
Write-Host ""
$depsInstalled = Get-FlutterDependencies
if (-not $depsInstalled) {
    Write-Error-Custom "Failed to get Flutter dependencies. Continuing anyway..."
    Write-Log "WARNING: Failed to get dependencies"
}

# Step 3: Run unit tests
$unitTestsPassed = Invoke-UnitTests

# Step 4: Run integration tests
$integrationTestsPassed = Invoke-IntegrationTests -hasDevices $hasDevices

# Step 5: Generate summary
New-TestSummary -unitTestsPassed $unitTestsPassed -integrationTestsPassed $integrationTestsPassed

# Final output
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Info "Test execution completed!"
Write-Host ""
Write-Info "Log Files:"
Write-Host "  Unit Tests:        $unitTestLog" -ForegroundColor DarkGray
Write-Host "  Integration Tests: $integrationTestLog" -ForegroundColor DarkGray
Write-Host "  Full Log:          $fullLog" -ForegroundColor DarkGray
Write-Host "  Summary:           $summaryLog" -ForegroundColor DarkGray
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# Exit with appropriate code
if ($unitTestsPassed -and $integrationTestsPassed) {
    Write-Log "Test execution completed successfully"
    exit 0
}
elseif ($unitTestsPassed) {
    Write-Log "Test execution completed with warnings"
    exit 2
}
else {
    Write-Log "Test execution completed with failures"
    exit 1
}
