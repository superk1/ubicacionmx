// lib/screens/map_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
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
  
  // --- VARIABLES PARA LA BÚSQUEDA PREDICTIVA ---
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Timer para la técnica de "debounce"
  List<PlaceSuggestion> _suggestions = []; // Lista para guardar las sugerencias
  // -------------------------------------------

  LatLng? _destino;
  LatLng? _posicionActual;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionInicial();
    // Añadimos un "escucha" al controlador para reaccionar a los cambios.
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Es crucial limpiar los controladores y timers para evitar fugas de memoria.
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- LÓGICA DEL DEBOUNCER PARA BÚSQUEDA PREDICTIVA ---
  void _onSearchChanged() {
    // Si ya hay un timer esperando, lo cancelamos para empezar de nuevo.
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Creamos un nuevo timer que esperará 500ms antes de buscar.
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Solo buscamos si el usuario ha escrito al menos 3 caracteres.
      if (_searchController.text.length > 2) {
        _fetchAutocompleteSuggestions();
      } else {
        // Si borra el texto, limpiamos las sugerencias.
        setState(() {
          _suggestions = [];
        });
      }
    });
  }
  // -----------------------------------------------------

  Future<void> _fetchAutocompleteSuggestions() async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return;

    final result = await _locationService.getAutocompleteSuggestions(_searchController.text, apiKey);
    if (!mounted) return;
    setState(() {
      _suggestions = result;
    });
  }

  Future<void> _obtenerUbicacionInicial() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _posicionActual = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _posicionActual!, zoom: 14),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: ${e.toString()}')),
      );
    }
  }

  // --- FUNCIÓN PARA MANEJAR LA SELECCIÓN DE UNA SUGERENCIA ---
  Future<void> _seleccionarDestino(PlaceSuggestion suggestion) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return;

    FocusScope.of(context).unfocus(); // Ocultar teclado

    // Lógica para evitar que el listener se dispare de nuevo al actualizar el texto
    _searchController.removeListener(_onSearchChanged);
    setState(() {
      _searchController.text = suggestion.description;
      _suggestions = []; 
    });
    _searchController.addListener(_onSearchChanged);

    try {
      final coordenadasDestino = await _locationService.getPlaceDetails(suggestion.placeId, apiKey);
      setState(() {
        _destino = coordenadasDestino;
      });
      await _trazarRuta();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener detalles del lugar: ${e.toString()}')),
      );
    }
  }
  // ---------------------------------------------------

  Future<void> _trazarRuta() async {
    if (_posicionActual == null || _destino == null) return;
    
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return;

    try {
      final points = await _locationService.getPolylinePoints(
        _posicionActual!,
        _destino!,
        apiKey,
      );
      if (!mounted) return;

      final southwestLat = math.min(_posicionActual!.latitude, _destino!.latitude);
      final southwestLng = math.min(_posicionActual!.longitude, _destino!.longitude);
      final northeastLat = math.max(_posicionActual!.latitude, _destino!.latitude);
      final northeastLng = math.max(_posicionActual!.longitude, _destino!.longitude);
      final LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(southwestLat, southwestLng),
          northeast: LatLng(northeastLat, northeastLng),
      );

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));

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
          Marker(
            markerId: const MarkerId('destino'),
            position: _destino!,
            infoWindow: InfoWindow(title: _searchController.text),
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
        title: const Text('UbicacionMX - Buscar Destino'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _posicionActual ?? const LatLng(19.4326, -99.1332),
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
            onTap: (_) {
              // Ocultar sugerencias y teclado si se toca el mapa
              FocusScope.of(context).unfocus();
              setState(() {
                _suggestions = [];
              });
            },
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [ BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)) ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '¿A dónde vamos?',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: (){
                          _searchController.clear();
                        },
                      )
                    ],
                  ),
                ),
                // --- LISTA DE SUGERENCIAS ---
                if (_suggestions.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 5),
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true, // Para que la lista no ocupe toda la pantalla
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          title: Text(suggestion.description),
                          leading: const Icon(Icons.location_on),
                          onTap: () {
                            _seleccionarDestino(suggestion);
                          },
                        );
                      },
                    ),
                  )
                // ---------------------------
              ],
            ),
          ),
        ],
      ),
    );
  }
}

