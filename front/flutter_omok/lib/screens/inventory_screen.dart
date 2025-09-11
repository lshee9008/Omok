import 'package:flutter/material.dart';
import 'package:flutter_omok/providers/game_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/item_models.dart';
import '../services/locator.dart';
import '../services/player_data.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final PlayerDataService _playerData = locator<PlayerDataService>();
  late List<String> _ownedItems;
  late String _equippedBoard;
  late String _equippedStones;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  void _loadPlayerData() {
    setState(() {
      _ownedItems = _playerData.getOwnedItems();
      _equippedBoard = _playerData.getEquippedBoard();
      _equippedStones = _playerData.getEquippedStones();
    });
  }

  Future<void> _equipItem(CustomItem item) async {
    if (item.type == ItemType.board) {
      await _playerData.setEquippedBoard(item.id);
    } else if (item.type == ItemType.stones) {
      await _playerData.setEquippedStones(item.id);
    }
    _loadPlayerData();

    // ✨ 장착 후 GameProvider에 테마를 다시 불러오라고 알림
    if (mounted) {
      context.read<GameProvider>().reloadTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownedBoards = shopItems
        .where(
          (item) =>
              item.type == ItemType.board && _ownedItems.contains(item.id),
        )
        .toList();
    final ownedStones = shopItems
        .where(
          (item) =>
              item.type == ItemType.stones && _ownedItems.contains(item.id),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('보관함')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('오목판', style: GoogleFonts.jua(fontSize: 28)),
          const SizedBox(height: 10),
          _buildItemGrid(ownedBoards, _equippedBoard),
          const SizedBox(height: 30),
          Text('오목알', style: GoogleFonts.jua(fontSize: 28)),
          const SizedBox(height: 10),
          _buildItemGrid(ownedStones, _equippedStones),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<CustomItem> items, String equippedId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isEquipped = item.id == equippedId;
        return GestureDetector(
          onTap: () => _equipItem(item),
          child: Stack(
            alignment: Alignment.center,
            children: [
              NeumorphicContainer(
                isCircle: false,
                child: item.buildPreview(context),
              ),
              if (isEquipped)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kHighlightColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kHighlightColor, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
