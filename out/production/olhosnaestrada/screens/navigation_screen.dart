import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class NavigationScreen extends StatefulWidget {
  final String destination;
  const NavigationScreen({super.key, required this.destination});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  double _progress = 0.0;
  Timer? _timer;
  
  // Dados simulados de manobra que seriam enviados ao ESP32
  String _currentInstruction = "Siga em frente na Av. Paulista";
  String _distanceToNext = "300m";
  IconData _directionIcon = Icons.straight;

  // Posição inicial simulada
  static const LatLng _initialPos = LatLng(-23.5617, -46.6560);

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    // Simula o progresso da viagem e sincronização com ESP32
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _timer?.cancel();
          _progress = 1.0;
        }
        
        // Simulação de mudanças de rota baseadas no progresso
        if (_progress > 0.3 && _progress < 0.7) {
          _currentInstruction = "Vire à direita na Al. Campinas";
          _distanceToNext = "120m";
          _directionIcon = Icons.turn_right;
        } else if (_progress >= 0.7 && _progress < 0.9) {
          _currentInstruction = "Prepare-se para o destino";
          _distanceToNext = "50m";
          _directionIcon = Icons.near_me;
        } else if (_progress >= 0.9) {
          _currentInstruction = "Você chegou ao seu destino!";
          _distanceToNext = "0m";
          _directionIcon = Icons.check_circle;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. GoogleMap (Ocupa todo o fundo)
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPos,
              zoom: 19,
              tilt: 60, // Inclinação para visão estilo navegação
              bearing: 30, // Rotação da câmera
            ),
            onMapCreated: (controller) {
              // Controller pode ser usado para seguir a posição
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),

          // 2. Painel de Instruções Superior (Flutuante)
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
                            backgroundColor: Colors.indigo,
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
                              "Distância: $_distanceToNext",
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Barra de Progresso / Sincronização ESP32
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
                                    style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progress,
                                  backgroundColor: Colors.indigo.withAlpha(25),
                                  color: Colors.indigo,
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

          // 3. Botão de Encerrar Navegação (Inferior)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Simula cancelamento e volta para a home
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
        ],
      ),
    );
  }
}
