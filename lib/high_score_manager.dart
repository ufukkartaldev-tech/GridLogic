import 'package:shared_preferences/shared_preferences.dart';

class HighScoreManager {
  static final HighScoreManager _instance = HighScoreManager._internal();
  factory HighScoreManager() => _instance;
  HighScoreManager._internal();

  static const String _highScoreKey = 'high_score';

  Future<int> getHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_highScoreKey) ?? 0;
    } catch (e) {
      print('Failed to load high score: $e');
      return 0;
    }
  }

  Future<void> saveHighScore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHighScore = await getHighScore();
      
      if (score > currentHighScore) {
        await prefs.setInt(_highScoreKey, score);
        print('New high score saved: $score');
      }
    } catch (e) {
      print('Failed to save high score: $e');
    }
  }

  Future<void> resetHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_highScoreKey);
      print('High score reset');
    } catch (e) {
      print('Failed to reset high score: $e');
    }
  }
}
