import 'package:get_it/get_it.dart';
import 'game_stats.dart';
import 'player_data.dart';

GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  final gameStats = GameStats();
  await gameStats.init();
  locator.registerSingleton<GameStats>(gameStats);

  final playerData = PlayerDataService();
  await playerData.init();
  locator.registerSingleton<PlayerDataService>(playerData);
}
