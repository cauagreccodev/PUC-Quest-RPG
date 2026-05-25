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

    // 2. Populando Quizzes
    final quizzesSnap = await _db.collection(_quizzesCollection).limit(1).get();
    if (quizzesSnap.docs.isEmpty) {
      final quizzes = [
        {
          'id': 'quiz_1',
          'zone': 'CEATEC',
          'question': 'Qual o paradigma principal da linguagem Java?',
          'options': ['Procedural', 'Orientação a Objetos', 'Funcional', 'Lógico'],
          'correctAnswerIndex': 1,
          'difficulty': 'Fácil'
        },
        {
          'id': 'quiz_2',
          'zone': 'CEA',
          'question': 'O que significa ROI?',
          'options': ['Retorno sobre Investimento', 'Risco Operacional Interno', 'Registro de Obrigações', 'Receita Operacional Integrada'],
          'correctAnswerIndex': 0,
          'difficulty': 'Fácil'
        },
      ];
      for (var quiz in quizzes) {
        await _db.collection(_quizzesCollection).doc(quiz['id'].toString()).set(quiz);
      }
      print("✅ Quizzes inseridos no banco automaticamente!");
    }

    // 3. Populando Itens Básicos do Jogo
    final itemsSnap = await _db.collection(_itemsCollection).limit(1).get();
    if (itemsSnap.docs.isEmpty) {
      final items = [
        {'id': 'item_cura', 'name': 'Código de Cura', 'description': 'Restaura 2 pontos de vida (+2 ❤️)', 'type': 'healing', 'value': 2},
        {'id': 'item_dica', 'name': 'Carta Dica', 'description': 'Auxílio na resolução de bugs ou desafios lógicos.', 'type': 'support', 'value': 1},
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

  // ==========================================
  // SAVES (Progresso do Jogo)
  // ==========================================

  /// Cria um novo slot de save (progresso) para o jogador
  Future<String> createNewSave(String uid) async {
    final saveRef = _db.collection(_savesCollection).doc(); // Gera ID automático
    
    await saveRef.set({
      'saveId': saveRef.id,
      'uid': uid,
      'level': 1,
      'xp': 0,
      'hp': 100,
      'maxHp': 100,
      'inventory': ['Carta Dica'], // Mantido para compatibilidade, o PlayerStateModel lidará com as chaves
      'unlocked_zones': ['CEATEC'], // Área inicial liberada
      'last_location': {'lat': 0.0, 'lon': 0.0},
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Atualiza o usuário com o ID deste novo save
    await _db.collection(_usersCollection).doc(uid).update({
      'activeSaveId': saveRef.id,
    });

    return saveRef.id;
  }

  /// Salva o progresso do jogo (Update)
  Future<void> updateGameSave(String saveId, Map<String, dynamic> dataToUpdate) async {
    dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(_savesCollection).doc(saveId).update(dataToUpdate);
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
