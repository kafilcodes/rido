import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  final String _apiKey = 'AIzaSyCirMlYvLCV-XyNco9C0gakqUiDfrnq2a8'; 
  final String _baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  Future<List<Map<String, dynamic>>> searchPlaces(String query, String sessionToken) async {
    if (query.isEmpty) return [];

    // Dhamtari/Chhattisgarh restriction approach:
    // strictbounds + location + radius is best.
    // Dhamtari Lat/Lng: 20.7066, 81.5492
    // Radius: ~100km to cover surrounding areas? Or just bias.
    // User said "restrict... show only...". strictbounds is needed.
    // Let's set location to Dhamtari and radius to 50km.
    
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'input': query,
      'key': _apiKey,
      'sessiontoken': sessionToken,
      'components': 'country:in', // Restrict to India
      'location': '20.7066,81.5492', // Dhamtari
      'radius': '50000', // 50km
      'strictbounds': 'true', // Restrict results to this region
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return List<Map<String, dynamic>>.from(data['predictions']);
      }
    }
    return [];
  }
  
  // Also need Place Details to get Lat/Lng from Place ID
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId, String sessionToken) async {
    final uri = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json').replace(queryParameters: {
      'place_id': placeId,
      'key': _apiKey,
      'sessiontoken': sessionToken,
      'fields': 'name,geometry,formatted_address', // minimize cost
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
       final data = json.decode(response.body);
       if (data['status'] == 'OK') {
         return data['result'];
       }
    }
    return null;
  }
}
