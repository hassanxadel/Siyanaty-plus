/// Model representing real-time OBD-II data from a vehicle
class ObdData {
  final int? rpm;                    // Engine RPM
  final int? speed;                  // Vehicle speed (km/h)
  final double? coolantTemp;         // Engine coolant temperature (°C)
  final double? throttlePosition;    // Throttle position (%)
  final double? fuelLevel;           // Fuel level (%)
  final double? batteryVoltage;      // Battery voltage (V)
  final double? engineLoad;          // Engine load (%)
  final double? intakeAirTemp;       // Intake air temperature (°C)
  final DateTime? timestamp;         // When this data was captured

  ObdData({
    this.rpm,
    this.speed,
    this.coolantTemp,
    this.throttlePosition,
    this.fuelLevel,
    this.batteryVoltage,
    this.engineLoad,
    this.intakeAirTemp,
    this.timestamp,
  });

  /// Create a copy with updated values
  ObdData copyWith({
    int? rpm,
    int? speed,
    double? coolantTemp,
    double? throttlePosition,
    double? fuelLevel,
    double? batteryVoltage,
    double? engineLoad,
    double? intakeAirTemp,
    DateTime? timestamp,
  }) {
    return ObdData(
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      coolantTemp: coolantTemp ?? this.coolantTemp,
      throttlePosition: throttlePosition ?? this.throttlePosition,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      engineLoad: engineLoad ?? this.engineLoad,
      intakeAirTemp: intakeAirTemp ?? this.intakeAirTemp,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert coolant temperature from Celsius to Fahrenheit
  double? get coolantTempF {
    if (coolantTemp == null) return null;
    return (coolantTemp! * 9 / 5) + 32;
  }

  /// Convert speed from km/h to mph
  double? get speedMph {
    if (speed == null) return null;
    return speed! * 0.621371;
  }

  /// Check if coolant temperature is in normal range
  bool get isCoolantTempNormal {
    if (coolantTemp == null) return true;
    return coolantTemp! >= 80 && coolantTemp! <= 110; // Normal range: 80-110°C
  }

  /// Check if battery voltage is healthy
  bool get isBatteryHealthy {
    if (batteryVoltage == null) return true;
    return batteryVoltage! >= 12.4; // Healthy voltage: >= 12.4V
  }

  /// Get human-readable status for coolant temperature
  String get coolantTempStatus {
    if (coolantTemp == null) return 'N/A';
    if (coolantTemp! < 60) return 'Cold';
    if (coolantTemp! < 80) return 'Warming';
    if (coolantTemp! <= 110) return 'Normal';
    if (coolantTemp! <= 120) return 'High';
    return 'Overheating';
  }

  /// Get human-readable status for battery
  String get batteryStatus {
    if (batteryVoltage == null) return 'N/A';
    if (batteryVoltage! >= 12.6) return 'Excellent';
    if (batteryVoltage! >= 12.4) return 'Good';
    if (batteryVoltage! >= 12.0) return 'Fair';
    return 'Low';
  }

  /// Check if any data is available
  bool get hasData {
    return rpm != null ||
        speed != null ||
        coolantTemp != null ||
        throttlePosition != null ||
        fuelLevel != null ||
        batteryVoltage != null;
  }

  @override
  String toString() {
    return 'ObdData(rpm: $rpm, speed: $speed km/h, coolantTemp: $coolantTemp°C, '
        'throttle: $throttlePosition%, fuel: $fuelLevel%, battery: $batteryVoltage V, '
        'timestamp: $timestamp)';
  }
}

/// Model representing a diagnostic trouble code
class DiagnosticCode {
  final String code;           // e.g., "P0171"
  final String description;    // Human-readable description
  final String status;         // "Active", "Pending", "Cleared"
  final DateTime? detectedAt;  // When the code was detected

  DiagnosticCode({
    required this.code,
    required this.description,
    required this.status,
    this.detectedAt,
  });

  /// Get the code type (Powertrain, Chassis, Body, Network)
  String get codeType {
    if (code.isEmpty) return 'Unknown';
    switch (code[0].toUpperCase()) {
      case 'P':
        return 'Powertrain';
      case 'C':
        return 'Chassis';
      case 'B':
        return 'Body';
      case 'U':
        return 'Network';
      default:
        return 'Unknown';
    }
  }

  /// Get severity level based on code
  /// This is a simplified version - real implementation would use a database
  String get severity {
    if (code.startsWith('P0')) {
      // Generic powertrain codes are usually moderate
      return 'Moderate';
    } else if (code.startsWith('P1')) {
      // Manufacturer-specific codes
      return 'Variable';
    }
    return 'Unknown';
  }

  @override
  String toString() {
    return 'DiagnosticCode(code: $code, description: $description, status: $status)';
  }
}

/// OBD connection state
enum ObdConnectionState {
  disconnected,
  connecting,
  initializing,
  connected,
  error,
}
