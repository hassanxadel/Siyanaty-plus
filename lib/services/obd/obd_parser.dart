import '../../shared/utils/app_logger.dart';

/// Parser for OBD-II command responses
/// Converts raw hex responses to human-readable values
class ObdParser {
  /// Parse engine coolant temperature (PID 0105)
  /// Response format: 41 05 A
  /// Formula: Temperature (°C) = A - 40
  static double? parseCoolantTemperature(String response) {
    try {
      final cleaned = _cleanResponse(response);
      if (!_isValidResponse(cleaned, '41 05')) return null;
      
      final bytes = _extractDataBytes(cleaned);
      if (bytes.isEmpty) return null;
      
      final tempC = bytes[0] - 40;
      return tempC.toDouble();
    } catch (e) {
      AppLogger.error('Error parsing coolant temperature', error: e);
      return null;
    }
  }

  /// Parse engine RPM (PID 010C)
  /// Response format: 41 0C A B
  /// Formula: RPM = ((A * 256) + B) / 4
  static int? parseEngineRpm(String response) {
    try {
      final cleaned = _cleanResponse(response);
      if (!_isValidResponse(cleaned, '41 0C')) return null;
      
      final bytes = _extractDataBytes(cleaned);
      if (bytes.length < 2) return null;
      
      final rpm = ((bytes[0] * 256) + bytes[1]) / 4;
      return rpm.round();
    } catch (e) {
      AppLogger.error('Error parsing engine RPM', error: e);
      return null;
    }
  }

  /// Parse vehicle speed (PID 010D)
  /// Response format: 41 0D A
  /// Formula: Speed (km/h) = A
  static int? parseVehicleSpeed(String response) {
    try {
      final cleaned = _cleanResponse(response);
      if (!_isValidResponse(cleaned, '41 0D')) return null;
      
      final bytes = _extractDataBytes(cleaned);
      if (bytes.isEmpty) return null;
      
      return bytes[0];
    } catch (e) {
      AppLogger.error('Error parsing vehicle speed', error: e);
      return null;
    }
  }

  /// Parse throttle position (PID 0111)
  /// Response format: 41 11 A
  /// Formula: Throttle (%) = (A * 100) / 255
  static double? parseThrottlePosition(String response) {
    try {
      final cleaned = _cleanResponse(response);
      if (!_isValidResponse(cleaned, '41 11')) return null;
      
      final bytes = _extractDataBytes(cleaned);
      if (bytes.isEmpty) return null;
      
      final throttle = (bytes[0] * 100) / 255;
      return throttle;
    } catch (e) {
      AppLogger.error('Error parsing throttle position', error: e);
      return null;
    }
  }

  /// Parse fuel level (PID 012F)
  /// Response format: 41 2F A
  /// Formula: Fuel (%) = (A * 100) / 255
  static double? parseFuelLevel(String response) {
    try {
      final cleaned = _cleanResponse(response);
      if (!_isValidResponse(cleaned, '41 2F')) return null;
      
      final bytes = _extractDataBytes(cleaned);
      if (bytes.isEmpty) return null;
      
      final fuel = (bytes[0] * 100) / 255;
      return fuel;
    } catch (e) {
      AppLogger.error('Error parsing fuel level', error: e);
      return null;
    }
  }

