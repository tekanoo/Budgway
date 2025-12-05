import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/encrypted_budget_service.dart';

class ProjectionsTab extends StatefulWidget {
  const ProjectionsTab({super.key});

  @override
  State<ProjectionsTab> createState() => _ProjectionsTabState();
}

class _ProjectionsTabState extends State<ProjectionsTab> {
  final ScrollController _scrollController = ScrollController();
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  Map<String, Map<String, double>> _monthlyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getMonthKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Utiliser la nouvelle méthode avec périodicité
      final projections = await _dataService.getProjectionsWithPeriodicity(
        yearStart: 2020,
        yearEnd: 2030,
      );

      if (kDebugMode) {
        print('DEBUG: Projections avec périodicité chargées');
        print('Nombre de mois: ${projections.length}');
      }

      setState(() {
        _monthlyData = projections;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur chargement projections: $e');
      }
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

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget _buildYearCard(int year) {
    final months = List.generate(12, (index) => DateTime(year, index + 1, 1));
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        children: [
          // En-tête de l'année
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: year == DateTime.now().year 
                    ? [Colors.orange.shade600, Colors.orange.shade800]
                    : [const Color(0xFF3F51B5), const Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  year.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (year == DateTime.now().year) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ANNÉE ACTUELLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Grille des mois
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthDate = months[index];
                final monthKey = _getMonthKey(monthDate);
                final monthData = _monthlyData[monthKey] ?? {'revenus': 0.0, 'charges': 0.0, 'depenses': 0.0};
                final isCurrentMonth = DateTime.now().year == year && DateTime.now().month == monthDate.month;
                final solde = monthData['revenus']! - monthData['charges']! - monthData['depenses']!;
                
                const monthNames = [
                  'JANVIER', 'FÉVRIER', 'MARS', 'AVRIL', 'MAI', 'JUIN',
                  'JUILLET', 'AOÛT', 'SEPTEMBRE', 'OCTOBRE', 'NOVEMBRE', 'DÉCEMBRE'
                ];
                
                final hasData = monthData['revenus']! > 0 || monthData['charges']! > 0 || monthData['depenses']! > 0;
                
                return GestureDetector(
                  onTap: () => _showMonthDetails(monthDate, monthData),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentMonth 
                          ? const Color.fromARGB(255, 245, 243, 241).withValues(alpha: 0.15)
                          : (hasData ? Colors.blue.withValues(alpha: 0.05) : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentMonth 
                            ? const Color.fromARGB(255, 232, 230, 228)
                            : (hasData ? Colors.blue.shade300 : Colors.grey.shade300),
                        width: isCurrentMonth ? 2 : 1,
                      ),
                      boxShadow: isCurrentMonth ? [
                        BoxShadow(
                          color: const Color.fromARGB(255, 231, 229, 226).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      children: [
                        // Nom du mois avec indicateur mois actuel
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                monthNames[monthDate.month - 1],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentMonth 
                                      ? const Color.fromARGB(255, 228, 226, 224) 
                                      : (hasData ? Colors.blue.shade700 : Colors.black87),
                                ),
                              ),
                              if (isCurrentMonth) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 239, 237, 234),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.today,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Zone de données financières - utilise l'espace disponible
                        Expanded(
                          child: Column(
                            children: [
                              if (hasData) ...[
                                // Revenus
                                if (monthData['revenus']! > 0)
                                  _buildCompactDataRow('R', monthData['revenus']!, Colors.green),
                                
                                // Charges
                                if (monthData['charges']! > 0)
                                  _buildCompactDataRow('C', monthData['charges']!, Colors.red),
                                
                                // Dépenses
                                if (monthData['depenses']! > 0)
                                  _buildCompactDataRow('D', monthData['depenses']!, Colors.purple),
                              ] else ...[
                                // Message centré pour pas de données
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Aucune\ndonnée',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              
                              // Espacement automatique
                              const Spacer(),
                              
                              // Solde en bas - prend plus de place
                              if (hasData || isCurrentMonth)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: solde >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: solde >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'SOLDE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: solde >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_formatAmount(solde)}€',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: solde >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDataRow(String prefix, double amount, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$prefix:',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${_formatAmount(amount)}€',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthDetails(DateTime monthDate, Map<String, double> monthData) {
    final solde = monthData['revenus']! - monthData['charges']! - monthData['depenses']!;
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Titre
            Text(
              '${monthNames[monthDate.month - 1]} ${monthDate.year}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            
            // Détails financiers
            Expanded(
              child: Column(
                children: [
                  _buildDetailCard('Revenus', monthData['revenus']!, Colors.green, Icons.trending_up),
                  const SizedBox(height: 16),
                  _buildDetailCard('Charges', monthData['charges']!, Colors.red, Icons.receipt_long),
                  const SizedBox(height: 16),
                  _buildDetailCard('Dépenses', monthData['depenses']!, Colors.purple, Icons.shopping_cart),
                  const SizedBox(height: 24),
                  
                  // Solde total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: solde >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: solde >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: solde >= 0 ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solde du mois',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: solde >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        Text(
                          '${_formatAmount(solde)} €',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: solde >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, double amount, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                Text(
                  '${_formatAmount(amount)} €',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Chargement des projections...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Générer les années en ordre décroissant : 2025, 2024, 2023...
    final currentYear = DateTime.now().year;
    final years = <int>[];
    
    // Commencer par l'année en cours et aller vers le futur (jusqu'à 2030)
    for (int year = currentYear; year <= 2030; year++) {
      years.add(year);
    }
    
    // Puis ajouter les années passées (jusqu'à 2020)
    for (int year = currentYear - 1; year >= 2020; year--) {
      years.add(year);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projections'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // En-tête informatif
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Projections par année ($currentYear en premier). Les montants correspondent aux transactions réelles saisies.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Résumé des données totales
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<Map<String, double>>(
                    future: _dataService.getTotals(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final totals = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              'Totaux globaux',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTotalItem('Revenus', totals['entrees'] ?? 0, Colors.green),
                                _buildTotalItem('Charges', totals['sorties'] ?? 0, Colors.red),
                                _buildTotalItem('Dépenses', totals['plaisirs'] ?? 0, Colors.purple),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Années avec leurs mois (ordre décroissant)
              ...years.map((year) => _buildYearCard(year)),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${_formatAmount(amount)}€',
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}