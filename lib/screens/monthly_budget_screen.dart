import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import 'home_tab.dart';
import 'plaisirs_tab.dart';
import 'entrees_tab.dart';
import 'sorties_tab.dart';
import 'monthly_analyse_tab.dart';

/// Écran de budget mensuel modernisé avec navigation fluide
class MonthlyBudgetScreen extends StatefulWidget {
  final DateTime selectedMonth;

  const MonthlyBudgetScreen({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  
  // Animation controller pour les transitions
  late final AnimationController _appBarAnimController;
  late final Animation<double> _appBarAnimation;
  
  // Mois actuel avec navigation
  late DateTime _currentMonth;

  late List<Widget> _tabs;

  // Configuration des onglets
  static const List<_TabConfig> _tabConfigs = [
    _TabConfig(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      color: Color(0xFF1A56DB),
    ),
    _TabConfig(
      title: 'Dépenses',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      color: Color(0xFFF59E0B),
    ),
    _TabConfig(
      title: 'Revenus',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up_rounded,
      color: Color(0xFF10B981),
    ),
    _TabConfig(
      title: 'Charges',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      color: Color(0xFFEF4444),
    ),
    _TabConfig(
      title: 'Analyse',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedMonth;
    _initAnimations();
    _initTabs();
  }
  
  void _initTabs() {
    _tabs = [
      HomeTab(selectedMonth: _currentMonth),
      PlaisirsTab(selectedMonth: _currentMonth),
      EntreesTab(selectedMonth: _currentMonth),
      SortiesTab(selectedMonth: _currentMonth),
      MonthlyAnalyseTab(selectedMonth: _currentMonth),
    ];
  }
  
  void _navigateToMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
      _initTabs();
    });
  }

  void _initAnimations() {
    _appBarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _appBarAnimation = CurvedAnimation(
      parent: _appBarAnimController,
      curve: Curves.easeOutCubic,
    );
    _appBarAnimController.forward();
  }

  @override
  void dispose() {
    _appBarAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _getMonthName(DateTime date) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monthName = _getMonthName(_currentMonth);
    final currentTab = _tabConfigs[_selectedIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(context, theme, colorScheme, monthName, currentTab),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _tabs,
      ),
      bottomNavigationBar: _buildModernBottomNav(context, theme, colorScheme),
    );
  }

  PreferredSizeWidget _buildModernAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String monthName,
    _TabConfig currentTab,
  ) {
    final gradients = theme.extension<AppGradients>();

    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: FadeTransition(
        opacity: _appBarAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradients?.heroGradient ??
                LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Bouton retour
                  _buildBackButton(context),
                  const SizedBox(width: 8),
                  // Titre et sous-titre
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            currentTab.title,
                            key: ValueKey(currentTab.title),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    monthName,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomNav(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _tabConfigs.length,
              (index) => _buildNavItem(
                context,
                index,
                _tabConfigs[index],
                theme,
                colorScheme,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    _TabConfig config,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? config.color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? config.color.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? config.selectedIcon : config.icon,
                color: isSelected ? config.color : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.labelSmall!.copyWith(
                color: isSelected ? config.color : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: isSelected ? 11 : 10,
              ),
              child: Text(config.title),
            ),
          ],
        ),
      ),
    );
  }
}

/// Configuration d'un onglet
class _TabConfig {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;

  const _TabConfig({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.color,
  });
}