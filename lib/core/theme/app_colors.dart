import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF5A52D5);
  static const secondary = Color(0xFFFF6584);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE53935);

  // Light theme surfaces
  static const backgroundLight = Color(0xFFF8F9FE);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF6B7280);

  // Dark theme surfaces
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E2E);
  static const textPrimaryDark = Color(0xFFE0E0E0);
  static const textSecondaryDark = Color(0xFF9CA3AF);

  // Habit color palette (12 Material colors)
  static const habitColors = [
    Color(0xFF6C63FF), // Purple (brand)
    Color(0xFFFF6584), // Coral
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF2196F3), // Blue
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF9C27B0), // Deep Purple
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF009688), // Teal
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  // Heatmap intensity colors (empty → full)
  static const heatmap0 = Color(0xFFEBEDF0); // no completion
  static const heatmap1 = Color(0xFFC6E48B); // 1–25%
  static const heatmap2 = Color(0xFF7BC96F); // 26–50%
  static const heatmap3 = Color(0xFF239A3B); // 51–75%
  static const heatmap4 = Color(0xFF196127); // 76–100%
  static const heatmapDark0 = Color(0xFF161B22);
  static const heatmapDark1 = Color(0xFF0E4429);
  static const heatmapDark2 = Color(0xFF006D32);
  static const heatmapDark3 = Color(0xFF26A641);
  static const heatmapDark4 = Color(0xFF39D353);
}
