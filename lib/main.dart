import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'services/auth_service.dart';
import 'services/geolocation_service.dart';
import 'game/pirpg_game.dart';
import 'models/player_state_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ui/login_screen.dart'; // Tela atual com AuthWrapper e Google/Facebook
import 'ui/profile_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/battle_screen.dart'; // Import da tela de batalha
import 'ui/guide_dialog.dart'; // Import do guide dialog
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização do Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GeolocationService()),
        ChangeNotifierProvider(create: (_) => PlayerStateModel()),
      ],

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.brown,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF4F4F4F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFF0E68C), width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),

    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final PIRPGGame _game;
  late final MapController _mapController;

  bool _initialized = false;
  bool _showGuide = true;

  double? _lastAnimatedLat;
  double? _lastAnimatedLon;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    try {
      final camera = _mapController.camera;
      final latTween = Tween<double>(
          begin: camera.center.latitude,
          end: destLocation.latitude);
      final lngTween = Tween<double>(
          begin: camera.center.longitude,
          end: destLocation.longitude);
      final zoomTween = Tween<double>(
          begin: camera.zoom, end: destZoom);

      final controller = AnimationController(
          duration: const Duration(milliseconds: 800), vsync: this);
      final animation = CurvedAnimation(
          parent: controller, curve: Curves.fastOutSlowIn);

      controller.addListener(() {
        try {
          _mapController.move(
              LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
              zoomTween.evaluate(animation));
        } catch (_) {}
      });

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          controller.dispose();
        }
      });

      controller.forward();
    } catch (_) {
      try {
        _mapController.move(destLocation, destZoom);
      } catch (_) {}
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final geoService = Provider.of<GeolocationService>(context, listen: false);
      final playerState = Provider.of<PlayerStateModel>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      _game = PIRPGGame(geoService: geoService, playerState: playerState, authService: authService);

      _initialized = true;
    }
  }

  void _openProfile() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar Perfil',
      barrierColor: Colors.black.withAlpha(120),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const ProfileOverlay(),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  void _openPause() {
    _game.pauseEngine();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Pause',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => PauseOverlay(game: _game),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  void _startPhaseChallenge(String phaseId, int estagio) async {
    final playerState = Provider.of<PlayerStateModel>(context, listen: false);
    
    if (!playerState.hasKeyForEstagio(estagio)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('A aura deste local é muito forte. Adquira mais experiência e conclua o estágio anterior para avançar!'),
        backgroundColor: Colors.red[900],
      ));
      return;
    }

    if (playerState.isPhaseDefeated(phaseId)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A ameaça desta região já foi eliminada!')));
       return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BattleScreen(phaseId: phaseId, estagio: estagio),
      ),
    );

    if (result == true) {
      if (!context.mounted) return;
      final pState = Provider.of<PlayerStateModel>(context, listen: false);
      pState.markPhaseDefeated(phaseId);
      pState.addItem(GameItem(
        id: 'carta_cura_$phaseId',
        name: 'Carta de Regeneração',
        description: 'Recupera 75 HP instantaneamente.',
        icon: '❤️',
      ));
      
      // Concede a próxima chave
      pState.grantNextKey(estagio);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boss Derrotado! Você recebeu recompensas e talvez uma nova chave!')));
    } else if (result == false) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você fugiu ou foi derrotado... Tente novamente!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final geoService = Provider.of<GeolocationService>(context);
    final playerState = Provider.of<PlayerStateModel>(context);
    final authService = Provider.of<AuthService>(context);
    final playerName = authService.currentUser?.displayName ?? 'Aventureiro';

    final locationName = geoService.isInsideCampus() ? 'REINO DA PUC' : 'TERRAS SELVAGENS';
    final locationColor = geoService.isInsideCampus() ? MedievalColors.emeraldLight : MedievalColors.crimsonLight;

    Map<String, dynamic>? currentLevel;
    for (var level in geoService.levels) {
      if (geoService.isNearLevel(level)) {
        currentLevel = level;
        break;
      }
    }

    final healCard = playerState.inventory.where((item) => item.name == 'Carta de Regeneração').firstOrNull;

    if (geoService.currentPosition != null) {
      final curLat = geoService.currentPosition!.latitude;
      final curLon = geoService.currentPosition!.longitude;
      if (_lastAnimatedLat != curLat || _lastAnimatedLon != curLon) {
        _lastAnimatedLat = curLat;
        _lastAnimatedLon = curLon;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animatedMapMove(LatLng(curLat, curLon), 18.0);
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                geoService.currentPosition?.latitude ?? geoService.campusCenterLat,
                geoService.currentPosition?.longitude ?? geoService.campusCenterLon,
              ),
              initialZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pirpg',
              ),
              MarkerLayer(
                markers: geoService.levels.map((level) {
                  final isUnlocked = (level['unlocked'] as bool) && 
                                     playerState.hasKeyForEstagio(level['estagio']);
                  return Marker(
                    point: LatLng(level['lat'], level['lon']),
                    width: 80,
                    height: 80,
                    child: _MedievalMapMarker(
                      name: level['name'],
                      isUnlocked: isUnlocked,
                      onTap: () {
                        final distance = geoService.currentPosition != null
                            ? Geolocator.distanceBetween(
                                geoService.currentPosition!.latitude,
                                geoService.currentPosition!.longitude,
                                level['lat'],
                                level['lon'],
                              ).toStringAsFixed(0)
                            : 'desconhecida';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${level['name']}: Aventura está a $distance metros de distância!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: const Color(0xFF2A1500),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          GameWidget(game: _game),

          Positioned(
            top: 40,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MedievalBadge(
                  icon: Icons.map_rounded,
                  label: locationName,
                  color: locationColor,
                ),

                const SizedBox(height: 12),
      
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.amber, width: 2),
                        ),
                        title: const Text(
                          'Escolher Estágio',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.looks_one,
                                color: Colors.white,
                              ),
                              title: const Text(
                                'Estágio 1',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BattleScreen(
                                      phaseId: 'test_phase',
                                      estagio: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.looks_two,
                                color: Colors.white,
                              ),
                              title: const Text(
                                'Estágio 2',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BattleScreen(
                                      phaseId: 'test_phase',
                                      estagio: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.looks_3,
                                color: Colors.white,
                              ),
                              title: const Text(
                                'Estágio 3',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BattleScreen(
                                      phaseId: 'test_phase',
                                      estagio: 3,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.looks_4,
                                color: Colors.white,
                              ),
                              title: const Text(
                                'Estágio 4',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BattleScreen(
                                      phaseId: 'test_phase',
                                      estagio: 4,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.looks_5,
                                color: Colors.white,
                              ),
                              title: const Text(
                                'Estágio 5',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BattleScreen(
                                      phaseId: 'test_phase',
                                      estagio: 5,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.amber, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ), // Deixa o botão mais compacto
                  ),
                  child: const Text(
                    'TESTAR BATALHA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                        title: const Text(
                          'Fake GPS - Teleporte',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: geoService.levels.length,
                            itemBuilder: (context, index) {
                              final level = geoService.levels[index];
                              return ListTile(
                                leading: Icon(
                                  level['icon'] as IconData? ?? Icons.location_on,
                                  color: Colors.white,
                                ),
                                title: Text(
                                  level['name'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  geoService.setFakeLocation(level['lat'], level['lon']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Teleportado para ${level['name']}!'),
                                      backgroundColor: Colors.blue[900],
                                    )
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.blueAccent, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'FAKE GPS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // HUD - Top Right
          Positioned(
            top: 40,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TavernButton(onTap: _openPause),

                    const SizedBox(width: 12),

                    _ProfileBadge(
                      onTap: _openProfile,
                      hp: playerState.hp,
                      maxHp: playerState.maxHp,
                    )   
                  ],
                ),
              ],
            ),
          ),
           
          // Guide Dialog
          if (_showGuide)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: DialogBox(
                characterName: 'Mestre Ancião',
                messages: [
                  'Saudações, $playerName!',
                  'Sua jornada começa agora. Explore os locais no mapa e enfrente os desafios das trevas!',
                ],
                onFinished: () {
                  setState(() {
                    _showGuide = false;
                  });
                },
              ),
            )
          else 
            // HUD - Bottom
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _HorizontalMapScroll(levels: geoService.levels, playerState: playerState),
            ),

          // Explore Button Overlay when near a level
          if (currentLevel != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _startPhaseChallenge(currentLevel!['id'], currentLevel['estagio']),
                  icon: const Icon(
                    Icons.explore,
                    color: MedievalColors.parchment,
                  ),
                  label: Text(playerState.isPhaseDefeated(currentLevel['id']) 
                      ? 'REJOGAR: ${currentLevel['name']}' 
                      : 'EXPLORAR: ${currentLevel['name']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: playerState.isPhaseDefeated(currentLevel['id']) 
                        ? Colors.green.withAlpha(180) 
                        : const Color(0xFF8B4513),
                    foregroundColor: MedievalColors.parchment,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: playerState.isPhaseDefeated(currentLevel['id']) 
                            ? MedievalColors.emeraldLight 
                            : MedievalColors.gold,
                        width: 2,
                      ),
                    ),
                    elevation: 10,
                  ),
                ),
              ),
            ),

          // Heal Card FAB in bottom left
          if (healCard != null)
            Positioned(
              bottom: 100,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  if (playerState.hp >= playerState.maxHp) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seu HP já está cheio!')));
                    return;
                  }
                  playerState.heal(75);
                  playerState.removeItem(healCard.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Curado em 75 HP!')));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: MedievalColors.crimson,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MedievalColors.gold, width: 2),
                    boxShadow: [BoxShadow(color: Colors.green.withAlpha(150), blurRadius: 10)],
                  ),
                  child: Column(
                    children: const [
                      Text('❤️', style: TextStyle(fontSize: 24)),
                      Text('USAR', style: TextStyle(color: MedievalColors.parchment, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Components ─────────────────────────────────────────────────────────────

class _MedievalBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MedievalBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC1A0A00),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(150), width: 1.5),
        boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: MedievalColors.parchment,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TavernButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TavernButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFF5A3A00), Color(0xFF2A1500)]),
          border: Border.all(color: MedievalColors.gold, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 10)],
        ),
        child: const Center(child: Text('⚔', style: TextStyle(fontSize: 18))),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final VoidCallback onTap;
  final int hp;
  final int maxHp;

  const _ProfileBadge({
    required this.onTap,
    required this.hp,
    required this.maxHp,
  });

  @override
  Widget build(BuildContext context) {
    final double healthPercentage = (maxHp > 0)
        ? (hp / maxHp).clamp(0.0, 1.0)
        : 0.0;
    const double medalSize = 48.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: medalSize,
            height: medalSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MedievalColors.gold, width: 2.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 10),
              ],
            ),
          ),

          SizedBox(
            width: medalSize - 3.0,
            height: medalSize - 3.0,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(120 / 360),
              child: CircularProgressIndicator(
                value: healthPercentage,
                strokeWidth: 4.0,
                color: const Color(0xFFA11010),
                backgroundColor: const Color(0xFF2A0808),
              ),
            ),
          ),

          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF5A3A00), Color(0xFF2A1500)],
              ),
            ),
            child: const Icon(
              Icons.person,
              color: MedievalColors.parchment,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalMapScroll extends StatelessWidget {
  final List<dynamic> levels;
  final PlayerStateModel playerState;
  const _HorizontalMapScroll({required this.levels, required this.playerState});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: MedievalColors.woodDark.withAlpha(220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedievalColors.gold, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final isUnlocked = (level['unlocked'] as bool) && 
                               playerState.hasKeyForEstagio(level['estagio']);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: index < levels.length - 1
                    ? Border(
                        right: BorderSide(
                          color: MedievalColors.goldDark.withAlpha(100),
                          width: 1.5,
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked ? Icons.outlined_flag : Icons.lock_outline,
                    size: 16,
                    color: isUnlocked
                        ? MedievalColors.emeraldLight
                        : MedievalColors.textMuted.withAlpha(150),
                  ),

                  const SizedBox(width: 6),

                  Text(
                    level['name'].toUpperCase(),
                    style: TextStyle(
                      color: isUnlocked
                          ? MedievalColors.parchment
                          : MedievalColors.textMuted.withAlpha(150),
                      fontSize: 11,
                      fontWeight: isUnlocked
                          ? FontWeight.bold
                          : FontWeight.normal,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MedievalMapMarker extends StatelessWidget {
  final String name;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _MedievalMapMarker({
    required this.name,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nome do local estilizado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xDD1A0A00),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isUnlocked ? MedievalColors.gold : Colors.grey[700]!,
                width: 1,
              ),
            ),
            child: Text(
              name.toUpperCase(),
              style: TextStyle(
                color: isUnlocked ? MedievalColors.parchment : Colors.grey[400],
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Marcador interativo com efeito de pulso
          Stack(
            alignment: Alignment.center,
            children: [
              if (isUnlocked)
                const _PulsingRing(color: MedievalColors.gold),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A0A00),
                  border: Border.all(
                    color: isUnlocked ? MedievalColors.gold : Colors.grey[700]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUnlocked ? MedievalColors.gold : Colors.black).withAlpha(120),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isUnlocked ? Icons.fort : Icons.lock_outline_rounded,
                  color: isUnlocked ? MedievalColors.gold : Colors.grey[600],
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  final Color color;
  const _PulsingRing({required this.color});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 38 * _controller.value,
          height: 38 * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(1.0 - _controller.value),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}

