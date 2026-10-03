typedef PreDesteteCorralTapHandler = void Function(int corralNumber);

abstract final class PreDesteteCorralBridge {
  static void register(PreDesteteCorralTapHandler handler) {}

  static void unregister(PreDesteteCorralTapHandler handler) {}
}
