import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String email;
  final String password;
  final String name;

  AuthUser({required this.email, required this.password, required this.name});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    email: json['email'],
    password: json['password'],
    name: json['name'],
  );
}

class AuthService extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = true;

  AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      _currentUser = AuthUser.fromJson(jsonDecode(userJson));
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersList = prefs.getStringList('registered_users') ?? [];

    for (var userStr in usersList) {
      final user = AuthUser.fromJson(jsonDecode(userStr));
      if (user.email == email && user.password == password) {
        _currentUser = user;
        await prefs.setString('auth_user', jsonEncode(user.toJson()));
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final usersList = prefs.getStringList('registered_users') ?? [];

    // Check if user already exists
    for (var userStr in usersList) {
      final user = AuthUser.fromJson(jsonDecode(userStr));
      if (user.email == email) return false;
    }

    final newUser = AuthUser(email: email, password: password, name: name);
    usersList.add(jsonEncode(newUser.toJson()));
    await prefs.setStringList('registered_users', usersList);
    
    // Auto login
    _currentUser = newUser;
    await prefs.setString('auth_user', jsonEncode(newUser.toJson()));
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> loginWithProvider(String provider) async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    final newUser = AuthUser(
      email: '${provider.toLowerCase()}@social.com',
      password: '',
      name: 'Herói do $provider',
    );
    
    _currentUser = newUser;
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
