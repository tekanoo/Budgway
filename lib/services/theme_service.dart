import 'package:flutter/material.dart';

@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  final Gradient primaryGradient;
  final Gradient elevatedGradient;

  const AppGradients({
    required this.primaryGradient,
    required this.elevatedGradient,
  });

  @override
  AppGradients copyWith({Gradient? primaryGradient, Gradient? elevatedGradient}) => AppGradients(
        primaryGradient: primaryGradient ?? this.primaryGradient,
        elevatedGradient: elevatedGradient ?? this.elevatedGradient,
      );

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      primaryGradient: LinearGradient(
        colors: List.generate(2, (i) => Color.lerp(
              (primaryGradient as LinearGradient).colors[i],
              (other.primaryGradient as LinearGradient).colors[i],
              t,
            )!),
      ),
      elevatedGradient: LinearGradient(
        colors: List.generate(2, (i) => Color.lerp(
              (elevatedGradient as LinearGradient).colors[i],
              (other.elevatedGradient as LinearGradient).colors[i],
              t,
            )!),
      ),
    );
  }
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // Suppression de toute la logique de thème dynamique
  // L'application utilisera toujours le thème clair

  Future<void> initialize() async {
    // Plus besoin d'initialisation
    notifyListeners();
  }

  // Génération de nuances dérivées du logo :
  // Couleurs bases estimées depuis l'image: Violet #6A35B5, Violet profond #4C1E87, Doré #F2B705
  // Nuances supplémentaires calculées manuellement pour cohérence UI.
  static ThemeData get lightTheme {
    // Palette bleu / noir / blanc :
    // Base: Profond #0D47A1, Medium #1565C0, Accent clair #42A5F5, Background très clair #F5F8FC
    const primary = Color(0xFF0D47A1);          // Bleu profond
    const primaryLight = Color(0xFF1565C0);     // Bleu moyen
    const primaryUltraLight = Color(0xFFF5F8FC); // Fond très clair
    const primaryDeep = Color(0xFF082D63);      // Bleu encore plus sombre
    const accentBlue = Color(0xFF42A5F5);       // Accent clair
    const accentBlueSoft = Color(0xFFB3DAFF);   // Conteneur clair
    const error = Color(0xFFD32F2F);            // Rouge standard Material

    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    final colorScheme = baseScheme.copyWith(
      primary: primary,
      primaryContainer: primaryLight,
      secondary: accentBlue,
      secondaryContainer: accentBlueSoft,
      error: error,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
  scaffoldBackgroundColor: primaryUltraLight,
  appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        margin: const EdgeInsets.all(8),
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
  fillColor: colorScheme.surface.withValues(alpha: 0.08),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
  filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
  elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: primaryDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDeep,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.55),
        labelStyle: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedColor: colorScheme.secondary,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentBlue,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 32,
        thickness: 0.8,
      ),
      extensions: const [
        AppGradients(
          primaryGradient: LinearGradient(
            colors: [Color(0xFF082D63), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          elevatedGradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
      textTheme: Typography.blackCupertino.copyWith(
        headlineLarge: const TextStyle(fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Palette sombre bleue / anthracite
    const primary = Color(0xFF82B1FF);        // Bleu clair lisible
    const primaryDeep = Color(0xFF0A2B55);    // Bleu nuit
    const accent = Color(0xFF1565C0);         // Accent actif
    const accentContainer = Color(0xFF0D47A1);
    const surface = Color(0xFF121821);        // Anthracite bleuté

    final baseDark = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);
    final colorScheme = baseDark.copyWith(
      primary: primary,
      primaryContainer: primaryDeep,
      secondary: accent,
      secondaryContainer: accentContainer,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
  scaffoldBackgroundColor: const Color(0xFF0D1218),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
  fillColor: colorScheme.surface.withValues(alpha: 0.3),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.tertiary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: const [
        AppGradients(
          primaryGradient: LinearGradient(
            colors: [Color(0xFF0A2B55), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          elevatedGradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }
}