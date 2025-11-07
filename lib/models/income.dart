import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final String id;
  final DateTime date;
  final double onlineIncome;
  final double offlineIncome;
  final int mealsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Income({
    required this.id,
    required this.date,
    required this.onlineIncome,
    required this.offlineIncome,
    this.mealsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  double get totalIncome => onlineIncome + offlineIncome;

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      onlineIncome: _parseDouble(json['online_income']),
      offlineIncome: _parseDouble(json['offline_income']),
      mealsCount: _parseInt(json['meals_count']),
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
      'online_income': onlineIncome,
      'offline_income': offlineIncome,
      'meals_count': mealsCount,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'date': date.toIso8601String(),
      'online_income': onlineIncome,
      'offline_income': offlineIncome,
      'meals_count': mealsCount,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Income copyWith({
    String? id,
    DateTime? date,
    double? onlineIncome,
    double? offlineIncome,
    int? mealsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      date: date ?? this.date,
      onlineIncome: onlineIncome ?? this.onlineIncome,
      offlineIncome: offlineIncome ?? this.offlineIncome,
      mealsCount: mealsCount ?? this.mealsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        onlineIncome,
        offlineIncome,
        mealsCount,
        createdAt,
        updatedAt,
      ];
}
