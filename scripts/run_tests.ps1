# PowerShell Script for Automated Flutter Testing
# Usage: .\run_tests.ps1

$ErrorActionPreference = 'Stop'

# -----------------------------
# Resolve project root safely
# -----------------------------
if ($PSScriptRoot) {
    $PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
} else {
    $PROJECT_ROOT = Get-Location
}

# -----------------------------
# Configuration
# -----------------------------
$LOG_DIR = Join-Path $PROJECT_ROOT 'test_logs'
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss'
$LOG_FILE = Join-Path $LOG_DIR "test_results_$TIMESTAMP.log"
$UNIT_TEST_LOG = Join-Path $LOG_DIR "unit_tests_$TIMESTAMP.log"
$INTEGRATION_TEST_LOG = Join-Path $LOG_DIR "integration_tests_$TIMESTAMP.log"

# ⚠️ Prefer environment variables in real projects
$TEST_EMAIL = 'hassanadelh@outlook.com'
$TEST_PASSWORD = '040800Masr'

# -----------------------------
# Create log directory
# -----------------------------
if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR | Out-Null
}

# -----------------------------
# Logging function
# -----------------------------
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    Add-Content -Path $LOG_FILE -Value $line
    Write-Host $line
}

# -----------------------------
# Tool checks
# -----------------------------
function Test-Command {
    param ([string]$Command)

    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-ADB {
    if (Test-Command adb) {
        Write-Log 'ADB is available'
        return $true
    }
    Write-Log 'ADB not found. Integration tests will be skipped.' 'WARNING'
    return $false
}

function Test-Flutter {
    if (Test-Command flutter) {
        Write-Log 'Flutter is available'
        return $true
    }
    Write-Log 'Flutter SDK not found. Exiting.' 'ERROR'
    return $false
}

# -----------------------------
# Device check
# -----------------------------
function Test-ConnectedDevices {
    Write-Log 'Checking for connected Android devices...'

    $devices = adb devices
    $deviceCount = ($devices | Select-String 'device$').Count

    if ($deviceCount -gt 0) {
        Write-Log "Found $deviceCount device(s)"
        return $true
    }

    Write-Log 'No devices found. Trying to start emulator...' 'WARNING'

    if (Test-Command emulator) {
        $avds = emulator -list-avds
        if ($avds.Count -gt 0) {
            $avd = $avds[0]
            Write-Log "Starting emulator: $avd"
            Start-Process emulator "-avd $avd" -WindowStyle Hidden
            Start-Sleep -Seconds 40
        }
    }

    $devices = adb devices
    return (($devices | Select-String 'device$').Count -gt 0)
}

# -----------------------------
# Unit Tests
# -----------------------------
function Run-UnitTests {
    Write-Log 'Starting Unit Tests'

    Push-Location $PROJECT_ROOT
    try {
        $unitPath = Join-Path $PROJECT_ROOT 'test'
        flutter test $unitPath 2>&1 | Tee-Object $UNIT_TEST_LOG

        if ($LASTEXITCODE -eq 0) {
            Write-Log 'Unit tests passed'
            return $true
        }

        Write-Log 'Unit tests failed' 'ERROR'
        return $false
    } finally {
        Pop-Location
    }
}

# -----------------------------
# Integration Tests
# -----------------------------
function Run-IntegrationTests {
    Write-Log 'Starting Integration Tests'

    if (-not (Test-ConnectedDevices)) {
        Write-Log 'No device available. Skipping integration tests.' 'WARNING'
        return $false
    }

    Push-Location $PROJECT_ROOT
    try {
        flutter build apk --debug | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log 'APK build failed' 'ERROR'
            return $false
        }

        $apkPath = Join-Path $PROJECT_ROOT 'build\app\outputs\flutter-apk\app-debug.apk'
        if (-not (Test-Path $apkPath)) {
            Write-Log 'APK not found after build' 'ERROR'
            return $false
        }

        # Install APK using Start-Process for reliable error handling
        $tempOutputFile = Join-Path $env:TEMP "adb_install_output_$(Get-Random).txt"
        $tempErrorFile = Join-Path $env:TEMP "adb_install_error_$(Get-Random).txt"
        
        try {
            # Use Start-Process to avoid PowerShell exception handling issues
            $process = Start-Process -FilePath "adb" -ArgumentList "install", "-r", $apkPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput $tempOutputFile -RedirectStandardError $tempErrorFile
            $installExitCode = $process.ExitCode
            
            # Read output files
            $stdout = if (Test-Path $tempOutputFile) { Get-Content $tempOutputFile -Raw } else { '' }
            $stderr = if (Test-Path $tempErrorFile) { Get-Content $tempErrorFile -Raw } else { '' }
            $errorMsg = ($stdout + $stderr).Trim()
            
            # Clean up temp files
            if (Test-Path $tempOutputFile) { Remove-Item $tempOutputFile -Force -ErrorAction SilentlyContinue }
            if (Test-Path $tempErrorFile) { Remove-Item $tempErrorFile -Force -ErrorAction SilentlyContinue }
        } catch {
            $errorMsg = $_.Exception.Message
            $installExitCode = 1
            # Clean up temp files on error
            if (Test-Path $tempOutputFile) { Remove-Item $tempOutputFile -Force -ErrorAction SilentlyContinue }
            if (Test-Path $tempErrorFile) { Remove-Item $tempErrorFile -Force -ErrorAction SilentlyContinue }
        }
        
        if ($installExitCode -ne 0) {
            if ($errorMsg -match 'INSTALL_FAILED_INSUFFICIENT_STORAGE') {
                Write-Log 'APK installation failed: Device has insufficient storage' 'ERROR'
                Write-Log 'Please free up space on your device and try again' 'WARNING'
                Write-Log 'You can check storage with: adb shell df -h' 'INFO'
            } elseif ($errorMsg -match 'INSTALL_FAILED_ALREADY_EXISTS|INSTALL_PARSE_FAILED_NOT_APK') {
                Write-Log 'APK installation issue detected, attempting to uninstall and reinstall...' 'INFO'
                # Try to get package name from build.gradle
                $buildGradlePath = Join-Path $PROJECT_ROOT 'android\app\build.gradle'
                if (Test-Path $buildGradlePath) {
                    $buildGradleContent = Get-Content $buildGradlePath -Raw
                    if ($buildGradleContent -match "applicationId\s+['""]([^'""]+)['""]") {
                        $packageName = $matches[1]
                        Write-Log "Uninstalling existing package: $packageName" 'INFO'
                        
                        # Uninstall using Start-Process
                        $uninstallProcess = Start-Process -FilePath "adb" -ArgumentList "uninstall", $packageName -NoNewWindow -Wait -PassThru
                        Start-Sleep -Seconds 2
                        
                        # Retry installation
                        $tempOutputFile2 = Join-Path $env:TEMP "adb_install_output_$(Get-Random).txt"
                        $tempErrorFile2 = Join-Path $env:TEMP "adb_install_error_$(Get-Random).txt"
                        try {
                            $process = Start-Process -FilePath "adb" -ArgumentList "install", "-r", $apkPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput $tempOutputFile2 -RedirectStandardError $tempErrorFile2
                            $installExitCode = $process.ExitCode
                            $stdout = if (Test-Path $tempOutputFile2) { Get-Content $tempOutputFile2 -Raw } else { '' }
                            $stderr = if (Test-Path $tempErrorFile2) { Get-Content $tempErrorFile2 -Raw } else { '' }
                            $errorMsg = ($stdout + $stderr).Trim()
                            if (Test-Path $tempOutputFile2) { Remove-Item $tempOutputFile2 -Force -ErrorAction SilentlyContinue }
                            if (Test-Path $tempErrorFile2) { Remove-Item $tempErrorFile2 -Force -ErrorAction SilentlyContinue }
                        } catch {
                            $errorMsg = $_.Exception.Message
                            $installExitCode = 1
                            if (Test-Path $tempOutputFile2) { Remove-Item $tempOutputFile2 -Force -ErrorAction SilentlyContinue }
                            if (Test-Path $tempErrorFile2) { Remove-Item $tempErrorFile2 -Force -ErrorAction SilentlyContinue }
                        }
                        
                        if ($installExitCode -ne 0) {
                            Write-Log "APK installation failed after uninstall: $errorMsg" 'ERROR'
                            return $false
                        } else {
                            Write-Log 'APK installed successfully after uninstall' 'INFO'
                        }
                    } else {
                        Write-Log "APK installation failed: $errorMsg" 'ERROR'
                        return $false
                    }
                } else {
                    Write-Log "APK installation failed: $errorMsg" 'ERROR'
                    return $false
                }
            } else {
                Write-Log "APK installation failed: $errorMsg" 'ERROR'
                return $false
            }
        } else {
            Write-Log 'APK installed successfully' 'INFO'
        }

        $integrationPath = Join-Path $PROJECT_ROOT 'test\integration_test'
        if (-not (Test-Path $integrationPath)) {
            Write-Log "Integration test directory not found: $integrationPath" 'ERROR'
            return $false
        }
        
        # Run integration tests using flutter test (works with integration_test plugin)
        flutter test $integrationPath 2>&1 | Tee-Object $INTEGRATION_TEST_LOG

        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
    }
}

# -----------------------------
# Summary
# -----------------------------
function Write-TestSummary {
    param($UnitPassed, $IntegrationPassed)

    Write-Log '========== SUMMARY =========='
    Write-Log "Unit Tests:        $(if ($UnitPassed) {'PASSED'} else {'FAILED'})"
    Write-Log "Integration Tests: $(if ($IntegrationPassed) {'PASSED'} else {'FAILED'})"
    Write-Log "Logs saved to: $LOG_DIR"

    if ($UnitPassed -and $IntegrationPassed) { exit 0 }
    exit 1
}

# -----------------------------
# Main
# -----------------------------
Write-Log 'Flutter Automated Test Suite - Siyanaty'
Write-Log "Timestamp: $TIMESTAMP"

if (-not (Test-Flutter)) { exit 1 }

$unitResult = Run-UnitTests
$integrationResult = Run-IntegrationTests

Write-TestSummary $unitResult $integrationResult
