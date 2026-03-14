import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_page.dart';

String _fmtKHR(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final VoidCallback onCartUpdated;
  final VoidCallback onGoToProducts;
  final VoidCallback onGoToOrders;

  const CartPage({
    super.key,
    required this.cart,
    required this.onCartUpdated,
    required this.onGoToProducts,
    required this.onGoToOrders,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isPlacingOrder = false;
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> get cart => widget.cart;

  double get _totalUSD => cart.fold(
      0.0, (sum, item) => sum + item['product'].priceUSD * item['qty']);
  int get _totalKHR => cart.fold(
      0, (sum, item) => sum + (item['product'].priceKHR * item['qty'] as int));
  int get _totalQty =>
      cart.fold<int>(0, (sum, item) => sum + ((item['qty'] as int?) ?? 0));

  void _changeQty(int index, int delta) {
    setState(() {
      final qty = (cart[index]['qty'] as int) + delta;
      if (qty <= 0) {
        cart.removeAt(index);
      } else {
        cart[index]['qty'] = qty;
      }
    });
    widget.onCartUpdated();
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'បញ្ជាក់ការបញ្ជាទិញ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: Color(0xFFE53935), size: 18),
                const SizedBox(width: 8),
                Text('$_totalQty ទំនិញ',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money_rounded,
                    color: Color(0xFFE53935), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '\$${_totalUSD.toStringAsFixed(2)}  ·  ${_fmtKHR(_totalKHR)} រៀល',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (_noteController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined,
                        size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_noteController.text.trim(),
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('យល់ព្រម',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isPlacingOrder = true);
    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'email': user.email,
        'note': _noteController.text.trim(),
        'items': cart
            .map((item) => {
                  'name': item['product'].name,
                  'img': item['product'].img,
                  'qty': item['qty'],
                  'priceUSD': item['product'].priceUSD,
                  'priceKHR': item['product'].priceKHR,
                })
            .toList(),
        'totalUSD': _totalUSD,
        'totalKHR': _totalKHR,
        'status': 'Processing',
        'createdAt': FieldValue.serverTimestamp(),
      });

      cart.clear();
      _noteController.clear();
      widget.onCartUpdated();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ បានបញ្ជាទិញដោយជោគជ័យ!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      widget.onGoToOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: cart.isEmpty
          ? _EmptyCart(onGoToProducts: widget.onGoToProducts)
          : Column(
              children: [
                // ── Gradient header ──────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'កន្ត្រកទំនិញ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$_totalQty ទំនិញរង្ចាំ',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18)),
                                title: const Text('លុបទំនិញទាំងអស់?'),
                                content: const Text(
                                    'តើអ្នកពិតជាចង់លុបទំនិញទាំងអស់ចេញពីកន្ត្រកមែនទេ?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx),
                                      child: const Text('បោះបង់')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE53935),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10))),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      setState(() => cart.clear());
                                      widget.onCartUpdated();
                                    },
                                    child: const Text('លុប',
                                        style: TextStyle(
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.white30),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.delete_sweep_outlined,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 5),
                                  Text(
                                    'លុបទាំងអស់',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Item list ────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: cart.length + 1,
                    itemBuilder: (context, index) {
                      if (index == cart.length) {
                        return _NoteField(controller: _noteController);
                      }
                      final item = cart[index];
                      final product = item['product'] as Product;
                      final int qty = item['qty'] as int;
                      final subtotalUSD = product.priceUSD * qty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  product.img,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 28),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${product.priceUSD.toStringAsFixed(2)} / ចំណែក',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '\$${subtotalUSD.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Color(0xFFE53935),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  _CartQtyBtn(
                                    icon: qty == 1
                                        ? Icons.delete_outline
                                        : Icons.remove,
                                    color: qty == 1
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                    onTap: () => _changeQty(index, -1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    child: Text(
                                      '$qty',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  _CartQtyBtn(
                                    icon: Icons.add,
                                    color: const Color(0xFFE53935),
                                    onTap: () => _changeQty(index, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                _OrderSummary(
                  totalQty: _totalQty,
                  totalUSD: _totalUSD,
                  totalKHR: _totalKHR,
                  isLoading: _isPlacingOrder,
                  onPlaceOrder: _placeOrder,
                ),
              ],
            ),
    );
  }
}

// ─── Empty cart ──────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final VoidCallback onGoToProducts;
  const _EmptyCart({required this.onGoToProducts});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: const Text(
              'កន្ត្រកទំនិញ',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          Icon(Icons.shopping_basket_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('កន្ត្រកទំនិញទទេ',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            'សូមជ្រើសរើសផលិតផលដែលអ្នកចូលចិត្ត',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onGoToProducts,
            icon: const Icon(Icons.shopping_bag_outlined,
                color: Colors.white),
            label: const Text(
              'មើលផលិតផល',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Note field ───────────────────────────────────────────────────────
class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  size: 18, color: Color(0xFFE53935)),
              SizedBox(width: 6),
              Text(
                'កំណត់ចំណាំ / ការណែនាំ',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'ឧ. ផ្ញើដល់ម៉ោង 5pm, ហៅទូរស័ព្ទ...',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE53935))),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order summary + checkout bar ────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final int totalQty;
  final double totalUSD;
  final int totalKHR;
  final bool isLoading;
  final VoidCallback onPlaceOrder;

  const _OrderSummary({
    required this.totalQty,
    required this.totalUSD,
    required this.totalKHR,
    required this.isLoading,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ចំនួនទំនិញ',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14)),
              Text('$totalQty ចំណែក',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('តម្លៃសរុប',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${totalUSD.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  Text(
                    '${_fmtKHR(totalKHR)} រៀល',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                elevation: 3,
                shadowColor: const Color(0xFFE53935).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: isLoading ? null : onPlaceOrder,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'ដាក់កាទិញ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
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

// ─── Cart qty button ──────────────────────────────────────────────────
class _CartQtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CartQtyBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
