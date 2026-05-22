import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import '../services/geolocation_service.dart';
import 'player.dart';

class PIRPGGame extends FlameGame with HasGameRef {
  final GeolocationService geoService;
  late Player player;
  Vector2 _lastPosition = Vector2.zero();
  
  PIRPGGame({required this.geoService});

  @override
  Future<void> onLoad() async {
    try {
      final tiledMap = await TiledComponent.load(
        'map1.tmx', 
        Vector2.all(32), // High-res tiles for better clarity
        prefix: 'assets/tiles/',
      );
      add(tiledMap);
    } catch (e) {
      debugPrint("Could not load Tiled map: $e");
    }

    player = Player(
      position: Vector2(160 * 2, 330 * 2), // Adjusted for 2x tile scale
    );
    add(player);

    camera.follow(player);
    camera.viewfinder.zoom = 2.0; // Balanced zoom for 32px tiles
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  Color backgroundColor() => const Color(0xFF0F172A); // Very dark slate (premium look)

  @override
  void update(double dt) {
    super.update(dt);
    
    if (geoService.currentPosition != null) {
      // Map Lat/Long to Game X/Y
      double lonDiff = (geoService.currentPosition!.longitude - geoService.campusCenterLon);
      double latDiff = (geoService.campusCenterLat - geoService.currentPosition!.latitude);
      
      // Scale: 0.008 deg (campus width) -> 672 pixels (336 * 2)
      double scaleX = 672 / 0.008; 
      double scaleY = 1344 / 0.008;

      Vector2 newPosition = Vector2(
        336 + (lonDiff * scaleX), // 168 * 2
        672 + (latDiff * scaleY)  // 336 * 2
      );

      // Calculate velocity for animation
      player.velocity = (newPosition - player.position) / dt;
      player.position = newPosition;

      // Update last position if needed
      _lastPosition = newPosition.clone();

      // Simple visual feedback if near a level
      for (var level in geoService.levels) {
        if (geoService.isNearLevel(level)) {
          // You are at a fase!
        }
      }
    }
  }
}
