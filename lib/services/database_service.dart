import '../models/customer_profile.dart';
import '../models/db_product.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  // Local in-memory products fallback for no-Firebase mode.
  final List<DbProduct> _localProducts = [];

  Stream<List<DbProduct>> streamProducts({bool onlyActive = true}) async* {
    // Return local products and then any updates
    yield _localProducts;
  }

  Future<void> syncAuthUser(dynamic user, {String? fullName}) async {
    // No-op for local mode.
  }

  Future<void> upsertProduct({
    String? id,
    required String name,
    required String image,
    required double priceUSD,
    required int priceKHR,
    String productType = 'unit',
    String packingGroup = 'general',
    String deliveryRule = 'group_capacity',
    int deliveryFactor = 1,
    int deliveryBoxCapacity = 1,
    required String category,
    bool isActive = true,
  }) async {
    final product = DbProduct(
      id: id ?? name,
      name: name,
      image: image,
      priceUSD: priceUSD,
      priceKHR: priceKHR,
      productType: productType,
      packingGroup: packingGroup,
      deliveryRule: deliveryRule,
      deliveryFactor: deliveryFactor,
      deliveryBoxCapacity: deliveryBoxCapacity,
      category: category,
      isActive: isActive,
    );
    _localProducts.removeWhere((p) => p.id == product.id);
    _localProducts.add(product);
  }

  Future<void> deleteProduct(String productId) async {
    _localProducts.removeWhere((p) => p.id == productId);
  }

  Future<CustomerProfile?> getCustomerProfile(String userId) async {
    return null;
  }

  Future<CustomerProfile> ensureCustomerProfile(dynamic user) async {
    return CustomerProfile(
      userId: user?.uid?.toString() ?? 'local',
      fullName: user?.displayName?.toString() ?? '',
      email: user?.email?.toString() ?? '',
      phone: '',
      address: '',
      profileImageUrl: '',
      profileImagePath: '',
      profileImageData: '',
    );
  }

  Future<void> upsertCustomerProfile(CustomerProfile profile) async {
    // no-op local mode
  }

  Future<Map<String, String>> uploadCustomerProfileImage({
    required String userId,
    required List<int> bytes,
    String? previousImagePath,
  }) async {
    return {'imageUrl': '', 'imagePath': ''};
  }

  Future<void> deleteCustomerProfileImage(String imagePath) async {
    // no-op local mode
  }
}
