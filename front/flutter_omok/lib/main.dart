import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 열거형 및 상수 정의 ---
enum GameMode { pvp, pvc }

enum Player { none, black, white }

enum Difficulty { easy, normal, hard }

// 앱 전체에 사용될 뉴모피즘 스타일 색상
const Color kBackgroundColor = Color(0xFFE0E5EC);
const Color kDarkShadow = Color(0xFFA3B1C6);
const Color kLightShadow = Color(0xFFFFFFFF);
const Color kTextColor = Color(0xFF303030);
const Color kAccentColor = Color(0xFF6D63FF);

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
              fontFamily: 'Pretendard', // Pretendard 폰트 사용 (없을 경우 시스템 폰트로 대체됨)
            ),
            home: const MainScreen(),
          );
        }
        return Container(
          color: kBackgroundColor,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// --- 메인 화면 ---
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Premium Omok',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: kTextColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 60),
            _NeumorphicButton(
              text: '컴퓨터와 대결',
              onPressed: () => _showDifficultyDialog(context),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            _NeumorphicButton(
              text: '전적 보기',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kTextColor.withOpacity(0.8),
                fontSize: 22,
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GameScreen(gameMode: GameMode.pvc, difficulty: difficulty),
          ),
        );
      },
      child: NeumorphicContainer(
        height: 60,
        width: double.infinity,
        isCircle: false,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
        ),
      ),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "${wins(key)}승 ${losses(key)}패",
              style: const TextStyle(fontSize: 18),
            ),
          ),
        )
        .toList();
    int blackWins = stats['pvp_black_wins'] ?? 0;
    int whiteWins = stats['pvp_white_wins'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("전적 보기", style: TextStyle(color: kTextColor)),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "VS 컴퓨터",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ...pvcWidgets,
          const Divider(height: 40),
          const Text(
            "VS 친구",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text(
              "흑돌",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "$blackWins 승",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          ListTile(
            title: const Text(
              "백돌",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "$whiteWins 승",
              style: const TextStyle(fontSize: 18),
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

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    if (widget.gameMode == GameMode.pvc) {
      _ai = AILogic(boardSize: boardSize, difficulty: widget.difficulty!);
    }
    _stonePlacementController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _resetGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stonePlacementController.dispose();
    _confettiController.dispose();
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
      _statusMessage = "${_getPlayerName(_currentPlayer)} 시간 초과!";
      _recordGameResult(winner: winner);
      _showGameOverDialog(isTimeout: true);
    });
  }

  void _switchPlayer() {
    setState(() {
      _currentPlayer = (_currentPlayer == Player.black)
          ? Player.white
          : Player.black;
      _statusMessage = '${_getPlayerName(_currentPlayer)}의 차례';
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
                "🎉 GAME OVER 🎉",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kTextColor.withOpacity(0.8),
                ),
              ),
            ),
            content: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                child: const Text(
                  "다시하기",
                  style: TextStyle(fontSize: 16, color: kAccentColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetGame();
                },
              ),
              TextButton(
                child: const Text(
                  "메인으로",
                  style: TextStyle(fontSize: 16, color: kAccentColor),
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
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: kTextColor.withOpacity(0.7)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayerInfo(),
              const Spacer(),
              _buildBoard(),
              const Spacer(),
              _NeumorphicButton(icon: Icons.refresh, onPressed: _resetGame),
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
        ),
        _PlayerIndicator(
          name: _getPlayerName(Player.white),
          isTurn: _currentPlayer == Player.white && !_isGameOver,
          time: _currentPlayer == Player.white ? _timeRemaining : turnTimeLimit,
        ),
      ],
    );
  }

  Widget _buildBoard() {
    // 👇 LayoutBuilder 위젯으로 감싸서 정확한 보드 크기를 얻습니다.
    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxWidth는 화면 전체가 아닌, 이 위젯이 가질 수 있는 실제 너비입니다.
        final boardSizeDimension = constraints.maxWidth;

        return NeumorphicContainer(
          width: boardSizeDimension,
          height: boardSizeDimension,
          isCircle: false,
          child: GestureDetector(
            onTapUp: (details) {
              if (widget.gameMode == GameMode.pvc &&
                  _currentPlayer == Player.white)
                return;

              // 👇 기존 context.size 대신 정확한 boardSizeDimension을 사용합니다.
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
    final Paint linePaint = Paint()
      ..color = kDarkShadow.withOpacity(0.5)
      ..strokeWidth = 1.0;

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

    final double stoneRadius = squareSize / 2.2;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != Player.none) {
          final center = Offset(j * squareSize, i * squareSize);
          bool isLastMove = lastMove?.x == i && lastMove?.y == j;
          double scale = isLastMove
              ? (0.8 + 0.2 * Curves.easeOut.transform(animationValue))
              : 1.0;
          double currentRadius = stoneRadius * scale;

          final rect = Rect.fromCircle(center: center, radius: currentRadius);
          final stonePaint = Paint();

          if (board[i][j] == Player.black) {
            stonePaint.shader = const RadialGradient(
              colors: [Color(0xFF414141), Color(0xFF101010)],
            ).createShader(rect);
          } else {
            stonePaint.shader = const RadialGradient(
              colors: [kLightShadow, kBackgroundColor],
              stops: [0.7, 1.0],
            ).createShader(rect);
          }
          canvas.drawCircle(center, currentRadius, stonePaint);
        }
      }
    }

    if (winningLine.isNotEmpty) {
      final linePaint = Paint()
        ..color = kAccentColor.withOpacity(0.8)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;
      Point start = winningLine.reduce(
        (a, b) => a.x < b.x || (a.x == b.x && a.y < b.y) ? a : b,
      );
      Point end = winningLine.reduce(
        (a, b) => a.x > b.x || (a.x == b.x && a.y > b.y) ? a : b,
      );
      canvas.drawLine(
        Offset(start.y * squareSize, start.x * squareSize),
        Offset(end.y * squareSize, end.x * squareSize),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- 커스텀 위젯들 ---
class _NeumorphicButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  const _NeumorphicButton({this.text, this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: NeumorphicContainer(
        width: text != null ? 240 : 70,
        height: 70,
        isCircle: text == null,
        child: Center(
          child: text != null
              ? Text(
                  text!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                )
              : Icon(icon, size: 30, color: kTextColor.withOpacity(0.8)),
        ),
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
            color: kDarkShadow,
            offset: Offset(5, 5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: kLightShadow,
            offset: Offset(-5, -5),
            blurRadius: 15,
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
  const _PlayerIndicator({
    required this.name,
    required this.isTurn,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isTurn
            ? const [
                BoxShadow(color: kAccentColor, blurRadius: 10, spreadRadius: 2),
                BoxShadow(
                  color: kDarkShadow,
                  offset: Offset(3, 3),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: kLightShadow,
                  offset: Offset(-3, -3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isTurn ? kAccentColor : kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$time초",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: time <= 5 ? Colors.red : kTextColor.withOpacity(0.8),
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
