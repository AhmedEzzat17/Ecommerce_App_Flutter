import 'package:flutter/material.dart';
import '../api_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);
    // const CartScreen({super.key});

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
    if (quantity < 1) {
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
                
                final images = product['images'] as List<dynamic>? ?? [];
                final displayUrl = (images.isNotEmpty && images[0] is Map) ? images[0]['image_path'] : (images.isNotEmpty ? images[0] : null);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedItemIds.contains(item['id']),
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: displayUrl != null
                              ? Image.network(displayUrl.toString(), width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.inventory_2, color: Colors.grey)))
                              : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.inventory_2, color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['title'] ?? 'Unknown Product', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('\$${item['price'] ?? product['price']}', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _removeItem(item['id']),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: item['quantity'] > 1 ? () => _updateQuantity(item['id'], item['quantity'] - 1) : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: item['quantity'] > 1 ? Colors.grey.shade200 : Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Icon(Icons.remove, size: 16, color: item['quantity'] > 1 ? Colors.black87 : Colors.grey.shade400),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text('${item['quantity']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                                InkWell(
                                  onTap: () => _updateQuantity(item['id'], item['quantity'] + 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                              ],
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