import 'package:flutter/material.dart';
import 'dart:math';

// 게임의 상태를 나타내는 열거형
enum Player { none, black, white }

void main() {
  runApp(const OmokGameApp());
}

class OmokGameApp extends StatelessWidget {
  const OmokGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '숲속의 돌멩이 친구들',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Gaegu', // 귀여운 느낌의 폰트 (google_fonts 패키지 필요)
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int boardSize = 15;
  late List<List<Player>> _board;
  Player _currentPlayer = Player.black;
  bool _isGameOver = false;
  String _statusMessage = "흑돌의 차례입니다";

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _board = List.generate(
        boardSize,
        (i) => List.generate(boardSize, (j) => Player.none),
      );
      _currentPlayer = Player.black;
      _isGameOver = false;
      _statusMessage = "흑돌의 차례입니다";
    });
  }

  void _handleTap(int row, int col) {
    if (_isGameOver || _board[row][col] != Player.none) {
      return;
    }

    setState(() {
      _board[row][col] = _currentPlayer;
      if (_checkWin(row, col)) {
        _isGameOver = true;
        _statusMessage =
            '${_currentPlayer == Player.black ? "흑돌" : "백돌"}의 승리! 🎉';
      } else {
        _currentPlayer = _currentPlayer == Player.black
            ? Player.white
            : Player.black;
        _statusMessage =
            '${_currentPlayer == Player.black ? "흑돌" : "백돌"}의 차례입니다';
      }
    });
  }

  bool _checkWin(int row, int col) {
    Player player = _board[row][col];

    // 가로, 세로, 대각선 2방향 체크
    // [1, 0] (가로), [0, 1] (세로), [1, 1] (대각선 \), [1, -1] (대각선 /)
    const directions = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1],
    ];

    for (var dir in directions) {
      int count = 1;
      // 정방향 체크
      for (int i = 1; i < 5; i++) {
        int nextRow = row + dir[0] * i;
        int nextCol = col + dir[1] * i;
        if (nextRow >= 0 &&
            nextRow < boardSize &&
            nextCol >= 0 &&
            nextCol < boardSize &&
            _board[nextRow][nextCol] == player) {
          count++;
        } else {
          break;
        }
      }
      // 역방향 체크
      for (int i = 1; i < 5; i++) {
        int nextRow = row - dir[0] * i;
        int nextCol = col - dir[1] * i;
        if (nextRow >= 0 &&
            nextRow < boardSize &&
            nextCol >= 0 &&
            nextCol < boardSize &&
            _board[nextRow][nextCol] == player) {
          count++;
        } else {
          break;
        }
      }
      if (count >= 5) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EADF), // 따뜻한 배경색
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
                    image: AssetImage('assets/wood_board.png'), // 나무 판 이미지
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

    // 가로 및 세로 선 그리기
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

    // 돌 그리기
    final double stoneRadius = squareSize / 2.2;
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] != Player.none) {
          final stonePaint = Paint();
          final center = Offset(j * squareSize, i * squareSize);

          // 돌에 그림자 효과를 주어 입체감 표현 (고급스러움)
          final shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
          canvas.drawCircle(center.translate(2, 2), stoneRadius, shadowPaint);

          if (board[i][j] == Player.black) {
            stonePaint.color = const Color(0xFF333333);
          } else {
            stonePaint.color = const Color(0xFFFAFAFA);
          }
          canvas.drawCircle(center, stoneRadius, stonePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
