// lib/screens/monthly_analyse_tab.dart - Version corrigée

import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart'; // SUPPRIMER CETTE LIGNE
import '../services/encrypted_budget_service.dart';

class MonthlyAnalyseTab extends StatefulWidget {
  final DateTime selectedMonth;
  
  const MonthlyAnalyseTab({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<MonthlyAnalyseTab> createState() => _MonthlyAnalyseTabState();
}

class _MonthlyAnalyseTabState extends State<MonthlyAnalyseTab> {
  final EncryptedBudgetDataService _dataService = EncryptedBudgetDataService();
  double totalEntrees = 0;
  double totalSorties = 0;
  double totalPlaisirs = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final entrees = await _dataService.getEntrees();
      final sorties = await _dataService.getSorties();
      final plaisirs = await _dataService.getPlaisirs();
      
      // Filtrer par mois sélectionné
      final monthlyEntrees = entrees.where((e) {
        final date = DateTime.tryParse(e['date'] ?? '');
        return date != null && 
               date.year == widget.selectedMonth.year &&
               date.month == widget.selectedMonth.month;
      }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));
      
      final monthlySorties = sorties.where((s) {
        final date = DateTime.tryParse(s['date'] ?? '');
        return date != null && 
               date.year == widget.selectedMonth.year &&
               date.month == widget.selectedMonth.month;
      }).fold(0.0, (sum, s) => sum + ((s['amount'] as num?)?.toDouble() ?? 0.0));
      
      // CORRECTION : Séparer les virements des dépenses pour le mois
      double monthlyPlaisirs = 0.0;
      double monthlyVirements = 0.0;
      
      for (var plaisir in plaisirs) {
        final date = DateTime.tryParse(plaisir['date'] ?? '');
        if (date != null && 
            date.year == widget.selectedMonth.year &&
            date.month == widget.selectedMonth.month) {
          final amount = (plaisir['amount'] as num?)?.toDouble() ?? 0.0;
          if (plaisir['isCredit'] == true) {
            monthlyVirements += amount; // Les virements vont aux revenus
          } else {
            monthlyPlaisirs += amount; // Les dépenses restent en dépenses
          }
        }
      }
      
      setState(() {
        totalEntrees = monthlyEntrees + monthlyVirements; // Ajouter les virements aux revenus
        totalSorties = monthlySorties;
        totalPlaisirs = monthlyPlaisirs; // Seulement les vraies dépenses
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getMonthName(DateTime date) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('🔓 Analyse du mois en cours...'),
          ],
        ),
      );
    }

    final difference = totalEntrees - totalSorties - totalPlaisirs;
    final monthName = _getMonthName(widget.selectedMonth);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 100, 16, 16),
      child: Column(
        children: [
          // En-tête avec mois sélectionné
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyse de $monthName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Données mensuelles sécurisées',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Carte de résumé mensuel
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Résumé de $monthName',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Revenus',
                        totalEntrees,
                        Colors.green,
                        Icons.trending_up,
                      ),
                      _buildSummaryItem(
                        'Charges',
                        totalSorties,
                        Colors.red,
                        Icons.receipt_long,
                      ),
                      _buildSummaryItem(
                        'Dépenses',
                        totalPlaisirs,
                        Colors.purple,
                        Icons.shopping_cart,
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildSummaryItem(
                    'Solde',
                    difference,
                    difference >= 0 ? Colors.green : Colors.red,
                    difference >= 0 ? Icons.trending_up : Icons.trending_down,
                    isLarge: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // NOUVEAU : Carte des ratios financiers avec méthode corrigée
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Indicateurs financiers',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  ..._buildFinancialRatios(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Affichage des données ou message si vide
          if (totalEntrees > 0 || totalSorties > 0 || totalPlaisirs > 0) ...[
            // NOUVEAU : Évaluation globale de la santé financière
            _buildOverallAssessment(),
          ] else ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune donnée pour $monthName',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez des revenus, charges ou dépenses pour voir l\'analyse',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, IconData icon, {bool isLarge = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: isLarge ? 32 : 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(2)} €',
          style: TextStyle(
            fontSize: isLarge ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFinancialRatios() {
    if (totalEntrees <= 0) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Aucun revenu pour ce mois - Impossible de calculer les ratios',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Calcul des ratios
    final chargesRatio = (totalSorties / totalEntrees) * 100;
    final depensesRatio = (totalPlaisirs.abs() / totalEntrees) * 100;
    final epargneRatio = ((totalEntrees - totalSorties - totalPlaisirs.abs()) / totalEntrees) * 100;
    
    return [
      _buildRatioItem(
        'Ratio Charges/Revenus',
        chargesRatio,
        '${chargesRatio.toStringAsFixed(1)}%',
        _evaluateChargesRatio(chargesRatio),
        Icons.receipt_long,
        Colors.red,
      ),
      const SizedBox(height: 16),
      _buildRatioItem(
        'Ratio Dépenses/Revenus',
        depensesRatio,
        '${depensesRatio.toStringAsFixed(1)}%',
        _evaluateDepensesRatio(depensesRatio),
        Icons.shopping_cart,
        Colors.purple,
      ),
      const SizedBox(height: 16),
      _buildRatioItem(
        'Capacité d\'épargne',
        epargneRatio,
        '${epargneRatio.toStringAsFixed(1)}%',
        _evaluateEpargneRatio(epargneRatio),
        Icons.savings,
        epargneRatio >= 0 ? Colors.green : Colors.red,
      ),
    ];
  }

  Widget _buildRatioItem(
    String label,
    double ratio,
    String percentage,
    Map<String, dynamic> evaluation,
    IconData icon,
    Color baseColor,
  ) {
    final Color statusColor = evaluation['color'] as Color;
    final String status = evaluation['status'] as String;
    final String advice = evaluation['advice'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: baseColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      percentage,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: baseColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      evaluation['icon'] as IconData,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            advice,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _evaluateChargesRatio(double ratio) {
    if (ratio <= 50) {
      return {
        'status': 'Excellent',
        'color': Colors.green,
        'icon': Icons.check_circle,
        'advice': 'Vos charges fixes sont très bien maîtrisées. Idéal pour l\'épargne !',
      };
    } else if (ratio <= 65) {
      return {
        'status': 'Bon',
        'color': Colors.lightGreen,
        'icon': Icons.thumb_up,
        'advice': 'Charges fixes correctes, mais surveillez les augmentations.',
      };
    } else if (ratio <= 80) {
      return {
        'status': 'Attention',
        'color': Colors.orange,
        'icon': Icons.warning,
        'advice': 'Charges élevées. Essayez de réduire certains abonnements.',
      };
    } else {
      return {
        'status': 'Critique',
        'color': Colors.red,
        'icon': Icons.error,
        'advice': 'Charges trop importantes ! Révisez vos contrats et abonnements.',
      };
    }
  }

  Map<String, dynamic> _evaluateDepensesRatio(double ratio) {
    if (ratio <= 20) {
      return {
        'status': 'Excellent',
        'color': Colors.green,
        'icon': Icons.check_circle,
        'advice': 'Dépenses très raisonnables. Vous gérez parfaitement votre budget !',
      };
    } else if (ratio <= 35) {
      return {
        'status': 'Bon',
        'color': Colors.lightGreen,
        'icon': Icons.thumb_up,
        'advice': 'Dépenses modérées. Continuez sur cette voie.',
      };
    } else if (ratio <= 50) {
      return {
        'status': 'Moyen',
        'color': Colors.orange,
        'icon': Icons.remove_circle,
        'advice': 'Dépenses un peu élevées. Réfléchissez avant chaque achat.',
      };
    } else {
      return {
        'status': 'Excessif',
        'color': Colors.red,
        'icon': Icons.error,
        'advice': 'Dépenses trop importantes ! Établissez un budget strict.',
      };
    }
  }

  Map<String, dynamic> _evaluateEpargneRatio(double ratio) {
    if (ratio >= 20) {
      return {
        'status': 'Excellent',
        'color': Colors.green,
        'icon': Icons.trending_up,
        'advice': 'Excellente capacité d\'épargne ! Vos finances sont saines.',
      };
    } else if (ratio >= 10) {
      return {
        'status': 'Bon',
        'color': Colors.lightGreen,
        'icon': Icons.savings,
        'advice': 'Bonne épargne. Essayez d\'augmenter progressivement.',
      };
    } else if (ratio >= 0) {
      return {
        'status': 'Fragile',
        'color': Colors.orange,
        'icon': Icons.warning,
        'advice': 'Peu d\'épargne. Réduisez vos dépenses non essentielles.',
      };
    } else {
      return {
        'status': 'Déficit',
        'color': Colors.red,
        'icon': Icons.trending_down,
        'advice': 'Situation critique ! Vous dépensez plus que vos revenus.',
      };
    }
  }

  Widget _buildOverallAssessment() {
    final chargesRatio = (totalSorties / totalEntrees) * 100;
    final depensesRatio = (totalPlaisirs.abs() / totalEntrees) * 100;
    final epargneRatio = ((totalEntrees - totalSorties - totalPlaisirs.abs()) / totalEntrees) * 100;
    
    // Score global (sur 100)
    int score = 0;
    
    // Score charges (30 points max)
    if (chargesRatio <= 50) {
      score += 30;
    } else if (chargesRatio <= 65) {
      score += 20;
    } else if (chargesRatio <= 80) {
      score += 10;
    }
    
    // Score dépenses (35 points max)
    if (depensesRatio <= 20) {
      score += 35;
    } else if (depensesRatio <= 35) {
      score += 25;
    } else if (depensesRatio <= 50) {
      score += 15;
    }
    
    // Score épargne (35 points max)
    if (epargneRatio >= 20) {
      score += 35;
    } else if (epargneRatio >= 10) {
      score += 25;
    } else if (epargneRatio >= 0) {
      score += 10;
    }
    
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;
    String globalAdvice;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.star;
      globalAdvice = 'Félicitations ! Votre gestion financière est exemplaire.';
    } else if (score >= 60) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'Bon';
      scoreIcon = Icons.thumb_up;
      globalAdvice = 'Bonne gestion globale. Quelques améliorations possibles.';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Moyen';
      scoreIcon = Icons.warning;
      globalAdvice = 'Gestion correcte mais des efforts sont nécessaires.';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Critique';
      scoreIcon = Icons.error;
      globalAdvice = 'Situation préoccupante. Révisez urgemment votre budget.'; // Correction : "urgemment" au lieu de "urgently"
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.1), scoreColor.withValues(alpha: 0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scoreColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  scoreIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score de santé financière',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$score/100',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            scoreLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            globalAdvice,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}