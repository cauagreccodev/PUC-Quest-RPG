import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firestore_service.dart';

class GameItem {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji ou nome do asset
  final String type; // 'key', 'healing', 'boost', 'support', etc.
  final int value; // Valor de cura ou multiplicador
  int quantity;

  GameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.type = 'support',
    this.value = 0,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'type': type,
        'value': value,
        'quantity': quantity,
      };

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        icon: json['icon'],
        type: json['type'] ?? 'support',
        value: json['value'] ?? 0,
        quantity: json['quantity'] ?? 1,
      );
}

class PlayerStateModel extends ChangeNotifier {
  int _hp;
  int _maxHp;
  String _currentPhase;
  List<GameItem> _inventory;
  List<String> _defeatedPhases;

  static const Map<int, Map<String, String>> keyData = {
    1: {'id': 'key_1', 'name': 'Chave do Calouro', 'description': 'Acesso à Praça de Alimentação', 'icon': '🔑'},
    2: {'id': 'key_2', 'name': 'Chave do Conhecimento', 'description': 'Acesso à Biblioteca (Redes)', 'icon': '🗝️'},
    3: {'id': 'key_3', 'name': 'Chave da Lógica', 'description': 'Acesso ao H14 (A02)', 'icon': '🔐'},
    4: {'id': 'key_4', 'name': 'Chave do Portal', 'description': 'Acesso à Entrada do H15', 'icon': '🗝️'},
    5: {'id': 'key_5', 'name': 'Chave do Diploma', 'description': 'Acesso ao H15 (Jogos Digitais)', 'icon': '🎓'},
  };

  PlayerStateModel({
    int hp = 100,
    int maxHp = 100,
    String currentPhase = 'Início',
    List<GameItem>? inventory,
    List<String>? defeatedPhases,
  })  : _hp = hp,
        _maxHp = maxHp,
        _currentPhase = currentPhase,
        _inventory = inventory ?? [],
        _defeatedPhases = defeatedPhases ?? [] {
    grantInitialKeyIfNeeded();
  }

  bool hasKeyForEstagio(int estagio) {
    if (estagio < 1 || estagio > 5) return true; // Se for fora de 1-5, não bloqueia por chave
    final keyId = keyData[estagio]!['id'];
    return _inventory.any((item) => item.id == keyId);
  }

  void grantNextKey(int currentEstagio) {
    int nextEstagio = currentEstagio + 1;
    if (nextEstagio <= 5) {
      final keyInfo = keyData[nextEstagio]!;
      if (!hasKeyForEstagio(nextEstagio)) {
        addItem(GameItem(
          id: keyInfo['id']!,
          name: keyInfo['name']!,
          description: keyInfo['description']!,
          icon: keyInfo['icon']!,
        ));
      }
    }
  }

  void grantInitialKeyIfNeeded() {
    if (!hasKeyForEstagio(1)) {
      final keyInfo = keyData[1]!;
      addItem(GameItem(
        id: keyInfo['id']!,
        name: keyInfo['name']!,
        description: keyInfo['description']!,
        icon: keyInfo['icon']!,
        type: 'key',
      ));
    }
  }

  void grantItem(GameItem item, int amount) {
    final existingIndex = _inventory.indexWhere((i) => i.id == item.id);
    if (existingIndex != -1) {
      _inventory[existingIndex].quantity += amount;
    } else {
      item.quantity = amount;
      _inventory.add(item);
    }
    notifyListeners();
  }

