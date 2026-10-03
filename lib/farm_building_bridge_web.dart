// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

typedef FarmBuildingTapHandler = void Function(String target);

abstract final class FarmBuildingBridge {
  static final Set<FarmBuildingTapHandler> _handlers = {};
  static bool _isListening = false;
  static String? _lastTarget;
  static DateTime? _lastTargetAt;

  static void register(FarmBuildingTapHandler handler) {
    _handlers.add(handler);
    if (_isListening) return;
    html.document.addEventListener('farm-building-tap', _handleEvent);
    html.window.addEventListener('farm-building-tap', _handleEvent);
    html.window.addEventListener('message', _handleEvent);
    _isListening = true;
  }

  static void unregister(FarmBuildingTapHandler handler) {
    _handlers.remove(handler);
    if (_handlers.isNotEmpty || !_isListening) return;
    html.document.removeEventListener('farm-building-tap', _handleEvent);
    html.window.removeEventListener('farm-building-tap', _handleEvent);
    html.window.removeEventListener('message', _handleEvent);
    _isListening = false;
  }

  static void _handleEvent(html.Event event) {
    final target = switch (event) {
      html.CustomEvent customEvent => customEvent.detail?.toString(),
      html.MessageEvent messageEvent => _targetFromMessage(messageEvent.data),
      _ => null,
    };
    if (target == null || target.isEmpty) return;
    final now = DateTime.now();
    final isDuplicate =
        _lastTarget == target &&
        _lastTargetAt != null &&
        now.difference(_lastTargetAt!).inMilliseconds < 350;
    if (isDuplicate) return;
    _lastTarget = target;
    _lastTargetAt = now;
    for (final handler in List<FarmBuildingTapHandler>.from(_handlers)) {
      handler(target);
    }
  }

  static String? _targetFromMessage(Object? data) {
    if (data is! String) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return null;
      if (decoded['type'] != 'farm-building-tap') return null;
      return decoded['target']?.toString();
    } catch (_) {
      return null;
    }
  }
}
