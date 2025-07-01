// lib/services/location_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// --- NUEVA CLASE MODELO PARA LAS SUGERENCIAS ---
// Un objeto simple para guardar los datos de cada sugerencia de lugar.
class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion(this.placeId, this.description);
}
// ---------------------------------------------

class LocationService {

  Future<Position> getCurrentLocation() async {
    // ... este método no cambia ...
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Los permisos de ubicación están permanentemente denegados.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // --- NUEVO MÉTODO PARA AUTOCOMPLETADO ---
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String input, String apiKey) async {
    if (input.isEmpty) {
      return [];
    }
    
    final String encodedInput = Uri.encodeComponent(input);
    // El "sessiontoken" ayuda a agrupar las solicitudes y puede reducir costos.
    // Se genera uno nuevo para cada sesión de búsqueda.
    final sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    
    // URL para una búsqueda amplia, restringida solo a México para mayor relevancia.
    final String url = 
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedInput&key=$apiKey&sessiontoken=$sessionToken&components=country:mx';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List;
        // Convertimos la respuesta JSON en una lista de nuestros objetos PlaceSuggestion.
        return predictions.map((p) => PlaceSuggestion(p['place_id'], p['description'])).toList();
      }
    }
    return []; // Devuelve una lista vacía si hay un error.
  }
  // ----------------------------------------

  // --- NUEVO MÉTODO PARA DETALLES DEL LUGAR ---
  Future<LatLng> getPlaceDetails(String placeId, String apiKey) async {
    final sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    // Le pedimos a la API solo el campo 'geometry' para obtener las coordenadas.
    final String url = 
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey&sessiontoken=$sessionToken&fields=geometry';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      } else {
        throw Exception("Error de Place Details API: ${data['error_message'] ?? data['status']}");
      }
    } else {
      throw Exception("Error al conectar con Place Details API. Código: ${response.statusCode}");
    }
  }
  // --------------------------------------------

  Future<List<LatLng>> getPolylinePoints(LatLng start, LatLng end, String apiKey) async {
    // ... este método no cambia ...
    final String url = 
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
            return _decodePolyline(encodedPolyline);
          } else {
            throw Exception("No se encontraron rutas en la respuesta de Google.");
          }
        } else {
          throw Exception("Error de la API de Direcciones: ${data['error_message'] ?? data['status']}");
        }
      } else {
        throw Exception("Error al conectar con la API de Direcciones. Código: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    // ... este método no cambia ...
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
