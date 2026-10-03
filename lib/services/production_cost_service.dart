class ProductionCostService {
  const ProductionCostService();

  double convertToBase({
    required double quantity,
    required double conversionToBase,
  }) {
    return quantity * conversionToBase;
  }

  double unitPrice({required double totalPrice, required double baseQuantity}) {
    if (baseQuantity <= 0) return 0;
    return totalPrice / baseQuantity;
  }

  double weightedAverageCost({
    required double currentStock,
    required double currentAverageCost,
    required double incomingQuantity,
    required double incomingUnitCost,
  }) {
    final totalStock = currentStock + incomingQuantity;
    if (totalStock <= 0) return 0;
    return ((currentStock * currentAverageCost) +
            (incomingQuantity * incomingUnitCost)) /
        totalStock;
  }

  double ingredientQuantity({
    required double totalPreparedKg,
    required double percentage,
  }) {
    return totalPreparedKg * percentage / 100;
  }

  double costPerKg({required double totalCost, required double totalKg}) {
    if (totalKg <= 0) return 0;
    return totalCost / totalKg;
  }

  double costPerLiveAnimal({
    required double accumulatedCost,
    required int liveAnimals,
  }) {
    if (liveAnimals <= 0) return 0;
    return accumulatedCost / liveAnimals;
  }

  double costPerProducedKg({
    required double accumulatedCost,
    required double soldWeight,
  }) {
    if (soldWeight <= 0) return 0;
    return accumulatedCost / soldWeight;
  }

  double suggestedPrice({
    required double costPerKg,
    required double profitMargin,
  }) {
    return costPerKg * (1 + profitMargin);
  }

  double weightedSectorCost({
    required double totalCosts,
    required double totalProducedKg,
  }) {
    if (totalProducedKg <= 0) return 0;
    return totalCosts / totalProducedKg;
  }
}
