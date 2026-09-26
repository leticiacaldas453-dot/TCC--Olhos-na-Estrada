import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../services/route_service.dart';
import 'navigation_screen.dart';
import '../services/app_language.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

class RouteConfirmationScreen extends StatefulWidget {
  final String destination;

  const RouteConfirmationScreen({super.key, required this.destination});

  @override
  State<RouteConfirmationScreen> createState() => _RouteConfirmationScreenState();
}

class _RouteConfirmationScreenState extends State<RouteConfirmationScreen> {
  static const LatLng _fallbackOrigin = LatLng(-23.5617, -46.6560);
  LatLng? _origin;
  LatLng? _destination;
  RouteResult? _routeResult;
  String? _error;
  String _distanceText = "-- km";
  String _durationText = "-- min";

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização necessária');
      }

      final position = await Geolocator.getCurrentPosition();
      final locations = await locationFromAddress(widget.destination);
      if (locations.isEmpty) throw Exception('Destino não encontrado');

      final origin = LatLng(position.latitude, position.longitude);
      final destination = LatLng(locations.first.latitude, locations.first.longitude);

      // ⬇️ AQUI: Lê o idioma salvo
      final language = await AppLanguage.getLanguage();

      final route = await RouteService.fetchRoute(
        origin: origin,
        destination: destination,
        language: language, // <-- Passa o idioma
      );

      if (!mounted) return;
      setState(() {
        _origin = origin;
        _destination = destination;
        _routeResult = route;
        // CORREÇÃO: Formata os doubles do OSRM para texto legível
        _distanceText = _formatDistance(route.distanceMeters, language);
        _durationText = _formatDuration(route.durationSeconds);
      });

      // Enquadra a rota na tela após o mapa ser criado
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRouteBounds());
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  /// Converte metros para "X.X km" ou "XXX m"
  String _formatDistance(double meters, String language) {
    final locale = language == 'pt-BR' ? 'pt_BR' : (language == 'es' ? 'es' : (language == 'zh' ? 'zh' : 'en'));
    final format = NumberFormat.decimalPattern(locale);

    if (meters >= 1000) {
      return '${format.format(meters / 1000)} km';
    }
    return '${format.format(meters)} m';
  }

  /// Converte segundos para "X min" ou "X h Y min"
  String _formatDuration(double seconds) {
    final totalMinutes = (seconds / 60).round();
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '${hours}h ${minutes}min';
    }
    return '$totalMinutes min';
  }

  Set<Marker> get _markers => {
        if (_origin != null)
          Marker(
            markerId: const MarkerId('origin'),
            position: _origin!,
            infoWindow: const InfoWindow(title: 'Sua Localização'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        if (_destination != null)
          Marker(
            markerId: const MarkerId('destination'),
            position: _destination!,
            infoWindow: const InfoWindow(title: 'Destino'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
      };

  Set<Polyline> get _polylines => {
        if (_routeResult != null && _routeResult!.points.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routeResult!.points,
            color: const Color.fromARGB(217, 217, 10, 10),
            width: 5,
          ),
      };

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitRouteBounds();
  }

  void _fitRouteBounds() {
    final points = _routeResult?.points;
    if (points == null || points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.confirmRoute),
        backgroundColor: const Color.fromARGB(217, 217, 10, 10),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. MAPA
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _origin ?? _fallbackOrigin,
              zoom: 13.5,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Botão de Centralizar
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _fitRouteBounds,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: Color.fromARGB(217, 217, 10, 10),
              ),
            ),
          ),

          // 3. Loading (enquanto carrega a rota)
          if (_origin == null && _error == null)
            const Center(child: CircularProgressIndicator()),

          // 4. Resumo da Viagem
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    Text(
                      '${t.destination}: ${widget.destination}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(217, 217, 10, 10),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              t.distance,
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              _distanceText,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              t.estimatedTime,
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              _durationText,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_origin == null ||
                                _destination == null ||
                                _routeResult == null)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NavigationScreen(
                                      destination: widget.destination,
                                      origin: _origin!,
                                      destinationPosition: _destination!,
                                      routePoints: _routeResult!.points,
                                      instructions: _routeResult!.instructions,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(217, 217, 10, 10),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          t.startRoute,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}