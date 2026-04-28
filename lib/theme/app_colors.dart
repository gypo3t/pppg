import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ── Brand : brun-ambre ────────────────────────────────────────────
  /// Accent principal — texte, icônes, boutons sur fond blanc
  static const primary = Color(0xFF7B4F00);

  /// Variante foncée — état pressé, lettre surlignée
  static const primaryDark = Color(0xFF5A3900);

  /// Accent sur fond sombre (barre de navigation)
  static const primaryOnDark = Color.fromARGB(255, 233, 147, 18);

  /// Bordures, sliders
  static const primaryBorder = Color(0xFFBA8A40);

  /// Fond de surface — chips, tuiles de mise en avant
  static const primarySurface = Color(0xFFFFF8EE);

  // ── Cellules / grille (esthétique chaude conservée) ───────────────
  static const cellGradientStart = Color(0xFFFFCC80); // orange.200
  static const cellGradientEnd = Color(0xFFFFCA28); // amber.400
  static const cellNormalGradStart = Color(0xFFF9F5ED);
  static const cellNormalGradEnd = Color(0xFFDDD3B5);
  static const cellNormalBorder = Color(0xFFBBAA82);
  static const cellEditGradStart = Color(0xFFE8F0FF);
  static const cellEditGradEnd = Color(0xFFB8CEFF);
  static const cellEditBorder = Color(0xFF42A5F5); // blue.400
  static const cellNormalText = Color(0xFF3E2723);
  static const cellEditingText = Color(0xFF1A237E);

  // ── Barre de navigation ───────────────────────────────────────────
  static const navBar = Color(0xFF212121); // grey.900

  // ── Sémantiques ───────────────────────────────────────────────────
  static const success = Color(0xFF43A047); // green.600
  static const successDark = Color(0xFF388E3C); // green.700
  static const error = Color(0xFFD32F2F); // red.700
  static const errorMid = Color(0xFFE53935); // red.600
  static const errorLight = Color(0xFFEF5350); // red.400
  static const errorBorder = Color(0xFFEF9A9A); // red.200

  // ── Scores (liste de mots) ────────────────────────────────────────
  static const score1 = Color(0xFF78909C); // blueGrey.400
  static const score2 = Color(0xFF2196F3); // blue.500
  static const score3 = Color(0xFF009688); // teal.500
  static const score5 = Color(0xFFFB8C00); // orange.600 — chaud conservé
  static const scoreMax = Color(0xFFE53935); // red.600

  // ── Surfaces & layout ────────────────────────────────────────────
  /// Fond crème commun à tous les écrans
  static const scaffoldBg = Color(0xFFF2EDE6);
  /// Bordure des cartes blanches
  static const cardBorder = Color(0xFFDDD5C8);
  /// Séparateur interne des cartes
  static const cardDivider = Color(0xFFEDE8E0);
  /// Ligne des titres de section
  static const sectionLine = Color(0xFFBBAA82);
  /// Ombre des cartes
  static const cardShadow = Color(0x28000000);

  // ── Neutres ───────────────────────────────────────────────────────
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey = Color(0xFF9E9E9E); // grey.500
  static const grey600 = Color(0xFF757575); // grey.600
  static const black87 = Color(0xDD000000);
  static const black54 = Color(0x8A000000);
  static const black45 = Color(0x73000000);
  static const black38 = Color(0x61000000);
  static const black12 = Color(0x1F000000);
}
