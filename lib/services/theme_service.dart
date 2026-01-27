import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum pour les modes de thème disponibles
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Extension de thème pour les gradients personnalisés de l'application
@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  final Gradient primaryGradient;
  final Gradient elevatedGradient;
  final Gradient heroGradient;
  final Gradient cardGradient;

  const AppGradients({
    required this.primaryGradient,
    required this.elevatedGradient,
    required this.heroGradient,
    required this.cardGradient,
  });

  @override
  AppGradients copyWith({
    Gradient? primaryGradient,
    Gradient? elevatedGradient,
    Gradient? heroGradient,
    Gradient? cardGradient,
  }) =>
      AppGradients(
        primaryGradient: primaryGradient ?? this.primaryGradient,
        elevatedGradient: elevatedGradient ?? this.elevatedGradient,
        heroGradient: heroGradient ?? this.heroGradient,
        cardGradient: cardGradient ?? this.cardGradient,
      );

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      primaryGradient: LinearGradient(
        colors: List.generate(
            2,
            (i) => Color.lerp(
                  (primaryGradient as LinearGradient).colors[i],
                  (other.primaryGradient as LinearGradient).colors[i],
                  t,
                )!),
      ),
      elevatedGradient: LinearGradient(
        colors: List.generate(
            2,
            (i) => Color.lerp(
                  (elevatedGradient as LinearGradient).colors[i],
                  (other.elevatedGradient as LinearGradient).colors[i],
                  t,
                )!),
      ),
      heroGradient: LinearGradient(
        colors: List.generate(
            3,
            (i) => Color.lerp(
                  (heroGradient as LinearGradient).colors[i],
                  (other.heroGradient as LinearGradient).colors[i],
                  t,
                )!),
      ),
      cardGradient: LinearGradient(
        colors: List.generate(
            2,
            (i) => Color.lerp(
                  (cardGradient as LinearGradient).colors[i],
                  (other.cardGradient as LinearGradient).colors[i],
                  t,
                )!),
      ),
    );
  }
}

/// Extension pour les espacements et rayons cohérents (Design Tokens 2026)
@immutable
class AppDimensions extends ThemeExtension<AppDimensions> {
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final double radiusXL;
  final double spacingXS;
  final double spacingS;
  final double spacingM;
  final double spacingL;
  final double spacingXL;
  final double cardElevation;

  const AppDimensions({
    this.radiusSmall = 8.0,
    this.radiusMedium = 16.0,
    this.radiusLarge = 24.0,
    this.radiusXL = 32.0,
    this.spacingXS = 4.0,
    this.spacingS = 8.0,
    this.spacingM = 16.0,
    this.spacingL = 24.0,
    this.spacingXL = 32.0,
    this.cardElevation = 8.0,
  });

  @override
  AppDimensions copyWith({
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusXL,
    double? spacingXS,
    double? spacingS,
    double? spacingM,
    double? spacingL,
    double? spacingXL,
    double? cardElevation,
  }) =>
      AppDimensions(
        radiusSmall: radiusSmall ?? this.radiusSmall,
        radiusMedium: radiusMedium ?? this.radiusMedium,
        radiusLarge: radiusLarge ?? this.radiusLarge,
        radiusXL: radiusXL ?? this.radiusXL,
        spacingXS: spacingXS ?? this.spacingXS,
        spacingS: spacingS ?? this.spacingS,
        spacingM: spacingM ?? this.spacingM,
        spacingL: spacingL ?? this.spacingL,
        spacingXL: spacingXL ?? this.spacingXL,
        cardElevation: cardElevation ?? this.cardElevation,
      );

