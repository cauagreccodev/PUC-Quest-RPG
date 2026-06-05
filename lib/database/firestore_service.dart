import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Coleções do banco de dados (Igual ao MongoDB)
  final String _usersCollection = 'users';
  final String _savesCollection = 'saves';
  final String _bossesCollection = 'bosses';
  final String _quizzesCollection = 'quizzes';
  final String _itemsCollection = 'items'; // Nova coleção de Itens

  // ==========================================
  // AUTOMAÇÃO (Seed do Banco de Dados)
  // ==========================================

  /// Preenche o banco de dados com os Chefões, Quizzes e Itens iniciais caso estejam vazios
  Future<void> seedDatabase() async {
    // 1. Populando Chefões (Bosses)
    final bossesSnap = await _db.collection(_bossesCollection).limit(1).get();
    if (bossesSnap.docs.isEmpty) {
      final bosses = [
        {'id': 'boss_ceatec', 'name': 'Guardião de Sistemas', 'hp': 200, 'damage': 15, 'zone': 'CEATEC', 'rewardItem': 'Código de Cura'},
        {'id': 'boss_cea', 'name': 'Mestre das Finanças', 'hp': 250, 'damage': 20, 'zone': 'CEA', 'rewardItem': 'Carta Dica'},
        {'id': 'boss_clc', 'name': 'Esfinge da Linguagem', 'hp': 180, 'damage': 25, 'zone': 'CLC', 'rewardItem': 'Código de Cura'},
        {'id': 'boss_cchsa', 'name': 'Sábio das Sociais', 'hp': 300, 'damage': 10, 'zone': 'CCHSA', 'rewardItem': 'Carta Dica Extrema'},
      ];
      for (var boss in bosses) {
        await _db.collection(_bossesCollection).doc(boss['id'].toString()).set(boss);
      }
      print("✅ Chefões inseridos no banco automaticamente!");
    }

    // 2. Populando Quizzes (10 por estágio, total 50)
    final quizzesSnap = await _db.collection(_quizzesCollection).limit(1).get();
    if (quizzesSnap.docs.isEmpty) {
      final quizzes = [
        // ── ESTÁGIO 1 – Matemática Discreta ─────────────────────────────
        {
          'id': 'q1_01', 'estagio': 1,
          'question': 'Em lógica proposicional, qual operador resulta em verdadeiro apenas quando ambas as proposições são verdadeiras?',
          'options': ['Disjunção (∨)', 'Conjunção (∧)', 'Implicação (→)', 'Negação (¬)'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q1_02', 'estagio': 1,
          'question': 'Qual é o resultado de ¬(p ∧ q) quando p=V e q=F?',
          'options': ['Falso', 'Verdadeiro', 'Indefinido', 'Depende do contexto'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q1_03', 'estagio': 1,
          'question': 'Um conjunto A tem 3 elementos. Quantos subconjuntos ele possui?',
          'options': ['6', '8', '9', '12'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q1_04', 'estagio': 1,
          'question': 'Qual das alternativas representa uma tautologia?',
          'options': ['p ∧ ¬p', 'p ∨ ¬p', 'p → q', 'p ∧ q'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q1_05', 'estagio': 1,
          'question': 'A relação de equivalência possui quais propriedades?',
          'options': ['Reflexiva, simétrica e transitiva', 'Reflexiva e antissimétrica', 'Simétrica e assimétrica', 'Transitiva e irreflexiva'],
          'correctAnswerIndex': 0,
        },
        {
          'id': 'q1_06', 'estagio': 1,
          'question': 'Qual é o valor de 5! (fatorial de 5)?',
          'options': ['25', '60', '120', '720'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q1_07', 'estagio': 1,
          'question': 'Em um grafo não direcionado com 4 vértices, qual é o número máximo de arestas?',
          'options': ['4', '6', '8', '12'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q1_08', 'estagio': 1,
          'question': 'Qual regra de inferência permite concluir q a partir de p e p→q?',
          'options': ['Modus Tollens', 'Modus Ponens', 'Silogismo', 'Adição'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q1_09', 'estagio': 1,
          'question': 'Um número natural é divisível por 2 se, e somente se, é:',
          'options': ['Primo', 'Par', 'Ímpar', 'Composto'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q1_10', 'estagio': 1,
          'question': 'A operação de interseção entre os conjuntos A={1,2,3} e B={2,3,4} resulta em:',
          'options': ['{1,2,3,4}', '{2,3}', '{1,4}', '{}'],
          'correctAnswerIndex': 1,
        },

        // ── ESTÁGIO 2 – Algoritmos e Lógica de Programação ──────────────
        {
          'id': 'q2_01', 'estagio': 2,
          'question': 'Qual é a complexidade de tempo do algoritmo Bubble Sort no pior caso?',
          'options': ['O(n)', 'O(n log n)', 'O(n²)', 'O(log n)'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q2_02', 'estagio': 2,
          'question': 'Uma estrutura de repetição que sempre executa ao menos uma vez é:',
          'options': ['for', 'while', 'do-while', 'foreach'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q2_03', 'estagio': 2,
          'question': 'Qual paradigma de programação tem como base funções matemáticas sem efeitos colaterais?',
          'options': ['Imperativo', 'Orientado a objetos', 'Funcional', 'Lógico'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q2_04', 'estagio': 2,
          'question': 'Em pseudocódigo, o que o operador MOD (%) retorna?',
          'options': ['Quociente da divisão', 'Resto da divisão', 'Parte inteira', 'Valor absoluto'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q2_05', 'estagio': 2,
          'question': 'Qual estrutura de dados usa o princípio LIFO (Last In, First Out)?',
          'options': ['Fila', 'Pilha', 'Lista ligada', 'Árvore'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q2_06', 'estagio': 2,
          'question': 'Binary Search exige que o vetor esteja:',
          'options': ['Desordenado', 'Ordenado', 'Com elementos únicos', 'Sem elementos nulos'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q2_07', 'estagio': 2,
          'question': 'Qual é a saída de: x=10; y=3; print(x // y) em Python?',
          'options': ['3.33', '3', '4', '1'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q2_08', 'estagio': 2,
          'question': 'Uma função que chama a si mesma é chamada de:',
          'options': ['Iterativa', 'Recursiva', 'Lambda', 'Estática'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q2_09', 'estagio': 2,
          'question': 'Qual notação descreve o limite superior (pior caso) de complexidade?',
          'options': ['Ω (Omega)', 'Θ (Theta)', 'O (Big-O)', 'Σ (Sigma)'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q2_10', 'estagio': 2,
          'question': 'Qual tipo de variável armazena verdadeiro ou falso?',
          'options': ['int', 'float', 'boolean', 'char'],
          'correctAnswerIndex': 2,
        },

        // ── ESTÁGIO 3 – Estruturas de Dados I e II ───────────────────────
        {
          'id': 'q3_01', 'estagio': 3,
          'question': 'Em uma árvore binária de busca (BST), onde ficam os menores valores?',
          'options': ['Nó raiz', 'Subárvore direita', 'Subárvore esquerda', 'Folhas'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q3_02', 'estagio': 3,
          'question': 'Qual operação de fila segue o princípio FIFO?',
          'options': ['push/pop', 'enqueue/dequeue', 'insert/delete', 'push/pull'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q3_03', 'estagio': 3,
          'question': 'A complexidade de busca em uma tabela hash com poucos conflitos é:',
          'options': ['O(n)', 'O(n²)', 'O(log n)', 'O(1)'],
          'correctAnswerIndex': 3,
        },
        {
          'id': 'q3_04', 'estagio': 3,
          'question': 'Qual travessia de árvore visita: esquerda → raiz → direita?',
          'options': ['Pré-ordem', 'In-ordem', 'Pós-ordem', 'BFS'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q3_05', 'estagio': 3,
          'question': 'Em uma lista duplamente ligada, cada nó possui:',
          'options': ['Um ponteiro para próximo', 'Ponteiros para próximo e anterior', 'Apenas o dado', 'Dois dados e um ponteiro'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q3_06', 'estagio': 3,
          'question': 'Qual estrutura é ideal para implementar algoritmos de busca em largura (BFS)?',
          'options': ['Pilha', 'Fila', 'Heap', 'Árvore AVL'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q3_07', 'estagio': 3,
          'question': 'Uma árvore AVL se diferencia de uma BST por:',
          'options': ['Permitir duplicatas', 'Ser auto-balanceada', 'Usar ponteiros duplos', 'Armazenar apenas inteiros'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q3_08', 'estagio': 3,
          'question': 'Qual é a altura máxima de uma árvore binária com n nós (pior caso)?',
          'options': ['O(log n)', 'O(√n)', 'O(n)', 'O(n²)'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q3_09', 'estagio': 3,
          'question': 'Em um heap máximo, o maior elemento está:',
          'options': ['Na última folha', 'Na raiz', 'No nível mais profundo', 'Aleatoriamente'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q3_10', 'estagio': 3,
          'question': 'Qual estrutura de dados utiliza alocação dinâmica e não tem tamanho fixo?',
          'options': ['Array estático', 'Lista ligada', 'Vetor', 'Tupla'],
          'correctAnswerIndex': 1,
        },

        // ── ESTÁGIO 4 – Banco de Dados I e II ───────────────────────────
        {
          'id': 'q4_01', 'estagio': 4,
          'question': 'Qual comando SQL é usado para consultar dados em uma tabela?',
          'options': ['INSERT', 'UPDATE', 'SELECT', 'DELETE'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q4_02', 'estagio': 4,
          'question': 'O que é uma chave primária em um banco de dados relacional?',
          'options': ['Campo que pode se repetir', 'Campo que identifica unicamente cada registro', 'Campo obrigatório com valor padrão', 'Índice secundário da tabela'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q4_03', 'estagio': 4,
          'question': 'O Teorema CAP (NoSQL) dita que garantimos até 2 de 3 propriedades:',
          'options': ['Cons./Disp./Partição', 'Concur./Atomic./Pilha', 'Control./Access./Priv.', 'Commit/Async/Pub'],
          'correctAnswerIndex': 0,
        },
        {
          'id': 'q4_04', 'estagio': 4,
          'question': 'Qual é um exemplo de banco de dados NoSQL do tipo Chave-Valor?',
          'options': ['MySQL', 'Redis', 'Neo4j', 'Cassandra'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q4_05', 'estagio': 4,
          'question': 'O que é uma Foreign Key (chave estrangeira)?',
          'options': ['Chave de outra língua', 'Referência à chave primária de outra tabela', 'Segundo índice de uma tabela', 'Chave criptografada'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q4_06', 'estagio': 4,
          'question': 'Qual tipo de JOIN retorna apenas registros com correspondência em AMBAS as tabelas?',
          'options': ['LEFT JOIN', 'RIGHT JOIN', 'INNER JOIN', 'FULL JOIN'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q4_07', 'estagio': 4,
          'question': 'Na normalização, a 1FN (Primeira Forma Normal) exige que:',
          'options': ['Não haja dependências transitivas', 'Todos os atributos sejam atômicos', 'A chave composta seja eliminada', 'Só haja uma tabela'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q4_08', 'estagio': 4,
          'question': 'Bancos NoSQL baseados em Grafos, como o Neo4j, são ideais para:',
          'options': ['Relatórios SQL', 'Redes Sociais', 'Logs temporais', 'Cache simples'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q4_09', 'estagio': 4,
          'question': 'Bancos NoSQL como MongoDB armazenam dados em qual formato?',
          'options': ['Tabelas relacionais', 'Documentos JSON', 'Planilhas XML', 'Grafos somente'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q4_10', 'estagio': 4,
          'question': 'O Cassandra é classificado como qual tipo de banco de dados NoSQL?',
          'options': ['Documento', 'Chave-Valor', 'Família de Colunas', 'Grafo'],
          'correctAnswerIndex': 2,
        },

        // ── ESTÁGIO 5 – Organização e Arquitetura de Computadores ────────
        {
          'id': 'q5_01', 'estagio': 5,
          'question': 'Qual componente da CPU é responsável por executar operações aritméticas e lógicas?',
          'options': ['Unidade de Controle', 'Registrador', 'ULA (ALU)', 'Cache L1'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q5_02', 'estagio': 5,
          'question': 'O que é o pipeline em arquitetura de processadores?',
          'options': ['Barramento de dados', 'Técnica de execução de instruções em paralelo por estágios', 'Memória cache de alta velocidade', 'Tipo de registrador especial'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q5_03', 'estagio': 5,
          'question': 'Qual é a representação em binário do número decimal 10?',
          'options': ['1000', '1010', '1100', '0110'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q5_04', 'estagio': 5,
          'question': 'A memória cache existe para:',
          'options': ['Aumentar o armazenamento permanente', 'Reduzir a latência de acesso à RAM', 'Substituir o HD', 'Processar gráficos'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q5_05', 'estagio': 5,
          'question': 'Qual instrução inicia o ciclo de busca-decodificação-execução em uma CPU?',
          'options': ['STORE', 'FETCH', 'JUMP', 'HALT'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q5_06', 'estagio': 5,
          'question': 'O que significa RISC na arquitetura de processadores?',
          'options': ['Reduced Instruction Set Computer', 'Random Instruction Set Cache', 'Rapid Integrated System Controller', 'Remote Instruction Sequence Core'],
          'correctAnswerIndex': 0,
        },
        {
          'id': 'q5_07', 'estagio': 5,
          'question': 'Qual porta lógica tem saída 1 somente quando TODAS as entradas são 1?',
          'options': ['OR', 'NOT', 'AND', 'XOR'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'q5_08', 'estagio': 5,
          'question': 'O complemento de 2 é usado para representar:',
          'options': ['Números reais', 'Números negativos em binário', 'Números hexadecimais', 'Endereços de memória'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q5_09', 'estagio': 5,
          'question': 'Qual é a função do registrador PC (Program Counter)?',
          'options': ['Armazenar o resultado de operações', 'Apontar para o endereço da próxima instrução', 'Controlar a velocidade do clock', 'Gerenciar a memória cache'],
          'correctAnswerIndex': 1,
        },
        {
          'id': 'q5_10', 'estagio': 5,
          'question': 'Um byte possui quantos bits?',
          'options': ['4', '8', '16', '32'],
          'correctAnswerIndex': 1,
        },
      ];
      for (var quiz in quizzes) {
        await _db.collection(_quizzesCollection).doc(quiz['id'].toString()).set(quiz);
      }
      print("✅ Quizzes inseridos no banco automaticamente! (50 questões, 5 estágios)");
    }

    // 3. Populando Itens Básicos do Jogo
    final itemsSnap = await _db.collection(_itemsCollection).limit(1).get();
    if (itemsSnap.docs.isEmpty) {
      final items = [
        {'id': 'item_cura', 'name': 'Código de Cura', 'description': 'Restaura 2 pontos de vida (+2 ❤️)', 'type': 'healing', 'value': 2, 'icon': '❤️'},
        {'id': 'item_dica', 'name': 'Carta Dica', 'description': 'Auxílio na resolução de bugs ou desafios lógicos.', 'type': 'support', 'value': 1, 'icon': '📜'},
        {'id': 'erva_divina', 'name': 'Erva Divina', 'description': 'Recupera 40 HP, mas consome seu turno em batalha.', 'type': 'healing', 'value': 40, 'icon': '🌿'},
        {'id': 'erva_ira', 'name': 'Erva da Ira', 'description': 'Dobra o dano se acertar, mas você toma o dobro se errar! Não consome turno.', 'type': 'boost', 'value': 2, 'icon': '🔥'},
        {'id': 'key_1', 'name': 'Chave do Calouro', 'description': 'Acesso à Praça de Alimentação', 'type': 'key', 'icon': '🔑'},
        {'id': 'key_2', 'name': 'Chave do Conhecimento', 'description': 'Acesso à Biblioteca (Redes)', 'type': 'key', 'icon': '🗝️'},
        {'id': 'key_3', 'name': 'Chave da Lógica', 'description': 'Acesso ao H14 (A02)', 'type': 'key', 'icon': '🔐'},
        {'id': 'key_4', 'name': 'Chave do Portal', 'description': 'Acesso à Entrada do H15', 'type': 'key', 'icon': '🗝️'},
        {'id': 'key_5', 'name': 'Chave do Diploma', 'description': 'Acesso ao H15 (Jogos Digitais)', 'type': 'key', 'icon': '🎓'},
      ];
      for (var item in items) {
        await _db.collection(_itemsCollection).doc(item['id'].toString()).set(item);
      }
      print("✅ Itens inseridos no banco automaticamente!");
    }
  }

  // ==========================================
  // USERS (Jogadores)
  // ==========================================

  /// Cria ou atualiza o perfil base do usuário no primeiro login
  Future<void> createUserProfile(User user) async {
    final userRef = _db.collection(_usersCollection).doc(user.uid);
    final docSnap = await userRef.get();

    // Só cria se o documento ainda não existir
    if (!docSnap.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': user.displayName ?? 'Jogador',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'activeSaveId': null, // ID do save atual sendo jogado
      });
      
      // Cria o primeiro "Save" do jogador logo após criar a conta
      await createNewSave(user.uid);
      
      // Garante que os Itens, Quizzes e Chefões estejam no banco (Automação)
      await seedDatabase();
    }
  }

  /// Atualiza as configurações de áudio do usuário
  Future<void> updateAudioSettings(String uid, Map<String, dynamic> audioSettings) async {
    try {
      await _db.collection(_usersCollection).doc(uid).set({
        'audio_settings': audioSettings,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erro ao salvar audio settings: $e');
    }
  }

  /// Recupera as configurações de áudio do usuário
  Future<Map<String, dynamic>?> getAudioSettings(String uid) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('audio_settings')) {
        return doc.data()!['audio_settings'] as Map<String, dynamic>;
      }
    } catch (e) {
      print('Erro ao recuperar audio settings: $e');
    }
    return null;
  }

  // ==========================================
  // ITENS (Mochila e Consumíveis)
  // ==========================================

  /// Busca todos os itens disponíveis no jogo
  Future<List<Map<String, dynamic>>> getAllItems() async {
    final snapshot = await _db.collection(_itemsCollection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ==========================================
  // SAVES (Progresso do Jogo)
  // ==========================================

  /// Cria um novo slot de save (progresso) para o jogador
  Future<String> createNewSave(String uid) async {
    final saveRef = _db.collection(_savesCollection).doc(); // Gera ID automático
    
    // Busca os dados das ervas iniciais para preencher o inventário corretamente
    final itemsList = await getAllItems();
    final ervaDivina = itemsList.firstWhere((i) => i['id'] == 'erva_divina', orElse: () => {});
    final ervaIra = itemsList.firstWhere((i) => i['id'] == 'erva_ira', orElse: () => {});
    
    final initialInventory = [];
    if (ervaDivina.isNotEmpty) {
      ervaDivina['quantity'] = 1;
      initialInventory.add(ervaDivina);
    }
    if (ervaIra.isNotEmpty) {
      ervaIra['quantity'] = 1;
      initialInventory.add(ervaIra);
    }

    await saveRef.set({
      'saveId': saveRef.id,
      'uid': uid,
      'level': 1,
      'xp': 0,
      'hp': 100,
      'maxHp': 100,
      'inventory': initialInventory, 
      'unlocked_zones': ['CEATEC'], // Área inicial liberada
      'last_location': {'lat': 0.0, 'lon': 0.0},
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Atualiza o usuário com o ID deste novo save (set+merge para não falhar se doc não existir)
    await _db.collection(_usersCollection).doc(uid).set(
      {'activeSaveId': saveRef.id},
      SetOptions(merge: true),
    );

    return saveRef.id;
  }

  /// Salva o progresso do jogo (cria ou atualiza)
  Future<void> updateGameSave(String saveId, Map<String, dynamic> dataToUpdate) async {
    dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();
    // Usa set+merge para criar o documento se não existir
    await _db.collection(_savesCollection).doc(saveId).set(
      dataToUpdate,
      SetOptions(merge: true),
    );
  }

  /// Espelha os dados do jogo no documento do usuário (users/{uid})
  Future<void> updateUserGameData(String uid, Map<String, dynamic> gameData) async {
    await _db.collection(_usersCollection).doc(uid).set(
      {'gameState': gameData},
      SetOptions(merge: true),
    );
  }

  /// Carrega o save atual do jogador
  Future<Map<String, dynamic>?> getActiveSave(String uid) async {
    final userDoc = await _db.collection(_usersCollection).doc(uid).get();
    final activeSaveId = userDoc.data()?['activeSaveId'];

    if (activeSaveId != null) {
      final saveDoc = await _db.collection(_savesCollection).doc(activeSaveId).get();
      return saveDoc.data();
    }
    return null;
  }

  // ==========================================
  // BOSSES (Chefões do Campus)
  // ==========================================

  /// Busca todos os chefões disponíveis
  Future<List<Map<String, dynamic>>> getBosses() async {
    final snapshot = await _db.collection(_bossesCollection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Busca o nome do chefão pelo estágio
  Future<String> getBossNameByEstagio(int estagio) async {
    try {
      final snapshot = await _db.collection(_bossesCollection)
          .where('estagio', isEqualTo: estagio)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return data['nome'] ?? data['name'] ?? 'Chefe Desconhecido';
      }
      
      final stringSnapshot = await _db.collection(_bossesCollection)
          .where('estagio', isEqualTo: estagio.toString())
          .limit(1)
          .get();
      if (stringSnapshot.docs.isNotEmpty) {
        final data = stringSnapshot.docs.first.data();
        return data['nome'] ?? data['name'] ?? 'Chefe Desconhecido';
      }
    } catch (e) {
      print("Erro ao buscar boss: $e");
    }
    
    switch (estagio) {
      case 1: return 'NÚCLEO DE LÓGICA X';
      case 2: return 'MESTRE DAS FINANÇAS';
      case 3: return 'ESFINGE DA LINGUAGEM';
      default: return 'INIMIGO DESCONHECIDO';
    }
  }

  // ==========================================
  // QUIZZES (Desafios Educacionais)
  // ==========================================

  /// Busca um quiz específico baseado na zona ou no chefão
  Future<List<Map<String, dynamic>>> getQuizzesForZone(String zoneName) async {
    final snapshot = await _db.collection(_quizzesCollection)
        .where('zone', isEqualTo: zoneName)
        .get();
        
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Busca todos os quizzes disponíveis
  Future<List<Map<String, dynamic>>> getAllQuizzes() async {
    final snapshot = await _db.collection(_quizzesCollection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
