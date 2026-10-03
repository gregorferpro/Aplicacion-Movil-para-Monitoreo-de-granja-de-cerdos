// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

typedef FeedFeederTapHandler =
    void Function(String barnId, int corralNumber, int feederNumber);

abstract final class FeedFeederBridge {
  static final Set<FeedFeederTapHandler> _handlers = {};
  static bool _isListening = false;
  static String? _lastKey;
  static DateTime? _lastTapAt;

  static void register(FeedFeederTapHandler handler) {
    _handlers.add(handler);
    if (_isListening) return;
    html.document.addEventListener('feed-feeder-tap', _handleEvent);
    html.window.addEventListener('feed-feeder-tap', _handleEvent);
    html.window.addEventListener('message', _handleEvent);
    _isListening = true;
  }

  static void unregister(FeedFeederTapHandler handler) {
    _handlers.remove(handler);
    if (_handlers.isNotEmpty || !_isListening) return;
    html.document.removeEventListener('feed-feeder-tap', _handleEvent);
    html.window.removeEventListener('feed-feeder-tap', _handleEvent);
    html.window.removeEventListener('message', _handleEvent);
    _isListening = false;
  }

  static void _handleEvent(html.Event event) {
    final tap = switch (event) {
      html.CustomEvent customEvent => _tapFromDetail(customEvent.detail),
      html.MessageEvent messageEvent => _tapFromMessage(messageEvent.data),
      _ => null,
    };
    if (tap == null) return;

    final key = '${tap.barnId}:${tap.corralNumber}:${tap.feederNumber}';
    final now = DateTime.now();
    final isDuplicate =
        _lastKey == key &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!).inMilliseconds < 350;
    if (isDuplicate) return;

    _lastKey = key;
    _lastTapAt = now;
    for (final handler in List<FeedFeederTapHandler>.from(_handlers)) {
      handler(tap.barnId, tap.corralNumber, tap.feederNumber);
    }
  }

  static _FeedFeederTap? _tapFromMessage(Object? data) {
    if (data is! String) return null;
    try {
      final decoded = jsonDecode(data);
      return _tapFromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  static _FeedFeederTap? _tapFromDetail(Object? detail) {
    if (detail is String) {
      try {
        return _tapFromMap(jsonDecode(detail));
      } catch (_) {
        return null;
      }
    }
    return _tapFromMap(detail);
  }

  static _FeedFeederTap? _tapFromMap(Object? data) {
    if (data is! Map) return null;
    if (data['type'] != null && data['type'] != 'feed-feeder-tap') {
      return null;
    }

    final barnId = data['barn']?.toString() ?? data['barnId']?.toString();
    final corralNumber = int.tryParse(
      (data['corral'] ?? data['corralNumber'])?.toString() ?? '',
    );
    final feederNumber = int.tryParse(
      (data['feeder'] ?? data['feederNumber'])?.toString() ?? '',
    );

    if (barnId == null ||
        barnId.isEmpty ||
        corralNumber == null ||
        feederNumber == null) {
      return null;
    }
    return _FeedFeederTap(barnId, corralNumber, feederNumber);
  }
}

class _FeedFeederTap {
  const _FeedFeederTap(this.barnId, this.corralNumber, this.feederNumber);

  final String barnId;
  final int corralNumber;
  final int feederNumber;
}
