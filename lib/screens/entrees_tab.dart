import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Ajouter cet import pour kDebugMode
import 'package:intl/intl.dart';
import '../services/encrypted_budget_service.dart';
import '../utils/amount_parser.dart';

class EntreesTab extends StatefulWidget {
  final DateTime? selectedMonth; // Ajouter ce paramètre optionnel
  
  const EntreesTab({
    super.key,
    this.selectedMonth,
  });

  @override
  State<EntreesTab> createState() => _EntreesTabState();
}

class _EntreesTabState extends State<EntreesTab> {
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  List<Map<String, dynamic>> entrees = [];
  List<Map<String, dynamic>> filteredEntrees = [];
  double totalEntrees = 0.0;
  double soldeDisponible = 0.0;
  bool isLoading = false;

  // Variables de filtrage
  DateTime? _selectedFilterDate;
  String _currentFilter = 'Tous';

  // Variables pour sélection multiple
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  bool _isProcessingBatch = false;

  // Variables financières à ajouter
  double totalSorties = 0.0;
  double totalDepenses = 0.0;
  double totalSortiesPointees = 0.0;
  double totalDepensesPointees = 0.0;
  
  // AJOUTER ces variables manquantes pour les revenus
  double totalRevenus = 0.0;
  double totalRevenuPointe = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEntrees();
    _loadFinancialData(); // Nouvelle méthode pour charger les données financières
  }

  Future<void> _loadEntrees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _dataService.getEntrees();
      
      // Charger TOUTES les données pour les calculs
      final sortiesData = await _dataService.getSorties();
      final plaisirsData = await _dataService.getPlaisirs();
      
      setState(() {
        entrees = data;
        
        // AJOUTER le calcul des totaux de revenus
        if (widget.selectedMonth != null) {
          // Calculs mensuels pour le mois sélectionné
          totalRevenus = entrees.where((e) {
            final date = DateTime.tryParse(e['date'] ?? '');
            return date != null && 
                   date.year == widget.selectedMonth!.year &&
                   date.month == widget.selectedMonth!.month;
          }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
          
          totalRevenuPointe = entrees.where((e) {
            final date = DateTime.tryParse(e['date'] ?? '');
            return date != null && 
                   date.year == widget.selectedMonth!.year &&
                   date.month == widget.selectedMonth!.month &&
                   e['isPointed'] == true;
          }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
          
          totalSorties = sortiesData.where((s) {
            final date = DateTime.tryParse(s['date'] ?? '');
            return date != null && 
                   date.year == widget.selectedMonth!.year &&
                   date.month == widget.selectedMonth!.month;
          }).fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
          
          totalDepenses = plaisirsData.where((p) {
            final date = DateTime.tryParse(p['date'] ?? '');
            return date != null && 
                   date.year == widget.selectedMonth!.year &&
                   date.month == widget.selectedMonth!.month;
          }).fold(0.0, (sum, p) {
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            if (p['isCredit'] == true) {
              return sum - amount; // Les crédits réduisent le total des dépenses
            } else {
              return sum + amount; // Les dépenses normales augmentent le total
            }
          });
          
          totalSortiesPointees = sortiesData.where((s) {
            final date = DateTime.tryParse(s['date'] ?? '');
            return date != null && 
                   date.year == widget.selectedMonth!.year &&
                   date.month == widget.selectedMonth!.month &&
                   s['isPointed'] == true;
          }).fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
          
          totalDepensesPointees = plaisirsData.where((p) {
            final date = DateTime.tryParse(p['date'] ?? '');
            return date != null && 
                   date.year == widget.selectedMonth!.year &&
                   date.month == widget.selectedMonth!.month &&
                   p['isPointed'] == true;
          }).fold(0.0, (sum, p) {
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            if (p['isCredit'] == true) {
              return sum - amount; // Les crédits pointés réduisent
            } else {
              return sum + amount; // Les dépenses pointées augmentent
            }
          });
        } else {
          // Calculs globaux
          totalRevenus = entrees.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
          totalRevenuPointe = entrees
              .where((e) => e['isPointed'] == true)
              .fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
          
          totalSorties = sortiesData.fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
          totalDepenses = plaisirsData.fold(0.0, (sum, p) {
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            if (p['isCredit'] == true) {
              return sum - amount;
            } else {
              return sum + amount;
            }
          });
          
          totalSortiesPointees = sortiesData
              .where((s) => s['isPointed'] == true)
              .fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
          
          totalDepensesPointees = plaisirsData
              .where((p) => p['isPointed'] == true)
              .fold(0.0, (sum, p) {
                final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                if (p['isCredit'] == true) {
                  return sum - amount;
                } else {
                  return sum + amount;
                }
              });
        }
        
        // Si un mois spécifique est sélectionné, filtrer automatiquement
        if (widget.selectedMonth != null) {
          _currentFilter = 'Mois';
          _selectedFilterDate = widget.selectedMonth;
          _applyFilter();
        } else {
          filteredEntrees = List.from(entrees);
          // Appliquer le tri par défaut
          _sortFilteredList();
          _calculateTotals();
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
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

  // Nouvelle méthode pour charger toutes les données financières
  Future<void> _loadFinancialData() async {
    try {
      final sorties = await _dataService.getSorties();
      final plaisirs = await _dataService.getPlaisirs();
      
      setState(() {
        totalSorties = sorties.fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
        totalDepenses = plaisirs.fold(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));
        
        // Calculer les montants pointés
        totalSortiesPointees = sorties
            .where((s) => s['isPointed'] == true)
            .fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
        
        // CORRECTION : Calcul des dépenses pointées avec gestion des crédits
        totalDepensesPointees = plaisirs
            .where((p) => p['isPointed'] == true)
            .fold(0.0, (sum, p) {
              final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
              if (p['isCredit'] == true) {
                // Les virements/remboursements pointés RÉDUISENT le total des dépenses pointées
                return sum - amount;
              } else {
                // Les dépenses normales pointées AUGMENTENT le total des dépenses pointées
                return sum + amount;
              }
            });
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement données financières: $e');
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_currentFilter == 'Tous') {
        filteredEntrees = List.from(entrees);
      } else if (_currentFilter == 'Pointés') {
        filteredEntrees = entrees.where((entree) => entree['isPointed'] == true).toList();
      } else if (_currentFilter == 'Non pointés') {
        filteredEntrees = entrees.where((entree) => entree['isPointed'] != true).toList();
      } else if (_currentFilter == 'Mois' && _selectedFilterDate != null) {
        filteredEntrees = entrees.where((entree) {
          final entreeDate = DateTime.tryParse(entree['date'] ?? '');
          if (entreeDate == null) return false;
          return entreeDate.year == _selectedFilterDate!.year &&
                 entreeDate.month == _selectedFilterDate!.month;
        }).toList();
      } else {
        filteredEntrees = List.from(entrees);
      }
      
      // Appliquer le tri
      _sortFilteredList();
      
      // Recalculer le total des entrées filtrées
      totalEntrees = filteredEntrees.fold(0.0, 
        (sum, entree) => sum + ((entree['amount'] as num?)?.toDouble() ?? 0.0));
    });
  }

  void _calculateTotals() {
    // Calculer le total des entrées
    totalEntrees = entrees.fold(0.0, (sum, entree) => sum + ((entree['amount'] as num?)?.toDouble() ?? 0.0));
    
    // Si un filtre est appliqué, recalculer le total des entrées filtrées
    if (_currentFilter != 'Tous' && _selectedFilterDate != null) {
      final filteredTotal = filteredEntrees.fold(0.0, 
        (sum, entree) => sum + ((entree['amount'] as num?)?.toDouble() ?? 0.0));
      
      setState(() {
        totalEntrees = filteredTotal;
      });
    }
  }

  void _sortFilteredList() {
    filteredEntrees.sort((a, b) {
      final aPointed = a['isPointed'] == true;
      final bPointed = b['isPointed'] == true;
      
      if (aPointed == bPointed) {
        // Si même statut de pointage, trier par date décroissante (plus récent en premier)
        final aDate = DateTime.tryParse(a['date'] ?? '');
        final bDate = DateTime.tryParse(b['date'] ?? '');
        if (aDate != null && bDate != null) {
          return bDate.compareTo(aDate);
        }
        return 0;
      }
      
      // Non pointés (false) en premier, pointés (true) en dernier
      return aPointed ? 1 : -1;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les revenus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tous'),
              leading: Radio<String>(
                value: 'Tous',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value!;
                    _selectedFilterDate = null;
                  });
                  Navigator.pop(context);
                  _applyFilter();
                },
              ),
            ),
            ListTile(
              title: const Text('Pointés'),
              leading: Radio<String>(
                value: 'Pointés',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value!;
                    _selectedFilterDate = null;
                  });
                  Navigator.pop(context);
                  _applyFilter();
                },
              ),
            ),
            ListTile(
              title: const Text('Non pointés'),
              leading: Radio<String>(
                value: 'Non pointés',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value!;
                    _selectedFilterDate = null;
                  });
                  Navigator.pop(context);
                  _applyFilter();
                },
              ),
            ),
            ListTile(
              title: const Text('Par mois'),
              leading: Radio<String>(
                value: 'Mois',
                groupValue: _currentFilter,
                onChanged: (value) {
                  Navigator.pop(context);
                  _pickFilterDate();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHeader() {
    // Utiliser les totaux calculés dans _loadEntrees()
    final soldePrevu = totalEntrees - totalSorties - totalDepenses;
    final soldeDebite = totalEntrees - totalSortiesPointees - totalDepensesPointees;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ligne de contrôles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 8),
              Row(
                children: [
                  if (filteredEntrees.isNotEmpty)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSelectionMode = !_isSelectionMode;
                          if (!_isSelectionMode) {
                            _selectedIndices.clear();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: Icon(
                          _isSelectionMode ? Icons.close : Icons.checklist,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Total des revenus
          Text(
            '${AmountParser.formatAmount(totalEntrees)} €',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Soldes prévu et débité
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Solde Prévu',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${AmountParser.formatAmount(soldePrevu)} €',
                        style: TextStyle(
                          color: soldePrevu >= 0 ? Colors.white : Colors.orange.shade200,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Solde Débité',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${AmountParser.formatAmount(soldeDebite)} €',
                        style: TextStyle(
                          color: soldeDebite >= 0 ? Colors.green.shade200 : Colors.orange.shade200,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 5),
          Text(
            '${filteredEntrees.length} revenu${filteredEntrees.length > 1 ? 's' : ''} • ${filteredEntrees.where((e) => e['isPointed'] == true).length} pointé${filteredEntrees.where((e) => e['isPointed'] == true).length > 1 ? 's' : ''}${_currentFilter != 'Tous' ? ' • $_currentFilter' : ''}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final soldeDebite = (totalRevenus - totalSorties - totalDepenses);
    
    return Card(
      elevation: 4,
      color: Colors.green.shade700,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ligne du titre avec le bouton de copie
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Résumé des revenus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // AJOUTER le bouton de copie (uniquement si on est dans la vue mensuelle)
                if (widget.selectedMonth != null) ...[
                  IconButton(
                    onPressed: _copyRevenuesToNextMonth,
                    icon: const Icon(Icons.content_copy, color: Colors.white),
                    tooltip: 'Copier vers le mois suivant',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Reste du contenu existant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text(
                      'Total Revenus',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${totalRevenus.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white30,
                ),
                Column(
                  children: [
                    const Text(
                      'Non pointé',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${(totalRevenus - totalRevenuPointe).toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white30,
                ),
                Column(
                  children: [
                    const Text(
                      'Solde',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${soldeDebite.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: soldeDebite >= 0 ? Colors.white : Colors.red.shade200,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFilterDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _currentFilter = 'Mois';
        _selectedFilterDate = date;
      });
      _applyFilter();
    }
  }

  Future<Map<String, dynamic>?> _showEntreeDialog({
    String? description,
    double? amount,
    DateTime? date,
    bool isEdit = false,
  }) async {
    final descriptionController = TextEditingController(text: description ?? '');
    final montantController = TextEditingController(
      text: amount != null ? AmountParser.formatAmount(amount) : ''
    );
    DateTime? selectedDate = date ?? (widget.selectedMonth ?? DateTime.now());

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (builderCtx, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add,
                color: isEdit ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Modifier le revenu' : 'Ajouter un revenu'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    helperText: 'Salaire, prime, freelance...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: montantController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Montant (€)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                    helperText: 'Ex: 2500.00',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: builderCtx,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (descriptionController.text.trim().isNotEmpty &&
                    montantController.text.trim().isNotEmpty &&
                    selectedDate != null) {
                  Navigator.pop(dialogCtx, {
                    'description': descriptionController.text.trim(),
                    'amount': AmountParser.parseAmount(montantController.text),
                    'date': selectedDate,
                    'success': true,
                  });
                }
              },
              child: Text(isEdit ? 'Modifier' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEntree() async {
    final parentCtx = context;
    final result = await _showEntreeDialog();
    if (result == null) return;
    try {
      await _dataService.addEntree(
        amountStr: result['amount'].toString(),
        description: result['description'],
        date: result['date'],
      );
      await _loadEntrees();
      if (!mounted) return;
      ScaffoldMessenger.of(parentCtx).showSnackBar(
        const SnackBar(
          content: Text('✅ Revenu ajouté'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(parentCtx).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editEntree(int displayIndex) async {
  final parentCtx = context; // capture avant await
  // Utiliser filteredEntrees au lieu de entrees
  final entree = filteredEntrees[displayIndex];
    final entreeId = entree['id'] ?? '';
    
  final originalEntrees = await _dataService.getEntrees();
    final realIndex = originalEntrees.indexWhere((e) => e['id'] == entreeId);
    
    if (realIndex == -1) return;
  final result = await _showEntreeDialog(
      description: entree['description'],
      amount: (entree['amount'] as num?)?.toDouble(),
      date: DateTime.tryParse(entree['date'] ?? ''),
      isEdit: true,
    );
    
    if (result != null) {
      try {
        await _dataService.updateEntree(
          index: realIndex,
          amountStr: result['amount'].toString(),
          description: result['description'],
          date: result['date'],
        );
        await _loadEntrees();
        if (!mounted) return;
        ScaffoldMessenger.of(parentCtx).showSnackBar(
          const SnackBar(
            content: Text('✅ Revenu modifié'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(parentCtx).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntree(int displayIndex) async {
  final parentCtx = context; // capture avant await
  // Utiliser filteredEntrees et trouver le vrai index
  final entree = filteredEntrees[displayIndex];
    final entreeId = entree['id'] ?? '';
    
    // Trouver l'index réel dans la liste complète
  final originalEntrees = await _dataService.getEntrees();
    final realIndex = originalEntrees.indexWhere((e) => e['id'] == entreeId);
    
    if (realIndex == -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Revenu non trouvé'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: parentCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voulez-vous vraiment supprimer ce revenu ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entree['description'] ?? 'Sans description',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(entree['amount'] as num?)?.toDouble().toStringAsFixed(2).replaceAll('.', ',')} €',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  if (entree['date'] != null)
                    Text(
                      'Date: ${DateTime.tryParse(entree['date']).toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _dataService.deleteEntree(realIndex);
      await _loadEntrees();
      if (!mounted) return;
      ScaffoldMessenger.of(parentCtx).showSnackBar(
        SnackBar(
          content: Text('✅ Revenu "${entree['description']}" supprimé'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(parentCtx).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePointing(int displayIndex) async {
  if (!mounted) return;
  final parentCtx = context;
  try {
      final entreeToToggle = filteredEntrees[displayIndex];
      final entreeId = entreeToToggle['id'] ?? '';
      
      final originalEntrees = await _dataService.getEntrees();
      final realIndex = originalEntrees.indexWhere((e) => e['id'] == entreeId);
      
      if (realIndex == -1) {
        throw Exception('Revenu non trouvé');
      }
      
      await _dataService.toggleEntreePointing(realIndex);
  await _loadEntrees();
      // Réappliquer le tri après le rechargement
      _sortFilteredList();
  if (!mounted) return;
  final isPointed = entreeToToggle['isPointed'] == true;
  ScaffoldMessenger.of(parentCtx).showSnackBar(
        SnackBar(
          content: Text(
            !isPointed 
              ? '✅ Revenu pointé - Solde mis à jour'
              : '↩️ Revenu dépointé - Solde mis à jour'
          ),
          backgroundColor: !isPointed ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(parentCtx).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du pointage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _batchTogglePointing() async {
    if (_selectedIndices.isEmpty || _isProcessingBatch) return;

    setState(() {
      _isProcessingBatch = true;
    });

    try {
      final realIndices = <int>[];
      for (int displayIndex in _selectedIndices) {
        final entree = filteredEntrees[displayIndex];
        final entreeId = entree['id'] ?? '';
        
        final originalEntrees = await _dataService.getEntrees();
        final realIndex = originalEntrees.indexWhere((e) => e['id'] == entreeId);
        
        if (realIndex != -1) {
          realIndices.add(realIndex);
        }
      }

      // Pointer en lot (en ordre décroissant pour éviter les problèmes d'index)
      realIndices.sort((a, b) => b.compareTo(a));
      for (int realIndex in realIndices) {
        await _dataService.toggleEntreePointing(realIndex);
      }

      await _loadEntrees();

      if (!mounted) return;
      
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${realIndices.length} revenu(s) mis à jour'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du traitement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBatch = false;
        });
      }
    }
  }

  Future<void> _batchDeleteEntrees() async {
    if (_selectedIndices.isEmpty) return;

    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${_selectedIndices.length} revenu(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessingBatch = true;
    });

    try {
      // Convertir les index d'affichage en index réels
      final originalEntrees = await _dataService.getEntrees();
      List<int> realIndices = [];
      
      for (int displayIndex in _selectedIndices) {
        final entree = filteredEntrees[displayIndex];
        final entreeId = entree['id'] ?? '';
        final realIndex = originalEntrees.indexWhere((e) => e['id'] == entreeId);
        
        if (realIndex != -1) {
          realIndices.add(realIndex);
        }
      }
      
      // Traiter dans l'ordre inverse pour éviter les décalages d'index
      realIndices.sort((a, b) => b.compareTo(a));
      
      for (int realIndex in realIndices) {
        await _dataService.deleteEntree(realIndex);
      }

      // Recharger les données
      await _loadEntrees();

      if (!mounted) return;

      // Sortir du mode sélection
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${realIndices.length} revenu(s) supprimé(s)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBatch = false;
        });
      }
    }
  }

  // AJOUTER cette nouvelle méthode pour copier les revenus vers le mois suivant
  Future<void> _copyRevenuesToNextMonth() async {
    if (widget.selectedMonth == null) return;

    final parentCtx = context; // capture
    final currentMonth = widget.selectedMonth!;
    final nextMonth = DateTime(
      currentMonth.month == 12 ? currentMonth.year + 1 : currentMonth.year,
      currentMonth.month == 12 ? 1 : currentMonth.month + 1,
    );
    final currentMonthName = _getMonthName(currentMonth.month);
    final nextMonthName = _getMonthName(nextMonth.month);

    final currentMonthRevenus = entrees.where((r) {
      final d = DateTime.tryParse(r['date'] ?? '');
      return d != null && d.year == currentMonth.year && d.month == currentMonth.month;
    }).toList();

    if (currentMonthRevenus.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(parentCtx).showSnackBar(
          SnackBar(
            content: Text('❌ Aucun revenu trouvé pour $currentMonthName ${currentMonth.year}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final existingNextMonthRevenus = entrees.where((r) {
      final d = DateTime.tryParse(r['date'] ?? '');
      return d != null && d.year == nextMonth.year && d.month == nextMonth.month;
    }).toList();

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: parentCtx,
      builder: (dCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.content_copy, color: Colors.green),
            SizedBox(width: 12),
            Text('Copier les revenus'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copier tous les revenus de $currentMonthName ${currentMonth.year} vers $nextMonthName ${nextMonth.year} ?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text('💰 ${currentMonthRevenus.length} revenu(s) à copier :'),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: currentMonthRevenus.map((revenu) {
                    final amount = (revenu['amount'] as num?)?.toDouble() ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${revenu['description']} - ${amount.toStringAsFixed(2).replaceAll('.', ',')}€', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                ),
              ),
              if (existingNextMonthRevenus.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attention : ${existingNextMonthRevenus.length} revenu(s) existe(nt) déjà pour $nextMonthName ${nextMonth.year}. Les nouveaux revenus seront ajoutés.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Les revenus seront copiés comme nouveaux éléments indépendants. Modifier ou supprimer l\'un n\'affectera pas l\'autre.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Copier'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Progress dialog
    showDialog(
      context: parentCtx,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('💰 Copie des revenus en cours...'),
          ],
        ),
      ),
    );

    int copiedCount = 0;
    int skippedCount = 0;
    final errors = <String>[];

    for (final revenu in currentMonthRevenus) {
      final originalDate = DateTime.tryParse(revenu['date'] ?? '');
      if (originalDate == null) {
        skippedCount++;
        continue;
      }
      final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
      final newDay = originalDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : originalDate.day;
      final newDate = DateTime(nextMonth.year, nextMonth.month, newDay);
      try {
        await _dataService.addEntree(
          amountStr: (revenu['amount'] as num).toString(),
            description: revenu['description'] as String,
            date: newDate,
        );
        copiedCount++;
      } catch (e) {
        errors.add('${revenu['description']}: $e');
        skippedCount++;
      }
    }

    if (!mounted) return; // still open dialog
    Navigator.of(parentCtx).pop(); // close progress
    await _loadEntrees();
    if (!mounted) return;

    String message;
    Color bg;
    if (copiedCount > 0 && errors.isEmpty) {
      message = '✅ $copiedCount revenu(s) copié(s) vers $nextMonthName ${nextMonth.year}';
      bg = Colors.green;
    } else if (copiedCount > 0 && errors.isNotEmpty) {
      message = '⚠️ $copiedCount copiés, $skippedCount échoués vers $nextMonthName ${nextMonth.year}';
      bg = Colors.orange;
    } else {
      message = '❌ Aucun revenu copié vers $nextMonthName ${nextMonth.year}';
      bg = Colors.red;
    }
    ScaffoldMessenger.of(parentCtx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        duration: const Duration(seconds: 4),
      ),
    );
    if (errors.isNotEmpty && mounted) {
      showDialog(
        context: parentCtx,
        builder: (_) => AlertDialog(
          title: const Text('⚠️ Erreurs de copie'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${errors.length} erreur(s) :'),
                const SizedBox(height: 8),
                ...errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(parentCtx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des revenus...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          filteredEntrees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 100,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _currentFilter == 'Tous' 
                            ? 'Aucun revenu enregistré'
                            : 'Aucun revenu pour cette période',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ajoutez vos revenus (salaire, primes...)',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _addEntree,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un revenu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // En-tête avec totaux et filtres
                    _buildFinancialHeader(),
                    _buildSummaryCard(), // AJOUTER la carte de résumé

                    // Barre d'outils avec bouton sélection multiple
                    if (filteredEntrees.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = !_isSelectionMode;
                                  if (!_isSelectionMode) {
                                    _selectedIndices.clear();
                                  }
                                });
                              },
                              icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
                              label: Text(_isSelectionMode ? 'Annuler sélection' : 'Sélection multiple'),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),

                    // Liste des entrées filtrées
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredEntrees.length,
                        itemBuilder: (context, index) {
                          final entree = filteredEntrees[index];
                          final amount = (entree['amount'] as num?)?.toDouble() ?? 0;
                          final description = entree['description'] as String? ?? '';
                          final dateStr = entree['date'] as String? ?? '';
                          final date = DateTime.tryParse(dateStr);
                          final isPointed = entree['isPointed'] == true;
                          final isSelected = _selectedIndices.contains(index);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Colors.blue.shade50 : null,
                            child: ListTile(
                              // Case à cocher en mode sélection ou indicateur de pointage
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (value) => _toggleSelection(index),
                                      activeColor: Colors.blue,
                                    )
                                  : GestureDetector(
                                      onTap: () => _togglePointing(index),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isPointed ? Colors.green.shade100 : Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isPointed ? Colors.green.shade300 : Colors.blue.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          isPointed ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: isPointed ? Colors.green.shade700 : Colors.blue.shade700,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                              title: Text(
                                description,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isPointed ? TextDecoration.lineThrough : null,
                                  color: isPointed ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AmountParser.formatAmount(amount)} €',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isPointed ? Colors.grey : Colors.green.shade700,
                                    ),
                                  ),
                                  if (date != null)
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(date),
                                      style: TextStyle(
                                        color: isPointed ? Colors.grey : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (isPointed && entree['pointedAt'] != null)
                                    Text(
                                      'Pointé le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(entree['pointedAt']))}',
                                      style: TextStyle(
                                        color: Colors.green.shade600,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: _isSelectionMode 
                                  ? null 
                                  : PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'point') {
                                          await _togglePointing(index);
                                        } else if (value == 'edit') {
                                          await _editEntree(index);
                                        } else if (value == 'delete') {
                                          await _deleteEntree(index);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'point',
                                          child: Row(
                                            children: [
                                              Icon(
                                                isPointed ? Icons.radio_button_unchecked : Icons.check_circle,
                                                color: isPointed ? Colors.orange : Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(isPointed ? 'Dépointer' : 'Pointer'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Modifier'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Supprimer'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                              onTap: _isSelectionMode
                                  ? () => _toggleSelection(index)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          
          // Barre d'actions en mode sélection
          if (_isSelectionMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: Row(
                    children: [
                      Text(
                        '${_selectedIndices.length} sélectionné(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _isSelectionMode = false;
                          _selectedIndices.clear();
                        }),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _selectedIndices.isEmpty || _isProcessingBatch
                            ? null
                            : _batchTogglePointing,
                        icon: _isProcessingBatch
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isProcessingBatch ? 'Pointage...' : 'Pointer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _selectedIndices.isEmpty || _isProcessingBatch
                            ? null
                            : _batchDeleteEntrees,
                        icon: _isProcessingBatch
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                              )
                            : const Icon(Icons.delete),
                        label: Text(_isProcessingBatch ? 'Suppression...' : 'Supprimer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _addEntree,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _AddEntreeDialog extends StatefulWidget {
  final Future<bool> Function(String amount, String description, DateTime date, String periodicity) onAdd;

  const _AddEntreeDialog({required this.onAdd});

  @override
  State<_AddEntreeDialog> createState() => _AddEntreeDialogState();
}

class _AddEntreeDialogState extends State<_AddEntreeDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final String _selectedPeriodicity = 'ponctuel';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un revenu'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Champ montant
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                  suffixText: '€',
                ),
              ),
              const SizedBox(height: 16),

              // Champ description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),

              // Sélecteur de date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sélecteur de périodicité
              // Suppression du sélecteur de périodicité
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAdd,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }

  void _handleAdd() async {
    if (_amountController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.onAdd(
        _amountController.text,
        _descriptionController.text,
        _selectedDate,
        _selectedPeriodicity,
      );

      if (success && mounted) {
        Navigator.of(context).pop({'success': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}