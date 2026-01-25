import 'package:equatable/equatable.dart';

enum CategoryType { income, expense }

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String userId;
  final CategoryType type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.userId,
    required this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, CategoryType type) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
    };
  }

  @override
  List<Object?> get props => [id, name, userId, type];
}
