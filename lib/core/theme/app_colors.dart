import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand Principal ──────────────────────────────────────
  static const primary = Color(0xFF7C5CFC);
  static const primaryLight = Color(0xFF9B7EFD);
  static const primaryDark = Color(0xFF5B3FD4);
  static const secondary = Color(0xFFFF6B9D);
  static const secondaryLight = Color(0xFFFF8FB5);
  static const accent = Color(0xFFFFD166);
  static const accentGreen = Color(0xFF06D6A0);
  static const accentBlue = Color(0xFF4CC9F0);

  // ── Backgrounds ──────────────────────────────────────────
  static const bgDark = Color(0xFF0F0E17);
  static const bgMedium = Color(0xFF1A1A2E);
  static const bgLight = Color(0xFF16213E);
  static const bgCard = Color(0xFF1E1E35);
  static const bgCardHover = Color(0xFF252540);

  // ── Glassmorphism ─────────────────────────────────────────
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x22FFFFFF);
  static const glassHighlight = Color(0x33FFFFFF);

  // ── Texto ─────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF5F5F8);
  static const textSecondary = Color(0xFFB4B4C8);
  static const textMuted = Color(0xFF6B6B8A);
  static const textDisabled = Color(0xFF3D3D5C);

  // ── Emoções ───────────────────────────────────────────────
  static const emotionJoy = Color(0xFFFFD166);
  static const emotionSadness = Color(0xFF4CC9F0);
  static const emotionAnger = Color(0xFFF72585);
  static const emotionFear = Color(0xFF7209B7);
  static const emotionAnxiety = Color(0xFFFF6B35);
  static const emotionHope = Color(0xFF06D6A0);
  static const emotionLove = Color(0xFFFF6B9D);
  static const emotionCalm = Color(0xFF90E0EF);
  static const emotionSurprise = Color(0xFFFFB703);
  static const emotionDisgust = Color(0xFF9B2226);
  static const emotionLoneliness = Color(0xFF6A4C93);
  static const emotionGuilt = Color(0xFFE07A5F);
  static const emotionMotivation = Color(0xFF3BB273);
  static const emotionExhaustion = Color(0xFF8D99AE);

  // ── Níveis ────────────────────────────────────────────────
  static const levelLight = Color(0xFF06D6A0);
  static const levelModerate = Color(0xFFFFD166);
  static const levelHigh = Color(0xFFFF6B35);
  static const levelCritical = Color(0xFFF72585);

  // ── Status ────────────────────────────────────────────────
  static const success = Color(0xFF06D6A0);
  static const warning = Color(0xFFFFD166);
  static const error = Color(0xFFFF4757);
  static const info = Color(0xFF4CC9F0);

  // ── Gradients ─────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5CFC), Color(0xFFFF6B9D)],
  );

  static const gradientBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0E17), Color(0xFF1A1A2E)],
  );

  static const gradientJoy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD166), Color(0xFFFF6B35)],
  );

  static const gradientCalm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CC9F0), Color(0xFF06D6A0)],
  );

  static const gradientEnergy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5CFC), Color(0xFF4CC9F0)],
  );

  // ── Shadows ───────────────────────────────────────────────
  static List<BoxShadow> get shadowPrimary => [
        BoxShadow(
          color: primary.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
