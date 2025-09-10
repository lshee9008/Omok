import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'providers/game_provider.dart';
import 'screens/main_screen.dart';
import 'services/locator.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await setupLocator();
  runApp(const OmokGameApp());
}

class OmokGameApp extends StatelessWidget {
  const OmokGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MaterialApp(
        title: '프리미엄 오목',
        theme: appTheme,
        home: const MainScreen(),
      ),
    );
  }
}
