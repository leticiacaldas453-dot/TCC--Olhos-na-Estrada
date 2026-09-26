import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/app_language.dart';
import '../services/ble_manager.dart';
import '../services/route_service.dart';

class NavigationScreen extends StatefulWidget {
  final String destination;
  final LatLng origin;
  final LatLng destinationPosition;
  final List<LatLng> routePoints;
  final List<RouteInstruction> instructions;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.origin,
    required this.destinationPosition,
    required this.routePoints,
    required this.instructions,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  double _progress = 0.0;
  Timer? _timer;
  Timer? _routeTimer;
  Timer? _sendTimer;
  StreamSubscription<Position>? _positionStreamSubscription;

  String _currentInstruction = "Siga em frente";
  final IconData _directionIcon = Icons.straight;

  late LatLng _currentPos = widget.origin;
  late List<LatLng> _routePoints = List.of(widget.routePoints);
  late List<RouteInstruction> _instructions = List.of(widget.instructions);
  DateTime _lastInstructionSent = DateTime.fromMillisecondsSinceEpoch(0);

  GoogleMapController? _mapController;

  Set<Polyline> get _route {
    if (_routePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('navigation_route'),
        points: _routePoints,
        color: const Color.fromARGB(217, 217, 10, 10),
        width: 6,
      ),
    };
  }

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Origem'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destinationPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.destination),
        ),
      };

  @override
  void initState() {
    super.initState();
   // WakelockPlus.enable();
    _startNavigation();
    _routeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshRoute());
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (_) => _sendDirectionsToEsp());
    _startBackgroundService();
  }

  Future<void> _startBackgroundService() async {
    print('>>> [BG] Iniciando serviço...');
    final service = FlutterBackgroundService();

    // Verifica se já está rodando
    final isRunningBefore = await service.isRunning();
    print('>>> [BG] Já estava rodando? $isRunningBefore');

    // Inicia o serviço
    await service.startService();
    print('>>> [BG] startService() chamado.');

    // Aguarda 2 segundos para o serviço inicializar
    await Future.delayed(const Duration(seconds: 2));

    // Verifica se está rodando agora
    final isRunningAfter = await service.isRunning();
    print('>>> [BG] Está rodando agora? $isRunningAfter');

    if (isRunningAfter) {
      // Promove para Foreground (ativa a notificação)
      service.invoke('setAsForeground');
      print('>>> [BG] setAsForeground() chamado! Notificação deve aparecer.');
    } else {
      print('>>> [BG] ERRO: Serviço não iniciou!');
    }
  }

  @override
  void dispose() {
   // WakelockPlus.disable();
    _timer?.cancel();
    _routeTimer?.cancel();
    _sendTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();

    final service = FlutterBackgroundService();
    service.invoke('stopService');

    super.dispose();
  }

  void _startNavigation() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) async {
      if (!mounted) return;

      final newPos = LatLng(position.latitude, position.longitude);

      if (_mapController != null) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newPos, zoom: 19, tilt: 60, bearing: position.heading),
          ),
        );
      }

      setState(() {
        _currentPos = newPos;
      });

      _updateNextInstruction(_currentPos);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) _progress = 1.0;
      });
    });
  }

  void _updateNextInstruction(LatLng position) {
    if (_instructions.isEmpty) return;
    final next = _instructions.firstWhere(
      (instruction) => Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        instruction.location.latitude,
        instruction.location.longitude,
      ) > 30,
      orElse: () => _instructions.last,
    );
    if (mounted) {
      setState(() {
        _currentInstruction = next.text;
      });
    }
  }

  Future<void> _refreshRoute() async {
    try {
      final language = await AppLanguage.getLanguage();
      final route = await RouteService.fetchRoute(
        origin: _currentPos,
        destination: widget.destinationPosition,
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _routePoints = route.points;
        _instructions = route.instructions;
      });
      _updateNextInstruction(_currentPos);
    } catch (e) {
      debugPrint("Erro ao atualizar rota: $e");
    }
  }

  Future<void> _sendDirectionsToEsp() async {
    if (!BleManager.instance.isConnected || _instructions.isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastInstructionSent) < const Duration(seconds: 4)) return;
    _lastInstructionSent = now;

    final instruction = _instructions.firstWhere(
      (item) => Geolocator.distanceBetween(
        _currentPos.latitude,
        _currentPos.longitude,
        item.location.latitude,
        item.location.longitude,
      ) > 30,
      orElse: () => _instructions.last,
    );
    final payload = 'DIR|${instruction.text}|${_currentPos.latitude},${_currentPos.longitude}';
    try {
      await BleManager.instance.writeInstruction(payload);
    } catch (e) {
      debugPrint("Erro ao enviar para ESP32: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.origin,
              zoom: 13.5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitRouteBounds();
            },
            polylines: _route,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 10,
                    shadowColor: Colors.black45,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color.fromARGB(217, 217, 10, 10),
                            child: Icon(_directionIcon, color: Colors.white, size: 32),
                          ),
                          title: Text(
                            _currentInstruction,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Destino: ${widget.destination}",
                              style: const TextStyle(
                                color: Color.fromARGB(217, 217, 10, 10),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Sincronizando com ESP32...",
                                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${(_progress * 100).toInt()}%",
                                    style: const TextStyle(fontSize: 11, color: Color.fromARGB(217, 217, 10, 10), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  backgroundColor: const Color.fromARGB(217, 217, 10, 10).withAlpha(25),
                                  color: const Color.fromARGB(217, 217, 10, 10),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Para o serviço em segundo plano
                        final service = FlutterBackgroundService();
                        service.invoke('stopService');

                        // Volta para a tela inicial
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1)],
                        ),
                        child: const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.close, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "ENCERRAR",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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

  void _fitRouteBounds() {
    if (_routePoints.isEmpty) return;
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }
}