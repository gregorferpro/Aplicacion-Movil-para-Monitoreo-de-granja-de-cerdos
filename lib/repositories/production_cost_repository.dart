import 'package:flutter/foundation.dart';

import '../data/local_database.dart';
import '../data/production_cost_codec.dart';
import '../models/production_cost_models.dart';
import '../services/production_cost_service.dart';

final ProductionCostRepository productionCostRepository =
    ProductionCostRepository.seeded();

class ProductionCostRepository extends ChangeNotifier {
  ProductionCostRepository.seeded() {
    _seed();
  }

  final ProductionCostService _service = const ProductionCostService();

  final List<Product> _products = [];
  final List<PurchaseEntry> _purchases = [];
  final List<InventoryMovement> _movements = [];
  final List<FeedFormula> _formulas = [];
  final List<PreparedFoodBatch> _preparedBatches = [];
  final List<ProductionLot> _lots = [];
  final List<ProductiveMovement> _productiveMovements = [];
  final List<ReproductiveCycle> _cycles = [];
  final List<ConsumptionRecord> _consumptions = [];
  final List<ManagementProtocol> _protocols = [];
  final List<MortalityRecord> _mortalities = [];
  final List<SaleRecord> _sales = [];
  final List<ReferenceRation> _referenceRations = [];
  bool _persistenceReady = false;

  bool allowNegativeStock = false;
  double defaultProfitMargin = .20;

  Future<void> initializePersistence() async {
    final snapshot = await localDatabase.readSnapshot('costos_produccion');
    var catalogMigrated = false;
    if (snapshot != null) {
      final state = decodeProductionCostState(snapshot);
      _products
        ..clear()
        ..addAll(state.products);
      _purchases
        ..clear()
        ..addAll(state.purchases);
      _movements
        ..clear()
        ..addAll(state.movements);
      _formulas
        ..clear()
        ..addAll(state.formulas);
      _preparedBatches
        ..clear()
        ..addAll(state.preparedBatches);
      _lots
        ..clear()
        ..addAll(state.lots);
      _productiveMovements
        ..clear()
        ..addAll(state.productiveMovements);
      _cycles
        ..clear()
        ..addAll(state.cycles);
      _consumptions
        ..clear()
        ..addAll(state.consumptions);
      _protocols
        ..clear()
        ..addAll(state.protocols);
      _mortalities
        ..clear()
        ..addAll(state.mortalities);
      _sales
        ..clear()
        ..addAll(state.sales);
      _referenceRations
        ..clear()
        ..addAll(state.referenceRations);
      allowNegativeStock = state.allowNegativeStock;
      defaultProfitMargin = state.defaultProfitMargin;
      catalogMigrated = _migrateLegacyPremixCatalog();
    }
    _persistenceReady = true;
    if (catalogMigrated) {
      notifyListeners();
    } else {
      super.notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_persistenceReady) return;
    localDatabase.scheduleSnapshot(
      'costos_produccion',
      encodeProductionCostState(
        products: _products,
        purchases: _purchases,
        movements: _movements,
        formulas: _formulas,
        preparedBatches: _preparedBatches,
        lots: _lots,
        productiveMovements: _productiveMovements,
        cycles: _cycles,
        consumptions: _consumptions,
        protocols: _protocols,
        mortalities: _mortalities,
        sales: _sales,
        referenceRations: _referenceRations,
        allowNegativeStock: allowNegativeStock,
        defaultProfitMargin: defaultProfitMargin,
      ),
    );
  }

  List<Product> get products => List.unmodifiable(_products);
  List<PurchaseEntry> get purchases => List.unmodifiable(_purchases);
  List<InventoryMovement> get movements => List.unmodifiable(_movements);
  List<FeedFormula> get formulas => List.unmodifiable(_formulas);
  List<PreparedFoodBatch> get preparedBatches =>
      List.unmodifiable(_preparedBatches);
  List<ProductionLot> get lots => List.unmodifiable(_lots);
  List<ProductiveMovement> get productiveMovements =>
      List.unmodifiable(_productiveMovements);
  List<ReproductiveCycle> get cycles => List.unmodifiable(_cycles);
  List<ConsumptionRecord> get consumptions => List.unmodifiable(_consumptions);
  List<ManagementProtocol> get protocols => List.unmodifiable(_protocols);
  List<MortalityRecord> get mortalities => List.unmodifiable(_mortalities);
  List<SaleRecord> get sales => List.unmodifiable(_sales);
  List<ReferenceRation> get referenceRations =>
      List.unmodifiable(_referenceRations);

