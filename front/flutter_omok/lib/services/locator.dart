import 'package:get_it/get_it.dart';

import 'game_stats.dart';
import 'player_data.dart';

// 앱 전역에서 사용할 GetIt 인스턴스 생성
GetIt locator = GetIt.instance;

// 앱이 시작될 때 실행될 서비스 등록 함수
Future<void> setupLocator() async {
  // 1. GameStats 클래스의 인스턴스를 생성하고 초기화합니다.
  final gameStats = GameStats();
  await gameStats.init();
  // 2. 초기화된 인스턴스를 '싱글톤'으로 등록하여 앱 어디서든 동일한 인스턴스를 사용할 수 있게 합니다.
  locator.registerSingleton<GameStats>(gameStats);

  // 3. PlayerDataService도 동일하게 생성, 초기화, 등록합니다.
  final playerData = PlayerDataService();
  await playerData.init();
  locator.registerSingleton<PlayerDataService>(playerData);
}
