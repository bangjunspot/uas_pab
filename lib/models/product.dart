class Product {
  final String id;
  final String name;
  final String? category;
  final double price;
  final String? imageUrl;
  final int minStock;
  final bool isActive;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.minStock,
    required this.isActive,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      category: map['category']?.toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['image_url']?.toString(),
      minStock: (map['min_stock'] as num?)?.toInt() ?? 3,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'min_stock': minStock,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdate() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'min_stock': minStock,
      'is_active': isActive,
    };
  }
}
