import 'package:shared_preferences/shared_preferences.dart';

class PlayerDataService {
  late SharedPreferences _prefs;
  static const String defaultBoardId = 'board_basic';
  static const String defaultStonesId = 'stones_basic';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int getAcorns() => _prefs.getInt('player_acorns') ?? 0;
  Future<void> addAcorns(int amount) async {
    int current = getAcorns();
    await _prefs.setInt('player_acorns', current + amount);
  }

  Future<bool> spendAcorns(int amount) async {
    int current = getAcorns();
    if (current >= amount) {
      await _prefs.setInt('player_acorns', current - amount);
      return true;
    }
    return false;
  }

  List<String> getOwnedItems() =>
      _prefs.getStringList('owned_items') ?? [defaultBoardId, defaultStonesId];
  Future<void> addOwnedItem(String itemId) async {
    List<String> items = getOwnedItems();
    if (!items.contains(itemId)) {
      items.add(itemId);
      await _prefs.setStringList('owned_items', items);
    }
  }

  String getEquippedBoard() =>
      _prefs.getString('equipped_board') ?? defaultBoardId;
  Future<void> setEquippedBoard(String itemId) async =>
      await _prefs.setString('equipped_board', itemId);
  String getEquippedStones() =>
      _prefs.getString('equipped_stones') ?? defaultStonesId;
  Future<void> setEquippedStones(String itemId) async =>
      await _prefs.setString('equipped_stones', itemId);
}
