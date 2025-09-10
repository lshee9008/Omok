import 'package:flutter/material.dart';
import '../utils/theme.dart';

enum ItemType { board, stones }

abstract class CustomItem {
  final String id;
  final String name;
  final int price;
  final ItemType type;
  final String? effectId; // 특수 효과 식별자 추가

  CustomItem({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    this.effectId, // 생성자에 추가
  });

  Widget buildPreview(BuildContext context);
}

class BoardTheme extends CustomItem {
  final Color boardColor;
  final Color lineColor;
  final List<BoxShadow> boxShadows;

  BoardTheme({
    required super.id,
    required super.name,
    required super.price,
    required this.boardColor,
    required this.lineColor,
    this.boxShadows = const [],
    super.effectId, // 부모 생성자에 전달
  }) : super(type: ItemType.board);

  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: boardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lineColor, width: 2),
        boxShadow: boxShadows,
      ),
    );
  }
}

class StoneTheme extends CustomItem {
  final Gradient blackStoneGradient;
  final Gradient whiteStoneGradient;
  final List<BoxShadow> blackStoneShadows;
  final List<BoxShadow> whiteStoneShadows;

  StoneTheme({
    required super.id,
    required super.name,
    required super.price,
    required this.blackStoneGradient,
    required this.whiteStoneGradient,
    this.blackStoneShadows = const [],
    this.whiteStoneShadows = const [],
    super.effectId, // 부모 생성자에 전달
  }) : super(type: ItemType.stones);

  @override
  Widget buildPreview(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: blackStoneGradient,
            boxShadow: blackStoneShadows,
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: whiteStoneGradient,
            boxShadow: whiteStoneShadows,
          ),
        ),
      ],
    );
  }
}

// 상점에서 판매될 아이템 목록
final List<CustomItem> shopItems = [
  // --- 기본 아이템 (무료) ---
  BoardTheme(
    id: 'board_basic',
    name: '기본 나무판',
    price: 0,
    boardColor: const Color(0xFFD2B48C),
    lineColor: const Color(0xFF6D4C41),
  ),
  StoneTheme(
    id: 'stones_basic',
    name: '기본 조약돌',
    price: 0,
    blackStoneGradient: const RadialGradient(
      colors: [Color(0xFF424242), kStoneBlackColor],
      stops: [0.0, 0.9],
    ),
    whiteStoneGradient: const RadialGradient(
      colors: [Color(0xFFFFFFFF), kStoneWhiteColor],
      stops: [0.1, 1.0],
    ),
  ),

  // --- 일반 유료 아이템 ---
  BoardTheme(
    id: 'board_cherry',
    name: '벚꽃 나무판',
    price: 100,
    boardColor: const Color(0xFFFFCDD2),
    lineColor: const Color(0xFFE57373),
  ),
  BoardTheme(
    id: 'board_deep_sea',
    name: '심해 석판',
    price: 150,
    boardColor: const Color(0xFF455A64),
    lineColor: const Color(0xFFB0BEC5),
  ),
  StoneTheme(
    id: 'stones_glass',
    name: '유리알',
    price: 120,
    blackStoneGradient: const RadialGradient(
      colors: [Color(0xAAE0E0E0), Color(0xAA212121)],
      stops: [0.1, 1.0],
    ),
    whiteStoneGradient: const RadialGradient(
      colors: [Color(0xDDFFFFFF), Color(0xAAEEEEEE)],
      stops: [0.1, 1.0],
    ),
  ),
  StoneTheme(
    id: 'stones_gold',
    name: '황금알',
    price: 300,
    blackStoneGradient: const RadialGradient(
      colors: [Color(0xFF424242), kStoneBlackColor],
      stops: [0.0, 0.9],
    ),
    whiteStoneGradient: const RadialGradient(
      colors: [Color(0xFFFFF59D), Color(0xFFFBC02D)],
    ),
    whiteStoneShadows: [
      BoxShadow(
        color: Colors.yellow.withOpacity(0.5),
        blurRadius: 5,
        spreadRadius: 2,
      ),
    ],
  ),

  // --- 삐까뻔쩍한 새로운 아이템들 ---
  BoardTheme(
    id: 'board_galaxy',
    name: '🌌 은하수 보드',
    price: 500,
    boardColor: const Color(0xFF1A237E),
    lineColor: const Color(0xFFE0F7FA),
    boxShadows: [
      BoxShadow(
        color: Colors.deepPurple.withOpacity(0.8),
        blurRadius: 20,
        spreadRadius: 5,
        offset: const Offset(0, 10),
      ),
    ],
    effectId: 'galaxy_stars',
  ),
  StoneTheme(
    id: 'stones_diamond',
    name: '💎 다이아몬드 돌',
    price: 750,
    blackStoneGradient: const RadialGradient(
      colors: [Color(0xFFB0BEC5), Color(0xFF607D8B), Color(0xFF263238)],
      stops: [0.0, 0.5, 1.0],
    ),
    whiteStoneGradient: const RadialGradient(
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
      stops: [0.0, 0.5, 1.0],
    ),
    blackStoneShadows: [
      BoxShadow(
        color: Colors.cyanAccent.withOpacity(0.7),
        blurRadius: 8,
        spreadRadius: 3,
      ),
    ],
    whiteStoneShadows: [
      BoxShadow(
        color: Colors.lightBlueAccent.withOpacity(0.7),
        blurRadius: 8,
        spreadRadius: 3,
      ),
    ],
    effectId: 'diamond_sparkle',
  ),
];
