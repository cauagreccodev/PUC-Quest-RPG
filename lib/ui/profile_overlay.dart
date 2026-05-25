import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_state_model.dart';

// ── Paleta Medieval ────────────────────────────────────────────
class MedievalColors {
  static const parchment     = Color(0xFFF2DFA0);
  static const parchmentDark = Color(0xFFD4B86A);
  static const gold          = Color(0xFFCFA84C);
  static const goldDark      = Color(0xFF8B6914);
  static const woodDark      = Color(0xFF1E0D00);
  static const woodMid       = Color(0xFF3D1C02);
  static const stone         = Color(0xFF2A2116);
  static const crimson       = Color(0xFF8B1A1A);
  static const crimsonLight  = Color(0xFFCC3333);
  static const emerald       = Color(0xFF2D5016);
  static const emeraldLight  = Color(0xFF4A7A22);
  static const textLight     = Color(0xFFF5E6C0);
  static const textMuted     = Color(0xFFB8A070);
}

class ProfileOverlay extends StatelessWidget {
  const ProfileOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStateModel>(
      builder: (context, playerState, _) {
        return Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E0D00), Color(0xFF2A1800), Color(0xFF1A0A00)],
                ),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                border: Border.all(color: MedievalColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: MedievalColors.gold.withAlpha(60),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decoração de fundo: linhas de pergaminho
                  Positioned.fill(
                    child: CustomPaint(painter: _ParchmentPatternPainter()),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                            child: Column(
                              children: [
                                _buildPhaseCard(playerState),
                                const SizedBox(height: 14),
                                _buildLivesCard(playerState),
                                const SizedBox(height: 14),
                                _buildInventoryCard(playerState),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MedievalColors.gold.withAlpha(100), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Escudo / Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF8B6914), Color(0xFF3D2800)],
              ),
              border: Border.all(color: MedievalColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: MedievalColors.gold.withAlpha(80),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.shield, color: MedievalColors.parchment, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚔  LIVRO DO HERÓI',
                  style: TextStyle(
                    color: MedievalColors.gold.withAlpha(200),
                    fontSize: 9,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aventureiro',
                  style: TextStyle(
                    color: MedievalColors.textLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: MedievalColors.textMuted, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(PlayerStateModel playerState) {
    return _MedievalCard(
      title: '⚑  MISSÃO ATUAL',
      titleColor: MedievalColors.emeraldLight,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MedievalColors.emerald.withAlpha(160),
                  MedievalColors.emerald.withAlpha(60),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: MedievalColors.emeraldLight.withAlpha(140)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.castle, color: MedievalColors.emeraldLight, size: 18),
                const SizedBox(width: 8),
                Text(
                  playerState.currentPhase,
                  style: const TextStyle(
                    color: MedievalColors.parchment,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivesCard(PlayerStateModel playerState) {
    final double hpRatio = playerState.hp / playerState.maxHp;
    return _MedievalCard(
      title: '♥  PONTOS DE VIDA',
      titleColor: MedievalColors.crimsonLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MedievalColors.crimson.withAlpha(100), width: 1),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: hpRatio.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [MedievalColors.crimson, MedievalColors.crimsonLight],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${playerState.hp} / ${playerState.maxHp}',
                    style: const TextStyle(
                      color: MedievalColors.parchment,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seu vigor em combate',
            style: TextStyle(color: MedievalColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(PlayerStateModel playerState) {
    final items = playerState.inventory;
    return _MedievalCard(
      title: '🎒  ALFORJE',
      titleColor: MedievalColors.parchmentDark,
      child: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.backpack_outlined,
                      color: MedievalColors.textMuted.withAlpha(80),
                      size: 38,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'O alforje está vazio.\nExplore as terras e colete itens!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MedievalColors.textMuted,
                        fontSize: 13,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Tooltip(
                  message: item.description,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MedievalColors.woodMid.withAlpha(200),
                          MedievalColors.woodDark.withAlpha(220),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MedievalColors.gold.withAlpha(100)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: MedievalColors.parchment,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Card medieval ──────────────────────────────────────────────
class _MedievalCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget child;

  const _MedievalCard({
    required this.title,
    required this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MedievalColors.gold.withAlpha(80), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título com ornamento
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: titleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 10,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Divider(color: MedievalColors.gold.withAlpha(50), height: 18),
          child,
        ],
      ),
    );
  }
}

// ── Padrão de pergaminho (fundo decorativo) ────────────────────
class _ParchmentPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFA84C).withAlpha(8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final borderPaint = Paint()
      ..color = const Color(0xFFCFA84C).withAlpha(30)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
