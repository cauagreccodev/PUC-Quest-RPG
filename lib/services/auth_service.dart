import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  String? get currentUserId => _auth.currentUser?.uid;

  // Login
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return true;
    } catch(e) {
      print('Erro ao fazer login: $e');
      return false;
    }
  }

  // Registro
  Future<bool> register(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      await credential.user!.updateDisplayName(name);

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'uid': credential.user!.uid,
          'activeSaveId': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return true;
    } catch(e) {
      print('Erro ao registrar: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Login Anônimo
  Future<bool> loginWithProvider(String provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInAnonymously();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro no login de provedor: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login com Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'uid': user.uid,
            'activeSaveId': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro no login com Google: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}