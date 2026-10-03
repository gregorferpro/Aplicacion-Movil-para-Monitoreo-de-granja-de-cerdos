import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

String _resolveModelAsset(String assetPath) {
  if (!kIsWeb) {
    return assetPath;
  }

  if (assetPath.startsWith('/') ||
      assetPath.startsWith(RegExp(r'^[a-zA-Z]+://')) ||
      assetPath.startsWith('data:')) {
    return assetPath;
  }

  final normalized = assetPath.replaceAll(RegExp(r'^/+'), '');
  final webPath = normalized.startsWith('assets/')
      ? 'assets/$normalized'
      : normalized;
  final resolved = Uri.base.resolve(webPath);
  return resolved
      .replace(
        queryParameters: {
          ...resolved.queryParameters,
          'v': 'maternity-20260714-render-v3',
        },
      )
      .toString();
}

class MaternityModelViewer extends StatelessWidget {
  const MaternityModelViewer({
    super.key,
    required this.viewerKey,
    required this.topView,
    this.hotspots = const [],
    this.showCrateHotspots = false,
    this.onCrateTap,
  });

  final Key viewerKey;
  final bool topView;
  final List<MaternityModelCrateHotspot> hotspots;
  final bool showCrateHotspots;
  final ValueChanged<int>? onCrateTap;

  static const String modelAsset = 'assets/models/maternidad.glb';
  static const List<String> componentAssets = [
    'assets/models/sow.glb',
    'assets/models/piglet.glb',
    'assets/models/farrowing_crate.glb',
    'assets/models/feeder.glb',
    'assets/models/drinker.glb',
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _viewerAssetsReady(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data != true) {
          return const Center(
            child: Text(
              'No se encontro el modelo assets/models/maternidad.glb',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ModelViewer(
          key: viewerKey,
          src: _resolveModelAsset(modelAsset),
          alt: 'Modelo 3D GLB de maternidad porcina con 10 jaulas',
          cameraControls: true,
          cameraOrbit: topView ? '-38deg 44deg 38m' : '-42deg 58deg 43m',
          cameraTarget: topView ? '0m 0.85m 0m' : '0m 1.35m 0m',
          fieldOfView: topView ? '25deg' : '28deg',
          minFieldOfView: '16deg',
          maxFieldOfView: '58deg',
          environmentImage: 'neutral',
          backgroundColor: const Color(0xfff1f2f1),
          exposure: 1.08,
          shadowIntensity: 1,
          shadowSoftness: 0.82,
          interactionPrompt: InteractionPrompt.auto,
          loading: Loading.eager,
          reveal: Reveal.auto,
          touchAction: TouchAction.none,
          minHotspotOpacity: showCrateHotspots ? 0.18 : null,
          maxHotspotOpacity: showCrateHotspots ? 1 : null,
          innerModelViewerHtml: showCrateHotspots
              ? _buildHotspotsHtml(hotspots)
              : null,
          relatedCss: showCrateHotspots ? _hotspotCss : _baseCss,
          relatedJs: showCrateHotspots ? _hotspotJs : null,
          javascriptChannels: showCrateHotspots && !kIsWeb && onCrateTap != null
              ? {
                  JavascriptChannel(
                    'MaternityCrateNative',
                    onMessageReceived: (message) {
                      final number = int.tryParse(message.message.trim());
                      if (number != null && number > 0) onCrateTap!(number);
                    },
                  ),
                }
              : null,
        );
      },
    );
  }

  Future<bool> _viewerAssetsReady() async {
    final mainExists = await _assetExists(modelAsset);
    for (final assetPath in componentAssets) {
      final exists = await _assetExists(assetPath);
      if (!exists) {
        debugPrint(
          'Aviso: no se encontro $assetPath; se usara el placeholder integrado en maternidad.glb.',
        );
      }
    }
    return mainExists;
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } on FlutterError {
      return false;
    }
  }