  double get inventoryValue {
    return _products
        .where((product) => product.active)
        .fold(0, (sum, product) => sum + product.stockValue);
  }

  int get lowStockCount {
    return _products
        .where((product) => product.active && product.lowStock)
        .length;
  }

  int get pendingSyncCount {
    var count = 0;
    count += _products.where((item) => !item.sync.synced).length;
    count += _purchases.where((item) => !item.sync.synced).length;
    count += _movements.where((item) => !item.sync.synced).length;
    count += _formulas.where((item) => !item.sync.synced).length;
    count += _preparedBatches.where((item) => !item.sync.synced).length;
    count += _lots.where((item) => !item.sync.synced).length;
    count += _consumptions.where((item) => !item.sync.synced).length;
    return count;
  }

  Product productById(String id) {
    return _products.firstWhere((product) => product.sync.idLocal == id);
  }

  Product createProduct({
    required String name,
    required ProductCategory category,
    required String baseUnit,
    required String controlType,
    required double minimumStock,
    Map<String, double> conversions = const <String, double>{},
  }) {
    if (name.trim().isEmpty) {
      throw StateError('El producto necesita nombre.');
    }
    final product = Product(
      sync: _newSync(),
      name: name.trim(),
      category: category,
      baseUnit: baseUnit,
      controlType: controlType.trim().isEmpty ? 'stock' : controlType.trim(),
      stock: 0,
      averageCost: 0,
      minimumStock: minimumStock,
      conversions: conversions,
    );
    _products.insert(0, product);
    notifyListeners();
    return product;
  }

  FeedFormula formulaById(String id) {
    return _formulas.firstWhere((formula) => formula.sync.idLocal == id);
  }

  ProductionLot lotById(String id) {
    return _lots.firstWhere((lot) => lot.sync.idLocal == id);
  }

  List<Product> productsByCategories(Set<ProductCategory> categories) {
    return _products
        .where(
          (product) => product.active && categories.contains(product.category),
        )
        .toList();
  }

  PurchaseEntry registerPurchase({
    required DateTime date,
    required String supplier,
    required String productId,
    required double purchasedQuantity,
    required String purchaseUnit,
    required double conversionToBase,
    required double totalPrice,
    required String responsible,
    String invoiceNumber = '',
    String note = '',
  }) {
    if (purchasedQuantity <= 0) {
      throw StateError('La cantidad comprada debe ser mayor a cero.');
    }
    if (conversionToBase <= 0) {
      throw StateError('La conversion a unidad base debe ser mayor a cero.');
    }
    if (totalPrice <= 0) {
      throw StateError('El precio total debe ser mayor a cero.');
    }

    final product = productById(productId);
    final baseQuantity = _service.convertToBase(
      quantity: purchasedQuantity,
      conversionToBase: conversionToBase,
    );
    final unitPrice = _service.unitPrice(
      totalPrice: totalPrice,
      baseQuantity: baseQuantity,
    );
    final newAverageCost = _service.weightedAverageCost(
      currentStock: product.stock,
      currentAverageCost: product.averageCost,
      incomingQuantity: baseQuantity,
      incomingUnitCost: unitPrice,
    );

    final purchase = PurchaseEntry(
      sync: _newSync(),
      date: date,
      supplier: supplier.trim().isEmpty ? 'Sin proveedor' : supplier.trim(),
      productId: productId,
      productName: product.name,
      category: product.category,
      purchasedQuantity: purchasedQuantity,
      purchaseUnit: purchaseUnit,
      conversionToBase: conversionToBase,
      baseQuantity: baseQuantity,
      totalPrice: totalPrice,
      unitPrice: unitPrice,
      invoiceNumber: invoiceNumber.trim(),
      note: note.trim(),
      responsible: responsible.trim().isEmpty ? 'Operador' : responsible.trim(),
    );

    _purchases.insert(0, purchase);
    _replaceProduct(
      product.copyWith(
        stock: product.stock + baseQuantity,
        averageCost: newAverageCost,
        sync: product.sync.copyWith(updatedAt: DateTime.now(), synced: false),
      ),
    );
    _movements.insert(
      0,
      InventoryMovement(
        sync: _newSync(),
        date: date,
        productId: productId,
        productName: product.name,
        type: InventoryMovementType.entry,
        quantity: baseQuantity,
        baseUnit: product.baseUnit,
        unitCost: unitPrice,
        totalCost: totalPrice,
        referenceType: 'compra',
        referenceId: purchase.sync.idLocal,
        note: note.trim(),
        responsible: purchase.responsible,
      ),
    );
    notifyListeners();
    return purchase;
  }

