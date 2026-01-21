import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  final String _apiKey = 'AIzaSyCirMlYvLCV-XyNco9C0gakqUiDfrnq2a8'; 
  
  // NEW API: v1
  final String _baseUrl = 'https://places.googleapis.com/v1/places:autocomplete';
  final String _detailsUrl = 'https://places.googleapis.com/v1/places';

  Future<List<Map<String, dynamic>>> searchPlaces(String query, String sessionToken) async {
    if (query.isEmpty) return [];

    // Dhamtari Restriction (New API uses JSON body for configuration)
    // Center: 20.7066, 81.5492
    // Radius: 50000 meters
    
    final requestBody = {
      "input": query,
      "sessionToken": sessionToken,
      "locationRestriction": {
        "circle": {
          "center": {
            "latitude": 20.7066,
            "longitude": 81.5492
          },
          "radius": 50000.0
        }
      },
      // Optional: Bias results to India if needed, but restriction handles area well.
      // "includedRegionCodes": ["IN"], 
    };

    print("DEBUG: Places Search (New API) Request: $_baseUrl");
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: json.encode(requestBody),
      );

      print("DEBUG: Places Search Response Code: ${response.statusCode}");
      // print("DEBUG: Places Search Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List<dynamic>?;
        
        if (suggestions != null) {
          // Map New API response to the structure expected by the UI (Legacy format)
          return suggestions.map((s) {
            final prediction = s['placePrediction'];
            final structured = prediction['structuredFormat'];
            
            return {
              'description': prediction['text']['text'], // Full text
              'place_id': prediction['placeId'],
              'structured_formatting': {
                'main_text': structured['mainText']['text'],
                'secondary_text': structured['secondaryText']?['text'] ?? "",
              }
            };
          }).toList().cast<Map<String, dynamic>>();
        }
      } else {
        print("DEBUG: Places API Error: ${response.body}");
      }
    } catch (e) {
      print("DEBUG: Places API Exception: $e");
    }
    return [];
  }
  
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId, String sessionToken) async {
    // New API Details: GET /v1/places/{placeId}
    // Requires FieldMask header
    
    final uri = Uri.parse('$_detailsUrl/$placeId');
    
    print("DEBUG: Place Details URI: $uri");
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-Session-Token': sessionToken,
          // Specify fields we need: location, formattedAddress
          'X-Goog-FieldMask': 'location,formattedAddress,displayName,addressComponents', 
        },
      );

      print("DEBUG: Place Details Response: ${response.statusCode}");
      
      if (response.statusCode == 200) {
         final data = json.decode(response.body);
         
         // Map to format expected by UI (which expects 'geometry' -> 'location')
         // New API returns top-level 'location' object: { "latitude": ..., "longitude": ... }
         
         return {
           'geometry': {
             'location': {
               'lat': data['location']['latitude'],
               'lng': data['location']['longitude'],
             }
           },
           'formatted_address': data['formattedAddress'],
           'name': data['displayName']?['text'] ?? "",
           'address_components': data['addressComponents'], // Pass through for validation
         };
      } else {
         print("DEBUG: Place Details Error: ${response.body}");
      }
    } catch (e) {
      print("DEBUG: Place Details Exception: $e");
    }
    return null;
  }
}