  String _buildHotspotsHtml(List<MaternityModelCrateHotspot> items) {
    return items
        .map((item) {
          final position = _cratePosition(item.number);
          final hitboxPosition = _crateHitboxPosition(item.number);
          final tag = _escapeHtml(item.label);
          final status = _escapeHtml(item.status);
          final number = item.number.toString().padLeft(2, '0');
          final stateClass = item.occupied ? 'occupied' : 'free';

          return '''
<button class="maternity-crate-hitbox" slot="hotspot-maternity-crate-hit-${item.number}" data-crate="${item.number}" data-position="${hitboxPosition.x}m ${hitboxPosition.y}m ${hitboxPosition.z}m" data-normal="0m 1m 0m" aria-label="Abrir jaula $number" onclick="event.preventDefault();event.stopPropagation();if(window.MaternityCrateNative&&window.MaternityCrateNative.postMessage){window.MaternityCrateNative.postMessage('${item.number}');}window.dispatchEvent(new CustomEvent('maternity-crate-tap',{detail:'${item.number}'}));document.dispatchEvent(new CustomEvent('maternity-crate-tap',{detail:'${item.number}'}));window.parent.postMessage(JSON.stringify({type:'maternity-crate-tap',crate:${item.number}}),'*');"></button>
<button class="maternity-crate-hotspot $stateClass" slot="hotspot-maternity-crate-${item.number}" data-crate="${item.number}" data-position="${position.x}m ${position.y}m ${position.z}m" data-normal="0m 1m 0m" aria-label="Abrir jaula $number" onclick="event.preventDefault();event.stopPropagation();if(window.MaternityCrateNative&&window.MaternityCrateNative.postMessage){window.MaternityCrateNative.postMessage('${item.number}');}window.dispatchEvent(new CustomEvent('maternity-crate-tap',{detail:'${item.number}'}));document.dispatchEvent(new CustomEvent('maternity-crate-tap',{detail:'${item.number}'}));window.parent.postMessage(JSON.stringify({type:'maternity-crate-tap',crate:${item.number}}),'*');">
  <span class="crate-number">$number</span>
  <span class="crate-tag">$tag</span>
  <span class="crate-status">$status</span>
</button>
''';
        })
        .join('\n');
  }

  _HotspotPosition _cratePosition(int number) {
    const xCenters = [-17.6, -8.8, 0.0, 8.8, 17.6];
    final rowIndex = number <= 5 ? number - 1 : number - 6;
    final x = xCenters[rowIndex.clamp(0, xCenters.length - 1)];
    final z = number <= 5 ? -5.8 : 5.8;
    return _HotspotPosition(x, 1.35, z);
  }

  _HotspotPosition _crateHitboxPosition(int number) {
    final labelPosition = _cratePosition(number);
    return _HotspotPosition(labelPosition.x, 0.72, labelPosition.z);
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static const String _baseCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #f1f2f1;
}
''';

  static const String _hotspotCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #f1f2f1;
}

.maternity-crate-hotspot {
  align-items: center;
  background: rgba(255, 255, 255, 0.72);
  border: 1px solid rgba(210, 224, 214, 0.72);
  border-radius: 9px;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
  color: #24332c;
  cursor: pointer;
  display: inline-grid;
  font: 800 10px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  gap: 1px;
  grid-template-columns: auto 1fr;
  line-height: 1.05;
  min-width: 68px;
  padding: 4px 6px;
  pointer-events: auto;
  text-align: left;
  transform: translate(-50%, -112%);
  white-space: nowrap;
}

.maternity-crate-hitbox {
  background: transparent;
  border: 0;
  cursor: pointer;
  display: block;
  height: 94px;
  opacity: 0;
  padding: 0;
  pointer-events: auto;
  transform: translate(-50%, -50%);
  width: 116px;
}

.maternity-crate-hitbox:focus,
.maternity-crate-hitbox:hover {
  background: transparent;
  box-shadow: none;
  outline: none;
}

.maternity-crate-hotspot:focus,
.maternity-crate-hotspot:hover {
  outline: none;
  box-shadow: 0 10px 26px rgba(15, 102, 70, 0.24);
}

.maternity-crate-hotspot .crate-number {
  align-items: center;
  border-radius: 6px;
  display: inline-flex;
  height: 20px;
  justify-content: center;
  margin-right: 5px;
  width: 24px;
}

.maternity-crate-hotspot.occupied .crate-number {
  background: #f59ab1;
  border: 1px solid #c94f73;
  color: #521428;
}

.maternity-crate-hotspot.free .crate-number {
  background: #e8f3ec;
  border: 1px solid #abc7b4;
  color: #31513d;
}

.maternity-crate-hotspot .crate-tag {
  color: #293c32;
  max-width: 76px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.maternity-crate-hotspot .crate-status {
  color: #587064;
  font-size: 8px;
  font-weight: 750;
  grid-column: 2;
  max-width: 76px;
  overflow: hidden;
  text-overflow: ellipsis;
}
''';

