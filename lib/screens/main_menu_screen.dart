import 'package:flutter/material.dart';
// Import foundation supprimé (pas de logs)
import 'package:firebase_analytics/firebase_analytics.dart';

import '../services/firebase_service.dart';
import '../services/encrypted_budget_service.dart' as encrypted;

import 'month_selector_screen.dart';
import 'auth_wrapper.dart'; // AJOUTER cet import
import 'tags_management_tab.dart';
import 'global_analyse_tab.dart'; // Importer le nouvel onglet GlobalAnalyseTab


class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final FirebaseService _firebaseService = FirebaseService();
  final encrypted.EncryptedBudgetDataService _dataService = encrypted.EncryptedBudgetDataService();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // MODIFIER: Retirer final pour permettre la réassignation
  List<Widget> _mainTabs = [
    const MonthSelectorScreen(), // Premier onglet = Sélection des mois
    const TagsManagementTab(), // Onglet pour la gestion des tags
    const GlobalAnalyseTab(), // Nouvel onglet pour l'analyse globale
  ];

  // SUPPRIMER cette section complètement car elle n'est plus utilisée
  // final List<String> _tabTitles = [
  //   'Sélection Mois',
  // ];

  // Options du menu de navigation - MISE À JOUR
  // SUPPRIMER complètement cette section car le menu n'est plus utilisé
  // List<Map<String, dynamic>> get _menuOptions => [
  //   {
  //     'title': 'Sélection Mois',
  //     'icon': Icons.calendar_month,
  //     'color': Colors.blue,
  //     'index': 0,
  //   },
  //   // Supprimer l'analyse globale et ajouter les analyses mensuelles
  //   {
  //     'title': 'Analyse Janvier',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 1,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Février',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 2,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Mars',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 3,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Avril',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 4,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Mai',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 5,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Juin',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 6,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Juillet',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 7,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Août',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 8,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Septembre',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 9,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Octobre',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 10,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Novembre',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 11,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Analyse Décembre',
  //     'icon': Icons.analytics,
  //     'color': Colors.orange,
  //     'month': 12,
  //     'isMonthlyAnalysis': true,
  //   },
  //   {
  //     'title': 'Catégories',
  //     'icon': Icons.label,
  //     'color': Colors.teal,
  //     'index': 1, // Changer de 2 à 1 car l'onglet analyse n'est plus dans _mainTabs
  //   },
  //   {
  //     'title': 'Projections',
  //     'icon': Icons.trending_up,
  //     'color': Colors.indigo,
  //     'index': 2, // Changer de 3 à 2 car l'onglet analyse n'est plus dans _mainTabs
  //   },
  // ];

  // Destinations de la barre de navigation - MISE À JOUR
  final List<NavigationDestination> _mainDestinations = [
    const NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Mois',
    ),
    const NavigationDestination(
      icon: Icon(Icons.label_outline),
      selectedIcon: Icon(Icons.label),
      label: 'Tags',
    ),
    const NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Analyse',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  _logScreenView();
  }

  Future<void> _initializeServices() async {
    try {
      await _dataService.initialize();
    } catch (e) {
      // Ignoré: échec d'initialisation non critique (pas de log en production)
    }
  }

  Future<void> _logScreenView() async {
    try {
      await _analytics.logScreenView(
        screenName: 'main_menu',
        screenClass: 'MainMenuScreen',
      );
    } catch (e) {
      // Ignoré: échec analytics non critique
    }
  }

  // Suppression du listener auth redondant (AuthWrapper gère déjà les rebuilds)

  void _onItemTapped(int index) {
    if (index < _mainTabs.length) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _trackTabChange(index);
    }
  }

  void _trackTabChange(int index) {
    // SUPPRIMER cette méthode car _menuOptions n'existe plus
    // ou la simplifier pour utiliser les onglets principaux
    
    final tabNames = ['Mois', 'Tags', 'Analyse'];
    final tabName = index < tabNames.length ? tabNames[index] : 'Unknown';
    
    try {
      _analytics.logSelectContent(
        contentType: 'tab',
        itemId: tabName,
      );
    } catch (e) {
      // Ignoré: erreur analytics tab non critique
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget App'),
        // AJOUTER le menu utilisateur
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                color: Colors.blue.shade700,
              ),
            ),
            onSelected: (value) => _handleUserMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _firebaseService.currentUser?.displayName ?? 'Utilisateur',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _firebaseService.currentUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'deleteData',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    const Text(
                      'Supprimer les données',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    const Text('Se déconnecter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _mainTabs,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: _mainDestinations,
      ),
    );
  }

  // AJOUTER cette méthode pour gérer les actions du menu utilisateur
  void _handleUserMenuAction(String action) {
    switch (action) {
      case 'profile':
        // Afficher les informations du profil
        _showUserProfile();
        break;
      case 'deleteData':
        // Supprimer les données
        _deleteAllData();
        break;
      case 'logout':
        // Se déconnecter
        _signOut();
        break;
    }
  }

  void _showUserProfile() {
    final user = _firebaseService.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_circle, color: Colors.blue),
            SizedBox(width: 12),
            Text('Profil utilisateur'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user?.photoURL != null) ...[
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user!.photoURL!),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildProfileInfo('Nom', user?.displayName ?? 'Non défini'),
            const SizedBox(height: 8),
            _buildProfileInfo('Email', user?.email ?? 'Non défini'),
            const SizedBox(height: 8),
            _buildProfileInfo('UID', user?.uid ?? 'Non défini'),
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

  Widget _buildProfileInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  void _deleteAllData() async {
    final ctx = context;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Supprimer toutes les données'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚠️ ATTENTION ⚠️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Cette action va supprimer définitivement TOUTES vos données :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Tous vos revenus'),
            Text('• Toutes vos charges'),
            Text('• Toutes vos dépenses'),
            Text('• Toutes vos catégories'),
            Text('• Tous vos pointages'),
            SizedBox(height: 16),
            Text(
              'Cette action est IRRÉVERSIBLE !',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
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
            child: const Text('SUPPRIMER TOUT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Capturer context et navigator avant les awaits
        final messenger = ScaffoldMessenger.of(ctx);
        final navContext = ctx;
        
        // Afficher le dialogue de chargement
        if (!mounted) return;
        showDialog(
          context: navContext,
          barrierDismissible: false,
          builder: (loadingCtx) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('🗑️ Suppression des données...'),
                ],
              ),
            ),
        );

        await _dataService.deleteAllUserData();

        if (!mounted) return;
        Navigator.pop(navContext); // Fermer le dialogue de chargement
        await _refreshAllTabs();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Toutes les données ont été supprimées et actualisées'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(ctx);
        Navigator.pop(ctx); // Fermer le dialogue de chargement si ouvert
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // MODIFIER: Actualiser la méthode _refreshAllTabs
  Future<void> _refreshAllTabs() async {
    try {
      // Forcer la reconstruction de tous les onglets
      setState(() {
        _mainTabs = [
          const MonthSelectorScreen(), // Onglet sélection de mois
          const TagsManagementTab(),   // Onglet gestion des tags
          const GlobalAnalyseTab(),    // Onglet analyse globale
        ];
      });

      // Optionnel: revenir au premier onglet
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _selectedIndex = 0;
        });
      }

    } catch (e) {
      // Ignoré: échec actualisation onglets non critique
    }
  }

  void _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 12),
            Text('Se déconnecter'),
          ],
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Afficher un indicateur de déconnexion
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
                  Text('🔓 Déconnexion en cours...'),
                ],
              ),
            ),
          );
        }

  await _firebaseService.signOut();
  if (!mounted) return; // Sécurité: ne pas utiliser context si démonté
        
        // La navigation sera gérée automatiquement par AuthWrapper
        // Mais on peut forcer le retour à la racine pour être sûr
        if (!mounted) return; // Vérification supplémentaire
        Navigator.of(context).popUntil((route) => route.isFirst);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AuthWrapper()),
        );
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Fermer le dialogue de chargement
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur de déconnexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
