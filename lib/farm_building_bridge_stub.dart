typedef FarmBuildingTapHandler = void Function(String target);

abstract final class FarmBuildingBridge {
  static void register(FarmBuildingTapHandler handler) {}

  static void unregister(FarmBuildingTapHandler handler) {}
}
