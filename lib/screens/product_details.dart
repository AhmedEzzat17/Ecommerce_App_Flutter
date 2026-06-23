import 'package:flutter/material.dart';
import '../api_service.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetails({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _isAdding = false;
  int? _cartItemId;
  bool _isLoadingCart = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _checkCartStatus();
  }

  void _checkAdminStatus() async {
    bool admin = await ApiService.isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  void _checkCartStatus() async {
    final cart = await ApiService.getCart();
    if (cart != null && cart['items'] != null) {
      final items = cart['items'] as List<dynamic>;
      // البحث عن المنتج داخل السلة في سطر واحد مختصر ومفهوم
      final match = items.firstWhere((item) => item['product']?['id'] == widget.product['id'], orElse: () => null);
      _cartItemId = match?['id'];
    }
    if (mounted) setState(() => _isLoadingCart = false);
  }

  void _toggleCart() async {
    setState(() => _isAdding = true);
    bool success;

    if (_cartItemId != null) {
      success = await ApiService.removeFromCart(_cartItemId!);
      if (success) _cartItemId = null;
    } else {
      success = await ApiService.addToCart(widget.product['id'], 1);
      if (success) {
        // تحديث السلة سريعاً لجلب الـ ID الجديد
        final cart = await ApiService.getCart();
        final items = cart?['items'] as List<dynamic>? ?? [];
        final match = items.firstWhere((item) => item['product']?['id'] == widget.product['id'], orElse: () => null);
        _cartItemId = match?['id'];
      }
    }

    if (!mounted) return;
    setState(() => _isAdding = false);

    // إشعار بسيط بلون متناسق حسب الحالة (أخضر للإضافة، برتقالي للحذف، أحمر للفشل)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? (_cartItemId == null ? 'Removed successfully' : 'Added successfully') : 'Error occurred'),
      backgroundColor: success ? (_cartItemId == null ? Colors.orange : Colors.green) : Colors.red,
    ));
  }

  void _deleteProduct() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product', style: TextStyle(fontSize: 18)),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deleteProduct(widget.product['id']);
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete product'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product['images'] as List<dynamic>? ?? [];
    final displayUrl = (images.isNotEmpty && images[0] is Map) ? images[0]['image_path'] : (images.isNotEmpty ? images[0] : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(displayUrl.toString(), height: 200, width: double.infinity, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 80, color: Colors.grey)),
                ),
              ),
            const SizedBox(height: 20),
            Text(widget.product['title'] ?? 'No Title', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('\$${widget.product['price']}', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.category, 'Category', widget.product['category']?['name'] ?? 'None', Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.price_change, 'Budget Range', widget.product['Budget_Range'] ?? widget.product['priority'] ?? 'Unknown', Colors.red),
            if (widget.product['date'] != null && widget.product['date'].isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(Icons.calendar_today, 'Date', widget.product['date'], Colors.orange),
            ],
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            if (widget.product['description'] != null && widget.product['description'].isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.product['description'], style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
              const SizedBox(height: 16),
            ],
            if (widget.product['note'] != null && widget.product['note'].isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.product['note'], style: const TextStyle(fontSize: 13, color: Colors.black87))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: (_isLoadingCart || _isAdding) ? null : _toggleCart,
                icon: (_isLoadingCart || _isAdding)
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_cartItemId != null ? Icons.remove_shopping_cart : Icons.add_shopping_cart, size: 20),
                label: Text(
                  _isLoadingCart ? 'Checking cart...' : (_isAdding ? (_cartItemId != null ? 'Removing...' : 'Adding...') : (_cartItemId != null ? 'Remove from Cart' : 'Add to Cart')),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _cartItemId != null ? Colors.red : Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cartItemId != null ? Colors.red.shade50 : Theme.of(context).colorScheme.primary,
                  foregroundColor: _cartItemId != null ? Colors.red : Colors.white,
                  side: _cartItemId != null ? const BorderSide(color: Colors.red) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}