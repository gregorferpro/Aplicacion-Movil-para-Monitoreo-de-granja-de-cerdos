import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'boar_corral_bridge.dart';
import 'farm_building_bridge.dart';
import 'feed_feeder_bridge.dart';
import 'gestation_crate_bridge.dart';
import 'maternity_crate_bridge.dart';
import 'data/local_database.dart';
import 'pages/galpon_inventory_page.dart';
import 'pre_destete_corral_bridge.dart';
import 'repositories/production_cost_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/dashboard_widgets.dart';
import 'widgets/maternity_model_viewer.dart';
import 'widgets/mobile_pig_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localDatabase.initialize();
  await _restoreBoarRecords();
  await productionCostRepository.initializePersistence();
  runApp(const CabanaApp());
}

List<Map<String, dynamic>> _jsonMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

class CabanaApp extends StatelessWidget {
  const CabanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIPOR 360 · Cabaña La Pampita',
      theme: AppTheme.light,
      home: const CabanaShell(),
    );
  }
}

class CabanaShell extends StatefulWidget {
  const CabanaShell({super.key});

  @override
  State<CabanaShell> createState() => _CabanaShellState();
}

class _CabanaShellState extends State<CabanaShell> {
  int _index = 0;

  static const _mobileItems = <PigNavigationItem>[
    PigNavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Inicio',
    ),
    PigNavigationItem(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
      label: 'Granja',
    ),
    PigNavigationItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      label: 'Registros',
    ),
    PigNavigationItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Inventario',
    ),
    PigNavigationItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Costos',
    ),
  ];

  void _selectDestination(int value) {
    if (value < 3) {
      setState(() => _index = value);
      return;
    }

    final page = GalponInventoryPage(initialTab: value == 3 ? 0 : 6);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openInventoryAction(GalponInventoryInitialAction action) {
    final initialTab = action == GalponInventoryInitialAction.purchase ? 0 : 3;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GalponInventoryPage(initialTab: initialTab, initialAction: action),
      ),
    );
  }

  Future<void> _openFarrowingAction() async {
    final maternity = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Registrar parto',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Elige la maternidad y luego toca la jaula ocupada.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.child_friendly_outlined),
              title: const Text('Maternidad 1'),
              subtitle: const Text('10 jaulas - 5 por lado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(sheetContext, 1),
            ),
            ListTile(
              leading: const Icon(Icons.child_friendly_outlined),
              title: const Text('Maternidad 2'),
              subtitle: const Text('10 jaulas - 5 por lado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(sheetContext, 2),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || maternity == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MaternityBarnPage(title: 'Maternidad $maternity'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).shortestSide < 600;
    final currentPage = switch (_index) {
      0 => DashboardPage(
        onOpenFarm: () => setState(() => _index = 1),
        onIngreso: () =>
            _openInventoryAction(GalponInventoryInitialAction.purchase),
        onConsumo: () =>
            _openInventoryAction(GalponInventoryInitialAction.consumption),
        onVacuna: () =>
            _openInventoryAction(GalponInventoryInitialAction.vaccination),
        onParto: _openFarrowingAction,
      ),
      1 => const FarmMapPage(),
      _ => const RecordsPage(),
    };

    return Scaffold(
      appBar: AppBar(title: DashboardHeader(onAlerts: () {})),
      // Keep only the visible GLB/WebView mounted. Mounting the dashboard and
      // farm viewers together can leave stale inherited dependencies during a
      // hot restart on Android.
      body: currentPage,
      bottomNavigationBar: isMobile
          ? PigBottomNavigationBar(
              selectedIndex: _index,
              onSelected: _selectDestination,
              items: _mobileItems,
            )
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _selectDestination,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Granja',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Registros',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Inventario',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Costos',
                ),
              ],
            ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onOpenFarm,
    required this.onIngreso,
    required this.onConsumo,
    required this.onVacuna,
    required this.onParto,
    this.farmPreview,
  });

  final VoidCallback onOpenFarm;
  final VoidCallback onIngreso;
  final VoidCallback onConsumo;
  final VoidCallback onVacuna;
  final VoidCallback onParto;
  final Widget? farmPreview;

  static const _farmLabels = [
    'Galpón',
    'Engorde',
    'Parrilla',
    'Pre-destete',
    'Maternidad 1',
    'Maternidad 2',
    'Verracos',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxWidth < 600;
          final pagePadding = compact ? 16.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pagePadding, 10, pagePadding, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DashboardGreeting(
                      name: 'Alejandro',
                      subtitle: 'Bienvenido a Cabaña La Pampita',
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Resumen de hoy'),
                    const SizedBox(height: 12),
                    const _PremiumStatsGrid(),
                    const SizedBox(height: 24),
                    FarmMapCard(
                      labels: _farmLabels,
                      onOpen: onOpenFarm,
                      title: 'Ubicación de la granja',
                      subtitle: 'Cabaña La Pampita · Bolivia',
                      status: 'Todo en orden',
                      child:
                          farmPreview ??
                          const ModelPreview(
                            src: 'assets/models/farm.glb',
                            framed: false,
                            showBadge: false,
                            showFarmLabels: false,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Acciones rápidas'),
                    const SizedBox(height: 12),
                    _PremiumQuickActions(
                      onIngreso: onIngreso,
                      onConsumo: onConsumo,
                      onVacuna: onVacuna,
                      onParto: onParto,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      title: 'Pendientes',
                      action: 'Ver todos',
                    ),
                    const SizedBox(height: 12),
                    const _PremiumAlertList(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumStatsGrid extends StatelessWidget {
  const _PremiumStatsGrid();

  @override
  Widget build(BuildContext context) {
    const cards = [
      StatCard(
        value: '1.284',
        label: 'Animales',
        detail: '+42 esta semana',
        icon: Icons.cruelty_free_outlined,
        color: AppPalette.accent,
      ),
      StatCard(
        value: '214',
        label: 'Madres',
        detail: '+8 esta semana',
        icon: Icons.female_outlined,
        color: AppPalette.mothers,
      ),
      StatCard(
        value: '18.6 t',
        label: 'Alimento',
        detail: 'Disponible',
        icon: Icons.bar_chart_rounded,
        color: AppPalette.primary,
      ),
      StatCard(
        value: 'Bs 8.450',
        label: 'Costo hoy',
        detail: 'Producción diaria',
        icon: Icons.monetization_on_outlined,
        color: AppPalette.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 330 ? 4 : 2;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: width, height: 124, child: card),
          ],
        );
      },
    );
  }
}

class _PremiumQuickActions extends StatelessWidget {
  const _PremiumQuickActions({
    required this.onIngreso,
    required this.onConsumo,
    required this.onVacuna,
    required this.onParto,
  });

  final VoidCallback onIngreso;
  final VoidCallback onConsumo;
  final VoidCallback onVacuna;
  final VoidCallback onParto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 2 : 4;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final actions = [
          (
            label: 'Ingreso',
            icon: Icons.add_task_rounded,
            color: AppPalette.primary,
            onTap: onIngreso,
          ),
          (
            label: 'Consumo',
            icon: Icons.scale_outlined,
            color: AppPalette.inventory,
            onTap: onConsumo,
          ),
          (
            label: 'Vacuna',
            icon: Icons.vaccines_outlined,
            color: AppPalette.mothers,
            onTap: onVacuna,
          ),
          (
            label: 'Parto',
            icon: Icons.child_friendly_outlined,
            color: AppPalette.accent,
            onTap: onParto,
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              SizedBox(
                key: ValueKey('quick-action-${action.label.toLowerCase()}'),
                width: width,
                height: 104,
                child: QuickActionCard(
                  label: action.label,
                  icon: action.icon,
                  color: action.color,
                  onTap: action.onTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PremiumAlertList extends StatelessWidget {
  const _PremiumAlertList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.outline),
        boxShadow: AppPalette.cardShadow,
      ),
      child: const Column(
        children: [
          PendingAlertCard(
            title: 'Vencimiento de vacuna Parvovirus',
            detail: 'Maternidad 1 · Cerdas',
            time: 'Hoy',
            priority: 'Alta',
            icon: Icons.monitor_heart_outlined,
            color: AppPalette.alert,
            embedded: true,
            onTap: _noAction,
          ),
          Divider(indent: 64),
          PendingAlertCard(
            title: 'Bajo stock de alimento',
            detail: 'Silo 2 · Balanceado gestación',
            time: '1 día',
            priority: 'Media',
            icon: Icons.inventory_2_outlined,
            color: AppPalette.inventory,
            embedded: true,
            onTap: _noAction,
          ),
          Divider(indent: 64),
          PendingAlertCard(
            title: 'Revisión de engorde',
            detail: 'Lote 3 · 120 animales',
            time: '2 días',
            priority: 'Normal',
            icon: Icons.fact_check_outlined,
            color: AppPalette.primary,
            embedded: true,
            onTap: _noAction,
          ),
        ],
      ),
    );
  }
}

void _noAction() {}

class FarmMapPage extends StatefulWidget {
  const FarmMapPage({super.key});

  @override
  State<FarmMapPage> createState() => _FarmMapPageState();
}

class _FarmMapPageState extends State<FarmMapPage> {
  @override
  void initState() {
    super.initState();
    FarmBuildingBridge.register(_openFarmBuildingTarget);
  }

  @override
  void dispose() {
    FarmBuildingBridge.unregister(_openFarmBuildingTarget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            const _SectionTitle(title: 'Diseño de la cabaña', action: '3D'),
            const SizedBox(height: 10),
            Expanded(
              child: ModelPreview(
                src: 'assets/models/farm.glb',
                onFarmBuildingTap: _openFarmBuildingTarget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFarmBuildingTarget(String target) {
    if (!mounted) return;
    final Widget? page = switch (target) {
      'galpon' => const GalponInventoryPage(),
      'engorde' => const Engorde3DPage(),
      'parrilla' => const Parrilla3DPage(),
      'pre-destete' => const PreDestete3DPage(),
      'maternidad-1' => const MaternityBarnPage(title: 'Maternidad 1'),
      'gestacion' => const GestationBarnPage(),
      'maternidad-2' => const MaternityBarnPage(title: 'Maternidad 2'),
      'verracos' => const BoarBarnPage(),
      _ => null,
    };
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.swap_horiz), text: 'Movimientos'),
                  Tab(
                    icon: Icon(Icons.medical_services_outlined),
                    text: 'Sanidad',
                  ),
                  Tab(icon: Icon(Icons.task_alt), text: 'Tareas'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _RecordList(items: _movementItems),
                  _RecordList(items: _healthItems),
                  _RecordList(items: _taskItems),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedFarmMap extends StatefulWidget {
  const AnimatedFarmMap({super.key, this.compact = false});

  final bool compact;

  @override
  State<AnimatedFarmMap> createState() => _AnimatedFarmMapState();
}

class _AnimatedFarmMapState extends State<AnimatedFarmMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _pan = Offset.zero;
  double _zoom = 1;
  double _startZoom = 1;
  double _rotation = -0.03;
  double _tilt = .38;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Listener(
            onPointerMove: widget.compact
                ? null
                : (event) {
                    if (event.buttons == kSecondaryMouseButton) {
                      setState(() => _pan += event.delta);
                    }
                  },
            onPointerSignal: widget.compact
                ? null
                : (event) {
                    if (event is PointerScrollEvent) {
                      final direction = event.scrollDelta.dy < 0 ? .1 : -.1;
                      setState(() {
                        _zoom = (_zoom + direction).clamp(.65, 2.5);
                      });
                    }
                  },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: widget.compact
                  ? null
                  : (_) {
                      _startZoom = _zoom;
                    },
              onScaleUpdate: widget.compact
                  ? null
                  : (details) {
                      setState(() {
                        _zoom = (_startZoom * details.scale).clamp(0.65, 2.5);
                        if (details.pointerCount > 1) {
                          _pan += details.focalPointDelta;
                        } else {
                          _rotation += details.focalPointDelta.dx * .01;
                          _tilt = (_tilt + details.focalPointDelta.dy * .003)
                              .clamp(.24, .56);
                        }
                      });
                    },
              onTapUp: widget.compact
                  ? null
                  : (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) {
                        return;
                      }
                      final building = _hitBuilding(
                        details.localPosition,
                        box.size,
                      );
                      if (building != null) {
                        _openBuilding(building);
                      }
                    },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: FarmPainter(
                      progress: _controller.value,
                      compact: widget.compact,
                      pan: widget.compact ? Offset.zero : _pan,
                      zoom: widget.compact ? 1.05 : _zoom,
                      rotation: widget.compact ? -0.03 : _rotation,
                      tilt: widget.compact ? .38 : _tilt,
                      showLabels: !widget.compact,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
          if (!widget.compact) ...[
            Positioned(
              left: 12,
              top: 12,
              child: _MapHint(
                zoom: _zoom,
                onReset: () {
                  setState(() {
                    _pan = Offset.zero;
                    _zoom = 1;
                    _rotation = -0.03;
                    _tilt = .38;
                  });
                },
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: _MapControls(
                onZoomIn: () {
                  setState(() => _zoom = (_zoom + .15).clamp(.65, 2.5));
                },
                onZoomOut: () {
                  setState(() => _zoom = (_zoom - .15).clamp(.65, 2.5));
                },
                onRotateLeft: () => setState(() => _rotation -= .12),
                onRotateRight: () => setState(() => _rotation += .12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  FarmBuilding? _hitBuilding(Offset point, Size size) {
    final scale = math.min(size.width / 136, size.height / 92) * _zoom;
    final center = Offset(size.width * 0.5, size.height * 0.5) + _pan;
    final cosR = math.cos(_rotation);
    final sinR = math.sin(_rotation);

    Offset project(double px, double pz) {
      final rx = px * cosR - pz * sinR;
      final rz = px * sinR + pz * cosR;
      return Offset(
        center.dx + (rx - rz) * scale * 0.82,
        center.dy + (rx + rz) * scale * _tilt,
      );
    }

    const clickable = {
      'Engorde',
      'Pre Destete',
      'Gestación',
      'Maternidad 1',
      'Maternidad 2',
      'Verracos',
    };
    FarmBuilding? hit;
    var nearest = double.infinity;

    for (final building in FarmPainter.buildings.where(
      (building) => clickable.contains(building.name),
    )) {
      final halfW = building.width / 2;
      final halfD = building.depth / 2;
      final lift = Offset(0, -building.height * 1.55 * scale);
      final corners = [
        project(building.x - halfW, building.z - halfD),
        project(building.x + halfW, building.z - halfD),
        project(building.x + halfW, building.z + halfD),
        project(building.x - halfW, building.z + halfD),
      ];
      final points = [...corners, ...corners.map((corner) => corner + lift)];

      var bounds = Rect.fromPoints(points.first, points.first);
      for (final p in points.skip(1)) {
        bounds = bounds.expandToInclude(Rect.fromPoints(p, p));
      }
      if (bounds
          .inflate(building.name == 'Verracos' ? 30 : 22)
          .contains(point)) {
        final centerPoint = project(building.x, building.z) + lift * .5;
        final distance = (point - centerPoint).distance;
        if (distance < nearest) {
          nearest = distance;
          hit = building;
        }
      }
    }
    return hit;
  }

  void _openBuilding(FarmBuilding building) {
    final Widget page = switch (building.name) {
      'Engorde' => const Engorde3DPage(),
      'Parrilla' => const Parrilla3DPage(),
      'Gestación' => const GestationBarnPage(),
      'Pre Destete' => const PreDestete3DPage(),
      'Maternidad 1' => const MaternityBarnPage(title: 'Maternidad 1'),
      'Maternidad 2' => const MaternityBarnPage(title: 'Maternidad 2'),
      'Verracos' => const BoarBarnPage(),
      _ => const FarmMapPage(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.zoom, required this.onReset});

  final double zoom;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdbe7df)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_with, size: 18, color: Color(0xff176b4d)),
            const SizedBox(width: 8),
            Text(
              '${(zoom * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Restablecer vista',
              visualDensity: VisualDensity.compact,
              onPressed: onReset,
              icon: const Icon(Icons.center_focus_strong, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRotateLeft,
    required this.onRotateRight,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdbe7df)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Acercar',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Alejar',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Girar izquierda',
            onPressed: onRotateLeft,
            icon: const Icon(Icons.rotate_left),
          ),
          IconButton(
            tooltip: 'Girar derecha',
            onPressed: onRotateRight,
            icon: const Icon(Icons.rotate_right),
          ),
        ],
      ),
    );
  }
}

class Engorde3DPage extends StatefulWidget {
  const Engorde3DPage({super.key});

  @override
  State<Engorde3DPage> createState() => _Engorde3DPageState();
}

class Parrilla3DPage extends StatefulWidget {
  const Parrilla3DPage({super.key});

  @override
  State<Parrilla3DPage> createState() => _Parrilla3DPageState();
}

class _FeederRecord {
  const _FeederRecord({
    required this.barnId,
    required this.corralNumber,
    required this.feederNumber,
    this.feedName = '',
    this.quantityKg = 0,
    this.updatedAt,
  });

  final String barnId;
  final int corralNumber;
  final int feederNumber;
  final String feedName;
  final double quantityKg;
  final DateTime? updatedAt;

  bool get hasFeed => feedName.trim().isNotEmpty && quantityKg > 0;

  _FeederRecord copyWith({
    String? feedName,
    double? quantityKg,
    DateTime? updatedAt,
  }) {
    return _FeederRecord(
      barnId: barnId,
      corralNumber: corralNumber,
      feederNumber: feederNumber,
      feedName: feedName ?? this.feedName,
      quantityKg: quantityKg ?? this.quantityKg,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  _FeederRecord cleared() {
    return _FeederRecord(
      barnId: barnId,
      corralNumber: corralNumber,
      feederNumber: feederNumber,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'barnId': barnId,
    'corralNumber': corralNumber,
    'feederNumber': feederNumber,
    'feedName': feedName,
    'quantityKg': quantityKg,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory _FeederRecord.fromJson(Map<String, dynamic> json) {
    return _FeederRecord(
      barnId: json['barnId'] as String? ?? '',
      corralNumber: (json['corralNumber'] as num?)?.toInt() ?? 0,
      feederNumber: (json['feederNumber'] as num?)?.toInt() ?? 0,
      feedName: json['feedName'] as String? ?? '',
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

List<_FeederRecord> _createFeederRecords(
  String barnId, {
  int corralCount = 4,
  int feedersPerCorral = 2,
}) {
  return [
    for (var corral = 1; corral <= corralCount; corral++)
      for (var feeder = 1; feeder <= feedersPerCorral; feeder++)
        _FeederRecord(
          barnId: barnId,
          corralNumber: corral,
          feederNumber: feeder,
        ),
  ];
}

class PreDestete3DPage extends StatefulWidget {
  const PreDestete3DPage({super.key});

  @override
  State<PreDestete3DPage> createState() => _PreDestete3DPageState();
}

String modelViewerWebAssetSrc(String assetPath) {
  if (!kIsWeb) return assetPath;

  if (assetPath.startsWith('/') ||
      assetPath.startsWith(RegExp(r'^[a-zA-Z]+://')) ||
      assetPath.startsWith('data:')) {
    return assetPath;
  }

  final normalized = assetPath.replaceAll(RegExp(r'^/+'), '');
  final webPath = normalized.startsWith('assets/')
      ? 'assets/$normalized'
      : normalized;
  return Uri.base.resolve(webPath).toString();
}

JavascriptChannel _feedFeederNativeChannel(
  void Function(String barnId, int corralNumber, int feederNumber) onTap,
) {
  return JavascriptChannel(
    'FeedFeederNative',
    onMessageReceived: (message) {
      final parts = message.message.trim().split('|');
      if (parts.length != 3) return;
      final corralNumber = int.tryParse(parts[1]);
      final feederNumber = int.tryParse(parts[2]);
      if (corralNumber == null || feederNumber == null) return;
      onTap(parts[0], corralNumber, feederNumber);
    },
  );
}

JavascriptChannel _numberTapNativeChannel(
  String name,
  ValueChanged<int> onTap,
) {
  return JavascriptChannel(
    name,
    onMessageReceived: (message) {
      final number = int.tryParse(message.message.trim());
      if (number != null && number > 0) onTap(number);
    },
  );
}

class ModelPreview extends StatelessWidget {
  const ModelPreview({
    super.key,
    required this.src,
    this.framed = true,
    this.showBadge = true,
    this.showFarmLabels = true,
    this.onFarmBuildingTap,
  });

  final String src;
  final bool framed;
  final bool showBadge;
  final bool showFarmLabels;
  final ValueChanged<String>? onFarmBuildingTap;

  @override
  Widget build(BuildContext context) {
    final resolvedSrc = modelViewerWebAssetSrc(src);
    final isFarmModel = src.endsWith('farm.glb');
    final preview = Stack(
      children: [
        Positioned.fill(
          child: ModelViewer(
            src: resolvedSrc,
            alt: 'Vista previa 3D',
            cameraControls: true,
            cameraOrbit: isFarmModel ? '-58deg 52deg 145m' : '-40deg 55deg 32m',
            cameraTarget: isFarmModel ? '0m 2.0m 0m' : '0m 2.0m 0m',
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
            relatedCss: isFarmModel
                ? '$_farmModelCss${showFarmLabels ? '' : _hiddenFarmLabelsCss}'
                : _baseModelCss,
            relatedJs: isFarmModel ? _farmModelJs : null,
            javascriptChannels:
                isFarmModel && !kIsWeb && onFarmBuildingTap != null
                ? {
                    JavascriptChannel(
                      'FarmBuildingBridge',
                      onMessageReceived: (message) {
                        final target = message.message.trim();
                        if (target.isNotEmpty) onFarmBuildingTap!(target);
                      },
                    ),
                  }
                : null,
          ),
        ),
        if (showBadge)
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
    );

    if (!framed) return preview;

    return Card(clipBehavior: Clip.antiAlias, child: preview);
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
  background: rgba(250, 252, 249, 0.92);
  border: 1px solid rgba(205, 224, 211, 0.84);
  border-radius: 6px;
  box-shadow: 0 3px 9px rgba(0, 0, 0, 0.09);
  color: rgba(33, 50, 41, 0.96);
  display: inline-flex;
  font: 800 9px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  gap: 4px;
  line-height: 1;
  min-height: 21px;
  min-width: 0;
  padding: 4px 6px;
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
    4px 0 0 #176b4d,
    0 4px 0 #176b4d,
    4px 4px 0 #176b4d;
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

  static const String _hiddenFarmLabelsCss = '''
.farm-label {
  display: none !important;
}
''';

  static const String _farmHotspotsHtml = '''
<button class="farm-hitbox" slot="hotspot-hit-galpon" style="--hit-w: 132px; --hit-h: 58px;" data-position="-56m 2.2m -23m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('galpon');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'galpon'}),'*');" aria-label="Abrir Galpón"></button>
<button class="farm-hitbox" slot="hotspot-hit-engorde" style="--hit-w: 82px; --hit-h: 48px;" data-position="-20m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('engorde');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'engorde'}),'*');" aria-label="Abrir Engorde"></button>
<button class="farm-hitbox" slot="hotspot-hit-parrilla" style="--hit-w: 62px; --hit-h: 46px;" data-position="-3m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('parrilla');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'parrilla'}),'*');" aria-label="Abrir Parrilla"></button>
<button class="farm-hitbox" slot="hotspot-hit-pre-destete" style="--hit-w: 70px; --hit-h: 46px;" data-position="11m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('pre-destete');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'pre-destete'}),'*');" aria-label="Abrir Pre Destete"></button>
<button class="farm-hitbox" slot="hotspot-hit-maternidad-1" style="--hit-w: 82px; --hit-h: 48px;" data-position="28m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('maternidad-1');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'maternidad-1'}),'*');" aria-label="Abrir Maternidad 1"></button>
<button class="farm-hitbox" slot="hotspot-hit-gestacion" style="--hit-w: 136px; --hit-h: 48px;" data-position="57m 2.2m 5m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('gestacion');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'gestacion'}),'*');" aria-label="Abrir Gestación"></button>
<button class="farm-hitbox" slot="hotspot-hit-maternidad-2" style="--hit-w: 128px; --hit-h: 46px;" data-position="55m 2.2m 21m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('maternidad-2');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'maternidad-2'}),'*');" aria-label="Abrir Maternidad 2"></button>
<button class="farm-hitbox" slot="hotspot-hit-verracos" style="--hit-w: 48px; --hit-h: 44px;" data-position="73m 2.2m 21m" data-normal="0m 1m 0m" onclick="event.preventDefault();event.stopPropagation();if(window.FarmBuildingBridge){window.FarmBuildingBridge.postMessage('verracos');}window.parent.postMessage(JSON.stringify({type:'farm-building-tap',target:'verracos'}),'*');" aria-label="Abrir Verracos"></button>
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
      if (window.FarmBuildingBridge &&
          typeof window.FarmBuildingBridge.postMessage === 'function') {
        window.FarmBuildingBridge.postMessage(target);
      }
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

class _Engorde3DPageState extends State<Engorde3DPage> {
  int _viewerVersion = 0;
  late List<_FeederRecord> _feeders;

  @override
  void initState() {
    super.initState();
    _feeders = _createFeederRecords('engorde');
    FeedFeederBridge.register(_openFeederByTap);
    _restoreFeeders();
  }

  Future<void> _restoreFeeders() async {
    final snapshot = await localDatabase.readSnapshot('comederos_engorde');
    final restored = _jsonMapList(snapshot?['feeders'])
        .map(_FeederRecord.fromJson)
        .where((item) => item.barnId == 'engorde')
        .toList();
    if (!mounted || restored.isEmpty) return;
    setState(() => _feeders = restored);
  }

  void _persistFeeders() {
    localDatabase.scheduleSnapshot('comederos_engorde', <String, dynamic>{
      'feeders': _feeders.map((item) => item.toJson()).toList(),
    });
  }

  @override
  void dispose() {
    FeedFeederBridge.unregister(_openFeederByTap);
    super.dispose();
  }

  void _resetView() {
    setState(() {
      _viewerVersion++;
    });
  }

  void _openFeederByTap(String barnId, int corralNumber, int feederNumber) {
    if (!mounted || barnId != 'engorde') return;
    final feeder = _findFeeder(corralNumber, feederNumber);
    if (feeder == null) return;
    _openFeederEditor(feeder);
  }

  _FeederRecord? _findFeeder(int corralNumber, int feederNumber) {
    for (final feeder in _feeders) {
      if (feeder.corralNumber == corralNumber &&
          feeder.feederNumber == feederNumber) {
        return feeder;
      }
    }
    return null;
  }

  Future<void> _openFeederEditor(_FeederRecord feeder) async {
    final updated = await _showFeederEditor(
      context: context,
      title: 'Engorde - Corral ${feeder.corralNumber}',
      feeder: feeder,
    );
    if (updated == null || !mounted) return;
    setState(() {
      _feeders = [
        for (final item in _feeders)
          if (item.corralNumber == updated.corralNumber &&
              item.feederNumber == updated.feederNumber)
            updated
          else
            item,
      ];
    });
    _persistFeeders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engorde',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '4 corrales - 2 por lado',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Restablecer vista',
            onPressed: _resetView,
            icon: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              const _SectionTitle(title: 'Galpón de engorde', action: '3D'),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ModelViewer(
                          key: ValueKey(_viewerVersion),
                          src: modelViewerWebAssetSrc(
                            'assets/models/engorde.glb',
                          ),
                          alt: 'Modelo 3D del galpón de engorde con 4 corrales',
                          cameraControls: true,
                          cameraOrbit: '-42deg 58deg 33m',
                          cameraTarget: '0m 1.6m 0m',
                          autoRotate: false,
                          backgroundColor: const Color(0xffedf5f1),
                          shadowIntensity: 0.95,
                          shadowSoftness: 0.74,
                          exposure: 1.12,
                          fieldOfView: '31deg',
                          minFieldOfView: '20deg',
                          maxFieldOfView: '54deg',
                          interactionPrompt: InteractionPrompt.auto,
                          loading: Loading.eager,
                          reveal: Reveal.auto,
                          touchAction: TouchAction.none,
                          innerModelViewerHtml:
                              _FeedableBarnGlbPreview.hotspotsHtml(
                                'engorde',
                                _feeders,
                              ),
                          minHotspotOpacity: 0.18,
                          maxHotspotOpacity: 1,
                          relatedCss: _FeedableBarnGlbPreview.modelCss,
                          relatedJs: _FeedableBarnGlbPreview.modelJs,
                          javascriptChannels: !kIsWeb
                              ? {_feedFeederNativeChannel(_openFeederByTap)}
                              : null,
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.view_in_ar,
                                  size: 18,
                                  color: Color(0xff176b4d),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'GLB',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FilledButton.icon(
                          onPressed: _resetView,
                          icon: const Icon(Icons.center_focus_strong),
                          label: const Text('Vista inicial'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Parrilla3DPageState extends State<Parrilla3DPage> {
  int _viewerVersion = 0;
  late List<_FeederRecord> _feeders;

  @override
  void initState() {
    super.initState();
    _feeders = _createFeederRecords('parrilla');
    FeedFeederBridge.register(_openFeederByTap);
    _restoreFeeders();
  }

  Future<void> _restoreFeeders() async {
    final snapshot = await localDatabase.readSnapshot('comederos_parrilla');
    final restored = _jsonMapList(snapshot?['feeders'])
        .map(_FeederRecord.fromJson)
        .where((item) => item.barnId == 'parrilla')
        .toList();
    if (!mounted || restored.isEmpty) return;
    setState(() => _feeders = restored);
  }

  void _persistFeeders() {
    localDatabase.scheduleSnapshot('comederos_parrilla', <String, dynamic>{
      'feeders': _feeders.map((item) => item.toJson()).toList(),
    });
  }

  @override
  void dispose() {
    FeedFeederBridge.unregister(_openFeederByTap);
    super.dispose();
  }

  void _resetView() {
    setState(() {
      _viewerVersion++;
    });
  }

  void _openFeederByTap(String barnId, int corralNumber, int feederNumber) {
    if (!mounted || barnId != 'parrilla') return;
    final feeder = _findFeeder(corralNumber, feederNumber);
    if (feeder == null) return;
    _openFeederEditor(feeder);
  }

  _FeederRecord? _findFeeder(int corralNumber, int feederNumber) {
    for (final feeder in _feeders) {
      if (feeder.corralNumber == corralNumber &&
          feeder.feederNumber == feederNumber) {
        return feeder;
      }
    }
    return null;
  }

  Future<void> _openFeederEditor(_FeederRecord feeder) async {
    final updated = await _showFeederEditor(
      context: context,
      title: 'Parrilla - Corral ${feeder.corralNumber}',
      feeder: feeder,
    );
    if (updated == null || !mounted) return;
    setState(() {
      _feeders = [
        for (final item in _feeders)
          if (item.corralNumber == updated.corralNumber &&
              item.feederNumber == updated.feederNumber)
            updated
          else
            item,
      ];
    });
    _persistFeeders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parrilla',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '4 corrales - 2 por lado',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Restablecer vista',
            onPressed: _resetView,
            icon: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              const _SectionTitle(title: 'Galpón de parrilla', action: '3D'),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ModelViewer(
                          key: ValueKey(_viewerVersion),
                          src: modelViewerWebAssetSrc(
                            'assets/models/parrilla.glb',
                          ),
                          alt:
                              'Modelo 3D del galpón de parrilla con 4 corrales',
                          cameraControls: true,
                          cameraOrbit: '-42deg 58deg 30m',
                          cameraTarget: '0m 1.25m 0m',
                          autoRotate: false,
                          backgroundColor: const Color(0xffedf5f1),
                          shadowIntensity: 0.95,
                          shadowSoftness: 0.74,
                          exposure: 1.12,
                          fieldOfView: '31deg',
                          minFieldOfView: '20deg',
                          maxFieldOfView: '54deg',
                          interactionPrompt: InteractionPrompt.auto,
                          loading: Loading.eager,
                          reveal: Reveal.auto,
                          touchAction: TouchAction.none,
                          innerModelViewerHtml:
                              _FeedableBarnGlbPreview.hotspotsHtml(
                                'parrilla',
                                _feeders,
                              ),
                          minHotspotOpacity: 0.18,
                          maxHotspotOpacity: 1,
                          relatedCss: _FeedableBarnGlbPreview.modelCss,
                          relatedJs: _FeedableBarnGlbPreview.modelJs,
                          javascriptChannels: !kIsWeb
                              ? {_feedFeederNativeChannel(_openFeederByTap)}
                              : null,
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.view_in_ar,
                                  size: 18,
                                  color: Color(0xff176b4d),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'GLB',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FilledButton.icon(
                          onPressed: _resetView,
                          icon: const Icon(Icons.center_focus_strong),
                          label: const Text('Vista inicial'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<_FeederRecord?> _showFeederEditor({
  required BuildContext context,
  required String title,
  required _FeederRecord feeder,
}) async {
  final feedController = TextEditingController(text: feeder.feedName);
  final quantityController = TextEditingController(
    text: feeder.quantityKg > 0 ? _formatKg(feeder.quantityKg) : '',
  );

  final updated = await showDialog<_FeederRecord>(
    context: context,
    builder: (context) {
      String? errorText;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('$title - Comedero ${feeder.feederNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: feedController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Alimento / grano',
                    helperText: 'Ej: maiz, balanceado, nucleo',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad (kg)',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                ),
                if (feeder.updatedAt != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ultima carga: ${_formatFeederDate(feeder.updatedAt!)}',
                      style: const TextStyle(
                        color: Color(0xff587064),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorText!,
                      style: const TextStyle(
                        color: Color(0xffb42318),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (feeder.hasFeed)
                TextButton(
                  onPressed: () => Navigator.pop(context, feeder.cleared()),
                  child: const Text('Limpiar'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final feedName = feedController.text.trim();
                  final quantity = _parseKg(quantityController.text);
                  if (feedName.isEmpty || quantity <= 0) {
                    setDialogState(() {
                      errorText = 'Completa alimento y cantidad mayor a 0.';
                    });
                    return;
                  }
                  Navigator.pop(
                    context,
                    feeder.copyWith(
                      feedName: feedName,
                      quantityKg: quantity,
                      updatedAt: DateTime.now(),
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );

  feedController.dispose();
  quantityController.dispose();
  return updated;
}

double _parseKg(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  final parsed = double.tryParse(normalized) ?? 0;
  return parsed.isFinite ? parsed : 0;
}

String _formatKg(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

String _formatFeederDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

abstract final class _FeedableBarnGlbPreview {
  static const List<
    ({String barnId, int corral, int feeder, double x, double z})
  >
  _feederCenters = [
    (barnId: 'engorde', corral: 1, feeder: 1, x: -11.5, z: -2.45),
    (barnId: 'engorde', corral: 1, feeder: 2, x: -3.3, z: -2.45),
    (barnId: 'engorde', corral: 2, feeder: 1, x: 3.3, z: -2.45),
    (barnId: 'engorde', corral: 2, feeder: 2, x: 11.5, z: -2.45),
    (barnId: 'engorde', corral: 3, feeder: 1, x: -11.5, z: 7.95),
    (barnId: 'engorde', corral: 3, feeder: 2, x: -3.3, z: 7.95),
    (barnId: 'engorde', corral: 4, feeder: 1, x: 3.3, z: 7.95),
    (barnId: 'engorde', corral: 4, feeder: 2, x: 11.5, z: 7.95),
    (barnId: 'parrilla', corral: 1, feeder: 1, x: -8.45, z: -2.7),
    (barnId: 'parrilla', corral: 1, feeder: 2, x: -2.15, z: -2.7),
    (barnId: 'parrilla', corral: 2, feeder: 1, x: 2.15, z: -2.7),
    (barnId: 'parrilla', corral: 2, feeder: 2, x: 8.45, z: -2.7),
    (barnId: 'parrilla', corral: 3, feeder: 1, x: -8.45, z: 6.9),
    (barnId: 'parrilla', corral: 3, feeder: 2, x: -2.15, z: 6.9),
    (barnId: 'parrilla', corral: 4, feeder: 1, x: 2.15, z: 6.9),
    (barnId: 'parrilla', corral: 4, feeder: 2, x: 8.45, z: 6.9),
    (barnId: 'pre-destete', corral: 1, feeder: 1, x: -17.55, z: -3.65),
    (barnId: 'pre-destete', corral: 2, feeder: 1, x: -9.95, z: -3.65),
    (barnId: 'pre-destete', corral: 3, feeder: 1, x: -2.35, z: -3.65),
    (barnId: 'pre-destete', corral: 4, feeder: 1, x: 5.25, z: -3.65),
    (barnId: 'pre-destete', corral: 5, feeder: 1, x: 12.85, z: -3.65),
    (barnId: 'pre-destete', corral: 6, feeder: 1, x: -17.55, z: 7.15),
    (barnId: 'pre-destete', corral: 7, feeder: 1, x: -9.95, z: 7.15),
    (barnId: 'pre-destete', corral: 8, feeder: 1, x: -2.35, z: 7.15),
    (barnId: 'pre-destete', corral: 9, feeder: 1, x: 5.25, z: 7.15),
    (barnId: 'pre-destete', corral: 10, feeder: 1, x: 12.85, z: 7.15),
  ];

  static String hotspotsHtml(String barnId, List<_FeederRecord> feeders) {
    return _feederCenters
        .where((center) => center.barnId == barnId)
        .map((center) {
          final record = feeders.firstWhere(
            (feeder) =>
                feeder.corralNumber == center.corral &&
                feeder.feederNumber == center.feeder,
            orElse: () => _FeederRecord(
              barnId: barnId,
              corralNumber: center.corral,
              feederNumber: center.feeder,
            ),
          );
          final stateClass = record.hasFeed ? 'filled' : 'empty';
          final code = 'C${center.corral}.${center.feeder}';
          final feedName = record.hasFeed ? record.feedName : 'Agregar';
          final amount = record.hasFeed
              ? '${_formatKg(record.quantityKg)} kg'
              : 'Vacio';
          final slotBase =
              'feed-feeder-${center.barnId}-${center.corral}-${center.feeder}';
          final x = center.x.toStringAsFixed(2);
          final z = center.z.toStringAsFixed(2);
          final tapScript =
              "event.preventDefault();event.stopPropagation();"
              "if(window.FeedFeederNative&&window.FeedFeederNative.postMessage){window.FeedFeederNative.postMessage('${center.barnId}|${center.corral}|${center.feeder}');}"
              "var detail=JSON.stringify({type:'feed-feeder-tap',barn:'${center.barnId}',barnId:'${center.barnId}',corral:${center.corral},feeder:${center.feeder}});"
              "window.dispatchEvent(new CustomEvent('feed-feeder-tap',{detail:detail}));"
              "document.dispatchEvent(new CustomEvent('feed-feeder-tap',{detail:detail}));"
              "if(window.parent){window.parent.postMessage(detail,'*');"
              "if(window.parent!==window){window.parent.dispatchEvent(new CustomEvent('feed-feeder-tap',{detail:detail}));}}";
          return '''
<button class="feed-feeder-hitbox" slot="hotspot-$slotBase-hit" data-barn="${center.barnId}" data-corral="${center.corral}" data-feeder="${center.feeder}" data-position="${x}m 0.85m ${z}m" data-normal="0m 1m 0m" aria-label="Agregar alimento $code" onclick="$tapScript"></button>
<button class="feed-feeder-label $stateClass" slot="hotspot-$slotBase-label" data-barn="${center.barnId}" data-corral="${center.corral}" data-feeder="${center.feeder}" data-position="${x}m 1.7m ${z}m" data-normal="0m 1m 0m" aria-label="Editar alimento $code" onclick="$tapScript">
  <span class="feed-code">$code</span>
  <span class="feed-name">${_escapeHtml(feedName)}</span>
  <span class="feed-amount">${_escapeHtml(amount)}</span>
</button>
''';
        })
        .join('\n');
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static const String modelCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #edf5f1;
}

.feed-feeder-hitbox {
  background: transparent;
  border: 0;
  cursor: pointer;
  height: 76px;
  opacity: 0;
  padding: 0;
  pointer-events: auto;
  transform: translate(-50%, -50%);
  width: 76px;
  z-index: 19;
}

.feed-feeder-hitbox:hover,
.feed-feeder-hitbox:focus {
  background: transparent;
  box-shadow: none;
  outline: none;
}

.feed-feeder-label {
  align-items: center;
  background: rgba(255, 255, 255, 0.86);
  border: 1px solid rgba(207, 224, 213, 0.78);
  border-radius: 8px;
  box-shadow: 0 8px 18px rgba(0, 0, 0, 0.14);
  color: #20352a;
  cursor: pointer;
  display: inline-grid;
  font: 800 9px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  gap: 1px 5px;
  grid-template-columns: auto 1fr;
  line-height: 1.05;
  min-width: 82px;
  padding: 4px 6px;
  pointer-events: auto;
  text-align: left;
  transform: translate(-50%, -120%);
  white-space: nowrap;
  z-index: 20;
}

.feed-feeder-label:hover,
.feed-feeder-label:focus {
  box-shadow: 0 10px 24px rgba(15, 102, 70, 0.22);
  outline: none;
}

.feed-feeder-label .feed-code {
  align-items: center;
  border-radius: 6px;
  display: inline-flex;
  height: 18px;
  justify-content: center;
  width: 28px;
}

.feed-feeder-label.filled .feed-code {
  background: #bff0d1;
  border: 1px solid #70b982;
  color: #153e27;
}

.feed-feeder-label.empty .feed-code {
  background: #eef4ef;
  border: 1px solid #abc7b4;
  color: #31513d;
}

.feed-feeder-label .feed-name {
  max-width: 82px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.feed-feeder-label .feed-amount {
  color: #587064;
  font-size: 8px;
  font-weight: 800;
  grid-column: 2;
  max-width: 82px;
  overflow: hidden;
  text-overflow: ellipsis;
}
''';

  static const String modelJs = '''
(function () {
  const feeders = [
    { barn: 'engorde', corral: 1, feeder: 1, x: -11.5, z: -2.45 },
    { barn: 'engorde', corral: 1, feeder: 2, x: -3.3, z: -2.45 },
    { barn: 'engorde', corral: 2, feeder: 1, x: 3.3, z: -2.45 },
    { barn: 'engorde', corral: 2, feeder: 2, x: 11.5, z: -2.45 },
    { barn: 'engorde', corral: 3, feeder: 1, x: -11.5, z: 7.95 },
    { barn: 'engorde', corral: 3, feeder: 2, x: -3.3, z: 7.95 },
    { barn: 'engorde', corral: 4, feeder: 1, x: 3.3, z: 7.95 },
    { barn: 'engorde', corral: 4, feeder: 2, x: 11.5, z: 7.95 },
    { barn: 'parrilla', corral: 1, feeder: 1, x: -8.45, z: -2.7 },
    { barn: 'parrilla', corral: 1, feeder: 2, x: -2.15, z: -2.7 },
    { barn: 'parrilla', corral: 2, feeder: 1, x: 2.15, z: -2.7 },
    { barn: 'parrilla', corral: 2, feeder: 2, x: 8.45, z: -2.7 },
    { barn: 'parrilla', corral: 3, feeder: 1, x: -8.45, z: 6.9 },
    { barn: 'parrilla', corral: 3, feeder: 2, x: -2.15, z: 6.9 },
    { barn: 'parrilla', corral: 4, feeder: 1, x: 2.15, z: 6.9 },
    { barn: 'parrilla', corral: 4, feeder: 2, x: 8.45, z: 6.9 },
    { barn: 'pre-destete', corral: 1, feeder: 1, x: -17.55, z: -3.65 },
    { barn: 'pre-destete', corral: 2, feeder: 1, x: -9.95, z: -3.65 },
    { barn: 'pre-destete', corral: 3, feeder: 1, x: -2.35, z: -3.65 },
    { barn: 'pre-destete', corral: 4, feeder: 1, x: 5.25, z: -3.65 },
    { barn: 'pre-destete', corral: 5, feeder: 1, x: 12.85, z: -3.65 },
    { barn: 'pre-destete', corral: 6, feeder: 1, x: -17.55, z: 7.15 },
    { barn: 'pre-destete', corral: 7, feeder: 1, x: -9.95, z: 7.15 },
    { barn: 'pre-destete', corral: 8, feeder: 1, x: -2.35, z: 7.15 },
    { barn: 'pre-destete', corral: 9, feeder: 1, x: 5.25, z: 7.15 },
    { barn: 'pre-destete', corral: 10, feeder: 1, x: 12.85, z: 7.15 }
  ];

  function dispatchTap(barn, corral, feeder) {
    if (!barn || !corral || !feeder) return;
    if (window.FeedFeederNative &&
        typeof window.FeedFeederNative.postMessage === 'function') {
      window.FeedFeederNative.postMessage(
        String(barn) + '|' + String(corral) + '|' + String(feeder)
      );
    }
    const detail = JSON.stringify({
      type: 'feed-feeder-tap',
      barn: barn,
      barnId: barn,
      corral: Number(corral),
      feeder: Number(feeder)
    });
    window.dispatchEvent(new CustomEvent('feed-feeder-tap', { detail: detail }));
    document.dispatchEvent(new CustomEvent('feed-feeder-tap', { detail: detail }));
    if (window.parent && window.parent !== window) {
      window.parent.dispatchEvent(new CustomEvent('feed-feeder-tap', {
        detail: detail
      }));
    }
    if (window.parent) {
      window.parent.postMessage(detail, '*');
    }
  }

  window.openFeedFeederFromHotspot = function (element, event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    if (!element || !element.dataset) return;
    dispatchTap(element.dataset.barn, element.dataset.corral, element.dataset.feeder);
  };

  function barnFromSrc(src) {
    if (!src) return null;
    if (src.includes('engorde.glb')) return 'engorde';
    if (src.includes('parrilla.glb')) return 'parrilla';
    if (src.includes('pre_destete.glb')) return 'pre-destete';
    return null;
  }

  function wireViewer(viewer) {
    if (!viewer || viewer.__feedFeederTapReady) return;
    const barn = barnFromSrc(viewer.src);
    if (!barn) return;
    viewer.__feedFeederTapReady = true;
    let pointerStart = null;

    viewer.addEventListener('pointerdown', function (event) {
      pointerStart = { x: event.clientX, y: event.clientY };
    });

    viewer.addEventListener('click', function (event) {
      if (event.defaultPrevented) return;
      const eventPath = event.composedPath ? event.composedPath() : [];
      const pathHotspot = eventPath.find(function (element) {
        return element && element.classList &&
          (element.classList.contains('feed-feeder-label') ||
           element.classList.contains('feed-feeder-hitbox'));
      });
      const hotspot = event.target && event.target.closest
        ? event.target.closest('.feed-feeder-label, .feed-feeder-hitbox')
        : null;
      const resolvedHotspot = pathHotspot || hotspot;
      if (resolvedHotspot) {
        window.openFeedFeederFromHotspot(resolvedHotspot, event);
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
      const candidates = feeders
        .filter(function (item) { return item.barn === barn; })
        .map(function (item) {
          return {
            item: item,
            distance: Math.hypot(point.x - item.x, point.z - item.z)
          };
        })
        .sort(function (a, b) { return a.distance - b.distance; });

      if (!candidates.length || candidates[0].distance > 1.3) return;
      event.preventDefault();
      event.stopPropagation();
      dispatchTap(
        candidates[0].item.barn,
        candidates[0].item.corral,
        candidates[0].item.feeder
      );
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

class _PreDesteteCorralRecord {
  const _PreDesteteCorralRecord({
    required this.number,
    this.pigCount = 0,
    this.origin = '',
  });

  final int number;
  final int pigCount;
  final String origin;

  bool get isOccupied => pigCount > 0;

  _PreDesteteCorralRecord copyWith({int? pigCount, String? origin}) {
    return _PreDesteteCorralRecord(
      number: number,
      pigCount: pigCount ?? this.pigCount,
      origin: origin ?? this.origin,
    );
  }

  _PreDesteteCorralRecord cleared() {
    return _PreDesteteCorralRecord(number: number);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'pigCount': pigCount,
    'origin': origin,
  };

  factory _PreDesteteCorralRecord.fromJson(Map<String, dynamic> json) {
    return _PreDesteteCorralRecord(
      number: (json['number'] as num?)?.toInt() ?? 0,
      pigCount: (json['pigCount'] as num?)?.toInt() ?? 0,
      origin: json['origin'] as String? ?? '',
    );
  }
}

class _PreDestete3DPageState extends State<PreDestete3DPage> {
  int _viewerVersion = 0;
  late List<_FeederRecord> _feeders;
  final List<_PreDesteteCorralRecord> _corrals = [
    const _PreDesteteCorralRecord(
      number: 1,
      pigCount: 28,
      origin: 'Maternidad 1 - Jaula 01',
    ),
    const _PreDesteteCorralRecord(
      number: 2,
      pigCount: 31,
      origin: 'Maternidad 1 - Jaula 02',
    ),
    const _PreDesteteCorralRecord(
      number: 3,
      pigCount: 27,
      origin: 'Maternidad 2 - Jaula 01',
    ),
    const _PreDesteteCorralRecord(number: 4),
    const _PreDesteteCorralRecord(number: 5),
    const _PreDesteteCorralRecord(
      number: 6,
      pigCount: 30,
      origin: 'Maternidad 2 - Jaula 02',
    ),
    const _PreDesteteCorralRecord(number: 7),
    const _PreDesteteCorralRecord(number: 8),
    const _PreDesteteCorralRecord(number: 9),
    const _PreDesteteCorralRecord(number: 10),
  ];

  @override
  void initState() {
    super.initState();
    _feeders = _createFeederRecords(
      'pre-destete',
      corralCount: 10,
      feedersPerCorral: 1,
    );
    PreDesteteCorralBridge.register(_openCorralByNumber);
    FeedFeederBridge.register(_openFeederByTap);
    _restoreState();
  }

  Future<void> _restoreState() async {
    final snapshot = await localDatabase.readSnapshot('pre_destete');
    if (snapshot == null) return;
    final restoredCorrals = _jsonMapList(
      snapshot['corrals'],
    ).map(_PreDesteteCorralRecord.fromJson).toList();
    final restoredFeeders = _jsonMapList(
      snapshot['feeders'],
    ).map(_FeederRecord.fromJson).toList();
    if (!mounted) return;
    setState(() {
      if (restoredCorrals.length == 10) {
        _corrals
          ..clear()
          ..addAll(restoredCorrals);
      }
      if (restoredFeeders.isNotEmpty) {
        _feeders = restoredFeeders;
      }
    });
  }

  void _persistState() {
    localDatabase.scheduleSnapshot('pre_destete', <String, dynamic>{
      'corrals': _corrals.map((item) => item.toJson()).toList(),
      'feeders': _feeders.map((item) => item.toJson()).toList(),
    });
  }

  @override
  void dispose() {
    PreDesteteCorralBridge.unregister(_openCorralByNumber);
    FeedFeederBridge.unregister(_openFeederByTap);
    super.dispose();
  }

  void _resetView() {
    setState(() {
      _viewerVersion++;
    });
  }

  void _openCorralByNumber(int corralNumber) {
    if (!mounted) return;
    final index = _corrals.indexWhere(
      (corral) => corral.number == corralNumber,
    );
    if (index == -1) return;
    _openCorralEditor(_corrals[index]);
  }

  void _openFeederByTap(String barnId, int corralNumber, int feederNumber) {
    if (!mounted || barnId != 'pre-destete') return;
    final feeder = _findFeeder(corralNumber, feederNumber);
    if (feeder == null) return;
    _openFeederEditor(feeder);
  }

  _FeederRecord? _findFeeder(int corralNumber, int feederNumber) {
    for (final feeder in _feeders) {
      if (feeder.corralNumber == corralNumber &&
          feeder.feederNumber == feederNumber) {
        return feeder;
      }
    }
    return null;
  }

  Future<void> _openFeederEditor(_FeederRecord feeder) async {
    final updated = await _showFeederEditor(
      context: context,
      title: 'Pre Destete - Corral ${feeder.corralNumber}',
      feeder: feeder,
    );
    if (updated == null || !mounted) return;
    setState(() {
      _feeders = [
        for (final item in _feeders)
          if (item.corralNumber == updated.corralNumber &&
              item.feederNumber == updated.feederNumber)
            updated
          else
            item,
      ];
    });
    _persistState();
  }

  Future<void> _openCorralEditor(_PreDesteteCorralRecord corral) async {
    final countController = TextEditingController(
      text: corral.isOccupied ? corral.pigCount.toString() : '',
    );
    final originController = TextEditingController(text: corral.origin);

    final updated = await showDialog<_PreDesteteCorralRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Corral ${corral.number}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de chanchitos',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: originController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'De qué corral vinieron',
                  helperText: 'Ej: Maternidad 1 - Jaula 03',
                  prefixIcon: Icon(Icons.input_outlined),
                ),
              ),
            ],
          ),
          actions: [
            if (corral.isOccupied || corral.origin.trim().isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(context, corral.cleared()),
                child: const Text('Limpiar'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(countController.text.trim()) ?? 0;
                final safeCount = parsed < 0 ? 0 : parsed;
                Navigator.pop(
                  context,
                  corral.copyWith(
                    pigCount: safeCount,
                    origin: originController.text.trim(),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    countController.dispose();
    originController.dispose();

    if (updated == null || !mounted) return;
    setState(() {
      final index = _corrals.indexWhere(
        (corral) => corral.number == updated.number,
      );
      if (index != -1) {
        _corrals[index] = updated;
      }
    });
    _persistState();
  }

  @override
  Widget build(BuildContext context) {
    final occupied = _corrals.where((corral) => corral.isOccupied).length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pre Destete',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '10 corrales - 5 por lado',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Restablecer vista',
            onPressed: _resetView,
            icon: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              _SectionTitle(
                title: 'Galpón de pre-destete',
                action: '$occupied/10 ocupados',
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _PreDesteteGlbPreview(
                  viewerVersion: _viewerVersion,
                  corrals: _corrals,
                  feeders: _feeders,
                  onResetView: _resetView,
                  onCorralTap: _openCorralByNumber,
                  onFeederTap: _openFeederByTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreDesteteGlbPreview extends StatelessWidget {
  const _PreDesteteGlbPreview({
    required this.viewerVersion,
    required this.corrals,
    required this.feeders,
    required this.onResetView,
    required this.onCorralTap,
    required this.onFeederTap,
  });

  final int viewerVersion;
  final List<_PreDesteteCorralRecord> corrals;
  final List<_FeederRecord> feeders;
  final VoidCallback onResetView;
  final ValueChanged<int> onCorralTap;
  final void Function(String barnId, int corralNumber, int feederNumber)
  onFeederTap;

  static const List<({double x, double z})> _centers = [
    (x: -15.2, z: -5.4),
    (x: -7.6, z: -5.4),
    (x: 0.0, z: -5.4),
    (x: 7.6, z: -5.4),
    (x: 15.2, z: -5.4),
    (x: -15.2, z: 5.4),
    (x: -7.6, z: 5.4),
    (x: 0.0, z: 5.4),
    (x: 7.6, z: 5.4),
    (x: 15.2, z: 5.4),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey(viewerVersion),
              src: modelViewerWebAssetSrc('assets/models/pre_destete.glb'),
              alt: 'Modelo 3D del galpón de pre-destete sin techo',
              cameraControls: true,
              cameraOrbit: '-42deg 58deg 42m',
              cameraTarget: '0m 1.2m 0m',
              autoRotate: false,
              backgroundColor: const Color(0xffedf5f1),
              shadowIntensity: 0.95,
              shadowSoftness: 0.74,
              exposure: 1.12,
              fieldOfView: '31deg',
              minFieldOfView: '20deg',
              maxFieldOfView: '54deg',
              interactionPrompt: InteractionPrompt.auto,
              loading: Loading.eager,
              reveal: Reveal.auto,
              touchAction: TouchAction.none,
              innerModelViewerHtml:
                  '${_FeedableBarnGlbPreview.hotspotsHtml('pre-destete', feeders)}\n'
                  '${_hotspotsHtml(corrals)}',
              minHotspotOpacity: 0.18,
              maxHotspotOpacity: 1,
              relatedCss:
                  '$_preDesteteModelCss\n${_FeedableBarnGlbPreview.modelCss}',
              relatedJs:
                  '$_preDesteteModelJs\n${_FeedableBarnGlbPreview.modelJs}',
              javascriptChannels: !kIsWeb
                  ? {
                      _numberTapNativeChannel(
                        'PreDesteteCorralNative',
                        onCorralTap,
                      ),
                      _feedFeederNativeChannel(onFeederTap),
                    }
                  : null,
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
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: onResetView,
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Vista inicial'),
            ),
          ),
        ],
      ),
    );
  }

  String _hotspotsHtml(List<_PreDesteteCorralRecord> corrals) {
    return corrals
        .map((corral) {
          final index = (corral.number - 1)
              .clamp(0, _centers.length - 1)
              .toInt();
          final center = _centers[index];
          final number = corral.number.toString().padLeft(2, '0');
          final stateClass = corral.isOccupied ? 'occupied' : 'free';
          final name = corral.isOccupied
              ? '${corral.pigCount} chanchitos'
              : 'Libre';
          final detail = corral.isOccupied
              ? (corral.origin.trim().isEmpty
                    ? 'Origen pendiente'
                    : corral.origin)
              : 'Sin registro';
          final tapScript =
              "event.preventDefault();event.stopPropagation();if(window.PreDesteteCorralNative&&window.PreDesteteCorralNative.postMessage){window.PreDesteteCorralNative.postMessage('${corral.number}');}window.dispatchEvent(new CustomEvent('pre-destete-corral-tap',{detail:'${corral.number}'}));document.dispatchEvent(new CustomEvent('pre-destete-corral-tap',{detail:'${corral.number}'}));window.parent.postMessage(JSON.stringify({type:'pre-destete-corral-tap',corral:${corral.number}}),'*');";

          return '''
<button class="pre-destete-corral-hitbox" slot="hotspot-pre-destete-corral-hit-${corral.number}" data-corral="${corral.number}" data-position="${center.x}m 0.85m ${center.z}m" data-normal="0m 1m 0m" aria-label="Abrir corral $number" onclick="$tapScript"></button>
<button class="pre-destete-corral-label $stateClass" slot="hotspot-pre-destete-corral-label-${corral.number}" data-corral="${corral.number}" data-position="${center.x}m 2.15m ${center.z}m" data-normal="0m 1m 0m" aria-label="Editar corral $number" onclick="$tapScript">
  <span class="corral-number">$number</span>
  <span class="corral-name">${_escapeHtml(name)}</span>
  <span class="corral-line">${_escapeHtml(detail)}</span>
</button>
''';
        })
        .join('\n');
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static const String _preDesteteModelCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #edf5f1;
}

.pre-destete-corral-hitbox {
  background: transparent;
  border: 0;
  cursor: pointer;
  display: block;
  height: 64px;
  opacity: 0;
  padding: 0;
  pointer-events: auto;
  transform: translate(-50%, -50%);
  width: 64px;
  z-index: 2;
}

.pre-destete-corral-hitbox:focus,
.pre-destete-corral-hitbox:hover {
  background: transparent;
  box-shadow: none;
  outline: none;
}

.pre-destete-corral-label {
  align-items: center;
  background: rgba(255, 255, 255, 0.80);
  border: 1px solid rgba(210, 224, 214, 0.72);
  border-radius: 9px;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
  color: #24332c;
  cursor: pointer;
  display: inline-grid;
  font: 800 10px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  gap: 1px;
  grid-template-columns: auto 1fr;
  line-height: 1.05;
  min-width: 94px;
  padding: 4px 6px;
  pointer-events: auto;
  text-align: left;
  transform: translate(-50%, -125%);
  white-space: nowrap;
  z-index: 3;
}

.pre-destete-corral-label:focus,
.pre-destete-corral-label:hover {
  box-shadow: 0 10px 26px rgba(15, 102, 70, 0.24);
  outline: none;
}

.pre-destete-corral-label .corral-number {
  align-items: center;
  border-radius: 6px;
  display: inline-flex;
  height: 20px;
  justify-content: center;
  margin-right: 5px;
  width: 24px;
}

.pre-destete-corral-label.occupied .corral-number {
  background: #bff0d1;
  border: 1px solid #6fb982;
  color: #164329;
}

.pre-destete-corral-label.free .corral-number {
  background: #eef4ef;
  border: 1px solid #abc7b4;
  color: #31513d;
}

.pre-destete-corral-label .corral-name {
  color: #293c32;
  max-width: 116px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.pre-destete-corral-label .corral-line {
  color: #587064;
  font-size: 8px;
  font-weight: 750;
  grid-column: 2;
  max-width: 116px;
  overflow: hidden;
  text-overflow: ellipsis;
}
''';

  static const String _preDesteteModelJs = '''
(function () {
  function openCorral(corralNumber) {
    if (!corralNumber) return;
    const detail = String(corralNumber);
    if (window.PreDesteteCorralNative &&
        typeof window.PreDesteteCorralNative.postMessage === 'function') {
      window.PreDesteteCorralNative.postMessage(detail);
    }
    window.dispatchEvent(new CustomEvent('pre-destete-corral-tap', { detail }));
    document.dispatchEvent(new CustomEvent('pre-destete-corral-tap', { detail }));
    if (window.parent && window.parent !== window) {
      window.parent.dispatchEvent(new CustomEvent('pre-destete-corral-tap', {
        detail: detail
      }));
    }
    if (window.parent) {
      window.parent.postMessage(JSON.stringify({
        type: 'pre-destete-corral-tap',
        corral: Number(detail)
      }), '*');
    }
  }

  function wireViewer(viewer) {
    if (!viewer || viewer.__preDesteteCorralTapReady) return;
    if (!viewer.src || !viewer.src.includes('pre_destete.glb')) return;
    viewer.__preDesteteCorralTapReady = true;

    const corrals = [
      { id: 1, x: -15.2, z: -5.4, w: 6.8, d: 5.2 },
      { id: 2, x: -7.6, z: -5.4, w: 6.8, d: 5.2 },
      { id: 3, x: 0.0, z: -5.4, w: 6.8, d: 5.2 },
      { id: 4, x: 7.6, z: -5.4, w: 6.8, d: 5.2 },
      { id: 5, x: 15.2, z: -5.4, w: 6.8, d: 5.2 },
      { id: 6, x: -15.2, z: 5.4, w: 6.8, d: 5.2 },
      { id: 7, x: -7.6, z: 5.4, w: 6.8, d: 5.2 },
      { id: 8, x: 0.0, z: 5.4, w: 6.8, d: 5.2 },
      { id: 9, x: 7.6, z: 5.4, w: 6.8, d: 5.2 },
      { id: 10, x: 15.2, z: 5.4, w: 6.8, d: 5.2 }
    ];

    let pointerStart = null;

    viewer.addEventListener('pointerdown', function (event) {
      pointerStart = { x: event.clientX, y: event.clientY };
    });

    viewer.addEventListener('click', function (event) {
      const eventPath = event.composedPath ? event.composedPath() : [];
      const feedHotspot = eventPath.find(function (element) {
        return element && element.classList &&
          (element.classList.contains('feed-feeder-label') ||
           element.classList.contains('feed-feeder-hitbox'));
      });
      if (feedHotspot) {
        window.openFeedFeederFromHotspot(feedHotspot, event);
        return;
      }

      // Los controles interactivos ya procesan su propio toque. Evita que el
      // mismo evento termine abriendo tambien el CRUD del corral.
      if (event.defaultPrevented) return;

      const pathHotspot = eventPath.find(function (element) {
        return element && element.classList &&
          (element.classList.contains('pre-destete-corral-label') ||
           element.classList.contains('pre-destete-corral-hitbox'));
      });
      const hotspot = event.target && event.target.closest
        ? event.target.closest('.pre-destete-corral-label, .pre-destete-corral-hitbox')
        : null;
      const resolvedHotspot = pathHotspot || hotspot;
      if (resolvedHotspot) {
        event.preventDefault();
        event.stopPropagation();
        openCorral(resolvedHotspot.dataset.corral);
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
      const corral = corrals.find(function (item) {
        return point.x >= item.x - item.w / 2 &&
          point.x <= item.x + item.w / 2 &&
          point.z >= item.z - item.d / 2 &&
          point.z <= item.z + item.d / 2;
      });

      if (!corral) return;
      event.preventDefault();
      event.stopPropagation();
      openCorral(corral.id);
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

class GestationBarnPage extends StatefulWidget {
  const GestationBarnPage({super.key});

  @override
  State<GestationBarnPage> createState() => _GestationBarnPageState();
}

const int _leftGestationCrateCount = 27;
const int _rightGestationCrateCount = 26;
const int _totalGestationCrateCount =
    _leftGestationCrateCount + _rightGestationCrateCount;
final ValueNotifier<List<BoarRecord>> _boarRecords =
    ValueNotifier<List<BoarRecord>>([
      const BoarRecord(number: 1, name: 'Verraco 1', bloodline: 'Duroc'),
      const BoarRecord(number: 2, name: 'Verraco 2', bloodline: 'Pietrain'),
      const BoarRecord(number: 3, name: 'Verraco 3', bloodline: 'Landrace'),
    ]);

Future<void> _restoreBoarRecords() async {
  final snapshot = await localDatabase.readSnapshot('verracos');
  final records = _jsonMapList(
    snapshot?['records'],
  ).map(BoarRecord.fromJson).where((record) => record.number > 0).toList();
  if (records.isNotEmpty) {
    _boarRecords.value = records;
  }
}

void _persistBoarRecords() {
  localDatabase.scheduleSnapshot('verracos', <String, dynamic>{
    'records': _boarRecords.value.map((record) => record.toJson()).toList(),
  });
}

List<String> _activeBoarLabels() {
  return _boarRecords.value
      .where((boar) => boar.isRegistered)
      .map((boar) => boar.label)
      .toList();
}

final ValueNotifier<Map<int, int>> _boarMatingCounts =
    ValueNotifier<Map<int, int>>(_initialBoarMatingCounts());

Map<int, int> _initialBoarMatingCounts() {
  final counts = _emptyBoarMatingCounts();
  final boars = _boarRecords.value.where((boar) => boar.isRegistered).toList();
  if (boars.isEmpty) {
    return counts;
  }

  for (var number = 1; number <= _totalGestationCrateCount; number++) {
    final isOccupied = number % 9 != 0 && number % 17 != 0;
    final matingCount = switch (number) {
      _ when !isOccupied => 0,
      _ when number % 13 == 0 => 0,
      _ when number % 11 == 0 => 1,
      _ when number % 7 == 0 => 2,
      _ => 3,
    };
    for (var index = 0; index < matingCount; index++) {
      final boar = boars[index % boars.length];
      counts[boar.number] = (counts[boar.number] ?? 0) + 1;
    }
  }

  return counts;
}

Map<int, int> _emptyBoarMatingCounts() {
  return {for (final boar in _boarRecords.value) boar.number: 0};
}

Map<int, int> _countBoarMatings(Iterable<GestationCrate> crates) {
  final counts = _emptyBoarMatingCounts();
  for (final crate in crates) {
    for (final assignment in crate.matingBoars.take(crate.matingDates.length)) {
      final number = _boarNumberFromMatingAssignment(assignment);
      if (number == null) {
        continue;
      }
      counts[number] = (counts[number] ?? 0) + 1;
    }
  }
  return counts;
}

int? _boarNumberFromMatingAssignment(String? assignment) {
  final value = assignment?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  final normalized = value.toLowerCase();
  for (final boar in _boarRecords.value) {
    final name = boar.name.trim().toLowerCase();
    final label = boar.label.trim().toLowerCase();
    if (normalized == name ||
        normalized == label ||
        (name.isNotEmpty && normalized.startsWith('$name '))) {
      return boar.number;
    }
  }

  final match = RegExp(r'verraco\s*(\d+)').firstMatch(normalized);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1) ?? '');
}

String _formatMatingCount(int count) =>
    count == 1 ? '1 monta' : '$count montas';

class _GestationBarnPageState extends State<GestationBarnPage> {
  late List<GestationCrate> _crates;
  late List<GestationCrate> _maternity1;
  late List<GestationCrate> _maternity2;
  SynchronizationBatch? _syncBatch;
  bool _showingHeatCheck = false;
  int _gestationViewerVersion = 0;

  @override
  void initState() {
    super.initState();
    _crates = _createGestationCrates();
    _maternity1 = _createMaternityCrates('Maternidad 1');
    _maternity2 = _createMaternityCrates('Maternidad 2');
    GestationCrateBridge.register(_openGestationCrateByNumber);
    _restoreState();
  }

  Future<void> _restoreState() async {
    final snapshot = await localDatabase.readSnapshot('gestacion');
    if (snapshot != null) {
      final crates = _jsonMapList(
        snapshot['crates'],
      ).map(GestationCrate.fromJson).toList();
      final maternity1 = _jsonMapList(
        snapshot['maternity1'],
      ).map(GestationCrate.fromJson).toList();
      final maternity2 = _jsonMapList(
        snapshot['maternity2'],
      ).map(GestationCrate.fromJson).toList();
      final batchJson = snapshot['synchronizationBatch'];
      if (!mounted) return;
      setState(() {
        if (crates.length == _totalGestationCrateCount) _crates = crates;
        if (maternity1.length == 10) _maternity1 = maternity1;
        if (maternity2.length == 10) _maternity2 = maternity2;
        if (batchJson is Map) {
          _syncBatch = SynchronizationBatch.fromJson(
            Map<String, dynamic>.from(batchJson),
          );
        }
      });
    }
    _publishBoarMatingCounts();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDueHeatCheck());
    }
  }

  void _persistState() {
    localDatabase.scheduleSnapshot('gestacion', <String, dynamic>{
      'crates': _crates.map((item) => item.toJson()).toList(),
      'maternity1': _maternity1.map((item) => item.toJson()).toList(),
      'maternity2': _maternity2.map((item) => item.toJson()).toList(),
      'synchronizationBatch': _syncBatch?.toJson(),
    });
  }

  @override
  void dispose() {
    GestationCrateBridge.unregister(_openGestationCrateByNumber);
    super.dispose();
  }

  List<GestationCrate> _createGestationCrates() {
    return List.generate(_totalGestationCrateCount, (index) {
      final number = index + 1;
      final side = number <= _leftGestationCrateCount ? 'Izquierda' : 'Derecha';
      final sideNumber = number <= _leftGestationCrateCount
          ? number
          : number - _leftGestationCrateCount;
      final isOccupied = number % 9 != 0 && number % 17 != 0;
      final days = number == 5
          ? 21
          : number % 5 == 0
          ? 8 + number % 9
          : 28 + (number * 3) % 86;
      final matingDates = switch (number) {
        _ when !isOccupied => const <DateTime>[],
        _ when number % 13 == 0 => const <DateTime>[],
        _ when number % 11 == 0 => _matingDatesInProgress(1),
        _ when number % 7 == 0 => _matingDatesInProgress(2),
        _ => _matingDatesForDays(days),
      };
      return GestationCrate(
        number: number,
        side: side,
        sideNumber: sideNumber,
        earTag: isOccupied ? 'G-${(2400 + number).toString()}' : null,
        matingDates: matingDates,
        matingBoars: _sampleBoarAssignments(matingDates.length),
        farrowingRecord: null,
        abortionRecord: null,
        heatCheckDone: isOccupied && matingDates.length == 3 && days > 21,
      );
    });
  }

  List<DateTime> _matingDatesInProgress(int count) {
    final today = _dateOnly(DateTime.now());
    return List.generate(
      count,
      (index) => today.subtract(Duration(days: count - index - 1)),
    );
  }

  List<DateTime> _matingDatesForDays(int days) {
    final thirdMating = _dateOnly(
      DateTime.now(),
    ).subtract(Duration(days: days));
    return [
      thirdMating.subtract(const Duration(days: 2)),
      thirdMating.subtract(const Duration(days: 1)),
      thirdMating,
    ];
  }

  List<String?> _sampleBoarAssignments(int count) {
    final boars = _activeBoarLabels();
    if (boars.isEmpty) {
      return List<String?>.filled(count, null);
    }
    return List.generate(count, (index) => boars[index % boars.length]);
  }

  List<GestationCrate> _createMaternityCrates(String barnName) {
    return List.generate(10, (index) {
      final number = index + 1;
      final occupiedLimit = barnName == 'Maternidad 1' ? 7 : 6;
      final tagPrefix = barnName == 'Maternidad 1' ? 'M1' : 'M2';
      return GestationCrate(
        number: number,
        side: number <= 5 ? 'Izquierda' : 'Derecha',
        sideNumber: number <= 5 ? number : number - 5,
        earTag: number <= occupiedLimit
            ? '$tagPrefix-${(3100 + number).toString()}'
            : null,
        matingDates: const [],
        matingBoars: const [],
        farrowingRecord: null,
        abortionRecord: null,
        heatCheckDone: false,
      );
    });
  }

  Future<void> _showDueHeatCheck() async {
    if (_showingHeatCheck || !mounted) {
      return;
    }
    final dueCrates = _crates.where((crate) => crate.needsHeatCheck).toList();
    if (dueCrates.isEmpty) {
      return;
    }

    _showingHeatCheck = true;
    final crate = dueCrates.first;
    final repeatedHeat = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Revisión de celo'),
          content: Text(
            '${crate.earTag} llegó a ${crate.daysPregnant} días desde la tercera monta. ¿La chancha volvió a entrar en celo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (repeatedHeat == true) {
      final updated = crate.copyWith(
        matingDates: const <DateTime>[],
        heatCheckDone: false,
      );
      setState(() => _replaceCrate(_crates, updated));
      _publishBoarMatingCounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${crate.earTag} quedó lista para reprogramar montas.'),
        ),
      );
      await _editCrate(updated, title: 'Reprogramar montas');
    } else if (repeatedHeat == false) {
      setState(() {
        _replaceCrate(_crates, crate.copyWith(heatCheckDone: true));
      });
    }

    _showingHeatCheck = false;
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDueHeatCheck());
    }
  }

  @override
  Widget build(BuildContext context) {
    final occupied = _crates.where((crate) => crate.isOccupied).length;
    final free = _crates.length - occupied;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestación',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '53 jaulas · 27 izquierda · 26 derecha',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _GestationStat(
                    label: 'Ocupadas',
                    value: '$occupied/${_crates.length}',
                    icon: Icons.pets_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GestationStat(
                    label: 'Libres',
                    value: free.toString(),
                    icon: Icons.event_seat_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PostWeaningSyncCard(
              batch: _syncBatch,
              onProgram: _programPostWeaningAmpoule,
            ),
            const SizedBox(height: 14),
            const _GestationStatusLegend(),
            const SizedBox(height: 14),
            const _SectionTitle(title: 'Jaulas', action: 'Arete visible'),
            const SizedBox(height: 10),
            SizedBox(
              height: math.max(560.0, MediaQuery.sizeOf(context).height - 250),
              child: _GestationGlbBarnView(
                viewerVersion: _gestationViewerVersion,
                crates: _crates,
                onResetView: _resetGestationView,
                onCrateTap: _openGestationCrateByNumber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetGestationView() {
    setState(() {
      _gestationViewerVersion++;
    });
  }

  void _openGestationCrateByNumber(int crateNumber) {
    for (final crate in _crates) {
      if (crate.number == crateNumber) {
        _openCrateActions(crate);
        return;
      }
    }
  }

  void _openCrateActions(GestationCrate crate) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jaula ${crate.number}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Lado: ${crate.side} · Posición ${crate.sideNumber}'),
                  const SizedBox(height: 6),
                  Text('Arete: ${crate.earTag ?? 'sin chancha registrada'}'),
                  if (crate.isOccupied) ...[
                    const SizedBox(height: 6),
                    Text('Estado: ${crate.statusLabel}'),
                  ],
                  if (crate.abortionRecord != null) ...[
                    const SizedBox(height: 10),
                    _AbortionRecordDetail(
                      record: crate.abortionRecord!,
                      onEdit: () {
                        Navigator.pop(sheetContext);
                        _editGestationAbortionRecord(crate);
                      },
                      onDelete: () {
                        Navigator.pop(sheetContext);
                        _deleteGestationAbortionRecord(crate);
                      },
                    ),
                  ],
                  if (crate.matingBoars.whereType<String>().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Verracos: ${crate.matingBoars.whereType<String>().join(', ')}',
                    ),
                  ],
                  if (crate.daysPregnant != null) ...[
                    const SizedBox(height: 6),
                    Text('Días de gestación: ${crate.daysPregnant}'),
                    const SizedBox(height: 6),
                    Text(
                      'Parto aprox.: ${_formatDate(crate.expectedFarrowingDate)}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Trasladar: ${_formatDate(crate.transferToMaternityDate)}',
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _editCrate(crate, title: 'Editar jaula');
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _editCrate(crate, title: 'Actualizar datos');
                          },
                          icon: const Icon(Icons.update),
                          label: const Text('Actualizar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: crate.isOccupied
                          ? () {
                              Navigator.pop(sheetContext);
                              _editGestationAbortionRecord(crate);
                            }
                          : null,
                      icon: const Icon(Icons.heart_broken_outlined),
                      label: Text(
                        crate.abortionRecord == null
                            ? 'Registrar aborto'
                            : 'Editar aborto',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: crate.isOccupied
                          ? () {
                              Navigator.pop(sheetContext);
                              _showMovePicker(crate);
                            }
                          : null,
                      icon: const Icon(Icons.drive_file_move_outline),
                      label: const Text('Mover chancha'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCrate(GestationCrate crate, {required String title}) async {
    final earTagController = TextEditingController(text: crate.earTag ?? '');
    final matingDates = List<DateTime>.from(crate.matingDates);
    final matingBoars = List<String?>.from(crate.matingBoars);

    final updated = await showDialog<GestationCrate>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final preview = crate.copyWith(
              matingDates: matingDates,
              matingBoars: matingBoars,
            );
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: earTagController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Número de arete',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (var index = 0; index < 3; index++) ...[
                      _MatingDateField(
                        label: 'Monta ${index + 1}',
                        date: index < matingDates.length
                            ? matingDates[index]
                            : null,
                        onPick: () async {
                          final initialDate = index < matingDates.length
                              ? matingDates[index]
                              : DateTime.now();
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (selected == null) {
                            return;
                          }
                          setDialogState(() {
                            final boars = _activeBoarLabels();
                            while (matingDates.length <= index) {
                              matingDates.add(selected);
                            }
                            while (matingBoars.length <= index) {
                              matingBoars.add(
                                boars.isEmpty ? null : boars.first,
                              );
                            }
                            matingDates[index] = _dateOnly(selected);
                            matingBoars[index] ??= boars.isEmpty
                                ? null
                                : boars.first;
                          });
                        },
                        onClear: index < matingDates.length
                            ? () {
                                setDialogState(() {
                                  matingDates.removeAt(index);
                                  if (index < matingBoars.length) {
                                    matingBoars.removeAt(index);
                                  }
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _BoarSelectorField(
                        label: 'Verraco monta ${index + 1}',
                        value: index < matingBoars.length
                            ? matingBoars[index]
                            : null,
                        enabled: index < matingDates.length,
                        onChanged: (value) {
                          setDialogState(() {
                            while (matingBoars.length <= index) {
                              matingBoars.add(null);
                            }
                            matingBoars[index] = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    _GestationCalculationPreview(crate: preview),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final earTag = earTagController.text.trim();
                    Navigator.pop(
                      context,
                      crate.copyWith(
                        earTag: earTag.isEmpty ? null : earTag,
                        matingDates: matingDates,
                        matingBoars: matingBoars,
                        heatCheckDone: false,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    earTagController.dispose();

    if (updated != null) {
      setState(() => _replaceCrate(_crates, updated));
      _publishBoarMatingCounts();
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDueHeatCheck());
    }
  }

  Future<void> _editGestationAbortionRecord(GestationCrate crate) async {
    final updated = await _showAbortionRecordDialog(context, crate);
    if (updated != null) {
      setState(() {
        _replaceCrate(
          _crates,
          crate.copyWith(abortionRecord: updated, heatCheckDone: true),
        );
      });
    }
  }

  Future<void> _deleteGestationAbortionRecord(GestationCrate crate) async {
    final confirmed = await _confirmDeleteAbortionRecord(context, crate.number);
    if (confirmed == true) {
      setState(
        () => _replaceCrate(_crates, crate.copyWith(abortionRecord: null)),
      );
    }
  }

  Future<void> _programPostWeaningAmpoule() async {
    var weaningDate = _syncBatch?.weaningDate ?? _dateOnly(DateTime.now());
    var ampouleDate = _syncBatch?.ampouleDate ?? _dateOnly(DateTime.now());
    final selectedSows = List<String>.from(
      _syncBatch?.earTags ?? const <String>[],
    );

    final batch = await showDialog<SynchronizationBatch>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ampolla post-destete'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MatingDateField(
                      label: 'Fecha de destete',
                      date: weaningDate,
                      onPick: () async {
                        final selected = await _pickDate(context, weaningDate);
                        if (selected != null) {
                          setDialogState(() => weaningDate = selected);
                        }
                      },
                      onClear: null,
                    ),
                    const SizedBox(height: 8),
                    _MatingDateField(
                      label: 'Fecha de ampolla',
                      date: ampouleDate,
                      onPick: () async {
                        final selected = await _pickDate(context, ampouleDate);
                        if (selected != null) {
                          setDialogState(() => ampouleDate = selected);
                        }
                      },
                      onClear: null,
                    ),
                    const SizedBox(height: 8),
                    _AmpouleAutoSchedulePreview(ampouleDate: ampouleDate),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await _selectAmpouleSows(
                            selectedSows,
                          );
                          if (selected != null) {
                            setDialogState(() {
                              selectedSows
                                ..clear()
                                ..addAll(selected);
                            });
                          }
                        },
                        icon: const Icon(Icons.checklist_outlined),
                        label: Text(
                          selectedSows.isEmpty
                              ? 'Seleccionar chanchas'
                              : 'Seleccionadas: ${selectedSows.length}/10',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SyncSowPreview(earTags: selectedSows),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selectedSows.isEmpty
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            SynchronizationBatch(
                              weaningDate: weaningDate,
                              ampouleDate: ampouleDate,
                              earTags: selectedSows.take(10).toList(),
                            ),
                          );
                        },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (batch != null) {
      setState(() => _syncBatch = batch);
      _persistState();
    }
  }

  Future<List<String>?> _selectAmpouleSows(List<String> selectedSows) {
    final groups = [
      _buildAmpouleSowGroup('Gestación', _crates),
      _buildAmpouleSowGroup('Maternidad 1', _maternity1),
      _buildAmpouleSowGroup('Maternidad 2', _maternity2),
    ];
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _AmpouleSowSelector(
          groups: groups,
          initialSelection: selectedSows,
          maxSelection: 10,
        );
      },
    );
  }

  _AmpouleSowGroup _buildAmpouleSowGroup(
    String title,
    List<GestationCrate> crates,
  ) {
    final candidates = crates
        .where((crate) => crate.isOccupied)
        .map(
          (crate) => _AmpouleSowCandidate(
            earTag: crate.earTag!,
            side: crate.side,
            detail: '${crate.side} · Jaula ${crate.sideNumber}',
          ),
        )
        .toList();
    return _AmpouleSowGroup(title: title, candidates: candidates);
  }

  Future<DateTime?> _pickDate(
    BuildContext context,
    DateTime initialDate,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    return selected == null ? null : _dateOnly(selected);
  }

  Future<void> _showMovePicker(GestationCrate crate) async {
    final destination = await showModalBottomSheet<MoveDestination>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _MoveDestinationPicker(
          gestationCrates: _crates
              .where((item) => item.number != crate.number)
              .toList(),
          maternity1Crates: _maternity1
              .where((item) => !item.isOccupied)
              .toList(),
          maternity2Crates: _maternity2
              .where((item) => !item.isOccupied)
              .toList(),
        );
      },
    );

    if (destination == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    if (destination.isSwap) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Intercambiar chanchas'),
            content: Text(
              'La jaula ${destination.crate.number} está ocupada por ${destination.crate.earTag}. ¿Quieres intercambiarla con ${crate.earTag}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Intercambiar'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
    }

    setState(() {
      switch (destination.target) {
        case MoveTarget.gestation:
          if (destination.crate.isOccupied) {
            final movedToDestination = crate.copyWith(
              number: destination.crate.number,
              side: destination.crate.side,
              sideNumber: destination.crate.sideNumber,
            );
            final movedBackToOrigin = destination.crate.copyWith(
              number: crate.number,
              side: crate.side,
              sideNumber: crate.sideNumber,
            );
            _replaceCrate(_crates, movedBackToOrigin);
            _replaceCrate(_crates, movedToDestination);
          } else {
            final moved = crate.copyWith(
              number: destination.crate.number,
              side: destination.crate.side,
              sideNumber: destination.crate.sideNumber,
            );
            _replaceCrate(_crates, crate.cleared());
            _replaceCrate(_crates, moved);
          }
        case MoveTarget.maternity1:
          final moved = crate.copyWith(
            number: destination.crate.number,
            side: destination.crate.side,
            sideNumber: destination.crate.sideNumber,
          );
          _replaceCrate(_crates, crate.cleared());
          _replaceCrate(_maternity1, moved);
        case MoveTarget.maternity2:
          final moved = crate.copyWith(
            number: destination.crate.number,
            side: destination.crate.side,
            sideNumber: destination.crate.sideNumber,
          );
          _replaceCrate(_crates, crate.cleared());
          _replaceCrate(_maternity2, moved);
      }
    });
    _publishBoarMatingCounts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            destination.isSwap
                ? '${crate.earTag} intercambiada con ${destination.crate.earTag}'
                : '${crate.earTag} movida a ${destination.label}, jaula ${destination.crate.number}',
          ),
        ),
      );
    }
  }

  void _replaceCrate(List<GestationCrate> crates, GestationCrate updated) {
    final index = crates.indexWhere((crate) => crate.number == updated.number);
    if (index >= 0) {
      crates[index] = updated;
      _persistState();
    }
  }

  void _publishBoarMatingCounts() {
    _boarMatingCounts.value = _countBoarMatings([
      ..._crates,
      ..._maternity1,
      ..._maternity2,
    ]);
  }
}

class MaternityBarnPage extends StatefulWidget {
  const MaternityBarnPage({super.key, required this.title});

  final String title;

  @override
  State<MaternityBarnPage> createState() => _MaternityBarnPageState();
}

class _MaternityFeedRecord {
  const _MaternityFeedRecord({
    required this.crateNumber,
    this.cups = 0,
    this.updatedAt,
  });

  final int crateNumber;
  final int cups;
  final DateTime? updatedAt;

  bool get hasFeed => cups > 0;
  int get kilograms => cups;

  _MaternityFeedRecord copyWith({int? cups, DateTime? updatedAt}) {
    return _MaternityFeedRecord(
      crateNumber: crateNumber,
      cups: cups ?? this.cups,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  _MaternityFeedRecord addCup(DateTime now) {
    return copyWith(cups: cups + 1, updatedAt: now);
  }

  _MaternityFeedRecord cleared() {
    return _MaternityFeedRecord(crateNumber: crateNumber);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'crateNumber': crateNumber,
    'cups': cups,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory _MaternityFeedRecord.fromJson(Map<String, dynamic> json) {
    return _MaternityFeedRecord(
      crateNumber: (json['crateNumber'] as num?)?.toInt() ?? 0,
      cups: (json['cups'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class _MaternityBarnPageState extends State<MaternityBarnPage> {
  late List<GestationCrate> _crates;
  final Map<int, _MaternityFeedRecord> _feedingRecords = {};
  int _viewerVersion = 0;
  String get _storageKey =>
      widget.title.endsWith('2') ? 'maternidad_2' : 'maternidad_1';

  @override
  void initState() {
    super.initState();
    _crates = _createMaternityPreviewCrates(widget.title);
    MaternityCrateBridge.register(_openMaternityCrateByNumber);
    _restoreState();
  }

  Future<void> _restoreState() async {
    final snapshot = await localDatabase.readSnapshot(_storageKey);
    if (snapshot == null) return;
    final crates = _jsonMapList(
      snapshot['crates'],
    ).map(GestationCrate.fromJson).toList();
    final feeding = _jsonMapList(
      snapshot['feedingRecords'],
    ).map(_MaternityFeedRecord.fromJson).toList();
    if (!mounted) return;
    setState(() {
      if (crates.length == 10) _crates = crates;
      _feedingRecords
        ..clear()
        ..addEntries(
          feeding
              .where((record) => record.crateNumber > 0)
              .map((record) => MapEntry(record.crateNumber, record)),
        );
    });
  }

  void _persistState() {
    localDatabase.scheduleSnapshot(_storageKey, <String, dynamic>{
      'title': widget.title,
      'crates': _crates.map((item) => item.toJson()).toList(),
      'feedingRecords': _feedingRecords.values
          .map((item) => item.toJson())
          .toList(),
    });
  }

  @override
  void dispose() {
    MaternityCrateBridge.unregister(_openMaternityCrateByNumber);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final occupied = _crates.where((crate) => crate.isOccupied).length;
    final free = _crates.length - occupied;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const Text(
              '10 jaulas · 5 por lado',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Vista superior',
            onPressed: _resetMaternityView,
            icon: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _MaternityGlbBarnView(
                viewerVersion: _viewerVersion,
                crates: _crates,
                feedingRecords: _feedingRecords,
                onCrateTap: _openMaternityCrateByNumber,
              ),
            ),
            Positioned(
              left: 16,
              top: 12,
              right: 16,
              child: _MaternityGlbStatusBar(
                occupied: occupied,
                free: free,
                onFeedAll: occupied == 0 ? null : _feedAllOccupiedCrates,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetMaternityView() {
    setState(() {
      _viewerVersion++;
    });
  }

  void _openMaternityCrateByNumber(int crateNumber) {
    if (!mounted) return;
    final index = _crates.indexWhere((crate) => crate.number == crateNumber);
    if (index < 0) return;
    _openCrate(_crates[index]);
  }

  void _openCrate(GestationCrate crate) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final farrowing = crate.farrowingRecord;
        final abortion = crate.abortionRecord;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jaula ${crate.number}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Lado: ${crate.side} · Posición ${crate.sideNumber}'),
                  const SizedBox(height: 6),
                  Text('Arete: ${crate.earTag ?? 'sin chancha registrada'}'),
                  const SizedBox(height: 6),
                  Text('Estado: ${crate.statusLabel}'),
                  const SizedBox(height: 14),
                  if (crate.isOccupied) ...[
                    _MaternityFeedSummary(
                      record: _feedingRecordFor(crate.number),
                      onAddCup: () {
                        Navigator.pop(context);
                        _addCupToMaternityCrate(crate);
                      },
                      onAdjust: () {
                        Navigator.pop(context);
                        _adjustMaternityFeed(crate);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (!crate.isOccupied)
                    _MaternityEmptyCrateNotice(
                      onAdd: () {
                        Navigator.pop(context);
                        _selectGestationSowForMaternity(crate);
                      },
                    )
                  else if (abortion != null)
                    _AbortionRecordDetail(
                      record: abortion,
                      onEdit: () {
                        Navigator.pop(context);
                        _editAbortionRecord(crate);
                      },
                      onDelete: () {
                        Navigator.pop(context);
                        _deleteAbortionRecord(crate);
                      },
                    )
                  else if (farrowing == null)
                    _EmptyFarrowingRecord(
                      onCreate: () {
                        Navigator.pop(context);
                        _editFarrowingRecord(crate);
                      },
                      onAbort: () {
                        Navigator.pop(context);
                        _editAbortionRecord(crate);
                      },
                    )
                  else
                    _FarrowingRecordDetail(
                      record: farrowing,
                      onEdit: () {
                        Navigator.pop(context);
                        _editFarrowingRecord(crate);
                      },
                      onDelete: () {
                        Navigator.pop(context);
                        _deleteFarrowingRecord(crate);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _MaternityFeedRecord _feedingRecordFor(int crateNumber) {
    return _feedingRecords[crateNumber] ??
        _MaternityFeedRecord(crateNumber: crateNumber);
  }

  void _addCupToMaternityCrate(GestationCrate crate) {
    if (!crate.isOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero agrega una chancha a esta jaula.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    setState(() {
      _feedingRecords[crate.number] = _feedingRecordFor(
        crate.number,
      ).addCup(now);
    });
    _persistState();
    final record = _feedingRecordFor(crate.number);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Jaula ${crate.number}: ${record.cups} vaso(s) registrados (${record.kilograms} kg).',
        ),
      ),
    );
  }

  void _feedAllOccupiedCrates() {
    final occupiedCrates = _crates.where((crate) => crate.isOccupied).toList();
    if (occupiedCrates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay jaulas ocupadas para alimentar.')),
      );
      return;
    }

    final now = DateTime.now();
    setState(() {
      for (final crate in occupiedCrates) {
        _feedingRecords[crate.number] = _feedingRecordFor(
          crate.number,
        ).addCup(now);
      }
    });
    _persistState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Se registró 1 vaso (1 kg) para ${occupiedCrates.length} jaulas ocupadas.',
        ),
      ),
    );
  }

  Future<void> _adjustMaternityFeed(GestationCrate crate) async {
    final current = _feedingRecordFor(crate.number);
    final cupsController = TextEditingController(
      text: current.hasFeed ? current.cups.toString() : '',
    );

    final updated = await showDialog<_MaternityFeedRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alimento jaula ${crate.number}'),
          content: TextField(
            controller: cupsController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Vasos entregados',
              helperText: '1 vaso equivale a 1 kg',
              prefixIcon: Icon(Icons.local_drink_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            if (current.hasFeed)
              TextButton(
                onPressed: () => Navigator.pop(context, current.cleared()),
                child: const Text('Limpiar'),
              ),
            FilledButton(
              onPressed: () {
                final cups = _parseNonNegativeInt(cupsController.text);
                Navigator.pop(
                  context,
                  current.copyWith(cups: cups, updatedAt: DateTime.now()),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      if (updated.hasFeed) {
        _feedingRecords[crate.number] = updated;
      } else {
        _feedingRecords.remove(crate.number);
      }
    });
    _persistState();
  }

  Future<void> _selectGestationSowForMaternity(
    GestationCrate maternityCrate,
  ) async {
    final currentTags = _crates
        .where((crate) => crate.isOccupied)
        .map((crate) => crate.earTag!)
        .toSet();
    final candidates = _createGestationTransferCandidates()
        .where((crate) => !currentTags.contains(crate.earTag))
        .toList();

    final selected = await showModalBottomSheet<GestationCrate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _GestationSowTransferPicker(candidates: candidates);
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final moved = selected.copyWith(
      number: maternityCrate.number,
      side: maternityCrate.side,
      sideNumber: maternityCrate.sideNumber,
      farrowingRecord: null,
      abortionRecord: null,
    );
    setState(() => _replaceCrate(moved));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selected.earTag} agregada a ${widget.title}, jaula ${maternityCrate.number}',
        ),
      ),
    );
  }

  Future<void> _editFarrowingRecord(GestationCrate crate) async {
    final current = crate.farrowingRecord;
    var farrowingDate = current?.date ?? _dateOnly(DateTime.now());
    final aliveController = TextEditingController(
      text: (current?.bornAlive ?? 0).toString(),
    );
    final deadController = TextEditingController(
      text: (current?.dead ?? 0).toString(),
    );
    final maleController = TextEditingController(
      text: (current?.males ?? 0).toString(),
    );
    final femaleController = TextEditingController(
      text: (current?.females ?? 0).toString(),
    );
    final mummifiedController = TextEditingController(
      text: (current?.mummified ?? 0).toString(),
    );
    final notesController = TextEditingController(text: current?.notes ?? '');

    final updated = await showDialog<FarrowingRecord>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(current == null ? 'Registrar parto' : 'Editar parto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MatingDateField(
                      label: 'Fecha de parto',
                      date: farrowingDate,
                      onPick: () async {
                        final selected = await _pickDate(
                          context,
                          farrowingDate,
                        );
                        if (selected != null) {
                          setDialogState(() => farrowingDate = selected);
                        }
                      },
                      onClear: null,
                    ),
                    const SizedBox(height: 10),
                    _NumberField(
                      controller: aliveController,
                      label: 'Nacidos vivos',
                      icon: Icons.child_care_outlined,
                    ),
                    const SizedBox(height: 10),
                    _NumberField(
                      controller: deadController,
                      label: 'Muertos',
                      icon: Icons.heart_broken_outlined,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            controller: maleController,
                            label: 'Machos',
                            icon: Icons.male_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumberField(
                            controller: femaleController,
                            label: 'Hembras',
                            icon: Icons.female_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _NumberField(
                      controller: mummifiedController,
                      label: 'Momificados',
                      icon: Icons.warning_amber_outlined,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      FarrowingRecord(
                        date: farrowingDate,
                        bornAlive: _parseCount(aliveController.text),
                        dead: _parseCount(deadController.text),
                        males: _parseCount(maleController.text),
                        females: _parseCount(femaleController.text),
                        mummified: _parseCount(mummifiedController.text),
                        notes: notesController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated != null) {
      setState(() => _replaceCrate(crate.copyWith(farrowingRecord: updated)));
    }
  }

  Future<void> _deleteFarrowingRecord(GestationCrate crate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar registro'),
          content: Text(
            '¿Quieres eliminar el registro de parto de la jaula ${crate.number}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      setState(() => _replaceCrate(crate.copyWith(farrowingRecord: null)));
    }
  }

  Future<void> _editAbortionRecord(GestationCrate crate) async {
    final updated = await _showAbortionRecordDialog(context, crate);

    if (updated != null) {
      setState(() {
        _replaceCrate(
          crate.copyWith(abortionRecord: updated, farrowingRecord: null),
        );
      });
    }
  }

  Future<void> _deleteAbortionRecord(GestationCrate crate) async {
    final confirmed = await _confirmDeleteAbortionRecord(context, crate.number);
    if (confirmed == true) {
      setState(() => _replaceCrate(crate.copyWith(abortionRecord: null)));
    }
  }

  void _replaceCrate(GestationCrate updated) {
    final index = _crates.indexWhere((crate) => crate.number == updated.number);
    if (index >= 0) {
      _crates[index] = updated;
      _persistState();
    }
  }

  int _parseCount(String value) {
    return _parseNonNegativeInt(value);
  }
}

class _MaternityGlbBarnView extends StatelessWidget {
  const _MaternityGlbBarnView({
    required this.viewerVersion,
    required this.crates,
    required this.feedingRecords,
    required this.onCrateTap,
  });

  final int viewerVersion;
  final List<GestationCrate> crates;
  final Map<int, _MaternityFeedRecord> feedingRecords;
  final ValueChanged<int> onCrateTap;

  @override
  Widget build(BuildContext context) {
    final hotspots = crates.map((crate) {
      final feed = feedingRecords[crate.number];
      final status = crate.isOccupied
          ? [
              crate.statusLabel,
              if (feed != null && feed.hasFeed) '${feed.kilograms} kg',
            ].join(' Â· ')
          : 'Sin registro';
      return MaternityModelCrateHotspot(
        number: crate.number,
        label: crate.earTag ?? 'Libre',
        status: status,
        occupied: crate.isOccupied,
      );
    }).toList();

    return MaternityModelViewer(
      viewerKey: ValueKey('maternity-barn-glb-$viewerVersion'),
      topView: true,
      showCrateHotspots: true,
      hotspots: hotspots,
      onCrateTap: onCrateTap,
    );
  }
}

class _MaternityGlbStatusBar extends StatelessWidget {
  const _MaternityGlbStatusBar({
    required this.occupied,
    required this.free,
    required this.onFeedAll,
  });

  final int occupied;
  final int free;
  final VoidCallback? onFeedAll;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MaternityGlbStatusChip(
          icon: Icons.child_friendly_outlined,
          label: 'Ocupadas',
          value: '$occupied/10',
        ),
        _MaternityGlbStatusChip(
          icon: Icons.event_seat_outlined,
          label: 'Libres',
          value: free.toString(),
        ),
        FilledButton.icon(
          onPressed: onFeedAll,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff1f7654),
            foregroundColor: Colors.white,
            elevation: 5,
            shadowColor: Colors.black.withValues(alpha: .18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.restaurant_outlined, size: 18),
          label: const Text(
            'Se alimentó a todas',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _MaternityGlbStatusChip extends StatelessWidget {
  const _MaternityGlbStatusChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdbe7df)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xff176b4d)),
            const SizedBox(width: 8),
            Text(
              '$value $label',
              style: const TextStyle(
                color: Color(0xff24332c),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaternityFeedSummary extends StatelessWidget {
  const _MaternityFeedSummary({
    required this.record,
    required this.onAddCup,
    required this.onAdjust,
  });

  final _MaternityFeedRecord record;
  final VoidCallback onAddCup;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final feedText = record.hasFeed
        ? '${record.cups} vaso(s) · ${record.kilograms} kg'
        : 'Sin alimento registrado';
    final dateText = record.updatedAt == null
        ? '1 vaso equivale a 1 kg'
        : 'Actualizado: ${_formatDate(record.updatedAt)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfff3fbf6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffcfe4d8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_drink_outlined,
                  color: Color(0xff176b4d),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Alimento de hoy',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  feedText,
                  style: const TextStyle(
                    color: Color(0xff176b4d),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateText,
              style: const TextStyle(
                color: Color(0xff5c7165),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAddCup,
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar 1 vaso'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAdjust,
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('Ajustar vasos'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MaternityTopDownPlan extends StatelessWidget {
  const _MaternityTopDownPlan({required this.crates, required this.onCrateTap});

  final List<GestationCrate> crates;
  final ValueChanged<GestationCrate> onCrateTap;

  @override
  Widget build(BuildContext context) {
    final topCrates = crates.where((crate) => crate.number <= 5).toList();
    final bottomCrates = crates.where((crate) => crate.number > 5).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff3c3f3c), Color(0xff232624)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffd5d0c5),
              border: Border.all(color: const Color(0xffaaa79f), width: 7),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 22,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MaternityPlanSideWall(
                        side: 'superior',
                        alignment: Alignment.centerRight,
                      ),
                      const SizedBox(height: 8),
                      _MaternityCrateRow(
                        crates: topCrates,
                        onCrateTap: onCrateTap,
                        sowPointsDown: true,
                        compact: compact,
                      ),
                      const SizedBox(height: 10),
                      _MaternityCentralWalkway(compact: compact),
                      const SizedBox(height: 10),
                      _MaternityCrateRow(
                        crates: bottomCrates,
                        onCrateTap: onCrateTap,
                        sowPointsDown: false,
                        compact: compact,
                      ),
                      const SizedBox(height: 8),
                      _MaternityPlanSideWall(
                        side: 'inferior',
                        alignment: Alignment.centerLeft,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaternityPlanSideWall extends StatelessWidget {
  const _MaternityPlanSideWall({required this.side, required this.alignment});

  final String side;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        children: [
          Align(
            alignment: alignment,
            child: Container(
              width: 92,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xffedf0e7),
                border: Border.all(color: const Color(0xffb6b9af)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (_) => Container(width: 18, color: const Color(0xffc9d2c4)),
                ),
              ),
            ),
          ),
          Align(
            alignment: side == 'superior' ? Alignment.center : Alignment.center,
            child: Container(
              width: 70,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xffaa8962),
                border: Border.all(color: const Color(0xff735536), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaternityCrateRow extends StatelessWidget {
  const _MaternityCrateRow({
    required this.crates,
    required this.onCrateTap,
    required this.sowPointsDown,
    required this.compact,
  });

  final List<GestationCrate> crates;
  final ValueChanged<GestationCrate> onCrateTap;
  final bool sowPointsDown;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final crate in crates)
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 5),
            child: _MaternityCrateCell(
              crate: crate,
              onTap: onCrateTap,
              sowPointsDown: sowPointsDown,
              compact: compact,
            ),
          ),
        ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _MaternityCrateCell extends StatelessWidget {
  const _MaternityCrateCell({
    required this.crate,
    required this.onTap,
    required this.sowPointsDown,
    required this.compact,
  });

  final GestationCrate crate;
  final ValueChanged<GestationCrate> onTap;
  final bool sowPointsDown;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = _CrateVisual.fromStatus(crate.status);
    final occupied = crate.isOccupied;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => onTap(crate),
        child: AspectRatio(
          aspectRatio: compact ? 1.02 : 1.12,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff2b8134), Color(0xff14501f)],
              ),
              border: Border.all(color: const Color(0xffeee9df), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(7, 9),
                ),
                BoxShadow(
                  color: Color(0x55ffffff),
                  blurRadius: 2,
                  offset: Offset(-2, -2),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _GreenSlatFloor(),
                Positioned.fill(child: _MaternityCrateBars(compact: compact)),
                if (occupied)
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 18 : 28,
                        vertical: compact ? 12 : 18,
                      ),
                      child: Transform.rotate(
                        angle: sowPointsDown ? 0 : math.pi,
                        child: CustomPaint(
                          painter: _SowTopViewPainter(
                            bodyColor: const Color(0xffd9aca1),
                            shadowColor: const Color(0x66000000),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: visual.chip,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: visual.border),
                    ),
                    child: Text(
                      crate.sideNumber.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w900,
                        color: visual.textColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: visual.background.withValues(alpha: .93),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: visual.border),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 5 : 7,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            visual.icon,
                            size: compact ? 13 : 15,
                            color: visual.iconColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              crate.earTag ?? 'Libre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 10 : 12,
                                fontWeight: FontWeight.w900,
                                color: visual.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!occupied)
                  Center(
                    child: Icon(
                      Icons.add_circle_outline,
                      color: visual.iconColor.withValues(alpha: .72),
                      size: compact ? 24 : 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreenSlatFloor extends StatelessWidget {
  const _GreenSlatFloor();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SlattedFloorPainter());
  }
}

class _SlattedFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xff1f6829);
    canvas.drawRect(Offset.zero & size, base);

    final line = Paint()
      ..color = const Color(0xff0e3519)
      ..strokeWidth = math.max(1.0, size.width * .018);
    final gap = size.width / 9;
    for (var x = gap; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }

    final cross = Paint()
      ..color = const Color(0x552f8d3f)
      ..strokeWidth = 1;
    final rowGap = size.height / 8;
    for (var y = rowGap; y < size.height; y += rowGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), cross);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MaternityCrateBars extends StatelessWidget {
  const _MaternityCrateBars({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MaternityCrateBarsPainter(compact: compact));
  }
}

class _MaternityCrateBarsPainter extends CustomPainter {
  const _MaternityCrateBarsPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = const Color(0xff9da49e)
      ..strokeWidth = compact ? 2.1 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final darkRail = Paint()
      ..color = const Color(0xff4e5751)
      ..strokeWidth = compact ? 1.1 : 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = size.width * .24;
    final right = size.width * .76;
    final top = size.height * .08;
    final bottom = size.height * .92;
    final radius = Radius.circular(size.width * .08);

    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), rail);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(size.width * .035), radius),
      darkRail,
    );

    for (final x in [
      left,
      left + size.width * .08,
      right - size.width * .08,
      right,
    ]) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), darkRail);
    }

    final gateTop = size.height * .14;
    final gateBottom = size.height * .30;
    final gateRect = Rect.fromLTRB(
      size.width * .30,
      gateTop,
      size.width * .70,
      gateBottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(gateRect, Radius.circular(size.width * .04)),
      rail,
    );

    final feeder = Paint()
      ..color = const Color(0xffd9ddd4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * .86, size.height * .14),
      size.width * .075,
      feeder,
    );
    canvas.drawCircle(
      Offset(size.width * .86, size.height * .14),
      size.width * .045,
      Paint()..color = const Color(0xff8d938d),
    );
  }

  @override
  bool shouldRepaint(covariant _MaternityCrateBarsPainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _SowTopViewPainter extends CustomPainter {
  const _SowTopViewPainter({
    required this.bodyColor,
    required this.shadowColor,
  });

  final Color bodyColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.28, -.35),
        radius: .95,
        colors: [const Color(0xfff0cfc6), bodyColor, const Color(0xffb98279)],
        stops: const [.0, .62, 1],
      ).createShader(Offset.zero & size);
    final bodyEdge = Paint()
      ..color = const Color(0x55a86c65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.width * .025);
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.2, -.25),
        radius: .9,
        colors: const [Color(0xfff2d2ca), Color(0xffc99389)],
      ).createShader(Offset.zero & size);
    final ear = Paint()..color = const Color(0xffc99088);
    final snout = Paint()..color = const Color(0xffe0aa9e);
    final hoof = Paint()..color = const Color(0xff9f655f);

    final bodyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .57),
      width: size.width * .64,
      height: size.height * .70,
    );
    canvas.drawOval(
      bodyRect.shift(Offset(size.width * .04, size.height * .04)),
      shadow,
    );
    canvas.drawOval(bodyRect, body);
    canvas.drawOval(bodyRect, bodyEdge);

    final spine = Paint()
      ..color = const Color(0x44fff8f2)
      ..strokeWidth = math.max(2, size.width * .035)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .5, size.height * .30),
      Offset(size.width * .5, size.height * .78),
      spine,
    );

    final headRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .19),
      width: size.width * .42,
      height: size.height * .27,
    );
    canvas.drawOval(
      headRect.shift(Offset(size.width * .025, size.height * .02)),
      shadow,
    );
    canvas.drawOval(headRect, headPaint);
    canvas.drawOval(headRect, bodyEdge);

    final leftEar = Path()
      ..moveTo(size.width * .34, size.height * .10)
      ..quadraticBezierTo(
        size.width * .22,
        size.height * .03,
        size.width * .27,
        size.height * .20,
      )
      ..quadraticBezierTo(
        size.width * .34,
        size.height * .18,
        size.width * .34,
        size.height * .10,
      );
    final rightEar = Path()
      ..moveTo(size.width * .66, size.height * .10)
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .03,
        size.width * .73,
        size.height * .20,
      )
      ..quadraticBezierTo(
        size.width * .66,
        size.height * .18,
        size.width * .66,
        size.height * .10,
      );
    canvas.drawPath(leftEar, ear);
    canvas.drawPath(rightEar, ear);

    final snoutRect = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .13),
      width: size.width * .24,
      height: size.height * .10,
    );
    canvas.drawOval(snoutRect, snout);
    final nostril = Paint()..color = const Color(0xff70443f);
    canvas.drawCircle(
      Offset(size.width * .46, size.height * .13),
      size.width * .012,
      nostril,
    );
    canvas.drawCircle(
      Offset(size.width * .54, size.height * .13),
      size.width * .012,
      nostril,
    );

    final legPaint = Paint()
      ..color = const Color(0xffc58e83)
      ..style = PaintingStyle.fill;
    for (final point in [
      Offset(size.width * .24, size.height * .40),
      Offset(size.width * .76, size.height * .40),
      Offset(size.width * .25, size.height * .72),
      Offset(size.width * .75, size.height * .72),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: point,
            width: size.width * .14,
            height: size.height * .065,
          ),
          Radius.circular(size.width * .04),
        ),
        legPaint,
      );
      canvas.drawCircle(
        Offset(point.dx, point.dy + size.height * .036),
        size.width * .025,
        hoof,
      );
    }

    final tail = Paint()
      ..color = const Color(0xffb87f77)
      ..strokeWidth = math.max(1.6, size.width * .022)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(size.width * .50, size.height * .92)
      ..cubicTo(
        size.width * .58,
        size.height * .97,
        size.width * .42,
        size.height * .99,
        size.width * .49,
        size.height * .94,
      );
    canvas.drawPath(tailPath, tail);
  }

  @override
  bool shouldRepaint(covariant _SowTopViewPainter oldDelegate) => false;
}

class _MaternityCentralWalkway extends StatelessWidget {
  const _MaternityCentralWalkway({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 64 : 92,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _CentralWalkwayPainter()),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xffc6c1b5).withValues(alpha: .92),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xff918d84)),
              ),
              child: const Text(
                'PASILLO CENTRAL',
                style: TextStyle(
                  color: Color(0xff514e48),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CentralWalkwayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xffbcb7ac);
    canvas.drawRect(Offset.zero & size, base);

    final groove = Paint()
      ..color = const Color(0xff6b6860)
      ..strokeWidth = 1.4;
    final gap = size.width / 52;
    for (var x = gap; x < size.width; x += gap * 1.45) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), groove);
    }

    final edge = Paint()
      ..color = const Color(0xff8c887e)
      ..strokeWidth = 4;
    canvas.drawLine(Offset(0, 1), Offset(size.width, 1), edge);
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      edge,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BoarBarnPage extends StatefulWidget {
  const BoarBarnPage({super.key});

  @override
  State<BoarBarnPage> createState() => _BoarBarnPageState();
}

class _BoarBarnPageState extends State<BoarBarnPage> {
  @override
  void initState() {
    super.initState();
    BoarCorralBridge.register(_openBoarCorralByNumber);
  }

  @override
  void dispose() {
    BoarCorralBridge.unregister(_openBoarCorralByNumber);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verracos',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '3 jaulas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<List<BoarRecord>>(
          valueListenable: _boarRecords,
          builder: (context, boars, _) {
            return ValueListenableBuilder<Map<int, int>>(
              valueListenable: _boarMatingCounts,
              builder: (context, matingCounts, _) {
                final active = boars.where((boar) => boar.isRegistered).length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle(
                        title: 'Corales de verracos',
                        action: '$active/3 activos',
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _BoarGlbPreview(
                          boars: boars,
                          matingCounts: matingCounts,
                          onCorralTap: _openBoarCorralByNumber,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openBoarCorralByNumber(int corralNumber) {
    if (!mounted) return;
    BoarRecord? boar;
    for (final item in _boarRecords.value) {
      if (item.number == corralNumber) {
        boar = item;
        break;
      }
    }
    if (boar == null) return;
    _openBoarEditor(context, boar, _matingCountForBoar(boar));
  }

  int _matingCountForBoar(BoarRecord boar) {
    return _boarMatingCounts.value[boar.number] ?? 0;
  }

  Future<void> _openBoarEditor(
    BuildContext context,
    BoarRecord boar,
    int matingCount,
  ) async {
    final nameController = TextEditingController(text: boar.name);
    final bloodlineController = TextEditingController(text: boar.bloodline);

    final updated = await showDialog<BoarRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            boar.isRegistered
                ? 'Editar verraco ${boar.number}'
                : 'Registrar verraco ${boar.number}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffeef7f1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xffcfe1d5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Montas registradas',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      _formatMatingCount(matingCount),
                      style: const TextStyle(
                        color: Color(0xff176b4d),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bloodlineController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Línea de sangre',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  boar.copyWith(
                    name: nameController.text.trim(),
                    bloodline: bloodlineController.text.trim(),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    bloodlineController.dispose();

    if (updated != null) {
      _saveBoar(updated);
    }
  }

  // ignore: unused_element
  Future<void> _clearBoar(BuildContext context, BoarRecord boar) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Limpiar jaula ${boar.number}'),
          content: Text(
            '¿Quieres quitar el registro de ${boar.name} de este coral?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Limpiar'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _saveBoar(boar.cleared());
    }
  }

  void _saveBoar(BoarRecord updated) {
    _boarRecords.value = [
      for (final boar in _boarRecords.value)
        if (boar.number == updated.number) updated else boar,
    ];
    _persistBoarRecords();
  }
}

class _BoarGlbPreview extends StatelessWidget {
  const _BoarGlbPreview({
    required this.boars,
    required this.matingCounts,
    required this.onCorralTap,
  });

  final List<BoarRecord> boars;
  final Map<int, int> matingCounts;
  final ValueChanged<int> onCorralTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              src: modelViewerWebAssetSrc('assets/models/verracos.glb'),
              alt: 'Modelo 3D de tres corrales de verracos',
              cameraControls: true,
              cameraOrbit: '-38deg 58deg 28m',
              cameraTarget: '0m 1.4m 0m',
              autoRotate: false,
              backgroundColor: const Color(0xffedf5f1),
              shadowIntensity: 0.95,
              shadowSoftness: 0.74,
              exposure: 1.12,
              fieldOfView: '31deg',
              minFieldOfView: '20deg',
              maxFieldOfView: '54deg',
              interactionPrompt: InteractionPrompt.auto,
              loading: Loading.eager,
              reveal: Reveal.auto,
              touchAction: TouchAction.none,
              innerModelViewerHtml: _hotspotsHtml(boars, matingCounts),
              minHotspotOpacity: 0.18,
              maxHotspotOpacity: 1,
              relatedCss: _boarModelCss,
              relatedJs: _boarModelJs,
              javascriptChannels: !kIsWeb
                  ? {_numberTapNativeChannel('BoarCorralNative', onCorralTap)}
                  : null,
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
          Positioned(
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Text(
                  'Toca un corral para editar',
                  style: TextStyle(
                    color: Color(0xff176b4d),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hotspotsHtml(List<BoarRecord> boars, Map<int, int> matingCounts) {
    const xCenters = [-10.4, 0.0, 10.4];
    return boars
        .map((boar) {
          final index = (boar.number - 1).clamp(0, xCenters.length - 1);
          final x = xCenters[index];
          final number = boar.number.toString().padLeft(2, '0');
          final name = _escapeHtml(boar.isRegistered ? boar.name : 'Libre');
          final matingCount = matingCounts[boar.number] ?? 0;
          final detail = boar.isRegistered
              ? _formatMatingCount(matingCount)
              : 'Sin registro';
          final counter = _escapeHtml(detail);
          final stateClass = boar.isRegistered ? 'active' : 'free';
          final tapScript =
              "event.preventDefault();event.stopPropagation();if(window.BoarCorralNative&&window.BoarCorralNative.postMessage){window.BoarCorralNative.postMessage('${boar.number}');}window.dispatchEvent(new CustomEvent('boar-corral-tap',{detail:'${boar.number}'}));document.dispatchEvent(new CustomEvent('boar-corral-tap',{detail:'${boar.number}'}));window.parent.postMessage(JSON.stringify({type:'boar-corral-tap',corral:${boar.number}}),'*');";

          return '''
<button class="boar-corral-hitbox" slot="hotspot-boar-corral-hit-${boar.number}" data-corral="${boar.number}" data-position="${x}m 0.9m 0m" data-normal="0m 1m 0m" aria-label="Abrir corral $number" onclick="$tapScript"></button>
<button class="boar-corral-label $stateClass" slot="hotspot-boar-corral-label-${boar.number}" data-corral="${boar.number}" data-position="${x}m 2.25m 0m" data-normal="0m 1m 0m" aria-label="Editar corral $number" onclick="$tapScript">
  <span class="corral-number">$number</span>
  <span class="corral-name">$name</span>
  <span class="corral-line">$counter</span>
</button>
''';
        })
        .join('\n');
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static const String _boarModelCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #edf5f1;
}

.boar-corral-hitbox {
  background: transparent;
  border: 0;
  cursor: pointer;
  display: block;
  height: 128px;
  opacity: 0;
  padding: 0;
  pointer-events: auto;
  transform: translate(-50%, -50%);
  width: 148px;
}

.boar-corral-hitbox:focus,
.boar-corral-hitbox:hover {
  background: transparent;
  box-shadow: none;
  outline: none;
}

.boar-corral-label {
  align-items: center;
  background: rgba(255, 255, 255, 0.78);
  border: 1px solid rgba(210, 224, 214, 0.72);
  border-radius: 9px;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
  color: #24332c;
  cursor: pointer;
  display: inline-grid;
  font: 800 10px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  gap: 1px;
  grid-template-columns: auto 1fr;
  line-height: 1.05;
  min-width: 78px;
  padding: 4px 6px;
  pointer-events: auto;
  text-align: left;
  transform: translate(-50%, -125%);
  white-space: nowrap;
}

.boar-corral-label:focus,
.boar-corral-label:hover {
  box-shadow: 0 10px 26px rgba(15, 102, 70, 0.24);
  outline: none;
}

.boar-corral-label .corral-number {
  align-items: center;
  border-radius: 6px;
  display: inline-flex;
  height: 20px;
  justify-content: center;
  margin-right: 5px;
  width: 24px;
}

.boar-corral-label.active .corral-number {
  background: #ffd8c7;
  border: 1px solid #d28a6b;
  color: #5a2b1c;
}

.boar-corral-label.free .corral-number {
  background: #e8f3ec;
  border: 1px solid #abc7b4;
  color: #31513d;
}

.boar-corral-label .corral-name {
  color: #293c32;
  max-width: 84px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.boar-corral-label .corral-line {
  color: #587064;
  font-size: 8px;
  font-weight: 750;
  grid-column: 2;
  max-width: 84px;
  overflow: hidden;
  text-overflow: ellipsis;
}
''';

  static const String _boarModelJs = '''
(function () {
  function openCorral(corralNumber) {
    if (!corralNumber) return;
    const detail = String(corralNumber);
    if (window.BoarCorralNative &&
        typeof window.BoarCorralNative.postMessage === 'function') {
      window.BoarCorralNative.postMessage(detail);
    }
    window.dispatchEvent(new CustomEvent('boar-corral-tap', { detail }));
    document.dispatchEvent(new CustomEvent('boar-corral-tap', { detail }));
    if (window.parent && window.parent !== window) {
      window.parent.dispatchEvent(new CustomEvent('boar-corral-tap', {
        detail: detail
      }));
    }
    if (window.parent) {
      window.parent.postMessage(JSON.stringify({
        type: 'boar-corral-tap',
        corral: Number(detail)
      }), '*');
    }
  }

  function wireViewer(viewer) {
    if (!viewer || viewer.__boarCorralTapReady) return;
    if (!viewer.src || !viewer.src.includes('verracos.glb')) return;
    viewer.__boarCorralTapReady = true;

    const corrals = [
      { id: 1, x: -10.4, z: 0, w: 8.8, d: 8.8 },
      { id: 2, x: 0.0, z: 0, w: 8.8, d: 8.8 },
      { id: 3, x: 10.4, z: 0, w: 8.8, d: 8.8 }
    ];

    let pointerStart = null;

    viewer.addEventListener('pointerdown', function (event) {
      pointerStart = { x: event.clientX, y: event.clientY };
    });

    viewer.addEventListener('click', function (event) {
      const hotspot = event.target && event.target.closest
        ? event.target.closest('.boar-corral-label, .boar-corral-hitbox')
        : null;
      if (hotspot) {
        event.preventDefault();
        event.stopPropagation();
        openCorral(hotspot.dataset.corral);
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
      const corral = corrals.find(function (item) {
        return point.x >= item.x - item.w / 2 &&
          point.x <= item.x + item.w / 2 &&
          point.z >= item.z - item.d / 2 &&
          point.z <= item.z + item.d / 2;
      });

      if (!corral) return;
      event.preventDefault();
      event.stopPropagation();
      openCorral(corral.id);
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

// ignore: unused_element
class _BoarCorralCard extends StatelessWidget {
  const _BoarCorralCard({
    required this.boar,
    required this.onEdit,
    required this.onClear,
  });

  final BoarRecord boar;
  final VoidCallback onEdit;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final active = boar.isRegistered;

    return SizedBox(
      height: 170,
      child: Card(
        color: active ? const Color(0xfffff7f2) : const Color(0xfff4f7f3),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xffffd8c7)
                            : const Color(0xffe1ece5),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: active
                              ? const Color(0xffd28a6b)
                              : const Color(0xffc9d8cf),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          boar.number.toString().padLeft(2, '0'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.male_outlined,
                      color: active
                          ? const Color(0xffa65332)
                          : const Color(0xff617067),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  active ? boar.name : 'Coral libre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  active ? boar.bloodline : 'Sin línea registrada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff617067),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: Icon(active ? Icons.edit_outlined : Icons.add),
                        label: Text(active ? 'Editar' : 'Registrar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Limpiar',
                      onPressed: onClear,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<GestationCrate> _createMaternityPreviewCrates(String barnName) {
  return List.generate(10, (index) {
    final number = index + 1;
    final occupiedLimit = barnName == 'Maternidad 1' ? 7 : 6;
    final tagPrefix = barnName == 'Maternidad 1' ? 'M1' : 'M2';
    return GestationCrate(
      number: number,
      side: number <= 5 ? 'Izquierda' : 'Derecha',
      sideNumber: number <= 5 ? number : number - 5,
      earTag: number <= occupiedLimit ? '$tagPrefix-${3100 + number}' : null,
      matingDates: const [],
      matingBoars: const [],
      farrowingRecord: null,
      abortionRecord: null,
      heatCheckDone: false,
    );
  });
}

List<GestationCrate> _createGestationTransferCandidates() {
  final today = _dateOnly(DateTime.now());
  final limit = today.add(const Duration(days: 14));
  final candidates =
      List.generate(_totalGestationCrateCount, (index) {
        final number = index + 1;
        final side = number <= _leftGestationCrateCount
            ? 'Izquierda'
            : 'Derecha';
        final sideNumber = number <= _leftGestationCrateCount
            ? number
            : number - _leftGestationCrateCount;
        final isOccupied = number % 9 != 0 && number % 17 != 0;
        final days = number == 5
            ? 21
            : number % 5 == 0
            ? 8 + number % 9
            : 28 + (number * 3) % 86;
        final matingDates = switch (number) {
          _ when !isOccupied => const <DateTime>[],
          _ when number % 13 == 0 => const <DateTime>[],
          _ when number % 11 == 0 => _previewMatingDatesInProgress(1),
          _ when number % 7 == 0 => _previewMatingDatesInProgress(2),
          _ => _previewMatingDatesForDays(days),
        };
        return GestationCrate(
          number: number,
          side: side,
          sideNumber: sideNumber,
          earTag: isOccupied ? 'G-${2400 + number}' : null,
          matingDates: matingDates,
          matingBoars: _previewBoarAssignments(matingDates.length),
          farrowingRecord: null,
          abortionRecord: null,
          heatCheckDone: isOccupied && matingDates.length == 3 && days > 21,
        );
      }).where((crate) {
        final transferDate = crate.transferToMaternityDate;
        return crate.status == ReproductiveStatus.confirmed &&
            transferDate != null &&
            !transferDate.isAfter(limit);
      }).toList();

  candidates.sort((a, b) {
    return a.transferToMaternityDate!.compareTo(b.transferToMaternityDate!);
  });
  return candidates;
}

List<DateTime> _previewMatingDatesInProgress(int count) {
  final today = _dateOnly(DateTime.now());
  return List.generate(
    count,
    (index) => today.subtract(Duration(days: count - index - 1)),
  );
}

List<DateTime> _previewMatingDatesForDays(int days) {
  final thirdMating = _dateOnly(DateTime.now()).subtract(Duration(days: days));
  return [
    thirdMating.subtract(const Duration(days: 2)),
    thirdMating.subtract(const Duration(days: 1)),
    thirdMating,
  ];
}

List<String?> _previewBoarAssignments(int count) {
  final boars = _activeBoarLabels();
  if (boars.isEmpty) {
    return List<String?>.filled(count, null);
  }
  return List.generate(count, (index) => boars[index % boars.length]);
}

class _EmptyFarrowingRecord extends StatelessWidget {
  const _EmptyFarrowingRecord({required this.onCreate, required this.onAbort});

  final VoidCallback onCreate;
  final VoidCallback onAbort;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xfffffbeb),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sin registro de parto',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Registra nacidos, muertos, machos, hembras y observaciones.',
              style: TextStyle(
                color: Color(0xff617067),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Registrar parto'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAbort,
                icon: const Icon(Icons.heart_broken_outlined),
                label: const Text('Registrar aborto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaternityEmptyCrateNotice extends StatelessWidget {
  const _MaternityEmptyCrateNotice({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xfff3f7f4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.event_seat_outlined, color: Color(0xff617067)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Primero agrega una chancha a esta jaula para registrar parto.',
                    style: TextStyle(
                      color: Color(0xff617067),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Se mostrarán las opciones de gestación cercanas a parir.',
              style: TextStyle(
                color: Color(0xff617067),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Agregar chancha'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GestationSowTransferPicker extends StatelessWidget {
  const _GestationSowTransferPicker({required this.candidates});

  final List<GestationCrate> candidates;

  @override
  Widget build(BuildContext context) {
    final left = candidates
        .where((crate) => crate.side == 'Izquierda')
        .toList();
    final right = candidates.where((crate) => crate.side == 'Derecha').toList();
    final rowCount = math.max(left.length, right.length);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .76,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(
                'Agregar chancha',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(
                'Selecciona una chancha de gestación próxima a parir.',
                style: TextStyle(
                  color: Color(0xff617067),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay chanchas próximas a traslado.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _GestationSowTransferSide(
                                    title: 'Gestación izquierda',
                                    crates: left,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _GestationMoveAisle(rowCount: rowCount),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _GestationSowTransferSide(
                                    title: 'Gestación derecha',
                                    crates: right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GestationSowTransferSide extends StatelessWidget {
  const _GestationSowTransferSide({required this.title, required this.crates});

  final String title;
  final List<GestationCrate> crates;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (crates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Sin candidatas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff617067),
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          for (final crate in crates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GestationSowTransferTile(crate: crate),
            ),
      ],
    );
  }
}

class _GestationSowTransferTile extends StatelessWidget {
  const _GestationSowTransferTile({required this.crate});

  final GestationCrate crate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Card(
        color: const Color(0xffeef9f0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pop(context, crate),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xffa8e5b4),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xff65b874)),
                  ),
                  child: Center(
                    child: Text(
                      crate.sideNumber.toString().padLeft(2, '0'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crate.earTag ?? 'Sin arete',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${crate.daysPregnant ?? 0} días · traslado ${_formatDate(crate.transferToMaternityDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff376642),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_outline, color: Color(0xff1f8d3a)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FarrowingRecordDetail extends StatelessWidget {
  const _FarrowingRecordDetail({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final FarrowingRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Registro de parto',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(
                    color: Color(0xff176b4d),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FarrowingChip(label: 'Total', value: record.totalBorn),
                _FarrowingChip(label: 'Vivos', value: record.bornAlive),
                _FarrowingChip(label: 'Muertos', value: record.dead),
                _FarrowingChip(label: 'Machos', value: record.males),
                _FarrowingChip(label: 'Hembras', value: record.females),
                _FarrowingChip(label: 'Momificados', value: record.mummified),
              ],
            ),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                record.notes,
                style: const TextStyle(
                  color: Color(0xff617067),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MaternityModelCard extends StatelessWidget {
  const _MaternityModelCard({required this.title, required this.onOpen});

  final String title;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.view_in_ar,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: const Text(
          'Modelo 3D de maternidad',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('$title · 10 jaulas · 5 por lado'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

class _AbortionRecordDetail extends StatelessWidget {
  const _AbortionRecordDetail({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final AbortionRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xfffff7f7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Registro de aborto',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(
                    color: Color(0xffb74d58),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FarrowingChip(label: 'Abortados', value: record.lostCount),
                _FarrowingChip(
                  label: 'Días gestación',
                  value: record.gestationDays,
                ),
              ],
            ),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                record.notes,
                style: const TextStyle(
                  color: Color(0xff617067),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FarrowingChip extends StatelessWidget {
  const _FarrowingChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xffeef9f0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffcce2d0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _GestationStat extends StatelessWidget {
  const _GestationStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xff617067),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostWeaningSyncCard extends StatelessWidget {
  const _PostWeaningSyncCard({required this.batch, required this.onProgram});

  final SynchronizationBatch? batch;
  final VoidCallback onProgram;

  @override
  Widget build(BuildContext context) {
    final active = batch != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xffeef6ff),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication_liquid_outlined,
                    color: Color(0xff1d6fae),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ampolla post-destete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        active
                            ? '${batch!.earTags.length} chanchas sincronizadas'
                            : 'Programa un grupo de 10 chanchas',
                        style: const TextStyle(
                          color: Color(0xff617067),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onProgram,
                  icon: Icon(active ? Icons.edit_outlined : Icons.add),
                  label: Text(active ? 'Editar' : 'Programar'),
                ),
              ],
            ),
            if (active) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SyncInfoChip(
                    label: 'Destete',
                    value: _formatDate(batch!.weaningDate),
                  ),
                  _SyncInfoChip(
                    label: 'Ampolla',
                    value: _formatDate(batch!.ampouleDate),
                  ),
                  _SyncInfoChip(
                    label: 'Celo',
                    value: _formatDate(batch!.heatDate),
                  ),
                  _SyncInfoChip(
                    label: 'Monta 1',
                    value: _formatDate(batch!.matingDates[0]),
                  ),
                  _SyncInfoChip(
                    label: 'Monta 2',
                    value: _formatDate(batch!.matingDates[1]),
                  ),
                  _SyncInfoChip(
                    label: 'Monta 3',
                    value: _formatDate(batch!.matingDates[2]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SyncSowPreview(earTags: batch!.earTags),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncInfoChip extends StatelessWidget {
  const _SyncInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xfff3f7f4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd7e2da)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff617067),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SyncSowPreview extends StatelessWidget {
  const _SyncSowPreview({required this.earTags});

  final List<String> earTags;

  @override
  Widget build(BuildContext context) {
    if (earTags.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfffffbeb),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffead68a)),
        ),
        child: const Text(
          'Todavía no seleccionaste chanchas.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffeef8f1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffcde5d4)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: earTags.map((tag) {
          return Chip(
            label: Text(tag),
            visualDensity: VisualDensity.compact,
            side: const BorderSide(color: Color(0xffb9d7c0)),
            backgroundColor: Colors.white,
          );
        }).toList(),
      ),
    );
  }
}

class _AmpouleSowSelector extends StatefulWidget {
  const _AmpouleSowSelector({
    required this.groups,
    required this.initialSelection,
    required this.maxSelection,
  });

  final List<_AmpouleSowGroup> groups;
  final List<String> initialSelection;
  final int maxSelection;

  @override
  State<_AmpouleSowSelector> createState() => _AmpouleSowSelectorState();
}

class _AmpouleSowSelectorState extends State<_AmpouleSowSelector> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .76,
        child: DefaultTabController(
          length: widget.groups.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Seleccionar chanchas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${_selected.length}/${widget.maxSelection}',
                      style: const TextStyle(
                        color: Color(0xff176b4d),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Text(
                  'Elige hasta 10 cerdas destetadas desde cualquier área.',
                  style: TextStyle(
                    color: Color(0xff617067),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TabBar(
                tabs: [
                  for (final group in widget.groups)
                    Tab(text: '${group.title} (${group.candidates.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final group in widget.groups)
                      _AmpouleSowGroupView(
                        group: group,
                        selected: _selected,
                        maxSelection: widget.maxSelection,
                        onToggle: _toggle,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                  _selected.take(widget.maxSelection).toList(),
                                );
                              },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(String earTag) {
    setState(() {
      if (_selected.contains(earTag)) {
        _selected.remove(earTag);
      } else if (_selected.length < widget.maxSelection) {
        _selected.add(earTag);
      }
    });
  }
}

class _AmpouleSowGroupView extends StatelessWidget {
  const _AmpouleSowGroupView({
    required this.group,
    required this.selected,
    required this.maxSelection,
    required this.onToggle,
  });

  final _AmpouleSowGroup group;
  final Set<String> selected;
  final int maxSelection;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final left = group.candidates
        .where((candidate) => candidate.side == 'Izquierda')
        .toList();
    final right = group.candidates
        .where((candidate) => candidate.side == 'Derecha')
        .toList();
    final rowCount = math.max(left.length, right.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        if (group.candidates.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay chanchas registradas en esta área.',
                style: TextStyle(
                  color: Color(0xff617067),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AmpouleSowColumn(
                      title: 'Izquierda',
                      candidates: left,
                      selected: selected,
                      maxSelection: maxSelection,
                      onToggle: onToggle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AmpouleSelectorAisle(rowCount: rowCount),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AmpouleSowColumn(
                      title: 'Derecha',
                      candidates: right,
                      selected: selected,
                      maxSelection: maxSelection,
                      onToggle: onToggle,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AmpouleSowGroup {
  const _AmpouleSowGroup({required this.title, required this.candidates});

  final String title;
  final List<_AmpouleSowCandidate> candidates;
}

class _AmpouleSowCandidate {
  const _AmpouleSowCandidate({
    required this.earTag,
    required this.side,
    required this.detail,
  });

  final String earTag;
  final String side;
  final String detail;
}

class _AmpouleSowColumn extends StatelessWidget {
  const _AmpouleSowColumn({
    required this.title,
    required this.candidates,
    required this.selected,
    required this.maxSelection,
    required this.onToggle,
  });

  final String title;
  final List<_AmpouleSowCandidate> candidates;
  final Set<String> selected;
  final int maxSelection;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (candidates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Sin chanchas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff617067),
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          for (final candidate in candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AmpouleSowButton(
                candidate: candidate,
                selected: selected.contains(candidate.earTag),
                disabled:
                    !selected.contains(candidate.earTag) &&
                    selected.length >= maxSelection,
                onTap: () => onToggle(candidate.earTag),
              ),
            ),
      ],
    );
  }
}

class _AmpouleSelectorAisle extends StatelessWidget {
  const _AmpouleSelectorAisle({required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: math.max(1, rowCount) * 66,
      decoration: BoxDecoration(
        color: const Color(0xffeef0e8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd7dfd6)),
      ),
      child: const RotatedBox(
        quarterTurns: 1,
        child: Center(
          child: Text(
            'DESTETADAS',
            style: TextStyle(
              color: Color(0xff66716a),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmpouleSowButton extends StatelessWidget {
  const _AmpouleSowButton({
    required this.candidate,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final _AmpouleSowCandidate candidate;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Card(
        color: selected ? const Color(0xfffff1f6) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? const Color(0xffc23d72)
                      : const Color(0xff617067),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.earTag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: disabled
                              ? const Color(0xff9aa59e)
                              : const Color(0xff17231d),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        candidate.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff617067),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmpouleAutoSchedulePreview extends StatelessWidget {
  const _AmpouleAutoSchedulePreview({required this.ampouleDate});

  final DateTime ampouleDate;

  @override
  Widget build(BuildContext context) {
    final heatDate = ampouleDate.add(const Duration(days: 3));
    final batch = SynchronizationBatch(
      weaningDate: ampouleDate,
      ampouleDate: ampouleDate,
      earTags: const [],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdf6f98)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendario automático',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          _PreviewLine(label: 'Entra en celo', value: _formatDate(heatDate)),
          _PreviewLine(
            label: 'Monta 1',
            value: _formatDate(batch.matingDates[0]),
          ),
          _PreviewLine(
            label: 'Monta 2',
            value: _formatDate(batch.matingDates[1]),
          ),
          _PreviewLine(
            label: 'Monta 3',
            value: _formatDate(batch.matingDates[2]),
          ),
        ],
      ),
    );
  }
}

class _GestationStatusLegend extends StatelessWidget {
  const _GestationStatusLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      _LegendItem(status: ReproductiveStatus.inHeat, text: 'En celo'),
      _LegendItem(status: ReproductiveStatus.inMating, text: 'En monta'),
      _LegendItem(status: ReproductiveStatus.observation, text: 'Observación'),
      _LegendItem(status: ReproductiveStatus.confirmed, text: 'Confirmada'),
      _LegendItem(status: ReproductiveStatus.empty, text: 'Libre'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final visual = _CrateVisual.fromStatus(item.status);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: visual.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: visual.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(visual.icon, size: 16, color: visual.iconColor),
                  const SizedBox(width: 6),
                  Text(
                    item.text,
                    style: TextStyle(
                      color: visual.textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LegendItem {
  const _LegendItem({required this.status, required this.text});

  final ReproductiveStatus status;
  final String text;
}

class _MatingDateField extends StatelessWidget {
  const _MatingDateField({
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: 'Limpiar fecha',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Text(
          date == null ? 'Seleccionar fecha' : _formatDate(date),
          style: TextStyle(
            fontWeight: date == null ? FontWeight.w500 : FontWeight.w800,
            color: date == null
                ? const Color(0xff617067)
                : const Color(0xff17231d),
          ),
        ),
      ),
    );
  }
}

class _BoarSelectorField extends StatelessWidget {
  const _BoarSelectorField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final boars = _activeBoarLabels();
    final selectedValue = boars.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.male_outlined),
      ),
      hint: const Text('Seleccionar verraco'),
      items: [
        for (final boar in boars)
          DropdownMenuItem(value: boar, child: Text(boar)),
      ],
      onChanged: enabled && boars.isNotEmpty ? onChanged : null,
    );
  }
}

class _GestationCalculationPreview extends StatelessWidget {
  const _GestationCalculationPreview({required this.crate});

  final GestationCrate crate;

  @override
  Widget build(BuildContext context) {
    if (crate.matingDates.length < 3) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfffffbeb),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffead68a)),
        ),
        child: const Text(
          'Registra las 3 montas para iniciar el conteo de gestación.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffeef8f1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffcde5d4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewLine(
            label: 'Inicio de conteo',
            value: _formatDate(crate.gestationStartDate),
          ),
          _PreviewLine(
            label: 'Días de gestación',
            value: '${crate.daysPregnant ?? 0}',
          ),
          _PreviewLine(
            label: 'Parto aprox.',
            value: _formatDate(crate.expectedFarrowingDate),
          ),
          _PreviewLine(
            label: 'Trasladar a maternidad',
            value: _formatDate(crate.transferToMaternityDate),
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff617067),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _GestationGlbBarnView extends StatelessWidget {
  const _GestationGlbBarnView({
    required this.viewerVersion,
    required this.crates,
    required this.onResetView,
    required this.onCrateTap,
  });

  final int viewerVersion;
  final List<GestationCrate> crates;
  final VoidCallback onResetView;
  final ValueChanged<int> onCrateTap;

  static const double _leftStartX = -24.7;
  static const double _rightStartX = -23.75;
  static const double _spacing = 1.9;
  static const double _leftZ = -4.75;
  static const double _rightZ = 4.75;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey(viewerVersion),
              src: modelViewerWebAssetSrc('assets/models/gestacion.glb'),
              alt: 'Modelo 3D de gestacion con 53 jaulas',
              cameraControls: true,
              cameraOrbit: '-42deg 58deg 76m',
              cameraTarget: '0m 1.25m 0m',
              autoRotate: false,
              backgroundColor: const Color(0xffedf5f1),
              shadowIntensity: 0.95,
              shadowSoftness: 0.74,
              exposure: 1.12,
              fieldOfView: '30deg',
              minFieldOfView: '18deg',
              maxFieldOfView: '56deg',
              interactionPrompt: InteractionPrompt.auto,
              loading: Loading.eager,
              reveal: Reveal.auto,
              touchAction: TouchAction.none,
              innerModelViewerHtml: _hotspotsHtml(crates),
              minHotspotOpacity: 0.12,
              maxHotspotOpacity: 1,
              relatedCss: _gestationModelCss,
              relatedJs: _gestationModelJs,
              javascriptChannels: !kIsWeb
                  ? {
                      _numberTapNativeChannel(
                        'GestationCrateNative',
                        onCrateTap,
                      ),
                    }
                  : null,
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
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: onResetView,
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Vista inicial'),
            ),
          ),
        ],
      ),
    );
  }

  String _hotspotsHtml(List<GestationCrate> crates) {
    return crates
        .map((crate) {
          final center = _centerForCrate(crate);
          final number = crate.sideNumber.toString().padLeft(2, '0');
          final stateClass = _statusClass(crate.status);
          final title = crate.earTag ?? 'Libre';
          final detail = crate.isOccupied
              ? crate.gestationSummary
              : 'Sin registro';
          final tapScript =
              "event.preventDefault();event.stopPropagation();if(window.GestationCrateNative&&window.GestationCrateNative.postMessage){window.GestationCrateNative.postMessage('${crate.number}');}window.dispatchEvent(new CustomEvent('gestation-crate-tap',{detail:'${crate.number}'}));document.dispatchEvent(new CustomEvent('gestation-crate-tap',{detail:'${crate.number}'}));window.parent.postMessage(JSON.stringify({type:'gestation-crate-tap',crate:${crate.number}}),'*');";

          return '''
<button class="gestation-crate-hitbox" slot="hotspot-gestation-crate-hit-${crate.number}" data-crate="${crate.number}" data-position="${center.x}m 0.9m ${center.z}m" data-normal="0m 1m 0m" aria-label="Abrir jaula $number" onclick="$tapScript"></button>
<button class="gestation-crate-label $stateClass" slot="hotspot-gestation-crate-label-${crate.number}" data-crate="${crate.number}" data-position="${center.x}m 1.95m ${center.z}m" data-normal="0m 1m 0m" title="${_escapeHtml(title)} - ${_escapeHtml(detail)}" aria-label="Abrir jaula $number" onclick="$tapScript">
  <span class="crate-number">$number</span>
</button>
''';
        })
        .join('\n');
  }

  static ({double x, double z}) _centerForCrate(GestationCrate crate) {
    if (crate.side == 'Izquierda') {
      return (x: _leftStartX + (crate.sideNumber - 1) * _spacing, z: _leftZ);
    }
    return (x: _rightStartX + (crate.sideNumber - 1) * _spacing, z: _rightZ);
  }

  String _statusClass(ReproductiveStatus status) {
    return switch (status) {
      ReproductiveStatus.empty => 'free',
      ReproductiveStatus.inHeat => 'heat',
      ReproductiveStatus.inMating => 'mating',
      ReproductiveStatus.observation => 'observation',
      ReproductiveStatus.confirmed => 'confirmed',
    };
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static const String _gestationModelCss = '''
model-viewer {
  --progress-bar-color: #176b4d;
  --progress-mask: #edf5f1;
}

.gestation-crate-label {
  align-items: center;
  background: rgba(255, 255, 255, 0.82);
  border: 1px solid rgba(210, 224, 214, 0.72);
  border-radius: 7px;
  box-shadow: 0 5px 14px rgba(0, 0, 0, 0.10);
  color: #24332c;
  cursor: pointer;
  display: inline-flex;
  font: 900 8px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  line-height: 1.02;
  padding: 2px;
  pointer-events: auto;
  text-align: left;
  transform: translate(-50%, -150%);
  white-space: nowrap;
}

.gestation-crate-hitbox {
  background: transparent;
  border: 0;
  cursor: pointer;
  display: block;
  height: 132px;
  opacity: 0;
  padding: 0;
  pointer-events: auto;
  transform: translate(-50%, -50%);
  width: 46px;
}

.gestation-crate-hitbox:focus,
.gestation-crate-hitbox:hover {
  background: transparent;
  box-shadow: none;
  outline: none;
}

.gestation-crate-label:focus,
.gestation-crate-label:hover {
  box-shadow: 0 9px 24px rgba(15, 102, 70, 0.22);
  outline: none;
}

.gestation-crate-label .crate-number {
  align-items: center;
  border-radius: 6px;
  display: inline-flex;
  height: 16px;
  justify-content: center;
  width: 20px;
}

.gestation-crate-label.free .crate-number {
  background: #edf5ef;
  border: 1px solid #b9d2c2;
  color: #31513d;
}

.gestation-crate-label.heat .crate-number {
  background: #ffa8c5;
  border: 1px solid #df6f98;
  color: #5c1430;
}

.gestation-crate-label.mating .crate-number {
  background: #b8dcff;
  border: 1px solid #7fb7ec;
  color: #163b5c;
}

.gestation-crate-label.observation .crate-number {
  background: #ffdf7f;
  border: 1px solid #dfb840;
  color: #4b3900;
}

.gestation-crate-label.confirmed .crate-number {
  background: #a8e5b4;
  border: 1px solid #65b874;
  color: #143e1d;
}
''';

  static const String _gestationModelJs = '''
(function () {
  function openCrate(crateNumber) {
    if (!crateNumber) return;
    const detail = String(crateNumber);
    if (window.GestationCrateNative &&
        typeof window.GestationCrateNative.postMessage === 'function') {
      window.GestationCrateNative.postMessage(detail);
    }
    window.dispatchEvent(new CustomEvent('gestation-crate-tap', { detail }));
    document.dispatchEvent(new CustomEvent('gestation-crate-tap', { detail }));
    if (window.parent && window.parent !== window) {
      window.parent.dispatchEvent(new CustomEvent('gestation-crate-tap', {
        detail: detail
      }));
    }
    if (window.parent) {
      window.parent.postMessage(JSON.stringify({
        type: 'gestation-crate-tap',
        crate: Number(detail)
      }), '*');
    }
  }

  function buildCrates() {
    const crates = [];
    for (let number = 1; number <= 27; number += 1) {
      crates.push({
        id: number,
        x: -24.7 + (number - 1) * 1.9,
        z: -4.75,
        w: 1.78,
        d: 4.9
      });
    }
    for (let side = 1; side <= 26; side += 1) {
      crates.push({
        id: 27 + side,
        x: -23.75 + (side - 1) * 1.9,
        z: 4.75,
        w: 1.78,
        d: 4.9
      });
    }
    return crates;
  }

  function wireViewer(viewer) {
    if (!viewer || viewer.__gestationCrateTapReady) return;
    if (!viewer.src || !viewer.src.includes('gestacion.glb')) return;
    viewer.__gestationCrateTapReady = true;

    const crates = buildCrates();
    let pointerStart = null;

    viewer.addEventListener('pointerdown', function (event) {
      pointerStart = { x: event.clientX, y: event.clientY };
    });

    viewer.addEventListener('click', function (event) {
      const hotspot = event.target && event.target.closest
        ? event.target.closest('.gestation-crate-label, .gestation-crate-hitbox')
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

class _CrateVisual {
  const _CrateVisual({
    required this.background,
    required this.chip,
    required this.border,
    required this.textColor,
    required this.subtleTextColor,
    required this.iconColor,
    required this.icon,
  });

  final Color background;
  final Color chip;
  final Color border;
  final Color textColor;
  final Color subtleTextColor;
  final Color iconColor;
  final IconData icon;

  factory _CrateVisual.fromStatus(ReproductiveStatus status) {
    return switch (status) {
      ReproductiveStatus.empty => const _CrateVisual(
        background: Color(0xfff3f7f4),
        chip: Color(0xffe1ece5),
        border: Color(0xffc9d8cf),
        textColor: Color(0xff26332d),
        subtleTextColor: Color(0xff617067),
        iconColor: Color(0xff617067),
        icon: Icons.add,
      ),
      ReproductiveStatus.inHeat => const _CrateVisual(
        background: Color(0xfffff1f6),
        chip: Color(0xffffa8c5),
        border: Color(0xffdf6f98),
        textColor: Color(0xff5c1430),
        subtleTextColor: Color(0xff8a4260),
        iconColor: Color(0xffc23d72),
        icon: Icons.favorite_border,
      ),
      ReproductiveStatus.inMating => const _CrateVisual(
        background: Color(0xffeef6ff),
        chip: Color(0xffb8dcff),
        border: Color(0xff7fb7ec),
        textColor: Color(0xff163b5c),
        subtleTextColor: Color(0xff42667f),
        iconColor: Color(0xff1d6fae),
        icon: Icons.water_drop_outlined,
      ),
      ReproductiveStatus.observation => const _CrateVisual(
        background: Color(0xfffffbeb),
        chip: Color(0xffffdf7f),
        border: Color(0xffdfb840),
        textColor: Color(0xff4b3900),
        subtleTextColor: Color(0xff7a620e),
        iconColor: Color(0xffa77900),
        icon: Icons.visibility_outlined,
      ),
      ReproductiveStatus.confirmed => const _CrateVisual(
        background: Color(0xffeef9f0),
        chip: Color(0xffa8e5b4),
        border: Color(0xff65b874),
        textColor: Color(0xff143e1d),
        subtleTextColor: Color(0xff376642),
        iconColor: Color(0xff1f8d3a),
        icon: Icons.check_circle_outline,
      ),
    };
  }
}

class _MoveDestinationPicker extends StatelessWidget {
  const _MoveDestinationPicker({
    required this.gestationCrates,
    required this.maternity1Crates,
    required this.maternity2Crates,
  });

  final List<GestationCrate> gestationCrates;
  final List<GestationCrate> maternity1Crates;
  final List<GestationCrate> maternity2Crates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .76,
        child: DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: Text(
                  'Mover a jaula',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: 'Gestación'),
                  Tab(text: 'Maternidad 1'),
                  Tab(text: 'Maternidad 2'),
                ],
              ),
              Expanded(child: _MoveDestinationTabs()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveDestinationTabs extends StatelessWidget {
  const _MoveDestinationTabs();

  @override
  Widget build(BuildContext context) {
    final picker = context
        .findAncestorWidgetOfExactType<_MoveDestinationPicker>();
    if (picker == null) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      children: [
        _GestationDestinationPlan(
          target: MoveTarget.gestation,
          crates: picker.gestationCrates,
        ),
        _MaternityDestinationPlan(
          target: MoveTarget.maternity1,
          crates: picker.maternity1Crates,
          title: 'Maternidad 1',
        ),
        _MaternityDestinationPlan(
          target: MoveTarget.maternity2,
          crates: picker.maternity2Crates,
          title: 'Maternidad 2',
        ),
      ],
    );
  }
}

class _GestationDestinationPlan extends StatelessWidget {
  const _GestationDestinationPlan({required this.target, required this.crates});

  final MoveTarget target;
  final List<GestationCrate> crates;

  @override
  Widget build(BuildContext context) {
    if (crates.isEmpty) {
      return const Center(
        child: Text(
          'No hay jaulas libres en este destino',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    final left = crates.where((crate) => crate.side == 'Izquierda').toList();
    final right = crates.where((crate) => crate.side == 'Derecha').toList();
    final rowCount = math.max(left.length, right.length);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Gestación',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Elige una jaula libre para mover, o una ocupada para intercambiar.',
          style: TextStyle(
            color: Color(0xff617067),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _GestationDestinationSide(
                    label: 'Izquierda',
                    crates: left,
                    target: target,
                  ),
                ),
                const SizedBox(width: 10),
                _GestationMoveAisle(rowCount: rowCount),
                const SizedBox(width: 10),
                Expanded(
                  child: _GestationDestinationSide(
                    label: 'Derecha',
                    crates: right,
                    target: target,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GestationDestinationSide extends StatelessWidget {
  const _GestationDestinationSide({
    required this.label,
    required this.crates,
    required this.target,
  });

  final String label;
  final List<GestationCrate> crates;
  final MoveTarget target;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final crate in crates)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _GestationDestinationButton(target: target, crate: crate),
          ),
      ],
    );
  }
}

class _GestationDestinationButton extends StatelessWidget {
  const _GestationDestinationButton({
    required this.target,
    required this.crate,
  });

  final MoveTarget target;
  final GestationCrate crate;

  @override
  Widget build(BuildContext context) {
    final destination = MoveDestination(target: target, crate: crate);
    final occupied = crate.isOccupied;

    return SizedBox(
      height: 56,
      child: Card(
        color: occupied ? const Color(0xfffff7f7) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pop(context, destination),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: occupied
                        ? const Color(0xfff4a3a8)
                        : const Color(0xffe9f2ed),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: occupied
                          ? const Color(0xffc65e68)
                          : const Color(0xffcbd9d0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      crate.sideNumber.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jaula ${crate.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        occupied ? crate.earTag! : 'Libre',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff617067),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  occupied ? 'Cambiar' : 'Mover',
                  style: TextStyle(
                    color: occupied
                        ? const Color(0xffb74d58)
                        : const Color(0xff176b4d),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GestationMoveAisle extends StatelessWidget {
  const _GestationMoveAisle({required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: rowCount * 63,
      decoration: BoxDecoration(
        color: const Color(0xffeef0e8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd7dfd6)),
      ),
      child: const RotatedBox(
        quarterTurns: 1,
        child: Center(
          child: Text(
            'PASILLO',
            style: TextStyle(
              color: Color(0xff66716a),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MaternityDestinationPlan extends StatelessWidget {
  const _MaternityDestinationPlan({
    required this.target,
    required this.crates,
    required this.title,
  });

  final MoveTarget target;
  final List<GestationCrate> crates;
  final String title;

  @override
  Widget build(BuildContext context) {
    final left = crates.where((crate) => crate.side == 'Izquierda').toList();
    final right = crates.where((crate) => crate.side == 'Derecha').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Seleccione una jaula libre para trasladar la chancha.',
          style: TextStyle(
            color: Color(0xff617067),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MaternitySideColumn(
                    label: 'Izquierda',
                    crates: left,
                    target: target,
                  ),
                ),
                const SizedBox(width: 10),
                const _MaternityAisle(),
                const SizedBox(width: 10),
                Expanded(
                  child: _MaternitySideColumn(
                    label: 'Derecha',
                    crates: right,
                    target: target,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MaternitySideColumn extends StatelessWidget {
  const _MaternitySideColumn({
    required this.label,
    required this.crates,
    required this.target,
  });

  final String label;
  final List<GestationCrate> crates;
  final MoveTarget target;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final crate in crates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MaternityCrateButton(target: target, crate: crate),
          ),
      ],
    );
  }
}

class _MaternityCrateButton extends StatelessWidget {
  const _MaternityCrateButton({required this.target, required this.crate});

  final MoveTarget target;
  final GestationCrate crate;

  @override
  Widget build(BuildContext context) {
    final destination = MoveDestination(target: target, crate: crate);

    return SizedBox(
      height: 58,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pop(context, destination),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xffe9f2ed),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xffcbd9d0)),
                  ),
                  child: Center(
                    child: Text(
                      crate.sideNumber.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jaula ${crate.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const Icon(Icons.add_circle_outline, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaternityAisle extends StatelessWidget {
  const _MaternityAisle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5 * 66,
      decoration: BoxDecoration(
        color: const Color(0xffeef0e8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd7dfd6)),
      ),
      child: const RotatedBox(
        quarterTurns: 1,
        child: Center(
          child: Text(
            'PASILLO',
            style: TextStyle(
              color: Color(0xff66716a),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

enum MoveTarget { gestation, maternity1, maternity2 }

class MoveDestination {
  const MoveDestination({required this.target, required this.crate});

  final MoveTarget target;
  final GestationCrate crate;

  bool get isSwap => target == MoveTarget.gestation && crate.isOccupied;

  String get label {
    return switch (target) {
      MoveTarget.gestation => 'Gestación',
      MoveTarget.maternity1 => 'Maternidad 1',
      MoveTarget.maternity2 => 'Maternidad 2',
    };
  }
}

const Object _unset = Object();

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

Future<DateTime?> _pickDate(BuildContext context, DateTime initialDate) async {
  final selected = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  return selected == null ? null : _dateOnly(selected);
}

Future<AbortionRecord?> _showAbortionRecordDialog(
  BuildContext context,
  GestationCrate crate,
) async {
  final current = crate.abortionRecord;
  var abortionDate = current?.date ?? _dateOnly(DateTime.now());
  final lostController = TextEditingController(
    text: (current?.lostCount ?? 0).toString(),
  );
  final daysController = TextEditingController(
    text: (current?.gestationDays ?? crate.daysPregnant ?? 0).toString(),
  );
  final notesController = TextEditingController(text: current?.notes ?? '');

  return showDialog<AbortionRecord>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(current == null ? 'Registrar aborto' : 'Editar aborto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MatingDateField(
                    label: 'Fecha de aborto',
                    date: abortionDate,
                    onPick: () async {
                      final selected = await _pickDate(context, abortionDate);
                      if (selected != null) {
                        setDialogState(() => abortionDate = selected);
                      }
                    },
                    onClear: null,
                  ),
                  const SizedBox(height: 10),
                  _NumberField(
                    controller: lostController,
                    label: 'Cantidad abortada',
                    icon: Icons.heart_broken_outlined,
                  ),
                  const SizedBox(height: 10),
                  _NumberField(
                    controller: daysController,
                    label: 'Días de gestación',
                    icon: Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    AbortionRecord(
                      date: abortionDate,
                      lostCount: _parseNonNegativeInt(lostController.text),
                      gestationDays: _parseNonNegativeInt(daysController.text),
                      notes: notesController.text.trim(),
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool?> _confirmDeleteAbortionRecord(
  BuildContext context,
  int crateNumber,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar aborto'),
        content: Text(
          '¿Quieres eliminar el registro de aborto de la jaula $crateNumber?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}

int _parseNonNegativeInt(String value) {
  return math.max(0, int.tryParse(value.trim()) ?? 0);
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '-';
  }
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

enum ReproductiveStatus { empty, inHeat, inMating, observation, confirmed }

class SynchronizationBatch {
  const SynchronizationBatch({
    required this.weaningDate,
    required this.ampouleDate,
    required this.earTags,
  });

  final DateTime weaningDate;
  final DateTime ampouleDate;
  final List<String> earTags;

  DateTime get heatDate => ampouleDate.add(const Duration(days: 3));

  List<DateTime> get matingDates {
    return [
      heatDate,
      heatDate.add(const Duration(days: 1)),
      heatDate.add(const Duration(days: 2)),
    ];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weaningDate': weaningDate.toIso8601String(),
    'ampouleDate': ampouleDate.toIso8601String(),
    'earTags': earTags,
  };

  factory SynchronizationBatch.fromJson(Map<String, dynamic> json) {
    return SynchronizationBatch(
      weaningDate: DateTime.parse(json['weaningDate'] as String),
      ampouleDate: DateTime.parse(json['ampouleDate'] as String),
      earTags: (json['earTags'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class BoarRecord {
  const BoarRecord({
    required this.number,
    required this.name,
    required this.bloodline,
  });

  final int number;
  final String name;
  final String bloodline;

  bool get isRegistered => name.trim().isNotEmpty;

  String get label {
    final cleanBloodline = bloodline.trim();
    if (cleanBloodline.isEmpty) {
      return name.trim();
    }
    return '${name.trim()} · $cleanBloodline';
  }

  BoarRecord copyWith({String? name, String? bloodline}) {
    return BoarRecord(
      number: number,
      name: name ?? this.name,
      bloodline: bloodline ?? this.bloodline,
    );
  }

  BoarRecord cleared() {
    return BoarRecord(number: number, name: '', bloodline: '');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'name': name,
    'bloodline': bloodline,
  };

  factory BoarRecord.fromJson(Map<String, dynamic> json) {
    return BoarRecord(
      number: (json['number'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      bloodline: json['bloodline'] as String? ?? '',
    );
  }
}

class FarrowingRecord {
  const FarrowingRecord({
    required this.date,
    required this.bornAlive,
    required this.dead,
    required this.males,
    required this.females,
    required this.mummified,
    required this.notes,
  });

  final DateTime date;
  final int bornAlive;
  final int dead;
  final int males;
  final int females;
  final int mummified;
  final String notes;

  int get totalBorn => bornAlive + dead + mummified;

  String get summary {
    return '$totalBorn nacidos · $bornAlive vivos · $dead muertos';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'date': date.toIso8601String(),
    'bornAlive': bornAlive,
    'dead': dead,
    'males': males,
    'females': females,
    'mummified': mummified,
    'notes': notes,
  };

  factory FarrowingRecord.fromJson(Map<String, dynamic> json) {
    return FarrowingRecord(
      date: DateTime.parse(json['date'] as String),
      bornAlive: (json['bornAlive'] as num?)?.toInt() ?? 0,
      dead: (json['dead'] as num?)?.toInt() ?? 0,
      males: (json['males'] as num?)?.toInt() ?? 0,
      females: (json['females'] as num?)?.toInt() ?? 0,
      mummified: (json['mummified'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class AbortionRecord {
  const AbortionRecord({
    required this.date,
    required this.lostCount,
    required this.gestationDays,
    required this.notes,
  });

  final DateTime date;
  final int lostCount;
  final int gestationDays;
  final String notes;

  String get summary {
    return 'Aborto · $lostCount perdidos · $gestationDays días';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'date': date.toIso8601String(),
    'lostCount': lostCount,
    'gestationDays': gestationDays,
    'notes': notes,
  };

  factory AbortionRecord.fromJson(Map<String, dynamic> json) {
    return AbortionRecord(
      date: DateTime.parse(json['date'] as String),
      lostCount: (json['lostCount'] as num?)?.toInt() ?? 0,
      gestationDays: (json['gestationDays'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class GestationCrate {
  const GestationCrate({
    required this.number,
    required this.side,
    required this.sideNumber,
    required this.earTag,
    required this.matingDates,
    required this.matingBoars,
    required this.farrowingRecord,
    required this.abortionRecord,
    required this.heatCheckDone,
  });

  final int number;
  final String side;
  final int sideNumber;
  final String? earTag;
  final List<DateTime> matingDates;
  final List<String?> matingBoars;
  final FarrowingRecord? farrowingRecord;
  final AbortionRecord? abortionRecord;
  final bool heatCheckDone;

  bool get isOccupied => earTag != null;

  ReproductiveStatus get status {
    if (!isOccupied) {
      return ReproductiveStatus.empty;
    }
    if (matingDates.isEmpty) {
      return ReproductiveStatus.inHeat;
    }
    if (matingDates.length < 3) {
      return ReproductiveStatus.inMating;
    }
    final days = daysPregnant ?? 0;
    if (days < 21 || !heatCheckDone) {
      return ReproductiveStatus.observation;
    }
    return ReproductiveStatus.confirmed;
  }

  bool get needsHeatCheck {
    final days = daysPregnant;
    return isOccupied &&
        matingDates.length >= 3 &&
        days != null &&
        days >= 21 &&
        !heatCheckDone;
  }

  String get statusLabel {
    return switch (status) {
      ReproductiveStatus.empty => 'Libre',
      ReproductiveStatus.inHeat => 'En celo',
      ReproductiveStatus.inMating => 'En monta',
      ReproductiveStatus.observation => 'Observación',
      ReproductiveStatus.confirmed => 'Confirmada',
    };
  }

  DateTime? get gestationStartDate {
    if (matingDates.length < 3) {
      return null;
    }
    return _dateOnly(matingDates[2]);
  }

  int? get daysPregnant {
    final start = gestationStartDate;
    if (start == null) {
      return null;
    }
    return _dateOnly(DateTime.now()).difference(start).inDays;
  }

  DateTime? get expectedFarrowingDate {
    final start = gestationStartDate;
    if (start == null) {
      return null;
    }
    return start.add(const Duration(days: 115));
  }

  DateTime? get transferToMaternityDate {
    final farrowing = expectedFarrowingDate;
    if (farrowing == null) {
      return null;
    }
    return farrowing.subtract(const Duration(days: 7));
  }

  String get gestationSummary {
    final abortion = abortionRecord;
    if (abortion != null) {
      return abortion.summary;
    }
    final farrowing = farrowingRecord;
    if (farrowing != null) {
      return farrowing.summary;
    }
    return switch (status) {
      ReproductiveStatus.empty => 'Sin registro',
      ReproductiveStatus.inHeat => 'En celo · lista para montar',
      ReproductiveStatus.inMating => 'En monta · ${matingDates.length}/3',
      ReproductiveStatus.observation =>
        '${daysPregnant ?? 0} días · observación',
      ReproductiveStatus.confirmed => '${daysPregnant ?? 0} días · confirmado',
    };
  }

  String get transferSummary {
    if (status != ReproductiveStatus.confirmed &&
        status != ReproductiveStatus.observation) {
      return statusLabel;
    }
    return 'traslado ${_formatDate(transferToMaternityDate)}';
  }

  GestationCrate copyWith({
    int? number,
    String? side,
    int? sideNumber,
    Object? earTag = _unset,
    Object? matingDates = _unset,
    Object? matingBoars = _unset,
    Object? farrowingRecord = _unset,
    Object? abortionRecord = _unset,
    bool? heatCheckDone,
  }) {
    return GestationCrate(
      number: number ?? this.number,
      side: side ?? this.side,
      sideNumber: sideNumber ?? this.sideNumber,
      earTag: identical(earTag, _unset) ? this.earTag : earTag as String?,
      matingDates: identical(matingDates, _unset)
          ? this.matingDates
          : List<DateTime>.from(matingDates as List<DateTime>),
      matingBoars: identical(matingBoars, _unset)
          ? this.matingBoars
          : List<String?>.from(matingBoars as List<String?>),
      farrowingRecord: identical(farrowingRecord, _unset)
          ? this.farrowingRecord
          : farrowingRecord as FarrowingRecord?,
      abortionRecord: identical(abortionRecord, _unset)
          ? this.abortionRecord
          : abortionRecord as AbortionRecord?,
      heatCheckDone: heatCheckDone ?? this.heatCheckDone,
    );
  }

  GestationCrate cleared() {
    return copyWith(
      earTag: null,
      matingDates: const <DateTime>[],
      matingBoars: const <String?>[],
      farrowingRecord: null,
      abortionRecord: null,
      heatCheckDone: false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'side': side,
    'sideNumber': sideNumber,
    'earTag': earTag,
    'matingDates': matingDates.map((date) => date.toIso8601String()).toList(),
    'matingBoars': matingBoars,
    'farrowingRecord': farrowingRecord?.toJson(),
    'abortionRecord': abortionRecord?.toJson(),
    'heatCheckDone': heatCheckDone,
  };

  factory GestationCrate.fromJson(Map<String, dynamic> json) {
    final farrowing = json['farrowingRecord'];
    final abortion = json['abortionRecord'];
    return GestationCrate(
      number: (json['number'] as num?)?.toInt() ?? 0,
      side: json['side'] as String? ?? '',
      sideNumber: (json['sideNumber'] as num?)?.toInt() ?? 0,
      earTag: json['earTag'] as String?,
      matingDates: (json['matingDates'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => DateTime.parse(item as String))
          .toList(),
      matingBoars: (json['matingBoars'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item as String?)
          .toList(),
      farrowingRecord: farrowing is Map<String, dynamic>
          ? FarrowingRecord.fromJson(farrowing)
          : farrowing is Map
          ? FarrowingRecord.fromJson(Map<String, dynamic>.from(farrowing))
          : null,
      abortionRecord: abortion is Map<String, dynamic>
          ? AbortionRecord.fromJson(abortion)
          : abortion is Map
          ? AbortionRecord.fromJson(Map<String, dynamic>.from(abortion))
          : null,
      heatCheckDone: json['heatCheckDone'] as bool? ?? false,
    );
  }
}

class FarmPainter extends CustomPainter {
  FarmPainter({
    required this.progress,
    required this.compact,
    required this.pan,
    required this.zoom,
    required this.rotation,
    required this.tilt,
    required this.showLabels,
  });

  final double progress;
  final bool compact;
  final Offset pan;
  final double zoom;
  final double rotation;
  final double tilt;
  final bool showLabels;

  static const _buildings = [
    FarmBuilding('Alimentos', -48, -18, 12, 6, 4.2, Color(0xfff1712d)),
    FarmBuilding('Engorde', -36, -8, 17, 10, 4.8, Color(0xfff1712d)),
    FarmBuilding('Parrilla', -16, -5, 17, 8, 4.5, Color(0xfff1712d)),
    FarmBuilding('Pre Destete', 6, -5, 13, 8, 4.4, Color(0xfff1712d)),
    FarmBuilding('Maternidad 1', 22, -5, 13, 8, 4.4, Color(0xfff1712d)),
    FarmBuilding('Gestación', 39, -5, 16, 8, 4.7, Color(0xfff1712d)),
    FarmBuilding('Maternidad 2', 39, 8, 16, 8, 4.7, Color(0xfff1712d)),
    FarmBuilding('Verracos', 52, 8, 7, 6, 3.5, Color(0xffd15f31)),
    FarmBuilding('Cargadero', -34, 5, 8, 4, 3.3, Color(0xffe25f2b)),
  ];

  static List<FarmBuilding> get buildings => _buildings;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 136, size.height / 92) * zoom;
    final center =
        Offset(size.width * 0.5, size.height * (compact ? 0.47 : 0.5)) + pan;
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    Offset project(double x, double z) {
      final rx = x * cosR - z * sinR;
      final rz = x * sinR + z * cosR;
      return Offset(
        center.dx + (rx - rz) * scale * 0.82,
        center.dy + (rx + rz) * scale * tilt,
      );
    }

    final sky = Paint()..color = const Color(0xff86bbe9);
    canvas.drawRect(Offset.zero & size, sky);

    final ground = Paint()..color = const Color(0xfff7f8ef);
    final groundPath = Path()
      ..moveTo(project(-60, -35).dx, project(-60, -35).dy)
      ..lineTo(project(60, -35).dx, project(60, -35).dy)
      ..lineTo(project(60, 35).dx, project(60, 35).dy)
      ..lineTo(project(-60, 35).dx, project(-60, 35).dy)
      ..close();
    canvas.drawPath(groundPath, ground);

    _drawFence(canvas, project, -58, -30, 55, -30, scale);
    _drawFence(canvas, project, 55, -30, 55, 34, scale);
    _drawFence(canvas, project, 55, 34, -58, 34, scale);
    _drawFence(canvas, project, -58, 34, -58, -30, scale);

    _drawRoad(canvas, project, -38, 20, 5, 45, scale, -0.22);
    _drawRoad(canvas, project, -43, -8, 4, 20, scale, -0.35);
    _drawRoad(canvas, project, 9, 2, 72, 4, scale, 0);
    _drawRoad(canvas, project, -36, -3, 4, 12, scale, -0.15);
    _drawRoad(canvas, project, 36, 4, 4, 13, scale, -0.1);

    for (final tree in _trees) {
      _drawTree(canvas, project(tree.x, tree.z), scale * tree.s);
    }

    final sortedBuildings = [..._buildings]
      ..sort((a, b) {
        final da = _depthValue(a.x, a.z);
        final db = _depthValue(b.x, b.z);
        return da.compareTo(db);
      });

    for (final building in sortedBuildings) {
      _drawBuilding(canvas, project, building, scale);
    }

    _drawMovingAnimals(canvas, project, scale);
    if (showLabels) {
      _drawEntranceLabel(canvas, project(-39, 27), scale);
    }
  }

  double _depthValue(double x, double z) {
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);
    final rx = x * cosR - z * sinR;
    final rz = x * sinR + z * cosR;
    return rx + rz;
  }

  void _drawBuilding(
    Canvas canvas,
    Offset Function(double x, double z) project,
    FarmBuilding building,
    double scale,
  ) {
    final halfW = building.width / 2;
    final halfD = building.depth / 2;
    final a = project(building.x - halfW, building.z - halfD);
    final b = project(building.x + halfW, building.z - halfD);
    final c = project(building.x + halfW, building.z + halfD);
    final d = project(building.x - halfW, building.z + halfD);
    final lift = Offset(0, -building.height * 1.72 * scale);
    final roofLift = Offset(0, -1.55 * scale);
    final roofDrop = Offset(0, 1.65 * scale);
    final pulse = 1 + math.sin(progress * math.pi * 2) * 0.02;

    final shadowPath = Path()..addPolygon([a, b, c, d], true);
    canvas.drawShadow(
      shadowPath.shift(Offset(1.8 * scale, 2.4 * scale)),
      Colors.black.withValues(alpha: 0.28),
      4,
      true,
    );

    Path wallPath(Offset from, Offset to) => Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy)
      ..lineTo(to.dx + lift.dx, to.dy + lift.dy)
      ..lineTo(from.dx + lift.dx, from.dy + lift.dy)
      ..close();

    final wallPanels = [
      _FarmSurface(
        wallPath(a, b),
        const Color(0xffb65227),
        _depthValue(building.x, building.z - halfD),
      ),
      _FarmSurface(
        wallPath(b, c),
        const Color(0xff9c4725),
        _depthValue(building.x + halfW, building.z),
      ),
      _FarmSurface(
        wallPath(d, c),
        building.wall,
        _depthValue(building.x, building.z + halfD),
      ),
      _FarmSurface(
        wallPath(a, d),
        const Color(0xffc85a2b),
        _depthValue(building.x - halfW, building.z),
      ),
    ]..sort((a, b) => a.depth.compareTo(b.depth));

    for (final panel in wallPanels) {
      canvas.drawPath(panel.path, Paint()..color = panel.color);
      canvas.drawPath(
        panel.path,
        Paint()
          ..color = const Color(0xff77351a).withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 0.72 * scale)
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final roofOverhangW = 1.15;
    final roofOverhangD = 0.95;
    final roofA =
        project(
          building.x - halfW - roofOverhangW,
          building.z - halfD - roofOverhangD,
        ) +
        lift +
        roofLift;
    final roofB =
        project(
          building.x + halfW + roofOverhangW,
          building.z - halfD - roofOverhangD,
        ) +
        lift +
        roofLift;
    final roofC =
        project(
          building.x + halfW + roofOverhangW,
          building.z + halfD + roofOverhangD,
        ) +
        lift +
        roofLift;
    final roofD =
        project(
          building.x - halfW - roofOverhangW,
          building.z + halfD + roofOverhangD,
        ) +
        lift +
        roofLift;

    final roofPath = Path()
      ..moveTo(roofA.dx, roofA.dy)
      ..lineTo(roofB.dx, roofB.dy)
      ..lineTo(roofC.dx, roofC.dy)
      ..lineTo(roofD.dx, roofD.dy)
      ..close();
    canvas.drawShadow(roofPath, Colors.black.withValues(alpha: 0.3), 5, true);
    canvas.drawPath(roofPath, Paint()..color = const Color(0xff1fc5f2));

    Path roofEdgePath(Offset from, Offset to) => Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy)
      ..lineTo(to.dx + roofDrop.dx, to.dy + roofDrop.dy)
      ..lineTo(from.dx + roofDrop.dx, from.dy + roofDrop.dy)
      ..close();

    final roofEdges = [
      _FarmSurface(
        roofEdgePath(roofA, roofB),
        const Color(0xff086eaa),
        _depthValue(building.x, building.z - halfD),
      ),
      _FarmSurface(
        roofEdgePath(roofB, roofC),
        const Color(0xff075f9e),
        _depthValue(building.x + halfW, building.z),
      ),
      _FarmSurface(
        roofEdgePath(roofD, roofC),
        const Color(0xff0d8bd1),
        _depthValue(building.x, building.z + halfD),
      ),
      _FarmSurface(
        roofEdgePath(roofA, roofD),
        const Color(0xff0877ba),
        _depthValue(building.x - halfW, building.z),
      ),
    ]..sort((a, b) => a.depth.compareTo(b.depth));

    for (final edge in roofEdges) {
      canvas.drawPath(edge.path, Paint()..color = edge.color);
      canvas.drawPath(
        edge.path,
        Paint()
          ..color = const Color(0xff064f87).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 0.75 * scale)
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final roofLine = Paint()
      ..color = const Color(0xff075a9a)
      ..strokeWidth = math.max(1.5, 1.05 * scale)
      ..style = PaintingStyle.stroke;
    canvas.drawPath(roofPath, roofLine);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = math.max(1.1, 0.95 * scale)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset.lerp(roofA, roofB, .16)!,
      Offset.lerp(roofD, roofC, .16)!,
      highlight,
    );

    final frontDepth = _depthValue(building.x, building.z + halfD);
    final backDepth = _depthValue(building.x, building.z - halfD);
    if (frontDepth >= backDepth) {
      _drawBuildingDoors(canvas, d, c, lift, scale);
    }
    if (building.name == 'Verracos') {
      _drawBoarMarkers(canvas, project, building.x, building.z + 5.2, scale);
    }

    if (showLabels) {
      final labelCenter =
          project(building.x, building.z) +
          Offset(0, -(building.height * 1.55 + 4.1) * scale * pulse);
      _drawLabel(canvas, building.name, labelCenter, scale);
    }
  }

  void _drawBoarMarkers(
    Canvas canvas,
    Offset Function(double x, double z) project,
    double x,
    double z,
    double scale,
  ) {
    final bodyPaint = Paint()..color = const Color(0xffb96a62);
    final headPaint = Paint()..color = const Color(0xffc98279);
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.16);

    for (var i = 0; i < 3; i++) {
      final p = project(x - 2.4 + i * 2.4, z + (i.isEven ? 0 : .8));
      canvas.drawOval(
        Rect.fromCenter(
          center: p + Offset(0, 1.8 * scale),
          width: 5.5 * scale,
          height: 2.4 * scale,
        ),
        shadowPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 4.8 * scale, height: 3.2 * scale),
        bodyPaint,
      );
      canvas.drawCircle(
        p + Offset(2.2 * scale, -0.3 * scale),
        1.2 * scale,
        headPaint,
      );
    }
  }

  void _drawBuildingDoors(
    Canvas canvas,
    Offset leftBase,
    Offset rightBase,
    Offset lift,
    double scale,
  ) {
    final wallVector = rightBase - leftBase;
    final unit = wallVector / wallVector.distance;
    final normal = Offset(-unit.dy, unit.dx);
    final doorPaint = Paint()..color = const Color(0xff4d4d4d);
    final doorEdgePaint = Paint()
      ..color = Colors.black.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, .45 * scale);

    for (final t in [.36, .5, .64]) {
      final bottom = Offset.lerp(leftBase, rightBase, t)!;
      final top = bottom + lift * .45;
      final width = 1.05 * scale;
      final door = Path()
        ..moveTo(bottom.dx - unit.dx * width, bottom.dy - unit.dy * width)
        ..lineTo(bottom.dx + unit.dx * width, bottom.dy + unit.dy * width)
        ..lineTo(
          top.dx + unit.dx * width + normal.dx * .15 * scale,
          top.dy + unit.dy * width + normal.dy * .15 * scale,
        )
        ..lineTo(
          top.dx - unit.dx * width + normal.dx * .15 * scale,
          top.dy - unit.dy * width + normal.dy * .15 * scale,
        )
        ..close();
      canvas.drawPath(door, doorPaint);
      canvas.drawPath(door, doorEdgePaint);
    }
  }

  void _drawRoad(
    Canvas canvas,
    Offset Function(double x, double z) project,
    double x,
    double z,
    double width,
    double depth,
    double scale,
    double rotation,
  ) {
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);
    final corners =
        [
          Offset(-width / 2, -depth / 2),
          Offset(width / 2, -depth / 2),
          Offset(width / 2, depth / 2),
          Offset(-width / 2, depth / 2),
        ].map((point) {
          final rx = point.dx * cosR - point.dy * sinR;
          final rz = point.dx * sinR + point.dy * cosR;
          return project(x + rx, z + rz);
        }).toList();

    final path = Path()..addPolygon(corners, true);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _drawFence(
    Canvas canvas,
    Offset Function(double x, double z) project,
    double x1,
    double z1,
    double x2,
    double z2,
    double scale,
  ) {
    final linePaint = Paint()
      ..color = const Color(0xffc1792e)
      ..strokeWidth = 1.2 * scale;
    canvas.drawLine(project(x1, z1), project(x2, z2), linePaint);

    final posts = 18;
    final postPaint = Paint()..color = const Color(0xff8b4a1f);
    for (var i = 0; i <= posts; i++) {
      final t = i / posts;
      final p = project(x1 + (x2 - x1) * t, z1 + (z2 - z1) * t);
      canvas.drawRect(
        Rect.fromCenter(center: p, width: 2 * scale, height: 5 * scale),
        postPaint,
      );
    }
  }

  void _drawTree(Canvas canvas, Offset base, double scale) {
    final trunk = Paint()..color = const Color(0xff7b471f);
    final leaf = Paint()..color = const Color(0xff2edc64);
    final shade = Paint()..color = const Color(0xff18a94a);
    canvas.drawRect(
      Rect.fromCenter(
        center: base + Offset(0, -3.5 * scale),
        width: 2.5 * scale,
        height: 7 * scale,
      ),
      trunk,
    );
    canvas.drawCircle(
      base + Offset(-2.8 * scale, -8.5 * scale),
      5 * scale,
      shade,
    );
    canvas.drawCircle(
      base + Offset(2.8 * scale, -9.5 * scale),
      5.3 * scale,
      leaf,
    );
    canvas.drawCircle(base + Offset(0, -13 * scale), 5.8 * scale, leaf);
  }

  void _drawMovingAnimals(
    Canvas canvas,
    Offset Function(double x, double z) project,
    double scale,
  ) {
    final animalPaint = Paint()..color = const Color(0xfff4a3a8);
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.14);
    final paths = [
      [const Offset(-46, 7), const Offset(-26, 4), const Offset(-10, 1)],
      [const Offset(2, 2), const Offset(18, 1), const Offset(36, 4)],
      [const Offset(35, 11), const Offset(42, 8), const Offset(48, 2)],
    ];

    for (var i = 0; i < paths.length; i++) {
      final local = (progress + i * 0.28) % 1;
      final point = _samplePath(paths[i], local);
      final p = project(point.dx, point.dy);
      canvas.drawOval(
        Rect.fromCenter(
          center: p + Offset(0, 2 * scale),
          width: 7 * scale,
          height: 3 * scale,
        ),
        shadowPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 7 * scale, height: 4.5 * scale),
        animalPaint,
      );
      canvas.drawCircle(
        p + Offset(3.2 * scale, -0.8 * scale),
        1.5 * scale,
        animalPaint,
      );
    }
  }

  Offset _samplePath(List<Offset> points, double t) {
    final segmentCount = points.length - 1;
    final scaled = t * segmentCount;
    final index = scaled.floor().clamp(0, segmentCount - 1);
    final local = scaled - index;
    return Offset.lerp(points[index], points[index + 1], local)!;
  }

  void _drawEntranceLabel(Canvas canvas, Offset center, double scale) {
    _drawLabel(
      canvas,
      'Entrada / Vehículos',
      center + Offset(0, -10 * scale),
      scale,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset center, double scale) {
    final labelFontSize = compact
        ? 8.5
        : math.min(12.0, math.max(9.5, scale * 2.4));
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xff17231d),
          fontSize: labelFontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 130);

    final rect = Rect.fromCenter(
      center: center,
      width: painter.width + 12,
      height: painter.height + 7,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke,
    );
    painter.paint(
      canvas,
      rect.topLeft + Offset((rect.width - painter.width) / 2, 3.5),
    );
  }

  @override
  bool shouldRepaint(covariant FarmPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.compact != compact ||
        oldDelegate.pan != pan ||
        oldDelegate.zoom != zoom ||
        oldDelegate.rotation != rotation ||
        oldDelegate.tilt != tilt ||
        oldDelegate.showLabels != showLabels;
  }
}

class FarmBuilding {
  const FarmBuilding(
    this.name,
    this.x,
    this.z,
    this.width,
    this.depth,
    this.height,
    this.wall,
  );

  final String name;
  final double x;
  final double z;
  final double width;
  final double depth;
  final double height;
  final Color wall;
}

class _FarmSurface {
  const _FarmSurface(this.path, this.color, this.depth);

  final Path path;
  final Color color;
  final double depth;
}

class FarmTree {
  const FarmTree(this.x, this.z, this.s);

  final double x;
  final double z;
  final double s;
}

const _trees = [
  FarmTree(-55, -33, 1),
  FarmTree(-45, -32, .8),
  FarmTree(-30, -34, 1),
  FarmTree(12, -33, .9),
  FarmTree(28, -31, 1),
  FarmTree(49, -28, .9),
  FarmTree(-60, -18, 1),
  FarmTree(-59, -5, 1.1),
  FarmTree(-57, 8, .9),
  FarmTree(-58, 24, 1),
  FarmTree(54, -18, 1),
  FarmTree(56, -2, 1.1),
  FarmTree(53, 18, .9),
  FarmTree(-42, 31, 1),
  FarmTree(-12, 32, .9),
  FarmTree(24, 30, 1),
  FarmTree(44, 32, .8),
];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.items});

  final List<_ListData> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _InfoTile(item: items[index]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _ListData item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _ListData {
  const _ListData(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

const _movementItems = [
  _ListData(
    'Ingreso lote E-15',
    '96 animales hacia Engorde · 08:20',
    Icons.login,
  ),
  _ListData(
    'Traslado interno',
    '38 animales de Pre Destete a Parrilla',
    Icons.swap_calls,
  ),
  _ListData(
    'Salida programada',
    'Lote P-08 listo para carga mañana',
    Icons.local_shipping_outlined,
  ),
];

const _healthItems = [
  _ListData(
    'Vacunación',
    'Maternidad 1 · refuerzo aplicado',
    Icons.vaccines_outlined,
  ),
  _ListData(
    'Observación',
    '2 animales con baja ingesta en Engorde',
    Icons.visibility_outlined,
  ),
  _ListData(
    'Limpieza',
    'Parrilla requiere desinfección final',
    Icons.cleaning_services_outlined,
  ),
];

const _taskItems = [
  _ListData(
    'Revisar comederos',
    'Engorde · prioridad alta',
    Icons.restaurant_outlined,
  ),
  _ListData(
    'Control de temperatura',
    'Pre Destete · cada 4 horas',
    Icons.device_thermostat,
  ),
  _ListData(
    'Confirmar alimento',
    'Galpón de Alimentos · inventario',
    Icons.inventory_2_outlined,
  ),
];
