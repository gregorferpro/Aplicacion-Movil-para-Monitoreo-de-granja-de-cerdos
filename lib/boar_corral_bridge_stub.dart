typedef BoarCorralTapHandler = void Function(int corralNumber);

abstract final class BoarCorralBridge {
  static void register(BoarCorralTapHandler handler) {}

  static void unregister(BoarCorralTapHandler handler) {}
}
