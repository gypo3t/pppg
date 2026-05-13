import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  // ── Valeurs & titres ─────────────────────────────────────────────────
  static const statValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.black87,
  );

  static const sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.primary,
  );

  static const pauseTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    color: Colors.white,
  );

  // ── Corps de texte ───────────────────────────────────────────────────
  static const body = TextStyle(fontSize: 14, color: AppColors.black87);
  static const bodySmall = TextStyle(fontSize: 13, color: AppColors.black87);

  static const subtitle = TextStyle(
    fontSize: 12,
    color: AppColors.black45,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.black38,
  );

  // ── Mots (liste de résultats) ────────────────────────────────────────
  static const wordSelected = TextStyle(
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: AppColors.primary,
  );

  static const wordNormal = TextStyle(
    fontWeight: FontWeight.normal,
    letterSpacing: 1.5,
    color: AppColors.black87,
  );

  // ── En-têtes tableau ─────────────────────────────────────────────────
  static const tableHeader = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.black54,
  );

  // ── Badges & chips ───────────────────────────────────────────────────
  static const scoreBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const chip = TextStyle(fontSize: 12);

  // ── Timer (chiffres tabulaires) ──────────────────────────────────────
  static const timer = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: Colors.white,
  );

  // ── Toasts ───────────────────────────────────────────────────────────
  static const toast = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
