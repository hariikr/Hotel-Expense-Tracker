import 'package:equatable/equatable.dart';

class BillItemModel extends Equatable {
  final String id;
  final String billId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const BillItemModel({
    required this.id,
    required this.billId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory BillItemModel.fromJson(Map<String, dynamic> json) {
    return BillItemModel(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      itemName: json['item_name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'bill_id': billId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  @override
  List<Object?> get props =>
      [id, billId, itemName, quantity, unitPrice, totalPrice];
}

class BillModel extends Equatable {
  final String id;
  final String userId;
  final String billNumber;
  final String customerName;
  final String customerPhone;
  final DateTime billDate;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double discount;
  final double totalAmount;
  final String? notes;
  final String? incomeId;
  final DateTime? createdAt;
  final List<BillItemModel> items;

  const BillModel({
    required this.id,
    required this.userId,
    required this.billNumber,
    required this.customerName,
    required this.customerPhone,
    required this.billDate,
    required this.subtotal,
    this.taxPercent = 0,
    this.taxAmount = 0,
    this.discount = 0,
    required this.totalAmount,
    this.notes,
    this.incomeId,
    this.createdAt,
    this.items = const [],
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['bill_items'] as List<dynamic>?;
    return BillModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      billNumber: json['bill_number'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      billDate: DateTime.parse(json['bill_date'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      incomeId: json['income_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      items: itemsList != null
          ? itemsList
              .map((e) => BillItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'bill_number': billNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'bill_date': billDate.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'discount': discount,
      'total_amount': totalAmount,
      'notes': notes,
      'income_id': incomeId,
    };
  }

  BillModel copyWith({
    String? id,
    String? userId,
    String? billNumber,
    String? customerName,
    String? customerPhone,
    DateTime? billDate,
    double? subtotal,
    double? taxPercent,
    double? taxAmount,
    double? discount,
    double? totalAmount,
    String? notes,
    String? incomeId,
    List<BillItemModel>? items,
  }) {
    return BillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      billNumber: billNumber ?? this.billNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      billDate: billDate ?? this.billDate,
      subtotal: subtotal ?? this.subtotal,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      incomeId: incomeId ?? this.incomeId,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        billNumber,
        customerName,
        customerPhone,
        billDate,
        subtotal,
        taxPercent,
        taxAmount,
        discount,
        totalAmount,
        notes,
        incomeId,
        items,
      ];
}
