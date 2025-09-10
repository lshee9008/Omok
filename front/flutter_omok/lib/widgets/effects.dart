import 'dart:math';
import 'package:flutter/material.dart';

class RaindropAnimation extends StatefulWidget {
  const RaindropAnimation({super.key});
  @override
  State<RaindropAnimation> createState() => _RaindropAnimationState();
}

class _RaindropAnimationState extends State<RaindropAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Raindrop> _raindrops = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.addListener(() {
      setState(() {
        if (_random.nextDouble() < 0.1) {
          _raindrops.add(
            Raindrop(
              x: _random.nextDouble() * MediaQuery.of(context).size.width,
              y: -_random.nextDouble() * 100,
              speed: 5 + _random.nextDouble() * 5,
              size: 1 + _random.nextDouble() * 2,
              opacity: 0.5 + _random.nextDouble() * 0.5,
            ),
          );
        }
        _raindrops.removeWhere(
          (drop) => drop.y > MediaQuery.of(context).size.height + 50,
        );
        for (var drop in _raindrops) {
          drop.y += drop.speed;
        }
      });
    });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: RaindropPainter(raindrops: _raindrops),
        child: Container(),
      ),
    );
  }
}

class Raindrop {
  double x, y, speed, size, opacity;
  Raindrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class RaindropPainter extends CustomPainter {
  final List<Raindrop> raindrops;
  RaindropPainter({required this.raindrops});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..strokeCap = StrokeCap.round;
    for (var drop in raindrops) {
      paint.color = Colors.blue.withOpacity(drop.opacity);
      paint.strokeWidth = drop.size;
      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x, drop.y + drop.size * 5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RaindropPainter oldDelegate) =>
      oldDelegate.raindrops != raindrops;
}
