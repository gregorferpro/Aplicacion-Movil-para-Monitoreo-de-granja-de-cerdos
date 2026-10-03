import 'package:flutter/material.dart';

import '../pages/maternity_3d_page.dart';
import 'widgets/model_preview.dart';
import 'widgets/section_title.dart';

class FarmMapPage extends StatelessWidget {
  const FarmMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            const SectionTitle(title: 'Diseño de la cabaña', action: '3D'),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ModelPreview(src: 'assets/models/farm.glb'),
                  ),
                  Align(
                    alignment: const Alignment(0.62, 0.18),
                    child: _FarmMapTapZone(
                      semanticLabel: 'Abrir plano de Maternidad',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const Maternity3DPage(),
                          ),
                        );
                      },
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

class _FarmMapTapZone extends StatelessWidget {
  const _FarmMapTapZone({required this.semanticLabel, required this.onTap});

  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 180,
        height: 76,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            hoverColor: const Color(0xff176b4d).withValues(alpha: .06),
            splashColor: const Color(0xff176b4d).withValues(alpha: .10),
            highlightColor: Colors.transparent,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
