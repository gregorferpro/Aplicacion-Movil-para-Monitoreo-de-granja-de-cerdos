import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.onAlerts});

  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _PigBrandMark(),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Cabaña La Pampita',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Administración operativa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          tooltip: 'Alertas',
          onTap: onAlerts,
          child: const Badge(
            label: Text('3'),
            backgroundColor: AppPalette.alert,
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          tooltip: 'Perfil',
          onTap: () {},
          child: const Icon(Icons.person_outline_rounded),
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: AppPalette.outline)),
        elevation: 1,
        shadowColor: const Color(0x160f3322),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 42, height: 42, child: Center(child: child)),
        ),
      ),
    );
  }
}

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $name',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 23, letterSpacing: 0),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _PigBrandMark extends StatelessWidget {
  const _PigBrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SIPOR 360',
      image: true,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppPalette.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x241f6b45),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const CustomPaint(painter: _PigGlyphPainter()),
      ),
    );
  }
}

class _PigGlyphPainter extends CustomPainter {
  const _PigGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .19,
        size.height * .31,
        size.width * .55,
        size.height * .38,
      ),
      Radius.circular(size.width * .16),
    );
    canvas.drawRRect(body, paint);
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .45),
      size.width * .15,
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .84, size.height * .48),
        width: size.width * .16,
        height: size.height * .12,
      ),
      paint,
    );
    final ear = Path()
      ..moveTo(size.width * .66, size.height * .34)
      ..lineTo(size.width * .72, size.height * .19)
      ..lineTo(size.width * .79, size.height * .36)
      ..close();
    canvas.drawPath(ear, paint);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .29,
        size.height * .64,
        size.width * .07,
        size.height * .13,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .58,
        size.height * .64,
        size.width * .07,
        size.height * .13,
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * .75, size.height * .42),
      size.width * .018,
      Paint()..color = AppPalette.primaryDark,
    );
    canvas.drawCircle(
      Offset(size.width * .85, size.height * .48),
      size.width * .015,
      Paint()..color = AppPalette.primaryDark,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * .08,
        size.height * .35,
        size.width * .18,
        size.height * .2,
      ),
      1.4,
      4.4,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PigGlyphPainter oldDelegate) => false;
}

class FarmMapCard extends StatelessWidget {
  const FarmMapCard({
    super.key,
    required this.child,
    required this.labels,
    required this.onOpen,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final Widget child;
  final List<String> labels;
  final VoidCallback onOpen;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Container(
          height: compact ? 236 : 410,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppPalette.outline),
            boxShadow: AppPalette.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppPalette.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: const TextStyle(
                          color: AppPalette.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: child),
                      Positioned.fill(
                        child: Semantics(
                          button: true,
                          label: 'Abrir plano de la granja',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(onTap: onOpen),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: AppPalette.cardShadow,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.view_in_ar_outlined,
                                size: 16,
                                color: AppPalette.primary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '3D',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Material(
                          color: Colors.white.withValues(alpha: .94),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: IconButton(
                            tooltip: 'Abrir plano de la granja',
                            onPressed: onOpen,
                            icon: const Icon(
                              Icons.open_in_full_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      if (!compact)
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < labels.length;
                                  index++
                                ) ...[
                                  FarmLabelChip(label: labels[index]),
                                  if (index < labels.length - 1)
                                    const SizedBox(width: 6),
                                ],
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
      },
    );
  }
}

class FarmLabelChip extends StatelessWidget {
  const FarmLabelChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppPalette.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.grid_view_rounded,
            size: 13,
            color: AppPalette.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 150;
        return Container(
          constraints: BoxConstraints(minHeight: compact ? 124 : 112),
          padding: EdgeInsets.all(compact ? 11 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppPalette.outline),
            boxShadow: AppPalette.cardShadow,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppPalette.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppPalette.outline),
      ),
      elevation: 1,
      shadowColor: const Color(0x160f3322),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class PendingAlertCard extends StatelessWidget {
  const PendingAlertCard({
    super.key,
    required this.title,
    required this.detail,
    required this.time,
    this.priority,
    required this.icon,
    required this.color,
    this.embedded = false,
    required this.onTap,
  });

  final String title;
  final String detail;
  final String time;
  final String? priority;
  final IconData icon;
  final Color color;
  final bool embedded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: embedded
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppPalette.outline),
            ),
      child: InkWell(
        onTap: onTap,
        borderRadius: embedded ? null : BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        priority!,
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: AppPalette.textSecondary.withValues(alpha: .7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
