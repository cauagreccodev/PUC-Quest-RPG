import 'package:flutter/material.dart';
import '../data/questions.dart';
import 'profile_overlay.dart'; // To access MedievalColors

class QuestionOverlay extends StatefulWidget {
  final Question question;
  final VoidCallback onCorrectAnswer;
  final VoidCallback onWrongAnswer;
  final VoidCallback onClose;

  const QuestionOverlay({
    super.key,
    required this.question,
    required this.onCorrectAnswer,
    required this.onWrongAnswer,
    required this.onClose,
  });

  @override
  State<QuestionOverlay> createState() => _QuestionOverlayState();
}

class _QuestionOverlayState extends State<QuestionOverlay> {
  int? _selectedOptionIndex;
  bool _answered = false;
  bool _isCorrect = false;

  // Boss HP for this specific encounter, simulating 100 HP.
  // In a full implementation, you'd track this in state logic.
  double _bossHpRatio = 1.0; 

  void _submitAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
      _isCorrect = widget.question.isCorrect(widget.question.opcoes[index]);

      if (_isCorrect) {
        _bossHpRatio -= 1.0; // -100 HP damage (instant kill)
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_isCorrect) {
        widget.onCorrectAnswer();
      } else {
        widget.onWrongAnswer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A20), // Dark cyberpunk background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MedievalColors.emeraldLight, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(200),
                blurRadius: 20,
              )
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/ui/fase1_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Safe area if image fails to load
              Container(color: Colors.black.withAlpha(100)),

              // Top Terminal HUD
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    border: Border.all(color: Colors.green.withAlpha(150), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('_MEMÓRIA: "O NÚCLEO DA MEMÓRIA"', style: TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace')),
                      Text('_STATUS: "OPRESSIVO / ZUMBIDO CONSTANTE"', style: TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace')),
                      Text('_ZONAS: SQL (RIGIDO), NoSQL (FLUIDO)', style: TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),

              // Boss rendering (Top Center)
              Positioned(
                top: 120,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Boss HP Bar
                    SizedBox(
                      width: 150,
                      child: Column(
                        children: [
                          const Text("Giga-Cube (Boss)", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _bossHpRatio.clamp(0.0, 1.0),
                            backgroundColor: Colors.black,
                            color: Colors.red,
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Boss Image
                    Image.asset(
                      'assets/images/player/boss1.png',
                      height: 140,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.memory, color: Colors.redAccent, size: 100),
                    ),
                  ],
                ),
              ),

              // Player Mock Rendering (Bottom Center just above questions space)
              Positioned(
                bottom: 270,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/images/player/Soldier_Idle.png',
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: MedievalColors.parchment, size: 80),
                  ),
                ),
              ),

              // Bottom Question Parchment
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: MedievalColors.woodDark,
                    border: Border(top: BorderSide(color: MedievalColors.gold, width: 3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.question.pergunta,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: MedievalColors.parchment,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(widget.question.opcoes.length, (index) {
                        final option = widget.question.opcoes[index];
                        Color buttonColor = const Color(0xFF2E1A11);
                        Color borderColor = MedievalColors.gold.withAlpha(150);

                        if (_answered && _selectedOptionIndex == index) {
                          buttonColor = _isCorrect ? Colors.green.shade800 : Colors.red.shade800;
                          borderColor = _isCorrect ? Colors.green : Colors.red;
                        } else if (_answered && widget.question.isCorrect(option)) {
                          buttonColor = Colors.green.shade800.withAlpha(100);
                          borderColor = Colors.green;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () => _submitAnswer(index),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: buttonColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                option.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: MedievalColors.parchment,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      if (!_answered) 
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton(
                            onPressed: widget.onClose,
                            child: const Text("Fugir (Fechar)", style: TextStyle(color: MedievalColors.textMuted)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
