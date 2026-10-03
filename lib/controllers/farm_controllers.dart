import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/farm_models.dart';

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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _formatDate(DateTime? date) {
  if (date == null) {
    return '-';
  }
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

int _parseNonNegativeInt(String value) {
  return math.max(0, int.tryParse(value.trim()) ?? 0);
}

Future<DateTime?> pickDate(BuildContext context, DateTime initialDate) async {
  final selected = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  return selected == null ? null : _dateOnly(selected);
}

Future<AbortionRecord?> showAbortionRecordDialog(
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
                      final selected = await pickDate(context, abortionDate);
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

Future<bool?> confirmDeleteAbortionRecord(
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

class ListData {
  const ListData(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

const movementItems = [
  ListData(
    'Ingreso lote E-15',
    '96 animales hacia Engorde · 08:20',
    Icons.login,
  ),
  ListData(
    'Traslado interno',
    '38 animales de Pre Destete a Parrilla',
    Icons.swap_calls,
  ),
  ListData(
    'Salida programada',
    'Lote P-08 listo para carga mañana',
    Icons.local_shipping_outlined,
  ),
];

const healthItems = [
  ListData(
    'Vacunación',
    'Maternidad 1 · refuerzo aplicado',
    Icons.vaccines_outlined,
  ),
  ListData(
    'Observación',
    '2 animales con baja ingesta en Engorde',
    Icons.visibility_outlined,
  ),
  ListData(
    'Limpieza',
    'Parrilla requiere desinfección final',
    Icons.cleaning_services_outlined,
  ),
];

const taskItems = [
  ListData(
    'Revisar comederos',
    'Engorde · prioridad alta',
    Icons.restaurant_outlined,
  ),
  ListData(
    'Control de temperatura',
    'Pre Destete · cada 4 horas',
    Icons.device_thermostat,
  ),
  ListData(
    'Confirmar alimento',
    'Maternidad 2 · entrega programada',
    Icons.checklist_rtl,
  ),
];
