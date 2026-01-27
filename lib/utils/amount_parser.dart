class AmountParser {
  /// Parse un montant sous forme de string et retourne un double
  static double parseAmount(String amountStr) {
    if (amountStr.isEmpty) return 0.0;
    
    // Remplacer les virgules par des points pour la conversion
    String cleanAmount = amountStr.replaceAll(',', '.');
    
    // Supprimer les espaces et autres caractères non numériques sauf le point
    cleanAmount = cleanAmount.replaceAll(RegExp(r'[^\d.]'), '');
    
    try {
      return double.parse(cleanAmount);
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Formate un montant double en string avec 2 décimales
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
  
  /// Formate un montant pour l'affichage avec gestion des décimales
  static String formatAmountDisplay(double amount) {
    if (amount == amount.roundToDouble()) {
      // Si c'est un nombre entier, afficher sans décimales
      return amount.round().toString();
    } else {
      // Sinon afficher avec décimales
      return formatAmount(amount);
    }
  }
  
  /// Valide si une string représente un montant valide
  static bool isValidAmount(String amountStr) {
    if (amountStr.isEmpty) return false;
    
    String cleanAmount = amountStr.replaceAll(',', '.');
    cleanAmount = cleanAmount.replaceAll(RegExp(r'[^\d.]'), '');
    
    try {
      double.parse(cleanAmount);
      return true;
    } catch (e) {
      return false;
    }
  }
}