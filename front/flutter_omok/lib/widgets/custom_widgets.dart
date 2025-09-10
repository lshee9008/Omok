import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import '../utils/theme.dart';

class NeumorphicButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final bool isCircle;

  const NeumorphicButton({
    super.key,
    this.text,
    this.icon,
    required this.onPressed,
    this.width = 240,
    this.height = 70,
    this.isCircle = false,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: NeumorphicContainer(
              width: widget.width,
              height: widget.height,
              isCircle: widget.isCircle,
              child: Center(
                child: widget.text != null
                    ? Text(
                        widget.text!,
                        style: GoogleFonts.jua(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                      )
                    : Icon(
                        widget.icon,
                        size: 30,
                        color: kTextColor.withOpacity(0.8),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NeumorphicContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;
  final bool isCircle;
  const NeumorphicContainer({
    super.key,
    this.width,
    this.height,
    required this.child,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: isCircle ? null : BorderRadius.circular(20),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: const [
          BoxShadow(
            color: kShadowColorDark,
            offset: Offset(4, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: kShadowColorLight,
            offset: Offset(-4, -4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class PlayerIndicator extends StatefulWidget {
  final String name;
  final bool isTurn;
  final Color playerColor;
  final VoidCallback onTimeout;

  const PlayerIndicator({
    super.key,
    required this.name,
    required this.isTurn,
    required this.playerColor,
    required this.onTimeout,
  });

  @override
  State<PlayerIndicator> createState() => _PlayerIndicatorState();
}

class _PlayerIndicatorState extends State<PlayerIndicator> {
  Timer? _timer;
  late int _timeRemaining;

  @override
  void initState() {
    super.initState();
    _timeRemaining = GameProvider.turnTimeLimit;
    if (widget.isTurn) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(PlayerIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTurn != oldWidget.isTurn) {
      _timer?.cancel();
      if (widget.isTurn) {
        _startTimer();
      } else {
        setState(() {
          _timeRemaining = GameProvider.turnTimeLimit;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemaining = GameProvider.turnTimeLimit;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (widget.isTurn)
            BoxShadow(
              color: kHighlightColor.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: kShadowColorDark.withOpacity(0.3),
            offset: const Offset(3, 3),
            blurRadius: 10,
          ),
          BoxShadow(
            color: kShadowColorLight.withOpacity(0.7),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
        border: widget.isTurn
            ? Border.all(color: kHighlightColor, width: 3)
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.playerColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.name,
                style: GoogleFonts.jua(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isTurn)
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: _timeRemaining / GameProvider.turnTimeLimit,
                      strokeWidth: 8,
                      backgroundColor: kTextColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timeRemaining <= 5 ? kDangerColor : kHighlightColor,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kTextColor.withOpacity(0.1),
                    ),
                  ),
                Text(
                  "$_timeRemaining",
                  style: GoogleFonts.jua(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: _timeRemaining <= 5 && widget.isTurn
                        ? kDangerColor
                        : kTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
