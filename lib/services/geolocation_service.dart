import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GeolocationService extends ChangeNotifier {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  Position? get currentPosition => _currentPosition;

  // PUC Campus I approximate center and radius in meters
  final double campusCenterLat = -22.83294988540271;
  final double campusCenterLon = -47.05144235640162;
  final double campusRadiusMeters = 800;

  // Example Level Locations (Fases)
  final List<Map<String, dynamic>> levels = [
    {
      'id': 'estagio_1',
      'name': 'Praça de Alimentação',
      'lat': -22.83220,
      'lon': -47.05100,
      'radius': 40,
      'unlocked': false,
      'icon': Icons.restaurant,
      'estagio': 1,
    },
    {
      'id': 'estagio_2',
      'name': 'Biblioteca (Redes)',
      'lat': -22.83280,
      'lon': -47.05150,
      'radius': 40,
      'unlocked': false,
      'icon': Icons.menu_book,
      'estagio': 2,
    },
    {
      'id': 'estagio_3',
      'name': 'H14 (A02)',
      'lat': -22.83350,
      'lon': -47.05210,
      'radius': 40,
      'unlocked': false,
      'icon': Icons.calculate,
      'estagio': 3,
    },
    {
      'id': 'estagio_4',
      'name': 'Entrada do H15',
      'lat': -22.83390,
      'lon': -47.05240,
      'radius': 40,
      'unlocked': false,
      'icon': Icons.meeting_room,
      'estagio': 4,
    },
    {
      'id': 'estagio_5',
      'name': 'H15 (Jogos Digitais)',
      'lat': -22.83430,
      'lon': -47.05260,
      'radius': 40,
      'unlocked': false,
      'icon': Icons.sports_esports,
      'estagio': 5,
    },
  ];

  GeolocationService() {
    _init();
  }

  bool isInsideCampus() {
    if (_currentPosition == null) return false;
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      campusCenterLat,
      campusCenterLon,
    );
    return distance <= campusRadiusMeters;
  }

  bool isNearLevel(Map<String, dynamic> level) {
    if (_currentPosition == null) return false;
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      level['lat'],
      level['lon'],
    );
    return distance <= level['radius'];
  }

  Future<void> _init() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      // Check for level unlocks
      for (var level in levels) {
        if (isNearLevel(level)) {
          level['unlocked'] = true;
        }
      }
      notifyListeners();
    });
  }

  void setFakeLocation(double lat, double lon) {
    _currentPosition = Position.fromMap({
      'latitude': lat,
      'longitude': lon,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'accuracy': 10.0,
      'altitude': 0.0,
      'heading': 0.0,
      'speed': 0.0,
      'speed_accuracy': 0.0,
      'altitude_accuracy': 0.0,
      'heading_accuracy': 0.0,
    });
    
    // Check for level unlocks
    for (var level in levels) {
      if (isNearLevel(level)) {
        level['unlocked'] = true;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