  static const String _hotspotJs = '''
(function () {
  function openCrate(crateNumber) {
    if (!crateNumber) return;
    const detail = String(crateNumber);
    if (window.MaternityCrateNative &&
        typeof window.MaternityCrateNative.postMessage === 'function') {
      window.MaternityCrateNative.postMessage(detail);
    }
    window.dispatchEvent(new CustomEvent('maternity-crate-tap', { detail }));
    document.dispatchEvent(new CustomEvent('maternity-crate-tap', { detail }));
    if (window.parent && window.parent !== window) {
      window.parent.dispatchEvent(new CustomEvent('maternity-crate-tap', {
        detail: detail
      }));
    }
    if (window.parent) {
      window.parent.postMessage(JSON.stringify({
        type: 'maternity-crate-tap',
        crate: Number(detail)
      }), '*');
    }
  }

  function wireViewer(viewer) {
    if (!viewer || viewer.__maternityCrateTapReady) return;
    if (!viewer.src || !viewer.src.includes('maternidad.glb')) return;
    viewer.__maternityCrateTapReady = true;

    const crates = [
      { id: 1, x: -17.6, z: -5.8, w: 7.8, d: 7.2 },
      { id: 2, x: -8.8, z: -5.8, w: 7.8, d: 7.2 },
      { id: 3, x: 0.0, z: -5.8, w: 7.8, d: 7.2 },
      { id: 4, x: 8.8, z: -5.8, w: 7.8, d: 7.2 },
      { id: 5, x: 17.6, z: -5.8, w: 7.8, d: 7.2 },
      { id: 6, x: -17.6, z: 5.8, w: 7.8, d: 7.2 },
      { id: 7, x: -8.8, z: 5.8, w: 7.8, d: 7.2 },
      { id: 8, x: 0.0, z: 5.8, w: 7.8, d: 7.2 },
      { id: 9, x: 8.8, z: 5.8, w: 7.8, d: 7.2 },
      { id: 10, x: 17.6, z: 5.8, w: 7.8, d: 7.2 }
    ];

    let pointerStart = null;

    viewer.addEventListener('pointerdown', function (event) {
      pointerStart = { x: event.clientX, y: event.clientY };
    });

    viewer.addEventListener('click', function (event) {
      const hotspot = event.target && event.target.closest
        ? event.target.closest('.maternity-crate-hotspot, .maternity-crate-hitbox')
        : null;
      if (hotspot) {
        event.preventDefault();
        event.stopPropagation();
        openCrate(hotspot.dataset.crate);
        return;
      }

      if (pointerStart) {
        const dragDistance = Math.hypot(
          event.clientX - pointerStart.x,
          event.clientY - pointerStart.y
        );
        if (dragDistance > 10) return;
      }

      if (typeof viewer.positionAndNormalFromPoint !== 'function') return;
      const hit = viewer.positionAndNormalFromPoint(event.clientX, event.clientY);
      if (!hit || !hit.position) return;

      const point = hit.position;
      const crate = crates.find(function (item) {
        return point.x >= item.x - item.w / 2 &&
          point.x <= item.x + item.w / 2 &&
          point.z >= item.z - item.d / 2 &&
          point.z <= item.z + item.d / 2;
      });

      if (!crate) return;
      event.preventDefault();
      event.stopPropagation();
      openCrate(crate.id);
    });
  }

  function wireAll() {
    document.querySelectorAll('model-viewer').forEach(wireViewer);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', wireAll, { once: true });
  } else {
    wireAll();
  }

  setTimeout(wireAll, 250);
  setTimeout(wireAll, 1000);
})();
''';
}

class MaternityModelCrateHotspot {
  const MaternityModelCrateHotspot({
    required this.number,
    required this.label,
    required this.status,
    required this.occupied,
  });

  final int number;
  final String label;
  final String status;
  final bool occupied;
}

class _HotspotPosition {
  const _HotspotPosition(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}
