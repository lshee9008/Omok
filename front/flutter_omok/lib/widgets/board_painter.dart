import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../models/item_models.dart';
import '../utils/theme.dart';

class BoardPainter extends CustomPainter {
  final List<List<Player>> board;
  final int boardSize;
  final Point<int>? lastMove;
  final double placementAnimationValue;
  final double continuousAnimationValue;
  final List<Point<int>> winningLine;
  final BoardTheme boardTheme;
  final StoneTheme stoneTheme;

  BoardPainter({
    required this.board,
    required this.boardSize,
    this.lastMove,
    required this.placementAnimationValue,
    required this.continuousAnimationValue,
    required this.winningLine,
    required this.boardTheme,
    required this.stoneTheme,
  });

  void _drawGalaxyEffect(Canvas canvas, Size size) {
    final random = Random(1);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 100; i++) {
      final opacity =
          (sin(2 * pi * continuousAnimationValue + random.nextDouble() * pi) +
              1) /
          2;
      starPaint.color = Colors.white.withOpacity(opacity * 0.8);
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawDiamondSparkleEffect(Canvas canvas, Offset center, double radius) {
    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final angle = continuousAnimationValue * 2 * pi;
    final progress = (sin(continuousAnimationValue * 2 * pi) + 1) / 2;
    if (progress > 0.7) {
      for (int i = 0; i < 4; i++) {
        final currentAngle = angle + i * (pi / 2);
        final start =
            center +
            Offset(cos(currentAngle), sin(currentAngle)) * radius * 0.8;
        final end =
            center +
            Offset(cos(currentAngle), sin(currentAngle)) *
                radius *
                1.2 *
                progress;
        canvas.drawLine(start, end, sparklePaint);
      }
    }
  }

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

    if (boardTheme.effectId == 'galaxy_stars') {
      _drawGalaxyEffect(canvas, size);
    }

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
              ? (0.7 +
                    0.3 * Curves.elasticOut.transform(placementAnimationValue))
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

          if (stoneTheme.effectId == 'diamond_sparkle') {
            _drawDiamondSparkleEffect(canvas, center, currentRadius);
          }

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

    if (winningLine.isNotEmpty && placementAnimationValue > 0) {
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
          start.y * squareSize + dx * placementAnimationValue,
          start.x * squareSize + dy * placementAnimationValue,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
