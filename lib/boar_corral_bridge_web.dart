// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

typedef BoarCorralTapHandler = void Function(int corralNumber);

abstract final class BoarCorralBridge {
  static final Set<BoarCorralTapHandler> _handlers = {};
  static bool _isListening = false;
  static int? _lastCorralNumber;
  static DateTime? _lastCorralAt;

  static void register(BoarCorralTapHandler handler) {
    _handlers.add(handler);
    if (_isListening) return;
    html.document.addEventListener('boar-corral-tap', _handleEvent);
    html.window.addEventListener('boar-corral-tap', _handleEvent);
    html.window.addEventListener('message', _handleEvent);
    _isListening = true;
  }

  static void unregister(BoarCorralTapHandler handler) {
    _handlers.remove(handler);
    if (_handlers.isNotEmpty || !_isListening) return;
    html.document.removeEventListener('boar-corral-tap', _handleEvent);
    html.window.removeEventListener('boar-corral-tap', _handleEvent);
    html.window.removeEventListener('message', _handleEvent);
    _isListening = false;
  }

  static void _handleEvent(html.Event event) {
    final corralNumber = switch (event) {
      html.CustomEvent customEvent => int.tryParse(
        customEvent.detail?.toString() ?? '',
      ),
      html.MessageEvent messageEvent => _corralFromMessage(messageEvent.data),
      _ => null,
    };
    if (corralNumber == null) return;
    final now = DateTime.now();
    final isDuplicate =
        _lastCorralNumber == corralNumber &&
        _lastCorralAt != null &&
        now.difference(_lastCorralAt!).inMilliseconds < 350;
    if (isDuplicate) return;
    _lastCorralNumber = corralNumber;
    _lastCorralAt = now;
    for (final handler in List<BoarCorralTapHandler>.from(_handlers)) {
      handler(corralNumber);
    }
  }

  static int? _corralFromMessage(Object? data) {
    if (data is! String) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return null;
      if (decoded['type'] != 'boar-corral-tap') return null;
      final raw =
          decoded['corral'] ?? decoded['corralNumber'] ?? decoded['target'];
      return int.tryParse(raw?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
