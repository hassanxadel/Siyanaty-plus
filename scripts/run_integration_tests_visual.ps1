# ===============================================================
#  SIYANATY+ VISUAL INTEGRATION TEST RUNNER
#  Runs integration tests with UI visible on emulator/device
#  WARNING: This is SLOW (10-15 minutes) - use for demonstration only
# ===============================================================

# Script configuration
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path $projectRoot "test_logs"
$visualTestLog = Join-Path $logDir "visual_integration_tests_$timestamp.log"

# Create log directory if it doesn't exist
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

# Color output functions
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
Write-Host "  SIYANATY+ VISUAL INTEGRATION TEST RUNNER (Windows)" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Warning "WARNING: This script uses 'flutter drive' which is SLOW"
Write-Warning "Expected runtime: 10-15 minutes"
Write-Warning "You will see the app running on the emulator during tests"
Write-Host ""

# Check for connected devices
Write-Info "Checking for connected devices..."
$devices = adb devices 2>&1 | Out-String
$deviceLines = $devices -split "`n" | Where-Object { $_.Trim() -ne "" -and $_ -match "\s+device\s*$" -and $_ -notmatch "List of devices" }

if ($deviceLines.Count -eq 0) {
    Write-Error-Custom "[ERROR] No device or emulator connected!"
    Write-Error-Custom "Please start an Android emulator or connect a device"
    Write-Host ""
    exit 1
}

Write-Success "[OK] Found $($deviceLines.Count) connected device(s)"
Write-Host ""

# Create test driver if it doesn't exist
$driverPath = Join-Path $projectRoot "test_driver\integration_test.dart"
if (-not (Test-Path $driverPath)) {
    Write-Info "Creating test driver file..."
    $driverContent = @"
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
"@
    New-Item -ItemType Directory -Force -Path (Split-Path $driverPath) | Out-Null
    $driverContent | Out-File -FilePath $driverPath -Encoding UTF8
    Write-Success "[OK] Test driver created"
    Write-Host ""
}

# Initialize log file
$logHeader = @"
========================================
VISUAL INTEGRATION TESTS - EXECUTION LOG
========================================

Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Mode: Visual (flutter drive)
Device: $($deviceLines[0])

Note: These tests run with UI visible on the device.
This provides a visual demonstration of the app's functionality.

========================================

"@
$logHeader | Out-File -FilePath $visualTestLog -Encoding UTF8

# Test files to run
$testFiles = @(
    "test/integration_test/app_test.dart",
    "test/integration_test/auth_workflow_test.dart"
)

$totalTests = $testFiles.Count
$currentTest = 0
$passedTests = 0
$failedTests = 0

foreach ($testFile in $testFiles) {
    $currentTest++
    $testName = Split-Path $testFile -Leaf
    
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Info "Running Test $currentTest of ${totalTests}: $testName"
    Write-Host "===============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Info "Watch the emulator screen - you'll see the app running!"
    Write-Host ""
    
    # Log test start
    Add-Content -Path $visualTestLog -Value "`n=== TEST: $testName ===`n"
    Add-Content -Path $visualTestLog -Value "Start Time: $(Get-Date -Format 'HH:mm:ss')`n"
    
    # Run the test
    $output = flutter drive --target=$testFile --driver=test_driver/integration_test.dart 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    
    # Save output to log
    Add-Content -Path $visualTestLog -Value $output
    Add-Content -Path $visualTestLog -Value "`nEnd Time: $(Get-Date -Format 'HH:mm:ss')"
    Add-Content -Path $visualTestLog -Value "Exit Code: $exitCode`n"
    
    # Check result
    if ($exitCode -eq 0) {
        Write-Success "[OK] $testName PASSED"
        $passedTests++
    }
    else {
        Write-Error-Custom "[FAIL] $testName FAILED"
        $failedTests++
    }
    
    Write-Host ""
}

# Final summary
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "           VISUAL INTEGRATION TEST SUMMARY" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

if ($failedTests -eq 0) {
    Write-Success "[OK] ALL VISUAL TESTS PASSED"
    Write-Success "  Total: $totalTests"
    Write-Success "  Passed: $passedTests"
    Write-Success "  Failed: 0"
}
else {
    Write-Warning "[WARN] SOME TESTS FAILED"
    Write-Warning "  Total: $totalTests"
    Write-Warning "  Passed: $passedTests"
    Write-Warning "  Failed: $failedTests"
}

Write-Host ""
Write-Info "Complete test log saved to:"
Write-Host "  $visualTestLog" -ForegroundColor DarkGray
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# Exit with appropriate code
if ($failedTests -eq 0) {
    exit 0
}
else {
    exit 1
}
