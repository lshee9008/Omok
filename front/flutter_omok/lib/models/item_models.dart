import 'package:flutter/material.dart';
import '../utils/theme.dart';

enum ItemType { board, stones }

abstract class CustomItem {
  final String id, name;
  final int price;
  final ItemType type;
  CustomItem({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });
  Widget buildPreview(BuildContext context);
}

class BoardTheme extends CustomItem {
  final Color boardColor, lineColor;
  BoardTheme({
    required super.id,
    required super.name,
    required super.price,
    required this.boardColor,
    required this.lineColor,
  }) : super(type: ItemType.board);
  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: boardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lineColor, width: 2),
      ),
    );
  }
}

class StoneTheme extends CustomItem {
  final Gradient blackStoneGradient, whiteStoneGradient;
  StoneTheme({
    required super.id,
    required super.name,
    required super.price,
    required this.blackStoneGradient,
    required this.whiteStoneGradient,
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
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: whiteStoneGradient,
          ),
        ),
      ],
    );
  }
}

final List<CustomItem> shopItems = [
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
  ),
];
