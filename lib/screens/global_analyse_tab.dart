import 'package:flutter/material.dart';
import '../services/encrypted_budget_service.dart';
import 'budget_simulator_tab.dart';

/// Onglet d'analyse globale remplaçant les projections.
/// Affiche :
/// Version simplifiée :
/// - Total dépenses nettes (dépenses normales - virements/remboursements)
/// - Moyenne mensuelle des dépenses sur les mois actifs (mois contenant au moins un revenu, charge ou dépense)
class GlobalAnalyseTab extends StatefulWidget {
  const GlobalAnalyseTab({super.key});

  @override
  State<GlobalAnalyseTab> createState() => _GlobalAnalyseTabState();
}

class _GlobalAnalyseTabState extends State<GlobalAnalyseTab> with TickerProviderStateMixin {
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  bool _loading = true;
  
  late TabController _tabController;

  double _totalDepenses = 0; // incluant virements
  double _avgDepenses = 0;   // moyenne sur mois actifs
  int _activeMonths = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entrees = await _dataService.getEntrees();
      final sorties = await _dataService.getSorties();
      final plaisirs = await _dataService.getPlaisirs();

      if (entrees.isEmpty && sorties.isEmpty && plaisirs.isEmpty) {
        setState(() { _loading = false; });
        return;
      }
      // Agréger par (année, mois) pour identifier les mois actifs
      final Set<String> activeMonthKeys = {};
      double totalDepenses = 0;

      void markActive(String? dateStr) {
        final d = DateTime.tryParse(dateStr ?? '');
        if (d != null) {
          activeMonthKeys.add('${d.year}-${d.month}');
        }
      }

      for (final e in entrees) { markActive(e['date']); }
      for (final s in sorties) { markActive(s['date']); }
      for (final p in plaisirs) {
        markActive(p['date']);
        final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        // Calculer les dépenses comme dans l'onglet dépenses (virements soustraits)
        if (p['isCredit'] == true) {
          totalDepenses -= amount; // Les virements réduisent le total
        } else {
          totalDepenses += amount; // Les dépenses normales augmentent le total
        }
      }

      final activeMonths = activeMonthKeys.length;
  final avgDepenses = activeMonths > 0 ? totalDepenses / activeMonths : 0.0;

      setState(() {
        _totalDepenses = totalDepenses;
        _avgDepenses = avgDepenses;
        _activeMonths = activeMonths;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement analyse: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _loading = false);
    }
  }

  String _fmt(double v, {int decimals = 2}) => v.toStringAsFixed(decimals).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Analyse Dépenses'),
              Tab(text: 'Simulateur Budget'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAnalyseTab(),
              const BudgetSimulatorTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyseTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Dans la version simplifiée, on ne calcule que les dépenses
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analyse Dépenses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Total dépenses: ${_fmt(_totalDepenses)} €', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Mois actifs: $_activeMonths', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Moyenne mensuelle: ${_fmt(_avgDepenses)} €', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
