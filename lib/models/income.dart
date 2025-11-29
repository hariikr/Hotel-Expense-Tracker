import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final String id;
  final DateTime date;
  final String context; // Context identifier (defaults to 'hotel')
  final double onlineIncome;
  final double offlineIncome;
  final int mealsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // New SaaS features - backward compatible (optional fields)
  final String? notes;
  final String? paymentMethod; // 'cash', 'upi', 'card', 'mixed'
  final List<String>? attachments; // List of image URLs/paths
  final Map<String, dynamic>? metadata; // For future extensibility

  const Income({
    required this.id,
    required this.date,
    required this.context,
    required this.onlineIncome,
    required this.offlineIncome,
    this.mealsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.paymentMethod,
    this.attachments,
    this.metadata,
  });

  double get totalIncome => onlineIncome + offlineIncome;

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      context: json['context'] as String? ?? 'hotel',
      onlineIncome: _parseDouble(json['online_income']),
      offlineIncome: _parseDouble(json['offline_income']),
      mealsCount: _parseInt(json['meals_count']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method'] as String?,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'context': context,
      'online_income': onlineIncome,
      'offline_income': offlineIncome,
      'meals_count': mealsCount,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'date': date.toIso8601String(),
      'context': context,
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
    String? context,
    double? onlineIncome,
    double? offlineIncome,
    int? mealsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? paymentMethod,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return Income(
      id: id ?? this.id,
      date: date ?? this.date,
      context: context ?? this.context,
      onlineIncome: onlineIncome ?? this.onlineIncome,
      offlineIncome: offlineIncome ?? this.offlineIncome,
      mealsCount: mealsCount ?? this.mealsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        context,
        onlineIncome,
        offlineIncome,
        mealsCount,
        createdAt,
        updatedAt,
        notes,
        paymentMethod,
        attachments,
        metadata,
      ];
}