  void adjustInventory({
    required String productId,
    required double quantity,
    required String unit,
    required double conversionToBase,
    required String note,
    required String responsible,
  }) {
    final product = productById(productId);
    final baseQuantity = _service.convertToBase(
      quantity: quantity,
      conversionToBase: conversionToBase,
    );
    final newStock = product.stock + baseQuantity;
    _ensureStockAllowed(product, newStock);
    _replaceProduct(
      product.copyWith(
        stock: newStock,
        sync: product.sync.copyWith(updatedAt: DateTime.now(), synced: false),
      ),
    );
    _movements.insert(
      0,
      InventoryMovement(
        sync: _newSync(),
        date: DateTime.now(),
        productId: productId,
        productName: product.name,
        type: InventoryMovementType.adjustment,
        quantity: baseQuantity,
        baseUnit: product.baseUnit,
        unitCost: product.averageCost,
        totalCost: baseQuantity.abs() * product.averageCost,
        referenceType: 'ajuste',
        referenceId: productId,
        note: note.trim(),
        responsible: responsible.trim().isEmpty
            ? 'Operador'
            : responsible.trim(),
      ),
    );
    notifyListeners();
  }

  FeedFormula createFormula({
    required String name,
    required String stage,
    required List<FormulaIngredient> ingredients,
    String note = '',
  }) {
    if (ingredients.isEmpty) {
      throw StateError('La formula debe tener ingredientes.');
    }
    final percentageSum = ingredients.fold<double>(
      0,
      (sum, ingredient) => sum + ingredient.percentage,
    );
    if ((percentageSum - 100).abs() > .01) {
      throw StateError('La suma de porcentajes debe dar 100%.');
    }

    final version =
        _formulas
            .where((formula) => formula.name == name && formula.stage == stage)
            .length +
        1;
    for (var i = 0; i < _formulas.length; i++) {
      final formula = _formulas[i];
      if (formula.name == name && formula.stage == stage && formula.active) {
        _formulas[i] = FeedFormula(
          sync: formula.sync.copyWith(updatedAt: DateTime.now(), synced: false),
          name: formula.name,
          stage: formula.stage,
          version: formula.version,
          active: false,
          createdDate: formula.createdDate,
          ingredients: formula.ingredients,
          note: formula.note,
        );
      }
    }

    final formula = FeedFormula(
      sync: _newSync(),
      name: name.trim(),
      stage: stage,
      version: version,
      active: true,
      createdDate: DateTime.now(),
      ingredients: ingredients,
      note: note.trim(),
    );
    _formulas.insert(0, formula);
    notifyListeners();
    return formula;
  }

