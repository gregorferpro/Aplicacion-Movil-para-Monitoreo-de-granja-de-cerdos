enum ProductCategory {
  feedIngredient,
  preparedFeed,
  medicine,
  vaccine,
  handlingProduct,
  serviceExpense,
}

extension ProductCategoryText on ProductCategory {
  String get label {
    return switch (this) {
      ProductCategory.feedIngredient => 'Ingrediente de alimento',
      ProductCategory.preparedFeed => 'Alimento preparado',
      ProductCategory.medicine => 'Medicamento',
      ProductCategory.vaccine => 'Vacuna',
      ProductCategory.handlingProduct => 'Producto de manejo',
      ProductCategory.serviceExpense => 'Servicio / gasto',
    };
  }
}

enum InventoryMovementType {
  entry,
  output,
  adjustment,
  preparation,
  consumption,
  loss,
}

extension InventoryMovementTypeText on InventoryMovementType {
  String get label {
    return switch (this) {
      InventoryMovementType.entry => 'Entrada',
      InventoryMovementType.output => 'Salida',
      InventoryMovementType.adjustment => 'Ajuste',
      InventoryMovementType.preparation => 'Preparacion',
      InventoryMovementType.consumption => 'Consumo',
      InventoryMovementType.loss => 'Merma',
    };
  }
}

enum ConsumptionTarget { corral, lot, animal }

extension ConsumptionTargetText on ConsumptionTarget {
  String get label {
    return switch (this) {
      ConsumptionTarget.corral => 'Por corral',
      ConsumptionTarget.lot => 'Por lote',
      ConsumptionTarget.animal => 'Individual',
    };
  }
}

class SyncFields {
  SyncFields({
    required this.idLocal,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
    this.deletedAt,
  });

  final String idLocal;
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  final DateTime? deletedAt;

