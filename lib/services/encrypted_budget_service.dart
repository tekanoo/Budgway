import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'encryption_service.dart';
import 'data_update_bus.dart';

class EncryptedBudgetDataService {
  static final EncryptedBudgetDataService _instance = EncryptedBudgetDataService._internal();
  factory EncryptedBudgetDataService() => _instance;
  EncryptedBudgetDataService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FinancialDataEncryption _encryption = FinancialDataEncryption();
  
  bool _isInitialized = false;

  /// Initialise le service avec l'utilisateur connecté
  Future<void> initialize() async {
    if (_firebaseService.currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    // Initialise le chiffrement pour cet utilisateur
    _encryption.initializeForUser(_firebaseService.currentUser!.uid);
    _isInitialized = true;
    
    if (kDebugMode) {
      print('🔐 Service de budget chiffré initialisé');
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Service non initialisé');
    }
    // AJOUTER cette vérification
    if (!_firebaseService.isSignedIn) {
      throw Exception('Utilisateur non connecté - Accès refusé');
    }
  }

  /// Collection de référence pour l'utilisateur actuel
  CollectionReference? get _userBudgetCollection {
    if (!_firebaseService.isSignedIn) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_firebaseService.currentUser!.uid)
        .collection('budget');
  }

  /// SYSTÈME DE POINTAGE DES DÉPENSES

  /// Bascule le statut de pointage d'une dépense
Future<void> togglePlaisirPointing(int index) async {
  _ensureInitialized();
  try {
    final plaisirs = await _firebaseService.loadPlaisirs();
    if (index >= 0 && index < plaisirs.length) {
      // Déchiffrer d'abord la transaction pour la modifier
      final decryptedPlaisir = _encryption.decryptTransaction(plaisirs[index]);
      
      final bool currentlyPointed = decryptedPlaisir['isPointed'] == true;
      
      // Bascule le statut
      decryptedPlaisir['isPointed'] = !currentlyPointed;
      
      if (!currentlyPointed) {
        // Si on pointe, on ajoute la date
        decryptedPlaisir['pointedAt'] = DateTime.now().toIso8601String();
      } else {
        // Si on dépointe, on supprime la date
        decryptedPlaisir.remove('pointedAt');
      }
      
      // Rechiffrer la transaction modifiée
      plaisirs[index] = _encryption.encryptTransaction(decryptedPlaisir);
      
      // Sauvegarder
      await _firebaseService.savePlaisirs(plaisirs);
  DataUpdateBus.emit('plaisirs');
      
      if (kDebugMode) {
        print('✅ Dépense ${currentlyPointed ? 'dépointée' : 'pointée'}');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Erreur basculement pointage: $e');
    }
    rethrow;
  }
}

  /// Calcule le total des dépenses pointées
  Future<double> getTotalPlaisirsTotaux() async {
    try {
      final plaisirs = await getPlaisirs();
      double total = 0.0;
      
      for (var plaisir in plaisirs) {
        if (plaisir['isPointed'] == true) {
          final amount = (plaisir['amount'] as num?)?.toDouble() ?? 0.0;
          if (plaisir['isCredit'] == true) {
            // CORRECTION : Les virements/remboursements pointés RÉDUISENT le total des "dépenses"
            // (car ils sont en fait des revenus qui viennent en déduction)
            total -= amount;
          } else {
            // Les dépenses pointées augmentent le total
            total += amount;
          }
        }
      }
      
      return total;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur calcul total pointé: $e');
      }
      return 0.0;
    }
  }

