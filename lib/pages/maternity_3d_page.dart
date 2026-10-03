import 'package:flutter/material.dart';

import '../widgets/maternity_model_viewer.dart';

class Maternity3DPage extends StatefulWidget {
  const Maternity3DPage({super.key});

  @override
  State<Maternity3DPage> createState() => _Maternity3DPageState();
}

class _Maternity3DPageState extends State<Maternity3DPage> {
  int _viewerVersion = 0;
  bool _topView = true;
  late final List<_MaternityCrateState> _crates = List.generate(
    10,
    (index) => _MaternityCrateState(number: index + 1),
  );

  void _resetToTopView() {
    setState(() {
      _topView = true;
      _viewerVersion++;
    });
  }

  void _backToMap() {
    Navigator.of(context).pop();
  }

  Future<void> _openCrateCrud(_MaternityCrateState crate) async {
    final result = await showModalBottomSheet<_MaternityCrateSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _MaternityCrateCrudSheet(crate: crate);
      },
    );

    if (!mounted || result == null) return;

    if (result.kind == _MaternityCrateSheetResultKind.saved) {
      setState(() {
        crate.earTag = result.earTag ?? crate.earTag;
        crate.notes = result.notes ?? crate.notes;
        crate.status = result.status ?? crate.status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jaula ${crate.number} actualizada')),
      );
      return;
    }

    if (result.kind == _MaternityCrateSheetResultKind.moved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mover jaula ${crate.number}: flujo de traslado listo para conectar',
          ),
        ),
      );
      return;
    }

    if (result.kind == _MaternityCrateSheetResultKind.deleted) {
      setState(() {
        crate.earTag = '';
        crate.notes = '';
        crate.status = 'Libre';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jaula ${crate.number} liberada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maternidad — 10 jaulas')),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: MaternityModelViewer(
                viewerKey: ValueKey('maternidad-$_viewerVersion-$_topView'),
                topView: _topView,
              ),
            ),
            Positioned.fill(
              child: _MaternityCrateOverlay(
                crates: _crates,
                onCrateTap: _openCrateCrud,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 88,
              child: FloatingActionButton.extended(
                heroTag: 'maternity-top-view',
                onPressed: _resetToTopView,
                icon: const Icon(Icons.vertical_align_center),
                label: const Text('Vista superior'),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 20,
              child: FloatingActionButton.extended(
                heroTag: 'maternity-back-map',
                onPressed: _backToMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Volver al plano'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaternityCrateOverlay extends StatelessWidget {
  const _MaternityCrateOverlay({
    required this.crates,
    required this.onCrateTap,
  });

  final List<_MaternityCrateState> crates;
  final ValueChanged<_MaternityCrateState> onCrateTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final crateWidth = width * 0.145;
        final crateHeight = height * 0.24;
        final topY = height * 0.13;
        final bottomY = height * 0.60;
        const leftFractions = [0.05, 0.22, 0.39, 0.56, 0.73];

        return Stack(
          children: [
            for (var i = 0; i < 5; i++)
              _MaternityCrateHotspot(
                crate: crates[i],
                left: width * leftFractions[i],
                top: topY,
                width: crateWidth,
                height: crateHeight,
                onTap: onCrateTap,
              ),
            for (var i = 5; i < 10; i++)
              _MaternityCrateHotspot(
                crate: crates[i],
                left: width * leftFractions[i - 5],
                top: bottomY,
                width: crateWidth,
                height: crateHeight,
                onTap: onCrateTap,
              ),
          ],
        );
      },
    );
  }
}

class _MaternityCrateHotspot extends StatelessWidget {
  const _MaternityCrateHotspot({
    required this.crate,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final _MaternityCrateState crate;
  final double left;
  final double top;
  final double width;
  final double height;
  final ValueChanged<_MaternityCrateState> onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = crate.earTag.trim().isNotEmpty;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        label: 'Jaula ${crate.number}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onTap(crate),
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: occupied
                          ? const Color(0xffffe9ee).withValues(alpha: .92)
                          : const Color(0xffedf3ed).withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: occupied
                            ? const Color(0xffd87c93).withValues(alpha: .55)
                            : const Color(0xffbfd3c5).withValues(alpha: .75),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        'Jaula ${crate.number}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff24332c),
                        ),
                      ),
                    ),
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

class _MaternityCrateCrudSheet extends StatefulWidget {
  const _MaternityCrateCrudSheet({required this.crate});

  final _MaternityCrateState crate;

  @override
  State<_MaternityCrateCrudSheet> createState() => _MaternityCrateCrudSheetState();
}

class _MaternityCrateCrudSheetState extends State<_MaternityCrateCrudSheet> {
  late final TextEditingController _earTagController;
  late final TextEditingController _notesController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _earTagController = TextEditingController(text: widget.crate.earTag);
    _notesController = TextEditingController(text: widget.crate.notes);
    _status = widget.crate.status;
  }

  @override
  void dispose() {
    _earTagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final occupied = widget.crate.earTag.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jaula ${widget.crate.number}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                occupied ? 'Cerda registrada' : 'Jaula libre',
                style: const TextStyle(
                  color: Color(0xff617067),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _earTagController,
                decoration: const InputDecoration(
                  labelText: 'Número de arete',
                  prefixIcon: Icon(Icons.tag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.pets_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Libre', child: Text('Libre')),
                  DropdownMenuItem(value: 'En celo', child: Text('En celo')),
                  DropdownMenuItem(value: 'Observación', child: Text('Observación')),
                  DropdownMenuItem(value: 'Confirmada', child: Text('Confirmada')),
                  DropdownMenuItem(value: 'Lista para parir', child: Text('Lista para parir')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _MaternityCrateSheetResult.saved(
                            earTag: _earTagController.text.trim(),
                            status: _status,
                            notes: _notesController.text.trim(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          const _MaternityCrateSheetResult.moved(),
                        );
                      },
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Mover'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      const _MaternityCrateSheetResult.deleted(),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaternityCrateState {
  _MaternityCrateState({required this.number});

  final int number;
  String earTag = '';
  String notes = '';
  String status = 'Libre';
}

class _MaternityCrateSheetResult {
  const _MaternityCrateSheetResult._(
    this.kind,
    this.earTag,
    this.status,
    this.notes,
  );

  const _MaternityCrateSheetResult.saved({
    required String earTag,
    required String status,
    required String notes,
  }) : this._(_MaternityCrateSheetResultKind.saved, earTag, status, notes);

  const _MaternityCrateSheetResult.moved()
    : this._(_MaternityCrateSheetResultKind.moved, null, null, null);

  const _MaternityCrateSheetResult.deleted()
    : this._(_MaternityCrateSheetResultKind.deleted, null, null, null);

  final _MaternityCrateSheetResultKind kind;
  final String? earTag;
  final String? status;
  final String? notes;
}

enum _MaternityCrateSheetResultKind { saved, moved, deleted }
