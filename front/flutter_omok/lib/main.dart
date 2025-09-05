import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 열거형 정의 ---
enum GameMode { pvp, pvc }

enum Player { none, black, white }

enum Difficulty { easy, normal, hard }

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
      key =
          'pvc_${difficulty.toString().split('.').last}_wins'; // pvc_hard_wins
      await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    } else {
      // PvP
      key = 'pvp_${winner.toString().split('.').last}_wins'; // pvp_black_wins
      await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    }
  }

  static Future<void> recordLoss(
    GameMode mode, {
    Difficulty? difficulty,
  }) async {
    // PVC에서만 패배를 기록 (플레이어 기준)
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

class OmokGameApp extends StatelessWidget {
  const OmokGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 이 FutureBuilder 부분이 모든 문제의 해결 열쇠입니다!
    return FutureBuilder(
      // 1. 다른 어떤 것보다 먼저 GameStats.init()을 실행해서 저장소를 준비시킵니다.
      future: GameStats.init(),
      builder: (context, snapshot) {
        // 2. 준비가 끝나면 (done)
        if (snapshot.connectionState == ConnectionState.done) {
          // 3. 준비가 끝났을 때만 앱의 첫 화면(MainScreen)을 보여줍니다.
          return MaterialApp(
            title: '숲속의 돌멩이 친구들',
            theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Gaegu'),
            home: const MainScreen(),
          );
        }
        // 준비가 아직 안 끝났다면 로딩 아이콘을 보여줍니다.
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

// --- 메인 화면 ---
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  // (이전 코드와 유사, '전적 보기' 버튼 추가)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EADF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '숲속의 오목',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 50),
            _buildMenuButton(
              context,
              '컴퓨터와 대결',
              () => _showDifficultyDialog(context),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(context, '친구와 대결', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const GameScreen(gameMode: GameMode.pvp),
                ),
              );
            }),
            const SizedBox(height: 20),
            _buildMenuButton(context, '전적 보기', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    /* 이전 코드와 동일 */
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3EADF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              "난이도 선택",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDifficultyButton(context, "쉬움", Difficulty.easy),
              const SizedBox(height: 10),
              _buildDifficultyButton(context, "보통", Difficulty.normal),
              const SizedBox(height: 10),
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
    /* 이전 코드와 동일 */
    return ElevatedButton(
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
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[500],
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        textStyle: const TextStyle(fontSize: 18),
      ),
      child: Text(text),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    /* 이전 코드와 동일 */
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 22, fontFamily: 'Gaegu'),
      ),
      child: Text(text),
    );
  }
}

