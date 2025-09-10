// lib/screens/game_screen.dart

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

  late GameProvider _gameProvider;
  bool _isDialogShowing = false; // 다이얼로그 중복 호출 방지 플래그

  @override
  void initState() {
    super.initState();

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

    _gameProvider.addListener(_onGameProviderChanged);
    _statusMessageController.forward();
  }

  void _onGameProviderChanged() {
    if (!mounted) return;

    final gameProvider = context.read<GameProvider>();

    // 마지막 수 애니메이션
    if (gameProvider.lastMove != null) {
      _stonePlacementController.forward(from: 0.0);
    }

    // ✅ 수정: 게임 종료 시 다이얼로그 표시 로직 개선
    if (gameProvider.isGameOver && !_isDialogShowing) {
      _isDialogShowing = true; // 다이얼로그가 곧 표시될 것임을 알림
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          gameProvider.showGameOverDialog(context);
          // 다이얼로그가 닫히면 플래그를 다시 false로 설정 (재시작 대비)
          Future.delayed(
            const Duration(seconds: 1),
            () => _isDialogShowing = false,
          );
        }
      });
    }

    _statusMessageController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_onGameProviderChanged);
    _stonePlacementController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          playerColor:
              gameProvider.currentStoneTheme.blackStoneGradient.colors.last,
          // ✅ 수정: 'initialTime' 매개변수 제거
          onTimeout: () => gameProvider.handleTimeout(),
        ),
        PlayerIndicator(
          name: gameProvider.getPlayerName(Player.white),
          isTurn:
              gameProvider.currentPlayer == Player.white &&
              !gameProvider.isGameOver,
          playerColor:
              gameProvider.currentStoneTheme.whiteStoneGradient.colors.first,
          // ✅ 수정: 'initialTime' 매개변수 제거
          onTimeout: () => gameProvider.handleTimeout(),
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
