import 'dart:math' as math;
import 'package:budget_app/screens/auth_wrapper.dart';
import 'package:budget_app/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page d'accueil modernisée avec animations fluides et design 2026
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Contrôleurs d'animation
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _floatingController;
  late final AnimationController _shimmerController;

  // Animations
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _floatingAnimation;

  // État du bouton
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Animation de fade-in principale
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // Animation de scale pour le logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Animation flottante continue pour le logo
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Animation shimmer pour l'effet de brillance
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Démarrer les animations avec un délai orchestré
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleStartApp(BuildContext context) async {
    // Feedback haptique léger
    HapticFeedback.lightImpact();

    setState(() => _isButtonPressed = true);

    try {
      // Animation de transition fluide
      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) return;

      // Navigation avec transition personnalisée
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AuthWrapper(),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      setState(() => _isButtonPressed = false);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showAppInfo(BuildContext context) {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildInfoBottomSheet(ctx),
    );
  }

  Widget _buildInfoBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec icône animée
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budgway',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Version 2.0.0 • 2026',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Features list
                _buildFeatureItem(
                  context,
                  Icons.trending_up_rounded,
                  'Suivi intelligent',
                  'Revenus et dépenses en temps réel',
                  colorScheme.secondary,
                ),
                _buildFeatureItem(
                  context,
                  Icons.celebration_rounded,
                  'Objectifs plaisirs',
                  'Définissez et atteignez vos objectifs',
                  colorScheme.tertiary,
                ),
                _buildFeatureItem(
                  context,
                  Icons.analytics_rounded,
                  'Analyses détaillées',
                  'Visualisez vos tendances financières',
                  colorScheme.primary,
                ),
                _buildFeatureItem(
                  context,
                  Icons.shield_rounded,
                  'Sécurisé',
                  'Chiffrement de bout en bout',
                  const Color(0xFF10B981),
                ),

                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradients = theme.extension<AppGradients>();
    final size = MediaQuery.sizeOf(context);

    // Configuration de la barre de statut
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Background avec gradient animé
          _buildAnimatedBackground(gradients, size),

          // Particules décoratives
          _buildFloatingParticles(size),

          // Contenu principal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Logo animé avec effet de flottement
                      _buildAnimatedLogo(colorScheme),

                      const SizedBox(height: 48),

                      // Titre avec gradient
                      _buildTitle(theme),

                      const SizedBox(height: 16),

                      // Sous-titre
                      _buildSubtitle(theme),

                      const SizedBox(height: 64),

                      // Bouton principal avec effet de pression
                      _buildMainButton(context, colorScheme),

                      const SizedBox(height: 24),

                      // Lien "À propos"
                      _buildInfoButton(context),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(AppGradients? gradients, Size size) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradients?.heroGradient ??
            const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF1A56DB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
      ),
      child: CustomPaint(
        painter: _BackgroundPatternPainter(
          animation: _shimmerController,
        ),
        size: size,
      ),
    );
  }

  Widget _buildFloatingParticles(Size size) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: List.generate(6, (index) {
            final offset = (index + 1) * 0.15;
            return Positioned(
              left: size.width * (0.1 + (index * 0.15)),
              top: size.height * (0.15 + (index * 0.12)) +
                  (_floatingAnimation.value * (index.isEven ? 1 : -1) * offset),
              child: _buildParticle(index),
            );
          }),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final sizes = [8.0, 12.0, 6.0, 10.0, 7.0, 9.0];
    final opacities = [0.15, 0.1, 0.2, 0.12, 0.18, 0.08];

    return Container(
      width: sizes[index],
      height: sizes[index],
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacities[index]),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAnimatedLogo(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _floatingAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cercle décoratif interne
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.primary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Icône principale
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFE0E7FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: Text(
        'Budgway',
        style: theme.textTheme.displayMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      'Gérez vos finances\navec élégance',
      style: theme.textTheme.titleLarge?.copyWith(
        color: Colors.white.withValues(alpha: 0.85),
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMainButton(BuildContext context, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.identity()..scale(_isButtonPressed ? 0.95 : 1.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isButtonPressed = true),
        onTapUp: (_) => _handleStartApp(context),
        onTapCancel: () => setState(() => _isButtonPressed = false),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isButtonPressed ? 0.1 : 0.2),
                blurRadius: _isButtonPressed ? 15 : 25,
                offset: Offset(0, _isButtonPressed ? 5 : 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isButtonPressed)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                )
              else
                Text(
                  'Commencer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              if (!_isButtonPressed) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showAppInfo(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(
        Icons.info_outline_rounded,
        size: 20,
        color: Colors.white.withValues(alpha: 0.8),
      ),
      label: Text(
        'À propos de l\'application',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Peintre personnalisé pour le motif de fond avec effet de brillance subtil
class _BackgroundPatternPainter extends CustomPainter {
  final Animation<double> animation;

  _BackgroundPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Dessiner des cercles concentriques subtils
    final center = Offset(size.width * 0.8, size.height * 0.2);
    for (int i = 0; i < 5; i++) {
      final radius = 100.0 + (i * 80);
      final opacity = 0.03 - (i * 0.005);
      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, paint);
    }

    // Ligne diagonale décorative avec shimmer
    final shimmerOffset = animation.value * size.width * 2;
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(math.pi / 4),
      ).createShader(Rect.fromLTWH(-shimmerOffset, 0, size.width * 3, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) => true;
}