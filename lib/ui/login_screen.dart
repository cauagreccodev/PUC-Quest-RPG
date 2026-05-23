import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _handleAuth() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!isLogin && name.isEmpty) {
      _showMessage('Informe o nome do personagem.', Colors.orange);
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Preencha e-mail e senha.', Colors.orange);
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Digite um e-mail válido.', Colors.orange);
      return;
    }

    if (password.length < 6) {
      _showMessage('A senha deve ter no mínimo 6 caracteres.', Colors.orange);
      return;
    }

    if (!isLogin && password != confirmPassword) {
      _showMessage('As senhas não coincidem.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();

    final success = isLogin
        ? await authService.login(email, password)
        : await authService.register(email, password, name);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      _showMessage(
        isLogin
            ? 'Login realizado com sucesso!'
            : 'Conta criada com sucesso!',
        Colors.green,
      );
      return;
    }

    _showMessage(
      isLogin
          ? 'Não foi possível fazer login. Verifique suas credenciais.'
          : 'Não foi possível criar a conta. E-mail talvez já cadastrado.',
      Colors.red,
    );
  }

  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isLogin ? 'BEM-VINDO' : 'NOVO HERÓI',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE0C9A6),
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'Entre na Taverna'
                      : 'Forje seu destino no reino',
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    color: const Color(0xFF8B4513),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  '',
                  style: GoogleFonts.merriweather(
                    fontSize: 12,
                    color: const Color(0xFFE0C9A6).withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (!isLogin) ...[
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nome do Personagem',
                  ),
                  const SizedBox(height: 16),
                ],

                _buildTextField(
                  controller: _emailController,
                  label: 'E-mail do Aventureiro',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Chave de Acesso',
                  obscureText: true,
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Chave de Acesso',
                    obscureText: true,
                  ),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: const Color(0xFFF0E68C),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(
                      color: Color(0xFFF0E68C),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFFF0E68C),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLogin ? 'ENTRAR' : 'CRIAR PERSONAGEM',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  child: Text(
                    isLogin
                        ? 'Deseja criar um novo herói?'
                        : 'Já possui um herói? Volte aqui.',
                    style: GoogleFonts.merriweather(
                      color: const Color(0xFFE0C9A6).withAlpha(150),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      style: GoogleFonts.merriweather(
        color: const Color(0xFFE0C9A6),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.merriweather(
          color: const Color(0xFF8B4513),
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFF3D3D3D),
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF8B4513),
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF8B4513),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFF0E68C),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}