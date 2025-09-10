// lib/screens/store_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/item_models.dart';
import '../services/locator.dart';
import '../services/player_data.dart';
import '../utils/ad_helper.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final PlayerDataService _playerData = locator<PlayerDataService>();
  late int _acorns;
  late List<String> _ownedItems;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
    _loadRewardedAd();
  }

  void _loadPlayerData() {
    setState(() {
      _acorns = _playerData.getAcorns();
      _ownedItems = _playerData.getOwnedItems();
    });
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          setState(() => _isRewardedAdLoaded = true);
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
        },
        onAdFailedToLoad: (err) => setState(() => _isRewardedAdLoaded = false),
      ),
    );
  }

  Future<void> _buyItem(CustomItem item) async {
    bool success = await _playerData.spendAcorns(item.price);
    if (success) {
      await _playerData.addOwnedItem(item.id);
      _loadPlayerData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name}을(를) 구매했습니다!'),
            backgroundColor: kHighlightColor,
          ),
        );
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('도토리가 부족해요!'), backgroundColor: kDangerColor),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상점')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '보유 도토리: $_acorns 🐿️',
              style: GoogleFonts.jua(fontSize: 28),
            ),
          ),

          // ✨ 테스트용 치트 버튼 (출시 전 반드시 삭제!) ✨
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kDangerColor),
              onPressed: () async {
                await _playerData.addAcorns(1000); // 버튼 누를 때마다 1000 도토리 추가
                _loadPlayerData(); // 화면 새로고침
              },
              child: const Text(
                '1000 도토리 추가 (테스트용)',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          // ✨ ================================== ✨
          if (_isRewardedAdLoaded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: NeumorphicButton(
                text: '광고 보고 15 도토리 받기',
                onPressed: () {
                  _rewardedAd?.show(
                    onUserEarnedReward: (ad, reward) {
                      _playerData.addAcorns(15);
                      _loadPlayerData();
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: shopItems.length,
              itemBuilder: (context, index) {
                final item = shopItems[index];
                final isOwned = _ownedItems.contains(item.id);
                return GestureDetector(
                  onTap: isOwned || item.price == 0
                      ? null
                      : () => _buyItem(item),
                  child: NeumorphicContainer(
                    isCircle: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 40, child: item.buildPreview(context)),
                        const SizedBox(height: 8),
                        Text(item.name, style: GoogleFonts.jua(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          isOwned ? "보유중" : '${item.price} 도토리',
                          style: GoogleFonts.jua(
                            fontSize: 18,
                            color: isOwned
                                ? kHighlightColor
                                : kTextColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
