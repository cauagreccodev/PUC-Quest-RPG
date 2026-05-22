import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'services/geolocation_service.dart';
import 'game/pirpg_game.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GeolocationService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIRPG',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final PIRPGGame _game;

  @override
  void initState() {
    super.initState();
    // We'll initialize the game here. 
    // Since we need geoService from context, we'll do it in didChangeDependencies
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final geoService = Provider.of<GeolocationService>(context, listen: false);
      _game = PIRPGGame(geoService: geoService);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final geoService = Provider.of<GeolocationService>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _game,
          ),
          // Top Left: Coordinates and Campus Status
          Positioned(
            top: 40,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "ESTADO DO GPS",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        geoService.currentPosition != null 
                          ? "Lat: ${geoService.currentPosition!.latitude.toStringAsFixed(6)}\nLon: ${geoService.currentPosition!.longitude.toStringAsFixed(6)}"
                          : "Buscando satélites...",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: geoService.isInsideCampus() 
                              ? [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]
                              : [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: geoService.isInsideCampus() ? Colors.greenAccent : Colors.redAccent,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              geoService.isInsideCampus() ? Icons.gps_fixed : Icons.gps_off,
                              color: geoService.isInsideCampus() ? Colors.greenAccent : Colors.redAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              geoService.isInsideCampus() ? "ÁREA DA PUC" : "FORA DA ÁREA",
                              style: TextStyle(
                                color: geoService.isInsideCampus() ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom Left: Level List (Fases)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 110, // Reduced from 120 to fix overflow
                  padding: const EdgeInsets.all(12), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "FASES DISPONÍVEIS",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Icon(Icons.map_outlined, color: Colors.white.withOpacity(0.4), size: 14),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: geoService.levels.length,
                          itemBuilder: (context, index) {
                            final level = geoService.levels[index];
                            final isUnlocked = level['unlocked'] as bool;
                            return Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(vertical: 4), // Added inner padding
                              decoration: BoxDecoration(
                                gradient: isUnlocked 
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.deepPurple.withOpacity(0.5), Colors.purpleAccent.withOpacity(0.3)],
                                    )
                                  : null,
                                color: isUnlocked ? null : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isUnlocked ? Colors.purpleAccent.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isUnlocked ? Icons.explore : Icons.lock_outline,
                                          color: isUnlocked ? Colors.purpleAccent : Colors.white24,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          level['name'],
                                          style: TextStyle(
                                            color: isUnlocked ? Colors.white : Colors.white38,
                                            fontSize: 12,
                                            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isUnlocked)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.greenAccent,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // User profile overlay
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                // Open Profile
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
