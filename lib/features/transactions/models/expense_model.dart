import 'package:equatable/equatable.dart';

class ExpenseModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String? description;
  final String? quantity;

  // Optional: Include category name for UI convenience if joined
  final String? categoryName;

  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.description,
    this.quantity,
    this.categoryName,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      quantity: json['quantity'] as String?,
      categoryName: json['expense_categories'] != null
          ? json['expense_categories']['name'] as String?
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
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'quantity': quantity,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amount,
        date,
        description,
        quantity,
        categoryName
      ];
}
