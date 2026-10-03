typedef GestationCrateTapHandler = void Function(int crateNumber);

abstract final class GestationCrateBridge {
  static void register(GestationCrateTapHandler handler) {}

  static void unregister(GestationCrateTapHandler handler) {}
}
