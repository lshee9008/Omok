import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// --- 열거형 및 상수 정의 ---
enum GameMode { pvp, pvc }

enum Player { none, black, white }

enum Difficulty { easy, normal, hard }

// 테마 색상 정의 (더 센스 있고 플레이에 집중할 수 있도록 재조정)
const Color kBackgroundColor = Color(0xFFF0F4F8); // 메인 배경 (은은한 회색)
const Color kBoardColor = Color(0xFFD2B48C); // 오목판 배경색 (나무색)
const Color kBoardLineColor = Color(0xFF8B4513); // 오목판 라인 (진한 나무색)
const Color kStoneBlackColor = Color(0xFF212121); // 흑돌 색상
const Color kStoneWhiteColor = Color(0xFFF0F0F0); // 백돌 색상
const Color kHighlightColor = Color(0xFF6D9F71); // 강조색 (초록색 계열)
const Color kAccentColor = Color(000000); // UI 포인트 색상 (파란색 계열)
const Color kDangerColor = Color(0xFFE57373); // 경고색 (빨간색)
const Color kTextColor = Color(0xFF424242); // 기본 텍스트 색상
const Color kShadowColorDark = Color(0xFFA3B1C6); // 뉴모피즘 어두운 그림자
const Color kShadowColorLight = Color(0xFFFFFFFF); // 뉴모피즘 밝은 그림자

void main() {
  runApp(const OmokGameApp());
}

// --- 전적 관리 클래스 ---
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

// --- 앱 진입점 ---
class OmokGameApp extends StatelessWidget {
  const OmokGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GameStats.init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: '프리미엄 오목',
            theme: ThemeData(
              scaffoldBackgroundColor: kBackgroundColor,
              textTheme: GoogleFonts.juaTextTheme(
                // Jua 폰트 적용 (더 귀엽고 가독성 좋음)
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const GameScreen(gameMode: GameMode.pvp),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _NeumorphicButton(
              text: '전적 보기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              },
            ),
          ],
        ),
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

  // 애니메이션 & 효과
  late AnimationController _stonePlacementController;
  late ConfettiController _confettiController;
  Point<int>? _lastMove;
  List<Point<int>> _winningLine = [];

  // 게임 상태 메시지 애니메이션
  late AnimationController _statusMessageController;
  late Animation<double> _statusMessageFadeAnimation;
  late Animation<Offset> _statusMessageSlideAnimation;

