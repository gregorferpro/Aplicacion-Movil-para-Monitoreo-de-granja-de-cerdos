typedef MaternityCrateTapHandler = void Function(int crateNumber);

abstract final class MaternityCrateBridge {
  static void register(MaternityCrateTapHandler handler) {}

  static void unregister(MaternityCrateTapHandler handler) {}
}
