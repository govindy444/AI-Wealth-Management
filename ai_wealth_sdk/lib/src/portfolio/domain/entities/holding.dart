import 'package:equatable/equatable.dart';

enum AssetClass {
  equity,
  debt,
  gold,
  cash,
  realEstate;

  static AssetClass fromWire(String value) => switch (value) {
        'equity' => AssetClass.equity,
        'debt' => AssetClass.debt,
        'gold' => AssetClass.gold,
        'cash' => AssetClass.cash,
        'real_estate' => AssetClass.realEstate,
        _ => AssetClass.cash,
      };

  String get label => switch (this) {
        AssetClass.equity => 'Equity',
        AssetClass.debt => 'Debt',
        AssetClass.gold => 'Gold',
        AssetClass.cash => 'Cash',
        AssetClass.realEstate => 'Real Estate',
      };
}

/// A single investment holding with its performance.
class Holding extends Equatable {
  const Holding({
    required this.id,
    required this.name,
    required this.assetClass,
    required this.invested,
    required this.currentValue,
    required this.gain,
    required this.gainPct,
  });

  final String id;
  final String name;
  final AssetClass assetClass;
  final double invested;
  final double currentValue;
  final double gain;
  final double gainPct;

  bool get isUp => gain >= 0;

  @override
  List<Object?> get props =>
      [id, name, assetClass, invested, currentValue, gain, gainPct];
}
