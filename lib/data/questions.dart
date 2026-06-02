class Question {
  final String id;
  final int estagio;
  final int dificuldade;
  final String pergunta;
  final List<dynamic> opcoes;
  final dynamic respostaCorreta;

  Question({
    required this.id,
    required this.estagio,
    required this.dificuldade,
    required this.pergunta,
    required this.opcoes,
    required this.respostaCorreta,
  });

  bool isCorrect(dynamic answer) {
    return answer.toString() == respostaCorreta.toString();
  }
}
