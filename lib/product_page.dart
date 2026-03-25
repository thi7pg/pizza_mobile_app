import 'dart:async';

import 'package:flutter/material.dart';
import 'services/api_service.dart';

class ProductPage extends StatefulWidget {
  final List<Map<String, dynamic>>? sharedCart;
  final VoidCallback? onCartUpdated;
  final VoidCallback? onGoToCart;
  final VoidCallback? onGoToOrders;

  const ProductPage({
    super.key,
    this.sharedCart,
    this.onCartUpdated,
    this.onGoToCart,
    this.onGoToOrders,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

// 🧀 Product model
class Product {
  final String name;
  final String img;
  final double priceUSD;
  final int priceKHR;
  final String category;
  final String productType;
  final String packingGroup;
  final String deliveryRule;
  final int deliveryFactor;
  final int deliveryBoxCapacity;

  Product({
    required this.name,
    required this.img,
    required this.priceUSD,
    required this.priceKHR,
    required this.category,
    required this.productType,
    required this.packingGroup,
    required this.deliveryRule,
    required this.deliveryFactor,
    required this.deliveryBoxCapacity,
  });

  String get cartKey => [
    name,
    productType,
    packingGroup,
    deliveryRule,
    deliveryFactor,
    deliveryBoxCapacity,
  ].join('|');
}

class _ProductPageState extends State<ProductPage> {
  final List<Map<String, dynamic>> _standaloneCart = [];
  final TextEditingController _searchController = TextEditingController();
  List<Product> _dbProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'ទាំងអស់';
  bool _isLoading = true;

  List<Map<String, dynamic>> get cart => widget.sharedCart ?? _standaloneCart;

  List<Product> get products => _dbProducts;

  List<String> get categories {
    final uniqueCategories = products.map((p) => p.category).toSet().toList()
      ..sort();
    return ['ទាំងអស់', ...uniqueCategories];
  }

  List<Product> get filteredProducts {
    var list = _selectedCategory == 'ទាំងអស់'
        ? products
        : products.where((p) => p.category == _selectedCategory).toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final apiProducts = await ApiService.getProducts();
      if (!mounted) return;
      setState(() {
        _dbProducts = apiProducts
            .where((p) => p.isActive)
            .map((p) => Product(
                  name: p.name,
                  img: p.image,
                  priceUSD: p.priceUSD,
                  priceKHR: p.priceKHR,
                  category: p.category,
                  productType: p.productType,
                  packingGroup: p.packingGroup,
                  deliveryRule: p.deliveryRule,
                  deliveryFactor: p.deliveryFactor,
                  deliveryBoxCapacity: p.deliveryBoxCapacity,
                ))
            .toList();
      });
    } catch (error) {
      print('Load products error: $error');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int _cartQtyFor(Product product) {
    return cart.fold<int>(
      0,
      (totalQty, item) =>
          totalQty +
          (((item['product'] as Product).cartKey == product.cartKey)
              ? ((item['qty'] as int?) ?? 0)
              : 0),
    );
  }

  int get _totalCartQty =>
      cart.fold<int>(0, (sum, item) => sum + ((item['qty'] as int?) ?? 0));

  void _addToCart(Product product) {
    setState(() {
      final existing = cart.where(
        (item) => (item['product'] as Product).cartKey == product.cartKey,
      );
      if (existing.isNotEmpty) {
        existing.first['qty']++;
      } else {
        cart.add({'product': product, 'qty': 1});
      }
    });
    widget.onCartUpdated?.call();
  }

  void _decreaseFromCart(Product product) {
    setState(() {
      final existing = cart
          .where(
            (item) => (item['product'] as Product).cartKey == product.cartKey,
          )
          .toList();
      if (existing.isNotEmpty) {
        if (existing.first['qty'] > 1) {
          existing.first['qty']--;
        } else {
          cart.remove(existing.first);
        }
      }
    });
    widget.onCartUpdated?.call();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = _totalCartQty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          // ─── Header ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ផលិតផល',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              'Products',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        // Cart badge button
                        GestureDetector(
                          onTap: () => _showCart(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.white30,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shopping_basket_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                if (totalQty > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.shade700,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$totalQty',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            //ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកផលិតផល...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFE53935),
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey.shade400,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Category chips ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE53935,
                                    //ignore: deprecated_member_use
                                  ).withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  //ignore: deprecated_member_use
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Count label ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredProducts.length} ផលិតផល',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _selectedCategory,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ─── Product grid ────────────────────────────────────
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'រកមិនឃើញផលិតផល',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 290,
                        ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final qtyInCart = _cartQtyFor(product);
                      return _ProductCard(
                        product: product,
                        qtyInCart: qtyInCart,
                        onAdd: () => _addToCart(product),
                        onDecrease: () => _decreaseFromCart(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCart(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (cart.isEmpty) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 28),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'កន្ត្រកទំនិញទទេ',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          double totalUSD = cart.fold(
            0,
            (sum, item) => sum + item['product'].priceUSD * item['qty'],
          );
          int totalKHR = cart.fold(
            0,
            (sum, item) =>
                sum + (item['product'].priceKHR * item['qty'] as int),
          );

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle + title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'កន្ត្រកទំនិញ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                //ignore: deprecated_member_use
                                color: const Color(0xFFE53935).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${cart.length} ទំនិញ',
                                style: const TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade100, height: 1),
                      ],
                    ),
                  ),

                  // Cart items list
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: cart.length,
                      //ignore: unnecessary_underscores
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        final product = item['product'] as Product;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.white,
                                  child: Image.asset(
                                    product.img,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                              size: 24,
                                            ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name & price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.productType,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${(product.priceUSD * item['qty']).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFFE53935),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity control
                              Row(
                                children: [
                                  _QtyButton(
                                    icon: item['qty'] == 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    color: item['qty'] == 1
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                    bg: item['qty'] == 1
                                        ? Colors.red.shade50
                                        : Colors.grey.shade200,
                                    onTap: () {
                                      setModalState(() {
                                        setState(() {
                                          if (item['qty'] > 1) {
                                            item['qty']--;
                                          } else {
                                            cart.removeAt(index);
                                          }
                                        });
                                        widget.onCartUpdated?.call();
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: 34,
                                    child: Center(
                                      child: Text(
                                        '${item['qty']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add,
                                    color: Colors.white,
                                    bg: const Color(0xFFE53935),
                                    onTap: () {
                                      setModalState(() {
                                        setState(() => item['qty']++);
                                        widget.onCartUpdated?.call();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Total + place order
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          //ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'សរុបទាំងអស់',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${totalUSD.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                                Text(
                                  '${totalKHR.toString()} រៀល',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              if (widget.onGoToCart != null) {
                                widget.onGoToCart!.call();
                                return;
                              }
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Open the Cart page to continue checkout.',
                                  ),
                                  backgroundColor: Color(0xFFE53935),
                                ),
                              );
                            },
                            child: const Text(
                              'បន្តទៅ Cart  →',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatKHR(int khr) {
  // e.g. 51900 → "51,900"
  final s = khr.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ─── Product card widget ────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final int qtyInCart;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;

  const _ProductCard({
    required this.product,
    required this.qtyInCart,
    required this.onAdd,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final bool inCart = qtyInCart > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            //ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image zone ──────────────────────────────────
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFF0F0),
                        const Color(0xFFFFF8F8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Product image
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(
                    product.img,
                    fit: BoxFit.contain,
                    //ignore: unnecessary_underscores
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade300,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Category chip — top left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                ),
                // Cart qty badge — top right
                if (inCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                //ignore: deprecated_member_use
                                const Color(0xFFE53935).withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'x$qtyInCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Detail zone ─────────────────────────────────
          Expanded(
            flex: 9,
            child: Container(
              decoration: BoxDecoration(
                color: inCart ? const Color(0xFFFFF5F5) : Colors.white,
                border: inCart
                    ? const Border(
                        top: BorderSide(color: Color(0xFFE53935), width: 2),
                      )
                    : null,
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.productType,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${product.priceUSD.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE53935),
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_formatKHR(product.priceKHR)}រ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Add / qty control
                  qtyInCart == 0
                      ? SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_shopping_cart, size: 14),
                            label: const Text(
                              'ដាក់ក្នុងកន្ត្រក',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 32,
                          decoration: BoxDecoration(
                            //ignore: deprecated_member_use
                            color: const Color(0xFFE53935).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              // Decrease / delete
                              GestureDetector(
                                onTap: onDecrease,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                  ),
                                  child: Icon(
                                    qtyInCart == 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Qty label
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '$qtyInCart',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                              ),
                              // Add
                              GestureDetector(
                                onTap: onAdd,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small qty icon button ──────────────────────────────────────────
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
