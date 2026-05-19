import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../main.dart'; // Para acessar a GameScreen
// Para o teste do estágio 1

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF2A2A2A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFB5651D)),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const GameScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Cores do Tema da Imagem
  final Color bgColor = const Color(0xFF2A2A2A);
  final Color copperColor = const Color(0xFFA66232); // Cor dos textos laranja/marrom e bordas
  final Color creamColor = const Color(0xFFEBE1C9); // Cor do texto BEM-VINDO e botões
  final Color inputBgColor = const Color(0xFF333333); // Fundo dos campos de texto
  final Color buttonBgColor = const Color(0xFF8B4A23); // Fundo do botão ENTRAR
  final Color buttonBorderColor = const Color(0xFFD4AF37); // Borda dourada do botão ENTRAR

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final success = await _authService.loginWithProvider('Google');
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        _showMessage('Falha no Google.');
      }
    }
  }

  void _handleAnonymousLogin() async {
    setState(() => _isLoading = true);
    final success = await _authService.loginWithProvider('Visitante');
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        _showMessage('O feitiço falhou. Verifique sua conexão.');
      }
    }
  }

  void _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    final success = await _authService.loginWithProvider('Facebook');
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        _showMessage('Falha no Facebook.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        content: Text(
          message,
          style: TextStyle(color: creamColor, fontFamily: 'serif'),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: copperColor),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título
                Text(
                  'BEM-VINDO',
                  style: TextStyle(
                    fontFamily: 'serif', // Usando serif para dar o ar medieval da imagem
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: creamColor,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtítulo
                Text(
                  'Entre na Taverna',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: copperColor,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo de E-mail
                _buildTextField(hint: 'E-mail do Aventureiro'),
                const SizedBox(height: 16),
                
                // Campo de Senha
                _buildTextField(hint: 'Chave de Acesso', isPassword: true),
                const SizedBox(height: 24),

                // Botão ENTRAR
                if (_isLoading)
                  CircularProgressIndicator(color: creamColor)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleAnonymousLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: buttonBorderColor, width: 1.5),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'ENTRAR',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: creamColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(Entrar como Visitante)',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      color: copperColor,
                    ),
                  ),
                
                const SizedBox(height: 20),

                // Divisor "OU"
                Row(
                  children: [
                    Expanded(child: Divider(color: copperColor.withOpacity(0.5), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          color: copperColor,
                          fontFamily: 'serif',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: copperColor.withOpacity(0.5), thickness: 1)),
                  ],
                ),
                
                const SizedBox(height: 32),

                // Botões Sociais
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        icon: Icons.g_mobiledata,
                        label: 'Google',
                        onPressed: _handleGoogleLogin,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onPressed: _handleFacebookLogin,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // Botão de Teste (Pular para o Jogo Completo)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: creamColor, width: 1.5),
                      ),
                    ),
                    child: Text(
                      'ENTRAR COMO TESTER (Jogo)',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: creamColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Criar novo herói
                InkWell(
                  onTap: () {
                    _showMessage('A guilda de novos heróis abrirá em breve!');
                  },
                  child: Text(
                    'Deseja criar um novo herói?',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      color: creamColor,
                      decoration: TextDecoration.underline,
                      decorationColor: creamColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      style: TextStyle(color: copperColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: copperColor.withOpacity(0.6), fontFamily: 'serif'),
        filled: true,
        fillColor: inputBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: copperColor.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: copperColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: creamColor, size: 24),
        label: Text(
          label,
          style: TextStyle(
            color: creamColor,
            fontFamily: 'serif',
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: copperColor.withOpacity(0.5), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
