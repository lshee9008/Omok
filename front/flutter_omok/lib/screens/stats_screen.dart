import 'package:flutter/material.dart';
import 'package:flutter_omok/main.dart';
import 'package:flutter_omok/services/game_stats.dart';
import 'package:flutter_omok/services/locator.dart';
import 'package:flutter_omok/utils/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statsService = locator<GameStats>();
    final stats = statsService.getStats();

    String getDifficulty(String key) => key.split('_')[1];
    int wins(String key) => stats[key] ?? 0;
    int losses(String key) => stats[key.replaceFirst('wins', 'losses')] ?? 0;

    List<Widget> pvcWidgets = stats.keys
        .where((k) => k.startsWith('pvc') && k.endsWith('wins'))
        .map(
          (key) => ListTile(
            title: Text(
              "컴퓨터 (${getDifficulty(key)})",
              style: GoogleFonts.jua(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            trailing: Text(
              "${wins(key)}승 ${losses(key)}패",
              style: GoogleFonts.jua(fontSize: 22, color: kTextColor),
            ),
          ),
        )
        .toList();

    int blackWins = stats['pvp_black_wins'] ?? 0;
    int whiteWins = stats['pvp_white_wins'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("전적 보기")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "VS 컴퓨터",
            style: GoogleFonts.jua(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 10),
          ...pvcWidgets,
          const Divider(height: 40),
          Text(
            "VS 친구",
            style: GoogleFonts.jua(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: Text(
              "흑돌",
              style: GoogleFonts.jua(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            trailing: Text(
              "$blackWins 승",
              style: GoogleFonts.jua(fontSize: 22, color: kTextColor),
            ),
          ),
          ListTile(
            title: Text(
              "백돌",
              style: GoogleFonts.jua(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            trailing: Text(
              "$whiteWins 승",
              style: GoogleFonts.jua(fontSize: 22, color: kTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