  SyncFields copyWith({
    DateTime? updatedAt,
    bool? synced,
    DateTime? deletedAt,
  }) {
    return SyncFields(
      idLocal: idLocal,
      uuid: uuid,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class Product {
  Product({
    required this.sync,
    required this.name,
    required this.category,
    required this.baseUnit,
    required this.controlType,
    required this.stock,
    required this.averageCost,
    required this.minimumStock,
    this.expirationDate,
    this.active = true,
    this.conversions = const <String, double>{},
  });

  final SyncFields sync;
  final String name;
  final ProductCategory category;
  final String baseUnit;
  final String controlType;
  final double stock;
  final double averageCost;
  final double minimumStock;
  final DateTime? expirationDate;
  final bool active;
  final Map<String, double> conversions;

  bool get lowStock => stock <= minimumStock;
  double get stockValue => stock * averageCost;

  Product copyWith({
    SyncFields? sync,
    String? name,
    ProductCategory? category,
    String? baseUnit,
    String? controlType,
    double? stock,
    double? averageCost,
    double? minimumStock,
    DateTime? expirationDate,
    bool? active,
    Map<String, double>? conversions,
  }) {
    return Product(
      sync: sync ?? this.sync,
      name: name ?? this.name,
      category: category ?? this.category,
      baseUnit: baseUnit ?? this.baseUnit,
      controlType: controlType ?? this.controlType,
      stock: stock ?? this.stock,
      averageCost: averageCost ?? this.averageCost,
      minimumStock: minimumStock ?? this.minimumStock,
      expirationDate: expirationDate ?? this.expirationDate,
      active: active ?? this.active,
      conversions: conversions ?? this.conversions,
    );
  }
}

class PurchaseEntry {
  PurchaseEntry({
    required this.sync,
    required this.date,
    required this.supplier,
    required this.productId,
    required this.productName,
    required this.category,
    required this.purchasedQuantity,
    required this.purchaseUnit,
    required this.conversionToBase,
    required this.baseQuantity,
    required this.totalPrice,
    required this.unitPrice,
    required this.responsible,
    this.invoiceNumber = '',
    this.note = '',
  });

  final SyncFields sync;
  final DateTime date;
  final String supplier;
  final String productId;
  final String productName;
  final ProductCategory category;
  final double purchasedQuantity;
  final String purchaseUnit;
  final double conversionToBase;
  final double baseQuantity;
  final double totalPrice;
  final double unitPrice;
  final String invoiceNumber;
  final String note;
  final String responsible;
}

class InventoryMovement {
  InventoryMovement({
    required this.sync,
    required this.date,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.baseUnit,
    required this.unitCost,
    required this.totalCost,
    required this.referenceType,
    required this.referenceId,
    required this.responsible,
    this.note = '',
  });

  final SyncFields sync;
  final DateTime date;
  final String productId;
  final String productName;
  final InventoryMovementType type;
  final double quantity;
  final String baseUnit;
  final double unitCost;
  final double totalCost;
  final String referenceType;
  final String referenceId;
  final String note;
  final String responsible;
}

class FormulaIngredient {
  const FormulaIngredient({
    required this.productId,
    required this.productName,
    required this.percentage,
  });

  final String productId;
  final String productName;
  final double percentage;
}

class FeedFormula {
  FeedFormula({
    required this.sync,
    required this.name,
    required this.stage,
    required this.version,
    required this.active,
    required this.createdDate,
    required this.ingredients,
    this.note = '',
  });

  final SyncFields sync;
  final String name;
  final String stage;
  final int version;
  final bool active;
  final DateTime createdDate;
  final List<FormulaIngredient> ingredients;
  final String note;

  double get percentageSum {
    return ingredients.fold(
      0,
      (sum, ingredient) => sum + ingredient.percentage,
    );
  }
}

class PreparationIngredient {
  const PreparationIngredient({
    required this.productId,
    required this.productName,
    required this.quantityKg,
    required this.unitCost,
    required this.totalCost,
  });

  final String productId;
  final String productName;
  final double quantityKg;
  final double unitCost;
  final double totalCost;
}

class PreparedFoodBatch {
  PreparedFoodBatch({
    required this.sync,
    required this.code,
    required this.productId,
    required this.formulaId,
    required this.formulaName,
    required this.date,
    required this.producedKg,
    required this.availableKg,
    required this.totalCost,
    required this.costPerKg,
    required this.ingredients,
    required this.responsible,
    this.note = '',
  });

  final SyncFields sync;
  final String code;
  final String productId;
  final String formulaId;
  final String formulaName;
  final DateTime date;
  final double producedKg;
  final double availableKg;
  final double totalCost;
  final double costPerKg;
  final List<PreparationIngredient> ingredients;
  final String responsible;
  final String note;
}

class CostLine {
  const CostLine({
    required this.date,
    required this.stage,
    required this.category,
    required this.description,
    required this.amount,
  });

  final DateTime date;
  final String stage;
  final ProductCategory category;
  final String description;
  final double amount;
}

class ProductionLot {
  ProductionLot({
    required this.sync,
    required this.code,
    required this.motherId,
    required this.birthDate,
    required this.totalBorn,
    required this.bornAlive,
    required this.bornDead,
    required this.weaned,
    required this.moved,
    required this.deadAccumulated,
    required this.currentAnimals,
    required this.currentStage,
    required this.currentLocation,
    required this.status,
    required this.costLines,
    this.totalSoldWeight = 0,
    this.saleDate,
  });

  final SyncFields sync;
  final String code;
  final String motherId;
  final DateTime birthDate;
  final int totalBorn;
  final int bornAlive;
  final int bornDead;
  final int weaned;
  final int moved;
  final int deadAccumulated;
  final int currentAnimals;
  final String currentStage;
  final String currentLocation;
  final String status;
  final List<CostLine> costLines;
  final double totalSoldWeight;
  final DateTime? saleDate;

  double get accumulatedCost {
    return costLines.fold(0, (sum, line) => sum + line.amount);
  }

  double get costPerLiveAnimal {
    if (currentAnimals <= 0) return 0;
    return accumulatedCost / currentAnimals;
  }

  double get costPerKg {
    if (totalSoldWeight <= 0) return 0;
    return accumulatedCost / totalSoldWeight;
  }

  Map<String, double> get costByStage {
    final result = <String, double>{};
    for (final line in costLines) {
      result[line.stage] = (result[line.stage] ?? 0) + line.amount;
    }
    return result;
  }

  Map<ProductCategory, double> get costByCategory {
    final result = <ProductCategory, double>{};
    for (final line in costLines) {
      result[line.category] = (result[line.category] ?? 0) + line.amount;
    }
    return result;
  }

  ProductionLot copyWith({
    SyncFields? sync,
    String? currentStage,
    String? currentLocation,
    String? status,
    int? deadAccumulated,
    int? currentAnimals,
    double? totalSoldWeight,
    DateTime? saleDate,
    List<CostLine>? costLines,
  }) {
    return ProductionLot(
      sync: sync ?? this.sync,
      code: code,
      motherId: motherId,
      birthDate: birthDate,
      totalBorn: totalBorn,
      bornAlive: bornAlive,
      bornDead: bornDead,
      weaned: weaned,
      moved: moved,
      deadAccumulated: deadAccumulated ?? this.deadAccumulated,
      currentAnimals: currentAnimals ?? this.currentAnimals,
      currentStage: currentStage ?? this.currentStage,
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      costLines: costLines ?? this.costLines,
      totalSoldWeight: totalSoldWeight ?? this.totalSoldWeight,
      saleDate: saleDate ?? this.saleDate,
    );
  }
}

class ProductiveMovement {
  ProductiveMovement({
    required this.sync,
    required this.date,
    required this.lotId,
    required this.originStage,
    required this.destinationStage,
    required this.movedAnimals,
    this.note = '',
  });

  final SyncFields sync;
  final DateTime date;
  final String lotId;
  final String originStage;
  final String destinationStage;
  final int movedAnimals;
  final String note;
}

class ReproductiveCycle {
  ReproductiveCycle({
    required this.sync,
    required this.motherId,
    required this.serviceDate,
    required this.estimatedFarrowingDate,
    required this.status,
    required this.gestationCost,
    this.confirmationDate,
    this.realFarrowingDate,
    this.note = '',
  });

  final SyncFields sync;
  final String motherId;
  final DateTime serviceDate;
  final DateTime? confirmationDate;
  final DateTime estimatedFarrowingDate;
  final DateTime? realFarrowingDate;
  final String status;
  final double gestationCost;
  final String note;
}

class ConsumptionRecord {
  ConsumptionRecord({
    required this.sync,
    required this.date,
    required this.target,
    required this.stage,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.conversionToBase,
    required this.baseQuantity,
    required this.unitCost,
    required this.totalCost,
    required this.responsible,
    this.lotId = '',
    this.corral = '',
    this.animalId = '',
    this.animalsTreated = 0,
    this.note = '',
  });

  final SyncFields sync;
  final DateTime date;
  final ConsumptionTarget target;
  final String stage;
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final double conversionToBase;
  final double baseQuantity;
  final double unitCost;
  final double totalCost;
  final String lotId;
  final String corral;
  final String animalId;
  final int animalsTreated;
  final String responsible;
  final String note;
}

class ManagementProtocol {
  ManagementProtocol({
    required this.sync,
    required this.name,
    required this.stage,
    required this.recommendedDay,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.appliesTo,
    this.note = '',
  });

  final SyncFields sync;
  final String name;
  final String stage;
  final int recommendedDay;
  final String productId;
  final String productName;
  final double quantity;
  final String unit;
  final ConsumptionTarget appliesTo;
  final String note;
}

class MortalityRecord {
  MortalityRecord({
    required this.sync,
    required this.date,
    required this.lotId,
    required this.stage,
    required this.deadCount,
    this.cause = '',
    this.note = '',
    this.responsible = '',
  });

  final SyncFields sync;
  final DateTime date;
  final String lotId;
  final String stage;
  final int deadCount;
  final String cause;
  final String note;
  final String responsible;
}

class SaleRecord {
  SaleRecord({
    required this.sync,
    required this.lotId,
    required this.date,
    required this.soldAnimals,
    required this.totalWeight,
    required this.averageWeight,
    required this.pricePerKg,
    required this.totalSale,
    required this.buyer,
    this.note = '',
  });

  final SyncFields sync;
  final String lotId;
  final DateTime date;
  final int soldAnimals;
  final double totalWeight;
  final double averageWeight;
  final double pricePerKg;
  final double totalSale;
  final String buyer;
  final String note;
}

class UnitConfig {
  const UnitConfig({
    required this.unit,
    required this.baseUnit,
    required this.factor,
    required this.productId,
  });

  final String unit;
  final String baseUnit;
  final double factor;
  final String productId;
}

class ReferenceRation {
  const ReferenceRation({
    required this.stage,
    required this.animalType,
    required this.condition,
    required this.kgPerDay,
    required this.kgMorning,
    required this.kgAfternoon,
    this.active = true,
  });

  final String stage;
  final String animalType;
  final String condition;
  final double kgPerDay;
  final double kgMorning;
  final double kgAfternoon;
  final bool active;
}
