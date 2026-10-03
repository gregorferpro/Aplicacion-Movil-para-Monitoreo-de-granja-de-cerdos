typedef FeedFeederTapHandler =
    void Function(String barnId, int corralNumber, int feederNumber);

abstract final class FeedFeederBridge {
  static void register(FeedFeederTapHandler handler) {}

  static void unregister(FeedFeederTapHandler handler) {}
}
