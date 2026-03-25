import 'dart:async';

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'demo_gateway_page.dart';
import 'product_page.dart';

// Formats Khmer Riel values with thousand separators for UI display.
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
  // Available delivery choices shown before checkout.
  static const List<_DeliveryOption> _deliveryOptions = [
    _DeliveryOption(
      value: 'vireak_buntham',
      title: 'វីរៈប៊ុននថាំ',
      subtitle: 'Vireak Buntham Express Delivery',
      ratePerBoxKHR: 5500,
      icon: Icons.local_shipping_outlined,
    ),
    _DeliveryOption(
      value: 'kapitol',
      title: 'កាពីតូល',
      subtitle: 'Kapitol Express Delivery',
      ratePerBoxKHR: 5500,
      icon: Icons.local_shipping_outlined,
    ),
    _DeliveryOption(
      value: 'pickup',
      title: 'មកយកដោយខ្លួនឯង',
      subtitle: 'Self Pickup',
      ratePerBoxKHR: 0,
      icon: Icons.storefront_outlined,
    ),
  ];

  static const List<_PaymentOption> _paymentOptions = [
    _PaymentOption(
      value: 'payment_gateway',
      title: 'Online Payment Gateway',
      subtitle: 'Pay online with card or connected gateway',
      icon: Icons.credit_card_outlined,
      accentColor: Color(0xFF0E4DA4),
      requiresAction: true,
    ),
    _PaymentOption(
      value: 'pay_on_delivery',
      title: 'Pay on Delivery',
      subtitle: 'Pay when the order arrives',
      icon: Icons.local_shipping_outlined,
      accentColor: Color(0xFF1D7E45),
      requiresAction: false,
    ),
    _PaymentOption(
      value: 'cash_on_delivery',
      title: 'Cash on Delivery',
      subtitle: 'Pay cash when the order arrives',
      icon: Icons.payments_outlined,
      accentColor: Color(0xFFE53935),
      requiresAction: false,
    ),
  ];

  bool _isPlacingOrder = false;
  final TextEditingController _noteController = TextEditingController();
  String _selectedDeliveryType = _deliveryOptions.first.value;

  List<Map<String, dynamic>> get cart => widget.cart;

  double get _totalUSD => cart.fold(
    0.0,
    // ignore: avoid_types_as_parameter_names
    (sum, item) => sum + item['product'].priceUSD * item['qty'],
  );
  int get _totalKHR => cart.fold(
    0,
     // ignore: avoid_types_as_parameter_names
    (sum, item) => sum + (item['product'].priceKHR * item['qty'] as int),
  );
  int get _totalQty =>
   // ignore: avoid_types_as_parameter_names
      cart.fold<int>(0, (sum, item) => sum + ((item['qty'] as int?) ?? 0));
  int get _productCount => cart.length;
  int _capacityOf(Product product) =>
      product.deliveryBoxCapacity <= 0 ? 1 : product.deliveryBoxCapacity;

  int _factorOf(Product product) =>
      product.deliveryFactor <= 0 ? 1 : product.deliveryFactor;

  String _packingGroupLabel(String packingGroup) {
    switch (packingGroup) {
      case 'standard_mix':
        return 'Standard Mix';
      case 'mayo_case':
        return 'Mayo Case';
      case 'sauce_case':
        return 'Sauce Case';
      default:
        return packingGroup;
    }
  }

  List<Map<String, dynamic>> get _packingBreakdown {
    if (_selectedDeliveryType == 'pickup') return const [];

    final grouped = <String, Map<String, dynamic>>{};
    final fixed = <String, Map<String, dynamic>>{};

    for (final item in cart) {
      final product = item['product'] as Product;
      final qty = (item['qty'] as int?) ?? 0;
      if (qty <= 0) continue;

      if (product.deliveryRule == 'fixed_box') {
        final key = product.cartKey;
        final boxCount = qty * _factorOf(product);
        final existing = fixed[key];
        fixed[key] = {
          'packingGroup': product.packingGroup,
          'label': '${product.name} (${product.productType})',
          'deliveryRule': product.deliveryRule,
          'boxCount': (existing?['boxCount'] as int? ?? 0) + boxCount,
          'points': (existing?['points'] as int? ?? 0) + boxCount,
          'boxCapacity': 1,
        };
        continue;
      }

      final key = product.packingGroup;
      final existing = grouped[key];
      grouped[key] = {
        'packingGroup': product.packingGroup,
        'label': _packingGroupLabel(product.packingGroup),
        'deliveryRule': product.deliveryRule,
        'points':
            (existing?['points'] as int? ?? 0) + (qty * _factorOf(product)),
        'boxCapacity': existing?['boxCapacity'] ?? _capacityOf(product),
      };
    }

    final results = grouped.values.map((group) {
      final points = group['points'] as int? ?? 0;
      final boxCapacity = group['boxCapacity'] as int? ?? 1;
      return {
        ...group,
        'boxCount': ((points + boxCapacity - 1) ~/ boxCapacity),
      };
    }).toList();

    results.addAll(fixed.values);
    return results;
  }

  int get _boxCount => _selectedDeliveryType == 'pickup'
      ? 0
      : _packingBreakdown.fold<int>(
          0,
          (totalBoxes, group) =>
              totalBoxes + ((group['boxCount'] as int?) ?? 0),
        );
  int get _deliveryFeeKHR => _boxCount * _selectedDeliveryOption.ratePerBoxKHR;
  int get _grandTotalKHR => _totalKHR + _deliveryFeeKHR;

  // Resolves the selected delivery value into a full option model.
  _DeliveryOption get _selectedDeliveryOption => _deliveryOptions.firstWhere(
    (option) => option.value == _selectedDeliveryType,
    orElse: () => _deliveryOptions.first,
  );

  Future<DemoGatewayResult?> _openDemoGateway(_PaymentOption payment) {
    return Navigator.of(context).push<DemoGatewayResult>(
      MaterialPageRoute(
        builder: (_) => DemoGatewayPage(
          paymentLabel: payment.title,
          totalKHR: _grandTotalKHR,
          totalUSD: _totalUSD,
          totalProducts: _productCount,
          deliveryLabel: _selectedDeliveryOption.title,
        ),
      ),
    );
  }

  Future<_PaymentOption?> _showPaymentDialog() async {
    String selectedPayment = _paymentOptions.first.value;

    return showDialog<_PaymentOption>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) {
          final payment = _paymentOptions.firstWhere(
            (option) => option.value == selectedPayment,
            orElse: () => _paymentOptions.first,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'បង់ប្រាក់ការកម្មង់',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'សរុបចំនួនប្រាក់ត្រូវបង់',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmtKHR(_grandTotalKHR)} រៀល',
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            '\$${_totalUSD.toStringAsFixed(2)}  ·  $_productCount products',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Payment Type',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ..._paymentOptions.map((option) {
                      final isSelected = option.value == selectedPayment;
                      return GestureDetector(
                        onTap: () =>
                            setDialog(() => selectedPayment = option.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                            //ignore: deprecated_member_use
                                ? option.accentColor.withOpacity(0.09)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? option.accentColor
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: option.accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  option.icon,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.subtitle,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? option.accentColor
                                    : Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    if (payment.requiresAction)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              color: payment.accentColor,
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              payment.title,
                              style: TextStyle(
                                color: payment.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_fmtKHR(_grandTotalKHR)} រៀល',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Gateway amount is prepared. Connect your provider API or checkout URL next.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: Color(0xFFE53935),
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Customer will pay when receiving the order.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount to collect: ${_fmtKHR(_grandTotalKHR)} រៀល',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('បោះបង់'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  payment.requiresAction
                      ? 'បន្តទៅ Gateway'
                      : 'បញ្ជាក់ការកម្មង់',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Updates cart item quantity and removes the item when it reaches zero.
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

  // Shows payment type and QR details, then saves the order.
  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;

    if (!ApiService.isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login before confirming the order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final payment = await _showPaymentDialog();
    if (payment == null) return;

    if (payment.requiresAction) {
      final gatewayResult = await _openDemoGateway(payment);
      if (gatewayResult == null) return;

      if (!gatewayResult.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demo gateway payment failed. Order was not created.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    setState(() => _isPlacingOrder = true);
    try {
      final orderItems = cart
          .map((item) => {
                'name': (item['product'] as Product).name,
                'priceUSD': (item['product'] as Product).priceUSD,
                'priceKHR': (item['product'] as Product).priceKHR,
                'qty': item['qty'],
              })
          .toList();

      await ApiService.createOrder(orderItems, _totalUSD, _grandTotalKHR);

      await Future.delayed(const Duration(milliseconds: 400));
      cart.clear();
      _noteController.clear();
      _selectedDeliveryType = _deliveryOptions.first.value;
      widget.onCartUpdated();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ បានបញ្ជាទិញដោយជោគជ័យ! Payment: ${payment.title}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onGoToOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
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
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_totalQty ទំនិញ  ·  \$${_totalUSD.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                title: const Text('លុបទំនិញទាំងអស់?'),
                                content: const Text(
                                  'តើអ្នកពិតជាចង់លុបទំនិញទាំងអស់ចេញពីកន្ត្រកមែនទេ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('បោះបង់'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE53935),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      setState(() => cart.clear());
                                      widget.onCartUpdated();
                                    },
                                    child: const Text(
                                      'លុប',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'លុបចោលការកម្មង់',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: cart.length + 2,
                    itemBuilder: (context, index) {
                      if (index == cart.length) {
                        return _DeliveryTypeSelector(
                          options: _deliveryOptions,
                          selectedValue: _selectedDeliveryType,
                          onChanged: (value) {
                            setState(() => _selectedDeliveryType = value);
                          },
                        );
                      }
                      if (index == cart.length + 1) {
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
                              //ignore: deprecated_member_use
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
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  product.img,
                                  fit: BoxFit.contain,
                                  //ignore: unnecessary_underscores
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${product.priceUSD.toStringAsFixed(2)} / ${product.productType.trim().isEmpty ? 'ចំណែក' : product.productType}',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '\$${subtotalUSD.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFFE53935),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
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
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                  productCount: _productCount,
                  totalUSD: _totalUSD,
                  totalKHR: _grandTotalKHR,
                  boxCount: _boxCount,
                  packingBreakdown: _packingBreakdown,
                  deliveryFeeKHR: _deliveryFeeKHR,
                  deliveryLabel: _selectedDeliveryOption.title,
                  isLoading: _isPlacingOrder,
                  onPlaceOrder: _placeOrder,
                ),
              ],
            ),
    );
  }
}

// Lightweight model for each selectable delivery method in the cart.
class _DeliveryOption {
  final String value;
  final String title;
  final String subtitle;
  final int ratePerBoxKHR;
  final IconData icon;

  const _DeliveryOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.ratePerBoxKHR,
    required this.icon,
  });
}

class _PaymentOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool requiresAction;

  const _PaymentOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.requiresAction,
  });
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: const Text(
              'កន្ត្រកទំនិញ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'កន្ត្រកទំនិញទទេ',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'សូមជ្រើសរើសផលិតផលដែលអ្នកចូលចិត្ត',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onGoToProducts,
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            label: const Text(
              'មើលផលិតផល',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Note field ───────────────────────────────────────────────────────
// Collects optional delivery notes from the customer before checkout.
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
            //ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: Color(0xFFE53935),
              ),
              SizedBox(width: 6),
              Text(
                'កំណត់ចំណាំ / ការណែនាំ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'ឧ. ផ្ញើដល់ម៉ោង 5pm, ហៅទូរស័ព្ទ...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE53935)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lets the customer choose how the order should be delivered.
class _DeliveryTypeSelector extends StatelessWidget {
  final List<_DeliveryOption> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _DeliveryTypeSelector({
    required this.options,
    required this.selectedValue,

    // Shows totals and triggers the final place-order action.
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            //ignore:deprecated_member_use
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: Color(0xFFE53935),
              ),
              SizedBox(width: 6),
              Text(
                'ជ្រើសរើសប្រភេទដឹកជញ្ជូន',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((option) {
            final isSelected = option.value == selectedValue;
            return GestureDetector(
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                  //ignore: deprecated_member_use
                      ? const Color(0xFFE53935).withOpacity(0.08)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE53935)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        option.icon,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFE53935),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.subtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.ratePerBoxKHR == 0
                                ? 'Free'
                                : '${_fmtKHR(option.ratePerBoxKHR)} រៀល / box',
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Order summary + checkout bar ────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final int productCount;
  final double totalUSD;
  final int totalKHR;
  final int boxCount;
  final List<Map<String, dynamic>> packingBreakdown;
  final int deliveryFeeKHR;
  final String deliveryLabel;
  final bool isLoading;
  final VoidCallback onPlaceOrder;

  const _OrderSummary({
    required this.productCount,
    required this.totalUSD,
    required this.totalKHR,
    required this.boxCount,
    required this.packingBreakdown,
    required this.deliveryFeeKHR,
    required this.deliveryLabel,
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
            //ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ចំនួនទំនិញ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              Text(
                '$productCount មុខទំនិញ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ដឹកជញ្ជូន',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    deliveryLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    deliveryFeeKHR == 0
                        ? 'Free'
                        : '$boxCount box x ${_fmtKHR(deliveryFeeKHR ~/ boxCount)} = ${_fmtKHR(deliveryFeeKHR)} រៀល',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  if (boxCount > 0)
                    Text(
                      '$boxCount total packing boxes',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  if (packingBreakdown.isNotEmpty)
                    ...packingBreakdown.map(
                      (group) => Text(
                        '${group['label']}: ${group['boxCount']} box',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'តម្លៃសរុប',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${totalUSD.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    '${_fmtKHR(totalKHR)} រៀល',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
                //ignore: deprecated_member_use
                shadowColor: const Color(0xFFE53935).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isLoading ? null : onPlaceOrder,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'ដាក់កាទិញ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

// ─── Cart qty button ──────────────────────────────────────────────────
// Small reusable quantity button used for increasing or decreasing items.
class _CartQtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CartQtyBtn({
    required this.icon,
    required this.color,
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
          //ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
