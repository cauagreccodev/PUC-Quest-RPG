import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/player_state_model.dart';
import '../database/firestore_service.dart';
import '../main.dart' as main_app;
import '../models/audio_settings_model.dart';
import 'pause_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssetPaths {
  static String battleBackground(int estagio) =>
      'assets/images/stages/stage$estagio/battle.png';
  static String battleBackground2(int estagio) =>
      'assets/images/stages/stage$estagio/battle2.png';
  static const String playerSprite = 'assets/images/player/Soldier_Idle.png';
}

class AssetGenerators {
  static Widget generateHudFrame({
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class BattleScreen extends StatefulWidget {
  final String? phaseId;
  final int estagio;

  const BattleScreen({super.key, this.phaseId, this.estagio = 1});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final Random _rng = Random();

  // Estado da batalha
  int playerHp = 100;
  int playerMaxHp = 100;
  int enemyHp = 100;
  int enemyMaxHp = 100;
  bool isPlayerTurn = true;
  String battleLog = 'Acessando dados do alvo...';
  bool isAnimating = false;
  int playerLevel = 50;
  int skillCooldown = 0;
  bool _didInitializeFromPlayerState = false;
  bool _iraBoostActive = false;

  // Variáveis do modo Quiz
  bool isQuizMode = false;
  bool isLoadingQuizzes = true;
  bool isBackpackMode = false;
  String? hoveredItemDescription;
  Map<String, dynamic>? currentQuiz;
  List<Map<String, dynamic>> _quizzes = [];
  final Set<String> _usedQuestions = {};
  final FirestoreService _dbService = FirestoreService();

  String bossName = 'Inimigo Desconhecido';
  final AudioPlayer _bossAudioPlayer = AudioPlayer();

  // Animação
  late AnimationController _damageController;
  late Animation<Offset> _damageAnimation;
  bool _enemyHitFlash = false;

  void _playBossMusic() async {
    await _bossAudioPlayer.setReleaseMode(ReleaseMode.loop);

    // Configuração inicial do volume
    final audioSettings = Provider.of<AudioSettingsModel>(
      context,
      listen: false,
    );
    double baseVolume = audioSettings.effectiveMusicVolume;
    double bossVolume = baseVolume > 0
        ? (baseVolume + 0.1).clamp(0.0, 1.0)
        : 0.0;
    await _bossAudioPlayer.setVolume(bossVolume);

    // Para a música principal (solução mais segura para Web)
    await main_app.player.stop();

    String fileName = '';
    switch (widget.estagio) {
      case 1:
        fileName = 'boss1/Number One - Bankai.mp3';
        break;
      case 2:
        fileName = 'boss2/Last Surprise.mp3';
        break;
      case 3:
        fileName = 'boss3/Clavar La Espada.mp3';
        break;
      case 4:
        fileName = 'boss4/Bleach OST - Vasto Lorde.mp3';
        break;
      case 5:
        fileName = 'boss5/Devil May Cry 3 - Devils Never Cry.mp3';
        break;
      default:
        fileName = 'boss1/Number One - Bankai.mp3';
    }

    await _bossAudioPlayer.play(AssetSource('audio/$fileName'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Atualiza o volume do boss em tempo real quando o usuário altera nas configurações
    final audioSettings = Provider.of<AudioSettingsModel>(context);
    double baseVolume = audioSettings.effectiveMusicVolume;
    double bossVolume = baseVolume > 0
        ? (baseVolume + 0.1).clamp(0.0, 1.0)
        : 0.0;
    _bossAudioPlayer.setVolume(bossVolume);

    if (_didInitializeFromPlayerState) return;

    final playerState = Provider.of<PlayerStateModel>(context, listen: false);
    playerMaxHp = playerState.maxHp;
    playerHp = playerState.hp.clamp(1, playerMaxHp);
    _didInitializeFromPlayerState = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playBossMusic();
    _loadQuizzes();
    _damageController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _damageAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(6, -8),
        ).animate(
          CurvedAnimation(parent: _damageController, curve: Curves.easeOut),
        );

    _damageController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool _wasPlayingBeforePause = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_bossAudioPlayer.state == PlayerState.playing) {
        _wasPlayingBeforePause = true;
        _bossAudioPlayer.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPlayingBeforePause) {
        _bossAudioPlayer.resume();
        _wasPlayingBeforePause = false;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Pausa e descarta para evitar vazamento de áudio (sobreposição)
    _bossAudioPlayer
        .stop()
        .then((_) {
          _bossAudioPlayer.dispose();
        })
        .catchError((_) {
          _bossAudioPlayer.dispose();
        });

    // Reinicia a música principal
    main_app.tocarMusica();

    _damageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    try {
      // Garante que o banco tem os quizzes caso a coleção esteja vazia
      await _dbService.seedDatabase();

      final allQuizzes = await _dbService.getAllQuizzes();
      // Filtra pelo estágio requisitado
      final quizzes = allQuizzes.where((q) {
        return q['estagio'] == widget.estagio ||
            q['estagio'] == widget.estagio.toString();
      }).toList();

      final fetchedBossName = await _dbService.getBossNameByEstagio(
        widget.estagio,
      );

      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          bossName = fetchedBossName;
          final pName = FirebaseAuth.instance.currentUser?.displayName?.toUpperCase() ?? 'VISITANTE';
          battleLog = '$bossName apareceu! Vá, $pName!';
          isLoadingQuizzes = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar quizzes: $e');
      if (mounted) {
        setState(() {
          isLoadingQuizzes = false;
        });
      }
    }
  }

  void _playerAttack() {
    if (isAnimating || !isPlayerTurn || isLoadingQuizzes) return;

    final validQuizzes = _quizzes.where((q) {
      final hasQuestion = q['question'] != null || q['pergunta'] != null;
      final options = q['options'] ?? q['opcoes'];
      final hasOptions =
          options != null && options is List && options.length >= 4;
      return hasQuestion && hasOptions;
    }).toList();

    if (validQuizzes.isEmpty) {
      _showToast('O inimigo bloqueou a ação! Analisando defesas...');
      setState(() => isLoadingQuizzes = true);
      _loadQuizzes();
      return;
    }

    var unusedQuizzes = validQuizzes.where((q) {
      final questionText = (q['question'] ?? q['pergunta']).toString();
      return !_usedQuestions.contains(questionText);
    }).toList();

    if (unusedQuizzes.isEmpty) {
      // Se todas já foram usadas, recomeça o ciclo
      _usedQuestions.clear();
      unusedQuizzes = validQuizzes;
    }

    final quiz = unusedQuizzes[_rng.nextInt(unusedQuizzes.length)];
    final questionText = (quiz['question'] ?? quiz['pergunta']).toString();
    _usedQuestions.add(questionText);

    setState(() {
      isQuizMode = true;
      currentQuiz = quiz;
    });
  }

  void _answerQuiz(int selectedIndex) {
    if (!isQuizMode || currentQuiz == null) return;

    setState(() {
      isQuizMode = false;
    });

    dynamic correctAnswer =
        currentQuiz!['correctAnswerIndex'] ?? currentQuiz!['resposta_correta'];
    int expectedIndex = -1;

    if (correctAnswer is int) {
      expectedIndex = correctAnswer;
    } else if (correctAnswer is String) {
      final options = currentQuiz!['options'] ?? currentQuiz!['opcoes'];
      if (options is List) {
        expectedIndex = options.indexWhere(
          (opt) => opt.toString().trim() == correctAnswer.trim(),
        );
      }
    }

    if (selectedIndex == expectedIndex ||
        (expectedIndex == -1 && selectedIndex == 0)) {
      // Resposta correta: ataca
      int damage = 20 + _rng.nextInt(16); // Dano entre 20 e 35
      final pName = FirebaseAuth.instance.currentUser?.displayName?.toUpperCase() ?? 'VISITANTE';
      if (_iraBoostActive) {
        damage *= 2;
        _iraBoostActive = false;
        _executePlayerAction(
          damage: damage,
          logText:
              'Resposta Correta!\nCom a Erva da Ira, $pName causou DANO DUPLO!',
        );
      } else {
        _executePlayerAction(
          damage: damage,
          logText: 'Resposta Correta!\n$pName usou Luta!',
        );
      }
    } else {
      // Resposta errada: falha, inimigo ataca
      setState(() {
        isAnimating = true;
        isPlayerTurn = false;
        if (_iraBoostActive) {
          battleLog =
              'Resposta Incorreta!\nA Erva da Ira te deixou vulnerável!';
        } else {
          battleLog = 'Resposta Incorreta!\nO ataque falhou!';
        }
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        _enemyAttack();
      });
    }
  }

  Widget _buildQuizOption(int index, String label) {
    if (currentQuiz == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _answerQuiz(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '$label. ${(currentQuiz?['options'] ?? currentQuiz?['opcoes'])?[index] ?? 'Opção'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Courier',
                height: 1.15,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackpackOption(GameItem? item) {
    String label = item == null ? 'Voltar' : '(x${item.quantity}) ${item.name}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onHover: (hovering) {
            if (hovering && item != null) {
              setState(() => hoveredItemDescription = item.description);
            } else if (hovering && item == null) {
              setState(() => hoveredItemDescription = 'Voltar para o combate');
            }
          },
          onHighlightChanged: (highlighted) {
            if (highlighted && item != null) {
              setState(() => hoveredItemDescription = item.description);
            } else if (highlighted && item == null) {
              setState(() => hoveredItemDescription = 'Voltar para o combate');
            }
          },
          onTap: () {
            if (item == null) {
              setState(() => isBackpackMode = false);
            } else {
              _useItem(item);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Courier',
                height: 1.15,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _useAbility() {
    if (isAnimating || !isPlayerTurn) return;
    if (skillCooldown > 0) {
      _showToast('Habilidade em recarga por $skillCooldown turno(s)');
      return;
    }

    final damage = 18 + _rng.nextInt(15);
    final pName = FirebaseAuth.instance.currentUser?.displayName?.toUpperCase() ?? 'VISITANTE';
    _executePlayerAction(
      damage: damage,
      logText: '$pName usou Pulso Quântico!',
      nextSkillCooldown: 2,
    );
  }

  void _executePlayerAction({
    required int damage,
    required String logText,
    int nextSkillCooldown = 0,
  }) {
    if (enemyHp <= 0 || playerHp <= 0) return;

    // Primeiro passo: mostra a ação do jogador
    setState(() {
      isAnimating = true;
      isPlayerTurn = false;
      battleLog = logText;
      if (nextSkillCooldown > 0) {
        skillCooldown = nextSkillCooldown;
      }
    });

    // Aguarda um pequeno intervalo para o "golpe" conectar
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted || enemyHp <= 0 || playerHp <= 0) return;

      setState(() {
        _enemyHitFlash = true;
        enemyHp = (enemyHp - damage).clamp(0, enemyMaxHp);
        battleLog = '$logText\n$damage de dano no inimigo!';
      });

      _damageController.forward().then((_) {
        if (!mounted) return;
        _damageController.reset();
        setState(() => _enemyHitFlash = false);

        if (enemyHp <= 0) {
          setState(() {
            battleLog = '✓ VITÓRIA! Você venceu o $bossName!';
            isAnimating = false;
          });
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) _closeGame();
          });
          return;
        }

        // Em um jogo de quiz, o chefe normalmente não contra-ataca quando você acerta.
        setState(() {
          isAnimating = false;
          isPlayerTurn = true;
        });
      });
    });
  }

  void _enemyAttack() {
    if (enemyHp <= 0) {
      setState(() {
        battleLog = '✓ VITÓRIA! Você venceu o $bossName!';
        isAnimating = false;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _closeGame();
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      int damage = 25 + _rng.nextInt(11); // Dano entre 25 e 35
      if (_iraBoostActive) {
        damage *= 2;
        _iraBoostActive = false; // reset after being attacked
      }
      setState(() {
        playerHp = (playerHp - damage).clamp(0, playerMaxHp);
        battleLog = '$bossName usou Raio Lógico!\n$damage de dano!';
        isAnimating = false;
        isPlayerTurn = playerHp > 0;
        if (skillCooldown > 0) {
          skillCooldown = (skillCooldown - 1).clamp(0, 99);
        }
      });

      if (playerHp <= 0) {
        setState(() {
          battleLog = '✗ DERROTA! Você foi derrotado...';
          isPlayerTurn = false;
        });
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) _closeGame();
        });
      }
    });
  }

  void _openBackpack() {
    if (isAnimating || !isPlayerTurn || isLoadingQuizzes) return;
    setState(() {
      isBackpackMode = true;
      hoveredItemDescription = null;
    });
  }

  void _useItem(GameItem item) {
    final playerState = Provider.of<PlayerStateModel>(context, listen: false);

    if (item.type == 'healing') {
      if (playerHp >= playerMaxHp) {
        _showToast('HP já está cheio.');
        return;
      }

      if (playerState.useItem(item.id)) {
        setState(() {
          playerHp = (playerHp + item.value).clamp(0, playerMaxHp);
          playerState.heal(item.value); // atualiza no model também
          battleLog = 'Você usou ${item.name}!\n+${item.value} HP restaurado.';
          isPlayerTurn = false;
          isAnimating = true;
          isBackpackMode = false;
        });

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() => isAnimating = false);
          _enemyAttack();
        });
      }
    } else if (item.type == 'boost') {
      if (playerState.useItem(item.id)) {
        setState(() {
          _iraBoostActive = true;
          battleLog =
              'Você usou ${item.name}!\nPróxima resposta certa dá DANO DUPLO, errar dá DANO DUPLO!';
          isBackpackMode = false;
        });
      }
    }
  }

  void _attemptRun() {
    if (isAnimating || !isPlayerTurn || isLoadingQuizzes) return;
    final escaped = _rng.nextDouble() < 0.35;
    if (escaped) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      battleLog = 'Tentativa de fuga falhou!';
      isPlayerTurn = false;
      isAnimating = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => isAnimating = false);
      _enemyAttack();
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _closeGame() {
    // Se a batalha não terminou, mostra aviso
    if (playerHp > 0 && enemyHp > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          title: const Text(
            'Fugir da Batalha?',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Todo o progresso desta batalha será perdido. Você voltará para o mapa de exploração. Tem certeza?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(ctx); // Fecha dialog
                Navigator.pop(
                  context,
                  false,
                ); // Fecha tela de batalha (retorna false)
              },
              child: const Text(
                'Fugir',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Se terminou, retorna o resultado (true = vitória, false = derrota)
    bool isVictory = enemyHp <= 0 && playerHp > 0;
    Navigator.pop(context, isVictory);
  }

  @override
  Widget build(BuildContext context) {
    final isGameOver = playerHp <= 0 || enemyHp <= 0;
    const imageWidth = 572.0;
    const imageHeight = 991.0;
    const imageRatio = imageWidth / imageHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableW = constraints.maxWidth;
            final availableH = constraints.maxHeight;
            final availableRatio = availableW / availableH;

            double renderW;
            double renderH;
            if (availableRatio > imageRatio) {
              renderH = availableH;
              renderW = renderH * imageRatio;
            } else {
              renderW = availableW;
              renderH = renderW / imageRatio;
            }

            final left = (availableW - renderW) / 2;
            final top = (availableH - renderH) / 2;

            Rect hitbox(double x, double y, double w, double h) =>
                Rect.fromLTWH(
                  left + renderW * x,
                  top + renderH * y,
                  renderW * w,
                  renderH * h,
                );

            final combatButton = hitbox(0.08, 0.81, 0.30, 0.17);
            final bagButton = hitbox(0.62, 0.81, 0.30, 0.17);
            final closeButton = hitbox(0.88, 0.02, 0.10, 0.06);
            final settingsButton = hitbox(0.02, 0.02, 0.10, 0.06);

            /// Sub-painel de dados do vilão (agora na esquerda).
            final villainDataPanel = hitbox(0.04, 0.18, 0.44, 0.12);

            /// Display tático do soldado (agora na direita embaixo).
            final soldierDataPanel = hitbox(0.55, 0.50, 0.41, 0.13);
            
            double logY;
            double answersY;
            switch (widget.estagio) {
              case 1:
                logY = 0.62;
                answersY = 0.77;
                break;
              case 2:
                logY = 0.62;
                answersY = 0.78;
                break;
              case 3:
                logY = 0.62;
                answersY = 0.79;
                break;
              case 4:
                logY = 0.63;
                answersY = 0.805;
                break;
              case 5:
                logY = 0.635;
                answersY = 0.795;
                break;
              default:
                logY = 0.655;
                answersY = 0.80;
                break;
            }

            final battleLogArea = hitbox(0.05, logY, 0.90, 0.16);
            final quizQuestionArea = hitbox(0.05, logY, 0.90, 0.16);
            final quizAnswersArea = hitbox(0.05, answersY, 0.90, 0.19);

            return Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: renderW,
                      height: renderH,
                      child: Image.asset(
                        (isQuizMode || isBackpackMode)
                            ? AssetPaths.battleBackground2(widget.estagio)
                            : AssetPaths.battleBackground(widget.estagio),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),

                Positioned.fromRect(
                  rect: villainDataPanel,
                  child: IgnorePointer(
                    child: VillainHealthField(
                      hp: enemyHp,
                      maxHp: enemyMaxHp,
                      bossName: bossName,
                    ),
                  ),
                ),

                Positioned.fromRect(
                  rect: soldierDataPanel,
                  child: IgnorePointer(
                    child: SoldierHealthField(
                      hp: playerHp,
                      maxHp: playerMaxHp,
                      level: playerLevel,
                      playerName:
                          FirebaseAuth.instance.currentUser?.displayName ??
                          'Visitante',
                    ),
                  ),
                ),

                // Mensagem inferior (pixel text; botões permanecem na arte)
                if (!isQuizMode && !isBackpackMode) ...[
                  Positioned.fromRect(
                    rect: battleLogArea,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: renderW * 0.8,
                            height: renderH * 0.16,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                battleLog,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Courier',
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Hitbox: COMBATE
                  if (!isGameOver)
                    Positioned.fromRect(
                      rect: combatButton,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _playerAttack,
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.white24,
                          highlightColor: Colors.transparent,
                        ),
                      ),
                    ),

                  // Hitbox: MOCHILA
                  if (!isGameOver)
                    Positioned.fromRect(
                      rect: bagButton,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openBackpack,
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.white24,
                          highlightColor: Colors.transparent,
                        ),
                      ),
                    ),
                ] else if (isQuizMode) ...[
                  // Modo Quiz
                  Positioned.fromRect(
                    rect: quizQuestionArea,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: renderW * 0.85,
                            height: renderH * 0.16,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                (currentQuiz?['question'] ??
                                            currentQuiz?['pergunta'])
                                        ?.toString() ??
                                    'Pergunta não encontrada',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Courier',
                                  height: 1.2,
                                  shadows: [
                                    Shadow(offset: Offset(1, 1), blurRadius: 2),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: quizAnswersArea,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: _buildQuizOption(0, 'A')),
                                Expanded(child: _buildQuizOption(2, 'C')),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: _buildQuizOption(1, 'B')),
                                Expanded(child: _buildQuizOption(3, 'D')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (isBackpackMode) ...[
                  // Modo Mochila
                  Positioned.fromRect(
                    rect: quizQuestionArea,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: renderW * 0.85,
                            height: renderH * 0.16,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                hoveredItemDescription ??
                                    'Mochila\nSelecione um item...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Courier',
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: quizAnswersArea,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Builder(
                        builder: (ctx) {
                          final playerState = Provider.of<PlayerStateModel>(
                            ctx,
                            listen: false,
                          );
                          final usableItems = playerState.inventory
                              .where(
                                (item) =>
                                    item.type == 'healing' ||
                                    item.type == 'boost',
                              )
                              .toList();

                          final options = <Widget>[];
                          for (int i = 0; i < 4; i++) {
                            if (i < usableItems.length) {
                              options.add(
                                Expanded(
                                  child: _buildBackpackOption(usableItems[i]),
                                ),
                              );
                            } else if (i == 3 || i == usableItems.length) {
                              options.add(
                                Expanded(child: _buildBackpackOption(null)),
                              ); // Voltar
                            } else {
                              options.add(
                                const Expanded(child: SizedBox.shrink()),
                              );
                            }
                          }

                          return Column(
                            children: [
                              Expanded(
                                child: Row(children: [options[0], options[2]]),
                              ),
                              Expanded(
                                child: Row(children: [options[1], options[3]]),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Hitbox: engrenagem (configurações)
                Positioned.fromRect(
                  rect: settingsButton,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: 'Pause',
                          barrierColor: Colors.transparent,
                          transitionDuration: const Duration(milliseconds: 200),
                          pageBuilder: (context, anim1, anim2) => PauseOverlay(
                            isInBattle: true,
                            onExitBattle: () {
                              Navigator.pop(context, false); // Derrota por fuga
                            },
                          ),
                          transitionBuilder: (context, anim1, anim2, child) {
                            return FadeTransition(opacity: anim1, child: child);
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(40),
                      splashColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),

                // Hitbox: fechar
                Positioned.fromRect(
                  rect: closeButton,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _closeGame,
                      borderRadius: BorderRadius.circular(40),
                      splashColor: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Image.asset(
      AssetPaths.battleBackground(widget.estagio),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.blueGrey[800]!,
                Colors.grey[900]!,
              ],
            ),
          ),
          child: CustomPaint(
            painter: BinaryRainPainter(),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  Widget _buildEnemySprite() {
    return SizedBox(
      width: 150,
      height: 150,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _enemyHitFlash ? Colors.orange[200]! : Colors.red[300]!,
              _enemyHitFlash ? Colors.red[700]! : Colors.red[900]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Telas vermelhas (efeito de acesso negado)
            Positioned(
              top: 30,
              left: 30,
              child: Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[400]!, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'X',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[400]!, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'X',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estilo de texto pixel / terminal comum ao HUD da batalha.
class _BattleHudText {
  static const TextStyle whiteHud = TextStyle(
    color: Color(0xFFE8E8E8),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    fontFamily: 'Courier',
    letterSpacing: 0.4,
    height: 1.15,
    shadows: [
      Shadow(offset: Offset(1, 1), blurRadius: 0, color: Colors.black87),
    ],
  );

  static TextStyle flavorEnemy(double fontSize) => TextStyle(
    color: Color.lerp(const Color(0xFFFF5252), const Color(0xFF7B1FA2), 0.45)!,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    fontFamily: 'Courier',
    letterSpacing: 0.3,
    height: 1.2,
  );

  static TextStyle flavorSoldier(double fontSize) => TextStyle(
    color: const Color(0xFF4FC3F7),
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    fontFamily: 'Courier',
    letterSpacing: 0.25,
    height: 1.2,
    shadows: const [
      Shadow(offset: Offset(1, 1), blurRadius: 0, color: Colors.black54),
    ],
  );
}

/// Sub-painel do vilão: metal, parafusos, tela estilo corpo do chefe.
class VillainHealthField extends StatelessWidget {
  final int hp;
  final int maxHp;
  final String bossName;

  const VillainHealthField({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.bossName,
  });

  @override
  Widget build(BuildContext context) {
    final double healthPercent = maxHp > 0 ? hp / maxHp : 0.0;
    final int percentage = (healthPercent * 100).clamp(0, 100).round();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            const Color(0xFF383838),
            const Color(0xFF1A0A14),
          ],
        ),
        border: Border.all(color: const Color(0xFF5D4037), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 180,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              bossName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 1,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _BossEnergyHpBar(value: healthPercent.clamp(0.0, 1.0)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            'HP: $hp / $maxHp',
                            style: _BattleHudText.whiteHud.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: _BattleHudText.whiteHud.copyWith(
                            fontSize: 12,
                            color: const Color(0xFFFFCDD2),
                          ),
                        ),
                      ],
                    ),
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

/// Barra vilão: grade energética, vermelho profundo → roxo sombrio.
class _BossEnergyHpBar extends StatelessWidget {
  final double value;

  const _BossEnergyHpBar({required this.value});

  @override
  Widget build(BuildContext context) {
    const h = 18.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2D0A24), Color(0xFF120818)],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * value.clamp(0.0, 1.0),
                    child: CustomPaint(
                      painter: _BossHpFillPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              },
            ),
            CustomPaint(
              painter: _EnergyGridOverlayPainter(),
              child: const SizedBox.expand(),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BossHpFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFB71C1C), Color(0xFF7B1FA2), Color(0xFF4A148C)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _BossHpFillPainter oldDelegate) => false;
}

class _EnergyGridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    const step = 5.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyGridOverlayPainter oldDelegate) => false;
}

/// Painel tático do soldado: grade, ícone, HP verde→azul.
class SoldierHealthField extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int level;
  final String playerName;

  const SoldierHealthField({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.level,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final double healthPercent = maxHp > 0 ? hp / maxHp : 0.0;
    final int percentage = (healthPercent * 100).clamp(0, 100).round();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B2A),
            const Color(0xFF102A43),
            const Color(0xFF061018),
          ],
        ),
        border: Border.all(color: const Color(0xFF546E7A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.12),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _TacticalGridBgPainter()),
          ),
          FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 170,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            playerName,
                            style: _BattleHudText.flavorSoldier(14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ESTADO DE COMBATE',
                      style: _BattleHudText.flavorSoldier(10),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: _TacticalEnergyHpBar(
                        value: healthPercent.clamp(0.0, 1.0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            'HP: $hp / $maxHp',
                            style: _BattleHudText.whiteHud.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: _BattleHudText.whiteHud.copyWith(
                            fontSize: 12,
                            color: const Color(0xFFB9F6CA),
                          ),
                        ),
                      ],
                    ),
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

/// Grade tática bem sutil sobre o painel do soldado.
class _TacticalGridBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 12.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalGridBgPainter oldDelegate) => false;
}

/// Barra soldado: leitura energia tática verde → azul.
class _TacticalEnergyHpBar extends StatelessWidget {
  final double value;

  const _TacticalEnergyHpBar({required this.value});

  @override
  Widget build(BuildContext context) {
    const h = 18.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF0A1628)),
            LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * value.clamp(0.0, 1.0),
                    child: CustomPaint(
                      painter: _SoldierHpFillPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              },
            ),
            CustomPaint(
              painter: _EnergyGridOverlayPainter(),
              child: const SizedBox.expand(),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoldierHpFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF00C853), Color(0xFF00ACC1), Color(0xFF0277BD)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _SoldierHpFillPainter oldDelegate) => false;
}

