// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../utils/ad_helper.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import 'game_screen.dart' hide GameProvider;
import 'inventory_screen.dart';
import 'stats_screen.dart';
import 'store_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late AnimationController _titleController;
  late Animation<Offset> _titleAnimation;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _titleAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _titleController, curve: Curves.elasticOut),
        );
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SlideTransition(
                    position: _titleAnimation,
                    child: Text(
                      '프리미엄 오목',
                      style: GoogleFonts.jua(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  NeumorphicButton(
                    text: '컴퓨터와 대결',
                    onPressed: () => _showDifficultyDialog(context),
                  ),
                  const SizedBox(height: 20),
                  NeumorphicButton(
                    text: '친구와 대결',
                    onPressed: () {
                      context.read<GameProvider>().initializeGame(GameMode.pvp);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  NeumorphicButton(
                    text: '전적 보기',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeumorphicButton(
                    text: '상점',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeumorphicButton(
                    text: '보관함',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventoryScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isBannerAdLoaded)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              "난이도 선택",
              style: GoogleFonts.jua(
                fontWeight: FontWeight.bold,
                color: kTextColor,
                fontSize: 32,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDifficultyButton(context, "쉬움", Difficulty.easy),
              const SizedBox(height: 15),
              _buildDifficultyButton(context, "보통", Difficulty.normal),
              const SizedBox(height: 15),
              _buildDifficultyButton(context, "어려움", Difficulty.hard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    String text,
    Difficulty difficulty,
  ) {
    return NeumorphicButton(
      height: 60,
      width: double.infinity,
      isCircle: false,
      text: text,
      onPressed: () {
        context.read<GameProvider>().initializeGame(
          GameMode.pvc,
          difficulty: difficulty,
        );
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GameScreen()),
        );
      },
    );
  }
}