  PreparedFoodBatch prepareFood({
    required String formulaId,
    required double quantityKg,
    required String responsible,
    String note = '',
  }) {
    if (quantityKg <= 0) {
      throw StateError('La cantidad a preparar debe ser mayor a cero.');
    }

    final formula = formulaById(formulaId);
    final ingredients = <PreparationIngredient>[];
    var totalCost = 0.0;

    for (final ingredient in formula.ingredients) {
      final product = productById(ingredient.productId);
      final requiredKg = _service.ingredientQuantity(
        totalPreparedKg: quantityKg,
        percentage: ingredient.percentage,
      );
      _ensureStockAllowed(product, product.stock - requiredKg);
      final ingredientCost = requiredKg * product.averageCost;
      ingredients.add(
        PreparationIngredient(
          productId: product.sync.idLocal,
          productName: product.name,
          quantityKg: requiredKg,
          unitCost: product.averageCost,
          totalCost: ingredientCost,
        ),
      );
      totalCost += ingredientCost;
    }

    final costPerKg = _service.costPerKg(
      totalCost: totalCost,
      totalKg: quantityKg,
    );
    final batchNumber = (_preparedBatches.length + 1).toString().padLeft(
      3,
      '0',
    );
    final code = '${formula.name} #$batchNumber';
    final productSync = _newSync();
    final preparedProduct = Product(
      sync: productSync,
      name: code,
      category: ProductCategory.preparedFeed,
      baseUnit: 'kg',
      controlType: 'stock',
      stock: quantityKg,
      averageCost: costPerKg,
      minimumStock: 25,
      conversions: const {'bolsa 40 kg': 40, 'quintal configurable': 46},
    );
    final batch = PreparedFoodBatch(
      sync: _newSync(),
      code: code,
      productId: preparedProduct.sync.idLocal,
      formulaId: formula.sync.idLocal,
      formulaName: formula.name,
      date: DateTime.now(),
      producedKg: quantityKg,
      availableKg: quantityKg,
      totalCost: totalCost,
      costPerKg: costPerKg,
      ingredients: ingredients,
      responsible: responsible.trim().isEmpty ? 'Operador' : responsible.trim(),
      note: note.trim(),
    );

    for (final ingredient in ingredients) {
      final product = productById(ingredient.productId);
      _replaceProduct(
        product.copyWith(
          stock: product.stock - ingredient.quantityKg,
          sync: product.sync.copyWith(updatedAt: DateTime.now(), synced: false),
        ),
      );
      _movements.insert(
        0,
        InventoryMovement(
          sync: _newSync(),
          date: batch.date,
          productId: product.sync.idLocal,
          productName: product.name,
          type: InventoryMovementType.preparation,
          quantity: -ingredient.quantityKg,
          baseUnit: product.baseUnit,
          unitCost: ingredient.unitCost,
          totalCost: ingredient.totalCost,
          referenceType: 'preparacion',
          referenceId: batch.sync.idLocal,
          note: 'Ingrediente para ${batch.code}',
          responsible: batch.responsible,
        ),
      );
    }

    _products.insert(0, preparedProduct);
    _preparedBatches.insert(0, batch);
    _movements.insert(
      0,
      InventoryMovement(
        sync: _newSync(),
        date: batch.date,
        productId: preparedProduct.sync.idLocal,
        productName: preparedProduct.name,
        type: InventoryMovementType.entry,
        quantity: quantityKg,
        baseUnit: 'kg',
        unitCost: costPerKg,
        totalCost: totalCost,
        referenceType: 'alimento_preparado',
        referenceId: batch.sync.idLocal,
        note: 'Entrada por preparacion',
        responsible: batch.responsible,
      ),
    );
    notifyListeners();
    return batch;
  }

