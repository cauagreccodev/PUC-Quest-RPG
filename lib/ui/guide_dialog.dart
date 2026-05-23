import 'dart:async';
import 'package:flutter/material.dart';
import 'profile_overlay.dart' show MedievalColors;

class DialogBox extends StatefulWidget{
  final String characterName;
  final List<String> messages;
  final VoidCallback? onFinished;

  const DialogBox({
    super.key,
    required this.characterName,
    required this.messages,
    this.onFinished,
  });

  @override
  State<DialogBox> createState() => _DialogBox();
}

class _DialogBox extends State<DialogBox> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  int _currentIndex = 0;
  List<String> _history = [];

  Timer? _typingTimer;
  String _displayedText = "";
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _startTyping();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTyping() {
    _typingTimer?.cancel();
    _displayedText = "";
    _isTyping = true;

    int charIndex = 0;
    String fullText = widget.messages[_currentIndex];

    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        if (charIndex < fullText.length) {
          _displayedText += fullText[charIndex];
          charIndex++;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          _isTyping = false;
          timer.cancel();
          _history.add(fullText);
        }
      });
    });
  }

  void _handleTap() {
    if (_isTyping) {
      _typingTimer?.cancel();
      setState(() {
        _displayedText = widget.messages[_currentIndex];
        _isTyping = false;
      });

      _history.add(widget.messages[_currentIndex]);
    } else {
      if (_currentIndex < widget.messages.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _startTyping();
      } else {
        if (widget.onFinished != null) {
          widget.onFinished!();
        }
      }
    }
  }

  void _showHistoryLog() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: MedievalColors.woodDark.withAlpha(240),
            border: const Border(
              top: BorderSide(color: MedievalColors.gold, width: 3),
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.history_edu, color: MedievalColors.gold),
                    SizedBox(width: 8),
                    Text(
                      "HISTÓRICO DE DIÁLOGOS",
                      style: TextStyle(
                        color: MedievalColors.gold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    )
                  ],
                ),
              ),

              const Divider(color: MedievalColors.goldDark, height: 1),

              Expanded(
                child: _history.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum registro anterior.",
                          style: TextStyle(color: MedievalColors.parchment),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.characterName.toUpperCase(),
                                  style: const TextStyle(
                                    color: MedievalColors.goldDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  )
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  _history[index],
                                  style: const TextStyle(
                                    color: MedievalColors.parchment,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
              ),
            ],
          ),
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 110.0,
        width: double.infinity,
        decoration: BoxDecoration(
          color: MedievalColors.woodDark.withAlpha(220),
          border: Border.all(
            color: MedievalColors.gold,
            width: 2,
          ),
          borderRadius:BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Space
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MedievalColors.goldDark,
                        width: 2,
                      ),
                      color: MedievalColors.woodMid,
                    ),
                    /*
                  // QUANDO FOR USAR A IMAGEM DO SEU JOGO, DESCOMENTE ESTA PARTE:
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/player/Soldier_Idle.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                */
                    child: const Icon(
                      Icons.person_outline,
                      color: MedievalColors.parchment,
                      size: 40.0,
                    ),
                  ),

                  SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Character Name + History Button
                            Text(
                              widget.characterName.toUpperCase(),
                              style: const TextStyle(
                                color: MedievalColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                letterSpacing: 1.2,
                              ),
                            ),

                            const Spacer(),

                            GestureDetector(
                              onTap: _showHistoryLog,
                              child: const Icon(
                                Icons.menu_book,
                                color: MedievalColors.goldDark,
                                size: 18,
                              ),
                            )
                          ],
                        ),

                        SizedBox(width: 6),

                        // Character Message
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Text(
                              _displayedText,
                              style: const TextStyle(
                                color: MedievalColors.parchment,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (!_isTyping)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _animationController,
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: MedievalColors.gold,
                      size: 32.0,
                    ),
                  )
                ),
            ],
          )
        ),
      ),
    );
  }
}