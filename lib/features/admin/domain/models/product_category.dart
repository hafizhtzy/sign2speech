import 'package:flutter/foundation.dart';

@immutable
class ProductCategory {
  final String id;
  final String slug;
  final String nameId;
  final String nameEn;
  final String description;
  final int sortOrder;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.slug,
    required this.nameId,
    this.nameEn = '',
    this.description = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ProductCategory.fromPostgresMap(Map<String, dynamic> map) {
    return ProductCategory(
      id: (map['id'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
      nameId: (map['name_id'] ?? map['nameId'] ?? '').toString(),
      nameEn: (map['name_en'] ?? map['nameEn'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      sortOrder: ((map['sort_order'] ?? map['sortOrder'] ?? 0) as num).toInt(),
      isActive: (map['is_active'] ?? map['isActive'] ?? true) == true,
    );
  }

  Map<String, dynamic> toPostgresMap() {
    return <String, dynamic>{
      if (id.isNotEmpty) 'id': id,
      'slug': slug.trim().toLowerCase(),
      'name_id': nameId.trim(),
      'name_en': nameEn.trim().isEmpty ? nameId.trim() : nameEn.trim(),
      'description': description.trim(),
      'sort_order': sortOrder,
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
