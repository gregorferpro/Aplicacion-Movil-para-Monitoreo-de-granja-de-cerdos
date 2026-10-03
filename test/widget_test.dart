import 'package:cabana_cerdos_app/main.dart';
import 'package:cabana_cerdos_app/pages/galpon_inventory_page.dart';
import 'package:cabana_cerdos_app/repositories/production_cost_repository.dart';
import 'package:cabana_cerdos_app/widgets/dashboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard quick actions execute their callbacks', (
    tester,
  ) async {
    var ingreso = false;
    var consumo = false;
    var vacuna = false;
    var parto = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardPage(
            onOpenFarm: () {},
            onIngreso: () => ingreso = true,
            onConsumo: () => consumo = true,
            onVacuna: () => vacuna = true,
            onParto: () => parto = true,
            farmPreview: const ColoredBox(color: Colors.green),
          ),
        ),
      ),
    );

    final actions = <String, QuickActionCard>{
      for (final card in tester.widgetList<QuickActionCard>(
        find.byType(QuickActionCard),
      ))
        card.label: card,
    };

    expect(
      actions.keys,
      containsAll(['Ingreso', 'Consumo', 'Vacuna', 'Parto']),
    );
    actions['Ingreso']!.onTap();
    actions['Consumo']!.onTap();
    actions['Vacuna']!.onTap();
    actions['Parto']!.onTap();
    await tester.pump();

    expect(ingreso, isTrue);
    expect(consumo, isTrue);
    expect(vacuna, isTrue);
    expect(parto, isTrue);
  });

  testWidgets('Ingreso opens the inventory purchase form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GalponInventoryPage(
          initialTab: 0,
          initialAction: GalponInventoryInitialAction.purchase,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ingresar compra'), findsWidgets);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('Consumo opens the consumption form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GalponInventoryPage(
          initialTab: 3,
          initialAction: GalponInventoryInitialAction.consumption,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registrar consumo'), findsWidgets);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('Vacuna opens consumption with vaccine selected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GalponInventoryPage(
          initialTab: 3,
          initialAction: GalponInventoryInitialAction.vaccination,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registrar consumo'), findsWidgets);
    expect(find.text('Vacuna lechones'), findsOneWidget);
  });

  testWidgets('Premix displays its six purchase subtypes', (tester) async {
    final activeNames = productionCostRepository.products
        .where((product) => product.active)
        .map((product) => product.name)
        .toList();
    expect(activeNames, isNot(contains('Alimento lactancia #base')));

    await tester.pumpWidget(
      const MaterialApp(
        home: GalponInventoryPage(
          initialTab: 0,
          initialAction: GalponInventoryInitialAction.purchase,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('purchase-product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Premix').last);
    await tester.pumpAndSettle();

    expect(find.text('Tipo de premix'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('purchase-premix-type')));
    await tester.pumpAndSettle();

    for (final name in const [
      'Premix Lactancia',
      'Premix Engorde',
      'Premix Crecimiento',
      'Premix Inicio',
      'Premix Gestación',
      'Premix Peletizado',
    ]) {
      expect(find.text(name), findsWidgets);
    }
  });
}
