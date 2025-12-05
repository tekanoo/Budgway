import 'package:budget_app/screens/auth_wrapper.dart'; // CHANGEMENT: Importer AuthWrapper au lieu de MainMenuScreen
import 'package:flutter/material.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleStartApp(BuildContext context) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Redirection...'),
            ],
          ),
        ),
      );
      
      // Petit délai pour l'UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Vérifier si le widget est monté
      if (!context.mounted) return;
      
      // Fermer le dialogue de chargement
      Navigator.of(context).pop();
      
      // CORRECTION: Rediriger vers AuthWrapper au lieu de MainMenuScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AuthWrapper()),
      );
      
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Fermer le dialogue de chargement
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('À propos de l\'app'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion Budget Pro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 12),
            Text('Fonctionnalités :'),
            Text('• Suivi des revenus et dépenses'),
            Text('• Objectifs de plaisirs'),
            Text('• Analyses détaillées'),
            Text('• Stockage local sécurisé'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(204), // 0.8 * 255
              Theme.of(context).colorScheme.primary.withAlpha(153), // 0.6 * 255
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51), // 0.2 * 255
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Titre et sous-titre
                  Text(
                    'Gestion Budget Pro',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Gérez vos finances en toute simplicité',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withAlpha(230), // 0.9 * 255
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  
                  // Bouton de démarrage
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleStartApp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Commencer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Bouton d'information
                  TextButton.icon(
                    onPressed: () => _showAppInfo(context),
                    icon: Icon(
                      Icons.info_outline,
                      color: Colors.white.withAlpha(204), // 0.8 * 255
                    ),
                    label: Text(
                      'À propos de l\'application',
                      style: TextStyle(
                        color: Colors.white.withAlpha(204), // 0.8 * 255
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}