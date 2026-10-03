import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const primary = Color(0xff1f6b45);
  static const primaryDark = Color(0xff154b31);
  static const primarySoft = Color(0xffeaf5ee);
  static const accent = Color(0xffd84c43);
  static const accentSoft = Color(0xffffeeeb);
  static const alert = Color(0xffd64545);
  static const inventory = Color(0xffc9812b);
  static const mothers = Color(0xff4e78b8);
  static const text = Color(0xff1f1f1f);
  static const textSecondary = Color(0xff6b6b6b);
  static const background = Color(0xfffbfaf7);
  static const surface = Colors.white;
  static const outline = Color(0xffe8e5df);
  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x120f3322), blurRadius: 18, offset: Offset(0, 7)),
  ];
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppPalette.primary,
          onPrimary: Colors.white,
          secondary: AppPalette.mothers,
          tertiary: AppPalette.inventory,
          error: AppPalette.alert,
          surface: AppPalette.surface,
          onSurface: AppPalette.text,
          outline: AppPalette.outline,
          surfaceContainerLowest: AppPalette.surface,
          surfaceContainerLow: const Color(0xfff4f7f3),
          surfaceContainer: const Color(0xffeef3ef),
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: defaultTargetPlatform == TargetPlatform.iOS
          ? '.SF Pro Text'
          : 'Roboto',
      scaffoldBackgroundColor: AppPalette.background,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 80,
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.text,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x140f3322),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppPalette.outline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.outline,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppPalette.primaryDark, size: 22),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          color: AppPalette.text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        titleLarge: const TextStyle(
          color: AppPalette.text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: const TextStyle(
          color: AppPalette.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          color: AppPalette.text,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        bodyMedium: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.primary,
          side: const BorderSide(color: AppPalette.outline),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppPalette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppPalette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppPalette.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppPalette.primary : AppPalette.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppPalette.primary
                : AppPalette.textSecondary,
          );
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.primaryDark,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
