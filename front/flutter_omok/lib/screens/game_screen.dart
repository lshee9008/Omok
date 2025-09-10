import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../widgets/board_painter.dart';
import '../widgets/custom_widgets.dart';
import '../utils/theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _stonePlacementController;
  late AnimationController _statusMessageController;
  late Animation<double> _statusMessageFadeAnimation;
  late Animation<Offset> _statusMessageSlideAnimation;

  // ✅ 1. GameProvider 인스턴스를 저장할 변수를 선언합니다.
  late GameProvider _gameProvider;

  @override
  void initState() {
    super.initState();

    // ✅ 2. initState에서 context가 안전할 때 Provider 인스턴스를 변수에 저장합니다.
    _gameProvider = context.read<GameProvider>();

    _stonePlacementController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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

    // ✅ 3. 저장해둔 _gameProvider 변수를 사용하여 리스너를 추가합니다.
    _gameProvider.addListener(_onGameProviderChanged);
    _statusMessageController.forward();
  }

  void _onGameProviderChanged() {
    if (!mounted) return; // 위젯이 트리에 없을 경우 아무것도 하지 않음

    final gameProvider = context
        .read<GameProvider>(); // 이 메서드는 dispose가 아니므로 안전
    if (gameProvider.lastMove != null) {
      _stonePlacementController.forward(from: 0.0);
    }
    if (gameProvider.isGameOver) {
      // build가 완료된 후 다이얼로그를 안전하게 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent != true) {
          gameProvider.showGameOverDialog(context);
        }
      });
    }
    _statusMessageController.forward(from: 0.0);
  }

  @override
  void dispose() {
    // ✅ 4. dispose에서는 context 대신 저장해둔 _gameProvider 변수를 사용합니다.
    _gameProvider.removeListener(_onGameProviderChanged);

    _stonePlacementController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI 업데이트를 위해 context.watch 사용
    final gameProvider = context.watch<GameProvider>();

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
              _buildPlayerInfo(gameProvider),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _statusMessageFadeAnimation,
                child: SlideTransition(
                  position: _statusMessageSlideAnimation,
                  child: Text(
                    gameProvider.statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jua(fontSize: 30, color: kTextColor),
                  ),
                ),
              ),
              const Spacer(),
              _buildBoard(context, gameProvider),
              const Spacer(),
              NeumorphicButton(
                icon: Icons.refresh,
                onPressed: () => context.read<GameProvider>().resetGame(),
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

  Widget _buildPlayerInfo(GameProvider gameProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        PlayerIndicator(
          name: gameProvider.getPlayerName(Player.black),
          isTurn:
              gameProvider.currentPlayer == Player.black &&
              !gameProvider.isGameOver,
          time: gameProvider.currentPlayer == Player.black
              ? gameProvider.timeRemaining
              : GameProvider.turnTimeLimit,
          playerColor:
              gameProvider.currentStoneTheme.blackStoneGradient.colors.last,
          turnTimeLimit: GameProvider.turnTimeLimit,
        ),
        PlayerIndicator(
          name: gameProvider.getPlayerName(Player.white),
          isTurn:
              gameProvider.currentPlayer == Player.white &&
              !gameProvider.isGameOver,
          time: gameProvider.currentPlayer == Player.white
              ? gameProvider.timeRemaining
              : GameProvider.turnTimeLimit,
          playerColor:
              gameProvider.currentStoneTheme.whiteStoneGradient.colors.first,
          turnTimeLimit: GameProvider.turnTimeLimit,
        ),
      ],
    );
  }

  Widget _buildBoard(BuildContext context, GameProvider gameProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSizeDimension = constraints.maxWidth;
        final double squareSize =
            boardSizeDimension / (GameProvider.boardSize - 1);
        return NeumorphicContainer(
          width: boardSizeDimension,
          height: boardSizeDimension,
          isCircle: false,
          child: GestureDetector(
            onTapUp: (details) {
              final col = (details.localPosition.dx / squareSize).round().clamp(
                0,
                GameProvider.boardSize - 1,
              );
              final row = (details.localPosition.dy / squareSize).round().clamp(
                0,
                GameProvider.boardSize - 1,
              );
              context.read<GameProvider>().handleTap(row, col);
            },
            child: AnimatedBuilder(
              animation: _stonePlacementController,
              builder: (context, child) => CustomPaint(
                painter: BoardPainter(
                  board: gameProvider.board,
                  boardSize: GameProvider.boardSize,
                  lastMove: gameProvider.lastMove,
                  animationValue: _stonePlacementController.value,
                  winningLine: gameProvider.winningLine,
                  boardTheme: gameProvider.currentBoardTheme,
                  stoneTheme: gameProvider.currentStoneTheme,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
