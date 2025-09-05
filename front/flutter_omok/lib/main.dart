import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// 게임 관련 열거형
enum GameMode { pvp, pvc }

enum Player { none, black, white }

enum Difficulty { easy, normal, hard }

void main() {
  runApp(const OmokGameApp());
}

class OmokGameApp extends StatelessWidget {
  const OmokGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '숲속의 돌멩이 친구들',
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Gaegu'),
      home: const MainScreen(),
    );
  }
}

// 메인 화면 (게임 모드 및 난이도 선택)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
            _buildMenuButton(
              context,
              '컴퓨터와 대결',
              () => _showDifficultyDialog(context),
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
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop(); // 다이얼로그 닫기
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

// 게임 화면
class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty? difficulty;
  const GameScreen({super.key, required this.gameMode, this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int boardSize = 15;
  late List<List<Player>> _board;
  Player _currentPlayer = Player.black;
  bool _isGameOver = false;
  String _statusMessage = "당신의 차례입니다";

  // AI 로직을 위한 변수
  late final AILogic _ai;

  @override
  void initState() {
    super.initState();
    _resetGame();
    if (widget.gameMode == GameMode.pvc) {
      _ai = AILogic(boardSize: boardSize, difficulty: widget.difficulty!);
    }
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
    });
  }

  void _handleTap(int row, int col) {
    if (_isGameOver || _board[row][col] != Player.none) return;

    _placeStone(row, col);

    // 컴퓨터 모드일 경우, 컴퓨터가 수를 둠
    if (widget.gameMode == GameMode.pvc &&
        !_isGameOver &&
        _currentPlayer == Player.white) {
      setState(() {
        _statusMessage = "컴퓨터가 생각 중...";
      });
      Timer(const Duration(milliseconds: 500), _computerMove);
    }
  }

  void _placeStone(int row, int col) {
    if (_isGameOver || _board[row][col] != Player.none) return;

    setState(() {
      _board[row][col] = _currentPlayer;
    });

    if (_checkWin(row, col)) {
      setState(() {
        _isGameOver = true;
        _statusMessage = '${_getPlayerName(_currentPlayer)}의 승리! 🎉';
      });
      return;
    }

    _switchPlayer();
  }

  void _computerMove() {
    if (_isGameOver) return;
    Point<int> bestMove = _ai.findBestMove(_board);
    _placeStone(bestMove.x, bestMove.y);
  }

  void _switchPlayer() {
    setState(() {
      _currentPlayer = _currentPlayer == Player.black
          ? Player.white
          : Player.black;
      _statusMessage = '${_getPlayerName(_currentPlayer)}의 차례입니다';
    });
  }

  // --- 이하 UI 및 게임 로직 (이전 코드와 유사/동일) ---

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
            Text(
              '숲속의 오목',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 24, color: Colors.brown[600]),
            ),
            const SizedBox(height: 20),
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
}

// BoardPainter 클래스는 이전과 동일합니다.
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

// ----------------------------------------------------
// ✨✨ 새로운 지능형 AI 로직 ✨✨
// ----------------------------------------------------
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

    // 필승/필패 체크를 위한 임시 보드
    var tempBoard = board.map((row) => List<Player>.from(row)).toList();

    // 1 & 2. 필승의 한 수 또는 필패의 방어 찾기
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (tempBoard[r][c] == Player.none) {
          // AI가 이기는 수
          tempBoard[r][c] = Player.white;
          if (_checkWin(r, c, Player.white, tempBoard)) return Point(r, c);

          // 플레이어가 이기는 수 (막아야 함)
          tempBoard[r][c] = Player.black;
          if (_checkWin(r, c, Player.black, tempBoard)) {
            bestScore = 100000; // 매우 높은 점수 부여
            bestMove = Point(r, c);
          }
          tempBoard[r][c] = Player.none; // 원상 복구
        }
      }
    }

    // 3. 점수 기반 최적의 수 찾기
    if (bestMove.x == -1) {
      // 필패 방어 수가 없었다면
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

    // 만약 둘 곳이 없다면 랜덤한 빈 곳에 둔다.
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

  // 쉬움 난이도 로직
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

  // 보통, 어려움 난이도를 위한 점수 계산
  int _calculateScore(int r, int c, List<List<Player>> board) {
    int score = 0;
    // [가로, 세로, 대각선\, 대각선/]
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      // AI(백돌)의 공격 점수
      score += _getScoreForLine(r, c, dir[0], dir[1], Player.white, board);
      // 플레이어(흑돌)를 막는 수비 점수
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
    int count = 1; // 연속된 돌의 수
    int openEnds = 0; // 열린 공간의 수

    // 정방향
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

    // 역방향
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

    // 난이도에 따른 점수 차등 부여
    bool isHard = difficulty == Difficulty.hard;

    if (count >= 4) return 50000;
    if (count == 3 && openEnds == 2) return isHard ? 5000 : 800; // 열린 셋
    if (count == 3 && openEnds == 1) return isHard ? 500 : 100;
    if (count == 2 && openEnds == 2) return isHard ? 300 : 50; // 열린 둘
    if (count == 2 && openEnds == 1) return 10;
    if (count == 1 && openEnds == 2) return 5;

    return 0;
  }

  // 필승 체크를 위한 보조 함수
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
