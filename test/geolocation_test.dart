import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  test('Testar validação de raio de geolocalização', () {
    final double campusCenterLat = -22.83294988540271;
    final double campusCenterLon = -47.05144235640162;
    final double campusRadiusMeters = 800;

    final List<Map<String, dynamic>> levels = [
      {
        'id': 'estagio_1',
        'name': 'Praça de Alimentação',
        'lat': -22.83220,
        'lon': -47.05100,
        'radius': 40,
      },
      {
        'id': 'estagio_2',
        'name': 'Biblioteca (Redes)',
        'lat': -22.83280,
        'lon': -47.05150,
        'radius': 40,
      },
      {
        'id': 'estagio_3',
        'name': 'H14 (A02)',
        'lat': -22.83350,
        'lon': -47.05210,
        'radius': 40,
      },
      {
        'id': 'estagio_4',
        'name': 'Entrada do H15',
        'lat': -22.83390,
        'lon': -47.05240,
        'radius': 40,
      },
      {
        'id': 'estagio_5',
        'name': 'H15 (Jogos Digitais)',
        'lat': -22.83430,
        'lon': -47.05260,
        'radius': 40,
      },
    ];

    print('--- TESTANDO DISTÂNCIAS DO CENTRO DO CAMPUS ---');
    for (var level in levels) {
      double distanceToCampusCenter = Geolocator.distanceBetween(
        campusCenterLat,
        campusCenterLon,
        level['lat'],
        level['lon'],
      );
      print('Estágio: ${level['name']}');
      print('Distância do centro do campus: ${distanceToCampusCenter.toStringAsFixed(2)} metros');
      print('Está dentro do campus? ${distanceToCampusCenter <= campusRadiusMeters}\n');
      
      expect(distanceToCampusCenter <= campusRadiusMeters, true, reason: '${level['name']} deveria estar dentro do campus.');
    }

    print('--- TESTANDO VALIDAÇÃO DE RAIO (40m) DA PRAÇA DE ALIMENTAÇÃO ---');
    double test1Lat = -22.83220;
    double test1Lon = -47.05100;
    double dist1 = Geolocator.distanceBetween(test1Lat, test1Lon, levels[0]['lat'], levels[0]['lon']);
    print('Teste 1 (Exatamente na Praça): Distância: ${dist1.toStringAsFixed(2)}m');
    expect(dist1 <= levels[0]['radius'], true);

    double test2Lat = -22.83220 + 0.00027; // ~30m
    double test2Lon = -47.05100;
    double dist2 = Geolocator.distanceBetween(test2Lat, test2Lon, levels[0]['lat'], levels[0]['lon']);
    print('Teste 2 (30m de distância): Distância: ${dist2.toStringAsFixed(2)}m');
    expect(dist2 <= levels[0]['radius'], true);

    double test3Lat = -22.83220 + 0.00045; // ~50m
    double test3Lon = -47.05100;
    double dist3 = Geolocator.distanceBetween(test3Lat, test3Lon, levels[0]['lat'], levels[0]['lon']);
    print('Teste 3 (50m de distância): Distância: ${dist3.toStringAsFixed(2)}m');
    expect(dist3 <= levels[0]['radius'], false);
  });
}
