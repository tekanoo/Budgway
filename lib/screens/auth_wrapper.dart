import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
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
          return const MainMenuScreen();
        }
        
        // Si pas connecté ou déconnecté
        return const LoginScreen();
      },
    );
  }
}