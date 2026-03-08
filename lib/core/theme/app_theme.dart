import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Full Material Design 3 theme.
/// ColorScheme is generated from the purple seed via M3 tonal palettes.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // ── M3 ColorScheme from seed ───────────────────────────────────────────
    // Flutter derives the full 30-role tonal palette from this single colour.
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,   // #6C63FF purple
      brightness: brightness,
    );

    final textTheme = isLight
        ? AppTypography.lightTextTheme
        : AppTypography.darkTextTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: textTheme,

      // ── AppBar ────────────────────────────────────────────────────────────
      // M3 spec: AppBar uses titleLarge; scrolled-under elevation creates a
      // surface-tint overlay (do NOT disable scrolledUnderElevation).
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(color: cs.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      // M3 Card: Elevated (surface+shadow) | Filled (surfaceContainerHighest)
      // | Outlined. Default is Elevated at tonal elevation 1.
      // Shape = Medium (12 dp).
      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Buttons ───────────────────────────────────────────────────────────
      // M3 FilledButton shape = Full (stadium). We map ElevatedButton to the
      // M3 "Filled" style (primary fill, onPrimary text, no shadow).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Input decoration ─────────────────────────────────────────────────
      // M3 TextField: Filled style with 4 dp top corners; Outlined with 4 dp
      // all corners. Using outlined here for clarity.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        labelStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: cs.primary),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      // M3 chip shape = Small (8 dp).
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.secondaryContainer,
        checkmarkColor: cs.onSecondaryContainer,
        side: BorderSide(color: cs.outlineVariant),
        labelStyle: textTheme.labelMedium?.copyWith(color: cs.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cs.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      // M3 FAB: primaryContainer fill, onPrimaryContainer icon, Large shape (16 dp).
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── NavigationBar ────────────────────────────────────────────────────
      // M3 NavigationBar: indicator pill uses secondaryContainer.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? cs.onSecondaryContainer
                : cs.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return (states.contains(WidgetState.selected)
              ? textTheme.labelSmall?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w600)
              : textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))!;
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 3,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      // M3 SnackBar: inverseSurface background.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onInverseSurface,
        ),
        actionTextColor: cs.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      // M3 Dialog shape = Extra Large (28 dp).
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 3,
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: cs.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      // M3 Bottom sheet: Extra Large (28 dp) top corners.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 1,
        showDragHandle: true,
        dragHandleColor: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? cs.onPrimary
                : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? cs.primary
                : cs.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.transparent
                : cs.outline),
      ),

      // ── Tab bar ───────────────────────────────────────────────────────────
      // M3 tab indicator: underline at bottom (default) or pill (secondary).
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.titleSmall,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: cs.outlineVariant,
      ),

      // ── List tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),

      // ── PopupMenu / DropdownButton ────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 2,
      ),
    );
  }
}
