class DbProduct {
  final String id;
  final String name;
  final String image;
  final double priceUSD;
  final int priceKHR;
  final String productType;
  final String packingGroup;
  final String deliveryRule;
  final int deliveryFactor;
  final int deliveryBoxCapacity;
  final String category;
  final bool isActive;

  const DbProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.priceUSD,
    required this.priceKHR,
    required this.productType,
    required this.packingGroup,
    required this.deliveryRule,
    required this.deliveryFactor,
    required this.deliveryBoxCapacity,
    required this.category,
    required this.isActive,
  });

  factory DbProduct.fromMap(Map<String, dynamic> data) {
    return DbProduct(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
      priceUSD: (data['priceUSD'] is num) ? (data['priceUSD'] as num).toDouble() : 0.0,
      priceKHR: (data['priceKHR'] is int) ? data['priceKHR'] as int : 0,
      productType: data['productType']?.toString() ?? 'unit',
      packingGroup: data['packingGroup']?.toString() ?? 'general',
      deliveryRule: data['deliveryRule']?.toString() ?? 'group_capacity',
      deliveryFactor: (data['deliveryFactor'] is int) ? data['deliveryFactor'] as int : 1,
      deliveryBoxCapacity: (data['deliveryBoxCapacity'] is int) ? data['deliveryBoxCapacity'] as int : 1,
      category: data['category']?.toString() ?? 'General',
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'priceUSD': priceUSD,
      'priceKHR': priceKHR,
      'productType': productType,
      'packingGroup': packingGroup,
      'deliveryRule': deliveryRule,
      'deliveryFactor': deliveryFactor,
      'deliveryBoxCapacity': deliveryBoxCapacity,
      'category': category,
      'isActive': isActive,
    };
  }
}
