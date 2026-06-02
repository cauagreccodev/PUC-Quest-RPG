import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../services/auth_service.dart';
import '../main.dart'; // Para acessar a GameScreen

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF2C2C2C),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE0C9A6)),
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
  bool isLogin = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _showMessage(String title, String message, ContentType type) {
    if (!mounted) return;

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: type, // Success, Failure, Help ou Warning
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar() // Esconde a anterior se o jogador clicar duas vezes
      ..showSnackBar(snackBar);
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final success = await _authService.loginWithProvider('Google');

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        _showMessage(
          'O feitiço falhou!',
          'Falha ao tentar entrar com o Google.',
          ContentType.failure,
        );
      }
    }
  }

  void _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    final success = await _authService.loginWithProvider('Facebook');

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        _showMessage(
          'O feitiço falhou!',
          'Falha ao tentar entrar com o Facebook.',
          ContentType.failure,
        );
      }
    }
  }

  void _handleAnonymousLogin() async {
    setState(() => _isLoading = true);
    final success = await _authService.loginWithProvider('Visitante');

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        _showMessage(
          'O feitiço falhou!',
          'Falha ao tentar entrar como visitante.',
          ContentType.failure,
        );
      }
    }
  }

  Future<void> _handleAuth() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!isLogin && name.isEmpty) {
      _showMessage(
        'Ops!',
        'Informe o nome do personagem.',
        ContentType.warning,
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Ops!',
        'Preencha os campos de e-mail e senha.',
        ContentType.warning,
      );
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Ops!', 'Digite um e-mail válido.', ContentType.warning);
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Ops!',
        'A senha deve ter no mínimo 6 caracteres.',
        ContentType.warning,
      );
      return;
    }

    if (!isLogin && password != confirmPassword) {
      _showMessage('Ops!', 'As senhas não coincidem.', ContentType.warning);
      return;
    }

    setState(() => _isLoading = true);

    final success = isLogin
        ? await _authService.login(email, password)
        : await _authService.register(email, password, name);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      _showMessage(
        'Glória!',
        isLogin ? 'Login realizado com sucesso!' : 'Conta criada com sucesso!',
        ContentType.success,
      );
      return;
    } else {
      _showMessage(
        'O feitiço falhou!',
        isLogin
            ? 'Não foi possível fazer login. Verifique suas credenciais.'
            : 'Não foi possível criar a conta. E-mail talvez já cadastrado.',
        ContentType.failure,
      );
    }
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
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                // Title
                Text(
                  isLogin ? 'BEM-VINDO' : 'NOVO HERÓI',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE0C9A6),
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isLogin ? 'Entre na Taverna' : 'Forje seu destino no reino',
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    color: const Color(0xFF8B4513),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                if (!isLogin) ...[
                  _BuildTextField(
                    controller: _nameController,
                    label: 'Nome do Personagem',
                    maxLength: 10,
                  ),
                  const SizedBox(height: 16),
                ],

                _BuildTextField(
                  controller: _emailController,
                  label: 'E-mail do Aventureiro',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _BuildTextField(
                  controller: _passwordController,
                  label: 'Chave de Acesso',
                  obscureText: true,
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  _BuildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Chave de Acesso',
                    obscureText: true,
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double
                      .infinity, // <-- Força o botão a esticar o máximo possível
                  child: ElevatedButton(
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
                ),

                const SizedBox(height: 24),

                // SEPARADOR "OU"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: const Color(0xFF8B4513).withOpacity(0.5),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OU',
                        style: GoogleFonts.merriweather(
                          color: const Color(0xFF8B4513),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: const Color(0xFF8B4513).withOpacity(0.5),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // BOTÕES SOCIAIS
                Row(
                  children: [
                    Expanded(
                      child: _BuildSocialButton(
                        icon: Icons.g_mobiledata,
                        label: 'Google',
                        onPressed: _handleGoogleLogin,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _BuildSocialButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onPressed: _handleFacebookLogin,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // BOTÃO VISITANTE
                TextButton(
                  onPressed: _isLoading ? null : _handleAnonymousLogin,
                  child: Text(
                    'Entrar como Visitante',
                    style: GoogleFonts.merriweather(
                      color: const Color(0xFFE0C9A6).withAlpha(150),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                // ALTERNAR MODO (LOGIN/REGISTRO)
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
}

class _BuildTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;

  const _BuildTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      style: GoogleFonts.merriweather(color: const Color(0xFFE0C9A6)),
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
          borderSide: BorderSide(color: Color(0xFF8B4513)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8B4513)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF0E68C), width: 1.5),
        ),
      ),
    );
  }
}

class _BuildSocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _BuildSocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFEBE1C9), size: 24),
        label: Text(
          label,
          style: TextStyle(
            color: const Color(0xFFEBE1C9),
            fontFamily: 'serif',
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: const Color(0xFFA66232).withOpacity(0.5),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
