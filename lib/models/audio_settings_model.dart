import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/firestore_service.dart';

class AudioSettingsModel extends ChangeNotifier {
  static const String _musicVolumeKey = 'music_volume';
  static const String _sfxVolumeKey = 'sfx_volume';
  static const String _musicMutedKey = 'music_muted';
  static const String _sfxMutedKey = 'sfx_muted';

  double _musicVolume = 0.3;
  double _sfxVolume = 0.5;
  bool _isMusicMuted = false;
  bool _isSfxMuted = false;

  String? _uid;
  final FirestoreService _dbService = FirestoreService();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  AudioSettingsModel() {
    _sfxPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ));
    AudioPlayer.global.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ));
    _loadSettingsLocally();
  }

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get isMusicMuted => _isMusicMuted;
  bool get isSfxMuted => _isSfxMuted;

  double get effectiveMusicVolume => _isMusicMuted ? 0.0 : _musicVolume;
  double get effectiveSfxVolume => _isSfxMuted ? 0.0 : _sfxVolume;

  void updateUser(String? uid) {
    if (_uid != uid) {
      _uid = uid;
      if (uid != null) {
        _loadSettingsFromFirebase();
      }
    }
  }

  Future<void> _loadSettingsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.3;
    _sfxVolume = prefs.getDouble(_sfxVolumeKey) ?? 0.5;
    _isMusicMuted = prefs.getBool(_musicMutedKey) ?? false;
    _isSfxMuted = prefs.getBool(_sfxMutedKey) ?? false;
    notifyListeners();
  }

  Future<void> _loadSettingsFromFirebase() async {
    if (_uid == null) return;
    final fbData = await _dbService.getAudioSettings(_uid!);
    if (fbData != null) {
      _musicVolume = fbData['musicVolume'] ?? 0.3;
      _sfxVolume = fbData['sfxVolume'] ?? 0.5;
      _isMusicMuted = fbData['isMusicMuted'] ?? false;
      _isSfxMuted = fbData['isSfxMuted'] ?? false;
      notifyListeners();
      
      // Save them locally too so next start is fast
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_musicVolumeKey, _musicVolume);
      await prefs.setDouble(_sfxVolumeKey, _sfxVolume);
      await prefs.setBool(_musicMutedKey, _isMusicMuted);
      await prefs.setBool(_sfxMutedKey, _isSfxMuted);
    }
  }

  Future<void> _syncToFirebase() async {
    if (_uid == null) return;
    await _dbService.updateAudioSettings(_uid!, {
      'musicVolume': _musicVolume,
      'sfxVolume': _sfxVolume,
      'isMusicMuted': _isMusicMuted,
      'isSfxMuted': _isSfxMuted,
    });
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, volume);
    _syncToFirebase();
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sfxVolumeKey, volume);
    _syncToFirebase();
  }

  Future<void> toggleMusicMute() async {
    _isMusicMuted = !_isMusicMuted;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicMutedKey, _isMusicMuted);
    _syncToFirebase();
  }

  Future<void> toggleSfxMute() async {
    _isSfxMuted = !_isSfxMuted;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxMutedKey, _isSfxMuted);
    _syncToFirebase();
  }

  /// Toca o som genérico de botão se não estiver mutado.
  Future<void> playButtonSound() async {
    if (_isSfxMuted) return;
    try {
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/button.mp3'), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Erro ao tocar som de botão: $e');
    }
  }
}
