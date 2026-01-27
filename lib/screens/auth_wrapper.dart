import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/encryption_service.dart';
import 'login_screen.dart';
import 'main_menu_screen.dart';

class AuthWrapper extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firebaseService.authStateChanges,
      builder: (context, snapshot) {
        // Si en cours de connexion
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('🔐 Vérification de l\'authentification...'),
                ],
              ),
            ),
          );
        }
        
        // Si utilisateur connecté
        if (snapshot.hasData && snapshot.data != null) {
          // Initialise le chiffrement et lance la migration de sécurité
          return _SecurityMigrationWrapper(
            userId: snapshot.data!.uid,
            child: const MainMenuScreen(),
          );
        }
        
        // Si pas connecté ou déconnecté
        return const LoginScreen();
      },
    );
  }
}

/// Widget qui gère l'initialisation du chiffrement et la migration de sécurité
class _SecurityMigrationWrapper extends StatefulWidget {
  final String userId;
  final Widget child;

  const _SecurityMigrationWrapper({
    required this.userId,
    required this.child,
  });

  @override
  State<_SecurityMigrationWrapper> createState() => _SecurityMigrationWrapperState();
}

class _SecurityMigrationWrapperState extends State<_SecurityMigrationWrapper> {
  bool _isInitialized = false;
  bool _isMigrating = false;
  final FirebaseService _firebaseService = FirebaseService();
  final FinancialDataEncryption _encryption = FinancialDataEncryption();

  @override
  void initState() {
    super.initState();
    _initializeAndMigrate();
  }

  Future<void> _initializeAndMigrate() async {
    // Initialise le service de chiffrement pour l'utilisateur
    _encryption.initializeForUser(widget.userId);
    
    // Vérifie et lance la migration si nécessaire
    setState(() => _isMigrating = true);
    
    try {
      await _firebaseService.migrateUserSecurity();
    } catch (e) {
      // Migration échouée mais on continue quand même
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _isMigrating 
                    ? '🔒 Mise à jour de sécurité en cours...'
                    : '🔐 Initialisation...',
              ),
            ],
          ),
        ),
      );
    }
    
    return widget.child;
  }
}