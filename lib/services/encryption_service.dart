import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Service de chiffrement sécurisé pour les données financières
/// Version 2.0 avec migration automatique depuis le format legacy
class FinancialDataEncryption {
  static final FinancialDataEncryption _instance = FinancialDataEncryption._internal();
  factory FinancialDataEncryption() => _instance;
  FinancialDataEncryption._internal();

  // Clé de chiffrement AES-256
  late encrypt.Encrypter _encrypter;
  late encrypt.Key _key;
  
  // Pour la compatibilité legacy (IV statique)
  late encrypt.IV _legacyIv;
  
  // Séparateur pour le format sécurisé (IV:ciphertext)
  static const String _secureFormatSeparator = ':';
  
  // Random sécurisé pour générer les IV
  final Random _secureRandom = Random.secure();
  
  /// Initialise le chiffrement pour un utilisateur spécifique
  void initializeForUser(String userId) {
    // Génère une clé unique basée sur l'ID utilisateur + salt secret
    final String saltedUserId = '$userId-budget-salt-2024';
    final List<int> keyBytes = sha256.convert(utf8.encode(saltedUserId)).bytes;
    
    // Utilise les 32 premiers bytes pour AES-256
    _key = encrypt.Key(Uint8List.fromList(keyBytes));
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    
    // Conserve l'IV legacy pour la migration (format ancien)
    final List<int> legacyIvBytes = sha256.convert(utf8.encode('$userId-iv')).bytes.take(16).toList();
    _legacyIv = encrypt.IV(Uint8List.fromList(legacyIvBytes));
  }

