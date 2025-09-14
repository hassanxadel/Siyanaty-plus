import 'dart:convert';
import 'package:http/http.dart' as http;
import '../shared/constants/app_constants.dart';

class VinDecodedBasic {
  final String vin;
  final String make;
  final String model;
  final String year;
  final String engine;
  final String transmission;
  final String bodyStyle;
  final String fuelType;

  VinDecodedBasic({
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.engine,
    required this.transmission,
    required this.bodyStyle,
    required this.fuelType,
  });

  factory VinDecodedBasic.fromApi(Map<String, dynamic> json) {
    String getVal(String key) {
      final node = json[key];
      if (node is Map && node['value'] != null && node['value'].toString().isNotEmpty) {
        return node['value'].toString();
      }
      return json[key]?.toString() ?? '';
    }

    return VinDecodedBasic(
      vin: json['VIN']?.toString() ?? '',
      make: getVal('Make'),
      model: getVal('Model'),
      year: getVal('Model_Year'),
      engine: getVal('Engine_Type').isNotEmpty ? getVal('Engine_Type') : getVal('Engine_Displacement'),
      transmission: getVal('Transmission-long').isNotEmpty ? getVal('Transmission-long') : getVal('Transmission-short'),
      bodyStyle: getVal('Body_Style'),
      fuelType: getVal('Fuel_Type'),
    );
  }

  factory VinDecodedBasic.fromZpkApi(Map<String, dynamic> json, String vin) {
    // Parse manufacturer name to extract make and model
    String make = '';
    String model = '';
    String year = '';
    String engine = '';
    String transmission = '';
    String bodyStyle = '';
    String fuelType = '';
    
    // Get manufacturer name
    final manufacturerName = json['manufacturer_name']?.toString() ?? '';
    if (manufacturerName.isNotEmpty) {
      // Split manufacturer name (e.g., "Ford MPV/SUV" -> make: "Ford", model: "MPV/SUV")
      final parts = manufacturerName.split(' ');
      if (parts.isNotEmpty) {
        make = parts[0];
        if (parts.length > 1) {
          model = parts.sublist(1).join(' ');
        }
      }
    }
    
    // Get model from the dedicated model field if available
    final modelField = json['model']?.toString() ?? '';
    if (modelField.isNotEmpty) {
      model = modelField;
    }
    
    // Get year from the response
    year = json['year']?.toString() ?? '';
    
    // Get engine information
    final engineL = json['engine_l']?.toString() ?? '';
    final engineCylinders = json['engine_cylinders']?.toString() ?? '';
    if (engineL.isNotEmpty && engineCylinders.isNotEmpty) {
      engine = '${engineL}L $engineCylinders-Cylinder';
    } else if (engineL.isNotEmpty) {
      engine = '${engineL}L Engine';
    }
    
    // Get transmission (not directly available in this API response)
    transmission = '';
    
    // Get body style
    final bodyClass = json['body_class']?.toString() ?? '';
    final vehicleType = json['vehicle_type']?.toString() ?? '';
    if (bodyClass.isNotEmpty) {
      bodyStyle = bodyClass;
    } else if (vehicleType.isNotEmpty) {
      bodyStyle = vehicleType;
    }
    
    // Get fuel type
    final fuelTypePrimary = json['engine_fuel_type_primary']?.toString() ?? '';
    if (fuelTypePrimary.isNotEmpty) {
      fuelType = fuelTypePrimary;
    }
    
    return VinDecodedBasic(
      vin: vin,
      make: make,
      model: model,
      year: year,
      engine: engine,
      transmission: transmission,
      bodyStyle: bodyStyle,
      fuelType: fuelType,
    );
  }
}

