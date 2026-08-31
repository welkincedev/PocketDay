// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: app_colors.dart
//
// Purpose:
// Centralized color palette definitions for PocketDay.
//
// Responsibilities:
// - Define brand emerald green and indigo accent colors.
// - Define income green, expense red, warning amber, and info blue.
// - Define light theme and dark theme surface, background, and text colors.
// - Define shimmer loading effect base and highlight colors.
//
// Data Flow:
// AppColors → AppTheme → ThemeData → Widget Tree
//
// Important Rules:
// - Do NOT hardcode hex colors in feature widgets; always consume AppColors or Theme.of(context).
// - Income is green (0xFF10B981), Expense is red (0xFFEF4444).
//
// Main Constants:
// - Brand: primary, primaryDark, primaryLight, accent
// - Financial: income, expense, warning, info
// - Light/Dark Palettes: lightBackground, darkBackground, lightSurface, darkSurface
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color accent = Color(0xFF6366F1); // Indigo

  // Status / Financial Colors
  static const Color income = Color(0xFF10B981); // Green
  static const Color expense = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Shimmer
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);
  static const Color shimmerBaseDark = Color(0xFF334155);
  static const Color shimmerHighlightDark = Color(0xFF475569);
}
