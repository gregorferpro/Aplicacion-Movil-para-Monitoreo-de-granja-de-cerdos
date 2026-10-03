import '../models/production_cost_models.dart';

Map<String, dynamic> encodeProductionCostState({
  required List<Product> products,
  required List<PurchaseEntry> purchases,
  required List<InventoryMovement> movements,
  required List<FeedFormula> formulas,
  required List<PreparedFoodBatch> preparedBatches,
  required List<ProductionLot> lots,
  required List<ProductiveMovement> productiveMovements,
  required List<ReproductiveCycle> cycles,
  required List<ConsumptionRecord> consumptions,
  required List<ManagementProtocol> protocols,
  required List<MortalityRecord> mortalities,
  required List<SaleRecord> sales,
  required List<ReferenceRation> referenceRations,
  required bool allowNegativeStock,
  required double defaultProfitMargin,
}) {
  return <String, dynamic>{
    'products': products.map(_productToJson).toList(),
    'purchases': purchases.map(_purchaseToJson).toList(),
    'movements': movements.map(_movementToJson).toList(),
    'formulas': formulas.map(_formulaToJson).toList(),
    'preparedBatches': preparedBatches.map(_batchToJson).toList(),
    'lots': lots.map(_lotToJson).toList(),
    'productiveMovements': productiveMovements
        .map(_productiveMovementToJson)
        .toList(),
    'cycles': cycles.map(_cycleToJson).toList(),
    'consumptions': consumptions.map(_consumptionToJson).toList(),
    'protocols': protocols.map(_protocolToJson).toList(),
    'mortalities': mortalities.map(_mortalityToJson).toList(),
    'sales': sales.map(_saleToJson).toList(),
    'referenceRations': referenceRations.map(_rationToJson).toList(),
    'allowNegativeStock': allowNegativeStock,
    'defaultProfitMargin': defaultProfitMargin,
  };
}

class ProductionCostState {
  const ProductionCostState({
    required this.products,
    required this.purchases,
    required this.movements,
    required this.formulas,
    required this.preparedBatches,
    required this.lots,
    required this.productiveMovements,
    required this.cycles,
    required this.consumptions,
    required this.protocols,
    required this.mortalities,
    required this.sales,
    required this.referenceRations,
    required this.allowNegativeStock,
    required this.defaultProfitMargin,
  });

  final List<Product> products;
  final List<PurchaseEntry> purchases;
  final List<InventoryMovement> movements;
  final List<FeedFormula> formulas;
  final List<PreparedFoodBatch> preparedBatches;
  final List<ProductionLot> lots;
  final List<ProductiveMovement> productiveMovements;
  final List<ReproductiveCycle> cycles;
  final List<ConsumptionRecord> consumptions;
  final List<ManagementProtocol> protocols;
  final List<MortalityRecord> mortalities;
  final List<SaleRecord> sales;
  final List<ReferenceRation> referenceRations;
  final bool allowNegativeStock;
  final double defaultProfitMargin;
}

