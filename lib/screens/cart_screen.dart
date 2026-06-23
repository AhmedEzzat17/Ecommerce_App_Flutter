import 'package:flutter/material.dart';
import '../api_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _cart;
  Set<int> _selectedItemIds = {};
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  void _fetchCart() async {
    final cart = await ApiService.getCart();
    if (cart != null && cart['items'] != null) {
      final items = cart['items'] as List<dynamic>;
      final currentIds = items.map((item) => item['id'] as int).toSet();
      
      if (!_isInit) {
        _selectedItemIds = currentIds;
        _isInit = true;
      } else {
        _selectedItemIds = _selectedItemIds.intersection(currentIds);
      }
    }
    if (mounted) {
      setState(() => _cart = cart);
    }
  }

  void _updateQuantity(int itemId, int quantity) async {
    if (quantity <= 0) {
      _removeItem(itemId);
      return;
    }
    await ApiService.updateCartItem(itemId, quantity);
    _fetchCart();
  }

  void _removeItem(int itemId) async {
    await ApiService.removeFromCart(itemId);
    _fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    if (_cart == null || (_cart!['items'] as List).isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(child: Text('Your cart is empty!', style: TextStyle(fontSize: 20))),
      );
    }

    final items = _cart!['items'] as List<dynamic>;

    // Calculate selected items info
    double selectedTotalPrice = 0.0;
    int selectedTotalItems = 0;
    List<dynamic> selectedItems = [];

    for (var item in items) {
      if (_selectedItemIds.contains(item['id'])) {
        final qty = item['quantity'] as int? ?? 0;
        final product = item['product'] ?? {};
        final price = double.tryParse((item['price'] ?? product['price'] ?? 0).toString()) ?? 0.0;
        selectedTotalPrice += price * qty;
        selectedTotalItems += qty;
        selectedItems.add(item);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          // Select All Checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: items.isNotEmpty && _selectedItemIds.length == items.length,
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedItemIds = items.map((e) => e['id'] as int).toSet();
                      } else {
                        _selectedItemIds.clear();
                      }
                    });
                  },
                ),
                const Text(
                  'Select All',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final product = item['product'] ?? {};
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: Checkbox(
                      value: _selectedItemIds.contains(item['id']),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedItemIds.add(item['id']);
                          } else {
                            _selectedItemIds.remove(item['id']);
                          }
                        });
                      },
                    ),
                    title: Text(product['title'] ?? 'Unknown Product'),
                    subtitle: Text('Price: \$${item['price'] ?? product['price']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateQuantity(item['id'], item['quantity'] - 1),
                        ),
                        Text('${item['quantity']}', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateQuantity(item['id'], item['quantity'] + 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(item['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Price', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${selectedTotalPrice.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Items: $selectedTotalItems',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: selectedItems.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    cartItems: selectedItems,
                                    totalPrice: selectedTotalPrice,
                                  ),
                                ),
                              ).then((value) {
                                _fetchCart();
                              });
                            },
                      icon: const Icon(Icons.payment_outlined),
                      label: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}