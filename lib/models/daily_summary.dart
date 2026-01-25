import 'package:equatable/equatable.dart';

class DailySummary extends Equatable {
  final String id;
  final String? userId; // User ID for multi-tenant support
  final DateTime date;
  final double totalIncome;
  final double totalExpense;
  final double profit;
  final int mealsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailySummary({
    required this.id,
    this.userId,
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
    required this.profit,
    required this.mealsCount,
    this.createdAt,
    this.updatedAt,
  });

  bool get isProfitable => profit > 0;
  bool get isLoss => profit < 0;

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      totalIncome: _parseDouble(json['total_income']),
      totalExpense: _parseDouble(json['total_expense']),
      profit: _parseDouble(json['profit']),
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
      'user_id': userId,
      'date': date.toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'profit': profit,
      'meals_count': mealsCount,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      if (userId != null) 'user_id': userId,
      'date': date.toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'profit': profit,
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

  DailySummary copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? totalIncome,
    double? totalExpense,
    double? profit,
    int? mealsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailySummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      profit: profit ?? this.profit,
      mealsCount: mealsCount ?? this.mealsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        totalIncome,
        totalExpense,
        profit,
        mealsCount,
        createdAt,
        updatedAt,
      ];
}
