import 'dart:math';

enum GameMode { pvp, pvc }

enum Player { none, black, white }

enum Difficulty { easy, normal, hard }

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
