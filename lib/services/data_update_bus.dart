import 'dart:async';

/// Bus d'événements simple pour propager les mises à jour de données
/// Types possibles: 'tags', 'plaisirs', 'entrees', 'sorties', 'all'
class DataUpdateBus {
  static final StreamController<String> _controller = StreamController<String>.broadcast();
  static Stream<String> get stream => _controller.stream;

  static void emit(String type) {
    if (!_controller.isClosed) {
      _controller.add(type);
    }
  }

  static void dispose() {
    _controller.close();
  }
}
