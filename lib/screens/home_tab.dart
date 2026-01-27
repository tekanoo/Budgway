import 'package:flutter/material.dart';
import '../services/encrypted_budget_service.dart';
import '../utils/amount_parser.dart';

class HomeTab extends StatefulWidget {
  final DateTime? selectedMonth; // Ajouter ce paramètre optionnel
  
  const HomeTab({
    super.key,
    this.selectedMonth, // Paramètre optionnel pour garder la compatibilité
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  
  // Données du mois
  double _monthlyEntrees = 0.0;
  double _monthlySorties = 0.0;
  double _monthlyPlaisirs = 0.0;
  double _monthlySortiesPointees = 0.0;      // Charges pointées
  double _monthlyPlaisirsPointees = 0.0;     // Dépenses (avec virements) pointées
  double _monthlyEntreesPointees = 0.0;      // Revenus pointés
  List<String> _availableTags = [];
  
  @override
  void initState() {
    super.initState();
    // Si selectedMonth est fourni, l'utiliser comme date sélectionnée
    if (widget.selectedMonth != null) {
      _selectedDate = widget.selectedMonth;
    }
    _loadMonthlyData();
    _loadAvailableTags();
  }
  
  // Modifier la méthode _loadMonthlyData pour filtrer par mois si nécessaire
  Future<void> _loadMonthlyData() async {
    try {
      if (widget.selectedMonth != null) {
        // Filtrer par mois sélectionné
        final entrees = await _dataService.getEntrees();
        final sorties = await _dataService.getSorties();
        final plaisirs = await _dataService.getPlaisirs();
        
        // Filtrer par mois
        final monthlyEntrees = entrees.where((e) {
          final date = DateTime.tryParse(e['date'] ?? '');
          return date != null && 
                 date.year == widget.selectedMonth!.year &&
                 date.month == widget.selectedMonth!.month;
        }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
        
        final monthlySorties = sorties.where((s) {
          final date = DateTime.tryParse(s['date'] ?? '');
          return date != null && 
                 date.year == widget.selectedMonth!.year &&
                 date.month == widget.selectedMonth!.month;
        }).fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
        
        // Calculer les dépenses comme dans l'onglet dépenses (virements soustraits)
        final monthlyPlaisirs = plaisirs.where((p) {
          final date = DateTime.tryParse(p['date'] ?? '');
          return date != null && 
                 date.year == widget.selectedMonth!.year &&
                 date.month == widget.selectedMonth!.month;
        }).fold(0.0, (sum, p) {
          final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
          if (p['isCredit'] == true) {
            return sum - amount; // Les virements réduisent le total
          } else {
            return sum + amount; // Les dépenses normales augmentent le total
          }
        });
        
        // Calculer les montants pointés pour ce mois
        final monthlySortiesPointees = sorties.where((s) {
          final date = DateTime.tryParse(s['date'] ?? '');
          return date != null && 
                 date.year == widget.selectedMonth!.year &&
                 date.month == widget.selectedMonth!.month &&
                 s['isPointed'] == true;
        }).fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
        
        final monthlyPlaisirsPointees = plaisirs.where((p) {
          final date = DateTime.tryParse(p['date'] ?? '');
          return date != null && 
                 date.year == widget.selectedMonth!.year &&
                 date.month == widget.selectedMonth!.month &&
                 p['isPointed'] == true;
        }).fold(0.0, (sum, p) {
          final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
          if (p['isCredit'] == true) {
            return sum - amount; // Les virements pointés réduisent le total pointé
          } else {
            return sum + amount; // Les dépenses pointées augmentent le total pointé
          }
        });
        
        // NOUVEAU : Calculer les revenus normaux pointés (sans virements)
        final monthlyEntreesPointees = entrees.where((e) {
          final date = DateTime.tryParse(e['date'] ?? '');
          return date != null && 
                 date.year == widget.selectedMonth!.year &&
                 date.month == widget.selectedMonth!.month &&
                 e['isPointed'] == true;
        }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
        
        setState(() {
          _monthlyEntrees = monthlyEntrees; // virements ne sont plus ajoutés aux revenus
          _monthlySorties = monthlySorties;
          _monthlyPlaisirs = monthlyPlaisirs; // Dépenses nettes (virements soustraits)
          _monthlySortiesPointees = monthlySortiesPointees;
          _monthlyPlaisirsPointees = monthlyPlaisirsPointees; // dépenses pointées nettes
          _monthlyEntreesPointees = monthlyEntreesPointees; // NOUVEAU
        });
      } else {
        // CORRECTION : Pour le calcul global, séparer aussi les virements
        final entrees = await _dataService.getEntrees();
        final sorties = await _dataService.getSorties();
        final plaisirs = await _dataService.getPlaisirs();
        
        final totalEntreesAmount = entrees.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
        final totalSortiesAmount = sorties.fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
        
  double totalPlaisirsAmount = 0.0; // dépenses nettes (virements soustraits)
  double totalSortiesPointees = 0.0;
  double totalPlaisirsPointees = 0.0; // dépenses pointées nettes
        
        for (var plaisir in plaisirs) {
          final amount = (plaisir['amount'] as num?)?.toDouble() ?? 0.0;
          if (plaisir['isCredit'] == true) {
            totalPlaisirsAmount -= amount; // Les virements réduisent le total
          } else {
            totalPlaisirsAmount += amount; // Les dépenses normales augmentent le total
          }
        }
        
    // Charges pointées
    totalSortiesPointees = sorties.where((s) => s['isPointed'] == true)
      .fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));

    // Dépenses pointées nettes (virements soustraits)
    totalPlaisirsPointees = plaisirs.where((p) => p['isPointed'] == true)
      .fold(0.0, (sum, p) {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        if (p['isCredit'] == true) {
          return sum - amount; // Les virements pointés réduisent le total pointé
        } else {
          return sum + amount; // Les dépenses pointées augmentent le total pointé
        }
      });
        
        // NOUVEAU : Calculer les revenus normaux pointés
        double totalEntreesPointees = entrees
            .where((e) => e['isPointed'] == true)
            .fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
        
        setState(() {
          _monthlyEntrees = totalEntreesAmount; // revenus uniquement
          _monthlySorties = totalSortiesAmount;  // charges
          _monthlyPlaisirs = totalPlaisirsAmount; // dépenses nettes (virements soustraits)
          _monthlySortiesPointees = totalSortiesPointees; // charges pointées
          _monthlyPlaisirsPointees = totalPlaisirsPointees; // dépenses pointées nettes
          _monthlyEntreesPointees = totalEntreesPointees; // revenus pointés
        });
      }
    } catch (e) {
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
  
  Future<void> _loadAvailableTags() async {
    try {
      final plaisirs = await _dataService.getPlaisirs();
      final tags = plaisirs
          .map((p) => p['tag'] as String? ?? '')
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList();
      
      setState(() {
        _availableTags = tags;
      });
    } catch (e) {
      // Gestion d'erreur silencieuse
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Afficher le mois sélectionné si spécifié
    final monthName = widget.selectedMonth != null 
        ? _getMonthName(widget.selectedMonth!)
        : 'Budget Global';
    final solde = _monthlyEntrees - _monthlySorties - _monthlyPlaisirs;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre du mois
            if (widget.selectedMonth != null) ...[
              Text(
                'Dashboard - $monthName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Cartes de résumé
            _buildSummaryCards(solde),
            
            const SizedBox(height: 20),
            
            // Section d'ajout rapide
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajout rapide - Dépense',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Montant',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.euro),
                              suffixText: '€',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _tagController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: 'Catégorie',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.tag),
                              suffixIcon: _availableTags.isNotEmpty
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) {
                                        _tagController.text = value;
                                      },
                                      itemBuilder: (context) => _availableTags
                                          .map((tag) => PopupMenuItem(
                                                value: tag,
                                                child: Text(tag),
                                              ))
                                          .toList(),
                                      icon: const Icon(Icons.arrow_drop_down),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate != null 
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : 'Sélectionner une date',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _addExpense,
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour obtenir le nom du mois
  String _getMonthName(DateTime date) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  Widget _buildSummaryCards(double solde) {
  // Solde Prévu (calculé avant) = Revenus - Charges - Dépenses
  // Solde Débité = Revenus pointés - Charges pointées - Dépenses pointées
  final soldeDebiteCalcule = _monthlyEntreesPointees - _monthlySortiesPointees - _monthlyPlaisirsPointees;
    
    return Column(
      children: [
        // NOUVELLE SECTION : Seulement Solde Prévu et Solde Débité
        Row(
          children: [
            // Solde Prévu
            Expanded(
              child: Card(
                color: solde >= 0 ? Colors.blue.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        solde >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: solde >= 0 ? Colors.blue.shade600 : Colors.red.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Solde Prévu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${AmountParser.formatAmount(solde)} €',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: solde >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Solde Débité
            Expanded(
              child: Card(
                color: soldeDebiteCalcule >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        soldeDebiteCalcule >= 0 ? Icons.check_circle : Icons.warning,
                        color: soldeDebiteCalcule >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Solde Débité',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${AmountParser.formatAmount(soldeDebiteCalcule)} €',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: soldeDebiteCalcule >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // SECTION DÉTAILS : Revenus, Charges, Dépenses (en plus petit)
        Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem('Revenus', _monthlyEntrees, Colors.green, Icons.trending_up),
                    _buildDetailItem('Charges', _monthlySorties, Colors.red, Icons.receipt_long),
                    _buildDetailItem('Dépenses', _monthlyPlaisirs, Colors.purple, Icons.shopping_cart),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NOUVELLE MÉTHODE : Widget pour les détails en petit
  Widget _buildDetailItem(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          '${AmountParser.formatAmount(amount)} €',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Limiter le sélecteur de date au mois sélectionné
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.selectedMonth ?? DateTime.now(),
      firstDate: widget.selectedMonth != null 
          ? DateTime(widget.selectedMonth!.year, widget.selectedMonth!.month, 1)
          : DateTime(2020),
      lastDate: widget.selectedMonth != null 
          ? DateTime(widget.selectedMonth!.year, widget.selectedMonth!.month + 1, 0)
          : DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  // Renommer la méthode pour plus de clarté
  Future<void> _addExpense() async {
    bool isCredit = false; // Variable locale pour la case à cocher
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.purple),
                SizedBox(width: 8),
                Text('Ajouter une dépense'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _tagController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      hintText: 'Restaurant, Courses...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Montant',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Case à cocher pour virement/remboursement
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: isCredit ? Colors.green.shade50 : null,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isCredit,
                          onChanged: (value) {
                            setState(() {
                              isCredit = value ?? false;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Virement/Remboursement',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCredit ? Colors.green.shade700 : Colors.black87,
                                ),
                              ),
                              Text(
                                'Cochez si c\'est un virement entrant',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              _selectedDate != null 
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Aujourd\'hui',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text('Modifier'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_amountController.text.trim().isEmpty || _tagController.text.isEmpty) return;
                  final navigator = Navigator.of(context); // capture avant await
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() { _isLoading = true; });
                  try {
                    await _dataService.addPlaisir(
                      amountStr: _amountController.text,
                      tag: _tagController.text,
                      date: _selectedDate ?? DateTime.now(),
                      isCredit: isCredit,
                    );
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isCredit
                              ? '💰 Virement/Remboursement ajouté avec succès'
                              : '✅ Dépense ajoutée avec succès'
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _clearFields();
                    await _loadMonthlyData();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() { _isLoading = false; });
                    }
                  }
                },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ajouter'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearFields() {
    _amountController.clear();
    _tagController.clear();
    setState(() {
      _selectedDate = null;
    });
  }
}