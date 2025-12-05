import 'package:flutter/material.dart';
// Import foundation retiré (suppression logs)
import 'package:intl/intl.dart';
import '../services/encrypted_budget_service.dart';
import '../utils/amount_parser.dart';

class SortiesTab extends StatefulWidget {
  final DateTime? selectedMonth;
  
  const SortiesTab({
    super.key,
    this.selectedMonth,
  });

  @override
  State<SortiesTab> createState() => _SortiesTabState();
}

class _SortiesTabState extends State<SortiesTab> {
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  List<Map<String, dynamic>> sorties = [];
  List<Map<String, dynamic>> filteredSorties = [];
  double totalSorties = 0.0;
  double totalPointe = 0.0;
  double soldeDisponible = 0.0;
  bool isLoading = false;

  // Variables de filtrage
  DateTime? _selectedFilterDate;
  String _currentFilter = 'Tous';

  // Variables pour la sélection multiple
  bool _isSelectionMode = false;
  Set<int> _selectedIndices = {};
  bool _isProcessingBatch = false;

  // Variables financières
  double totalRevenus = 0.0;
  double totalDepenses = 0.0;
  double totalDepensesPointees = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSorties();
  }

  Future<void> _loadSorties() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _dataService.getSorties();
      
      // Charger TOUTES les données pour les calculs
      final entreesData = await _dataService.getEntrees();
      final plaisirsData = await _dataService.getPlaisirs();
      
      setState(() {
        sorties = data;
        
        // Calculer les totaux selon le mois sélectionné
        if (widget.selectedMonth != null) {
          // Calculs mensuels pour le mois sélectionné
          totalRevenus = entreesData.where((e) {
            final date = DateTime.tryParse(e['date'] ?? '');
            return date != null && 
                   date.year == widget.selectedMonth!.year &&
                   date.month == widget.selectedMonth!.month;
          }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
          
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
          // Calculs globaux (code existant)
          totalRevenus = entreesData.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
          totalDepenses = plaisirsData.fold(0.0, (sum, p) {
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            if (p['isCredit'] == true) {
              return sum - amount;
            } else {
              return sum + amount;
            }
          });
          
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
          filteredSorties = List.from(sorties);
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

  void _applyFilter() {
    if (_currentFilter == 'Tous' || _selectedFilterDate == null) {
      filteredSorties = List.from(sorties);
      // Restaurer les totaux globaux
      _loadSorties();
    } else {
      filteredSorties = sorties.where((sortie) {
        final sortieDate = DateTime.tryParse(sortie['date'] ?? '');
        if (sortieDate == null) return false;
        
        if (_currentFilter == 'Mois') {
          return sortieDate.year == _selectedFilterDate!.year &&
                 sortieDate.month == _selectedFilterDate!.month;
        } else if (_currentFilter == 'Année') {
          return sortieDate.year == _selectedFilterDate!.year;
        }
        return true;
      }).toList();
      
      _calculateTotals();
    }
    
    _sortFilteredList();
  }

  void _sortFilteredList() {
    filteredSorties.sort((a, b) {
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

  void _calculateTotals() {
    // Calcul des charges filtrées
    totalSorties = filteredSorties.fold(0.0, 
      (sum, sortie) => sum + ((sortie['amount'] as num?)?.toDouble() ?? 0.0));
    
    totalPointe = filteredSorties
        .where((s) => s['isPointed'] == true)
        .fold(0.0, (sum, sortie) => sum + ((sortie['amount'] as num?)?.toDouble() ?? 0.0));
    
    // CORRECTION : Recalculer les dépenses selon le filtre appliqué
    if (_currentFilter != 'Tous' && _selectedFilterDate != null) {
      // Recharger les dépenses avec le même filtre que les charges
      _loadDepensesByFilter();
    }
    
    setState(() {});
  }

  // Nouvelle méthode pour recalculer les dépenses selon le filtre
  Future<void> _loadDepensesByFilter() async {
    try {
      final plaisirsData = await _dataService.getPlaisirs();
      
      // Filtrer les dépenses avec les mêmes critères que les charges
      final filteredPlaisirs = plaisirsData.where((p) {
        final date = DateTime.tryParse(p['date'] ?? '');
        if (date == null) return false;
        
        if (_currentFilter == 'Mois') {
          return date.year == _selectedFilterDate!.year &&
                 date.month == _selectedFilterDate!.month;
        } else if (_currentFilter == 'Année') {
          return date.year == _selectedFilterDate!.year;
        }
        return true;
      }).toList();
      
      // Recalculer totalDepenses avec les dépenses filtrées
      totalDepenses = filteredPlaisirs.fold(0.0, (sum, p) {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        if (p['isCredit'] == true) {
          return sum - amount; // Les crédits réduisent le total des dépenses
        } else {
          return sum + amount; // Les dépenses normales augmentent le total
        }
      });
      
      // Recalculer totalDepensesPointees avec les dépenses filtrées ET pointées
      totalDepensesPointees = filteredPlaisirs
          .where((p) => p['isPointed'] == true)
          .fold(0.0, (sum, p) {
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            if (p['isCredit'] == true) {
              return sum - amount; // Les crédits pointés réduisent
            } else {
              return sum + amount; // Les dépenses pointées augmentent
            }
          });
      
      setState(() {});
    } catch (e) {
      // Logs supprimés
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            
            const Text(
              'Filtrer les charges',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Options de filtre
            ListTile(
              leading: Radio<String>(
                value: 'Tous',
                groupValue: _currentFilter,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = value!;
                    _selectedFilterDate = null;
                  });
                  _applyFilter();
                  Navigator.pop(context);
                },
              ),
              title: const Text('Toutes les charges'),
              subtitle: Text('${sorties.length} charges'),
            ),
            
            ListTile(
              leading: Radio<String>(
                value: 'Mois',
                groupValue: _currentFilter,
                onChanged: (value) async {
                  final navigator = Navigator.of(context);
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (!mounted) return;
                  if (date != null) {
                    setState(() {
                      _currentFilter = value!;
                      _selectedFilterDate = date;
                    });
                    _applyFilter();
                    navigator.pop();
                  }
                },
              ),
              title: const Text('Par mois'),
              subtitle: _currentFilter == 'Mois' && _selectedFilterDate != null
                  ? Text('${_getMonthName(_selectedFilterDate!.month)} ${_selectedFilterDate!.year}')
                  : const Text('Sélectionner un mois'),
            ),
            
            ListTile(
              leading: Radio<String>(
                value: 'Année',
                groupValue: _currentFilter,
                onChanged: (value) async {
                  final navigator = Navigator.of(context);
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (!mounted) return;
                  if (date != null) {
                    setState(() {
                      _currentFilter = value!;
                      _selectedFilterDate = DateTime(date.year);
                    });
                    _applyFilter();
                    navigator.pop();
                  }
                },
              ),
              title: const Text('Par année'),
              subtitle: _currentFilter == 'Année' && _selectedFilterDate != null
                  ? Text(_selectedFilterDate!.year.toString())
                  : const Text('Sélectionner une année'),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  Future<void> _togglePointing(int displayIndex) async {
    if (!mounted) return;
    
    try {
      final sortieToToggle = filteredSorties[displayIndex];
      final sortieId = sortieToToggle['id'] ?? '';
      
      final originalSorties = await _dataService.getSorties();
      final realIndex = originalSorties.indexWhere((s) => s['id'] == sortieId);
      
      if (realIndex == -1) {
        throw Exception('Charge non trouvée');
      }
      
      await _dataService.toggleSortiePointing(realIndex);
      await _loadSorties();
      // Réappliquer le tri après le rechargement
      _sortFilteredList();
      
      if (!mounted) return;
      final isPointed = sortieToToggle['isPointed'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isPointed 
              ? '✅ Charge pointée - Solde mis à jour'
              : '↩️ Charge dépointée - Solde mis à jour'
          ),
          backgroundColor: !isPointed ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du pointage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addSortie() async {
    final result = await _showSortieDialog();
    if (result != null) {
      try {
        await _dataService.addSortie(
          amountStr: result['amount'].toString(),
          description: result['description'],
          date: result['date'],
        );
        await _loadSorties();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Charge ajoutée'),
              backgroundColor: Colors.green,
            ),
          );
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
      }
    }
  }

  Future<void> _editSortie(int displayIndex) async {
    final sortie = filteredSorties[displayIndex];
    final sortieId = sortie['id'] ?? '';
    
    final originalSorties = await _dataService.getSorties();
    final realIndex = originalSorties.indexWhere((s) => s['id'] == sortieId);
    
    if (realIndex == -1) return;
    
    final result = await _showSortieDialog(
      description: sortie['description'],
      amount: (sortie['amount'] as num?)?.toDouble(),
      date: DateTime.tryParse(sortie['date'] ?? ''),
      isEdit: true,
    );
    
    if (result != null) {
      try {
        await _dataService.updateSortie(
          index: realIndex,
          amountStr: result['amount'].toString(),
          description: result['description'],
          date: result['date'],
        );
        await _loadSorties();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Charge modifiée'),
              backgroundColor: Colors.green,
            ),
          );
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
      }
    }
  }

  Future<void> _deleteSortie(int index) async {
    final sortie = filteredSorties[index];
    final sortieId = sortie['id'] ?? '';
    
    final originalSorties = await _dataService.getSorties();
    final realIndex = originalSorties.indexWhere((s) => s['id'] == sortieId);
    
    if (realIndex == -1) return;
    
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la charge'),
        content: Text('Voulez-vous vraiment supprimer "${sortie['description']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _dataService.deleteSortie(realIndex);
        await _loadSorties();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Charge supprimée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  void _selectAll() {
    setState(() {
      if (_selectedIndices.length == filteredSorties.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices = Set.from(List.generate(filteredSorties.length, (index) => index));
      }
    });
  }

  Future<void> _batchTogglePointing() async {
    if (_selectedIndices.isEmpty) return;

    setState(() {
      _isProcessingBatch = true;
    });

    try {
      final originalSorties = await _dataService.getSorties();
      List<int> realIndices = [];
      
      for (int displayIndex in _selectedIndices) {
        final sortie = filteredSorties[displayIndex];
        final sortieId = sortie['id'] ?? '';
        final realIndex = originalSorties.indexWhere((s) => s['id'] == sortieId);
        
        if (realIndex != -1) {
          realIndices.add(realIndex);
        }
      }
      
      realIndices.sort((a, b) => b.compareTo(a));
      
      for (int realIndex in realIndices) {
        await _dataService.toggleSortiePointing(realIndex);
      }

      await _loadSorties();

      if (!mounted) return;
      
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${realIndices.length} charge(s) mise(s) à jour'),
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

  Future<Map<String, dynamic>?> _showSortieDialog({
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add,
                color: isEdit ? Colors.blue : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Modifier la charge' : 'Ajouter une charge'),
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
                    helperText: 'Loyer, Électricité, Internet...',
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
                    helperText: 'Ex: 50.00',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (descriptionController.text.trim().isNotEmpty &&
                    montantController.text.trim().isNotEmpty &&
                    selectedDate != null) {
                  Navigator.pop(context, {
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

  Widget _buildFinancialHeader() {
    // Pour le solde débité, on utilise les charges pointées ET les dépenses pointées
    final soldeDebite = totalRevenus - totalPointe - totalDepensesPointees;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre et boutons d'actions
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Charges',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // AJOUTER le bouton de copie vers le mois suivant
              if (widget.selectedMonth != null) ...[
                InkWell(
                  onTap: _copyChargesToNextMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(
                      Icons.content_copy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (_isSelectionMode)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIndices.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              InkWell(
                  onTap: () {
                    setState(() {
                      _isSelectionMode = true;
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
          
          const SizedBox(height: 16),
          
          // CORRECTION : Affichage du total net des charges (charges - remboursements des dépenses)
          Column(
            children: [
              const Text(
                'Charges nettes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${totalSorties.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Statistiques en ligne
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Pointées',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${totalPointe.toStringAsFixed(2).replaceAll('.', ',')} €',
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
                    'Non pointées',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${(totalSorties - totalPointe).toStringAsFixed(2).replaceAll('.', ',')} €',
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
    );
  }

  // AJOUTER cette nouvelle méthode pour copier les charges vers le mois suivant
  Future<void> _copyChargesToNextMonth() async {
    if (widget.selectedMonth == null) return;

    // Calculer le mois suivant
    final nextMonth = DateTime(
      widget.selectedMonth!.month == 12 
          ? widget.selectedMonth!.year + 1 
          : widget.selectedMonth!.year,
      widget.selectedMonth!.month == 12 
          ? 1 
          : widget.selectedMonth!.month + 1,
    );

    final currentMonthName = _getMonthName(widget.selectedMonth!.month);
    final nextMonthName = _getMonthName(nextMonth.month);

    // Vérifier s'il y a des charges à copier pour le mois actuel
    final currentMonthCharges = sorties.where((charge) {
      final date = DateTime.tryParse(charge['date'] ?? '');
      return date != null && 
             date.year == widget.selectedMonth!.year &&
             date.month == widget.selectedMonth!.month;
    }).toList();

    if (currentMonthCharges.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Aucune charge trouvée pour $currentMonthName ${widget.selectedMonth!.year}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.content_copy, color: Colors.blue),
            SizedBox(width: 12),
            Text('Copier les charges'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copier toutes les charges de $currentMonthName ${widget.selectedMonth!.year} vers $nextMonthName ${nextMonth.year} ?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text('📋 ${currentMonthCharges.length} charge(s) à copier :'),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: currentMonthCharges.map((charge) {
                    final amount = (charge['amount'] as num?)?.toDouble() ?? 0;
                    final description = charge['description'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              description,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${amount.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Les charges seront copiées avec les mêmes montants et descriptions, mais adaptées aux dates du mois suivant.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Copier'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Afficher le dialogue de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('📋 Copie des charges en cours...'),
              ],
            ),
          ),
        );
      }

      int copiedCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      // Copier chaque charge vers le mois suivant
      for (var charge in currentMonthCharges) {
        try {
          final originalDate = DateTime.tryParse(charge['date'] ?? '');
          if (originalDate == null) {
            skippedCount++;
            continue;
          }

          // Calculer la nouvelle date dans le mois suivant
          // Garder le même jour, mais ajuster si le mois suivant n'a pas assez de jours
          final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          final newDay = originalDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : originalDate.day;
          
          final newDate = DateTime(nextMonth.year, nextMonth.month, newDay);

          // Ajouter la nouvelle charge
          await _dataService.addSortie(
            amountStr: (charge['amount'] as num).toString(),
            description: charge['description'] as String,
            date: newDate,
          );

          copiedCount++;
        } catch (e) {
          errors.add('${charge['description']}: $e');
          skippedCount++;
        }
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        navigator.pop(); // Fermer le dialogue de chargement
        
        // Recharger les données pour voir les nouvelles charges
        await _loadSorties();
        
        // Afficher le résultat
        String message;
        Color backgroundColor;
        
        if (copiedCount > 0 && errors.isEmpty) {
          message = '✅ $copiedCount charge(s) copiée(s) vers $nextMonthName ${nextMonth.year}';
          backgroundColor = Colors.green;
        } else if (copiedCount > 0 && errors.isNotEmpty) {
          message = '⚠️ $copiedCount copiée(s), $skippedCount échec(s)';
          backgroundColor = Colors.orange;
        } else {
          message = '❌ Aucune charge n\'a pu être copiée';
          backgroundColor = Colors.red;
        }
        
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
            action: errors.isNotEmpty ? SnackBarAction(
              label: 'Détails',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erreurs de copie'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: errors.map((error) => Text('• $error')).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
            ) : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialogue de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la copie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              Text('Chargement des charges...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addSortie,
        backgroundColor: Colors.red,
        tooltip: 'Ajouter une charge',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          filteredSorties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 100,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _currentFilter == 'Tous' 
                            ? 'Aucune charge enregistrée'
                            : 'Aucune charge pour cette période',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ajoutez vos charges fixes et variables',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildFinancialHeader(),
                    if (filteredSorties.isNotEmpty)
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
                              label: Text(_isSelectionMode ? 'Annuler' : 'Sélection multiple'),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _addSortie,
                              icon: const Icon(Icons.add),
                              tooltip: 'Ajouter une charge',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSorties.length,
                        itemBuilder: (context, index) {
                          final sortie = filteredSorties[index];
                          final amount = (sortie['amount'] as num?)?.toDouble() ?? 0;
                          final description = sortie['description'] as String? ?? '';
                          final dateStr = sortie['date'] as String? ?? '';
                          final date = DateTime.tryParse(dateStr);
                          final isPointed = sortie['isPointed'] == true;
                          final isSelected = _selectedIndices.contains(index);
                          final pointedAt = sortie['pointedAt'] != null 
                              ? DateTime.tryParse(sortie['pointedAt'] as String)
                              : null;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.blue.shade50 
                                  : (isPointed ? Colors.green.shade50 : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.blue.shade300
                                    : (isPointed ? Colors.green.shade300 : Colors.grey.shade200),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
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
                                          color: isPointed ? Colors.green.shade100 : 
                                                 (sortie['type'] == 'fixe' ? Colors.red.shade100 : Colors.orange.shade100),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isPointed ? Colors.green.shade300 : 
                                                   (sortie['type'] == 'fixe' ? Colors.red.shade300 : Colors.orange.shade300),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          isPointed ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: isPointed ? Colors.green.shade700 : 
                                                 (sortie['type'] == 'fixe' ? Colors.red.shade700 : Colors.orange.shade700),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      description,
                                      style: TextStyle(
                                        fontWeight: sortie['type'] == 'fixe' ? FontWeight.bold : FontWeight.normal,
                                        color: isPointed ? Colors.green.shade700 : null,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${AmountParser.formatAmount(amount)} €',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isPointed ? Colors.green.shade700 : 
                                                 (sortie['type'] == 'fixe' ? Colors.red : Colors.orange),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.lock_open,
                                        size: 12,
                                        color: isPointed ? Colors.green.shade400 : 
                                               (sortie['type'] == 'fixe' ? Colors.red.shade400 : Colors.orange.shade400),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        sortie['type'] == 'fixe' 
                                            ? Icons.repeat 
                                            : Icons.show_chart,
                                        size: 16,
                                        color: isPointed ? Colors.green.shade600 : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        sortie['type'] == 'fixe' 
                                            ? 'Charge fixe mensuelle'
                                            : 'Charge variable',
                                        style: TextStyle(
                                          color: isPointed ? Colors.green.shade600 : Colors.grey,
                                        ),
                                      ),
                                      if (date != null) ...[
                                        const Text(' • '),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(date),
                                          style: TextStyle(
                                            color: isPointed ? Colors.green.shade600 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isPointed && pointedAt != null)
                                    Text(
                                      'Pointée le ${pointedAt.day}/${pointedAt.month} à ${pointedAt.hour}:${pointedAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: Colors.green.shade600,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: !_isSelectionMode
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'toggle':
                                            _togglePointing(index);
                                            break;
                                          case 'edit':
                                            _editSortie(index);
                                            break;
                                          case 'delete':
                                            _deleteSortie(index);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'toggle',
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
                                    )
                                  : null,
                              onTap: _isSelectionMode
                                  ? () => _toggleSelection(index)
                                  : () => _togglePointing(index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          if (_isSelectionMode && _selectedIndices.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedIndices.length} charge${_selectedIndices.length > 1 ? 's' : ''} sélectionnée${_selectedIndices.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_isProcessingBatch)
                        const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      else ...[
                        ElevatedButton.icon(
                          onPressed: _batchTogglePointing,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Pointer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _selectAll,
                          icon: const Icon(Icons.select_all),
                          label: const Text('Tout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}