import 'dart:async';
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
      'id': 'fase_ceatec',
      'name': 'CEATEC',
      'lat': -22.8335,
      'lon': -47.0520,
      'radius': 50,
      'unlocked': false,
    },
    {
      'id': 'fase_cea',
      'name': 'CEA',
      'lat': -22.8315,
      'lon': -47.0505,
      'radius': 50,
      'unlocked': false,
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

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
