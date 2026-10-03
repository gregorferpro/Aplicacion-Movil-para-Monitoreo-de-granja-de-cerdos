import 'package:cabana_cerdos_app/data/production_cost_codec.dart';
import 'package:cabana_cerdos_app/repositories/production_cost_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production cost state survives a SQLite JSON round trip', () {
    final repository = ProductionCostRepository.seeded();

    final encoded = encodeProductionCostState(
      products: repository.products,
      purchases: repository.purchases,
      movements: repository.movements,
      formulas: repository.formulas,
      preparedBatches: repository.preparedBatches,
      lots: repository.lots,
      productiveMovements: repository.productiveMovements,
      cycles: repository.cycles,
      consumptions: repository.consumptions,
      protocols: repository.protocols,
      mortalities: repository.mortalities,
      sales: repository.sales,
      referenceRations: repository.referenceRations,
      allowNegativeStock: repository.allowNegativeStock,
      defaultProfitMargin: repository.defaultProfitMargin,
    );
    final decoded = decodeProductionCostState(encoded);

    expect(decoded.products.length, repository.products.length);
    expect(decoded.purchases.length, repository.purchases.length);
    expect(decoded.movements.length, repository.movements.length);
    expect(decoded.formulas.length, repository.formulas.length);
    expect(decoded.preparedBatches.length, repository.preparedBatches.length);
    expect(decoded.lots.length, repository.lots.length);
    expect(
      decoded.productiveMovements.length,
      repository.productiveMovements.length,
    );
    expect(decoded.cycles.length, repository.cycles.length);
    expect(decoded.consumptions.length, repository.consumptions.length);
    expect(decoded.protocols.length, repository.protocols.length);
    expect(decoded.mortalities.length, repository.mortalities.length);
    expect(decoded.sales.length, repository.sales.length);
    expect(decoded.referenceRations.length, repository.referenceRations.length);
    expect(decoded.products.first.name, repository.products.first.name);
    expect(decoded.lots.first.code, repository.lots.first.code);
    expect(decoded.allowNegativeStock, repository.allowNegativeStock);
    expect(decoded.defaultProfitMargin, repository.defaultProfitMargin);
  });
}
