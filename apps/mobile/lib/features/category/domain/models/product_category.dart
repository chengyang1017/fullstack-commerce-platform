class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.iconName,
    required this.iconColorStart,
    required this.iconColorEnd,
  });

  final String id;
  final String name;
  final int sortOrder;
  final String iconName;
  final String iconColorStart;
  final String iconColorEnd;

  factory ProductCategory.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder:
          (json['sortOrder'] as num?)?.toInt() ?? 0,
      iconName:
          json['iconName'] as String? ?? 'category',
      iconColorStart:
          json['iconColorStart'] as String? ?? '#7C3AED',
      iconColorEnd:
          json['iconColorEnd'] as String? ?? '#06B6D4',
    );
  }
}