  @override
  AppDimensions lerp(ThemeExtension<AppDimensions>? other, double t) {
    if (other is! AppDimensions) return this;
    return AppDimensions(
      radiusSmall: radiusSmall + (other.radiusSmall - radiusSmall) * t,
      radiusMedium: radiusMedium + (other.radiusMedium - radiusMedium) * t,
      radiusLarge: radiusLarge + (other.radiusLarge - radiusLarge) * t,
      radiusXL: radiusXL + (other.radiusXL - radiusXL) * t,
      spacingXS: spacingXS + (other.spacingXS - spacingXS) * t,
      spacingS: spacingS + (other.spacingS - spacingS) * t,
      spacingM: spacingM + (other.spacingM - spacingM) * t,
      spacingL: spacingL + (other.spacingL - spacingL) * t,
      spacingXL: spacingXL + (other.spacingXL - spacingXL) * t,
      cardElevation: cardElevation + (other.cardElevation - cardElevation) * t,
    );
  }
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme_mode';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  AppThemeMode get themeMode => _themeMode;
  
  /// Retourne le ThemeMode Flutter correspondant
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);
    if (savedMode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
    }
    notifyListeners();
  }
  
  /// Change le mode de thème et le persiste
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }
  
  /// Cycle entre les modes: System -> Light -> Dark -> System
  Future<void> cycleThemeMode() async {
    final nextMode = AppThemeMode.values[
      (_themeMode.index + 1) % AppThemeMode.values.length
    ];
    await setThemeMode(nextMode);
  }
  
  /// Retourne l'icône correspondant au mode actuel
  IconData get themeModeIcon {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
      case AppThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }
  
  /// Retourne le label du mode actuel
  String get themeModeLabel {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.dark:
        return 'Sombre';
      case AppThemeMode.system:
        return 'Système';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PALETTE BUDGWAY 2026 - Moderne, Premium, Accessible
  // ═══════════════════════════════════════════════════════════════════════════
  // Couleurs principales inspirées du monde financier moderne
  // avec une touche de sophistication et d'accessibilité WCAG AA
  
  static ThemeData get lightTheme {
    // Palette "Ocean Finance" - Professionnelle et apaisante
    const primary = Color(0xFF1A56DB);          // Bleu royal vif
    const primaryLight = Color(0xFF3B82F6);     // Bleu moyen lumineux
    const primaryUltraLight = Color(0xFFF8FAFC); // Fond très clair (slate-50)
    const primaryDeep = Color(0xFF1E3A5F);      // Bleu nuit profond
    const accentEmerald = Color(0xFF10B981);    // Vert succès moderne
    const accentAmber = Color(0xFFF59E0B);      // Ambre pour alertes
    const surfaceCard = Color(0xFFFFFFFF);      // Blanc pur pour cartes
    const surfaceElevated = Color(0xFFF1F5F9); // Fond élevé (slate-100)
    const textPrimary = Color(0xFF0F172A);      // Texte principal (slate-900)
    const textSecondary = Color(0xFF64748B);    // Texte secondaire (slate-500)
    const error = Color(0xFFDC2626);            // Rouge erreur moderne

    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    
    final colorScheme = baseScheme.copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDBEAFE), // Bleu très clair
      onPrimaryContainer: primaryDeep,
      secondary: accentEmerald,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD1FAE5), // Vert très clair
      onSecondaryContainer: const Color(0xFF065F46),
      tertiary: accentAmber,
      tertiaryContainer: const Color(0xFFFEF3C7),
      error: error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      surface: surfaceCard,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: const Color(0xFFCBD5E1), // slate-300
      outlineVariant: const Color(0xFFE2E8F0), // slate-200
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: primaryUltraLight,
      
      // ═══════════════ SYSTEM UI OVERLAY ═══════════════
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: primaryUltraLight,
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      
      // ═══════════════ CARDS PREMIUM ═══════════════
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        shadowColor: primary.withValues(alpha: 0.08),
      ),
      
      // ═══════════════ INPUT FIELDS MODERNES ═══════════════
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: textSecondary.withValues(alpha: 0.7),
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // ═══════════════ BOUTONS PREMIUM ═══════════════
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceCard,
          foregroundColor: primary,
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // ═══════════════ FLOATING ACTION BUTTON ═══════════════
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      
      // ═══════════════ SNACKBAR MODERNE ═══════════════
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDeep,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // ═══════════════ CHIPS ÉLÉGANTS ═══════════════
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        labelStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      
      // ═══════════════ INDICATEURS DE PROGRESSION ═══════════════
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),
      
      // ═══════════════ DIVIDERS ═══════════════
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 24,
        thickness: 1,
      ),
      
      // ═══════════════ BOTTOM NAVIGATION ═══════════════
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        elevation: 8,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // ═══════════════ NAVIGATION BAR (Material 3) ═══════════════
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      
      // ═══════════════ TABS ═══════════════
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
      ),
      
      // ═══════════════ DIALOGS ═══════════════
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        contentTextStyle: TextStyle(
          fontSize: 15,
          color: textSecondary,
          height: 1.5,
        ),
      ),
      
      // ═══════════════ BOTTOM SHEET ═══════════════
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: colorScheme.outlineVariant,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),
      
      // ═══════════════ LIST TILES ═══════════════
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      
      // ═══════════════ EXTENSIONS CUSTOM ═══════════════
      extensions: const [
        AppGradients(
          primaryGradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF1A56DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          elevatedGradient: LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          heroGradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A5F),
              Color(0xFF1A56DB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          cardGradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        AppDimensions(),
      ],
      
      // ═══════════════ TYPOGRAPHIE MODERNE ═══════════════
      textTheme: const TextTheme(
        // Display - Pour les grands titres hero
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          height: 1.1,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          height: 1.15,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          height: 1.2,
          color: textPrimary,
        ),
        // Headlines - Pour les titres de section
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.25,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.3,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.35,
          color: textPrimary,
        ),
        // Titles - Pour les titres d'éléments
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.4,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.45,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.45,
          color: textPrimary,
        ),
        // Body - Pour le contenu
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.5,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
          height: 1.5,
          color: textSecondary,
        ),
        // Labels - Pour les boutons et étiquettes
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.4,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          height: 1.4,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: textSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Palette sombre "Midnight Finance" - Élégante et reposante
    const primary = Color(0xFF60A5FA);        // Bleu clair lumineux
    const primaryDeep = Color(0xFF1E3A5F);    // Bleu nuit
    const accent = Color(0xFF34D399);         // Vert émeraude clair
    const accentContainer = Color(0xFF064E3B);
    const surface = Color(0xFF1E293B);        // Slate-800
    const surfaceCard = Color(0xFF334155);    // Slate-700
    const background = Color(0xFF0F172A);     // Slate-900
    const textPrimary = Color(0xFFF8FAFC);    // Slate-50
    const textSecondary = Color(0xFF94A3B8);  // Slate-400

    final baseDark = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );
    
    final colorScheme = baseDark.copyWith(
      primary: primary,
      onPrimary: const Color(0xFF0F172A),
      primaryContainer: primaryDeep,
      onPrimaryContainer: textPrimary,
      secondary: accent,
      onSecondary: const Color(0xFF0F172A),
      secondaryContainer: accentContainer,
      onSecondaryContainer: const Color(0xFFD1FAE5),
      tertiary: const Color(0xFFFBBF24),
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: const Color(0xFF475569), // Slate-600
      outlineVariant: const Color(0xFF334155), // Slate-700
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: background,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceCard,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: colorScheme.outline,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),
      
      extensions: const [
        AppGradients(
          primaryGradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          elevatedGradient: LinearGradient(
            colors: [Color(0xFF334155), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          heroGradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF1E3A5F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          cardGradient: LinearGradient(
            colors: [Color(0xFF334155), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        AppDimensions(),
      ],
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          height: 1.1,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          height: 1.15,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          height: 1.2,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.25,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.3,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.35,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.4,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.45,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.45,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.5,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
          height: 1.5,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.4,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          height: 1.4,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: textSecondary,
        ),
      ),
    );
  }
}