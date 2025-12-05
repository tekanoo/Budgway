import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class BankBalanceCard extends StatefulWidget {
  const BankBalanceCard({super.key});

  @override
  State<BankBalanceCard> createState() => _BankBalanceCardState();
}

class _BankBalanceCardState extends State<BankBalanceCard> {
  final StorageService _storage = StorageService();
  double _currentBalance = 0.0;
  final _balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final balance = await _storage.getBankBalance();
    setState(() {
      _currentBalance = balance;
    });
  }

  void _updateBalance() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre à jour le solde'),
        content: TextField(
          controller: _balanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nouveau solde',
            suffixText: '€',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBalance = double.tryParse(_balanceController.text) ?? _currentBalance;
              await _storage.saveBankBalance(newBalance);
              setState(() {
                _currentBalance = newBalance;
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Solde du compte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _updateBalance,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentBalance.toStringAsFixed(2)} €',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _currentBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }
}