ProductionCostState decodeProductionCostState(Map<String, dynamic> json) {
  return ProductionCostState(
    products: _maps(json['products']).map(_productFromJson).toList(),
    purchases: _maps(json['purchases']).map(_purchaseFromJson).toList(),
    movements: _maps(json['movements']).map(_movementFromJson).toList(),
    formulas: _maps(json['formulas']).map(_formulaFromJson).toList(),
    preparedBatches: _maps(
      json['preparedBatches'],
    ).map(_batchFromJson).toList(),
    lots: _maps(json['lots']).map(_lotFromJson).toList(),
    productiveMovements: _maps(
      json['productiveMovements'],
    ).map(_productiveMovementFromJson).toList(),
    cycles: _maps(json['cycles']).map(_cycleFromJson).toList(),
    consumptions: _maps(
      json['consumptions'],
    ).map(_consumptionFromJson).toList(),
    protocols: _maps(json['protocols']).map(_protocolFromJson).toList(),
    mortalities: _maps(json['mortalities']).map(_mortalityFromJson).toList(),
    sales: _maps(json['sales']).map(_saleFromJson).toList(),
    referenceRations: _maps(
      json['referenceRations'],
    ).map(_rationFromJson).toList(),
    allowNegativeStock: json['allowNegativeStock'] as bool? ?? false,
    defaultProfitMargin:
        (json['defaultProfitMargin'] as num?)?.toDouble() ?? .20,
  );
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

DateTime _date(Object? value) => DateTime.parse(value as String);
DateTime? _optionalDate(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
int _int(Object? value) => (value as num?)?.toInt() ?? 0;

Map<String, dynamic> _syncToJson(SyncFields value) => <String, dynamic>{
  'idLocal': value.idLocal,
  'uuid': value.uuid,
  'createdAt': value.createdAt.toIso8601String(),
  'updatedAt': value.updatedAt.toIso8601String(),
  'synced': value.synced,
  'deletedAt': value.deletedAt?.toIso8601String(),
};

SyncFields _syncFromJson(Map<String, dynamic> json) => SyncFields(
  idLocal: json['idLocal'] as String,
  uuid: json['uuid'] as String,
  createdAt: _date(json['createdAt']),
  updatedAt: _date(json['updatedAt']),
  synced: json['synced'] as bool? ?? false,
  deletedAt: _optionalDate(json['deletedAt']),
);

Map<String, dynamic> _productToJson(Product value) => <String, dynamic>{
  'sync': _syncToJson(value.sync),
  'name': value.name,
  'category': value.category.name,
  'baseUnit': value.baseUnit,
  'controlType': value.controlType,
  'stock': value.stock,
  'averageCost': value.averageCost,
  'minimumStock': value.minimumStock,
  'expirationDate': value.expirationDate?.toIso8601String(),
  'active': value.active,
  'conversions': value.conversions,
};

Product _productFromJson(Map<String, dynamic> json) => Product(
  sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
  name: json['name'] as String,
  category: ProductCategory.values.byName(json['category'] as String),
  baseUnit: json['baseUnit'] as String,
  controlType: json['controlType'] as String,
  stock: _double(json['stock']),
  averageCost: _double(json['averageCost']),
  minimumStock: _double(json['minimumStock']),
  expirationDate: _optionalDate(json['expirationDate']),
  active: json['active'] as bool? ?? true,
  conversions: (json['conversions'] as Map? ?? const <String, dynamic>{}).map(
    (key, value) => MapEntry(key.toString(), _double(value)),
  ),
);

Map<String, dynamic> _purchaseToJson(PurchaseEntry value) => <String, dynamic>{
  'sync': _syncToJson(value.sync),
  'date': value.date.toIso8601String(),
  'supplier': value.supplier,
  'productId': value.productId,
  'productName': value.productName,
  'category': value.category.name,
  'purchasedQuantity': value.purchasedQuantity,
  'purchaseUnit': value.purchaseUnit,
  'conversionToBase': value.conversionToBase,
  'baseQuantity': value.baseQuantity,
  'totalPrice': value.totalPrice,
  'unitPrice': value.unitPrice,
  'invoiceNumber': value.invoiceNumber,
  'note': value.note,
  'responsible': value.responsible,
};

PurchaseEntry _purchaseFromJson(Map<String, dynamic> json) => PurchaseEntry(
  sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
  date: _date(json['date']),
  supplier: json['supplier'] as String,
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  category: ProductCategory.values.byName(json['category'] as String),
  purchasedQuantity: _double(json['purchasedQuantity']),
  purchaseUnit: json['purchaseUnit'] as String,
  conversionToBase: _double(json['conversionToBase']),
  baseQuantity: _double(json['baseQuantity']),
  totalPrice: _double(json['totalPrice']),
  unitPrice: _double(json['unitPrice']),
  invoiceNumber: json['invoiceNumber'] as String? ?? '',
  note: json['note'] as String? ?? '',
  responsible: json['responsible'] as String,
);

Map<String, dynamic> _movementToJson(InventoryMovement value) =>
    <String, dynamic>{
      'sync': _syncToJson(value.sync),
      'date': value.date.toIso8601String(),
      'productId': value.productId,
      'productName': value.productName,
      'type': value.type.name,
      'quantity': value.quantity,
      'baseUnit': value.baseUnit,
      'unitCost': value.unitCost,
      'totalCost': value.totalCost,
      'referenceType': value.referenceType,
      'referenceId': value.referenceId,
      'note': value.note,
      'responsible': value.responsible,
    };

InventoryMovement _movementFromJson(Map<String, dynamic> json) =>
    InventoryMovement(
      sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
      date: _date(json['date']),
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      type: InventoryMovementType.values.byName(json['type'] as String),
      quantity: _double(json['quantity']),
      baseUnit: json['baseUnit'] as String,
      unitCost: _double(json['unitCost']),
      totalCost: _double(json['totalCost']),
      referenceType: json['referenceType'] as String,
      referenceId: json['referenceId'] as String,
      note: json['note'] as String? ?? '',
      responsible: json['responsible'] as String,
    );

Map<String, dynamic> _formulaIngredientToJson(FormulaIngredient value) =>
    <String, dynamic>{
      'productId': value.productId,
      'productName': value.productName,
      'percentage': value.percentage,
    };

FormulaIngredient _formulaIngredientFromJson(Map<String, dynamic> json) =>
    FormulaIngredient(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      percentage: _double(json['percentage']),
    );

Map<String, dynamic> _formulaToJson(FeedFormula value) => <String, dynamic>{
  'sync': _syncToJson(value.sync),
  'name': value.name,
  'stage': value.stage,
  'version': value.version,
  'active': value.active,
  'createdDate': value.createdDate.toIso8601String(),
  'ingredients': value.ingredients.map(_formulaIngredientToJson).toList(),
  'note': value.note,
};

FeedFormula _formulaFromJson(Map<String, dynamic> json) => FeedFormula(
  sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
  name: json['name'] as String,
  stage: json['stage'] as String,
  version: _int(json['version']),
  active: json['active'] as bool? ?? true,
  createdDate: _date(json['createdDate']),
  ingredients: _maps(
    json['ingredients'],
  ).map(_formulaIngredientFromJson).toList(),
  note: json['note'] as String? ?? '',
);

Map<String, dynamic> _preparationIngredientToJson(
  PreparationIngredient value,
) => <String, dynamic>{
  'productId': value.productId,
  'productName': value.productName,
  'quantityKg': value.quantityKg,
  'unitCost': value.unitCost,
  'totalCost': value.totalCost,
};

PreparationIngredient _preparationIngredientFromJson(
  Map<String, dynamic> json,
) => PreparationIngredient(
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  quantityKg: _double(json['quantityKg']),
  unitCost: _double(json['unitCost']),
  totalCost: _double(json['totalCost']),
);

Map<String, dynamic> _batchToJson(PreparedFoodBatch value) => <String, dynamic>{
  'sync': _syncToJson(value.sync),
  'code': value.code,
  'productId': value.productId,
  'formulaId': value.formulaId,
  'formulaName': value.formulaName,
  'date': value.date.toIso8601String(),
  'producedKg': value.producedKg,
  'availableKg': value.availableKg,
  'totalCost': value.totalCost,
  'costPerKg': value.costPerKg,
  'ingredients': value.ingredients.map(_preparationIngredientToJson).toList(),
  'responsible': value.responsible,
  'note': value.note,
};

PreparedFoodBatch _batchFromJson(Map<String, dynamic> json) =>
    PreparedFoodBatch(
      sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
      code: json['code'] as String,
      productId: json['productId'] as String,
      formulaId: json['formulaId'] as String,
      formulaName: json['formulaName'] as String,
      date: _date(json['date']),
      producedKg: _double(json['producedKg']),
      availableKg: _double(json['availableKg']),
      totalCost: _double(json['totalCost']),
      costPerKg: _double(json['costPerKg']),
      ingredients: _maps(
        json['ingredients'],
      ).map(_preparationIngredientFromJson).toList(),
      responsible: json['responsible'] as String,
      note: json['note'] as String? ?? '',
    );

Map<String, dynamic> _costLineToJson(CostLine value) => <String, dynamic>{
  'date': value.date.toIso8601String(),
  'stage': value.stage,
  'category': value.category.name,
  'description': value.description,
  'amount': value.amount,
};

CostLine _costLineFromJson(Map<String, dynamic> json) => CostLine(
  date: _date(json['date']),
  stage: json['stage'] as String,
  category: ProductCategory.values.byName(json['category'] as String),
  description: json['description'] as String,
  amount: _double(json['amount']),
);

Map<String, dynamic> _lotToJson(ProductionLot value) => <String, dynamic>{
  'sync': _syncToJson(value.sync),
  'code': value.code,
  'motherId': value.motherId,
  'birthDate': value.birthDate.toIso8601String(),
  'totalBorn': value.totalBorn,
  'bornAlive': value.bornAlive,
  'bornDead': value.bornDead,
  'weaned': value.weaned,
  'moved': value.moved,
  'deadAccumulated': value.deadAccumulated,
  'currentAnimals': value.currentAnimals,
  'currentStage': value.currentStage,
  'currentLocation': value.currentLocation,
  'status': value.status,
  'costLines': value.costLines.map(_costLineToJson).toList(),
  'totalSoldWeight': value.totalSoldWeight,
  'saleDate': value.saleDate?.toIso8601String(),
};

ProductionLot _lotFromJson(Map<String, dynamic> json) => ProductionLot(
  sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
  code: json['code'] as String,
  motherId: json['motherId'] as String,
  birthDate: _date(json['birthDate']),
  totalBorn: _int(json['totalBorn']),
  bornAlive: _int(json['bornAlive']),
  bornDead: _int(json['bornDead']),
  weaned: _int(json['weaned']),
  moved: _int(json['moved']),
  deadAccumulated: _int(json['deadAccumulated']),
  currentAnimals: _int(json['currentAnimals']),
  currentStage: json['currentStage'] as String,
  currentLocation: json['currentLocation'] as String,
  status: json['status'] as String,
  costLines: _maps(json['costLines']).map(_costLineFromJson).toList(),
  totalSoldWeight: _double(json['totalSoldWeight']),
  saleDate: _optionalDate(json['saleDate']),
);

Map<String, dynamic> _productiveMovementToJson(ProductiveMovement value) =>
    <String, dynamic>{
      'sync': _syncToJson(value.sync),
      'date': value.date.toIso8601String(),
      'lotId': value.lotId,
      'originStage': value.originStage,
      'destinationStage': value.destinationStage,
      'movedAnimals': value.movedAnimals,
      'note': value.note,
    };

ProductiveMovement _productiveMovementFromJson(Map<String, dynamic> json) =>
    ProductiveMovement(
      sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
      date: _date(json['date']),
      lotId: json['lotId'] as String,
      originStage: json['originStage'] as String,
      destinationStage: json['destinationStage'] as String,
      movedAnimals: _int(json['movedAnimals']),
      note: json['note'] as String? ?? '',
    );

Map<String, dynamic> _cycleToJson(ReproductiveCycle value) => <String, dynamic>{
  'sync': _syncToJson(value.sync),
  'motherId': value.motherId,
  'serviceDate': value.serviceDate.toIso8601String(),
  'confirmationDate': value.confirmationDate?.toIso8601String(),
  'estimatedFarrowingDate': value.estimatedFarrowingDate.toIso8601String(),
  'realFarrowingDate': value.realFarrowingDate?.toIso8601String(),
  'status': value.status,
  'gestationCost': value.gestationCost,
  'note': value.note,
};

ReproductiveCycle _cycleFromJson(Map<String, dynamic> json) =>
    ReproductiveCycle(
      sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
      motherId: json['motherId'] as String,
      serviceDate: _date(json['serviceDate']),
      confirmationDate: _optionalDate(json['confirmationDate']),
      estimatedFarrowingDate: _date(json['estimatedFarrowingDate']),
      realFarrowingDate: _optionalDate(json['realFarrowingDate']),
      status: json['status'] as String,
      gestationCost: _double(json['gestationCost']),
      note: json['note'] as String? ?? '',
    );

Map<String, dynamic> _consumptionToJson(ConsumptionRecord value) =>
    <String, dynamic>{
      'sync': _syncToJson(value.sync),
      'date': value.date.toIso8601String(),
      'target': value.target.name,
      'stage': value.stage,
      'productId': value.productId,
      'productName': value.productName,
      'quantity': value.quantity,
      'unit': value.unit,
      'conversionToBase': value.conversionToBase,
      'baseQuantity': value.baseQuantity,
      'unitCost': value.unitCost,
      'totalCost': value.totalCost,
      'lotId': value.lotId,
      'corral': value.corral,
      'animalId': value.animalId,
      'animalsTreated': value.animalsTreated,
      'responsible': value.responsible,
      'note': value.note,
    };

ConsumptionRecord _consumptionFromJson(Map<String, dynamic> json) =>
    ConsumptionRecord(
      sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
      date: _date(json['date']),
      target: ConsumptionTarget.values.byName(json['target'] as String),
      stage: json['stage'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: _double(json['quantity']),
      unit: json['unit'] as String,
      conversionToBase: _double(json['conversionToBase']),
      baseQuantity: _double(json['baseQuantity']),
      unitCost: _double(json['unitCost']),
      totalCost: _double(json['totalCost']),
      lotId: json['lotId'] as String? ?? '',
      corral: json['corral'] as String? ?? '',
      animalId: json['animalId'] as String? ?? '',
      animalsTreated: _int(json['animalsTreated']),
      responsible: json['responsible'] as String,
      note: json['note'] as String? ?? '',
    );

Map<String, dynamic> _protocolToJson(ManagementProtocol value) =>
    <String, dynamic>{
      'sync': _syncToJson(value.sync),
      'name': value.name,
      'stage': value.stage,
      'recommendedDay': value.recommendedDay,
      'productId': value.productId,
      'productName': value.productName,
      'quantity': value.quantity,
      'unit': value.unit,
      'appliesTo': value.appliesTo.name,
      'note': value.note,
    };

ManagementProtocol _protocolFromJson(Map<String, dynamic> json) =>
    ManagementProtocol(
      sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
      name: json['name'] as String,
      stage: json['stage'] as String,
      recommendedDay: _int(json['recommendedDay']),
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: _double(json['quantity']),
      unit: json['unit'] as String,
      appliesTo: ConsumptionTarget.values.byName(json['appliesTo'] as String),
      note: json['note'] as String? ?? '',
    );

Map<String, dynamic> _mortalityToJson(MortalityRecord value) =>
    <String, dynamic>{
      'sync': _syncToJson(value.sync),
      'date': value.date.toIso8601String(),
      'lotId': value.lotId,
      'stage': value.stage,
      'deadCount': value.deadCount,
      'cause': value.cause,
      'note': value.note,
      'responsible': value.responsible,
    };

MortalityRecord _mortalityFromJson(Map<String, dynamic> json) =>
    MortalityRecord(
      sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
      date: _date(json['date']),
      lotId: json['lotId'] as String,
      stage: json['stage'] as String,
      deadCount: _int(json['deadCount']),
      cause: json['cause'] as String? ?? '',
      note: json['note'] as String? ?? '',
      responsible: json['responsible'] as String? ?? '',
    );

Map<String, dynamic> _saleToJson(SaleRecord value) => <String, dynamic>{
  'sync': _syncToJson(value.sync),
  'lotId': value.lotId,
  'date': value.date.toIso8601String(),
  'soldAnimals': value.soldAnimals,
  'totalWeight': value.totalWeight,
  'averageWeight': value.averageWeight,
  'pricePerKg': value.pricePerKg,
  'totalSale': value.totalSale,
  'buyer': value.buyer,
  'note': value.note,
};

SaleRecord _saleFromJson(Map<String, dynamic> json) => SaleRecord(
  sync: _syncFromJson(Map<String, dynamic>.from(json['sync'] as Map)),
  lotId: json['lotId'] as String,
  date: _date(json['date']),
  soldAnimals: _int(json['soldAnimals']),
  totalWeight: _double(json['totalWeight']),
  averageWeight: _double(json['averageWeight']),
  pricePerKg: _double(json['pricePerKg']),
  totalSale: _double(json['totalSale']),
  buyer: json['buyer'] as String,
  note: json['note'] as String? ?? '',
);

Map<String, dynamic> _rationToJson(ReferenceRation value) => <String, dynamic>{
  'stage': value.stage,
  'animalType': value.animalType,
  'condition': value.condition,
  'kgPerDay': value.kgPerDay,
  'kgMorning': value.kgMorning,
  'kgAfternoon': value.kgAfternoon,
  'active': value.active,
};

ReferenceRation _rationFromJson(Map<String, dynamic> json) => ReferenceRation(
  stage: json['stage'] as String,
  animalType: json['animalType'] as String,
  condition: json['condition'] as String,
  kgPerDay: _double(json['kgPerDay']),
  kgMorning: _double(json['kgMorning']),
  kgAfternoon: _double(json['kgAfternoon']),
  active: json['active'] as bool? ?? true,
);
