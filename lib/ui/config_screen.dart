import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_settings_model.dart';
import '../models/player_state_model.dart';
import '../services/auth_service.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(color: Color(0xFFF0E68C), fontFamily: 'Courier', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2A1B0A),
        iconTheme: const IconThemeData(color: Color(0xFFF0E68C)),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1800), Color(0xFF1A0A00), Color(0xFF160800)],
          ),
          border: Border.all(color: const Color(0xFF8B4513), width: 4),
        ),
        child: Consumer2<AudioSettingsModel, AuthService>(
          builder: (context, audioSettings, authService, child) {
            final isGuest = authService.currentUser?.isAnonymous == true;
            final userProviders = authService.currentUser?.providerData.map((e) => e.providerId).toList() ?? [];
            final isGoogleLinked = userProviders.contains('google.com');
            final isFacebookLinked = authService.isFacebookLinkedMock;
            
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'ÁUDIO E SOM',
                    style: TextStyle(
                      color: Color(0xFFF0E68C),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Volume Geral (SFX)
                _buildVolumeControl(
                  context: context,
                  title: 'Volume Geral (Efeitos)',
                  icon: Icons.volume_up_rounded,
                  isMuted: audioSettings.isSfxMuted,
                  volume: audioSettings.sfxVolume,
                  onMuteToggle: () {
                    audioSettings.toggleSfxMute();
                    audioSettings.playButtonSound();
                  },
                  onVolumeChanged: (val) {
                    audioSettings.setSfxVolume(val);
                  },
                  onChangeEnd: (val) {
                    audioSettings.playButtonSound();
                  },
                ),

                const SizedBox(height: 30),

                // Volume da Música
                _buildVolumeControl(
                  context: context,
                  title: 'Música de Fundo',
                  icon: Icons.music_note_rounded,
                  isMuted: audioSettings.isMusicMuted,
                  volume: audioSettings.musicVolume,
                  onMuteToggle: () {
                    audioSettings.toggleMusicMute();
                    audioSettings.playButtonSound();
                  },
                  onVolumeChanged: (val) {
                    audioSettings.setMusicVolume(val);
                  },
                ),

                const SizedBox(height: 40),
                const Divider(color: Color(0xFF8B4513), thickness: 2),
                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'GERENCIAMENTO DE CONTA',
                    style: TextStyle(
                      color: Color(0xFFF0E68C),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                if (isGuest) ...[
                  _buildAccountButton(
                    label: 'Registrar Conta do Jogo',
                    icon: Icons.app_registration_rounded,
                    color: const Color(0xFF2E7D32),
                    borderColor: const Color(0xFF1B5E20),
                    onPressed: () {
                      audioSettings.playButtonSound();
                      _showEmailRegistrationDialog(context, authService);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                _buildAccountButton(
                  label: isGoogleLinked ? 'Google Vinculado' : 'Vincular com Google',
                  icon: isGoogleLinked ? Icons.check_circle_outline_rounded : Icons.g_mobiledata_rounded,
                  color: isGoogleLinked ? const Color(0xFF1B5E20) : const Color(0xFF1565C0),
                  borderColor: isGoogleLinked ? const Color(0xFF0D3311) : const Color(0xFF0D47A1),
                  onPressed: isGoogleLinked ? () {
                    audioSettings.playButtonSound();
                  } : () async {
                    audioSettings.playButtonSound();
                    final success = await authService.linkWithGoogle();
                    if (success && context.mounted) {
                      final pState = Provider.of<PlayerStateModel>(context, listen: false);
                      await pState.saveGame(uid: authService.currentUser?.isAnonymous == true ? null : authService.currentUserId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conta do Google vinculada com sucesso!')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildAccountButton(
                  label: isFacebookLinked ? 'Facebook Vinculado' : 'Vincular com Facebook',
                  icon: isFacebookLinked ? Icons.check_circle_outline_rounded : Icons.facebook_rounded,
                  color: isFacebookLinked ? const Color(0xFF1B5E20) : const Color(0xFF0277BD),
                  borderColor: isFacebookLinked ? const Color(0xFF0D3311) : const Color(0xFF01579B),
                  onPressed: isFacebookLinked ? () {
                    audioSettings.playButtonSound();
                  } : () async {
                    audioSettings.playButtonSound();
                    final success = await authService.linkWithFacebookVisualOnly();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conta do Facebook vinculada com sucesso!')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Botão Sair da Conta (Alterar Conta)
                _buildAccountButton(
                  label: 'Alterar Conta / Sair',
                  icon: Icons.exit_to_app_rounded,
                  color: const Color(0xFF5A0A0A),
                  borderColor: const Color(0xFF8B1A1A),
                  onPressed: () async {
                    audioSettings.playButtonSound();
                    // Salva antes de sair da conta
                    if (context.mounted) {
                      final pState = Provider.of<PlayerStateModel>(context, listen: false);
                      await pState.saveGame(uid: authService.currentUser?.isAnonymous == true ? null : authService.currentUserId);
                    }
                    await authService.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVolumeControl({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isMuted,
    required double volume,
    required VoidCallback onMuteToggle,
    required ValueChanged<double> onVolumeChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B4513), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF0E68C), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              InkWell(
                onTap: onMuteToggle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isMuted ? Colors.redAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMuted ? Colors.redAccent : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: isMuted ? Colors.redAccent : Colors.green,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFFF0E68C),
            inactiveColor: Colors.grey[800],
            onChanged: isMuted ? null : onVolumeChanged,
            onChangeEnd: isMuted ? null : onChangeEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showEmailRegistrationDialog(BuildContext context, AuthService authService) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1B0A),
          title: const Text('Registrar Conta', style: TextStyle(color: Color(0xFFF0E68C), fontFamily: 'Courier')),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Text('Vincule seu progresso atual a uma conta de email.', style: TextStyle(color: Colors.white70, fontSize: 12)),
               const SizedBox(height: 16),
               TextField(
                 controller: nameController,
                 style: const TextStyle(color: Colors.white),
                 decoration: const InputDecoration(
                   labelText: 'Nome do Herói',
                   labelStyle: TextStyle(color: Colors.grey),
                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B4513))),
                   focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFF0E68C))),
                 ),
               ),
               const SizedBox(height: 12),
               TextField(
                 controller: emailController,
                 style: const TextStyle(color: Colors.white),
                 decoration: const InputDecoration(
                   labelText: 'E-mail',
                   labelStyle: TextStyle(color: Colors.grey),
                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B4513))),
                   focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFF0E68C))),
                 ),
               ),
               const SizedBox(height: 12),
               TextField(
                 controller: passwordController,
                 style: const TextStyle(color: Colors.white),
                 obscureText: true,
                 decoration: const InputDecoration(
                   labelText: 'Senha',
                   labelStyle: TextStyle(color: Colors.grey),
                   enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B4513))),
                   focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFF0E68C))),
                 ),
               ),
             ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final name = nameController.text.trim();

                if (email.isEmpty || password.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
                  return;
                }

                Navigator.pop(ctx);
                
                final success = await authService.linkWithEmailPassword(email, password, name);
                if (success && context.mounted) {
                  final pState = Provider.of<PlayerStateModel>(context, listen: false);
                  await pState.saveGame(uid: authService.currentUser?.isAnonymous == true ? null : authService.currentUserId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conta registrada com sucesso!')),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Falha ao vincular conta. Email já existe?')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text('Registrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
