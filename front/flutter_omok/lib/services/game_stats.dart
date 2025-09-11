import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class GameStats {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> recordWin(
    GameMode mode, {
    Difficulty? difficulty,
    Player? winner,
  }) async {
    String key;
    if (mode == GameMode.pvc) {
      key = 'pvc_${difficulty.toString().split('.').last}_wins';
      await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    } else {
      key = 'pvp_${winner.toString().split('.').last}_wins';
      await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    }
  }

  Future<void> recordLoss(GameMode mode, {Difficulty? difficulty}) async {
    if (mode == GameMode.pvc) {
      String key = 'pvc_${difficulty.toString().split('.').last}_losses';
      await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    }
  }

  Map<String, int> getStats() {
    Map<String, int> stats = {};

    // SharedPreferences의 모든 키를 가져옵니다.
    final allKeys = _prefs.getKeys();

    // '_wins' 또는 '_losses'로 끝나는 키만 필터링합니다.
    final statKeys = allKeys.where(
      (key) => key.endsWith('_wins') || key.endsWith('_losses'),
    );

    // 필터링된 전적 관련 키에 대해서만 값을 읽어옵니다.
    for (var key in statKeys) {
      stats[key] = _prefs.getInt(key) ?? 0;
    }

    return stats;
  }
}
