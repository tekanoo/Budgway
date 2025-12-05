import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // AJOUT
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // nécessaire pour kIsWeb uniquement
import 'data_update_bus.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance; // AJOUT
  
  // GoogleSignIn initialisé directement
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '570468917791-5op36av9boj6q6qcb3nmlf5a3bk0k7ub.apps.googleusercontent.com' : null,
  );

  // Stream pour écouter les changements d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;
  
  // Vérifier si connecté
  bool get isSignedIn => currentUser != null;

  /// AUTHENTIFICATION
  
  // Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
  // Log supprimé

      // Déclencher le flow d'authentification
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
  if (googleUser == null) {
        return null;
      }

  // Log supprimé

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer les credentials
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

  // Log supprimé

      // Se connecter à Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
  // Log supprimé

      // AJOUT: Tracker l'événement de connexion
      await _analytics.logLogin(loginMethod: 'google');
      await _analytics.setUserId(id: userCredential.user?.uid);
      await _analytics.setUserProperty(name: 'login_method', value: 'google');

      // Créer/mettre à jour le profil utilisateur
      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!);
      }
      
      return userCredential;
      
  } catch (e) {
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      // AJOUT: Tracker la déconnexion
      await _analytics.logEvent(name: 'user_logout');
      
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  // Créer le profil utilisateur dans Firestore
  Future<void> _createUserProfile(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
  // Log supprimé
      } else {
        // Mettre à jour la dernière connexion
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
  // Log supprimé
      }
  } catch (e) {
      // Ne pas faire échouer la connexion pour une erreur de profil
    }
  }

  /// DONNÉES BUDGET
  
  // Collection de référence pour l'utilisateur actuel
  CollectionReference? get _userBudgetCollection {
    if (!isSignedIn) return null;
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('budget');
  }

  // Sauvegarder les entrées
  Future<void> saveEntrees(List<Map<String, dynamic>> entrees) async {
    if (!isSignedIn) throw Exception('Utilisateur non connecté');
    
    try {
      await _userBudgetCollection!.doc('entrees').set({
        'data': entrees,
        'updatedAt': FieldValue.serverTimestamp(),
      });
  DataUpdateBus.emit('entrees');
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  // Charger les entrées
  Future<List<Map<String, dynamic>>> loadEntrees() async {
    if (!isSignedIn) return [];
    
    try {
      final doc = await _userBudgetCollection!.doc('entrees').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
  } catch (e) {
      return [];
    }
  }

  // Sauvegarder les sorties
  Future<void> saveSorties(List<Map<String, dynamic>> sorties) async {
    if (!isSignedIn) throw Exception('Utilisateur non connecté');
    
    try {
      await _userBudgetCollection!.doc('sorties').set({
        'data': sorties,
        'updatedAt': FieldValue.serverTimestamp(),
      });
  DataUpdateBus.emit('sorties');
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  // Charger les sorties
  Future<List<Map<String, dynamic>>> loadSorties() async {
    if (!isSignedIn) return [];
    
    try {
      final doc = await _userBudgetCollection!.doc('sorties').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
  } catch (e) {
      return [];
    }
  }

  // Sauvegarder les plaisirs
  Future<void> savePlaisirs(List<Map<String, dynamic>> plaisirs) async {
    if (!isSignedIn) throw Exception('Utilisateur non connecté');
    
    try {
      await _userBudgetCollection!.doc('plaisirs').set({
        'data': plaisirs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
  DataUpdateBus.emit('plaisirs');
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  // Charger les plaisirs
  Future<List<Map<String, dynamic>>> loadPlaisirs() async {
    if (!isSignedIn) return [];
    
    try {
      final doc = await _userBudgetCollection!.doc('plaisirs').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
  } catch (e) {
      return [];
    }
  }

  // Sauvegarder le solde bancaire
  Future<void> saveBankBalance(double balance) async {
    if (!isSignedIn) throw Exception('Utilisateur non connecté');
    
    try {
      await _userBudgetCollection!.doc('settings').set({
        'bankBalance': balance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  DataUpdateBus.emit('settings');
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  // Charger le solde bancaire
  Future<double> loadBankBalance() async {
    if (!isSignedIn) return 0.0;
    
    try {
      final doc = await _userBudgetCollection!.doc('settings').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['bankBalance'] ?? 0.0).toDouble();
      }
      return 0.0;
  } catch (e) {
      return 0.0;
    }
  }

  // Sauvegarder les tags
  Future<void> saveTags(List<String> tags) async {
    if (!isSignedIn) throw Exception('Utilisateur non connecté');
    
    try {
      await _userBudgetCollection!.doc('settings').set({
        'availableTags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  DataUpdateBus.emit('tags');
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  // Charger les tags
  Future<List<String>> loadTags() async {
    if (!isSignedIn) return [];
    
    try {
      final doc = await _userBudgetCollection!.doc('settings').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['availableTags'] ?? []);
      }
      return [];
  } catch (e) {
      return [];
    }
  }

  // Stream pour écouter les changements de données en temps réel
  Stream<DocumentSnapshot> watchBudgetData(String docType) {
    if (!isSignedIn) {
      return const Stream.empty();
    }
    return _userBudgetCollection!.doc(docType).snapshots();
  }

  /// SUPPRESSION COMPLÈTE DES DONNÉES
  Future<void> deleteAllUserData() async {
    if (!isSignedIn) throw Exception('Utilisateur non connecté');
    
    try {
      final batch = _firestore.batch();
      final userBudgetRef = _userBudgetCollection!;
      
      // Liste des documents à supprimer
      final docsToDelete = ['entrees', 'sorties', 'plaisirs', 'settings'];
      
      for (String docName in docsToDelete) {
        batch.delete(userBudgetRef.doc(docName));
      }
      
      // Exécuter la suppression en lot
      await batch.commit();
      
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  /// Supprimer toutes les données de l'utilisateur connecté
  Future<void> deleteUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Supprimer tous les documents de la collection budget
      final budgetCollection = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget');

      // Supprimer tous les documents de la sous-collection budget
      final docs = await budgetCollection.get();
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }

      // Supprimer le document principal de l'utilisateur (optionnel)
      // await _firestore.collection('users').doc(user.uid).delete();
      
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }
}