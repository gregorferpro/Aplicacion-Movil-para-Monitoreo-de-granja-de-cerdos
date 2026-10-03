// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

typedef GestationCrateTapHandler = void Function(int crateNumber);

abstract final class GestationCrateBridge {
  static final Set<GestationCrateTapHandler> _handlers = {};
  static bool _isListening = false;
  static int? _lastCrateNumber;
  static DateTime? _lastCrateAt;

  static void register(GestationCrateTapHandler handler) {
    _handlers.add(handler);
    if (_isListening) return;
    html.document.addEventListener('gestation-crate-tap', _handleEvent);
    html.window.addEventListener('gestation-crate-tap', _handleEvent);
    html.window.addEventListener('message', _handleEvent);
    _isListening = true;
  }

  static void unregister(GestationCrateTapHandler handler) {
    _handlers.remove(handler);
    if (_handlers.isNotEmpty || !_isListening) return;
    html.document.removeEventListener('gestation-crate-tap', _handleEvent);
    html.window.removeEventListener('gestation-crate-tap', _handleEvent);
    html.window.removeEventListener('message', _handleEvent);
    _isListening = false;
  }

  static void _handleEvent(html.Event event) {
    final crateNumber = switch (event) {
      html.CustomEvent customEvent => int.tryParse(
        customEvent.detail?.toString() ?? '',
      ),
      html.MessageEvent messageEvent => _crateFromMessage(messageEvent.data),
      _ => null,
    };
    if (crateNumber == null) return;

    final now = DateTime.now();
    final isDuplicate =
        _lastCrateNumber == crateNumber &&
        _lastCrateAt != null &&
        now.difference(_lastCrateAt!).inMilliseconds < 350;
    if (isDuplicate) return;

    _lastCrateNumber = crateNumber;
    _lastCrateAt = now;
    for (final handler in List<GestationCrateTapHandler>.from(_handlers)) {
      handler(crateNumber);
    }
  }

  static int? _crateFromMessage(Object? data) {
    if (data is! String) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return null;
      if (decoded['type'] != 'gestation-crate-tap') return null;
      final raw =
          decoded['crate'] ?? decoded['crateNumber'] ?? decoded['target'];
      return int.tryParse(raw?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
