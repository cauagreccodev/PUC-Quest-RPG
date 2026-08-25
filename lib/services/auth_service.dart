import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/firestore_service.dart';

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
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Recria o perfil no Firestore caso tenha sido deletado manualmente
      if (credential.user != null) {
        await FirestoreService().createUserProfile(credential.user!);
      }
      notifyListeners();
      return true;
    } catch(e) {
      print('Erro ao fazer login: $e');
      return false;
    }
  }

  // Registro - retorna null em caso de sucesso, ou uma String com o código do erro
  Future<String?> registerWithError(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      await credential.user!.updateDisplayName(name);

      if (credential.user != null) {
        await FirestoreService().createUserProfile(credential.user!);
      }

      notifyListeners();
      return null; // sucesso
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException ao registrar: ${e.code}');
      return e.code; // ex: 'email-already-in-use'
    } catch(e) {
      print('Erro ao registrar: $e');
      return 'unknown';
    }
  }

  // Mantido por compatibilidade (chama registerWithError internamente)
  Future<bool> register(String email, String password, String name) async {
    final error = await registerWithError(email, password, name);
    return error == null;
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
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user != null) {
        // Usuário anônimo (Visitante) não salva perfil no Firebase,
        // jogará apenas localmente no SharedPreferences.
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException no login de provedor: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
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
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '106292251398-s8dl9m4o5jvppd0669m8r6tu4qrpm3j6.apps.googleusercontent.com' : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

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
        // Cria perfil e save no Firestore se ainda não existir
        await FirestoreService().createUserProfile(user);
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

  // ==========================================
  // VINCULAÇÃO DE CONTAS (ACCOUNT LINKING)
  // ==========================================

  Future<bool> linkWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '106292251398-s8dl9m4o5jvppd0669m8r6tu4qrpm3j6.apps.googleusercontent.com' : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
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

      // Vincular a credencial ao usuário logado atual
      final userCredential = await _auth.currentUser?.linkWithCredential(credential);
      final user = userCredential?.user;

      if (user != null) {
        // Garantir que exista um perfil no Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Jogador',
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
      print('Erro ao vincular com Google: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> linkWithEmailPassword(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      
      final userCredential = await _auth.currentUser?.linkWithCredential(credential);
      final user = userCredential?.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await FirestoreService().createUserProfile(user);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao vincular com Email: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Simulação Visual do Facebook
  bool isFacebookLinkedMock = false;

  Future<bool> linkWithFacebookVisualOnly() async {
    _isLoading = true;
    notifyListeners();
    
    // Simula uma espera de rede
    await Future.delayed(const Duration(seconds: 1));
    
    // O usuário pediu pra ser apenas visual. Então retornamos true sem fazer alterações reais no Firebase.
    isFacebookLinkedMock = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }
}