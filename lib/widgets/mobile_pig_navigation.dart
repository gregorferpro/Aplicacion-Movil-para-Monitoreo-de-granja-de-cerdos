import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PigNavigationItem {
  const PigNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class PigBottomNavigationBar extends StatelessWidget {
  const PigBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<PigNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(7, 0, 7, 6),
      child: SizedBox(
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: _PigNavigationBody()),
            Positioned(
              left: 62,
              right: 31,
              top: 13,
              bottom: 15,
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      child: _PigDestination(
                        item: items[index],
                        selected: selectedIndex == index,
                        onTap: () => onSelected(index),
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

class _PigNavigationBody extends StatelessWidget {
  const _PigNavigationBody();

  static const _asset = 'assets/images/pig_navigation_3d.png';

  Widget _image() {
    return Image.asset(
      _asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: const Offset(0, 5),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x4073443e),
                BlendMode.srcIn,
              ),
              child: _image(),
            ),
          ),
        ),
        _image(),
      ],
    );
  }
}

class _PigDestination extends StatelessWidget {
  const _PigDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PigNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
              decoration: BoxDecoration(
                color: selected ? null : Colors.transparent,
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xfaffffff), Color(0xe8ffeae5)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(
                        color: AppPalette.accent.withValues(alpha: .34),
                      )
                    : null,
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x38a45249),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Color(0xb3ffffff),
                          blurRadius: 2,
                          offset: Offset(0, -1),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: selected
                        ? AppPalette.accent
                        : const Color(0xff524d4c),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? AppPalette.accent
                            : const Color(0xff524d4c),
                        fontSize: 10.5,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
