// lib/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ubicacionmx_nueva/services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = LocationService();
  static const LatLng _destinoCDMX = LatLng(19.432608, -99.133209);
  LatLng? _posicionActual;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionYTrazarRuta();
  }

  Future<void> _obtenerUbicacionYTrazarRuta() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _posicionActual = LatLng(position.latitude, position.longitude);
      });
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _posicionActual!, zoom: 14),
      ));
      await _trazarRuta();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: ${e.toString()}')),
      );
    }
  }

  Future<void> _trazarRuta() async {
    if (_posicionActual == null) return;
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: API Key de Direcciones no encontrada.')),
      );
      return;
    }
    try {
      final points = await _locationService.getPolylinePoints(
        _posicionActual!,
        _destinoCDMX,
        apiKey,
      );
      if (!mounted) return;
      setState(() {
        _markers.clear();
        _polylines.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('posicionActual'),
            position: _posicionActual!,
            infoWindow: const InfoWindow(title: 'Mi Ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
        _markers.add(
          const Marker(
            markerId: MarkerId('destinoCDMX'),
            position: _destinoCDMX,
            infoWindow: InfoWindow(title: 'Destino: CDMX'),
          ),
        );
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('ruta'),
            color: Colors.blueAccent,
            points: points,
            width: 5,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al trazar la ruta: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UbicacionMX - Ruta a CDMX'),
      ),
      body: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _posicionActual ?? _destinoCDMX,
                zoom: 12,
              ),
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                    _controller.complete(controller);
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
       floatingActionButton: FloatingActionButton.extended(
        onPressed: _obtenerUbicacionYTrazarRuta,
        label: const Text('Recalcular'),
        icon: const Icon(Icons.refresh),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
