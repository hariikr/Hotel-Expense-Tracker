import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final DateTime date;
  final String context; // 'hotel' or 'house'
  final double fish;
  final double meat;
  final double chicken;
  final double milk;
  final double parotta;
  final double pathiri;
  final double dosa;
  final double appam;
  final double coconut;
  final double vegetables;
  final double rice;
  final double laborManisha;
  final double laborMidhun;
  final double others;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Expense({
    required this.id,
    required this.date,
    required this.context,
    required this.fish,
    required this.meat,
    required this.chicken,
    required this.milk,
    required this.parotta,
    required this.pathiri,
    required this.dosa,
    required this.appam,
    required this.coconut,
    required this.vegetables,
    required this.rice,
    required this.laborManisha,
    required this.laborMidhun,
    required this.others,
    this.createdAt,
    this.updatedAt,
  });

  double get totalExpense =>
      fish +
      meat +
      chicken +
      milk +
      parotta +
      pathiri +
      dosa +
      appam +
      coconut +
      vegetables +
      rice +
      laborManisha +
      laborMidhun +
      others;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      context: json['context'] as String? ?? 'hotel',
      fish: _parseDouble(json['fish']),
      meat: _parseDouble(json['meat']),
      chicken: _parseDouble(json['chicken']),
      milk: _parseDouble(json['milk']),
      parotta: _parseDouble(json['parotta']),
      pathiri: _parseDouble(json['pathiri']),
      dosa: _parseDouble(json['dosa']),
      appam: _parseDouble(json['appam']),
      coconut: _parseDouble(json['coconut']),
      vegetables: _parseDouble(json['vegetables']),
      rice: _parseDouble(json['rice']),
      laborManisha: _parseDouble(json['labor_manisha']),
      laborMidhun: _parseDouble(json['labor_midhun']),
      others: _parseDouble(json['others']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'context': context,
      'fish': fish,
      'meat': meat,
      'chicken': chicken,
      'milk': milk,
      'parotta': parotta,
      'pathiri': pathiri,
      'dosa': dosa,
      'appam': appam,
      'coconut': coconut,
      'vegetables': vegetables,
      'rice': rice,
      'labor_manisha': laborManisha,
      'labor_midhun': laborMidhun,
      'others': others,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'date': date.toIso8601String(),
      'context': context,
      'fish': fish,
      'meat': meat,
      'chicken': chicken,
      'milk': milk,
      'parotta': parotta,
      'pathiri': pathiri,
      'dosa': dosa,
      'appam': appam,
      'coconut': coconut,
      'vegetables': vegetables,
      'rice': rice,
      'labor_manisha': laborManisha,
      'labor_midhun': laborMidhun,
      'others': others,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Expense copyWith({
    String? id,
    DateTime? date,
    String? context,
    double? fish,
    double? meat,
    double? chicken,
    double? milk,
    double? parotta,
    double? pathiri,
    double? dosa,
    double? appam,
    double? coconut,
    double? vegetables,
    double? rice,
    double? laborManisha,
    double? laborMidhun,
    double? others,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      context: context ?? this.context,
      fish: fish ?? this.fish,
      meat: meat ?? this.meat,
      chicken: chicken ?? this.chicken,
      milk: milk ?? this.milk,
      parotta: parotta ?? this.parotta,
      pathiri: pathiri ?? this.pathiri,
      dosa: dosa ?? this.dosa,
      appam: appam ?? this.appam,
      coconut: coconut ?? this.coconut,
      vegetables: vegetables ?? this.vegetables,
      rice: rice ?? this.rice,
      laborManisha: laborManisha ?? this.laborManisha,
      laborMidhun: laborMidhun ?? this.laborMidhun,
      others: others ?? this.others,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        context,
        fish,
        meat,
        chicken,
        milk,
        parotta,
        pathiri,
        dosa,
        appam,
        coconut,
        vegetables,
        rice,
        laborManisha,
        laborMidhun,
        others,
        createdAt,
        updatedAt,
      ];
}
