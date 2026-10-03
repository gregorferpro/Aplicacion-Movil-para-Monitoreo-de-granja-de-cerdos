import 'package:flutter/material.dart';

import 'widgets/dashboard_widgets.dart';
import 'widgets/model_preview.dart';
import 'widgets/section_title.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SectionTitle(title: 'Vista general', action: 'Hoy'),
          const SizedBox(height: 10),
          const SizedBox(
            height: 280,
            child: ModelPreview(src: 'assets/models/farm.glb'),
          ),
          const SizedBox(height: 16),
          const StatsGrid(),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Acciones rápidas', action: 'Nuevo'),
          const SizedBox(height: 10),
          const QuickActions(),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Atención pendiente', action: '3 alertas'),
          const SizedBox(height: 10),
          const AlertList(),
        ],
      ),
    );
  }
}