  bool useItem(String itemId) {
    final existingIndex = _inventory.indexWhere((i) => i.id == itemId);
    if (existingIndex != -1) {
      if (_inventory[existingIndex].quantity > 0) {
        _inventory[existingIndex].quantity -= 1;
        
        // Remove do inventário se a quantidade chegar a zero (opcional, ou pode manter com zero)
        // Optamos por remover para limpar o inventário
        if (_inventory[existingIndex].quantity <= 0) {
          _inventory.removeAt(existingIndex);
        }
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  int get hp => _hp;
  int get maxHp => _maxHp;
  String get currentPhase => _currentPhase;
  List<GameItem> get inventory => List.unmodifiable(_inventory);

  bool isPhaseDefeated(String phaseId) => _defeatedPhases.contains(phaseId);

  void markPhaseDefeated(String phaseId) {
    if (!_defeatedPhases.contains(phaseId)) {
      _defeatedPhases.add(phaseId);
      notifyListeners();
    }
  }

  void setPhase(String phase) {
    if (_currentPhase != phase) {
      _currentPhase = phase;
      notifyListeners();
    }
  }

  void takeDamage(int amount) {
    if (_hp > 0) {
      _hp -= amount;
      if (_hp < 0) _hp = 0;
      notifyListeners();
    }
  }

  void heal(int amount) {
    if (_hp < _maxHp) {
      _hp += amount;
      if (_hp > _maxHp) _hp = _maxHp;
      notifyListeners();
    }
  }

  void addItem(GameItem item) {
    _inventory.add(item);
    notifyListeners();
  }

  void removeItem(String itemId) {
    _inventory.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  Future<void> saveGame({String? token, String? baseUrl, String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hp', _hp);
    await prefs.setInt('maxHp', _maxHp);
    await prefs.setString('currentPhase', _currentPhase);
    final itemsJson = _inventory.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList('inventory', itemsJson);
    await prefs.setStringList('defeatedPhases', _defeatedPhases);

    if (token != null && baseUrl != null) {
      try {
        await http.put(
          Uri.parse('$baseUrl/api/game/state'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'hp': _hp,
            'maxHp': _maxHp,
            'currentPhase': _currentPhase,
            'inventory': _inventory.map((i) => i.toJson()).toList(),
            'defeatedPhases': _defeatedPhases,
          }),
        );
      } catch (e) {
        print('Erro ao salvar no servidor HTTP: $e');
      }
    }

    if (uid != null) {
      try {
        final db = FirestoreService();
        final user = FirebaseAuth.instance.currentUser;
        
        // Verifica e recria o perfil no Firestore se foi deletado manualmente
        if (user != null && !user.isAnonymous) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (!userDoc.exists) {
             print('Recriando perfil de usuário ausente no Firestore...');
             await db.createUserProfile(user);
          }
        }

        final gameData = {
          'hp': _hp,
          'maxHp': _maxHp,
          'currentPhase': _currentPhase,
          'inventory': _inventory.map((i) => i.toJson()).toList(),
          'defeatedPhases': _defeatedPhases,
          'lastSavedAt': DateTime.now().toIso8601String(),
        };

        var save = await db.getActiveSave(uid);
        // Se não existe save no Firestore, cria um agora
        if (save == null) {
          await db.createNewSave(uid);
          save = await db.getActiveSave(uid);
        }
        if (save != null) {
          final saveId = save['saveId'] as String;
          // Salva na coleção saves
          await db.updateGameSave(saveId, gameData);
        }

        // Espelha os dados do jogo também na coleção users
        await db.updateUserGameData(uid, gameData);
      } catch (e) {
        print('Erro ao salvar no Firestore: $e');
      }
    }
  }

  Future<void> loadGame({String? token, String? baseUrl, String? uid}) async {
    bool loadedFromServer = false;

    if (uid != null) {
      try {
        final db = FirestoreService();
        final save = await db.getActiveSave(uid);
        if (save != null) {
          _hp = save['hp'] ?? 100;
          _maxHp = save['maxHp'] ?? 100;
          _currentPhase = save['currentPhase'] ?? 'Início';
          
          if (save['inventory'] != null) {
            _inventory = (save['inventory'] as List)
                .map((i) => GameItem.fromJson(i as Map<String, dynamic>))
                .toList();
          }
          
          if (save['defeatedPhases'] != null) {
            _defeatedPhases = List<String>.from(save['defeatedPhases']);
          }
          loadedFromServer = true;
        }
      } catch (e) {
        print('Erro ao carregar do Firestore: $e');
      }
    }

    if (!loadedFromServer && token != null && baseUrl != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/game/state'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null && data.isNotEmpty) {
            _hp = data['hp'] ?? 100;
            _maxHp = data['maxHp'] ?? 100;
            _currentPhase = data['currentPhase'] ?? 'Início';
            
            if (data['inventory'] != null) {
              _inventory = (data['inventory'] as List)
                  .map((i) => GameItem.fromJson(i))
                  .toList();
            }
            
            if (data['defeatedPhases'] != null) {
              _defeatedPhases = List<String>.from(data['defeatedPhases']);
            }
            loadedFromServer = true;
          }
        }
      } catch (e) {
        print('Erro ao carregar do servidor HTTP: $e');
      }
    }

    if (!loadedFromServer) {
      final prefs = await SharedPreferences.getInstance();
      bool isNewGame = prefs.getInt('hp') == null;
      
      _hp = prefs.getInt('hp') ?? 100;
      _maxHp = prefs.getInt('maxHp') ?? 100;
      _currentPhase = prefs.getString('currentPhase') ?? 'Início';
      final itemsJson = prefs.getStringList('inventory') ?? [];
      _inventory = itemsJson
          .map((s) => GameItem.fromJson(jsonDecode(s)))
          .toList();
      _defeatedPhases = prefs.getStringList('defeatedPhases') ?? [];
      
      if (isNewGame) {
        grantItem(GameItem(
          id: 'erva_divina',
          name: 'Erva Divina',
          description: 'Recupera 40 HP, mas consome seu turno em batalha.',
          icon: '🌿',
          type: 'healing',
          value: 40,
        ), 1);
        grantItem(GameItem(
          id: 'erva_ira',
          name: 'Erva da Ira',
          description: 'Dobra o dano se acertar, mas você toma o dobro se errar! Não consome turno.',
          icon: '🔥',
          type: 'boost',
          value: 2,
        ), 1);
      }
    }
    
    grantInitialKeyIfNeeded(); // Garante que terá a chave 1 se não tiver nenhuma

    Future.delayed(Duration.zero, () {
      notifyListeners();
    });
  }
}