class VinDecoderService {
  Future<VinDecodedBasic> decodeVin(String vin) async {
    final normalizedVin = vin.trim().toUpperCase();
    print('VIN Decoder: Starting decode for VIN: $normalizedVin');
    
    // Test internet connectivity first
    try {
      print('VIN Decoder: Testing internet connectivity...');
      final testResponse = await http.get(
        Uri.parse('https://httpbin.org/ip'),
      ).timeout(const Duration(seconds: 5));
      print('VIN Decoder: Internet test successful - Status: ${testResponse.statusCode}');
      
      // Test ZPK domain specifically
      print('VIN Decoder: Testing ZPK domain connectivity...');
      final zpkTestResponse = await http.get(
        Uri.parse('https://zpk.systems'),
      ).timeout(const Duration(seconds: 5));
      print('VIN Decoder: ZPK domain test successful - Status: ${zpkTestResponse.statusCode}');
    } catch (e) {
      print('VIN Decoder: Connectivity test failed: $e');
      throw Exception('Network connectivity issue. Please check your internet connection and try again.');
    }
    
    // Use only ZPK API with retry logic
    print('VIN Decoder: Using ZPK API...');
    return await _tryZpkApiWithRetry(normalizedVin);
  }

  Future<VinDecodedBasic> _tryZpkApiWithRetry(String vin) async {
    int maxRetries = 3;
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          // Progressive delay: 5s, 10s
          await Future.delayed(Duration(seconds: 5 * attempt));
        }
        
        final uri = Uri.parse('${AppConstants.zpkBaseUrl}/vin-analyzer/analyze');
        print('ZPK API URL: $uri');

        final requestBody = {
          'application_id': AppConstants.zpkApplicationId,
          'api_key': AppConstants.zpkApiKey,
          'vins': [vin],
        };
        print('ZPK API Request Body: ${json.encode(requestBody)}');

        print('ZPK API: Making HTTP request...');
        final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 15));
        print('ZPK API: HTTP request completed');

        print('ZPK API Response Status: ${response.statusCode}');
        print('ZPK API Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final parsed = json.decode(response.body);

          // Check if response has success: true and results array
          if (parsed is Map<String, dynamic> && parsed['success'] == true) {
            if (parsed['results'] is List && (parsed['results'] as List).isNotEmpty) {
              final results = parsed['results'] as List;
              final firstResult = results.first as Map<String, dynamic>;
              
              if (firstResult.containsKey('vin') && firstResult['vin'] is Map<String, dynamic>) {
                final vinData = firstResult['vin'] as Map<String, dynamic>;
                print('ZPK API Success: Found VIN data');
                return VinDecodedBasic.fromZpkApi(vinData, vin);
              }
            }
            print('ZPK API Error: No VIN data found in successful response');
            throw Exception('No VIN data found in API response');
          }
          
          // Handle error response (success: false)
          if (parsed is Map<String, dynamic> && parsed['success'] == false) {
            if (parsed['errors'] is List && (parsed['errors'] as List).isNotEmpty) {
              final errors = parsed['errors'] as List;
              final firstError = errors.first as Map<String, dynamic>;
              final errorId = firstError['id']?.toString() ?? 'UNKNOWN_ERROR';
              final errorMessage = firstError['message']?.toString() ?? 'Unknown error';
              
              print('ZPK API Error: $errorId - $errorMessage');
              
              if (errorId == 'INVALID_API_KEY') {
                throw Exception('Invalid API key. Please check your ZPK API credentials.');
              } else if (errorId == 'RATE_LIMIT_EXCEEDED') {
                throw Exception('Rate limit exceeded. Please wait a few minutes before trying again.');
              } else {
                throw Exception('API Error: $errorMessage');
              }
            }
            print('ZPK API Error: Unknown error format - ${response.body}');
            throw Exception('Unknown API error format');
          }
          
          print('ZPK API Error: Invalid response format - ${response.body}');
          throw Exception('Invalid response format from ZPK API');
        }
        
        if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded');
        }
        
        throw Exception('ZPK API returned status ${response.statusCode}: ${response.body}');
      } catch (e) {
        print('ZPK API Attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          throw Exception('VIN lookup failed after $maxRetries attempts. Please try again in a few minutes.');
        }
      }
    }
    
    throw Exception('VIN lookup failed: Unable to retrieve vehicle information');
  }

}



