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

  // 은하수 효과
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

  // 벚꽃 효과
  void _drawCherryBlossomEffect(Canvas canvas, Size size) {
    final random = Random(2);
    for (int i = 0; i < 15; i++) {
      final petalPaint = Paint()
        ..color = Colors.pink.shade100.withOpacity(
          random.nextDouble() * 0.5 + 0.3,
        );
      final x =
          (random.nextDouble() * 1.2 * size.width -
              0.1 * size.width +
              (continuousAnimationValue * size.width / 2)) %
          size.width;
      final y =
          (random.nextDouble() * size.height +
              (continuousAnimationValue * size.height)) %
          size.height;
      final r = continuousAnimationValue * 2 * pi + random.nextDouble() * pi;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(r);
      canvas.drawCircle(Offset.zero, 3 + random.nextDouble() * 3, petalPaint);
      canvas.restore();
    }
  }

  // 심해 효과
  void _drawDeepSeaEffect(Canvas canvas, Size size) {
    final random = Random(3);
    for (int i = 0; i < 10; i++) {
      final bubblePaint = Paint()
        ..color = Colors.lightBlue.shade100.withOpacity(
          random.nextDouble() * 0.3,
        );
      final x = random.nextDouble() * size.width;
      final y =
          size.height -
          (random.nextDouble() * size.height +
                  continuousAnimationValue * size.height) %
              size.height;
      final radius = 2 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), radius, bubblePaint);
    }
  }

  // 젠가든 나뭇잎 효과
  void _drawDriftingLeafEffect(Canvas canvas, Size size) {
    final leafPaint = Paint()..color = Colors.brown.shade400;
    final progress = continuousAnimationValue;
    final x = size.width * progress;
    final y = size.height * 0.5 + sin(progress * 2 * pi) * 50;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(progress * 4 * pi);
    canvas.drawOval(const Rect.fromLTWH(-15, -5, 30, 10), leafPaint);
    canvas.restore();
  }

  // 다이아몬드 반짝임 효과
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

  // 유리알 반사광 효과
  void _drawGlassGlintEffect(Canvas canvas, Offset center, double radius) {
    if (placementAnimationValue > 0.5) {
      final progress = (placementAnimationValue - 0.5) * 2;
      final glintPaint = Paint()
        ..color = Colors.white.withOpacity(1 - progress)
        ..strokeWidth = 3.0;
      final start = center + Offset(-radius, radius) * progress;
      final end = center + Offset(radius, -radius) * progress;
      canvas.drawLine(start, end, glintPaint);
    }
  }

  // 황금알 반짝임 효과
  void _drawGoldGleamEffect(Canvas canvas, Offset center, double radius) {
    final progress = (sin(continuousAnimationValue * 2 * pi) + 1) / 2;
    if (progress > 0.95) {
      final gleamPaint = Paint()..color = Colors.white.withOpacity(0.8);
      canvas.drawCircle(
        center + Offset(-radius * 0.4, -radius * 0.4),
        radius * 0.1,
        gleamPaint,
      );
    }
  }

  // 마력 구슬 에너지 효과
  void _drawSwirlingEnergyEffect(
    Canvas canvas,
    Offset center,
    double radius,
    List<Color> colors,
  ) {
    final progress = continuousAnimationValue * 2 * pi;
    final paint = Paint();
    for (int i = 0; i < colors.length; i++) {
      final angle = progress + (i * pi);
      final energyCenter =
          center + Offset(cos(angle) * radius * 0.4, sin(angle) * radius * 0.4);
      paint.color = colors[i].withOpacity(0.7);
      canvas.drawCircle(energyCenter, radius * 0.2, paint);
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

    // --- 보드 특수 효과 그리기 ---
    switch (boardTheme.effectId) {
      case 'galaxy_stars':
        _drawGalaxyEffect(canvas, size);
        break;
      case 'cherry_blossom':
        _drawCherryBlossomEffect(canvas, size);
        break;
      case 'deep_sea':
        _drawDeepSeaEffect(canvas, size);
        break;
      case 'drifting_leaf':
        _drawDriftingLeafEffect(canvas, size);
        break;
    }

    // --- 라인 그리기 ---
    final Paint linePaint;
    if (boardTheme.effectId == 'glowing_lines') {
      final glowAmount = (sin(continuousAnimationValue * 2 * pi) + 1.5) / 2.5;
      linePaint = Paint()
        ..color = boardTheme.lineColor.withOpacity(glowAmount * 0.8)
        ..strokeWidth = 2.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowAmount * 4);
    } else {
      linePaint = Paint()
        ..color = boardTheme.lineColor.withOpacity(0.9)
        ..strokeWidth = 2.0;
    }
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

    // 화점 그리기
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

    // 돌 그리기
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

          // --- 돌 특수 효과 그리기 ---
          switch (stoneTheme.effectId) {
            case 'diamond_sparkle':
              _drawDiamondSparkleEffect(canvas, center, currentRadius);
              break;
            case 'glass_glint':
              _drawGlassGlintEffect(canvas, center, currentRadius);
              break;
            case 'gold_gleam':
              _drawGoldGleamEffect(canvas, center, currentRadius);
              break;
            case 'swirling_energy':
              _drawSwirlingEnergyEffect(
                canvas,
                center,
                currentRadius,
                (board[i][j] == Player.black)
                    ? [Colors.purpleAccent, Colors.deepPurple]
                    : [Colors.cyanAccent, Colors.lightBlue],
              );
              break;
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

    // 승리 라인 그리기
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
