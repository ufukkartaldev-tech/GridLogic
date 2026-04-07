import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  late AudioPlayer _audioPlayer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    _audioPlayer = AudioPlayer();
    
    // Pre-load sounds (using system sounds for now, can be replaced with custom files)
    try {
      // For now, we'll use system beep sounds
      // In a real app, you would load actual audio files here
      _initialized = true;
    } catch (e) {
      print('Failed to initialize sounds: $e');
    }
  }

  Future<void> playClick() async {
    if (!_initialized) return;
    
    try {
      // Play a short click sound using system beep
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Failed to play click sound: $e');
    }
  }

  Future<void> playDrop() async {
    if (!_initialized) return;
    
    try {
      // Play a different system sound for drop
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Failed to play drop sound: $e');
    }
  }

  Future<void> playExplosion() async {
    if (!_initialized) return;
    
    try {
      // Play a more dramatic sound for line clear
      await SystemSound.play(SystemSoundType.alert);
      // Add a slight delay and play again for more impact
      await Future.delayed(const Duration(milliseconds: 100));
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Failed to play explosion sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _initialized = false;
  }
}
