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

class QuestionsData {
  static final List<Question> allQuestions = [
    // --- ESTÁGIO 1 - DIFICULDADE 1 ---
    Question(
      id: "69c32a9522b1c47a840afa9e",
      estagio: 1,
      dificuldade: 1,
      pergunta: "Em lógica proposicional, se a proposição P é Falsa (0) e a proposição Q é Verdadeira (1), qual é o valor verdade da conjunção (P AND Q)?",
      opcoes: [0, 1, "Depende de P", "Nulo"],
      respostaCorreta: 0,
    ),
    
    // --- ESTÁGIO 1 - DIFICULDADE 2 ---
    Question(
      id: "69cd47ce15dd55e316839180",
      estagio: 1,
      dificuldade: 2,
      pergunta: "De acordo com as Leis de Morgan, a negação de uma disjunção, expressa como NOT (P OR Q), é logicamente equivalente a qual destas expressões?",
      opcoes: ["(NOT P) AND (NOT Q)", "(NOT P) OR (NOT Q)", "NOT (P AND Q)", "P OR (NOT Q)"],
      respostaCorreta: "(NOT P) AND (NOT Q)",
    ),
    Question(
      id: "69cd48ad15dd55e316839183",
      estagio: 1,
      dificuldade: 2,
      pergunta: "Na álgebra booleana, a propriedade da identidade para a conjunção estabelece que a expressão (P AND 1) é logicamente equivalente a quê?",
      opcoes: [1, 0, "P", "NOT P"],
      respostaCorreta: "P",
    ),
    Question(
      id: "69cd499215dd55e316839185",
      estagio: 1,
      dificuldade: 2,
      pergunta: "Avalie o valor verdade da seguinte proposição composta, sabendo que P = 1 e Q = 0: (P OR Q) AND (NOT Q).",
      opcoes: [1, 0, "P", "Q"],
      respostaCorreta: 1,
    ),

    // --- ESTÁGIO 1 - DIFICULDADE 3 ---
    Question(
      id: "69cd4c8815dd55e31683918a",
      estagio: 1,
      dificuldade: 3,
      pergunta: "Uma Contradição é uma proposição que sempre resulta em Falso (0). Qual das expressões abaixo representa uma contradição lógica?",
      opcoes: ["P AND (NOT P)", "P OR (NOT P)", "NOT (NOT P)", "P OR 1"],
      respostaCorreta: "P AND (NOT P)",
    ),
    Question(
      id: "69cd4cb215dd55e31683918b",
      estagio: 1,
      dificuldade: 3,
      pergunta: "De acordo com a propriedade da Idempotência, a expressão (P OR P) é logicamente equivalente a quê?",
      opcoes: ["P", "Q", "P AND Q", 1],
      respostaCorreta: "P",
    ),
  ];

  static List<Question> getQuestionsForPhase(int phaseNumber) {
    return allQuestions.where((q) => q.estagio == phaseNumber).toList();
  }
}