  ConsumptionRecord registerConsumption({
    required ConsumptionTarget target,
    required String stage,
    required String productId,
    required double quantity,
    required String unit,
    required double conversionToBase,
    required String responsible,
    String lotId = '',
    String corral = '',
    String animalId = '',
    int animalsTreated = 0,
    String note = '',
  }) {
    if (quantity <= 0) {
      throw StateError('La cantidad debe ser mayor a cero.');
    }
    final product = productById(productId);
    final baseQuantity = _service.convertToBase(
      quantity: quantity,
      conversionToBase: conversionToBase,
    );
    _ensureStockAllowed(product, product.stock - baseQuantity);

    final totalCost = baseQuantity * product.averageCost;
    final record = ConsumptionRecord(
      sync: _newSync(),
      date: DateTime.now(),
      target: target,
      stage: stage,
      productId: product.sync.idLocal,
      productName: product.name,
      quantity: quantity,
      unit: unit,
      conversionToBase: conversionToBase,
      baseQuantity: baseQuantity,
      unitCost: product.averageCost,
      totalCost: totalCost,
      lotId: lotId,
      corral: corral.trim(),
      animalId: animalId.trim(),
      animalsTreated: animalsTreated,
      responsible: responsible.trim().isEmpty ? 'Operador' : responsible.trim(),
      note: note.trim(),
    );

    _replaceProduct(
      product.copyWith(
        stock: product.stock - baseQuantity,
        sync: product.sync.copyWith(updatedAt: DateTime.now(), synced: false),
      ),
    );
    _consumptions.insert(0, record);
    _movements.insert(
      0,
      InventoryMovement(
        sync: _newSync(),
        date: record.date,
        productId: product.sync.idLocal,
        productName: product.name,
        type: InventoryMovementType.consumption,
        quantity: -baseQuantity,
        baseUnit: product.baseUnit,
        unitCost: product.averageCost,
        totalCost: totalCost,
        referenceType: record.target.label,
        referenceId: lotId.isNotEmpty ? lotId : animalId,
        note: note.trim(),
        responsible: record.responsible,
      ),
    );

    if (lotId.isNotEmpty) {
      _addCostToLot(
        lotId: lotId,
        stage: stage,
        category: product.category,
        description: product.name,
        amount: totalCost,
      );
    }

    notifyListeners();
    return record;
  }

  void registerMortality({
    required String lotId,
    required String stage,
    required int deadCount,
    required String cause,
    required String responsible,
    String note = '',
  }) {
    if (deadCount <= 0) {
      throw StateError('La mortalidad debe ser mayor a cero.');
    }
    final lot = lotById(lotId);
    if (deadCount > lot.currentAnimals) {
      throw StateError('La cantidad supera los animales actuales.');
    }
    _mortalities.insert(
      0,
      MortalityRecord(
        sync: _newSync(),
        date: DateTime.now(),
        lotId: lotId,
        stage: stage,
        deadCount: deadCount,
        cause: cause.trim(),
        note: note.trim(),
        responsible: responsible.trim().isEmpty
            ? 'Operador'
            : responsible.trim(),
      ),
    );
    _replaceLot(
      lot.copyWith(
        deadAccumulated: lot.deadAccumulated + deadCount,
        currentAnimals: lot.currentAnimals - deadCount,
        sync: lot.sync.copyWith(updatedAt: DateTime.now(), synced: false),
      ),
    );
    notifyListeners();
  }

  void registerSale({
    required String lotId,
    required int soldAnimals,
    required double totalWeight,
    required double pricePerKg,
    required String buyer,
    String note = '',
  }) {
    if (soldAnimals <= 0 || totalWeight <= 0 || pricePerKg <= 0) {
      throw StateError('Animales, peso y precio deben ser mayores a cero.');
    }
    final lot = lotById(lotId);
    if (soldAnimals > lot.currentAnimals) {
      throw StateError('La venta supera los animales actuales.');
    }
    final sale = SaleRecord(
      sync: _newSync(),
      lotId: lotId,
      date: DateTime.now(),
      soldAnimals: soldAnimals,
      totalWeight: totalWeight,
      averageWeight: totalWeight / soldAnimals,
      pricePerKg: pricePerKg,
      totalSale: totalWeight * pricePerKg,
      buyer: buyer.trim().isEmpty ? 'Sin comprador' : buyer.trim(),
      note: note.trim(),
    );
    _sales.insert(0, sale);
    _replaceLot(
      lot.copyWith(
        currentAnimals: lot.currentAnimals - soldAnimals,
        totalSoldWeight: lot.totalSoldWeight + totalWeight,
        saleDate: sale.date,
        status: lot.currentAnimals - soldAnimals <= 0 ? 'Vendido' : lot.status,
        sync: lot.sync.copyWith(updatedAt: DateTime.now(), synced: false),
      ),
    );
    notifyListeners();
  }

