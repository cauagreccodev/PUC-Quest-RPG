import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import '../models/player_state_model.dart';
import '../services/auth_service.dart';
import 'profile_overlay.dart' show MedievalColors;

class PauseOverlay extends StatefulWidget {
  final FlameGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withAlpha(160),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A1800), Color(0xFF1A0A00), Color(0xFF160800)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: MedievalColors.gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: MedievalColors.gold.withAlpha(50),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(200),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Padrão de linhas de pergaminho
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CustomPaint(painter: _ScrollPatternPainter()),
                      ),
                    ),
                    // Ornamentos de canto
                    _CornerOrnament(alignment: Alignment.topLeft),
                    _CornerOrnament(alignment: Alignment.topRight, flipX: true),
                    _CornerOrnament(alignment: Alignment.bottomLeft, flipY: true),
                    _CornerOrnament(alignment: Alignment.bottomRight, flipX: true, flipY: true),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título medieval
                          _buildTitle(),
                          const SizedBox(height: 24),
                          _buildDivider(),
                          const SizedBox(height: 22),

                          // Botão Salvar
                          _MedievalButton(
                            label: 'Registrar Progresso',
                            leftIcon: '📜',
                            rightWidget: const Icon(Icons.save_rounded, color: MedievalColors.parchmentDark, size: 18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D5016), Color(0xFF3A6620)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderColor: MedievalColors.emeraldLight,
                            onTap: () async {
                              final playerState = Provider.of<PlayerStateModel>(context, listen: false);
                              final authService = Provider.of<AuthService>(context, listen: false);
                              await playerState.saveGame();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Text('📜', style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 10),
                                      Text(
                                        'Progresso registrado nos anais!',
                                        style: TextStyle(color: MedievalColors.parchment),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: MedievalColors.emerald,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: const BorderSide(color: MedievalColors.emeraldLight),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Botão Continuar
                          _MedievalButton(
                            label: 'Continuar Jornada',
                            leftIcon: '⚔',
                            rightWidget: const Icon(Icons.play_arrow_rounded, color: MedievalColors.parchmentDark, size: 20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7A5800), Color(0xFFCFA84C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderColor: MedievalColors.gold,
                            onTap: () {
                              widget.game.resumeEngine();
                              Navigator.of(context).pop();
                            },
                          ),
                          const SizedBox(height: 12),

                          // Botão Sair (Logout)
                          _MedievalButton(
                            label: 'Sair da Conta',
                            leftIcon: '🗝️',
                            rightWidget: const Icon(Icons.exit_to_app_rounded, color: MedievalColors.parchmentDark, size: 18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A3520), Color(0xFF2A1B0A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderColor: MedievalColors.goldDark,
                            onTap: () async {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              await authService.logout();
                              if (!context.mounted) return;
                              Navigator.of(context).pop(); // Fecha o pause
                            },
                          ),
                          const SizedBox(height: 12),

                          // Botão Sair (Fechar App)
                          _MedievalButton(
                            label: 'Fechar Pergaminho',
                            leftIcon: '🏚',
                            rightWidget: const Icon(Icons.close_rounded, color: MedievalColors.parchmentDark, size: 18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5A0A0A), Color(0xFF8B1A1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderColor: MedievalColors.crimsonLight,
                            onTap: () {
                              SystemNavigator.pop();
                            },
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
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text('⚔ ⚔ ⚔', style: TextStyle(fontSize: 14, letterSpacing: 6)),
        const SizedBox(height: 8),
        const Text(
          'DESCANSO\nNA TAVERNA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MedievalColors.parchment,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'O que deseja fazer, aventureiro?',
          style: TextStyle(
            color: MedievalColors.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: MedievalColors.gold.withAlpha(80))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.shield, color: MedievalColors.gold.withAlpha(160), size: 16),
        ),
        Expanded(child: Container(height: 1, color: MedievalColors.gold.withAlpha(80))),
      ],
    );
  }
}

// ── Botão medieval ─────────────────────────────────────────────
class _MedievalButton extends StatefulWidget {
  final String label;
  final String leftIcon;
  final Widget rightWidget;
  final Gradient gradient;
  final Color borderColor;
  final VoidCallback onTap;

  const _MedievalButton({
    required this.label,
    required this.leftIcon,
    required this.rightWidget,
    required this.gradient,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_MedievalButton> createState() => _MedievalButtonState();
}

class _MedievalButtonState extends State<_MedievalButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: widget.borderColor.withAlpha(180)),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(widget.leftIcon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: MedievalColors.parchment,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              widget.rightWidget,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ornamento de canto ─────────────────────────────────────────
class _CornerOrnament extends StatelessWidget {
  final AlignmentGeometry alignment;
  final bool flipX;
  final bool flipY;

  const _CornerOrnament({
    required this.alignment,
    this.flipX = false,
    this.flipY = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: flipY ? null : 6,
      bottom: flipY ? 6 : null,
      left: flipX ? null : 6,
      right: flipX ? 6 : null,
      child: Transform.scale(
        scaleX: flipX ? -1 : 1,
        scaleY: flipY ? -1 : 1,
        child: const Text(
          '✦',
          style: TextStyle(
            color: MedievalColors.goldDark,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Padrão de pergaminho ───────────────────────────────────────
class _ScrollPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFA84C).withAlpha(10)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
