import 'package:flutter/material.dart';

import '../controllers/farm_controllers.dart';

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
                  RecordList(items: movementItems),
                  RecordList(items: healthItems),
                  RecordList(items: taskItems),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordList extends StatelessWidget {
  const RecordList({super.key, required this.items});

  final List<ListData> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(item.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        );
      },
    );
  }
}
