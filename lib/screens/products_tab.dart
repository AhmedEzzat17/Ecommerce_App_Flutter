import 'package:flutter/material.dart';
import 'dart:async';
import '../api_service.dart';
import 'add_edit_product_screen.dart';
import 'product_details.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  _ProductsTabState createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  List<dynamic> _products = [];
  String _searchQuery = '';
  String _currentSort = '';
  Timer? _debounce;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchProducts();
  }

  void _checkAdminStatus() async {
    bool admin = await ApiService.isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  void _fetchProducts() async {
    final products = await ApiService.getProducts(search: _searchQuery, sort: _currentSort);
    if (mounted) setState(() => _products = products);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _fetchProducts();
    });
  }

  void _addToCart(int productId) async {
    final success = await ApiService.addToCart(productId, 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Product added to cart' : 'Failed to add to cart'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: const TextStyle(fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.primary),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.sort, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      const Text('Sort by:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSortChip('Latest Added', ''),
                              const SizedBox(width: 8),
                              _buildSortChip('Lowest Price', 'price'),
                              const SizedBox(width: 8),
                              _buildSortChip('Release Date', 'date'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _fetchProducts(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final images = product['images'] as List<dynamic>? ?? [];
                    final displayUrl = (images.isNotEmpty && images[0] is Map) ? images[0]['image_path'] : (images.isNotEmpty ? images[0] : null);
                    return _buildProductCard(product, displayUrl);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())).then((_) => _fetchProducts()),
              mini: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 24),
            )
          : null,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, dynamic displayUrl) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
        ).then((value) {
          if (value == true) {
            _fetchProducts();
          }
        }),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: displayUrl != null
                    ? Image.network(displayUrl.toString(), width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholderImage())
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['title'] ?? 'No Title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('\$${product['price']}', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(product['category']?['name'] ?? 'Uncategorized', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (_isAdmin) ...[
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
                      ).then((_) => _fetchProducts()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.green),
                    onPressed: () => _addToCart(product['id']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.inventory_2, size: 24, color: Colors.grey));

  Widget _buildSortChip(String label, String sortValue) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: _currentSort == sortValue,
      onSelected: (selected) { if (selected) { setState(() => _currentSort = sortValue); _fetchProducts(); } },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -4),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}