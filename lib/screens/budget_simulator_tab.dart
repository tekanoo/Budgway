import 'package:flutter/material.dart';
import 'dart:async';
import '../services/encrypted_budget_service.dart';

/// Modèle pour un élément de budget (revenu, charge, dépense)
class BudgetItem {
  final String id;
  String label;
  double amount;
  String frequency; // 'Mensuel' ou 'Annuel'
  
  // Controllers pour les TextFields
  late final TextEditingController labelController;
  late final TextEditingController amountController;
  
  BudgetItem({
    required this.id,
    required this.label,
    required this.amount,
    this.frequency = 'Mensuel',
  }) {
    labelController = TextEditingController(text: label);
    amountController = TextEditingController(text: amount > 0 ? amount.toString() : '');
  }
  
  double getMonthlyAmount() {
    return frequency == 'Annuel' ? amount / 12 : amount;
  }
  
  void dispose() {
    labelController.dispose();
    amountController.dispose();
  }
}

/// Simulateur de Budget Personnel
class BudgetSimulatorTab extends StatefulWidget {
  const BudgetSimulatorTab({super.key});

  @override
  State<BudgetSimulatorTab> createState() => _BudgetSimulatorTabState();
}

class _BudgetSimulatorTabState extends State<BudgetSimulatorTab> {
  final List<BudgetItem> _incomes = [];
  final List<BudgetItem> _charges = [];
  final List<BudgetItem> _expenses = [];
  double _expensePercent = 0;
  late final TextEditingController _expensePercentController;
  
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  bool _isLoading = true;
  Timer? _saveTimer;
  