// Widget de Botões de Ação
class ActionButtons extends StatelessWidget {
  final VoidCallback onFight;
  final VoidCallback onAbility;
  final VoidCallback onBackpack;
  final VoidCallback onRun;
  final bool isPlayerTurn;
  final bool isBusy;
  final int healKits;
  final int skillCooldown;

  const ActionButtons({
    super.key,
    required this.onFight,
    required this.onAbility,
    required this.onBackpack,
    required this.onRun,
    required this.isPlayerTurn,
    required this.isBusy,
    required this.healKits,
    required this.skillCooldown,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = isPlayerTurn && !isBusy;

    return Container(
      width: 215,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Luta',
                  enabled: enabled,
                  onTap: onFight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: skillCooldown == 0
                      ? 'Habilidade'
                      : 'Recarga $skillCooldown',
                  enabled: enabled && skillCooldown == 0,
                  onTap: onAbility,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Mochila ($healKits)',
                  enabled: enabled && healKits > 0,
                  onTap: onBackpack,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Fugir',
                  enabled: enabled,
                  onTap: onRun,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Widget Caixa de Diálogo
class DialogBoxWidget extends StatelessWidget {
  final String text;

  const DialogBoxWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AssetGenerators.generateHudFrame(
      borderColor: Colors.amber,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 100),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Courier',
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class BinaryRainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final List<String> binaryChars = ['0', '1'];

    for (int i = 0; i < 50; i++) {
      final x = (i * 30 % size.width).toDouble();
      final y = (i * 15 % size.height).toDouble();
      final char = binaryChars[i % 2];

      textPainter.text = TextSpan(
        text: char,
        style: TextStyle(
          color: Colors.cyan.withOpacity(0.4),
          fontSize: 12,
          fontFamily: 'Courier',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(BinaryRainPainter oldDelegate) => false;
}