  @override
  void initState() {
    super.initState();
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

    _resetGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stonePlacementController.dispose();
    _confettiController.dispose();
    _statusMessageController.dispose();
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
    setState(() {
      _isGameOver = true;
      Player winner = _currentPlayer == Player.black
          ? Player.white
          : Player.black;
      _statusMessage =
          "${_getPlayerName(_currentPlayer)} 시간 초과!\n${_getPlayerName(winner)} 승리!";
    });
    _recordGameResult(
      winner: _currentPlayer == Player.black ? Player.white : Player.black,
    ); // 시간 초과한 플레이어가 패배
    _showGameOverDialog(isTimeout: true);
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
      _showGameOverDialog();
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

  void _showGameOverDialog({bool isTimeout = false}) {
    if (!isTimeout) _confettiController.play();
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
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          if (!isTimeout)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              colors: const [
                kHighlightColor,
                kAccentColor,
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
          playerColor: kStoneBlackColor,
          turnTimeLimit: turnTimeLimit,
        ),
        _PlayerIndicator(
          name: _getPlayerName(Player.white),
          isTurn: _currentPlayer == Player.white && !_isGameOver,
          time: _currentPlayer == Player.white ? _timeRemaining : turnTimeLimit,
          playerColor: kStoneWhiteColor,
          turnTimeLimit: turnTimeLimit,
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSizeDimension = constraints.maxWidth;

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

              final squareSize = boardSizeDimension / (boardSize - 1);
              final row = (details.localPosition.dy / squareSize).round();
              final col = (details.localPosition.dx / squareSize).round();

              if (row >= 0 && row < boardSize && col >= 0 && col < boardSize) {
                _handleTap(row, col);
              }
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- 커스텀 페인터 (돌과 보드 그리기) ---
class BoardPainter extends CustomPainter {
  final List<List<Player>> board;
  final int boardSize;
  final Point<int>? lastMove;
  final double animationValue;
  final List<Point<int>> winningLine;

  BoardPainter({
    required this.board,
    required this.boardSize,
    this.lastMove,
    required this.animationValue,
    required this.winningLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double squareSize = size.width / (boardSize - 1);

    // 오목판 배경 그리기 (더 부드러운 나무 질감)
    final boardPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD2B48C), Color(0xFFA0522D)],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(15),
      ),
      boardPaint,
    );

    // 보드 라인 그리기
    final Paint linePaint = Paint()
      ..color = kBoardLineColor.withOpacity(0.8)
      ..strokeWidth = 1.5; // 약간 두껍게
    for (int i = 0; i < boardSize; i++) {
      canvas.drawLine(
        Offset(0, i * squareSize),
        Offset(size.width, i * squareSize),
        linePaint,
      );
      canvas.drawLine(
        Offset(i * squareSize, 0),
        Offset(i * squareSize, size.height),
        linePaint,
      );
    }

    // 화점 그리기
    final Paint dotPaint = Paint()..color = kBoardLineColor.withOpacity(0.9);
    final double dotRadius = 5.0; // 화점 크기 증가
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

    // 돌 그리기
    final double stoneRadius = squareSize / 2.3; // 돌 크기 미세 조정
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != Player.none) {
          final center = Offset(j * squareSize, i * squareSize);
          bool isLastMove = lastMove?.x == i && lastMove?.y == j;
          bool isWinningStone = winningLine.any((p) => p.x == i && p.y == j);

          // 돌 놓기 애니메이션 (통통 튀는 효과)
          double scale = isLastMove
              ? (0.7 + 0.3 * Curves.elasticOut.transform(animationValue))
              : 1.0;
          double currentRadius = stoneRadius * scale;

          final rect = Rect.fromCircle(center: center, radius: currentRadius);
          final stonePaint = Paint();

          // 흑돌 그라디언트
          if (board[i][j] == Player.black) {
            stonePaint.shader = const RadialGradient(
              colors: [Color(0xFF424242), Color(0xFF212121), Color(0xFF000000)],
              stops: [0.0, 0.7, 1.0],
            ).createShader(rect);
          }
          // 백돌 그라디언트
          else {
            stonePaint.shader = const RadialGradient(
              colors: [Color(0xFFE0E0E0), Color(0xFFC0C0C0), Color(0xFFFFFFFF)],
              stops: [0.0, 0.7, 1.0],
            ).createShader(rect);
          }

          // 돌 그림자 효과
          final shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
          canvas.drawCircle(
            center.translate(2 * scale, 2 * scale),
            currentRadius,
            shadowPaint,
          );

          canvas.drawCircle(center, currentRadius, stonePaint);

          // 마지막으로 놓은 돌 표시 (테두리)
          if (isLastMove) {
            final lastMovePaint = Paint()
              ..color = kHighlightColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0;
            canvas.drawCircle(center, currentRadius + 2, lastMovePaint);
          }

          // 승리 돌 하이라이트 효과 (반짝임)
          if (isWinningStone) {
            final highlightPaint = Paint()
              ..color = Colors.yellow.withOpacity(0.6)
              ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);
            canvas.drawCircle(center, currentRadius + 3, highlightPaint);
          }
        }
      }
    }

    // 승리 라인 그리기 (애니메이션)
    if (winningLine.isNotEmpty && animationValue > 0) {
      final linePaint = Paint()
        ..color = kHighlightColor.withOpacity(0.9)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          // 반짝이는 효과를 위한 그라디언트
          colors: [
            Colors.white.withOpacity(0.8),
            kHighlightColor,
            Colors.white.withOpacity(0.8),
          ],
          stops: [0.0, 0.5, 1.0],
          tileMode: TileMode.mirror,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      Point start = winningLine.first;
      Point end = winningLine.last;

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

// --- 커스텀 위젯들 ---
class _NeumorphicButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final bool isCircle;

  const _NeumorphicButton({
    super.key,
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

  // 👇 여기가 수정된 부분입니다!
  void _onTapUp(TapUpDetails details) {
    // 'TapUpUpDetails' -> 'TapUpDetails'
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
              // 플레이어 아이콘 (돌 모양)
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
          // 타이머 게이지와 남은 시간
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isTurn) // 현재 턴인 경우에만 게이지 표시
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
                  // 현재 턴이 아닐 때는 원형 플레이트
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

// --- AI 로직 클래스 (변동 없음) ---
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
          tempBoard[r][c] = Player.black;
          if (_checkWin(r, c, Player.black, tempBoard)) {
            bestScore = 100000;
            bestMove = Point(r, c);
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
    Point<int> bestMove = const Point(7, 7); // 기본 중앙
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == Player.none) {
          int score = 0;
          // 주변에 돌이 있는 칸에 가중치
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
    // 주변에 돌이 없으면 랜덤으로 선택
    if (maxScore == 0 && emptyCells.isNotEmpty) {
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
      score += _getScoreForLine(r, c, dir[0], dir[1], Player.white, board);
      score += _getScoreForLine(r, c, dir[0], dir[1], Player.black, board);
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
      }
    }
    bool isHard = difficulty == Difficulty.hard;
    if (count >= 4) return 50000;
    if (count == 3 && openEnds == 2) return isHard ? 5000 : 800;
    if (count == 3 && openEnds == 1) return isHard ? 500 : 100;
    if (count == 2 && openEnds == 2) return isHard ? 300 : 50;
    if (count == 2 && openEnds == 1) return 10;
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
