import 'package:equatable/equatable.dart';

class IncomeModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String? description;

  // Optional: Include category name for UI convenience if joined
  final String? categoryName;

  const IncomeModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.description,
    this.categoryName,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      categoryName: json['income_categories'] != null
          ? json['income_categories']['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, categoryId, amount, date, description, categoryName];
}
