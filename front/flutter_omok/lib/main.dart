import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

// --- 열거형 및 상수 정의 ---
enum GameMode { pvp, pvc }

enum Player { none, black, white }

enum Difficulty { easy, normal, hard }

// 테마 색상 정의
const Color kBackgroundColor = Color(0xFFF0F4F8);
const Color kTextColor = Color(0xFF424242);
const Color kHighlightColor = Color(0xFF6D9F71);
const Color kDangerColor = Color(0xFFE57373);
const Color kShadowColorDark = Color(0xFFA3B1C6);
const Color kShadowColorLight = Color(0xFFFFFFFF);

// --- 플랫폼별 광고 ID 분기 처리 ---
String get bannerAdUnitId {
  if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
  if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
  throw UnsupportedError('Unsupported platform');
}

String get interstitialAdUnitId {
  if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
  if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
  throw UnsupportedError('Unsupported platform');
}

String get rewardedAdUnitId {
  if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
  if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
  throw UnsupportedError('Unsupported platform');
}

Future<void> requestTrackingPermission() async {
  final status = await AppTrackingTransparency.requestTrackingAuthorization();
  print('Tracking status: $status');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    print('AdMob initialization failed: $e');
  }
  runApp(const OmokGameApp());
}

// --- 데이터 관리 클래스들 ---
class GameStats {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> recordWin(
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

  static Future<void> recordLoss(
    GameMode mode, {
    Difficulty? difficulty,
  }) async {
    if (mode == GameMode.pvc) {
      String key = 'pvc_${difficulty.toString().split('.').last}_losses';
      await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    }
  }

  static Map<String, int> getStats() {
    Map<String, int> stats = {};
    _prefs.getKeys().forEach((key) {
      stats[key] = _prefs.getInt(key) ?? 0;
    });
    return stats;
  }
}

class PlayerDataService {
  static late SharedPreferences _prefs;
  static const String defaultBoardId = 'board_basic';
  static const String defaultStonesId = 'stones_basic';
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static int getAcorns() => _prefs.getInt('player_acorns') ?? 0;
  static Future<void> addAcorns(int amount) async {
    int current = getAcorns();
    await _prefs.setInt('player_acorns', current + amount);
  }

  static Future<bool> spendAcorns(int amount) async {
    int current = getAcorns();
    if (current >= amount) {
      await _prefs.setInt('player_acorns', current - amount);
      return true;
    }
    return false;
  }

  static List<String> getOwnedItems() =>
      _prefs.getStringList('owned_items') ?? [defaultBoardId, defaultStonesId];
  static Future<void> addOwnedItem(String itemId) async {
    List<String> items = getOwnedItems();
    if (!items.contains(itemId)) {
      items.add(itemId);
      await _prefs.setStringList('owned_items', items);
    }
  }

