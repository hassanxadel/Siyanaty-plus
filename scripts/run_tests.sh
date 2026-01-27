#!/bin/bash

# Bash Script for Automated Flutter Testing
# This script automates the execution of Flutter unit and integration tests using ADB commands
# Usage: ./run_tests.sh

# Set error handling
set -e

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/test_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/test_results_$TIMESTAMP.log"
UNIT_TEST_LOG="$LOG_DIR/unit_tests_$TIMESTAMP.log"
INTEGRATION_TEST_LOG="$LOG_DIR/integration_tests_$TIMESTAMP.log"

# Test credentials (provided by user)
TEST_EMAIL="hassanadelh@outlook.com"
TEST_PASSWORD="040800Masr"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to write log messages
write_log() {
    local level="${2:-INFO}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local message="[$timestamp] [$level] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

# Function to check if ADB is available
check_adb() {
    if command -v adb &> /dev/null; then
        write_log "ADB is available" "INFO"
        return 0
    else
        write_log "ADB is not available. Please install Android SDK Platform Tools." "ERROR"
        return 1
    fi
}

# Function to check if Flutter is available
check_flutter() {
    if command -v flutter &> /dev/null; then
        write_log "Flutter is available" "INFO"
        return 0
    else
        write_log "Flutter is not available. Please install Flutter SDK." "ERROR"
        return 1
    fi
}

# Function to check for connected devices
check_connected_devices() {
    write_log "Checking for connected Android devices..." "INFO"
    
    if ! command -v adb &> /dev/null; then
        write_log "ADB is not available. Integration tests will be skipped." "WARNING"
        return 1
    fi
    
    local device_count=$(adb devices 2>/dev/null | grep -E "device$" | wc -l)
    
    if [ "$device_count" -eq 0 ]; then
        write_log "No Android devices found. Please connect a device or start an emulator." "WARNING"
        write_log "Attempting to start emulator..." "INFO"
        
        # Try to list available emulators
        if command -v emulator &> /dev/null; then
            local emulators=$(emulator -list-avds 2>/dev/null | grep -v "^Android" | head -n 1)
            if [ -n "$emulators" ]; then
                local first_emulator=$(echo "$emulators" | head -n 1)
                write_log "Starting emulator: $first_emulator" "INFO"
                emulator -avd "$first_emulator" &
                sleep 30
                
                # Check again
                device_count=$(adb devices | grep -E "device$" | wc -l)
            fi
        fi
    fi
    
    if [ "$device_count" -gt 0 ]; then
        write_log "Found $device_count connected device(s)" "INFO"
        return 0
    else
        write_log "No devices available. Some tests may be skipped." "WARNING"
        return 1
    fi
}

# Function to run unit tests
run_unit_tests() {
    write_log "========================================" "INFO"
    write_log "Starting Unit Tests" "INFO"
    write_log "========================================" "INFO"
    
    cd "$PROJECT_ROOT"
    
    # Run all unit tests
    write_log "Running unit tests..." "INFO"
    if flutter test test/unit/ 2>&1 | tee "$UNIT_TEST_LOG"; then
        write_log "Unit tests completed successfully" "INFO"
        return 0
    else
        write_log "Unit tests failed with exit code: $?" "ERROR"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    local require_device="${1:-true}"
    
    write_log "========================================" "INFO"
    write_log "Starting Integration Tests" "INFO"
    write_log "========================================" "INFO"
    
    # Check if device is required and available
    if [ "$require_device" = "true" ]; then
        if ! check_connected_devices; then
            write_log "Skipping integration tests - no device available" "WARNING"
            return 1
        fi
    fi
    
    cd "$PROJECT_ROOT"
    
    # Build the app for testing
    write_log "Building app for integration testing..." "INFO"
    if ! flutter build apk --debug > /dev/null 2>&1; then
        write_log "Failed to build app for testing" "ERROR"
        return 1
    fi
    
    # Install the app on device
    write_log "Installing app on device..." "INFO"
    local apk_path="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk"
    if [ -f "$apk_path" ]; then
        adb install -r "$apk_path" > /dev/null 2>&1
        write_log "App installed successfully" "INFO"
    fi
    
    # Run integration tests
    write_log "Running integration tests..." "INFO"
    if flutter test integration_test/ 2>&1 | tee "$INTEGRATION_TEST_LOG"; then
        write_log "Integration tests completed successfully" "INFO"
        return 0
    else
        write_log "Integration tests failed with exit code: $?" "ERROR"
        return 1
    fi
}

# Function to generate test summary
write_test_summary() {
    local unit_passed="$1"
    local integration_passed="$2"
    
    write_log "========================================" "INFO"
    write_log "Test Execution Summary" "INFO"
    write_log "========================================" "INFO"
    
    if [ "$unit_passed" -eq 0 ]; then
        write_log "Unit Tests: PASSED" "INFO"
    else
        write_log "Unit Tests: FAILED" "INFO"
    fi
    
    if [ "$integration_passed" -eq 0 ]; then
        write_log "Integration Tests: PASSED" "INFO"
    else
        write_log "Integration Tests: FAILED" "INFO"
    fi
    
    write_log "Log File: $LOG_FILE" "INFO"
    write_log "Unit Test Log: $UNIT_TEST_LOG" "INFO"
    write_log "Integration Test Log: $INTEGRATION_TEST_LOG" "INFO"
    write_log "========================================" "INFO"
    
    if [ "$unit_passed" -eq 0 ] && [ "$integration_passed" -eq 0 ]; then
        write_log "All tests completed successfully!" "INFO"
        exit 0
    else
        write_log "Some tests failed. Please check the log files for details." "ERROR"
        exit 1
    fi
}

# Main execution
write_log "========================================" "INFO"
write_log "Flutter Automated Test Suite" "INFO"
write_log "Project: Siyanaty+" "INFO"
write_log "Timestamp: $TIMESTAMP" "INFO"
write_log "========================================" "INFO"

# Check prerequisites
write_log "Checking prerequisites..." "INFO"
if ! check_flutter; then
    write_log "Flutter is required but not available. Exiting." "ERROR"
    exit 1
fi

# Run tests
unit_tests_passed=1
integration_tests_passed=1

# Run unit tests (don't require device)
write_log "Running unit tests (no device required)..." "INFO"
if run_unit_tests; then
    unit_tests_passed=0
fi

# Run integration tests (require device)
write_log "Running integration tests (device required)..." "INFO"
if run_integration_tests true; then
    integration_tests_passed=0
fi

# Generate summary
write_test_summary "$unit_tests_passed" "$integration_tests_passed"

