import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RouteInstruction {
  final String text;
  final LatLng location;
  final double distanceMeters;

  const RouteInstruction({
    required this.text,
    required this.location,
    required this.distanceMeters,
  });
}

class RouteResult {
  final List<LatLng> points;
  final List<RouteInstruction> instructions;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.instructions,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RouteService {
  // ⚠️ SUBSTITUA ABAIXO PELA SUA CHAVE DE API DO GOOGLE CLOUD
  static const String _apiKey = 'AIzaSyBqIhbT-hOjm-Mj_kSM9UcU6byEQv2lZ-w';

  static Future<RouteResult> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    String language = 'pt-BR',
  }) async {
    // URL da Google Directions API
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving' // Modo carro (não há "motorcycle" oficial)
          '&departure_time=now' // Ativa o cálculo com trânsito em tempo real
          '&traffic_model=best_guess'
          '&language=$language'
          '&key=$_apiKey',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Serviço de rotas indisponível (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    print('STATUS: ${json['status']}');
    print('ERRO: ${json['error_message']}');

    // Verifica se a API retornou erro (ex: chave inválida)
    final status = json['status'] as String?;
    if (status != 'OK') {
      throw Exception('Erro na API do Google: $status');
    }

    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw Exception('Nenhuma rota encontrada');
    }

    final route = routes.first as Map<String, dynamic>;

    // 1. Decodificar a Polyline (o Google manda codificada)
    final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>;
    final encodedPoints = overviewPolyline['points'] as String;

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPoints);

    final points = decodedPoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    // 2. Extrair Instruções (passo a passo)
    final instructions = <RouteInstruction>[];
    final legs = route['legs'] as List<dynamic>? ?? const [];

    for (final leg in legs) {
      final steps = (leg as Map<String, dynamic>)['steps'] as List<dynamic>? ?? const [];
      for (final step in steps) {
        final stepMap = step as Map<String, dynamic>;
        final startLocation = stepMap['start_location'] as Map<String, dynamic>;

        // Texto da instrução (o Google manda com HTML, precisamos limpar)
        String instructionText = stepMap['html_instructions'] as String? ?? 'Siga em frente';
        instructionText = instructionText.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove tags HTML

        instructions.add(
          RouteInstruction(
            text: instructionText,
            location: LatLng(
              (startLocation['lat'] as num).toDouble(),
              (startLocation['lng'] as num).toDouble(),
            ),
            distanceMeters: (stepMap['distance']['value'] as num? ?? 0).toDouble(),
          ),
        );
      }
    }

    // 3. Extrair Distância e Tempo (com trânsito)
    final leg = legs.first as Map<String, dynamic>;
    final distanceMeters = (leg['distance']['value'] as num).toDouble();

    // Tenta pegar o tempo com trânsito, se não existir usa o normal
    final durationSeconds = (leg['duration_in_traffic']?['value'] as num? ??
        leg['duration']['value'] as num).toDouble();

    return RouteResult(
      points: points,
      instructions: instructions,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }
}
