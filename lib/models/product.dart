class Product {
  final String id;
  final String categoryId;
  final String title;
  final String image;
  final double price;
  final int sold;

  const Product({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.image,
    required this.price,
    required this.sold,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'image': image,
      'price': price,
      'sold': sold,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      image: json['image'] as String,
      price: (json['price'] as num).toDouble(),
      sold: (json['sold'] as num).toInt(),
    );
  }
}

final List<Product> products = [
  const Product(
    id: 'product_001',
    categoryId: 'phone',
    title: '智能手機',
    image: 'https://picsum.photos/id/160/600/600',
    price: 1299,
    sold: 328,
  ),
  const Product(
    id: 'product_002',
    categoryId: 'computer',
    title: '筆記型電腦',
    image: 'https://picsum.photos/id/180/600/600',
    price: 3599,
    sold: 196,
  ),
  const Product(
    id: 'product_003',
    categoryId: 'camera',
    title: '數位相機',
    image: 'https://picsum.photos/id/250/600/600',
    price: 2199,
    sold: 87,
  ),
];
