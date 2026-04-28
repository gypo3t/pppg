import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

abstract final class AppCard {
  AppCard._();

  /// Largeur maximale des cartes de contenu sur tous les écrans.
  static const double maxWidth = 480.0;

  /// Carte blanche standard (fond, ombre, bordure, coins arrondis).
  static Widget card({required Widget child}) => Card(
    elevation: 2,
    shadowColor: AppColors.cardShadow,
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.cardBorder, width: 1),
    ),
    child: child,
  );

  /// Titre de section avec icône et ligne décorative.
  static Widget sectionTitle(String label, IconData icon) => Row(
    children: [
      Icon(icon, size: 15, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.0,
        ),
      ),
      const SizedBox(width: 8),
      const Expanded(child: Divider(color: AppColors.sectionLine)),
    ],
  );

  /// Séparateur interne standard entre tuiles d'une carte.
  static const divider = Divider(
    height: 1,
    indent: 20,
    endIndent: 20,
    color: AppColors.cardDivider,
  );
}
