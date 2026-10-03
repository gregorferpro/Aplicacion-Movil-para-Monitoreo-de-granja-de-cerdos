import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../controllers/farm_controllers.dart';

class ModelPreview extends StatelessWidget {
  const ModelPreview({super.key, required this.src});

  final String src;

  @override
  Widget build(BuildContext context) {
    final resolvedSrc = modelViewerWebAssetSrc(src);
    final isFarmModel = src.endsWith('farm.glb');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              src: resolvedSrc,
              alt: 'Vista previa 3D',
              cameraControls: true,
              cameraOrbit: isFarmModel
                  ? '-58deg 52deg 145m'
                  : '-40deg 55deg 32m',
              cameraTarget: '0m 2.0m 0m',
              autoRotate: !isFarmModel,
              autoRotateDelay: 1400,
              rotationPerSecond: isFarmModel ? '6deg' : '18deg',
              backgroundColor: isFarmModel
                  ? const Color(0xffdce9d7)
                  : const Color(0xffedf5f1),
              shadowIntensity: 0.9,
              shadowSoftness: 0.72,
              exposure: 1.15,
              fieldOfView: isFarmModel ? '30deg' : '32deg',
              minFieldOfView: isFarmModel ? '18deg' : '22deg',
              maxFieldOfView: isFarmModel ? '60deg' : '52deg',
              interactionPrompt: InteractionPrompt.auto,
              loading: Loading.eager,
              reveal: Reveal.auto,
              touchAction: TouchAction.none,
              innerModelViewerHtml: isFarmModel ? _farmHotspotsHtml : null,
              minHotspotOpacity: isFarmModel ? 0.2 : null,
              maxHotspotOpacity: isFarmModel ? 1.0 : null,
              relatedCss: isFarmModel ? _farmModelCss : _baseModelCss,
              relatedJs: isFarmModel ? _farmModelJs : null,
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xffdbe7df)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar, size: 18, color: Color(0xff176b4d)),
                    SizedBox(width: 8),
                    Text('GLB', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const String _baseModelCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #edf5f1;
}
''';

  static const String _farmModelCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #edf5f1;
}

.farm-label {
  align-items: center;
  background: rgba(238, 247, 238, 0.88);
  border: 1px solid rgba(205, 224, 211, 0.78);
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.10);
  color: rgba(33, 50, 41, 0.96);
  display: inline-flex;
  font: 800 11px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  gap: 5px;
  line-height: 1;
  min-height: 26px;
  min-width: 0;
  padding: 5px 8px;
  cursor: pointer;
  z-index: 10;
  pointer-events: none;
  transform: translate(-50%, -132%);
  white-space: nowrap;
}

.farm-label:hover,
.farm-label:focus {
  outline: none;
  background: rgba(238, 247, 238, 0.94);
  border-color: rgba(205, 224, 211, 0.9);
}

.farm-label::before {
  background: #176b4d;
  border-radius: 2px;
  box-shadow:
    5px 0 0 #176b4d,
    0 5px 0 #176b4d,
    5px 5px 0 #176b4d;
  content: "";
  height: 3px;
  width: 3px;
}

.farm-hitbox {
  background: transparent;
  border: 0;
  cursor: pointer;
  height: var(--hit-h);
  opacity: 0;
  padding: 0;
  pointer-events: auto;
  transform: translate(-50%, -50%);
  width: var(--hit-w);
}

.farm-hitbox:focus {
  outline: none;
}
''';

  static const String _farmHotspotsHtml = '''
<button class="farm-hitbox" slot="hotspot-hit-galpon" style="--hit-w: 132px; --hit-h: 58px;" data-position="-56m 2.2m -23m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'galpon'}),'*');" aria-label="Abrir Galpón"></button>
<button class="farm-hitbox" slot="hotspot-hit-engorde" style="--hit-w: 82px; --hit-h: 48px;" data-position="-20m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'engorde'}),'*');" aria-label="Abrir Engorde"></button>
<button class="farm-hitbox" slot="hotspot-hit-parrilla" style="--hit-w: 62px; --hit-h: 46px;" data-position="-3m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'parrilla'}),'*');" aria-label="Abrir Parrilla"></button>
<button class="farm-hitbox" slot="hotspot-hit-pre-destete" style="--hit-w: 70px; --hit-h: 46px;" data-position="11m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'pre-destete'}),'*');" aria-label="Abrir Pre Destete"></button>
<button class="farm-hitbox" slot="hotspot-hit-maternidad-1" style="--hit-w: 82px; --hit-h: 48px;" data-position="28m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'maternidad-1'}),'*');" aria-label="Abrir Maternidad 1"></button>
<button class="farm-hitbox" slot="hotspot-hit-gestacion" style="--hit-w: 136px; --hit-h: 48px;" data-position="57m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'gestacion'}),'*');" aria-label="Abrir Gestación"></button>
<button class="farm-hitbox" slot="hotspot-hit-maternidad-2" style="--hit-w: 128px; --hit-h: 46px;" data-position="55m 2.2m 21m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'maternidad-2'}),'*');" aria-label="Abrir Maternidad 2"></button>
<button class="farm-hitbox" slot="hotspot-hit-verracos" style="--hit-w: 48px; --hit-h: 44px;" data-position="73m 2.2m 21m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'verracos'}),'*');" aria-label="Abrir Verracos"></button>
<button class="farm-label" slot="hotspot-galpon" data-target="galpon" data-position="-56m 5.6m -23m" data-normal="0m 1m 0m">Galpón</button>
<button class="farm-label" slot="hotspot-engorde" data-target="engorde" data-position="-20m 6.2m 5m" data-normal="0m 1m 0m">Engorde</button>
<button class="farm-label" slot="hotspot-parrilla" data-target="parrilla" data-position="-3m 6.1m 5m" data-normal="0m 1m 0m">Parrilla</button>
<button class="farm-label" slot="hotspot-pre-destete" data-target="pre-destete" data-position="11m 6.1m 5m" data-normal="0m 1m 0m">Pre Destete</button>
<button class="farm-label" slot="hotspot-maternidad-1" data-target="maternidad-1" data-position="28m 6.2m 5m" data-normal="0m 1m 0m">Maternidad 1</button>
<button class="farm-label" slot="hotspot-gestacion" data-target="gestacion" data-position="57m 5.6m 5m" data-normal="0m 1m 0m">Gestación</button>
<button class="farm-label" slot="hotspot-maternidad-2" data-target="maternidad-2" data-position="55m 5.5m 21m" data-normal="0m 1m 0m">Maternidad 2</button>
<button class="farm-label" slot="hotspot-verracos" data-target="verracos" data-position="73m 6.0m 21m" data-normal="0m 1m 0m">Verracos</button>
''';

  static const String _farmModelJs = '''
(function () {
  function wireViewer(viewer) {
    if (!viewer || viewer.__farmTapReady) return;
    if (!viewer.src || !viewer.src.includes('farm.glb')) return;
    viewer.__farmTapReady = true;

    const buildings = [
    { id: 'galpon', x: -56, z: -23, w: 26, d: 12 },
    { id: 'engorde', x: -20, z: 5, w: 16, d: 10 },
    { id: 'parrilla', x: -3, z: 5, w: 11, d: 10 },
    { id: 'pre-destete', x: 11, z: 5, w: 12, d: 10 },
    { id: 'maternidad-1', x: 28, z: 5, w: 16, d: 10 },
    { id: 'gestacion', x: 57, z: 5, w: 32, d: 10 },
    { id: 'maternidad-2', x: 55, z: 21, w: 30, d: 9 },
    { id: 'verracos', x: 73, z: 21, w: 7, d: 9 }
  ];

    let pointerStart = null;

    function openFarmTarget(target) {
      if (!target) return;
      const event = new CustomEvent('farm-building-tap', { detail: target });
      window.dispatchEvent(event);
      if (window.parent && window.parent !== window) {
        window.parent.dispatchEvent(new CustomEvent('farm-building-tap', {
          detail: target
        }));
      }
    }

    viewer.addEventListener('click', function (event) {
      const label = event.target && event.target.closest
        ? event.target.closest('.farm-label')
        : null;
      if (label) {
        const slot = label.getAttribute('slot') || '';
        const target = label.dataset.target || slot.replace('hotspot-', '');
        event.preventDefault();
        event.stopPropagation();
        openFarmTarget(target);
        return;
      }
    });

    viewer.addEventListener('pointerdown', function (event) {
      pointerStart = { x: event.clientX, y: event.clientY };
    });

    viewer.addEventListener('click', function (event) {
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
      const margin = 0.35;
      const matches = buildings.filter(function (item) {
        return point.x >= item.x - item.w / 2 - margin &&
          point.x <= item.x + item.w / 2 + margin &&
          point.z >= item.z - item.d / 2 - margin &&
          point.z <= item.z + item.d / 2 + margin;
      }).map(function (item) {
        const dx = point.x - item.x;
        const dz = point.z - item.z;
        return {
          item: item,
          area: item.w * item.d,
          distance: Math.hypot(dx / item.w, dz / item.d)
        };
      }).sort(function (a, b) {
        if (a.area !== b.area) return a.area - b.area;
        return a.distance - b.distance;
      });

      const building = matches.length ? matches[0].item : null;

      if (!building) return;
      event.preventDefault();
      event.stopPropagation();
      openFarmTarget(building.id);
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
})();
''';
}
