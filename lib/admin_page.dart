import 'package:flutter/material.dart';
import 'services/api_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isLoading = true;
  int _tabIndex = 0; // 0 users, 1 products, 2 orders

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];

  final _nameCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _khrCtl = TextEditingController();
  final _imageCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    setState(() => _isLoading = true);
    final users = await ApiService.adminGetUsers();
    final products = await ApiService.adminGetProducts();
    final orders = await ApiService.adminGetOrders();
    if (!mounted) return;
    setState(() {
      _users = users;
      _products = products;
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _openAddProductDialog() async {
    _nameCtl.text = '';
    _priceCtl.text = '';
    _khrCtl.text = '';
    _imageCtl.text = '';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _priceCtl, decoration: const InputDecoration(labelText: 'Price USD'), keyboardType: TextInputType.number),
              TextField(controller: _khrCtl, decoration: const InputDecoration(labelText: 'Price KHR'), keyboardType: TextInputType.number),
              TextField(controller: _imageCtl, decoration: const InputDecoration(labelText: 'Image path')), 
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = _nameCtl.text.trim();
              final price = double.tryParse(_priceCtl.text.trim()) ?? -1.0;
              final khr = int.tryParse(_khrCtl.text.trim()) ?? -1;
              if (name.isEmpty || price < 0 || khr < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide valid product data')));
                return;
              }
              final ok = await ApiService.adminCreateProduct(
                name: name,
                price: price,
                khr: khr,
                image: _imageCtl.text.trim(),
              );
              Navigator.pop(context, ok);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true) {
      await _reloadAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added')));
    }
  }

  Future<void> _openEditProductDialog(Map<String, dynamic> product) async {
    _nameCtl.text = product['name']?.toString() ?? '';
    _priceCtl.text = (product['price']?.toString() ?? '');
    _khrCtl.text = (product['khr']?.toString() ?? '');
    _imageCtl.text = product['image']?.toString() ?? '';

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _priceCtl, decoration: const InputDecoration(labelText: 'Price USD'), keyboardType: TextInputType.number),
              TextField(controller: _khrCtl, decoration: const InputDecoration(labelText: 'Price KHR'), keyboardType: TextInputType.number),
              TextField(controller: _imageCtl, decoration: const InputDecoration(labelText: 'Image path')), 
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = _nameCtl.text.trim();
              final price = double.tryParse(_priceCtl.text.trim()) ?? -1.0;
              final khr = int.tryParse(_khrCtl.text.trim()) ?? -1;
              if (name.isEmpty || price < 0 || khr < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide valid product data')));
                return;
              }
              final ok = await ApiService.adminUpdateProduct(
                id: product['id'].toString(),
                name: name,
                price: price,
                khr: khr,
                image: _imageCtl.text.trim(),
              );
              Navigator.pop(context, ok);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      await _reloadAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiService.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        backgroundColor: const Color(0xFFD62828),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  children: [
                    _TabButton(label: 'Users', selected: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                    _TabButton(label: 'Products', selected: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                    _TabButton(label: 'Orders', selected: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
                  ],
                ),
                Expanded(
                  child: _tabIndex == 0
                      ? ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final u = _users[index];
                            return ListTile(
                              title: Text(u['fullName'] ?? u['email'] ?? 'unknown'),
                              subtitle: Text('${u['email']} — role ${u['role']}'),
                            );
                          },
                        )
                      : _tabIndex == 1
                          ? Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(onPressed: _openAddProductDialog, child: const Text('Add Product')),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: _products.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final p = _products[index];
                                      return ListTile(
                                        title: Text(p['name'] ?? ''),
                                        subtitle: Text('\$${p['price']} • ${p['khr']}KHR'),
                                        trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _openEditProductDialog(p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final ok = await ApiService.adminDeleteProduct(p['id'].toString());
                                          if (ok) {
                                            await _reloadAll();
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product removed')));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _orders.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final o = _orders[index];
                                final date = o['createdAt'] ?? '?';
                                return ListTile(
                                  title: Text('Order ${o['id'] ?? 'unknown'} | ${o['status']}'),
                                  subtitle: Text('User: ${o['email']} • total ${o['totalPrice']} USD'),
                                  trailing: Text(date.toString().split('T').first),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 45,
          color: selected ? const Color(0xFFE53935) : Colors.white,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
