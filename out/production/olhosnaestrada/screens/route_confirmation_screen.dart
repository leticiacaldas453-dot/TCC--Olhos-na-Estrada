import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'navigation_screen.dart';

class RouteConfirmationScreen extends StatefulWidget {
  final String destination;

  const RouteConfirmationScreen({super.key, required this.destination});

  @override
  State<RouteConfirmationScreen> createState() => _RouteConfirmationScreenState();
}

class _RouteConfirmationScreenState extends State<RouteConfirmationScreen> {
  // Coordenadas fictícias para demonstração
  static const LatLng _origin = LatLng(-23.5617, -46.6560); // Av. Paulista
  static const LatLng _dest = LatLng(-23.5899, -46.6347);   // Perto do Ibirapuera

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('origin'),
      position: _origin,
      infoWindow: InfoWindow(title: 'Sua Localização'),
    ),
    Marker(
      markerId: const MarkerId('destination'),
      position: _dest,
      infoWindow: InfoWindow(title: 'Destino'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ),
  };

  final Set<Polyline> _polylines = {
    const Polyline(
      polylineId: PolylineId('route'),
      points: [
        _origin,
        LatLng(-23.5700, -46.6500),
        LatLng(-23.5800, -46.6400),
        _dest,
      ],
      color: Colors.indigo,
      width: 5,
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    // Controller pode ser usado para animar câmera se necessário
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Rota'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _origin,
              zoom: 13.5,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Botão flutuante para centralizar rota (opcional)
          PositionIndicator(),

          // Resumo da Viagem (BottomSheet customizado)
          Align(
            alignment: Alignment.bottomCenter,
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
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destino: ${widget.destination}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
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
                          const Text('Distância', style: TextStyle(color: Colors.grey)),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: '4.8 ',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: 'km'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tempo estimado', style: TextStyle(color: Colors.grey)),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: '12 ',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: 'min'),
                              ],
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NavigationScreen(destination: widget.destination),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'INICIAR TRAJETO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PositionIndicator extends StatelessWidget {
  const PositionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.indigo),
      ),
    );
  }
}