  @override
  void initState() {
    super.initState();
    _expensePercentController = TextEditingController();
    _loadSimulatorData();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _expensePercentController.dispose();
    // Nettoie les controllers
    for (var item in _incomes) {
      item.dispose();
    }
    for (var item in _charges) {
      item.dispose();
    }
    for (var item in _expenses) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSimulatorData() async {
    try {
      final data = await _dataService.loadBudgetSimulator();
      setState(() {
        // Nettoie les anciens items
        for (var item in _incomes) {
          item.dispose();
        }
        for (var item in _charges) {
          item.dispose();
        }
        for (var item in _expenses) {
          item.dispose();
        }
        
        _incomes.clear();
        _charges.clear();
        _expenses.clear();
        
        // Charge les revenus
        if (data['incomes'] is List) {
          for (var income in data['incomes'] as List) {
            _incomes.add(BudgetItem(
              id: income['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              label: income['description'] ?? '',
              amount: (income['amount'] as num?)?.toDouble() ?? 0.0,
              frequency: income['frequency'] ?? 'Mensuel',
            ));
          }
        }
        
        // Charge les charges
        if (data['charges'] is List) {
          for (var charge in data['charges'] as List) {
            _charges.add(BudgetItem(
              id: charge['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              label: charge['description'] ?? '',
              amount: (charge['amount'] as num?)?.toDouble() ?? 0.0,
              frequency: charge['frequency'] ?? 'Mensuel',
            ));
          }
        }
        
        // Charge les dépenses
        if (data['expenses'] is List) {
          for (var expense in data['expenses'] as List) {
            _expenses.add(BudgetItem(
              id: expense['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              label: expense['description'] ?? '',
              amount: (expense['amount'] as num?)?.toDouble() ?? 0.0,
              frequency: expense['frequency'] ?? 'Mensuel',
            ));
          }
        }
        
        _expensePercent = (data['expensePercent'] as num?)?.toDouble() ?? 0.0;
        _expensePercentController.text = _expensePercent > 0 ? _expensePercent.toString() : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement simulateur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveBudgetData() async {
    try {
      final simulatorData = {
        'incomes': _incomes.map((item) => {
          'id': item.id,
          'description': item.label,
          'amount': item.amount,
          'frequency': item.frequency,
        }).toList(),
        'charges': _charges.map((item) => {
          'id': item.id,
          'description': item.label,
          'amount': item.amount,
          'frequency': item.frequency,
        }).toList(),
        'expenses': _expenses.map((item) => {
          'id': item.id,
          'description': item.label,
          'amount': item.amount,
          'frequency': item.frequency,
        }).toList(),
        'expensePercent': _expensePercent,
      };
      
      await _dataService.saveBudgetSimulator(simulatorData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveBudgetData);
  }

  void _addIncome() {
    setState(() {
      _incomes.add(BudgetItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: '',
        amount: 0,
        frequency: 'Mensuel',
      ));
    });
    _saveBudgetData();
  }

  void _addCharge() {
    setState(() {
      _charges.add(BudgetItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: '',
        amount: 0,
        frequency: 'Mensuel',
      ));
    });
    _saveBudgetData();
  }

  void _addExpense() {
    setState(() {
      _expenses.add(BudgetItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: '',
        amount: 0,
        frequency: 'Mensuel',
      ));
    });
    _saveBudgetData();
  }

  void _removeItem(List<BudgetItem> list, String id) {
    setState(() {
      final item = list.firstWhere((item) => item.id == id);
      item.dispose();
      list.removeWhere((item) => item.id == id);
    });
    _saveBudgetData();
  }

  void _applyExpensePercent() {
    if (_expensePercent <= 0 || _incomes.isEmpty) return;
    
    final totalIncome = _incomes.fold(0.0, (sum, item) => sum + item.getMonthlyAmount());
    final percentAmount = totalIncome * (_expensePercent / 100);
    
    setState(() {
      // Nettoie les anciens items
      for (var item in _expenses) {
        item.dispose();
      }
      _expenses.clear();
      _expenses.add(BudgetItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: '${_expensePercent}% du revenu',
        amount: percentAmount,
        frequency: 'Mensuel',
      ));
    });
    _saveBudgetData();
  }

  double _getTotalIncome() {
    return _incomes.fold(0.0, (sum, item) => sum + item.getMonthlyAmount());
  }

  double _getTotalCharges() {
    return _charges.fold(0.0, (sum, item) => sum + item.getMonthlyAmount());
  }

  double _getTotalExpenses() {
    return _expenses.fold(0.0, (sum, item) => sum + item.getMonthlyAmount());
  }

  double _getRemainingToInvest() {
    final total = _getTotalIncome() - _getTotalCharges() - _getTotalExpenses();
    return total > 0 ? total : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du simulateur...'),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 1024;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isLargeScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildInputSection(),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: _buildResultsSection(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildInputSection(),
                    const SizedBox(height: 32),
                    _buildResultsSection(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Simulateur de Budget Personnel',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gérez vos revenus, charges et dépenses pour calculer votre capacité d\'investissement mensuelle et annuelle.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        
        // Bloc Revenus
        _buildBudgetSection(
          title: '💰 Revenus',
          titleColor: const Color(0xFF4CAF50), // Success green
          items: _incomes,
          onAdd: _addIncome,
          onRemove: _removeItem,
          showFrequency: true,
        ),
        const SizedBox(height: 24),
        
        // Bloc Charges
        _buildBudgetSection(
          title: '📊 Charges',
          titleColor: const Color(0xFFFFC107), // Warning yellow
          items: _charges,
          onAdd: _addCharge,
          onRemove: _removeItem,
        ),
        _buildHelpText('Impôts, cotisations sociales, assurances obligatoires...'),
        const SizedBox(height: 24),
        
        // Bloc Dépenses
        _buildBudgetSection(
          title: '💸 Dépenses',
          titleColor: const Color(0xFFf44336), // Danger red
          items: _expenses,
          onAdd: _addExpense,
          onRemove: _removeItem,
        ),
        _buildPercentExpenseHelper(),
        _buildHelpText('Loyer, alimentation, transport, loisirs...'),
      ],
    );
  }

  Widget _buildBudgetSection({
    required String title,
    required Color titleColor,
    required List<BudgetItem> items,
    required VoidCallback onAdd,
    required Function(List<BudgetItem>, String) onRemove,
    bool showFrequency = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun élément ajouté',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            )
          else
            ...items.map((item) => _buildBudgetItemRow(
              item,
              showFrequency: showFrequency,
              onRemove: () => onRemove(items, item.id),
            )),
        ],
      ),
    );
  }

  Widget _buildBudgetItemRow(
    BudgetItem item, {
    required bool showFrequency,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 500;
          
          if (isSmallScreen) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: item.labelController,
                        onChanged: (value) {
                          setState(() {
                            item.label = value;
                          });
                          _scheduleSave();
                        },
                        decoration: InputDecoration(
                          hintText: 'Libellé',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onRemove,
                      iconSize: 20,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: item.amountController,
                        onChanged: (value) {
                          setState(() {
                            item.amount = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                          });
                          _scheduleSave();
                        },
                        decoration: InputDecoration(
                          hintText: 'Montant',
                          suffixText: '€',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (showFrequency) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: item.frequency,
                          onChanged: (value) {
                            setState(() {
                              item.frequency = value ?? 'Mensuel';
                            });
                            _scheduleSave();
                          },
                          items: ['Mensuel', 'Annuel']
                              .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                              .toList(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: item.labelController,
                    onChanged: (value) {
                      setState(() {
                        item.label = value;
                      });
                      _scheduleSave();
                    },
                    decoration: InputDecoration(
                      hintText: 'Libellé',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: item.amountController,
                    onChanged: (value) {
                      setState(() {
                        item.amount = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                      });
                      _scheduleSave();
                    },
                    decoration: InputDecoration(
                      hintText: 'Montant',
                      suffixText: '€',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (showFrequency) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: item.frequency,
                      onChanged: (value) {
                        setState(() {
                          item.frequency = value ?? 'Mensuel';
                        });
                        _scheduleSave();
                      },
                      items: ['Mensuel', 'Annuel']
                          .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                          .toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                  iconSize: 20,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPercentExpenseHelper() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.shade50,
        ),
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            
            return isSmallScreen
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expensePercentController,
                              onChanged: (value) {
                                setState(() {
                                  _expensePercent = double.tryParse(value) ?? 0;
                                });
                                _scheduleSave();
                              },
                              decoration: InputDecoration(
                                hintText: 'Ex: 30',
                                suffixText: '%',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'du revenu',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _applyExpensePercent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          child: const Text('Appliquer', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expensePercentController,
                          onChanged: (value) {
                            setState(() {
                              _expensePercent = double.tryParse(value) ?? 0;
                            });
                            _scheduleSave();
                          },
                          decoration: InputDecoration(
                            hintText: 'Ex: 30',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '% du revenu',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyExpensePercent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Appliquer', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildHelpText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildResultsSection() {
    final totalIncome = _getTotalIncome();
    final totalCharges = _getTotalCharges();
    final totalExpenses = _getTotalExpenses();
    final remaining = _getRemainingToInvest();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé de votre Budget',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        
        _buildSummaryCard(
          label: 'Revenus mensuels',
          amount: totalIncome,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          label: 'Charges mensuelles',
          amount: totalCharges,
          color: const Color(0xFFFFC107),
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          label: 'Dépenses mensuelles',
          amount: totalExpenses,
          color: const Color(0xFFf44336),
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          label: 'Reste à investir',
          amount: remaining,
          color: const Color(0xFF2196F3),
          isHighlight: true,
        ),
        const SizedBox(height: 24),
        
        // Carte Annuelle
        _buildSummaryCard(
          label: 'Reste à investir (annuel)',
          amount: remaining * 12,
          color: const Color(0xFF2196F3),
          isHighlight: true,
        ),
        const SizedBox(height: 24),
        _buildTipCard(),
        const SizedBox(height: 12),
        _buildBonusCard(),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isHighlight
            ? Border.all(color: color, width: 2)
            : Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
        color: isHighlight ? color.withValues(alpha: 0.05) : Colors.white,
        boxShadow: isHighlight
            ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)]
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            '${amount.toStringAsFixed(2).replaceAll('.', ',')} €',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2196F3), width: 1),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF2196F3).withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Astuce',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le montant "Reste à investir" peut être utilisé comme contribution mensuelle dans l\'onglet Intérêts Composés pour simuler la croissance de votre capital à long terme.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF4CAF50).withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Prime Annuelle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'N\'oubliez pas d\'inclure votre prime annuelle dans les revenus en sélectionnant la fréquence "Annuel". Cela vous permettra de visualiser votre capacité d\'investissement totale sur l\'année.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