  static String getEquippedBoard() =>
      _prefs.getString('equipped_board') ?? defaultBoardId;
  static Future<void> setEquippedBoard(String itemId) async =>
      await _prefs.setString('equipped_board', itemId);
  static String getEquippedStones() =>
      _prefs.getString('equipped_stones') ?? defaultStonesId;
  static Future<void> setEquippedStones(String itemId) async =>
      await _prefs.setString('equipped_stones', itemId);
}

// --- 앱 진입점 ---
class OmokGameApp extends StatelessWidget {
  const OmokGameApp({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([GameStats.init(), PlayerDataService.init()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: '프리미엄 오목',
            theme: ThemeData(
              scaffoldBackgroundColor: kBackgroundColor,
              textTheme: GoogleFonts.juaTextTheme(
                Theme.of(context).textTheme.apply(bodyColor: kTextColor),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: kBackgroundColor,
                elevation: 0,
                iconTheme: const IconThemeData(color: kTextColor),
                titleTextStyle: GoogleFonts.jua(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ),
            home: const MainScreen(),
          );
        }
        return Container(
          color: kBackgroundColor,
          child: const Center(
            child: CircularProgressIndicator(color: kHighlightColor),
          ),
        );
      },
    );
  }
}

// --- 메인 화면 ---
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
                  _NeumorphicButton(
                    text: '컴퓨터와 대결',
                    onPressed: () => _showDifficultyDialog(context),
                  ),
                  const SizedBox(height: 20),
                  _NeumorphicButton(
                    text: '친구와 대결',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const GameScreen(gameMode: GameMode.pvp),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _NeumorphicButton(
                    text: '전적 보기',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _NeumorphicButton(
                    text: '상점',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _NeumorphicButton(
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
    return _NeumorphicButton(
      height: 60,
      width: double.infinity,
      isCircle: false,
      text: text,
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GameScreen(gameMode: GameMode.pvc, difficulty: difficulty),
          ),
        );
      },
    );
  }
}

// --- 전적 화면 ---
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final stats = GameStats.getStats();
    String getDifficulty(String key) => key.split('_')[1];
    int wins(String key) => stats[key] ?? 0;
    int losses(String key) => stats[key.replaceFirst('wins', 'losses')] ?? 0;
    List<Widget> pvcWidgets = stats.keys
        .where((k) => k.startsWith('pvc') && k.endsWith('wins'))
        .map(
          (key) => ListTile(
            title: Text(
              "컴퓨터 (${getDifficulty(key)})",
              style: GoogleFonts.jua(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            trailing: Text(
              "${wins(key)}승 ${losses(key)}패",
              style: GoogleFonts.jua(fontSize: 22, color: kTextColor),
            ),
          ),
        )
        .toList();
    int blackWins = stats['pvp_black_wins'] ?? 0;
    int whiteWins = stats['pvp_white_wins'] ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text("전적 보기")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "VS 컴퓨터",
            style: GoogleFonts.jua(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 10),
          ...pvcWidgets,
          const Divider(height: 40),
          Text(
            "VS 친구",
            style: GoogleFonts.jua(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: Text(
              "흑돌",
              style: GoogleFonts.jua(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            trailing: Text(
              "$blackWins 승",
              style: GoogleFonts.jua(fontSize: 22, color: kTextColor),
            ),
          ),
          ListTile(
            title: Text(
              "백돌",
              style: GoogleFonts.jua(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            trailing: Text(
              "$whiteWins 승",
              style: GoogleFonts.jua(fontSize: 22, color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 상점 화면 ---
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
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
      _acorns = PlayerDataService.getAcorns();
      _ownedItems = PlayerDataService.getOwnedItems();
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
    if (_acorns >= item.price) {
      bool success = await PlayerDataService.spendAcorns(item.price);
      if (success) {
        await PlayerDataService.addOwnedItem(item.id);
        _loadPlayerData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name}을(를) 구매했습니다!'),
            backgroundColor: kHighlightColor,
          ),
        );
      }
    } else {
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
          if (_isRewardedAdLoaded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _NeumorphicButton(
                text: '광고 보고 15 도토리 받기',
                onPressed: () {
                  _rewardedAd?.show(
                    onUserEarnedReward: (ad, reward) {
                      PlayerDataService.addAcorns(15);
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

// --- 보관함 화면 ---
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late List<String> _ownedItems;
  late String _equippedBoard;
  late String _equippedStones;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  void _loadPlayerData() {
    setState(() {
      _ownedItems = PlayerDataService.getOwnedItems();
      _equippedBoard = PlayerDataService.getEquippedBoard();
      _equippedStones = PlayerDataService.getEquippedStones();
    });
  }

  Future<void> _equipItem(CustomItem item) async {
    if (item.type == ItemType.board) {
      await PlayerDataService.setEquippedBoard(item.id);
    } else if (item.type == ItemType.stones) {
      await PlayerDataService.setEquippedStones(item.id);
    }
    _loadPlayerData();
  }

  @override
  Widget build(BuildContext context) {
    final ownedBoards = shopItems
        .where(
          (item) =>
              item.type == ItemType.board && _ownedItems.contains(item.id),
        )
        .toList();
    final ownedStones = shopItems
        .where(
          (item) =>
              item.type == ItemType.stones && _ownedItems.contains(item.id),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('보관함')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('오목판', style: GoogleFonts.jua(fontSize: 28)),
          const SizedBox(height: 10),
          _buildItemGrid(ownedBoards, _equippedBoard),
          const SizedBox(height: 30),
          Text('오목알', style: GoogleFonts.jua(fontSize: 28)),
          const SizedBox(height: 10),
          _buildItemGrid(ownedStones, _equippedStones),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<CustomItem> items, String equippedId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isEquipped = item.id == equippedId;
        return GestureDetector(
          onTap: () => _equipItem(item),
          child: Stack(
            alignment: Alignment.center,
            children: [
              NeumorphicContainer(
                isCircle: false,
                child: item.buildPreview(context),
              ),
              if (isEquipped)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kHighlightColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kHighlightColor, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// --- 게임 화면 ---
class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty? difficulty;
  const GameScreen({super.key, required this.gameMode, this.difficulty});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int boardSize = 15;
  static const int turnTimeLimit = 20;

  late List<List<Player>> _board;
  Player _currentPlayer = Player.black;
  bool _isGameOver = false;
  String _statusMessage = "";

  late AILogic _ai;
  Timer? _timer;
  int _timeRemaining = turnTimeLimit;

  late AnimationController _stonePlacementController;
  late ConfettiController _confettiController;
  Point<int>? _lastMove;
  List<Point<int>> _winningLine = [];

  late AnimationController _statusMessageController;
  late Animation<double> _statusMessageFadeAnimation;
  late Animation<Offset> _statusMessageSlideAnimation;

  late BoardTheme _currentBoardTheme;
  late StoneTheme _currentStoneTheme;

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    if (widget.gameMode == GameMode.pvc) {
      _ai = AILogic(boardSize: boardSize, difficulty: widget.difficulty!);
    }
    _stonePlacementController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _statusMessageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _statusMessageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statusMessageController, curve: Curves.easeIn),
    );
    _statusMessageSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _statusMessageController,
            curve: Curves.easeOut,
          ),
        );
    _loadInterstitialAd();
    _resetGame();
  }

  void _loadTheme() {
    String boardId = PlayerDataService.getEquippedBoard();
    String stonesId = PlayerDataService.getEquippedStones();
    _currentBoardTheme =
        shopItems.firstWhere(
              (item) => item.id == boardId,
              orElse: () => shopItems.first,
            )
            as BoardTheme;
    _currentStoneTheme =
        shopItems.firstWhere(
              (item) => item.id == stonesId,
              orElse: () => shopItems.first,
            )
            as StoneTheme;
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  Navigator.of(context).pop();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  Navigator.of(context).pop();
                },
              );
        },
        onAdFailedToLoad: (err) {},
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stonePlacementController.dispose();
    _confettiController.dispose();
    _statusMessageController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _resetGame() {
    setState(() {
      _board = List.generate(
        boardSize,
        (i) => List.generate(boardSize, (j) => Player.none),
      );
      _currentPlayer = Player.black;
      _isGameOver = false;
      _statusMessage = '${_getPlayerName(_currentPlayer)}의 차례';
      _lastMove = null;
      _winningLine = [];
      _statusMessageController.forward(from: 0.0);
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemaining = turnTimeLimit;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (_isGameOver) return;
    _timer?.cancel();
    Player timedOutPlayer = _currentPlayer;
    setState(() {
      _currentPlayer = (_currentPlayer == Player.black)
          ? Player.white
          : Player.black;
      _statusMessage =
          '${_getPlayerName(timedOutPlayer)} 시간 초과!\n${_getPlayerName(_currentPlayer)}의 차례';
      _statusMessageController.forward(from: 0.0);
      _startTimer();
    });
    if (widget.gameMode == GameMode.pvc &&
        !_isGameOver &&
        _currentPlayer == Player.white) {
      setState(() {
        _statusMessage = "컴퓨터가 생각 중...";
      });
      _timer?.cancel();
      Timer(const Duration(milliseconds: 700), _computerMove);
    }
  }

  void _switchPlayer() {
    setState(() {
      _currentPlayer = (_currentPlayer == Player.black)
          ? Player.white
          : Player.black;
      _statusMessage = '${_getPlayerName(_currentPlayer)}의 차례';
      _statusMessageController.forward(from: 0.0);
      _startTimer();
    });
  }

  void _placeStone(int row, int col) {
    if (_isGameOver || _board[row][col] != Player.none) return;
    setState(() {
      _board[row][col] = _currentPlayer;
      _lastMove = Point(row, col);
      _stonePlacementController.forward(from: 0.0);
    });
    if (_checkWin(row, col)) {
      _timer?.cancel();
      setState(() {
        _isGameOver = true;
        _statusMessage = '${_getPlayerName(_currentPlayer)}의 승리!';
      });
      _recordGameResult(winner: _currentPlayer);
      _showGameOverDialog(winner: _currentPlayer);
      return;
    }
    _switchPlayer();
  }

  void _handleTap(int row, int col) {
    if (_isGameOver ||
        (widget.gameMode == GameMode.pvc && _currentPlayer == Player.white))
      return;
    _placeStone(row, col);
    if (widget.gameMode == GameMode.pvc &&
        !_isGameOver &&
        _currentPlayer == Player.white) {
      setState(() {
        _statusMessage = "컴퓨터가 생각 중...";
        _statusMessageController.forward(from: 0.0);
      });
      _timer?.cancel();
      Timer(const Duration(milliseconds: 700), _computerMove);
    }
  }

  void _computerMove() {
    if (_isGameOver) return;
    Point<int> bestMove = _ai.findBestMove(_board);
    _placeStone(bestMove.x, bestMove.y);
  }

  void _recordGameResult({required Player winner}) {
    bool playerWon =
        (widget.gameMode == GameMode.pvc && winner == Player.black) ||
        (widget.gameMode == GameMode.pvp);
    if (playerWon) {
      PlayerDataService.addAcorns(10);
    }
    if (widget.gameMode == GameMode.pvc) {
      if (winner == Player.black) {
        GameStats.recordWin(GameMode.pvc, difficulty: widget.difficulty);
      } else {
        GameStats.recordLoss(GameMode.pvc, difficulty: widget.difficulty);
      }
    } else {
      GameStats.recordWin(GameMode.pvp, winner: winner);
    }
  }

  String _getPlayerName(Player player) {
    if (widget.gameMode == GameMode.pvc) {
      return player == Player.black ? "플레이어" : "컴퓨터";
    } else {
      return player == Player.black ? "흑돌" : "백돌";
    }
  }

  bool _checkWin(int row, int col) {
    Player player = _board[row][col];
    if (player == Player.none) return false;
    const directions = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1],
    ];
    for (var dir in directions) {
      int count = 1;
      List<Point<int>> line = [Point(row, col)];
      for (int i = 1; i < 5; i++) {
        int r = row + dir[0] * i, c = col + dir[1] * i;
        if (r >= 0 &&
            r < boardSize &&
            c >= 0 &&
            c < boardSize &&
            _board[r][c] == player) {
          count++;
          line.add(Point(r, c));
        } else
          break;
      }
      for (int i = 1; i < 5; i++) {
        int r = row - dir[0] * i, c = col - dir[1] * i;
        if (r >= 0 &&
            r < boardSize &&
            c >= 0 &&
            c < boardSize &&
            _board[r][c] == player) {
          count++;
          line.add(Point(r, c));
        } else
          break;
      }
      if (count >= 5) {
        setState(() => _winningLine = line);
        return true;
      }
    }
    return false;
  }

  void _showGameOverDialog({bool isTimeout = false, Player? winner}) {
    bool isPlayerLostToAI =
        (widget.gameMode == GameMode.pvc && winner == Player.white);
    if (!isTimeout && !isPlayerLostToAI) {
      _confettiController.play();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
            backgroundColor: kBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Center(
              child: Text(
                isTimeout ? "시간 초과!" : "🎉 게임 종료 🎉",
                style: GoogleFonts.jua(
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  fontSize: 36,
                ),
              ),
            ),
            content: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.jua(fontSize: 28, color: kTextColor),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                child: Text(
                  "다시하기",
                  style: GoogleFonts.jua(fontSize: 24, color: kHighlightColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetGame();
                },
              ),
              TextButton(
                child: Text(
                  "메인으로",
                  style: GoogleFonts.jua(fontSize: 24, color: kHighlightColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_interstitialAd != null) {
                    _interstitialAd!.show();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          if (!isTimeout)
            isPlayerLostToAI
                ? const RaindropAnimation()
                : ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    emissionFrequency: 0.05,
                    colors: const [
                      kHighlightColor,
                      Colors.blueAccent,
                      Colors.purpleAccent,
                    ],
                  ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '프리미엄 오목',
          style: GoogleFonts.jua(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayerInfo(),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _statusMessageFadeAnimation,
                child: SlideTransition(
                  position: _statusMessageSlideAnimation,
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jua(fontSize: 30, color: kTextColor),
                  ),
                ),
              ),
              const Spacer(),
              _buildBoard(),
              const Spacer(),
              _NeumorphicButton(
                icon: Icons.refresh,
                onPressed: _resetGame,
                isCircle: true,
                width: 70,
                height: 70,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _PlayerIndicator(
          name: _getPlayerName(Player.black),
          isTurn: _currentPlayer == Player.black && !_isGameOver,
          time: _currentPlayer == Player.black ? _timeRemaining : turnTimeLimit,
          playerColor: _currentStoneTheme.blackStoneGradient.colors.last,
          turnTimeLimit: turnTimeLimit,
        ),
        _PlayerIndicator(
          name: _getPlayerName(Player.white),
          isTurn: _currentPlayer == Player.white && !_isGameOver,
          time: _currentPlayer == Player.white ? _timeRemaining : turnTimeLimit,
          playerColor: _currentStoneTheme.whiteStoneGradient.colors.first,
          turnTimeLimit: turnTimeLimit,
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSizeDimension = constraints.maxWidth;
        final double squareSize = boardSizeDimension / (boardSize - 1);
        return NeumorphicContainer(
          width: boardSizeDimension,
          height: boardSizeDimension,
          isCircle: false,
          child: GestureDetector(
            onTapUp: (details) {
              if (_isGameOver ||
                  (widget.gameMode == GameMode.pvc &&
                      _currentPlayer == Player.white))
                return;
              final col = (details.localPosition.dx / squareSize).round().clamp(
                0,
                boardSize - 1,
              );
              final row = (details.localPosition.dy / squareSize).round().clamp(
                0,
                boardSize - 1,
              );
              _handleTap(row, col);
            },
            child: AnimatedBuilder(
              animation: _stonePlacementController,
              builder: (context, child) => CustomPaint(
                painter: BoardPainter(
                  board: _board,
                  boardSize: boardSize,
                  lastMove: _lastMove,
                  animationValue: _stonePlacementController.value,
                  winningLine: _winningLine,
                  boardTheme: _currentBoardTheme,
                  stoneTheme: _currentStoneTheme,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- 커스텀 페인터 ---
class BoardPainter extends CustomPainter {
  final List<List<Player>> board;
  final int boardSize;
  final Point<int>? lastMove;
  final double animationValue;
  final List<Point<int>> winningLine;
  final BoardTheme boardTheme;
  final StoneTheme stoneTheme;

  BoardPainter({
    required this.board,
    required this.boardSize,
    this.lastMove,
    required this.animationValue,
    required this.winningLine,
    required this.boardTheme,
    required this.stoneTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double squareSize = size.width / (boardSize - 1);
    final boardPaint = Paint()..color = boardTheme.boardColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(15),
      ),
      boardPaint,
    );
    final Paint linePaint = Paint()
      ..color = boardTheme.lineColor.withOpacity(0.9)
      ..strokeWidth = 2.0;
    for (int i = 0; i < boardSize; i++) {
      canvas.drawLine(
        Offset(i * squareSize, 0),
        Offset(i * squareSize, size.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, i * squareSize),
        Offset(size.width, i * squareSize),
        linePaint,
      );
    }
    final Paint dotPaint = Paint()..color = boardTheme.lineColor;
    final double dotRadius = 5.0;
    final List<Point<int>> dotPositions = [
      const Point(3, 3),
      const Point(3, 11),
      const Point(11, 3),
      const Point(11, 11),
      const Point(7, 7),
    ];
    for (var pos in dotPositions) {
      canvas.drawCircle(
        Offset(pos.y * squareSize, pos.x * squareSize),
        dotRadius,
        dotPaint,
      );
    }
    final double stoneRadius = squareSize / 2.3;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != Player.none) {
          final center = Offset(j * squareSize, i * squareSize);
          bool isLastMove = lastMove?.x == i && lastMove?.y == j;
          bool isWinningStone = winningLine.any((p) => p.x == i && p.y == j);
          double scale = isLastMove
              ? (0.7 + 0.3 * Curves.elasticOut.transform(animationValue))
              : 1.0;
          double currentRadius = stoneRadius * scale;
          final rect = Rect.fromCircle(center: center, radius: currentRadius);
          final stonePaint = Paint();
          if (board[i][j] == Player.black) {
            stonePaint.shader = stoneTheme.blackStoneGradient.createShader(
              rect,
            );
          } else {
            stonePaint.shader = stoneTheme.whiteStoneGradient.createShader(
              rect,
            );
          }
          final shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
          canvas.drawCircle(
            center.translate(2 * scale, 2 * scale),
            currentRadius,
            shadowPaint,
          );
          canvas.drawCircle(center, currentRadius, stonePaint);
          if (isLastMove) {
            final lastMovePaint = Paint()
              ..color = kHighlightColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0;
            canvas.drawCircle(center, currentRadius + 2, lastMovePaint);
          }
          if (isWinningStone) {
            final highlightPaint = Paint()
              ..color = Colors.yellow.withOpacity(0.6)
              ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);
            canvas.drawCircle(center, currentRadius + 3, highlightPaint);
          }
        }
      }
    }
    if (winningLine.isNotEmpty && animationValue > 0) {
      final linePaint = Paint()
        ..color = kHighlightColor.withOpacity(0.9)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            kHighlightColor,
            Colors.white.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
          tileMode: TileMode.mirror,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      Point start = winningLine.first;
      Point end = winningLine.last;
      for (var p in winningLine) {
        if (p.x < start.x || (p.x == start.x && p.y < start.y)) start = p;
        if (p.x > end.x || (p.x == end.x && p.y > end.y)) end = p;
      }
      double dx = (end.y - start.y) * squareSize;
      double dy = (end.x - start.x) * squareSize;
      canvas.drawLine(
        Offset(start.y * squareSize, start.x * squareSize),
        Offset(
          start.y * squareSize + dx * animationValue,
          start.x * squareSize + dy * animationValue,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- 빗방울 애니메이션 위젯 ---
class RaindropAnimation extends StatefulWidget {
  const RaindropAnimation({super.key});
  @override
  State<RaindropAnimation> createState() => _RaindropAnimationState();
}

class _RaindropAnimationState extends State<RaindropAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Raindrop> _raindrops = [];
  final Random _random = Random();
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.addListener(() {
      setState(() {
        if (_random.nextDouble() < 0.1) {
          _raindrops.add(
            Raindrop(
              x: _random.nextDouble() * MediaQuery.of(context).size.width,
              y: -_random.nextDouble() * 100,
              speed: 5 + _random.nextDouble() * 5,
              size: 1 + _random.nextDouble() * 2,
              opacity: 0.5 + _random.nextDouble() * 0.5,
            ),
          );
        }
        _raindrops.removeWhere(
          (drop) => drop.y > MediaQuery.of(context).size.height + 50,
        );
        for (var drop in _raindrops) {
          drop.y += drop.speed;
        }
      });
    });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: RaindropPainter(raindrops: _raindrops),
        child: Container(),
      ),
    );
  }
}

class Raindrop {
  double x, y, speed, size, opacity;
  Raindrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class RaindropPainter extends CustomPainter {
  final List<Raindrop> raindrops;
  RaindropPainter({required this.raindrops});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..strokeCap = StrokeCap.round;
    for (var drop in raindrops) {
      paint.color = Colors.blue.withOpacity(drop.opacity);
      paint.strokeWidth = drop.size;
      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x, drop.y + drop.size * 5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RaindropPainter oldDelegate) =>
      oldDelegate.raindrops != raindrops;
}

// --- 커스텀 위젯들 ---
class _NeumorphicButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final bool isCircle;
  const _NeumorphicButton({
    this.text,
    this.icon,
    required this.onPressed,
    this.width = 240,
    this.height = 70,
    this.isCircle = false,
  });
  @override
  State<_NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<_NeumorphicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: NeumorphicContainer(
              width: widget.width,
              height: widget.height,
              isCircle: widget.isCircle,
              child: Center(
                child: widget.text != null
                    ? Text(
                        widget.text!,
                        style: GoogleFonts.jua(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                      )
                    : Icon(
                        widget.icon,
                        size: 30,
                        color: kTextColor.withOpacity(0.8),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NeumorphicContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;
  final bool isCircle;
  const NeumorphicContainer({
    super.key,
    this.width,
    this.height,
    required this.child,
    this.isCircle = true,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: isCircle ? null : BorderRadius.circular(20),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: const [
          BoxShadow(
            color: kShadowColorDark,
            offset: Offset(4, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: kShadowColorLight,
            offset: Offset(-4, -4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlayerIndicator extends StatelessWidget {
  final String name;
  final bool isTurn;
  final int time;
  final Color playerColor;
  final int turnTimeLimit;
  const _PlayerIndicator({
    required this.name,
    required this.isTurn,
    required this.time,
    required this.playerColor,
    required this.turnTimeLimit,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (isTurn)
            BoxShadow(
              color: kHighlightColor.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: kShadowColorDark.withOpacity(0.3),
            offset: const Offset(3, 3),
            blurRadius: 10,
          ),
          BoxShadow(
            color: kShadowColorLight.withOpacity(0.7),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
        border: isTurn ? Border.all(color: kHighlightColor, width: 3) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: playerColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: GoogleFonts.jua(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isTurn)
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: time / turnTimeLimit,
                      strokeWidth: 8,
                      backgroundColor: kTextColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        time <= 5 ? kDangerColor : kHighlightColor,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kTextColor.withOpacity(0.1),
                    ),
                  ),
                Text(
                  "$time",
                  style: GoogleFonts.jua(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: time <= 5 && isTurn ? kDangerColor : kTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- AI 로직 클래스 ---
class AILogic {
  final int boardSize;
  final Difficulty difficulty;
  AILogic({required this.boardSize, required this.difficulty});
  Point<int> findBestMove(List<List<Player>> board) {
    if (difficulty == Difficulty.easy) return _findBestMoveEasy(board);
    int bestScore = -1;
    Point<int> bestMove = const Point(-1, -1);
    var tempBoard = board.map((row) => List<Player>.from(row)).toList();
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (tempBoard[r][c] == Player.none) {
          tempBoard[r][c] = Player.white;
          if (_checkWin(r, c, Player.white, tempBoard)) return Point(r, c);
          tempBoard[r][c] = Player.none;
        }
      }
    }
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (tempBoard[r][c] == Player.none) {
          tempBoard[r][c] = Player.black;
          if (_checkWin(r, c, Player.black, tempBoard)) {
            bestScore = 100000;
            bestMove = Point(r, c);
            tempBoard[r][c] = Player.none;
            return bestMove;
          }
          tempBoard[r][c] = Player.none;
        }
      }
    }
    if (bestMove.x == -1) {
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (board[r][c] == Player.none) {
            int score = _calculateScore(r, c, board);
            if (score > bestScore) {
              bestScore = score;
              bestMove = Point(r, c);
            }
          }
        }
      }
    }
    if (bestMove.x == -1) {
      if (board[boardSize ~/ 2][boardSize ~/ 2] == Player.none) {
        return Point(boardSize ~/ 2, boardSize ~/ 2);
      }
      List<Point<int>> emptyCells = [];
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (board[r][c] == Player.none) emptyCells.add(Point(r, c));
        }
      }
      if (emptyCells.isNotEmpty) {
        bestMove = emptyCells[Random().nextInt(emptyCells.length)];
      }
    }
    return bestMove;
  }

  Point<int> _findBestMoveEasy(List<List<Player>> board) {
    List<Point<int>> emptyCells = [];
    int maxScore = -1;
    Point<int> bestMove = const Point(7, 7);
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == Player.none) {
          int score = 0;
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              int nr = r + dr, nc = c + dc;
              if (nr >= 0 &&
                  nr < boardSize &&
                  nc >= 0 &&
                  nc < boardSize &&
                  board[nr][nc] != Player.none) {
                score++;
              }
            }
          }
          if (score > maxScore) {
            maxScore = score;
            bestMove = Point(r, c);
          }
          emptyCells.add(Point(r, c));
        }
      }
    }
    if (maxScore == 0 && emptyCells.isNotEmpty) {
      return emptyCells[Random().nextInt(emptyCells.length)];
    }
    if (bestMove.x == 7 &&
        bestMove.y == 7 &&
        board[7][7] != Player.none &&
        emptyCells.isNotEmpty) {
      return emptyCells[Random().nextInt(emptyCells.length)];
    }
    return bestMove;
  }

  int _calculateScore(int r, int c, List<List<Player>> board) {
    int score = 0;
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (var dir in directions) {
      score += _getScoreForLine(
        r,
        c,
        dir[0],
        dir[1],
        Player.white,
        board,
        this.difficulty,
      );
      score += _getScoreForLine(
        r,
        c,
        dir[0],
        dir[1],
        Player.black,
        board,
        this.difficulty,
      );
    }
    return score;
  }

  int _getScoreForLine(
    int r,
    int c,
    int dr,
    int dc,
    Player player,
    List<List<Player>> board,
    Difficulty difficulty,
  ) {
    int count = 1, openEnds = 0;
    for (int i = 1; i < 5; i++) {
      int nr = r + dr * i, nc = c + dc * i;
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
        if (board[nr][nc] == player)
          count++;
        else if (board[nr][nc] == Player.none) {
          openEnds++;
          break;
        } else
          break;
      } else {
        break;
      }
    }
    for (int i = 1; i < 5; i++) {
      int nr = r - dr * i, nc = c - dc * i;
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize) {
        if (board[nr][nc] == player)
          count++;
        else if (board[nr][nc] == Player.none) {
          openEnds++;
          break;
        } else
          break;
      } else {
        break;
      }
    }
    bool isHard = difficulty == Difficulty.hard;
    if (count >= 5) return 50000;
    if (count == 4) {
      if (openEnds == 2) return isHard ? 10000 : 8000;
      if (openEnds == 1) return isHard ? 5000 : 3000;
    }
    if (count == 3) {
      if (openEnds == 2) return isHard ? 2000 : 500;
      if (openEnds == 1) return isHard ? 100 : 50;
    }
    if (count == 2) {
      if (openEnds == 2) return isHard ? 50 : 20;
      if (openEnds == 1) return 10;
    }
    if (count == 1 && openEnds == 2) return 5;
    return 0;
  }

  bool _checkWin(int row, int col, Player player, List<List<Player>> board) {
    if (player == Player.none) return false;
    const directions = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1],
    ];
    for (var dir in directions) {
      int count = 1;
      for (int i = 1; i < 5; i++) {
        int nr = row + dir[0] * i, nc = col + dir[1] * i;
        if (nr >= 0 &&
            nr < boardSize &&
            nc >= 0 &&
            nc < boardSize &&
            board[nr][nc] == player)
          count++;
        else
          break;
      }
      for (int i = 1; i < 5; i++) {
        int nr = row - dir[0] * i, nc = col - dir[1] * i;
        if (nr >= 0 &&
            nr < boardSize &&
            nc >= 0 &&
            nc < boardSize &&
            board[nr][nc] == player)
          count++;
        else
          break;
      }
      if (count >= 5) return true;
    }
    return false;
  }
}

// --- 아이템 모델 정의 ---
enum ItemType { board, stones }

abstract class CustomItem {
  final String id, name;
  final int price;
  final ItemType type;
  CustomItem({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });
  Widget buildPreview(BuildContext context);
}

class BoardTheme extends CustomItem {
  final Color boardColor, lineColor;
  BoardTheme({
    required super.id,
    required super.name,
    required super.price,
    required this.boardColor,
    required this.lineColor,
  }) : super(type: ItemType.board);
  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: boardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lineColor, width: 2),
      ),
    );
  }
}

class StoneTheme extends CustomItem {
  final Gradient blackStoneGradient, whiteStoneGradient;
  StoneTheme({
    required super.id,
    required super.name,
    required super.price,
    required this.blackStoneGradient,
    required this.whiteStoneGradient,
  }) : super(type: ItemType.stones);
  @override
  Widget buildPreview(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: blackStoneGradient,
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: whiteStoneGradient,
          ),
        ),
      ],
    );
  }
}

final List<CustomItem> shopItems = [
  BoardTheme(
    id: 'board_basic',
    name: '기본 나무판',
    price: 0,
    boardColor: const Color(0xFFD2B48C),
    lineColor: const Color(0xFF6D4C41),
  ),
  StoneTheme(
    id: 'stones_basic',
    name: '기본 조약돌',
    price: 0,
    blackStoneGradient: const RadialGradient(
      colors: [Color(0xFF424242), Color(0xFF212121)],
      stops: [0.0, 0.9],
    ),
    whiteStoneGradient: const RadialGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
      stops: [0.1, 1.0],
    ),
  ),
  BoardTheme(
    id: 'board_cherry',
    name: '벚꽃 나무판',
    price: 100,
    boardColor: const Color(0xFFFFCDD2),
    lineColor: const Color(0xFFE57373),
  ),
  BoardTheme(
    id: 'board_deep_sea',
    name: '심해 석판',
    price: 150,
    boardColor: const Color(0xFF455A64),
    lineColor: const Color(0xFFB0BEC5),
  ),
  StoneTheme(
    id: 'stones_glass',
    name: '유리알',
    price: 120,
    blackStoneGradient: const RadialGradient(
      colors: [Color(0xAAE0E0E0), Color(0xAA212121)],
      stops: [0.1, 1.0],
    ),
    whiteStoneGradient: const RadialGradient(
      colors: [Color(0xDDFFFFFF), Color(0xAAEEEEEE)],
      stops: [0.1, 1.0],
    ),
  ),
  StoneTheme(
    id: 'stones_gold',
    name: '황금알',
    price: 300,
    blackStoneGradient: const RadialGradient(
      colors: [Color(0xFF424242), Color(0xFF212121)],
      stops: [0.0, 0.9],
    ),
    whiteStoneGradient: const RadialGradient(
      colors: [Color(0xFFFFF59D), Color(0xFFFBC02D)],
    ),
  ),
];
