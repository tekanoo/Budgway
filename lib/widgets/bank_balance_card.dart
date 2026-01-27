import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';

/// Carte premium affichant le solde bancaire avec animations et design moderne
class BankBalanceCard extends StatefulWidget {
  const BankBalanceCard({super.key});

  @override
  State<BankBalanceCard> createState() => _BankBalanceCardState();
}

class _BankBalanceCardState extends State<BankBalanceCard>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  double _currentBalance = 0.0;
  bool _isLoading = true;
  bool _isBalanceVisible = true;
  final _balanceController = TextEditingController();

  // Animation
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadBalance();
  }

  void _initAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  Future<void> _loadBalance() async {
    final balance = await _storage.getBankBalance();
    if (mounted) {
      setState(() {
        _currentBalance = balance;
        _isLoading = false;
      });
    }
  }

  void _toggleBalanceVisibility() {
    HapticFeedback.selectionClick();
    setState(() => _isBalanceVisible = !_isBalanceVisible);
  }

  void _updateBalance() {
    HapticFeedback.mediumImpact();
    _balanceController.text = _currentBalance.toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUpdateBalanceSheet(context),
    );
  }

  Widget _buildUpdateBalanceSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + bottomPadding,
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Mettre à jour le solde',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Input field
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              autofocus: true,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Nouveau solde',
                suffixText: '€',
                suffixStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.euro_rounded,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final newBalance =
                          double.tryParse(_balanceController.text.replaceAll(',', '.')) ??
                              _currentBalance;
                      await _storage.saveBankBalance(newBalance);
                      
                      // Animation de mise à jour
                      _animController.reset();
                      
                      setState(() {
                        _currentBalance = newBalance;
                      });
                      
                      _animController.forward();
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: colorScheme.onPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text('Solde mis à jour'),
                              ],
                            ),
                            backgroundColor: colorScheme.primary,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradients = theme.extension<AppGradients>();
    final isPositive = _currentBalance >= 0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleBalanceVisibility,
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Solde du compte',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Visibility toggle
                          IconButton(
                            onPressed: _toggleBalanceVisibility,
                            icon: Icon(
                              _isBalanceVisible
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 22,
                            ),
                            tooltip: _isBalanceVisible
                                ? 'Masquer le solde'
                                : 'Afficher le solde',
                          ),
                          // Edit button
                          IconButton(
                            onPressed: _updateBalance,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            tooltip: 'Modifier le solde',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Balance display
                  if (_isLoading)
                    _buildLoadingState()
                  else
                    _buildBalanceDisplay(theme, isPositive),

                  const SizedBox(height: 16),

                  // Status indicator
                  _buildStatusIndicator(theme, isPositive),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 48,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildBalanceDisplay(ThemeData theme, bool isPositive) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _isBalanceVisible
          ? Text(
              '${_currentBalance.toStringAsFixed(2)} €',
              key: const ValueKey('visible'),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            )
          : Text(
              '••••••',
              key: const ValueKey('hidden'),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isPositive
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444))
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isPositive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444))
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isPositive ? 'Solde positif' : 'Solde négatif',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _animController.dispose();
    super.dispose();
  }
}