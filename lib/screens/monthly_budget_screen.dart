import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'plaisirs_tab.dart';
import 'entrees_tab.dart';
import 'sorties_tab.dart';
import 'monthly_analyse_tab.dart'; // AJOUTER cet import

class MonthlyBudgetScreen extends StatefulWidget {
  final DateTime selectedMonth;
  
  const MonthlyBudgetScreen({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  
  late List<Widget> _tabs;
  
  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeTab(selectedMonth: widget.selectedMonth),
      PlaisirsTab(selectedMonth: widget.selectedMonth),
      EntreesTab(selectedMonth: widget.selectedMonth),
      SortiesTab(selectedMonth: widget.selectedMonth),
      MonthlyAnalyseTab(selectedMonth: widget.selectedMonth), // AJOUTER l'onglet analyse
    ];
  }
  
  // Méthode pour obtenir le nom du mois en français
  String _getMonthName(DateTime date) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    final monthName = _getMonthName(widget.selectedMonth);
    final tabTitles = ['Dashboard', 'Dépenses', 'Revenus', 'Charges', 'Analyse']; // AJOUTER 'Analyse'
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(tabTitles[_selectedIndex]),
            Text(
              monthName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Dépenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Revenus',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Charges',
          ),
          // AJOUTER la destination Analyse
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analyse',
          ),
        ],
      ),
    );
  }
}