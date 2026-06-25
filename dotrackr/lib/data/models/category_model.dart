import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  String iconName;

  @HiveField(4)
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.colorValue = 0xFFB0B0B0,
    this.iconName = 'folder',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CategoryModel copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? iconName,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}