  /// Parse battery voltage (ATRV command - ELM327 specific)
  /// Response format: "12.6V"
  static double? parseBatteryVoltage(String response) {
    try {
      final cleaned = _cleanResponse(response);
      // Remove 'V' and any whitespace
      final numericString = cleaned.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numericString);
    } catch (e) {
      AppLogger.error('Error parsing battery voltage', error: e);
      return null;
    }
  }

  /// Parse engine load (PID 0104)
  /// Response format: 41 04 A
  /// Formula: Load (%) = (A * 100) / 255
  static double? parseEngineLoad(String response) {
    try {
      final cleaned = _cleanResponse(response);
      if (!_isValidResponse(cleaned, '41 04')) return null;
      
      final bytes = _extractDataBytes(cleaned);
      if (bytes.isEmpty) return null;
      
      final load = (bytes[0] * 100) / 255;
      return load;
    } catch (e) {
      AppLogger.error('Error parsing engine load', error: e);
      return null;
    }
  }

  /// Parse intake air temperature (PID 010F)
  /// Response format: 41 0F A
  /// Formula: Temperature (°C) = A - 40
  static double? parseIntakeAirTemperature(String response) {
    try {
      final cleaned = _cleanResponse(response);
      if (!_isValidResponse(cleaned, '41 0F')) return null;
      
      final bytes = _extractDataBytes(cleaned);
      if (bytes.isEmpty) return null;
      
      final tempC = bytes[0] - 40;
      return tempC.toDouble();
    } catch (e) {
      AppLogger.error('Error parsing intake air temperature', error: e);
      return null;
    }
  }

  /// Parse diagnostic trouble codes (DTC)
  /// Response format varies, can be multiple lines
  static List<String> parseDiagnosticCodes(String response) {
    try {
      final codes = <String>[];
      final cleaned = _cleanResponse(response);
      
      // DTC format: P0XXX, C0XXX, B0XXX, U0XXX
      final dtcRegex = RegExp(r'[PCBU][0-9A-F]{4}', caseSensitive: false);
      final matches = dtcRegex.allMatches(cleaned);
      
      for (final match in matches) {
        codes.add(match.group(0)!.toUpperCase());
      }
      
      return codes;
    } catch (e) {
      AppLogger.error('Error parsing diagnostic codes', error: e);
      return [];
    }
  }

  /// Clean OBD response by removing unwanted characters
  /// - Remove carriage returns and newlines
  /// - Remove '>' prompt
  /// - Remove "SEARCHING..." and "NO DATA" messages
  /// - Trim whitespace
  static String _cleanResponse(String response) {
    return response
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll('>', '')
        .replaceAll('SEARCHING...', '')
        .replaceAll('SEARCHING', '')
        .trim()
        .toUpperCase();
  }

  /// Check if response is valid for given PID
  /// Valid response should start with expected header (e.g., "41 05" for PID 0105)
  static bool _isValidResponse(String response, String expectedHeader) {
    if (response.contains('NO DATA')) return false;
    if (response.contains('ERROR')) return false;
    if (response.contains('UNABLE TO CONNECT')) return false;
    if (response.isEmpty) return false;
    
    return response.startsWith(expectedHeader);
  }

  /// Extract data bytes from OBD response
  /// Example: "41 05 7B" → [123] (0x7B = 123)
  static List<int> _extractDataBytes(String response) {
    try {
      // Split by spaces and filter out empty strings
      final parts = response.split(' ').where((s) => s.isNotEmpty).toList();
      
      // First two bytes are header (41 XX), rest are data
      if (parts.length <= 2) return [];
      
      final dataBytes = <int>[];
      for (int i = 2; i < parts.length; i++) {
        final byte = int.tryParse(parts[i], radix: 16);
        if (byte != null) {
          dataBytes.add(byte);
        }
      }
      
      return dataBytes;
    } catch (e) {
      AppLogger.error('Error extracting data bytes', error: e);
      return [];
    }
  }

  /// Check if response indicates no data available
  static bool isNoDataResponse(String response) {
    final cleaned = _cleanResponse(response);
    return cleaned.contains('NO DATA') || 
           cleaned.contains('?') || 
           cleaned.isEmpty;
  }

  /// Check if response indicates an error
  static bool isErrorResponse(String response) {
    final cleaned = _cleanResponse(response);
    return cleaned.contains('ERROR') || 
           cleaned.contains('UNABLE TO CONNECT') ||
           cleaned.contains('CAN ERROR') ||
           cleaned.contains('BUS INIT');
  }
}
