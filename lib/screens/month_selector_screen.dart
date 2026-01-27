import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encrypted_budget_service.dart';
import 'monthly_budget_screen.dart';

class MonthSelectorScreen extends StatefulWidget {
  const MonthSelectorScreen({super.key});

  @override
  State<MonthSelectorScreen> createState() => _MonthSelectorScreenState();
}

class _MonthSelectorScreenState extends State<MonthSelectorScreen> {
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  Map<String, Map<String, double>> _monthlyData = {};
  bool _isLoading = true;
  bool _isInitialized = false;
  late ScrollController _scrollController;
  
  // Années à afficher (5 ans en arrière, 2 ans en avant)
  late int _startYear;
  late int _endYear;
  
  @override
  void initState() {
    super.initState();
    _startYear = DateTime.now().year - 3;
    _endYear = DateTime.now().year + 2;
    _scrollController = ScrollController();
    _initializeAndLoadData();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeAndLoadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _dataService.initialize();
      setState(() {
        _isInitialized = true;
      });
      await _loadMonthlyData();
      // Scroll vers l'année courante après le chargement
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentYear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'initialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _scrollToCurrentYear() {
    final currentYearIndex = DateTime.now().year - _startYear;
    // Calculer la position approximative (chaque année fait environ 200px de hauteur)
    final targetPosition = currentYearIndex * 180.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }
  
  Future<void> _loadMonthlyData() async {
    if (!_isInitialized) return;
    
    try {
      final projections = await _dataService.getProjectionsWithPeriodicity(
        yearStart: _startYear,
        yearEnd: _endYear,
      );
      
      setState(() {
        _monthlyData = projections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des données...'),
                ],
              ),
            )
          : !_isInitialized
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Erreur d\'initialisation'),
                      Text('Veuillez redémarrer l\'application'),
                    ],
                  ),
                )
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // En-tête sticky
                    SliverToBoxAdapter(
                      child: _buildHeader(theme),
                    ),
                    
                    // Liste des années avec leurs mois
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final year = _startYear + index;
                            return _buildYearSection(year, theme);
                          },
                          childCount: _endYear - _startYear + 1,
                        ),
                      ),
                    ),
                    
                    // Espace en bas
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
      // FAB pour aller à l'année courante
      floatingActionButton: !_isLoading && _isInitialized
          ? FloatingActionButton.small(
              onPressed: () {
                HapticFeedback.selectionClick();
                _scrollToCurrentYear();
              },
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.today_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendrier Budget',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Sélectionnez un mois',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Légende
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('Actuel', const Color(0xFF1A56DB), true),
                _buildLegendItem('Données', const Color(0xFF10B981), false),
                _buildLegendItem('Vide', Colors.grey.shade400, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isFilled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildYearSection(int year, ThemeData theme) {
    final isCurrentYear = year == DateTime.now().year;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentYear 
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 2)
            : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête année
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentYear 
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  year.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrentYear 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (isCurrentYear) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ACTUEL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                _buildYearSummary(year, theme),
              ],
            ),
          ),
          
          // Grille des mois (4 colonnes x 3 lignes)
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1.3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return _buildCompactMonthCell(year, index + 1, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSummary(int year, ThemeData theme) {
    double totalSolde = 0;
    int monthsWithData = 0;
    
    for (int month = 1; month <= 12; month++) {
      final monthKey = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
      final monthData = _monthlyData[monthKey];
      if (monthData != null) {
        final revenus = monthData['revenus'] ?? 0.0;
        final charges = monthData['charges'] ?? 0.0;
        final depenses = monthData['depenses'] ?? 0.0;
        if (revenus > 0 || charges > 0 || depenses > 0) {
          monthsWithData++;
          totalSolde += revenus - charges - depenses;
        }
      }
    }
    
    if (monthsWithData == 0) {
      return Text(
        'Aucune donnée',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }
    
    final isPositive = totalSolde >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${_formatAmount(totalSolde)} €',
        style: theme.textTheme.labelMedium?.copyWith(
          color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCompactMonthCell(int year, int month, ThemeData theme) {
    final monthKey = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final monthData = _monthlyData[monthKey];
    final hasData = monthData != null &&
                   ((monthData['revenus'] ?? 0) > 0 || 
                    (monthData['charges'] ?? 0) > 0 || 
                    (monthData['depenses'] ?? 0) > 0);
    
    final isCurrentMonth = DateTime.now().year == year && DateTime.now().month == month;
    final isPastMonth = DateTime(year, month).isBefore(DateTime(DateTime.now().year, DateTime.now().month));
    
    // Calculer le solde si données présentes
    double? solde;
    if (hasData) {
      final revenus = monthData!['revenus'] ?? 0.0;
      final charges = monthData['charges'] ?? 0.0;
      final depenses = monthData['depenses'] ?? 0.0;
      solde = revenus - charges - depenses;
    }
    
    const monthNames = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    const monthFullNames = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    
    // Couleurs selon l'état
    Color bgColor;
    Color textColor;
    Color borderColor;
    
    if (isCurrentMonth) {
      bgColor = theme.colorScheme.primary;
      textColor = Colors.white;
      borderColor = theme.colorScheme.primary;
    } else if (hasData) {
      final isPositive = solde! >= 0;
      bgColor = (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1);
      textColor = theme.colorScheme.onSurface;
      borderColor = (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4);
    } else if (isPastMonth) {
      bgColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      textColor = theme.colorScheme.outline;
      borderColor = Colors.transparent;
    } else {
      bgColor = Colors.transparent;
      textColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonthlyBudgetScreen(
                selectedMonth: DateTime(year, month),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: '${monthFullNames[month - 1]} $year${hasData ? '\nSolde: ${_formatAmount(solde!)} €' : ''}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: isCurrentMonth ? 2 : 1),
              boxShadow: isCurrentMonth
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthNames[month - 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: isCurrentMonth ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: solde! >= 0 
                          ? (isCurrentMonth ? Colors.white : const Color(0xFF10B981))
                          : (isCurrentMonth ? Colors.orange.shade200 : const Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}