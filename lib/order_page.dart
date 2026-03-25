import 'package:flutter/material.dart';
import 'services/api_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!ApiService.isLoggedIn) {
      setState(() {
        _isLoading = false;
        _orders = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final orders = await ApiService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
      });
    } catch (error) {
      debugPrint('Load orders error: $error');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiService.isLoggedIn) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(
          child: Text(
            'Please sign in to view your orders.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD62828),
        title: const Text('Order History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Text(
                    'You have not placed any orders yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final items = (order['items'] as List<dynamic>?) ?? [];
                      final createdAt = order['createdAt'] ?? '';
                      final totalPrice = order['totalPrice'] ?? 0;
                      final totalKhr = order['totalKhr'] ?? 0;
                      final status = order['status'] ?? 'unknown';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order['id'] ?? index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Chip(
                                    label: Text(status.toString()),
                                    backgroundColor: status == 'pending'
                                        ? Colors.amber.shade100
                                        : status == 'completed'
                                            ? Colors.green.shade100
                                            : Colors.grey.shade100,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Placed at: $createdAt'),
                              const SizedBox(height: 8),
                              Text('${items.length} item(s)'),
                              const SizedBox(height: 8),
                              Text('Total: \$${totalPrice.toString()} • ${totalKhr.toString()}KHR'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
