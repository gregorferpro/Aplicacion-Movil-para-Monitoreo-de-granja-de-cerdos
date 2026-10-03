import 'package:flutter/material.dart';

import '../models/production_cost_models.dart';
import '../repositories/production_cost_repository.dart';

enum GalponInventoryInitialAction { purchase, consumption, vaccination }

const _premixGroupValue = '__premix__';
const _premixProductNames = [
  'Premix Lactancia',
  'Premix Engorde',
  'Premix Crecimiento',
  'Premix Inicio',
  'Premix Gestación',
  'Premix Peletizado',
];

class GalponInventoryPage extends StatefulWidget {
  const GalponInventoryPage({
    super.key,
    this.initialTab = 0,
    this.initialAction,
  }) : assert(initialTab >= 0 && initialTab < 7);

  final int initialTab;
  final GalponInventoryInitialAction? initialAction;

  @override
  State<GalponInventoryPage> createState() => _GalponInventoryPageState();
}

class _GalponInventoryPageState extends State<GalponInventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ProductionCostRepository _repo = productionCostRepository;

  static const _stages = [
    'Gestacion',
    'Maternidad',
    'Pre-destete',
    'Parrilla / Crecimiento',
    'Engorde',
    'Verracos',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      initialIndex: widget.initialTab,
      vsync: this,
    );
    final initialAction = widget.initialAction;
    if (initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (initialAction) {
          case GalponInventoryInitialAction.purchase:
            _showPurchaseDialog();
          case GalponInventoryInitialAction.consumption:
            _showConsumptionDialog();
          case GalponInventoryInitialAction.vaccination:
            final vaccines = _repo.products
                .where(
                  (product) =>
                      product.category == ProductCategory.vaccine &&
                      product.stock > 0,
                )
                .toList(growable: false);
            if (vaccines.isEmpty) {
              _showSnack('No hay vacunas con stock disponible.');
            } else {
              _showConsumptionDialog(initialProduct: vaccines.first);
            }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Galpon / Inventario / Costos',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            Text(
              'Offline-first · Cabaña La Pampita',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Inventario'),
            Tab(icon: Icon(Icons.percent_outlined), text: 'Formulas'),
            Tab(icon: Icon(Icons.blender_outlined), text: 'Preparar'),
            Tab(icon: Icon(Icons.restaurant_outlined), text: 'Consumos'),
            Tab(icon: Icon(Icons.groups_outlined), text: 'Lotes'),
            Tab(icon: Icon(Icons.rule_folder_outlined), text: 'Protocolos'),
            Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Reportes'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _repo,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _inventoryTab(),
              _formulasTab(),
              _preparationTab(),
              _consumptionTab(),
              _lotsTab(),
              _protocolsTab(),
              _reportsTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _inventoryTab() {
    final products = _repo.products.where((product) => product.active).toList();
    final movements = _repo.movements.take(8).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _SummaryGrid(
          children: [
            _SummaryCard(
              icon: Icons.savings_outlined,
              label: 'Valor inventario',
              value: _money(_repo.inventoryValue),
            ),
            _SummaryCard(
              icon: Icons.warning_amber_outlined,
              label: 'Stock bajo',
              value: '${_repo.lowStockCount}',
            ),
            _SummaryCard(
              icon: Icons.cloud_sync_outlined,
              label: 'Pendiente sync',
              value: '${_repo.pendingSyncCount}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _showPurchaseDialog,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Ingresar compra'),
            ),
            OutlinedButton.icon(
              onPressed: _showProductDialog,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Nuevo producto'),
            ),
            OutlinedButton.icon(
              onPressed: _showAdjustmentDialog,
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Ajuste'),
            ),
            OutlinedButton.icon(
              onPressed: _showPrepareFoodDialog,
              icon: const Icon(Icons.blender_outlined),
              label: const Text('Preparar alimento'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionHeader(
          title: 'Productos / insumos',
          subtitle: 'Stock actual y costo promedio ponderado',
        ),
        const SizedBox(height: 8),
        for (final product in products) ...[
          _ProductCard(product: product),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        const _SectionHeader(
          title: 'Ultimos movimientos',
          subtitle: 'Entradas, preparaciones, consumos, ajustes y mermas',
        ),
        const SizedBox(height: 8),
        if (movements.isEmpty)
          const _EmptyState(text: 'Aun no hay movimientos de inventario.')
        else
          for (final movement in movements) ...[
            _MovementCard(movement: movement),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _formulasTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _ActionBanner(
          icon: Icons.percent_outlined,
          title: 'Formulas versionadas',
          subtitle:
              'Si cambias una formula, se crea una nueva version para conservar costos historicos.',
          actionLabel: 'Crear formula',
          onAction: _showFormulaDialog,
        ),
        const SizedBox(height: 14),
        for (final formula in _repo.formulas) ...[
          _FormulaCard(formula: formula),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _preparationTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _ActionBanner(
          icon: Icons.blender_outlined,
          title: 'Preparacion de alimento',
          subtitle:
              'Descuenta ingredientes, calcula costo por kg y entra como alimento preparado.',
          actionLabel: 'Preparar alimento',
          onAction: _showPrepareFoodDialog,
        ),
        const SizedBox(height: 14),
        if (_repo.preparedBatches.isEmpty)
          const _EmptyState(text: 'Aun no hay alimentos preparados.')
        else
          for (final batch in _repo.preparedBatches) ...[
            _PreparedBatchCard(batch: batch),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _consumptionTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _ActionBanner(
          icon: Icons.restaurant_outlined,
          title: 'Registrar consumo',
          subtitle:
              'Permite consumo por corral, por lote o individual. Descuenta stock y suma costo.',
          actionLabel: 'Nuevo consumo',
          onAction: _showConsumptionDialog,
        ),
        const SizedBox(height: 14),
        if (_repo.consumptions.isEmpty)
          const _EmptyState(text: 'Aun no hay consumos registrados.')
        else
          for (final consumption in _repo.consumptions) ...[
            _ConsumptionCard(consumption: consumption),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _lotsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const _SectionHeader(
          title: 'Lotes productivos',
          subtitle: 'El costo se conserva aunque el lote cambie de etapa',
        ),
        const SizedBox(height: 10),
        for (final lot in _repo.lots) ...[
          _LotCostCard(
            lot: lot,
            onConsumption: () => _showConsumptionDialog(lot: lot),
            onMortality: () => _showMortalityDialog(lot),
            onSale: () => _showSaleDialog(lot),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _protocolsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const _SectionHeader(
          title: 'Protocolos de manejo',
          subtitle:
              'Configurables. Al ejecutarlos se crea un consumo real y se suma el costo.',
        ),
        const SizedBox(height: 10),
        for (final protocol in _repo.protocols) ...[
          _ProtocolCard(
            protocol: protocol,
            onExecute: () => _showExecuteProtocolDialog(protocol),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        const _SectionHeader(
          title: 'Raciones de referencia',
          subtitle: 'Solo orientativas; no imponen dosis ni cantidades fijas',
        ),
        const SizedBox(height: 8),
        for (final ration in _repo.referenceRations) ...[
          _RationCard(ration: ration),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _reportsTab() {
    final lots = _repo.lots;
    final totalCost = lots.fold(0.0, (sum, lot) => sum + lot.accumulatedCost);
    final totalKg = lots.fold(0.0, (sum, lot) => sum + lot.totalSoldWeight);
    final sectorCost = _repo.sectorWeightedCost();
    final suggested = sectorCost * (1 + _repo.defaultProfitMargin);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _SummaryGrid(
          children: [
            _SummaryCard(
              icon: Icons.payments_outlined,
              label: 'Costo acumulado',
              value: _money(totalCost),
            ),
            _SummaryCard(
              icon: Icons.monitor_weight_outlined,
              label: 'Kg vendidos',
              value: _quantity(totalKg, 'kg'),
            ),
            _SummaryCard(
              icon: Icons.price_check_outlined,
              label: 'Precio sugerido sector',
              value: sectorCost > 0 ? _money(suggested) : 'Sin venta',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionHeader(
          title: 'Reporte por lote',
          subtitle: 'Costo por etapa, animal vivo, kilo producido y margen',
        ),
        const SizedBox(height: 8),
        for (final lot in lots) ...[
          _LotReportCard(lot: lot),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        _DatabaseSchemaCard(pendingSync: _repo.pendingSyncCount),
      ],
    );
  }

  Future<void> _showProductDialog() async {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');
    final controlController = TextEditingController(text: 'stock');
    final minController = TextEditingController(text: '10');
    ProductCategory category = ProductCategory.feedIngredient;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo producto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ProductCategory>(
                      initialValue: category,
                      items: ProductCategory.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Categoria'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unidad base',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock minimo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controlController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de control',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.createProduct(
                        name: nameController.text,
                        category: category,
                        baseUnit: unitController.text.trim().isEmpty
                            ? 'unidad'
                            : unitController.text.trim(),
                        controlType: controlController.text,
                        minimumStock: _parseDouble(minController.text),
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Producto creado.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showPurchaseDialog() async {
    final products = _repo.products.where((item) => item.active).toList();
    if (products.isEmpty) return;

    final premixProducts = <Product>[
      for (final name in _premixProductNames)
        ...products.where((product) => product.name == name),
    ];
    final standardProducts = products
        .where((product) => !_premixProductNames.contains(product.name))
        .toList();
    var premixSelected = standardProducts.isEmpty && premixProducts.isNotEmpty;
    var product = premixSelected
        ? premixProducts.first
        : standardProducts.first;
    var productGroup = premixSelected
        ? _premixGroupValue
        : product.sync.idLocal;
    var unit = product.baseUnit;
    final supplierController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final conversionController = TextEditingController(text: '1');
    final totalController = TextEditingController(text: '0');
    final invoiceController = TextEditingController();
    final noteController = TextEditingController();
    final responsibleController = TextEditingController(text: 'Operador');
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final baseQuantity =
                _parseDouble(quantityController.text) *
                _parseDouble(conversionController.text);
            final unitPrice = baseQuantity <= 0
                ? 0.0
                : _parseDouble(totalController.text) / baseQuantity;
            return AlertDialog(
              title: const Text('Ingresar compra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      key: const ValueKey('purchase-product'),
                      initialValue: productGroup,
                      items: [
                        for (final item in standardProducts)
                          DropdownMenuItem(
                            value: item.sync.idLocal,
                            child: Text(item.name),
                          ),
                        if (premixProducts.isNotEmpty)
                          const DropdownMenuItem(
                            value: _premixGroupValue,
                            child: Text('Premix'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          productGroup = value;
                          premixSelected = value == _premixGroupValue;
                          product = premixSelected
                              ? premixProducts.first
                              : standardProducts.firstWhere(
                                  (item) => item.sync.idLocal == value,
                                );
                          unit = product.baseUnit;
                          conversionController.text = '1';
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Producto'),
                    ),
                    if (premixSelected) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Product>(
                        key: const ValueKey('purchase-premix-type'),
                        initialValue: product,
                        items: premixProducts
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            product = value;
                            unit = value.baseUnit;
                            conversionController.text = '1';
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tipo de premix',
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: supplierController,
                      decoration: const InputDecoration(labelText: 'Proveedor'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad comprada',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: unit,
                            items: _unitsFor(product)
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                unit = value;
                                conversionController.text = _conversionFor(
                                  product,
                                  unit,
                                ).toString();
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Unidad',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: conversionController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Conversion a ${product.baseUnit}',
                        helperText:
                            'Ejemplo: 1 quintal = 46 kg o el valor que uses',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: totalController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Precio total',
                        prefixText: 'Bs ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ReadonlyMetric(
                            label: 'Cantidad base',
                            value: _quantity(baseQuantity, product.baseUnit),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReadonlyMetric(
                            label: 'Precio unitario',
                            value: '${_money(unitPrice)}/${product.baseUnit}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: invoiceController,
                      decoration: const InputDecoration(
                        labelText: 'Factura / opcional',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: responsibleController,
                      decoration: const InputDecoration(
                        labelText: 'Responsable',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observacion',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.registerPurchase(
                        date: DateTime.now(),
                        supplier: supplierController.text,
                        productId: product.sync.idLocal,
                        purchasedQuantity: _parseDouble(
                          quantityController.text,
                        ),
                        purchaseUnit: unit,
                        conversionToBase: _parseDouble(
                          conversionController.text,
                        ),
                        totalPrice: _parseDouble(totalController.text),
                        responsible: responsibleController.text,
                        invoiceNumber: invoiceController.text,
                        note: noteController.text,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Compra registrada y stock actualizado.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showAdjustmentDialog() async {
    final products = _repo.products;
    if (products.isEmpty) return;

    var product = products.first;
    var unit = product.baseUnit;
    final quantityController = TextEditingController();
    final conversionController = TextEditingController(text: '1');
    final noteController = TextEditingController();
    final responsibleController = TextEditingController(text: 'Operador');
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajuste de inventario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Product>(
                      initialValue: product,
                      items: products
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          product = value;
                          unit = value.baseUnit;
                          conversionController.text = '1';
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Producto'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad (+ entrada / - salida)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: unit,
                      items: _unitsFor(product)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          unit = value;
                          conversionController.text = _conversionFor(
                            product,
                            unit,
                          ).toString();
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Unidad'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: conversionController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Conversion a ${product.baseUnit}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: responsibleController,
                      decoration: const InputDecoration(
                        labelText: 'Responsable',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observacion',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.adjustInventory(
                        productId: product.sync.idLocal,
                        quantity: _parseDouble(quantityController.text),
                        unit: unit,
                        conversionToBase: _parseDouble(
                          conversionController.text,
                        ),
                        note: noteController.text,
                        responsible: responsibleController.text,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Ajuste registrado.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showFormulaDialog() async {
    final ingredients = _repo.productsByCategories({
      ProductCategory.feedIngredient,
    });
    if (ingredients.isEmpty) {
      _showSnack('Primero registra ingredientes de alimento.');
      return;
    }

    final nameController = TextEditingController(text: 'Nueva formula');
    var stage = _stages[3];
    final selectedProducts = List<Product?>.filled(5, null);
    final percentControllers = List.generate(5, (_) => TextEditingController());
    final defaultPercents = ['55', '20', '22', '3', ''];
    for (var i = 0; i < percentControllers.length; i++) {
      percentControllers[i].text = defaultPercents[i];
      selectedProducts[i] = i < ingredients.length ? ingredients[i] : null;
    }
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sum = percentControllers.fold<double>(
              0,
              (value, controller) => value + _parseDouble(controller.text),
            );
            return AlertDialog(
              title: const Text('Crear formula'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: stage,
                        items: _stages
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => stage = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Etapa'),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < selectedProducts.length; i++) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<Product>(
                                initialValue: selectedProducts[i],
                                items: ingredients
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedProducts[i] = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Ingrediente ${i + 1}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: percentControllers[i],
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  labelText: '%',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      _ReadonlyMetric(
                        label: 'Suma',
                        value: '${sum.toStringAsFixed(2)}%',
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      final formulaIngredients = <FormulaIngredient>[];
                      for (var i = 0; i < selectedProducts.length; i++) {
                        final product = selectedProducts[i];
                        final percent = _parseDouble(
                          percentControllers[i].text,
                        );
                        if (product != null && percent > 0) {
                          formulaIngredients.add(
                            FormulaIngredient(
                              productId: product.sync.idLocal,
                              productName: product.name,
                              percentage: percent,
                            ),
                          );
                        }
                      }
                      _repo.createFormula(
                        name: nameController.text,
                        stage: stage,
                        ingredients: formulaIngredients,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Formula creada como nueva version.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showPrepareFoodDialog() async {
    final formulas = _repo.formulas.where((formula) => formula.active).toList();
    if (formulas.isEmpty) {
      _showSnack('Primero crea una formula activa.');
      return;
    }

    var formula = formulas.first;
    final quantityController = TextEditingController(text: '100');
    final responsibleController = TextEditingController(text: 'Operador');
    final noteController = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final quantityKg = _parseDouble(quantityController.text);
            final preview = formula.ingredients.map((ingredient) {
              final product = _repo.productById(ingredient.productId);
              final requiredKg = quantityKg * ingredient.percentage / 100;
              return (
                product: product,
                ingredient: ingredient,
                requiredKg: requiredKg,
                totalCost: requiredKg * product.averageCost,
              );
            }).toList();
            final totalCost = preview.fold<double>(
              0,
              (sum, item) => sum + item.totalCost,
            );
            final costPerKg = quantityKg <= 0 ? 0 : totalCost / quantityKg;

            return AlertDialog(
              title: const Text('Preparar alimento'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<FeedFormula>(
                        initialValue: formula,
                        items: formulas
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  '${item.name} v${item.version} · ${item.stage}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => formula = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Formula'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad a preparar (kg)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final item in preview)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.product.stock >= item.requiredKg
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: item.product.stock >= item.requiredKg
                                ? const Color(0xff176b4d)
                                : Colors.red,
                          ),
                          title: Text(item.product.name),
                          subtitle: Text(
                            '${item.ingredient.percentage}% · Requiere ${_quantity(item.requiredKg, 'kg')} · Stock ${_quantity(item.product.stock, item.product.baseUnit)}',
                          ),
                          trailing: Text(_money(item.totalCost)),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _ReadonlyMetric(
                              label: 'Costo total',
                              value: _money(totalCost),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ReadonlyMetric(
                              label: 'Costo por kg',
                              value: _money(costPerKg),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: responsibleController,
                        decoration: const InputDecoration(
                          labelText: 'Responsable',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Observacion',
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.prepareFood(
                        formulaId: formula.sync.idLocal,
                        quantityKg: _parseDouble(quantityController.text),
                        responsible: responsibleController.text,
                        note: noteController.text,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Alimento preparado y stock actualizado.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showConsumptionDialog({
    ProductionLot? lot,
    Product? initialProduct,
  }) async {
    final products = _repo.products.where((item) => item.stock > 0).toList();
    if (products.isEmpty) {
      _showSnack('No hay productos con stock disponible.');
      return;
    }

    var product =
        initialProduct != null &&
            products.any(
              (item) => item.sync.idLocal == initialProduct.sync.idLocal,
            )
        ? products.firstWhere(
            (item) => item.sync.idLocal == initialProduct.sync.idLocal,
          )
        : products.first;
    var unit = product.baseUnit;
    var target = lot == null ? ConsumptionTarget.corral : ConsumptionTarget.lot;
    var stage = lot?.currentStage ?? _stages.first;
    ProductionLot? selectedLot =
        lot ?? (_repo.lots.isEmpty ? null : _repo.lots.first);
    final quantityController = TextEditingController(text: '1');
    final conversionController = TextEditingController(text: '1');
    final corralController = TextEditingController(
      text: lot?.currentLocation ?? '',
    );
    final animalController = TextEditingController();
    final treatedController = TextEditingController(
      text: lot?.currentAnimals.toString() ?? '0',
    );
    final responsibleController = TextEditingController(text: 'Operador');
    final noteController = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final baseQuantity =
                _parseDouble(quantityController.text) *
                _parseDouble(conversionController.text);
            final totalCost = baseQuantity * product.averageCost;

            return AlertDialog(
              title: const Text('Registrar consumo'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<ConsumptionTarget>(
                        initialValue: target,
                        items: ConsumptionTarget.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => target = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: stage,
                        items: _stages
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => stage = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Etapa'),
                      ),
                      const SizedBox(height: 10),
                      if (_repo.lots.isNotEmpty)
                        DropdownButtonFormField<ProductionLot>(
                          initialValue: selectedLot,
                          items: _repo.lots
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.code),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedLot = value;
                              corralController.text =
                                  value?.currentLocation ??
                                  corralController.text;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Lote asociado',
                          ),
                        ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Product>(
                        initialValue: product,
                        items: products
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            product = value;
                            unit = value.baseUnit;
                            conversionController.text = '1';
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Producto',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDialogState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: unit,
                              items: _unitsFor(product)
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  unit = value;
                                  conversionController.text = _conversionFor(
                                    product,
                                    unit,
                                  ).toString();
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: conversionController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Conversion a ${product.baseUnit}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (target == ConsumptionTarget.corral)
                        TextField(
                          controller: corralController,
                          decoration: const InputDecoration(
                            labelText: 'Corral',
                          ),
                        ),
                      if (target == ConsumptionTarget.animal)
                        TextField(
                          controller: animalController,
                          decoration: const InputDecoration(
                            labelText: 'Arete / animal',
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: treatedController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Animales tratados / referencia',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ReadonlyMetric(
                              label: 'Cantidad base',
                              value: _quantity(baseQuantity, product.baseUnit),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ReadonlyMetric(
                              label: 'Costo total',
                              value: _money(totalCost),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: responsibleController,
                        decoration: const InputDecoration(
                          labelText: 'Responsable',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Observacion',
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.registerConsumption(
                        target: target,
                        stage: stage,
                        productId: product.sync.idLocal,
                        quantity: _parseDouble(quantityController.text),
                        unit: unit,
                        conversionToBase: _parseDouble(
                          conversionController.text,
                        ),
                        responsible: responsibleController.text,
                        lotId: selectedLot?.sync.idLocal ?? '',
                        corral: corralController.text,
                        animalId: animalController.text,
                        animalsTreated: _parseInt(treatedController.text),
                        note: noteController.text,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Consumo registrado y costo asignado.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showMortalityDialog(ProductionLot lot) async {
    final deadController = TextEditingController(text: '1');
    final causeController = TextEditingController();
    final responsibleController = TextEditingController(text: 'Operador');
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Mortalidad ${lot.code}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: deadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Muertos'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: causeController,
                    decoration: const InputDecoration(labelText: 'Causa'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: responsibleController,
                    decoration: const InputDecoration(labelText: 'Responsable'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.registerMortality(
                        lotId: lot.sync.idLocal,
                        stage: lot.currentStage,
                        deadCount: _parseInt(deadController.text),
                        cause: causeController.text,
                        responsible: responsibleController.text,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Mortalidad registrada.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showSaleDialog(ProductionLot lot) async {
    final animalsController = TextEditingController(
      text: lot.currentAnimals.toString(),
    );
    final weightController = TextEditingController();
    final priceController = TextEditingController();
    final buyerController = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final animals = _parseInt(animalsController.text);
            final weight = _parseDouble(weightController.text);
            final price = _parseDouble(priceController.text);
            final average = animals <= 0 ? 0 : weight / animals;
            final saleTotal = weight * price;
            return AlertDialog(
              title: Text('Venta ${lot.code}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: animalsController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Animales vendidos',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Peso total kg',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Precio venta kg',
                        prefixText: 'Bs ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: buyerController,
                      decoration: const InputDecoration(labelText: 'Comprador'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ReadonlyMetric(
                            label: 'Peso promedio',
                            value: _quantity(average, 'kg'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReadonlyMetric(
                            label: 'Venta total',
                            value: _money(saleTotal),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.registerSale(
                        lotId: lot.sync.idLocal,
                        soldAnimals: animals,
                        totalWeight: weight,
                        pricePerKg: price,
                        buyer: buyerController.text,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Venta registrada.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
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

  Future<void> _showExecuteProtocolDialog(ManagementProtocol protocol) async {
    if (_repo.lots.isEmpty) return;
    var lot = _repo.lots.first;
    final treatedController = TextEditingController(
      text: lot.currentAnimals.toString(),
    );
    final responsibleController = TextEditingController(text: 'Operador');
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ejecutar ${protocol.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ProductionLot>(
                    initialValue: lot,
                    items: _repo.lots
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.code),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          lot = value;
                          treatedController.text = value.currentAnimals
                              .toString();
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Lote'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: treatedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Animales tratados',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: responsibleController,
                    decoration: const InputDecoration(labelText: 'Responsable'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      _repo.executeProtocol(
                        protocolId: protocol.sync.idLocal,
                        lotId: lot.sync.idLocal,
                        animalsTreated: _parseInt(treatedController.text),
                        responsible: responsibleController.text,
                      );
                      Navigator.pop(dialogContext);
                      _showSnack('Protocolo ejecutado y costo asignado.');
                    } catch (exception) {
                      setDialogState(() => error = _cleanError(exception));
                    }
                  },
                  child: const Text('Ejecutar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _unitsFor(Product product) {
    return {product.baseUnit, ...product.conversions.keys}.toList();
  }

  double _conversionFor(Product product, String unit) {
    if (unit == product.baseUnit) return 1;
    return product.conversions[unit] ?? 1;
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  String _cleanError(Object error) {
    final text = error.toString();
    return text.replaceFirst('Bad state: ', '');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _money(num value) => 'Bs ${value.toStringAsFixed(2)}';

String _quantity(num value, String unit) {
  return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)} $unit';
}

String _shortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return GridView.count(
          crossAxisCount: isWide ? children.length : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 84,
          children: children,
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff617067),
                      fontWeight: FontWeight.w700,
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

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xff617067),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xff617067),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final color = product.lowStock ? Colors.orange : const Color(0xff176b4d);
    return Card(
      child: ListTile(
        leading: _IconTile(icon: Icons.inventory_2_outlined, color: color),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${product.category.label} · Stock minimo ${_quantity(product.minimumStock, product.baseUnit)}',
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _quantity(product.stock, product.baseUnit),
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              Text(
                '${_money(product.averageCost)}/${product.baseUnit}',
                style: const TextStyle(
                  color: Color(0xff617067),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement});

  final InventoryMovement movement;

  @override
  Widget build(BuildContext context) {
    final isOut = movement.quantity < 0;
    return Card(
      child: ListTile(
        dense: true,
        leading: _IconTile(
          icon: isOut ? Icons.arrow_downward : Icons.arrow_upward,
          color: isOut ? Colors.red.shade700 : const Color(0xff176b4d),
        ),
        title: Text(
          '${movement.type.label} · ${movement.productName}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${_shortDate(movement.date)} · ${movement.referenceType} · ${movement.responsible}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _quantity(movement.quantity, movement.baseUnit),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(_money(movement.totalCost)),
          ],
        ),
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.formula});

  final FeedFormula formula;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconTile(icon: Icons.percent_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${formula.name} v${formula.version}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(
                  text: formula.active ? 'Activa' : 'Historica',
                  color: formula.active ? const Color(0xff176b4d) : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formula.stage,
              style: const TextStyle(
                color: Color(0xff617067),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final ingredient in formula.ingredients)
                  _MiniChip(
                    text:
                        '${ingredient.productName} ${ingredient.percentage.toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedBatchCard extends StatelessWidget {
  const _PreparedBatchCard({required this.batch});

  final PreparedFoodBatch batch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: _IconTile(icon: Icons.blender_outlined),
        title: Text(
          batch.code,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${_shortDate(batch.date)} · ${batch.responsible}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _quantity(batch.availableKg, 'kg'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text('${_money(batch.costPerKg)}/kg'),
          ],
        ),
        children: [
          for (final ingredient in batch.ingredients)
            ListTile(
              dense: true,
              title: Text(ingredient.productName),
              subtitle: Text(_quantity(ingredient.quantityKg, 'kg')),
              trailing: Text(_money(ingredient.totalCost)),
            ),
        ],
      ),
    );
  }
}

class _ConsumptionCard extends StatelessWidget {
  const _ConsumptionCard({required this.consumption});

  final ConsumptionRecord consumption;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _IconTile(icon: Icons.restaurant_outlined),
        title: Text(
          '${consumption.productName} · ${consumption.target.label}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${consumption.stage} · ${_shortDate(consumption.date)} · ${consumption.corral.isEmpty ? consumption.animalId : consumption.corral}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _quantity(consumption.baseQuantity, consumption.unit),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(_money(consumption.totalCost)),
          ],
        ),
      ),
    );
  }
}

class _LotCostCard extends StatelessWidget {
  const _LotCostCard({
    required this.lot,
    required this.onConsumption,
    required this.onMortality,
    required this.onSale,
  });

  final ProductionLot lot;
  final VoidCallback onConsumption;
  final VoidCallback onMortality;
  final VoidCallback onSale;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconTile(icon: Icons.groups_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.code,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${lot.currentStage} · ${lot.currentLocation} · ${lot.currentAnimals} vivos',
                      ),
                    ],
                  ),
                ),
                _StatusPill(text: lot.status, color: const Color(0xff176b4d)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniMetric(
                  label: 'Costo total',
                  value: _money(lot.accumulatedCost),
                ),
                _MiniMetric(
                  label: 'Animal vivo',
                  value: _money(lot.costPerLiveAnimal),
                ),
                _MiniMetric(
                  label: 'Costo kg',
                  value: lot.costPerKg > 0
                      ? _money(lot.costPerKg)
                      : 'Sin venta',
                ),
                _MiniMetric(label: 'Muertos', value: '${lot.deadAccumulated}'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onConsumption,
                  icon: const Icon(Icons.restaurant_outlined),
                  label: const Text('Consumo'),
                ),
                OutlinedButton.icon(
                  onPressed: onMortality,
                  icon: const Icon(Icons.heart_broken_outlined),
                  label: const Text('Mortalidad'),
                ),
                FilledButton.icon(
                  onPressed: onSale,
                  icon: const Icon(Icons.sell_outlined),
                  label: const Text('Venta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({required this.protocol, required this.onExecute});

  final ManagementProtocol protocol;
  final VoidCallback onExecute;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _IconTile(icon: Icons.rule_folder_outlined),
        title: Text(
          protocol.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${protocol.stage} · Dia ${protocol.recommendedDay} · ${protocol.quantity} ${protocol.unit} de ${protocol.productName}',
        ),
        trailing: FilledButton(
          onPressed: onExecute,
          child: const Text('Ejecutar'),
        ),
      ),
    );
  }
}

class _RationCard extends StatelessWidget {
  const _RationCard({required this.ration});

  final ReferenceRation ration;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _IconTile(icon: Icons.scale_outlined),
        title: Text(
          '${ration.stage} · ${ration.animalType}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(ration.condition),
        trailing: Text(
          ration.kgPerDay <= 0 ? 'Manual' : '${ration.kgPerDay} kg/dia',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _LotReportCard extends StatelessWidget {
  const _LotReportCard({required this.lot});

  final ProductionLot lot;

  @override
  Widget build(BuildContext context) {
    final suggested = lot.costPerKg > 0 ? lot.costPerKg * 1.20 : 0;
    return Card(
      child: ExpansionTile(
        leading: _IconTile(icon: Icons.bar_chart_outlined),
        title: Text(
          lot.code,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${lot.currentStage} · ${lot.currentAnimals} vivos'),
        trailing: Text(
          _money(lot.accumulatedCost),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        children: [
          ListTile(
            dense: true,
            title: const Text('Costo por animal vivo'),
            trailing: Text(_money(lot.costPerLiveAnimal)),
          ),
          ListTile(
            dense: true,
            title: const Text('Costo por kg producido'),
            trailing: Text(
              lot.costPerKg > 0 ? _money(lot.costPerKg) : 'Sin venta',
            ),
          ),
          ListTile(
            dense: true,
            title: const Text('Precio sugerido 20%'),
            trailing: Text(suggested > 0 ? _money(suggested) : 'Sin venta'),
          ),
          for (final entry in lot.costByStage.entries)
            ListTile(
              dense: true,
              title: Text('Etapa ${entry.key}'),
              trailing: Text(_money(entry.value)),
            ),
          for (final entry in lot.costByCategory.entries)
            ListTile(
              dense: true,
              title: Text(entry.key.label),
              trailing: Text(_money(entry.value)),
            ),
        ],
      ),
    );
  }
}

class _DatabaseSchemaCard extends StatelessWidget {
  const _DatabaseSchemaCard({required this.pendingSync});

  final int pendingSync;

  @override
  Widget build(BuildContext context) {
    const tables = [
      'productos',
      'compras',
      'movimientos_inventario',
      'formulas_alimento',
      'formula_ingredientes',
      'preparaciones_alimento',
      'preparacion_ingredientes',
      'alimento_preparado_stock',
      'lotes',
      'movimientos_lote',
      'animales',
      'ciclos_reproductivos',
      'consumos',
      'protocolos',
      'protocolo_detalles',
      'mortalidades',
      'pesajes_ventas',
      'costos_lote_resumen',
      'config_unidades',
      'raciones_referencia',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconTile(icon: Icons.storage_outlined),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Base offline-first preparada',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusPill(
                  text: '$pendingSync pendientes',
                  color: pendingSync == 0
                      ? const Color(0xff176b4d)
                      : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Cada entidad creada usa identificador local, UUID, estado de sincronizacion, fecha de creacion, fecha de actualizacion y fecha de eliminacion opcional. La capa de repositorio guarda en SQLite y queda preparada para sincronizar con PostgreSQL.',
              style: TextStyle(
                color: Color(0xff617067),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final table in tables) _MiniChip(text: table)],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyMetric extends StatelessWidget {
  const _ReadonlyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffeef6f1),
        border: Border.all(color: const Color(0xffcfe4d8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff617067),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffeef6f1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffcfe4d8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff617067),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffedf6f0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffcfe4d8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xff176b4d),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.color = const Color(0xff176b4d)});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xff617067),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
