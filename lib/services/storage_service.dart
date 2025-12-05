import 'dart:convert';
// Import foundation retiré (suppression debug)
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _storageKey = 'budget_data';
  static const String _lastUpdateKey = 'last_update';
  static const String _balanceKey = 'bank_balance';
  static const String _checkedTransactionsKey = 'checked_transactions';
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<bool> saveData({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> plaisirs,
    required List<Map<String, dynamic>> entrees,
    required List<Map<String, dynamic>> sorties,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'transactions': transactions,
        'plaisirs': plaisirs,
        'entrees': entrees,
        'sorties': sorties,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      final success = await prefs.setString(_storageKey, jsonEncode(data));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());

  // Log supprimé
      return success;
  } catch (e) {
      return false;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_storageKey);
      
      if (storedData == null) {
        return _getEmptyData();
      }

      final data = jsonDecode(storedData) as Map<String, dynamic>;
      
      return {
        'transactions': List<Map<String, dynamic>>.from(data['transactions'] ?? []),
        'plaisirs': List<Map<String, dynamic>>.from(data['plaisirs'] ?? []),
        'entrees': List<Map<String, dynamic>>.from(data['entrees'] ?? []),
        'sorties': List<Map<String, dynamic>>.from(data['sorties'] ?? []),
      };
  } catch (e) {
      return _getEmptyData();
    }
  }

  Map<String, List<Map<String, dynamic>>> _getEmptyData() {
    return {
      'transactions': [],
      'plaisirs': [],
      'entrees': [],
      'sorties': [],
    };
  }

  Future<DateTime?> getLastUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_lastUpdateKey);
      return dateStr != null ? DateTime.parse(dateStr) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_lastUpdateKey);
      
  // Log supprimé
  } catch (e) {
      rethrow;
    }
  }

  Future<void> saveBankBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey, balance);
  }

  Future<double> getBankBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey) ?? 0.0;
  }

  Future<void> updateTransactionStatus(String transactionId, bool isChecked) async {
    final prefs = await SharedPreferences.getInstance();
    final checkedTransactions = prefs.getStringList(_checkedTransactionsKey) ?? [];
    
    if (isChecked && !checkedTransactions.contains(transactionId)) {
      checkedTransactions.add(transactionId);
    } else if (!isChecked) {
      checkedTransactions.remove(transactionId);
    }
    
    await prefs.setStringList(_checkedTransactionsKey, checkedTransactions);
  }
}