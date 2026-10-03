import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'farm_map_page.dart';
import 'records_page.dart';

class CabanaShell extends StatefulWidget {
  const CabanaShell({super.key});

  @override
  State<CabanaShell> createState() => _CabanaShellState();
}

class _CabanaShellState extends State<CabanaShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [DashboardPage(), FarmMapPage(), RecordsPage()];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cabaña La Pampita',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              'Administración operativa',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Alertas',
            onPressed: () {},
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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
        ],
      ),
    );
  }
}
