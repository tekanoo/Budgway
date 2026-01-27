import 'package:flutter/material.dart';
import '../services/encrypted_budget_service.dart';
import 'monthly_budget_screen.dart';

class MonthSelectorScreen extends StatefulWidget {
  const MonthSelectorScreen({super.key});

  @override
  State<MonthSelectorScreen> createState() => _MonthSelectorScreenState();
}

class _MonthSelectorScreenState extends State<MonthSelectorScreen> {
  int _currentYear = DateTime.now().year;
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  Map<String, Map<String, double>> _monthlyData = {};
  bool _isLoading = true;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
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
  
  Future<void> _loadMonthlyData() async {
    if (!_isInitialized) return;
    
    try {
      final projections = await _dataService.getProjectionsWithPeriodicity(
        yearStart: _currentYear - 1,
        yearEnd: _currentYear + 1,
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
    return Scaffold(
      // SUPPRIMER AppBar car maintenant géré par MainMenuScreen
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
              : Column(
        children: [
          // En-tête avec année et titre
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Gestion Budget Pro',
                  style: TextStyle( // CORRECTION: Ajouter 'const'
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentYear--;
                        });
                        _loadMonthlyData();
                      },
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Text(
                      _currentYear.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentYear++;
                        });
                        _loadMonthlyData();
                      },
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Grille des mois
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return _buildMonthCard(index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(int month) {
    // Supprimer la variable monthDate inutilisée
    final monthKey = '${_currentYear.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final monthData = _monthlyData[monthKey];
    final hasData = monthData != null &&
                   (monthData['revenus']! > 0 || monthData['charges']! > 0 || monthData['depenses']! > 0);
    
    final revenus = monthData?['revenus'] ?? 0.0;
    final charges = monthData?['charges'] ?? 0.0;
    final depenses = monthData?['depenses'] ?? 0.0;
    final solde = revenus - charges - depenses;
    
    final isCurrentMonth = DateTime.now().year == _currentYear && DateTime.now().month == month;
    
    const monthNames = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    final monthName = monthNames[month - 1];
    
    return Card(
      elevation: isCurrentMonth ? 8 : (hasData ? 6 : 4),
      color: isCurrentMonth 
          ? Theme.of(context).primaryColor 
          : (hasData ? Colors.blue.shade50 : null),
      child: InkWell(
        onTap: () {
          final selectedDate = DateTime(_currentYear, month); // CORRECTION: utiliser 'month' au lieu de 'monthIndex + 1'
                    
          // Navigation vers l'écran de budget mensuel avec les 4 onglets
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonthlyBudgetScreen(
                selectedMonth: selectedDate,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Nom du mois
              Text(
                monthName.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrentMonth 
                      ? Colors.white 
                      : (hasData ? Colors.blue.shade700 : Colors.black87),
                ),
                textAlign: TextAlign.center,
              ),
              
              // Icône et indicateur
              Icon(
                hasData ? Icons.account_balance_wallet : Icons.calendar_month,
                size: 24,
                color: isCurrentMonth 
                    ? Colors.white 
                    : (hasData ? Colors.blue.shade600 : Colors.grey.shade600),
              ),
              
              // Données financières
              if (hasData) ...[
                Column(
                  children: [
                    if (revenus > 0)
                      _buildDataRow('R', revenus, Colors.green, isCurrentMonth),
                    if (charges > 0)
                      _buildDataRow('C', charges, Colors.red, isCurrentMonth),
                    if (depenses > 0)
                      _buildDataRow('D', depenses, Colors.purple, isCurrentMonth),
                    const SizedBox(height: 4),
                    // Solde
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (solde >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1), // CORRECTION: remplacer withOpacity par withValues
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: solde >= 0 ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_formatAmount(solde)}€',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: solde >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Aucune donnée',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrentMonth ? Colors.white70 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, double amount, Color color, bool isCurrentMonth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCurrentMonth ? Colors.white70 : color,
            ),
          ),
          Text(
            '${_formatAmount(amount)}€',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCurrentMonth ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0);
  }
}