import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 테마 색상 정의
const Color kBackgroundColor = Color(0xFFF0F4F8);
const Color kBoardColor = Color(0xFFD2B48C);
const Color kBoardLineColor = Color(0xFF6D4C41);
const Color kStoneBlackColor = Color(0xFF212121);
const Color kStoneWhiteColor = Color(0xFFF0F0F0);
const Color kHighlightColor = Color(0xFF6D9F71);
const Color kDangerColor = Color(0xFFE57373);
const Color kTextColor = Color(0xFF424242);
const Color kShadowColorDark = Color(0xFFA3B1C6);
const Color kShadowColorLight = Color(0xFFFFFFFF);

// 앱 전체 테마
final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: kBackgroundColor,
  textTheme: GoogleFonts.juaTextTheme(
    ThemeData.light().textTheme.apply(bodyColor: kTextColor),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kBackgroundColor,
    elevation: 0,
    iconTheme: const IconThemeData(color: kTextColor),
    titleTextStyle: GoogleFonts.jua(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kTextColor,
    ),
  ),
);