  /// Calcule le total des sorties pointées
  Future<double> getTotalSortiesTotaux() async {
    try {
      final sorties = await getSorties();
      double total = 0.0;
      
      for (var sortie in sorties) {
        if (sortie['isPointed'] == true) {
          total += (sortie['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      return total;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur calcul total sorties pointées: $e');
      }
      return 0.0;
    }
  }

  /// Calcule le solde débité (revenus - charges pointées - dépenses pointées)
  Future<double> getSoldeDisponible() async {
    try {
      final entrees = await getEntrees();
      final sorties = await getSorties();
      final plaisirs = await getPlaisirs();
      
      // Calcul du total des revenus POINTÉS seulement
      double totalRevenusPointes = 0.0;
      for (var entree in entrees) {
        if (entree['isPointed'] == true) {
          totalRevenusPointes += (entree['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      // Calcul du total des charges pointées
      double totalChargesPointees = 0.0;
      for (var sortie in sorties) {
        if (sortie['isPointed'] == true) {
          totalChargesPointees += (sortie['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      // CORRECTION : Séparer les virements des dépenses pointées
      double totalDepensesPointees = 0.0;
      double totalVirementsPointes = 0.0;
      
      for (var plaisir in plaisirs) {
        if (plaisir['isPointed'] == true) {
          final amount = (plaisir['amount'] as num?)?.toDouble() ?? 0.0;
          if (plaisir['isCredit'] == true) {
            // Les virements/remboursements pointés AJOUTENT au solde
            totalVirementsPointes += amount;
          } else {
            // Les dépenses normales pointées DIMINUENT le solde
            totalDepensesPointees += amount;
          }
        }
      }
      
      // Formule corrigée : Revenus pointés + Virements pointés - Charges pointées - Dépenses pointées
      final result = totalRevenusPointes + totalVirementsPointes - totalChargesPointees - totalDepensesPointees;
      
      if (kDebugMode) {
        print('🔍 CALCUL SOLDE DÉBITÉ (CORRIGÉ):');
        print('  - Revenus pointés: $totalRevenusPointes €');
        print('  - Virements pointés: $totalVirementsPointes €');
        print('  - Charges pointées: $totalChargesPointees €');
        print('  - Dépenses pointées: $totalDepensesPointees €');
        print('  - FORMULE: $totalRevenusPointes + $totalVirementsPointes - $totalChargesPointees - $totalDepensesPointees = $result €');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur calcul solde débité: $e');
      }
      return 0.0;
    }
  }

  /// GESTION DES ENTRÉES (REVENUS) CHIFFRÉES

  Future<List<Map<String, dynamic>>> getEntrees() async {
    _ensureInitialized();
    try {
      final encryptedData = await _firebaseService.loadEntrees();
      
      // Déchiffre chaque entrée
      final List<Map<String, dynamic>> decryptedEntrees = [];
      for (var entry in encryptedData) {
        decryptedEntrees.add(_encryption.decryptTransaction(entry));
      }
      
      return decryptedEntrees;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement entrées chiffrées: $e');
      }
      return [];
    }
  }

  /// SYSTÈME DE POINTAGE DES REVENUS
  
  /// Bascule le statut de pointage d'un revenu
  Future<void> toggleEntreePointing(int index) async {
    _ensureInitialized();
    try {
      final entrees = await _firebaseService.loadEntrees();
      if (index >= 0 && index < entrees.length) {
        // Déchiffrer d'abord la transaction pour la modifier
        final decryptedEntree = _encryption.decryptTransaction(entrees[index]);
        
        final bool currentlyPointed = decryptedEntree['isPointed'] == true;
        
        // Bascule le statut
        decryptedEntree['isPointed'] = !currentlyPointed;
        
        if (!currentlyPointed) {
          // Si on pointe, on ajoute la date
          decryptedEntree['pointedAt'] = DateTime.now().toIso8601String();
        } else {
          // Si on dépointe, on supprime la date
          decryptedEntree.remove('pointedAt');
        }
        
        // Rechiffrer la transaction modifiée
        entrees[index] = _encryption.encryptTransaction(decryptedEntree);
        
        // Sauvegarder
        await _firebaseService.saveEntrees(entrees);
        
        if (kDebugMode) {
          print('✅ Revenu ${currentlyPointed ? 'dépointé' : 'pointé'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur basculement pointage revenu: $e');
      }
      rethrow;
    }
  }

  /// Calcule le total des revenus pointés
  Future<double> getTotalEntreesTotaux() async {
    try {
      final entrees = await getEntrees();
      double total = 0.0;
      
      for (var entree in entrees) {
        if (entree['isPointed'] == true) {
          total += (entree['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      return total;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur calcul total revenus pointés: $e');
      }
      return 0.0;
    }
  }

  Future<void> addEntree({
    required String amountStr,
    required String description,
    DateTime? date,
  }) async {
    _ensureInitialized();
    try {
      final entrees = await _firebaseService.loadEntrees();
      
      final double amount = AmountParser.parseAmount(amountStr);
      final newEntree = {
        'amount': amount,
        'description': description,
        'date': (date ?? DateTime.now()).toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isPointed': false, // Par défaut, non pointé
      };
      
      final encryptedEntree = _encryption.encryptTransaction(newEntree);
      entrees.add(encryptedEntree);
      
      await _firebaseService.saveEntrees(entrees);
  DataUpdateBus.emit('entrees');
      
      if (kDebugMode) {
        print('✅ Entrée chiffrée ajoutée: [MONTANT_CHIFFRÉ] - $description');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout entrée chiffrée: $e');
      }
      rethrow;
    }
  }

  Future<void> updateEntree({
    required int index,
    required String amountStr,
    required String description,
    DateTime? date,
  }) async {
    _ensureInitialized();
    try {
      final entrees = await _firebaseService.loadEntrees();
      if (index >= 0 && index < entrees.length) {
        final oldEntree = _encryption.decryptTransaction(entrees[index]);
        
        final double amount = AmountParser.parseAmount(amountStr);
        final updatedEntree = {
          'amount': amount,
          'description': description,
          'date': (date ?? DateTime.tryParse(oldEntree['date'] ?? '') ?? DateTime.now()).toIso8601String(),
          'timestamp': oldEntree['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          'id': oldEntree['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'isPointed': oldEntree['isPointed'] ?? false, // Conserver le statut de pointage
          'pointedAt': oldEntree['pointedAt'], // Conserver la date de pointage si elle existe
        };
        
        entrees[index] = _encryption.encryptTransaction(updatedEntree);
        await _firebaseService.saveEntrees(entrees);
    DataUpdateBus.emit('entrees');
        
        if (kDebugMode) {
          print('✅ Entrée mise à jour');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour entrée: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteEntree(int index) async {
    _ensureInitialized();
    try {
      final entrees = await _firebaseService.loadEntrees();
      if (index >= 0 && index < entrees.length) {
        entrees.removeAt(index);
        await _firebaseService.saveEntrees(entrees);
    DataUpdateBus.emit('entrees');
        
        if (kDebugMode) {
          print('✅ Entrée chiffrée supprimée');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression entrée chiffrée: $e');
      }
      rethrow;
    }
  }

  /// GESTION DES SORTIES (CHARGES) CHIFFRÉES

  Future<List<Map<String, dynamic>>> getSorties() async {
    _ensureInitialized();
    try {
      final encryptedData = await _firebaseService.loadSorties();
      
      // Déchiffre chaque sortie
      final List<Map<String, dynamic>> decryptedSorties = [];
      for (var entry in encryptedData) {
        decryptedSorties.add(_encryption.decryptTransaction(entry));
      }
      
      return decryptedSorties;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement sorties chiffrées: $e');
      }
      return [];
    }
  }

  Future<void> addSortie({
    required String amountStr,
    required String description,
    DateTime? date,
    // Suppression du paramètre periodicity
  }) async {
    _ensureInitialized();
    try {
      final sorties = await _firebaseService.loadSorties();
      
      final double amount = AmountParser.parseAmount(amountStr);
      final newSortie = {
        'amount': amount,
        'description': description,
        'date': (date ?? DateTime.now()).toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isPointed': false,
        // Suppression de 'periodicity': periodicity ?? 'ponctuel',
      };
      
      final encryptedSortie = _encryption.encryptTransaction(newSortie);
      sorties.add(encryptedSortie);
      
      await _firebaseService.saveSorties(sorties);
  DataUpdateBus.emit('sorties');
      
      if (kDebugMode) {
        print('✅ Sortie chiffrée ajoutée: [MONTANT_CHIFFRÉ] - $description');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout sortie chiffrée: $e');
      }
      rethrow;
    }
  }

  Future<void> updateSortie({
    required int index,
    required String amountStr,
    required String description,
    DateTime? date,
    // Suppression du paramètre periodicity
  }) async {
    _ensureInitialized();
    try {
      final sorties = await _firebaseService.loadSorties();
      if (index >= 0 && index < sorties.length) {
        final oldSortie = _encryption.decryptTransaction(sorties[index]);
        
        final double amount = AmountParser.parseAmount(amountStr);
        final updatedSortie = {
          'amount': amount,
          'description': description,
          'date': (date ?? DateTime.tryParse(oldSortie['date'] ?? '') ?? DateTime.now()).toIso8601String(),
          'timestamp': oldSortie['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          'id': oldSortie['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'isPointed': oldSortie['isPointed'] ?? false,
          'pointedAt': oldSortie['pointedAt'],
          // Suppression de 'periodicity': periodicity ?? oldSortie['periodicity'] ?? 'ponctuel',
        };
        
        sorties[index] = _encryption.encryptTransaction(updatedSortie);
        await _firebaseService.saveSorties(sorties);
    DataUpdateBus.emit('sorties');
        
        if (kDebugMode) {
          print('✅ Sortie mise à jour');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour sortie: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteSortie(int index) async {
    _ensureInitialized();
    try {
      final sorties = await _firebaseService.loadSorties();
      if (index >= 0 && index < sorties.length) {
        sorties.removeAt(index);
        await _firebaseService.saveSorties(sorties);
    DataUpdateBus.emit('sorties');
        
        if (kDebugMode) {
          print('✅ Sortie chiffrée supprimée');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression sortie chiffrée: $e');
      }
      rethrow;
    }
  }

  /// GESTION DES PLAISIRS (DÉPENSES) CHIFFRÉES AVEC POINTAGE

  Future<List<Map<String, dynamic>>> getPlaisirs() async {
    _ensureInitialized();
    try {
      final encryptedData = await _firebaseService.loadPlaisirs();
      
      // Déchiffre chaque plaisir
      final List<Map<String, dynamic>> decryptedPlaisirs = [];
      for (var entry in encryptedData) {
        decryptedPlaisirs.add(_encryption.decryptTransaction(entry));
      }
      
      return decryptedPlaisirs;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement plaisirs chiffrés: $e');
      }
      return [];
    }
  }

  Future<void> addPlaisir({
    required String amountStr,
    String? tag,
    DateTime? date,
    bool isCredit = false, // NOUVEAU paramètre
  }) async {
    _ensureInitialized();
    try {
      final plaisirs = await _firebaseService.loadPlaisirs();
      final double amount = AmountParser.parseAmount(amountStr);
      
      final newPlaisir = {
        'amount': amount,
        'tag': tag ?? 'Sans catégorie',
        'date': (date ?? DateTime.now()).toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isPointed': false, // Par défaut, non pointé
        'isCredit': isCredit, // NOUVEAU champ
      };
      
      // Chiffre avant d'ajouter
      final encryptedPlaisir = _encryption.encryptTransaction(newPlaisir);
      plaisirs.add(encryptedPlaisir);
      
      await _firebaseService.savePlaisirs(plaisirs);
  DataUpdateBus.emit('plaisirs');
      
      // Sauvegarder le tag s'il est nouveau (en clair pour l'autocomplétion)
      if (tag != null && tag.isNotEmpty) {
        await _addTagIfNew(tag);
      }
      
      if (kDebugMode) {
        print('✅ Plaisir chiffré ajouté: [MONTANT_CHIFFRÉ] - ${tag ?? "Sans catégorie"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout plaisir chiffré: $e');
      }
      rethrow;
    }
  }

  /// Mettre à jour un plaisir avec support du pointage et crédit
  Future<void> updatePlaisir({
    required int index,
    required String amountStr,
    required String tag,
    DateTime? date,
    bool? isPointed,
    String? pointedAt,
    bool? isCredit, // Nouveau paramètre
  }) async {
    _ensureInitialized();
    try {
      final plaisirs = await _firebaseService.loadPlaisirs();
      if (index >= 0 && index < plaisirs.length) {
        // Récupérer l'ancien plaisir pour préserver certaines données
        final oldPlaisir = _encryption.decryptTransaction(plaisirs[index]);
        
        final amount = AmountParser.parseAmount(amountStr);
        
        final updatedPlaisir = {
          'amount': amount,
          'tag': tag,
          'date': (date ?? DateTime.now()).toIso8601String(),
          'id': oldPlaisir['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'isPointed': isPointed ?? oldPlaisir['isPointed'] ?? false,
          'isCredit': isCredit ?? oldPlaisir['isCredit'] ?? false, // Nouveau champ
        };

        // Ajouter pointedAt si fourni
        if (pointedAt != null) {
          updatedPlaisir['pointedAt'] = pointedAt;
        } else if (oldPlaisir['pointedAt'] != null) {
          updatedPlaisir['pointedAt'] = oldPlaisir['pointedAt'];
        }
        
        // Chiffrer et sauvegarder
        plaisirs[index] = _encryption.encryptTransaction(updatedPlaisir);
        await _firebaseService.savePlaisirs(plaisirs);
    DataUpdateBus.emit('plaisirs');
        
        // Sauvegarder le tag s'il est nouveau
        if (tag.isNotEmpty) {
          await _addTagIfNew(tag);
        }
        
        if (kDebugMode) {
          print('✅ Plaisir chiffré mis à jour: [MONTANT_CHIFFRÉ] - $tag${isCredit == true ? " (CRÉDIT)" : ""}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour plaisir: $e');
      }
      rethrow;
    }
  }

  Future<void> deletePlaisir(int index) async {
    _ensureInitialized();
    try {
      final plaisirs = await _firebaseService.loadPlaisirs();
      if (index >= 0 && index < plaisirs.length) {
        plaisirs.removeAt(index);
        await _firebaseService.savePlaisirs(plaisirs);
    DataUpdateBus.emit('plaisirs');
        
        if (kDebugMode) {
          print('✅ Plaisir chiffré supprimé');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression plaisir chiffré: $e');
      }
      rethrow;
    }
  }

  /// GESTION DU SOLDE BANCAIRE CHIFFRÉ

  Future<double> getBankBalance() async {
    _ensureInitialized();
    try {
      // Charge les données chiffrées
      final data = await _userBudgetCollection!.doc('settings').get();
      if (data.exists && data.data() != null) {
        final settings = data.data() as Map<String, dynamic>;
        
        // Vérifie si le solde est chiffré
        if (settings.containsKey('encryptedBankBalance')) {
          return _encryption.decryptAmount(settings['encryptedBankBalance']);
        }
        
        // Fallback vers l'ancien format non chiffré
        return (settings['bankBalance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement solde chiffré: $e');
      }
      return 0.0;
    }
  }

  Future<void> setBankBalance(String balanceStr) async {
    _ensureInitialized();
    try {
      final double balance = AmountParser.parseAmount(balanceStr);
      
      await _userBudgetCollection!.doc('settings').set({
        'encryptedBankBalance': _encryption.encryptAmount(balance),
        'updatedAt': FieldValue.serverTimestamp(),
        // Supprime l'ancien champ non chiffré
        'bankBalance': FieldValue.delete(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('✅ Solde bancaire chiffré sauvegardé: [MONTANT_CHIFFRÉ]');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde solde chiffré: $e');
      }
      rethrow;
    }
  }

  /// UTILITAIRES

  Future<void> _addTagIfNew(String tag) async {
    try {
      final tags = await _firebaseService.loadTags();
      if (!tags.contains(tag)) {
        tags.add(tag);
        await _firebaseService.saveTags(tags);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur ajout tag: $e');
      }
    }
  }

  Future<List<String>> getTags() async {
    try {
      return await _firebaseService.loadTags();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement tags: $e');
      }
      return [];
    }
  }

  Future<void> saveTags(List<String> tags) async {
    try {
      await _firebaseService.saveTags(tags);
  DataUpdateBus.emit('tags');
      if (kDebugMode) {
        print('✅ Tags sauvegardés (${tags.length} tags)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde tags: $e');
      }
      rethrow;
    }
  }

  /// CALCULS ET STATISTIQUES (sur données déchiffrées côté client)

  Future<Map<String, double>> getTotals() async {
    _ensureInitialized();
    try {
      final entrees = await getEntrees();
      final sorties = await getSorties();
      final plaisirs = await getPlaisirs();

      double totalEntrees = 0;
      for (var entree in entrees) {
        totalEntrees += (entree['amount'] as num).toDouble();
      }

      double totalSorties = 0;
      for (var sortie in sorties) {
        totalSorties += (sortie['amount'] as num).toDouble();
      }

      double totalPlaisirs = 0;
      double totalPlaisirsTotaux = 0; // Total des dépenses pointées
      for (var plaisir in plaisirs) {
        final amount = (plaisir['amount'] as num).toDouble();
        
        // Pour le total général (solde prévu)
        if (plaisir['isCredit'] == true) {
          totalPlaisirs -= amount; // Les crédits réduisent le total des dépenses (donc augmentent le solde)
        } else {
          totalPlaisirs += amount; // Les dépenses augmentent le total des dépenses
        }
        
        // Pour les pointés (solde pointé)
        if (plaisir['isPointed'] == true) {
          if (plaisir['isCredit'] == true) {
            totalPlaisirsTotaux -= amount; // Les crédits pointés réduisent le total des dépenses pointées
          } else {
            totalPlaisirsTotaux += amount; // Les dépenses pointées augmentent le total
          }
        }
      }

      return {
        'entrees': totalEntrees,
        'sorties': totalSorties,
        'plaisirs': totalPlaisirs, // Peut être négatif si plus de crédits que de dépenses
        'plaisirsTotaux': totalPlaisirsTotaux, // Idem pour les pointés
        'solde': totalEntrees - totalSorties - totalPlaisirs, // Le solde sera correct
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur calcul totaux chiffrés: $e');
      }
      return {
        'entrees': 0.0,
        'sorties': 0.0,
        'plaisirs': 0.0,
        'plaisirsTotaux': 0.0,
        'solde': 0.0,
      };
    }
  }

  Future<Map<String, double>> getPlaisirsByTag() async {
    try {
      final plaisirs = await getPlaisirs();
      final Map<String, double> totals = {};

      for (var plaisir in plaisirs) {
        final tag = plaisir['tag'] as String? ?? 'Sans catégorie';
        final amount = (plaisir['amount'] as num).toDouble();
        totals[tag] = (totals[tag] ?? 0) + amount;
      }

      return totals;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur calcul plaisirs par tag: $e');
      }
      return {};
    }
  }

  /// Migration des données existantes vers le format chiffré
  Future<void> migrateToEncrypted() async {
    _ensureInitialized();
    try {
      if (kDebugMode) {
        print('🔄 Migration vers données chiffrées...');
      }

      // Migrer les entrées
      final entrees = await _firebaseService.loadEntrees();
      bool needsMigration = false;
      
      for (int i = 0; i < entrees.length; i++) {
        if (entrees[i]['_encrypted'] != true) {
          entrees[i] = _encryption.encryptTransaction(entrees[i]);
          needsMigration = true;
        }
      }
      
      if (needsMigration) {
        await _firebaseService.saveEntrees(entrees);
        if (kDebugMode) {
          print('✅ Entrées migrées vers format chiffré');
        }
      }

      // Migrer les sorties
      final sorties = await _firebaseService.loadSorties();
      needsMigration = false;
      
      for (int i = 0; i < sorties.length; i++) {
        if (sorties[i]['_encrypted'] != true) {
          sorties[i] = _encryption.encryptTransaction(sorties[i]);
          needsMigration = true;
        }
      }
      
      if (needsMigration) {
        await _firebaseService.saveSorties(sorties);
        if (kDebugMode) {
          print('✅ Sorties migrées vers format chiffré');
        }
      }

      // Migrer les plaisirs avec ajout du système de pointage
      final plaisirs = await _firebaseService.loadPlaisirs();
      needsMigration = false;
      
      for (int i = 0; i < plaisirs.length; i++) {
        if (plaisirs[i]['_encrypted'] != true) {
          // Ajoute le système de pointage si absent
          if (!plaisirs[i].containsKey('isPointed')) {
            plaisirs[i]['isPointed'] = false;
          }
          plaisirs[i] = _encryption.encryptTransaction(plaisirs[i]);
          needsMigration = true;
        } else if (!plaisirs[i].containsKey('isPointed')) {
          // Ajoute le pointage aux données déjà chiffrées
          final decrypted = _encryption.decryptTransaction(plaisirs[i]);
          decrypted['isPointed'] = false;
          plaisirs[i] = _encryption.encryptTransaction(decrypted);
          needsMigration = true;
        }
      }
      
      if (needsMigration) {
        await _firebaseService.savePlaisirs(plaisirs);
        if (kDebugMode) {
          print('✅ Plaisirs migrés vers format chiffré avec pointage');
        }
      }

      if (kDebugMode) {
        print('✅ Migration terminée');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur migration: $e');
      }
    }
  }

  // Ajouter cette méthode après les autres méthodes de gestion des sorties
  Future<void> toggleSortiePointing(int index) async {
    _ensureInitialized();
    try {
      final sorties = await _firebaseService.loadSorties();
      if (index >= 0 && index < sorties.length) {
        // Déchiffrer la sortie
        final decryptedSortie = _encryption.decryptTransaction(sorties[index]);
        
        final bool currentlyPointed = decryptedSortie['isPointed'] == true;
        
        // Bascule le statut
        decryptedSortie['isPointed'] = !currentlyPointed;
        
        if (!currentlyPointed) {
          // Si on pointe, on ajoute la date
          decryptedSortie['pointedAt'] = DateTime.now().toIso8601String();
        } else {
          // Si on dépointe, on supprime la date
          decryptedSortie.remove('pointedAt');
        }
        
        // Rechiffrer et sauvegarder
        sorties[index] = _encryption.encryptTransaction(decryptedSortie);
        await _firebaseService.saveSorties(sorties);
        
        if (kDebugMode) {
          print('✅ Charge ${currentlyPointed ? 'dépointée' : 'pointée'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur basculement pointage sortie: $e');
      }
      rethrow;
    }
  }

  /// SUPPRESSION COMPLÈTE DES DONNÉES
  Future<void> deleteAllUserData() async {
    _ensureInitialized();
    try {
      await _firebaseService.deleteAllUserData();
      
      if (kDebugMode) {
        print('✅ Suppression complète des données terminée');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression complète: $e');
      }
      rethrow;
    }
  }

  /// Ajouter cette méthode à la fin de la classe EncryptedBudgetDataService
  Future<void> deleteAllData() async {
    _ensureInitialized();
    try {
      // Effacer les données dans Firebase si connecté
      final user = _firebaseService.currentUser;
      if (user != null) {
        await _firebaseService.deleteUserData();
      }
      
      if (kDebugMode) {
        print('✅ Toutes les données ont été supprimées');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression des données: $e');
      }
      rethrow;
    }
  }

  /// Génère les projections SANS périodicité (tous ponctuels maintenant)
  Future<Map<String, Map<String, double>>> getProjectionsWithPeriodicity({
    int yearStart = 2024,
    int yearEnd = 2030,
  }) async {
    try {
      final entrees = await getEntrees();
      final sorties = await getSorties();
      final plaisirs = await getPlaisirs();
      
      Map<String, Map<String, double>> projections = {};
      
      // Initialiser toutes les périodes
      for (int year = yearStart; year <= yearEnd; year++) {
        for (int month = 1; month <= 12; month++) {
          final monthKey = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
          projections[monthKey] = {'revenus': 0.0, 'charges': 0.0, 'depenses': 0.0};
        }
      }
      
      // Traiter les revenus SANS périodicité (toujours ponctuels)
      for (var entree in entrees) {
        final amount = (entree['amount'] as num).toDouble();
        final dateStr = entree['date'] as String? ?? '';
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final monthKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
          if (projections.containsKey(monthKey)) {
            projections[monthKey]!['revenus'] = projections[monthKey]!['revenus']! + amount;
          }
        }
      }
      
      // Traiter les charges (toujours ponctuelles)
      for (var sortie in sorties) {
        final amount = (sortie['amount'] as num).toDouble();
        final dateStr = sortie['date'] as String? ?? '';
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final monthKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
          if (projections.containsKey(monthKey)) {
            projections[monthKey]!['charges'] = projections[monthKey]!['charges']! + amount;
          }
        }
      }
      
      // Traiter les dépenses (toujours ponctuelles)
      for (var plaisir in plaisirs) {
        final dateStr = plaisir['date'] as String? ?? '';
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final monthKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
          if (projections.containsKey(monthKey)) {
            final amount = (plaisir['amount'] as num).toDouble();
            final isCredit = plaisir['isCredit'] == true;
            
            if (isCredit) {
              projections[monthKey]!['depenses'] = projections[monthKey]!['depenses']! - amount;
            } else {
              projections[monthKey]!['depenses'] = projections[monthKey]!['depenses']! + amount;
            }
          }
        }
      }
      
      return projections;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur génération projections: $e');
      }
      return {};
    }
  }
}