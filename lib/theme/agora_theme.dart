import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgoraColors {
  const AgoraColors._();

  static const paper = Color(0xFFFFFFFF);
  static const cream = Color(0xFFF8F2EA);
  static const canvas = Color(0xFFF4ECDF);
  static const ink = Color(0xFF19264C);
  static const ink2 = Color(0xFF2C3A66);
  static const inkSoft = Color(0xFF6A7390);
  static const mute = Color(0xFF8A93AC);
  static const hair = Color(0xFFECE4D5);
  static const hair2 = Color(0xFFE4DDCB);
  static const line = Color(0xFFD9D1BD);
  static const accent = Color(0xFF3F66E0);
  static const accent2 = Color(0xFF5D80FF);
  static const violet = Color(0xFF7B6AE0);
  static const pink = Color(0xFFE78FB3);
  static const peach = Color(0xFFF2B991);
  static const mint = Color(0xFF9CC9B5);
  static const gold = Color(0xFFE9CE9A);
  static const rose = Color(0xFFF3D6DC);
  static const lilac = Color(0xFFE6E0F5);
  static const sand = Color(0xFFF4ECDF);
  static const sky = Color(0xFFDDE6F7);
  static const green = Color(0xFF3FB67C);
}

class AgoraRadii {
  const AgoraRadii._();
  static const sm = Radius.circular(12);
  static const md = Radius.circular(16);
  static const lg = Radius.circular(18);
  static const xl = Radius.circular(24);
}

class AgoraShadows {
  const AgoraShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AgoraColors.ink.withOpacity(0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: AgoraColors.ink.withOpacity(0.06),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get panel => [
        BoxShadow(
          color: AgoraColors.ink.withOpacity(0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: AgoraColors.ink.withOpacity(0.08),
          blurRadius: 36,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get pop => [
        BoxShadow(
          color: AgoraColors.ink.withOpacity(0.18),
          blurRadius: 48,
          offset: const Offset(0, 16),
        ),
      ];
}

TextStyle displayStyle({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w700,
  Color color = AgoraColors.ink,
  double? height,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: -0.01 * fontSize,
  );
}

TextStyle bodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = AgoraColors.ink2,
  double? height,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

ThemeData buildAgoraTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AgoraColors.accent,
      surface: AgoraColors.cream,
      background: AgoraColors.cream,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AgoraColors.cream,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AgoraColors.ink2,
      displayColor: AgoraColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AgoraColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AgoraColors.paper,
      hintStyle: bodyStyle(color: AgoraColors.mute),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: AgoraColors.hair),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: AgoraColors.hair),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: AgoraColors.line),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AgoraColors.inkSoft),
    ),
  );
}
