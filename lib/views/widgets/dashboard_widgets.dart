import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.pets, color: Color(0xff176b4d)),
                  SizedBox(height: 18),
                  Text(
                    '1.284',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text('Animales'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.female, color: Color(0xff4a7cd1)),
                  SizedBox(height: 18),
                  Text(
                    '214',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text('Madres'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(label: 'Registrar entrada', icon: Icons.login),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(label: 'Registrar salida', icon: Icons.logout),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            label: 'Nuevo evento',
            icon: Icons.add_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff176b4d)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertList extends StatelessWidget {
  const AlertList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _AlertTile(
          title: 'Revisión de jaulas',
          subtitle: '3 jaulas pendientes',
        ),
        _AlertTile(title: 'Maternidad', subtitle: '2 partos en 24h'),
        _AlertTile(title: 'Sanidad', subtitle: 'Campaña de vacunación mañana'),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