// --- 전적 보기 화면 ---
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
      backgroundColor: const Color(0xFFF3EADF),
      appBar: AppBar(
        title: const Text("전적 보기"),
        backgroundColor: Colors.brown[600],
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
            trailing: Text("$whiteWins 승", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// --- 게임 화면 (타이머 기능 추가) ---
class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty? difficulty;
  const GameScreen({super.key, required this.gameMode, this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int boardSize = 15;
  static const int turnTimeLimit = 20; // 턴 제한 시간 (초)

  late List<List<Player>> _board;
  Player _currentPlayer = Player.black;
  bool _isGameOver = false;
  String _statusMessage = "";

  late AILogic _ai;
  Timer? _timer;
  int _timeRemaining = turnTimeLimit;

  @override
  void initState() {
    super.initState();
    if (widget.gameMode == GameMode.pvc) {
      _ai = AILogic(boardSize: boardSize, difficulty: widget.difficulty!);
    }
    _resetGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemaining = turnTimeLimit;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer?.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (_isGameOver) return;
    setState(() {
      _isGameOver = true;
      Player winner = _currentPlayer == Player.black
          ? Player.white
          : Player.black;
      _statusMessage =
          "${_getPlayerName(_currentPlayer)} 시간 초과! ${_getPlayerName(winner)} 승리!";
      _recordGameResult(winner: winner);
    });
  }

  void _resetGame() {
    setState(() {
      _board = List.generate(
        boardSize,
        (i) => List.generate(boardSize, (j) => Player.none),
      );
      _currentPlayer = Player.black;
      _isGameOver = false;
      _statusMessage = widget.gameMode == GameMode.pvc
          ? "당신의 차례입니다"
          : "흑돌의 차례입니다";
      _startTimer();
    });
  }

  void _placeStone(int row, int col) {
    if (_isGameOver || _board[row][col] != Player.none) return;

    setState(() {
      _board[row][col] = _currentPlayer;
    });

    if (_checkWin(row, col)) {
      _timer?.cancel();
      setState(() {
        _isGameOver = true;
        _statusMessage = '${_getPlayerName(_currentPlayer)}의 승리! 🎉';
      });
      _recordGameResult(winner: _currentPlayer);
      return;
    }
    _switchPlayer();
  }

  void _recordGameResult({required Player winner}) {
    if (widget.gameMode == GameMode.pvc) {
      if (winner == Player.black) {
        // 플레이어 승리
        GameStats.recordWin(GameMode.pvc, difficulty: widget.difficulty);
      } else {
        // 컴퓨터 승리
        GameStats.recordLoss(GameMode.pvc, difficulty: widget.difficulty);
      }
    } else {
      // PvP
      GameStats.recordWin(GameMode.pvp, winner: winner);
    }
  }

  void _switchPlayer() {
    setState(() {
      _currentPlayer = (_currentPlayer == Player.black)
          ? Player.white
          : Player.black;
      _statusMessage = '${_getPlayerName(_currentPlayer)}의 차례입니다';
      _startTimer();
    });
  }

  void _handleTap(int row, int col) {
    if (_isGameOver || _board[row][col] != Player.none) return;
    _placeStone(row, col);

    if (widget.gameMode == GameMode.pvc &&
        !_isGameOver &&
        _currentPlayer == Player.white) {
      setState(() {
        _statusMessage = "컴퓨터가 생각 중...";
      });
      _timer?.cancel(); // 컴퓨터 생각 중에는 타이머 멈춤
      Timer(const Duration(milliseconds: 500), _computerMove);
    }
  }

  void _computerMove() {
    if (_isGameOver) return;
    Point<int> bestMove = _ai.findBestMove(_board);
    _placeStone(bestMove.x, bestMove.y);
  }

  // ... 이하 _getPlayerName, _checkWin, build 메서드는 이전 코드와 동일 ...
  String _getPlayerName(Player player) {
    if (widget.gameMode == GameMode.pvc) {
      return player == Player.black ? "당신" : "컴퓨터";
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
      for (int i = 1; i < 5; i++) {
        int nextRow = row + dir[0] * i, nextCol = col + dir[1] * i;
        if (nextRow >= 0 &&
            nextRow < boardSize &&
            nextCol >= 0 &&
            nextCol < boardSize &&
            _board[nextRow][nextCol] == player)
          count++;
        else
          break;
      }
      for (int i = 1; i < 5; i++) {
        int nextRow = row - dir[0] * i, nextCol = col - dir[1] * i;
        if (nextRow >= 0 &&
            nextRow < boardSize &&
            nextCol >= 0 &&
            nextCol < boardSize &&
            _board[nextRow][nextCol] == player)
          count++;
        else
          break;
      }
      if (count >= 5) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EADF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[700]),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 타이머 UI 추가
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimerDisplay(Player.black),
                  Text(
                    '숲속의 오목',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[700],
                    ),
                  ),
                  _buildTimerDisplay(Player.white),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 24, color: Colors.brown[600]),
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/wood_board.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                margin: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTapUp: (details) {
                    if (widget.gameMode == GameMode.pvc &&
                        _currentPlayer == Player.white)
                      return;
                    final size = context.size?.width ?? 300;
                    final squareSize = (size - 32) / (boardSize - 1);
                    final row = (details.localPosition.dy / squareSize).round();
                    final col = (details.localPosition.dx / squareSize).round();
                    _handleTap(row, col);
                  },
                  child: CustomPaint(
                    painter: BoardPainter(board: _board, boardSize: boardSize),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.refresh),
              label: const Text('다시하기', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 타이머 UI 위젯
  Widget _buildTimerDisplay(Player player) {
    bool isCurrentTurn = _currentPlayer == player && !_isGameOver;
    return Column(
      children: [
        Text(
          _getPlayerName(player),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isCurrentTurn ? Colors.red[700] : Colors.brown[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isCurrentTurn ? '$_timeRemaining' : '-',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isCurrentTurn ? Colors.red[700] : Colors.brown[800],
          ),
        ),
      ],
    );
  }
}

// --- BoardPainter와 AILogic 클래스 ---
// (이전 코드와 완전히 동일하므로 생략하지 않고 포함합니다)
class BoardPainter extends CustomPainter {
  final List<List<Player>> board;
  final int boardSize;
  BoardPainter({required this.board, required this.boardSize});
  @override
  void paint(Canvas canvas, Size size) {
    final double squareSize = size.width / (boardSize - 1);
    final Paint linePaint = Paint()
      ..color = Colors.brown[800]!
      ..strokeWidth = 1.5;
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
    final Paint dotPaint = Paint()..color = Colors.brown[800]!;
    final double dotRadius = 4.0;
    final List<Point<int>> dotPositions = [
      Point(3, 3),
      Point(3, 11),
      Point(11, 3),
      Point(11, 11),
      Point(7, 7),
    ];
    for (var pos in dotPositions) {
      canvas.drawCircle(
        Offset(pos.x * squareSize, pos.y * squareSize),
        dotRadius,
        dotPaint,
      );
    }
    final double stoneRadius = squareSize / 2.2;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != Player.none) {
          final stonePaint = Paint();
          final center = Offset(j * squareSize, i * squareSize);
          final shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
          canvas.drawCircle(center.translate(2, 2), stoneRadius, shadowPaint);
          stonePaint.color = (board[i][j] == Player.black)
              ? const Color(0xFF333333)
              : const Color(0xFFFAFAFA);
          canvas.drawCircle(center, stoneRadius, stonePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AILogic {
  final int boardSize;
  final Difficulty difficulty;
  AILogic({required this.boardSize, required this.difficulty});
  Point<int> findBestMove(List<List<Player>> board) {
    if (difficulty == Difficulty.easy) {
      return _findBestMoveEasy(board);
    }
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
    int count = 1;
    int openEnds = 0;
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
