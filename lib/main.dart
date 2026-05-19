import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import 'services/auth_service.dart';
import 'services/geolocation_service.dart';
import 'game/pirpg_game.dart';
import 'models/player_state_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart'; // Tela atual com AuthWrapper e Google/Facebook
import 'ui/profile_overlay.dart';
import 'ui/pause_overlay.dart';
import 'dart:math';
import 'ui/question_overlay.dart';
import 'data/questions.dart';
import 'ui/battle_screen.dart'; // Import da tela de batalha
import 'ui/guide_dialog.dart'; // Import do guide dialog

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

class _GameScreenState extends State<GameScreen> {
  late final PIRPGGame _game;

  bool _initialized = false;
  bool _showGuide = true;

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

  void _startPhaseChallenge(String phaseId) async {
    final playerState = Provider.of<PlayerStateModel>(context, listen: false);
    if (playerState.isPhaseDefeated(phaseId)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A ameaça desta região já foi eliminada!')));
       return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BattleScreen(phaseId: phaseId),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boss Derrotado! Você recebeu uma Carta de Regeneração!')));
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
    final playerName = authService.currentUser?.name ?? 'Aventureiro';

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

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),

          // HUD - Top Left
          Positioned(
            top: 40,
            left: 16,
            child: _MedievalBadge(
              icon: Icons.map_rounded,
              label: locationName,
              color: locationColor,
            ),
          ),

          // HUD - Top Center
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TavernButton(onTap: _openPause),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BattleScreen(phaseId: 'test_phase'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.amber, width: 2),
                    ),
                    child: const Text('TESTAR BATALHA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // HUD - Top Right
          Positioned(
            top: 40,
            right: 16,
            child: _CompactProfile(
              onTap: _openProfile,
              hp: playerState.hp,
              maxHp: playerState.maxHp,
              playerName: playerName,
            ),
          ),

          // HUD - Bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _HorizontalMapScroll(levels: geoService.levels),
          ),

          // Explore Button Overlay when near a level
          if (currentLevel != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: playerState.isPhaseDefeated(currentLevel['id'])
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(200),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MedievalColors.emeraldLight, width: 2),
                      ),
                      child: const Text('FASE CONCLUÍDA', style: TextStyle(color: MedievalColors.parchment, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _startPhaseChallenge(currentLevel!['id']),
                      icon: const Icon(Icons.explore, color: MedievalColors.parchment),
                      label: Text('EXPLORAR: ${currentLevel['name']}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: MedievalColors.parchment,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: MedievalColors.gold, width: 2),
                        ),
                        elevation: 10,
                      ),
                    ),
              ),
            ),
            
          // Guide Dialog
          if (_showGuide)
            Positioned(
              bottom: 90,
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

class _CompactProfile extends StatelessWidget {
  final VoidCallback onTap;
  final int hp;
  final int maxHp;
  final String playerName;

  const _CompactProfile({required this.onTap, required this.hp, required this.maxHp, required this.playerName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$hp / $maxHp HP', style: const TextStyle(color: MedievalColors.crimsonLight, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(playerName.toUpperCase(), style: const TextStyle(color: MedievalColors.gold, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MedievalColors.gold, width: 1.5),
              color: const Color(0xFF2A1500),
            ),
            child: const Icon(Icons.person, color: MedievalColors.parchment, size: 24),

          ),
        ],
      ),
    );
  }
}

class _HorizontalMapScroll extends StatelessWidget {
  final List<dynamic> levels;
  const _HorizontalMapScroll({required this.levels});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MedievalColors.gold.withAlpha(50)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isUnlocked = level['unlocked'] as bool;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              level['name'],
              style: TextStyle(
                color: isUnlocked ? MedievalColors.parchment : MedievalColors.textMuted.withAlpha(100),
                fontSize: 11,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}

