import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/geolocation_service.dart';
import '../models/player_state_model.dart';
import '../services/auth_service.dart';

import 'player.dart';

import 'dart:math' as math;

class PIRPGGame extends FlameGame {
  final GeolocationService geoService;
  final PlayerStateModel playerState;
  final AuthService authService;
  late Player player;

  double _lastLon = 0;
  double _lastLat = 0;
  double _velocityDecay = 0;

  PIRPGGame({required this.geoService, required this.playerState, required this.authService});

  @override
  Future<void> onLoad() async {
    // Agora o Google Maps fica no fundo, então o Flame não carrega o mapa Tiled
    player = Player(
      position: Vector2.zero(), // O jogador fica na origem
    );
    player.priority = 10;
    
    world.add(player);

    camera.viewfinder.zoom = 3.0; // Aumentado de 2.0 para 3.0 para ver melhor o herói
    camera.follow(player);

    await playerState.loadGame();
  }

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void update(double dt) {
    super.update(dt);
    
    if (geoService.currentPosition != null) {
      double currentLon = geoService.currentPosition!.longitude;
      double currentLat = geoService.currentPosition!.latitude;

      if (_lastLon != 0 && _lastLat != 0) {
        double lonDiff = currentLon - _lastLon;
        double latDiff = _lastLat - currentLat;
        
        // Se houver uma mudança significativa de posição, inicia a animação de caminhada
        if (lonDiff.abs() > 0.000005 || latDiff.abs() > 0.000005) {
            player.velocity = Vector2(lonDiff, latDiff).normalized() * 50;
            _velocityDecay = 1.0; // Sincronizado com os 1000ms do main.dart
        }
      }
      
      _lastLon = currentLon;
      _lastLat = currentLat;
      
      if (_velocityDecay > 0) {
        _velocityDecay -= dt;
        if (_velocityDecay <= 0) {
            player.velocity = Vector2.zero();
        }
      }
      
      for (var level in geoService.levels) {
        if (geoService.isNearLevel(level)) {
          playerState.setPhase(level['name'] as String);
        }
      }
    }
  }
}