  void moveLot({
    required String lotId,
    required String destinationStage,
    required String destinationLocation,
    required int movedAnimals,
    String note = '',
  }) {
    final lot = lotById(lotId);
    _productiveMovements.insert(
      0,
      ProductiveMovement(
        sync: _newSync(),
        date: DateTime.now(),
        lotId: lotId,
        originStage: lot.currentStage,
        destinationStage: destinationStage,
        movedAnimals: movedAnimals,
        note: note.trim(),
      ),
    );
    _replaceLot(
      lot.copyWith(
        currentStage: destinationStage,
        currentLocation: destinationLocation,
        sync: lot.sync.copyWith(updatedAt: DateTime.now(), synced: false),
      ),
    );
    notifyListeners();
  }

  void executeProtocol({
    required String protocolId,
    required String lotId,
    required int animalsTreated,
    required String responsible,
  }) {
    final protocol = _protocols.firstWhere(
      (item) => item.sync.idLocal == protocolId,
    );
    registerConsumption(
      target: protocol.appliesTo,
      stage: protocol.stage,
      productId: protocol.productId,
      quantity: protocol.quantity,
      unit: protocol.unit,
      conversionToBase: _conversionForProduct(
        protocol.productId,
        protocol.unit,
      ),
      lotId: lotId,
      animalsTreated: animalsTreated,
      responsible: responsible,
      note: 'Protocolo: ${protocol.name}',
    );
  }

