// lib/providers/game_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';

import '../models/game_models.dart';
import '../models/item_models.dart';
import '../services/locator.dart';
import '../services/player_data.dart';
import '../services/game_stats.dart';
import '../utils/ad_helper.dart';
import '../widgets/effects.dart';
import '../utils/theme.dart';

class GameProvider extends ChangeNotifier {
  static const int boardSize = 15;
  static const int turnTimeLimit = 20;

  late List<List<Player>> _board;
  Player _currentPlayer = Player.black;
  bool _isGameOver = false;
  String _statusMessage = "";

  late AILogic _ai;
  Timer? _timer;
  int _timeRemaining = turnTimeLimit;

  Point<int>? _lastMove;
  List<Point<int>> _winningLine = [];
  late ConfettiController confettiController;

  InterstitialAd? _interstitialAd;

  late BoardTheme _currentBoardTheme;
  late StoneTheme _currentStoneTheme;

  GameMode _gameMode = GameMode.pvc;
  Difficulty? _difficulty;

  // Getters
  List<List<Player>> get board => _board;
  Player get currentPlayer => _currentPlayer;
  bool get isGameOver => _isGameOver;
  String get statusMessage => _statusMessage;
  int get timeRemaining => _timeRemaining;
  Point<int>? get lastMove => _lastMove;
  List<Point<int>> get winningLine => _winningLine;
  BoardTheme get currentBoardTheme => _currentBoardTheme;
  StoneTheme get currentStoneTheme => _currentStoneTheme;

  final PlayerDataService _playerData = locator<PlayerDataService>();
  final GameStats _gameStats = locator<GameStats>();

  GameProvider() {
    confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadTheme();
    _loadInterstitialAd();
    resetGame(); // ✅ 수정: _resetGame -> resetGame
  }

  void _loadTheme() {
    String boardId = _playerData.getEquippedBoard();
    String stonesId = _playerData.getEquippedStones();
    _currentBoardTheme =
        shopItems.firstWhere(
              (item) => item.id == boardId,
              orElse: () => shopItems.firstWhere(
                (i) => i.id == PlayerDataService.defaultBoardId,
              ),
            )
            as BoardTheme;
    _currentStoneTheme =
        shopItems.firstWhere(
              (item) => item.id == stonesId,
              orElse: () => shopItems.firstWhere(
                (i) => i.id == PlayerDataService.defaultStonesId,
              ),
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
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void initializeGame(GameMode mode, {Difficulty? difficulty}) {
    _gameMode = mode;
    _difficulty = difficulty;
    if (mode == GameMode.pvc) {
      _ai = AILogic(boardSize: boardSize, difficulty: difficulty!);
    }
    resetGame();
  }

  // ✅ 수정: _resetGame -> resetGame
  void resetGame() {
    _board = List.generate(
      boardSize,
      (i) => List.generate(boardSize, (j) => Player.none),
    );
    _currentPlayer = Player.black;
    _isGameOver = false;
    _statusMessage = '${getPlayerName(_currentPlayer)}의 차례';
    _lastMove = null;
    _winningLine = [];
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = turnTimeLimit;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameOver) {
        timer.cancel();
        return;
      }
      if (_timeRemaining > 0) {
        _timeRemaining--;
      } else {
        timer.cancel();
        _handleTimeout();
      }
      notifyListeners();
    });
  }

  void _handleTimeout() {
    if (_isGameOver) return;
    _timer?.cancel();
    Player timedOutPlayer = _currentPlayer;

    _currentPlayer = (_currentPlayer == Player.black)
        ? Player.white
        : Player.black;
    _statusMessage =
        '${getPlayerName(timedOutPlayer)} 시간 초과!\n${getPlayerName(_currentPlayer)}의 차례';
    _startTimer();
    notifyListeners();

    if (_gameMode == GameMode.pvc &&
        !_isGameOver &&
        _currentPlayer == Player.white) {
      _statusMessage = "컴퓨터가 생각 중...";
      notifyListeners();
      _timer?.cancel();
      Timer(const Duration(milliseconds: 700), _computerMove);
    }
  }

  void _switchPlayer() {
    _currentPlayer = (_currentPlayer == Player.black)
        ? Player.white
        : Player.black;
    _statusMessage = '${getPlayerName(_currentPlayer)}의 차례';
    _startTimer();
    notifyListeners();
  }

  void placeStone(int row, int col) {
    if (_isGameOver || _board[row][col] != Player.none) return;

    _board[row][col] = _currentPlayer;
    _lastMove = Point(row, col);

    if (_checkWin(row, col)) {
      _timer?.cancel();
      _isGameOver = true;
      _statusMessage = '${getPlayerName(_currentPlayer)}의 승리!';
      _recordGameResult(winner: _currentPlayer);
      notifyListeners();
      return;
    }
    _switchPlayer();
  }

  void handleTap(int row, int col) {
    if (_isGameOver ||
        (_gameMode == GameMode.pvc && _currentPlayer == Player.white))
      return;
    placeStone(row, col);
    if (_gameMode == GameMode.pvc &&
        !_isGameOver &&
        _currentPlayer == Player.white) {
      _statusMessage = "컴퓨터가 생각 중...";
      notifyListeners();
      _timer?.cancel();
      Timer(const Duration(milliseconds: 700), _computerMove);
    }
  }

  void _computerMove() {
    if (_isGameOver) return;
    Point<int> bestMove = _ai.findBestMove(_board);
    placeStone(bestMove.x, bestMove.y);
  }

  void _recordGameResult({required Player winner}) {
    bool playerWon =
        (_gameMode == GameMode.pvc && winner == Player.black) ||
        (_gameMode == GameMode.pvp);

    if (playerWon) {
      _playerData.addAcorns(10);
    }

    if (_gameMode == GameMode.pvc) {
      if (winner == Player.black) {
        _gameStats.recordWin(GameMode.pvc, difficulty: _difficulty);
      } else {
        _gameStats.recordLoss(GameMode.pvc, difficulty: _difficulty);
      }
    } else {
      _gameStats.recordWin(GameMode.pvp, winner: winner);
    }
  }

  // ✅ 수정: _getPlayerName -> getPlayerName
  String getPlayerName(Player player) {
    if (_gameMode == GameMode.pvc) {
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
        _winningLine = line;
        return true;
      }
    }
    return false;
  }

  void showGameOverDialog(BuildContext context, {bool isTimeout = false}) {
    bool isPlayerLostToAI =
        (_gameMode == GameMode.pvc && currentPlayer == Player.white);
    if (!isTimeout && !isPlayerLostToAI) {
      confettiController.play();
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
                  resetGame();
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
                    _interstitialAd!.show().then((_) {
                      if (context.mounted) Navigator.of(context).pop();
                    });
                    _interstitialAd!.fullScreenContentCallback =
                        FullScreenContentCallback(
                          onAdDismissedFullScreenContent: (ad) => ad.dispose(),
                          onAdFailedToShowFullScreenContent: (ad, error) =>
                              ad.dispose(),
                        );
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
                    confettiController: confettiController,
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
  void dispose() {
    _timer?.cancel();
    confettiController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