  /// Génère un IV aléatoire sécurisé (16 bytes)
  encrypt.IV _generateSecureIV() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    return encrypt.IV(Uint8List.fromList(bytes));
  }

  /// Normalise un montant pour supporter les virgules
  double _normalizeAmount(String amountStr) {
    String normalized = amountStr.replaceAll(',', '.');
    List<String> parts = normalized.split('.');
    if (parts.length > 2) {
      normalized = '${parts.sublist(0, parts.length - 1).join('')}.${parts.last}';
    }
    return double.tryParse(normalized) ?? 0.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES DE CHIFFREMENT SÉCURISÉ (NOUVEAU FORMAT)
  // Format: "base64(IV):base64(ciphertext)"
  // ═══════════════════════════════════════════════════════════════════════════

  /// Chiffre un montant avec IV aléatoire unique (NOUVEAU FORMAT SÉCURISÉ)
  String encryptAmount(double amount) {
    try {
      final String amountStr = amount.toStringAsFixed(2);
      final encrypt.IV iv = _generateSecureIV();
      final encrypt.Encrypted encrypted = _encrypter.encrypt(amountStr, iv: iv);
      
      // Format sécurisé: IV:ciphertext (les deux en base64)
      return '${iv.base64}$_secureFormatSeparator${encrypted.base64}';
    } catch (e) {
      // Fallback sécurisé
      final encrypt.IV iv = _generateSecureIV();
      final encrypt.Encrypted encrypted = _encrypter.encrypt('0.00', iv: iv);
      return '${iv.base64}$_secureFormatSeparator${encrypted.base64}';
    }
  }

  /// Chiffre une description avec IV aléatoire (NOUVEAU FORMAT SÉCURISÉ)
  String encryptDescription(String description) {
    try {
      if (description.isEmpty) return '';
      final encrypt.IV iv = _generateSecureIV();
      final encrypt.Encrypted encrypted = _encrypter.encrypt(description, iv: iv);
      return '${iv.base64}$_secureFormatSeparator${encrypted.base64}';
    } catch (e) {
      return '';
    }
  }

  /// Chiffre un montant depuis une chaîne (support des virgules)
  String encryptAmountFromString(String amountStr) {
    final double amount = _normalizeAmount(amountStr);
    return encryptAmount(amount);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES LEGACY (ANCIEN FORMAT - IV STATIQUE)
  // Pour la migration des anciennes données
  // ═══════════════════════════════════════════════════════════════════════════

  /// Déchiffre un montant avec l'ancien format (IV statique)
  double _decryptAmountLegacy(String encryptedAmount) {
    try {
      final encrypt.Encrypted encrypted = encrypt.Encrypted.fromBase64(encryptedAmount);
      final String decryptedStr = _encrypter.decrypt(encrypted, iv: _legacyIv);
      return _normalizeAmount(decryptedStr);
    } catch (e) {
      return 0.0;
    }
  }

  /// Déchiffre une description avec l'ancien format (IV statique)
  String _decryptDescriptionLegacy(String encryptedDescription) {
    try {
      if (encryptedDescription.isEmpty) return '';
      final encrypt.Encrypted encrypted = encrypt.Encrypted.fromBase64(encryptedDescription);
      return _encrypter.decrypt(encrypted, iv: _legacyIv);
    } catch (e) {
      return 'Description indisponible';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES DE DÉCHIFFREMENT AVEC FALLBACK AUTOMATIQUE
  // Essaie d'abord le nouveau format, puis fallback sur legacy
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie si une chaîne est au nouveau format sécurisé
  bool _isSecureFormat(String encrypted) {
    return encrypted.contains(_secureFormatSeparator);
  }

  /// Déchiffre un montant (avec fallback automatique legacy)
  double decryptAmount(String encryptedAmount) {
    if (encryptedAmount.isEmpty) return 0.0;
    
    // Essaie d'abord le nouveau format sécurisé
    if (_isSecureFormat(encryptedAmount)) {
      try {
        final parts = encryptedAmount.split(_secureFormatSeparator);
        if (parts.length == 2) {
          final encrypt.IV iv = encrypt.IV.fromBase64(parts[0]);
          final encrypt.Encrypted encrypted = encrypt.Encrypted.fromBase64(parts[1]);
          final String decryptedStr = _encrypter.decrypt(encrypted, iv: iv);
          return _normalizeAmount(decryptedStr);
        }
      } catch (e) {
        // Si le format semble sécurisé mais échoue, ne pas fallback
        return 0.0;
      }
    }
    
    // Fallback vers l'ancien format legacy (IV statique)
    return _decryptAmountLegacy(encryptedAmount);
  }

  /// Déchiffre une description (avec fallback automatique legacy)
  String decryptDescription(String encryptedDescription) {
    if (encryptedDescription.isEmpty) return '';
    
    // Essaie d'abord le nouveau format sécurisé
    if (_isSecureFormat(encryptedDescription)) {
      try {
        final parts = encryptedDescription.split(_secureFormatSeparator);
        if (parts.length == 2) {
          final encrypt.IV iv = encrypt.IV.fromBase64(parts[0]);
          final encrypt.Encrypted encrypted = encrypt.Encrypted.fromBase64(parts[1]);
          return _encrypter.decrypt(encrypted, iv: iv);
        }
      } catch (e) {
        return 'Description indisponible';
      }
    }
    
    // Fallback vers l'ancien format legacy
    return _decryptDescriptionLegacy(encryptedDescription);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIGRATION DES DONNÉES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie si une valeur chiffrée est au format legacy
  bool isLegacyFormat(String encrypted) {
    return encrypted.isNotEmpty && !_isSecureFormat(encrypted);
  }

  /// Ré-encrypte un montant déjà déchiffré avec le nouveau format sécurisé
  String reEncryptAmount(double amount) {
    return encryptAmount(amount);
  }

  /// Ré-encrypte une description déjà déchiffrée avec le nouveau format sécurisé
  String reEncryptDescription(String description) {
    return encryptDescription(description);
  }

  /// Migre une transaction du format legacy vers le format sécurisé
  /// Retourne la transaction ré-encryptée, ou null si déjà au bon format
  Map<String, dynamic>? migrateTransaction(Map<String, dynamic> transaction) {
    if (transaction['_encrypted'] != true) {
      return null; // Pas chiffrée, rien à migrer
    }
    
    bool needsMigration = false;
    final Map<String, dynamic> migratedTransaction = Map.from(transaction);
    
    // Vérifier et migrer le montant
    if (transaction.containsKey('amount') && transaction['amount'] is String) {
      final String encryptedAmount = transaction['amount'];
      if (isLegacyFormat(encryptedAmount)) {
        final double amount = decryptAmount(encryptedAmount);
        migratedTransaction['amount'] = encryptAmount(amount);
        needsMigration = true;
      }
    }
    
    // Vérifier et migrer la description
    if (transaction.containsKey('description') && transaction['description'] is String) {
      final String encryptedDesc = transaction['description'];
      if (encryptedDesc.isNotEmpty && isLegacyFormat(encryptedDesc)) {
        final String description = decryptDescription(encryptedDesc);
        migratedTransaction['description'] = encryptDescription(description);
        needsMigration = true;
      }
    }
    
    // Marquer la version de chiffrement
    if (needsMigration) {
      migratedTransaction['_encryptionVersion'] = 2;
      return migratedTransaction;
    }
    
    return null; // Déjà au bon format
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES DE TRANSACTION COMPLÈTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Chiffre un objet transaction complet (NOUVEAU FORMAT)
  Map<String, dynamic> encryptTransaction(Map<String, dynamic> transaction) {
    final Map<String, dynamic> encryptedTransaction = Map.from(transaction);
    
    // Chiffre le montant (OBLIGATOIRE)
    if (transaction.containsKey('amount')) {
      final dynamic amountValue = transaction['amount'];
      double amount = 0.0;
      
      if (amountValue is String) {
        amount = _normalizeAmount(amountValue);
      } else if (amountValue is num) {
        amount = amountValue.toDouble();
      }
      
      encryptedTransaction['amount'] = encryptAmount(amount);
      encryptedTransaction['_encrypted'] = true;
      encryptedTransaction['_encryptionVersion'] = 2; // Nouvelle version
    }
    
    // Chiffre la description si présente (OPTIONNEL)
    if (transaction.containsKey('description')) {
      final String description = transaction['description'] as String? ?? '';
      encryptedTransaction['description'] = encryptDescription(description);
    }
    
    // Préserve les données de pointage si présentes
    if (transaction.containsKey('isPointed')) {
      encryptedTransaction['isPointed'] = transaction['isPointed'];
    }
    if (transaction.containsKey('pointedAt')) {
      encryptedTransaction['pointedAt'] = transaction['pointedAt'];
    }
    
    return encryptedTransaction;
  }

  /// Déchiffre un objet transaction complet (avec fallback legacy automatique)
  Map<String, dynamic> decryptTransaction(Map<String, dynamic> encryptedTransaction) {
    final Map<String, dynamic> transaction = Map.from(encryptedTransaction);
    
    // Vérifie si la transaction est chiffrée
    if (encryptedTransaction['_encrypted'] != true) {
      return transaction;
    }
    
    // Déchiffre le montant (fallback automatique)
    if (encryptedTransaction.containsKey('amount')) {
      final String encryptedAmount = encryptedTransaction['amount'] as String? ?? '';
      transaction['amount'] = decryptAmount(encryptedAmount);
    }
    
    // Déchiffre la description si présente (fallback automatique)
    if (encryptedTransaction.containsKey('description')) {
      final String encryptedDesc = encryptedTransaction['description'] as String? ?? '';
      transaction['description'] = decryptDescription(encryptedDesc);
    }
    
    // Préserve les données de pointage
    if (encryptedTransaction.containsKey('isPointed')) {
      transaction['isPointed'] = encryptedTransaction['isPointed'];
    }
    if (encryptedTransaction.containsKey('pointedAt')) {
      transaction['pointedAt'] = encryptedTransaction['pointedAt'];
    }
    
    // Supprime les marqueurs internes
    transaction.remove('_encrypted');
    transaction.remove('_encryptionVersion');
    
    return transaction;
  }

  /// Génère un hash anonyme pour les analytics
  String generateAnonymousHash(double amount) {
    final String data = '${amount.toStringAsFixed(2)}-${DateTime.now().millisecondsSinceEpoch}';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 12);
  }
}

/// Utilitaire pour parser les montants avec support des virgules
class AmountParser {
  static double parseAmount(String input) {
    if (input.isEmpty) return 0.0;
    
    String normalized = input.trim().replaceAll(',', '.');
    normalized = normalized.replaceAll(' ', '');
    
    List<String> parts = normalized.split('.');
    if (parts.length > 2) {
      normalized = '${parts.sublist(0, parts.length - 1).join('')}.${parts.last}';
    }
    
    return double.tryParse(normalized) ?? 0.0;
  }
  
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
}

/// Extension pour simplifier l'utilisation
extension EncryptedBudgetData on Map<String, dynamic> {
  bool get isEncrypted => this['_encrypted'] == true;
  
  double getAmount() {
    if (isEncrypted && this['amount'] is String) {
      return FinancialDataEncryption().decryptAmount(this['amount']);
    }
    final dynamic amountValue = this['amount'];
    if (amountValue is String) {
      return AmountParser.parseAmount(amountValue);
    }
    return (amountValue as num?)?.toDouble() ?? 0.0;
  }
  
  String getDescription() {
    if (isEncrypted && this['description'] is String) {
      return FinancialDataEncryption().decryptDescription(this['description']);
    }
    return this['description'] as String? ?? '';
  }
  
  String getTag() {
    return this['tag'] as String? ?? 'Sans catégorie';
  }
  
  bool get isPointed => this['isPointed'] == true;
  
  DateTime? get pointedAt {
    final String? dateStr = this['pointedAt'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }
}