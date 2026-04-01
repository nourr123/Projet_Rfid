import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color teal = Color(0xFF0D9488);

  // Couleurs pour les statuts des postes
  static const Color available = Color(0xFF4CAF50);  // Vert
  static const Color occupied = Color(0xFFFF6B6B);   // Rouge/Orange
  static const Color blocked = Color(0xFF718096);    // Gris
  static const Color booked = Color(0xFF4299E1);     // Bleu

  // Tons clairs pour les fonds
  static const Color availableLight = Color(0xFFC8E6C9);
  static const Color occupiedLight = Color(0xFFFFCDD2);
  static const Color blockedLight = Color(0xFFE2E8F0);
  static const Color bookedLight = Color(0xFFBBDEFB);

  // Neutres
  static const Color charcoal = Color(0xFF1F2937);
  static const Color gray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color offWhite = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);

  // États
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Ombres
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  // Ajout de buttonShadow qui manquait
  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  static Color? get primaryDark => null;
}