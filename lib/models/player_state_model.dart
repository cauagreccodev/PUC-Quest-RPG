import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GameItem {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji ou nome do asset

  GameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
      };

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        icon: json['icon'],
      );
}

class PlayerStateModel extends ChangeNotifier {
  int _hp;
  int _maxHp;
  String _currentPhase;
  List<GameItem> _inventory;
  List<String> _defeatedPhases;

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
        _defeatedPhases = defeatedPhases ?? [];

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
    _currentPhase = phase;
    notifyListeners();
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

  Future<void> saveGame({String? token, String? baseUrl}) async {
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
        print('Erro ao salvar no servidor: $e');
      }
    }
  }

  Future<void> loadGame({String? token, String? baseUrl}) async {
    bool loadedFromServer = false;

    if (token != null && baseUrl != null) {
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
        print('Erro ao carregar do servidor: $e');
      }
    }

    if (!loadedFromServer) {
      final prefs = await SharedPreferences.getInstance();
      _hp = prefs.getInt('hp') ?? 100;
      _maxHp = prefs.getInt('maxHp') ?? 100;
      _currentPhase = prefs.getString('currentPhase') ?? 'Início';
      final itemsJson = prefs.getStringList('inventory') ?? [];
      _inventory = itemsJson
          .map((s) => GameItem.fromJson(jsonDecode(s)))
          .toList();
      _defeatedPhases = prefs.getStringList('defeatedPhases') ?? [];
    }

    notifyListeners();
  }
}