  void markAllAsSynced() {
    for (var i = 0; i < _products.length; i++) {
      _products[i] = _products[i].copyWith(
        sync: _products[i].sync.copyWith(
          synced: true,
          updatedAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  double sectorWeightedCost() {
    final totalCosts = _lots.fold(0.0, (sum, lot) => sum + lot.accumulatedCost);
    final totalKg = _lots.fold(0.0, (sum, lot) => sum + lot.totalSoldWeight);
    return _service.weightedSectorCost(
      totalCosts: totalCosts,
      totalProducedKg: totalKg,
    );
  }

  void _addCostToLot({
    required String lotId,
    required String stage,
    required ProductCategory category,
    required String description,
    required double amount,
  }) {
    final lot = lotById(lotId);
    final costs = [
      ...lot.costLines,
      CostLine(
        date: DateTime.now(),
        stage: stage,
        category: category,
        description: description,
        amount: amount,
      ),
    ];
    _replaceLot(
      lot.copyWith(
        costLines: costs,
        sync: lot.sync.copyWith(updatedAt: DateTime.now(), synced: false),
      ),
    );
  }

  void _ensureStockAllowed(Product product, double nextStock) {
    if (!allowNegativeStock && nextStock < -0.0001) {
      throw StateError(
        'Stock insuficiente de ${product.name}. Disponible: ${product.stock.toStringAsFixed(2)} ${product.baseUnit}.',
      );
    }
  }

  double _conversionForProduct(String productId, String unit) {
    final product = productById(productId);
    if (unit == product.baseUnit) return 1;
    return product.conversions[unit] ?? 1;
  }

  void _replaceProduct(Product updated) {
    final index = _products.indexWhere(
      (product) => product.sync.idLocal == updated.sync.idLocal,
    );
    if (index >= 0) {
      _products[index] = updated;
    }
  }

  void _replaceLot(ProductionLot updated) {
    final index = _lots.indexWhere(
      (lot) => lot.sync.idLocal == updated.sync.idLocal,
    );
    if (index >= 0) {
      _lots[index] = updated;
    }
  }

  SyncFields _newSync({bool synced = false}) {
    final now = DateTime.now();
    final id = _newId();
    return SyncFields(
      idLocal: id,
      uuid: id,
      createdAt: now,
      updatedAt: now,
      synced: synced,
    );
  }

  String _newId() {
    _idCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  bool _migrateLegacyPremixCatalog() {
    const premixNames = [
      'Premix Lactancia',
      'Premix Engorde',
      'Premix Crecimiento',
      'Premix Inicio',
      'Premix Gestación',
      'Premix Peletizado',
    ];
    var changed = false;
    final now = DateTime.now();
    final legacyPremixIndex = _products.indexWhere(
      (product) => product.name.trim().toLowerCase() == 'premix',
    );
    final growthPremixExists = _products.any(
      (product) => product.name == 'Premix Crecimiento',
    );

    if (legacyPremixIndex >= 0) {
      final legacy = _products[legacyPremixIndex];
      _products[legacyPremixIndex] = legacy.copyWith(
        name: growthPremixExists ? legacy.name : 'Premix Crecimiento',
        active: !growthPremixExists,
        sync: legacy.sync.copyWith(updatedAt: now, synced: false),
      );
      changed = true;
    }

    final legacyLactationIndex = _products.indexWhere(
      (product) =>
          product.name.trim().toLowerCase() == 'alimento lactancia #base',
    );
    if (legacyLactationIndex >= 0 && _products[legacyLactationIndex].active) {
      final legacy = _products[legacyLactationIndex];
      _products[legacyLactationIndex] = legacy.copyWith(
        active: false,
        sync: legacy.sync.copyWith(updatedAt: now, synced: false),
      );
      changed = true;
    }

    for (final name in premixNames) {
      if (_products.any((product) => product.name == name)) continue;
      _products.add(
        Product(
          sync: _newSync(),
          name: name,
          category: ProductCategory.feedIngredient,
          baseUnit: 'kg',
          controlType: 'stock',
          stock: 0,
          averageCost: 0,
          minimumStock: 15,
          conversions: const {'bolsa 25 kg': 25},
        ),
      );
      changed = true;
    }
    return changed;
  }

  void _seed() {
    final now = DateTime.now();
    Product product({
      required String name,
      required ProductCategory category,
      required String baseUnit,
      required double stock,
      required double averageCost,
      required double minimumStock,
      Map<String, double> conversions = const <String, double>{},
    }) {
      return Product(
        sync: _newSync(synced: true),
        name: name,
        category: category,
        baseUnit: baseUnit,
        controlType: 'stock',
        stock: stock,
        averageCost: averageCost,
        minimumStock: minimumStock,
        conversions: conversions,
      );
    }

    _products.addAll([
      product(
        name: 'Maiz',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 920,
        averageCost: 1.8,
        minimumStock: 150,
        conversions: const {'quintal 46 kg': 46, 'bolsa 40 kg': 40},
      ),
      product(
        name: 'Sorgo',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 420,
        averageCost: 1.65,
        minimumStock: 80,
        conversions: const {'quintal 46 kg': 46, 'bolsa 40 kg': 40},
      ),
      product(
        name: 'Soya',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 360,
        averageCost: 4.3,
        minimumStock: 70,
        conversions: const {'quintal 46 kg': 46, 'bolsa 40 kg': 40},
      ),
      product(
        name: 'Premix Lactancia',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 0,
        averageCost: 0,
        minimumStock: 15,
        conversions: const {'bolsa 25 kg': 25},
      ),
      product(
        name: 'Premix Engorde',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 0,
        averageCost: 0,
        minimumStock: 15,
        conversions: const {'bolsa 25 kg': 25},
      ),
      product(
        name: 'Premix Crecimiento',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 56,
        averageCost: 13.2,
        minimumStock: 15,
        conversions: const {'bolsa 25 kg': 25},
      ),
      product(
        name: 'Premix Inicio',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 0,
        averageCost: 0,
        minimumStock: 15,
        conversions: const {'bolsa 25 kg': 25},
      ),
      product(
        name: 'Premix Gestación',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 0,
        averageCost: 0,
        minimumStock: 15,
        conversions: const {'bolsa 25 kg': 25},
      ),
      product(
        name: 'Premix Peletizado',
        category: ProductCategory.feedIngredient,
        baseUnit: 'kg',
        stock: 0,
        averageCost: 0,
        minimumStock: 15,
        conversions: const {'bolsa 25 kg': 25},
      ),
      product(
        name: 'Hierro',
        category: ProductCategory.handlingProduct,
        baseUnit: 'ml',
        stock: 460,
        averageCost: .8,
        minimumStock: 80,
        conversions: const {'frasco 100 ml': 100},
      ),
      product(
        name: 'Vacuna lechones',
        category: ProductCategory.vaccine,
        baseUnit: 'dosis',
        stock: 120,
        averageCost: 8,
        minimumStock: 20,
        conversions: const {'caja 20 dosis': 20},
      ),
      product(
        name: 'Desinfectante',
        category: ProductCategory.handlingProduct,
        baseUnit: 'litro',
        stock: 18,
        averageCost: 24,
        minimumStock: 5,
        conversions: const {'ml': .001, 'bidon 20 litros': 20},
      ),
    ]);

    Product seededProduct(String name) {
      return _products.firstWhere((product) => product.name == name);
    }

    _formulas.add(
      FeedFormula(
        sync: _newSync(synced: true),
        name: 'Crecimiento',
        stage: 'Parrilla / Crecimiento',
        version: 1,
        active: true,
        createdDate: now,
        ingredients: [
          FormulaIngredient(
            productId: seededProduct('Maiz').sync.idLocal,
            productName: seededProduct('Maiz').name,
            percentage: 55,
          ),
          FormulaIngredient(
            productId: seededProduct('Sorgo').sync.idLocal,
            productName: seededProduct('Sorgo').name,
            percentage: 20,
          ),
          FormulaIngredient(
            productId: seededProduct('Soya').sync.idLocal,
            productName: seededProduct('Soya').name,
            percentage: 22,
          ),
          FormulaIngredient(
            productId: seededProduct('Premix Crecimiento').sync.idLocal,
            productName: seededProduct('Premix Crecimiento').name,
            percentage: 3,
          ),
        ],
        note: 'Formula base para parrilla.',
      ),
    );

    final initialCost = 148.50;
    _lots.add(
      ProductionLot(
        sync: _newSync(synced: true),
        code: 'M1-3101',
        motherId: 'M1-3101',
        birthDate: now.subtract(const Duration(days: 28)),
        totalBorn: 13,
        bornAlive: 12,
        bornDead: 1,
        weaned: 11,
        moved: 11,
        deadAccumulated: 1,
        currentAnimals: 11,
        currentStage: 'Pre-destete',
        currentLocation: 'Corral 1',
        status: 'Activo',
        costLines: [
          CostLine(
            date: now.subtract(const Duration(days: 28)),
            stage: 'Gestacion',
            category: ProductCategory.preparedFeed,
            description: 'Costo gestacion asignado',
            amount: initialCost,
          ),
        ],
      ),
    );

    _cycles.add(
      ReproductiveCycle(
        sync: _newSync(synced: true),
        motherId: 'M1-3101',
        serviceDate: now.subtract(const Duration(days: 144)),
        confirmationDate: now.subtract(const Duration(days: 123)),
        estimatedFarrowingDate: now.subtract(const Duration(days: 29)),
        realFarrowingDate: now.subtract(const Duration(days: 28)),
        status: 'Pario',
        gestationCost: initialCost,
        note: 'Costo inicial transferido al lote M1-3101.',
      ),
    );

    _referenceRations.addAll(const [
      ReferenceRation(
        stage: 'Gestacion',
        animalType: 'Madre',
        condition: 'Normal',
        kgPerDay: 2,
        kgMorning: 1,
        kgAfternoon: 1,
      ),
      ReferenceRation(
        stage: 'Maternidad',
        animalType: 'Madre lactante',
        condition: 'Manual',
        kgPerDay: 0,
        kgMorning: 0,
        kgAfternoon: 0,
      ),
      ReferenceRation(
        stage: 'Verracos',
        animalType: 'Verraco',
        condition: 'Normal',
        kgPerDay: 2.5,
        kgMorning: 1.25,
        kgAfternoon: 1.25,
      ),
    ]);

    _protocols.add(
      ManagementProtocol(
        sync: _newSync(synced: true),
        name: 'Hierro lechones',
        stage: 'Maternidad',
        recommendedDay: 3,
        productId: seededProduct('Hierro').sync.idLocal,
        productName: seededProduct('Hierro').name,
        quantity: 24,
        unit: 'ml',
        appliesTo: ConsumptionTarget.lot,
        note: 'Cantidad total configurable por lote.',
      ),
    );
  }

  static int _idCounter = 0;
}
