// lib/services/location_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationService {

  Future<Position> getCurrentLocation() async {
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

  Future<List<LatLng>> getPolylinePoints(LatLng start, LatLng end, String apiKey) async {
    final String url = 
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey';
    
    if (kDebugMode) {
      print("[DEBUG] URL de Direcciones: $url");
    }

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
      if (kDebugMode) {
        print("[DEBUG] Error en getPolylinePoints: $e");
      }
      rethrow;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
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
