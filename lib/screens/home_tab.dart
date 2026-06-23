import 'package:flutter/material.dart';
import '../api_service.dart';
import 'product_details.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onCategoryTap;

  const HomeTab({Key? key, this.onCategoryTap}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? _userProfile;
  List<dynamic> _categories = [];
  List<dynamic> _latestProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await ApiService.getProfile();
    final categories = await ApiService.getCategories();
    final products = await ApiService.getProducts();

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _categories = categories;
        _latestProducts = products.take(6).toList();
      });
    }
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

  IconData _getCategoryIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('elect') || name.contains('tech') || name.contains('phone')) return Icons.devices;
    if (name.contains('cloth') || name.contains('wear') || name.contains('fashion') || name.contains('shoes')) return Icons.checkroom;
    if (name.contains('home') || name.contains('furnit') || name.contains('appl') || name.contains('kitchen')) return Icons.chair;
    if (name.contains('book') || name.contains('read') || name.contains('novel')) return Icons.book;
    if (name.contains('food') || name.contains('grocer') || name.contains('eat') || name.contains('snack')) return Icons.local_grocery_store;
    if (name.contains('sport') || name.contains('fit') || name.contains('gym')) return Icons.sports_soccer;
    if (name.contains('toy') || name.contains('game') || name.contains('kid')) return Icons.smart_toy;
    return Icons.category;
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.inventory_2, size: 36, color: Colors.grey)),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, dynamic displayUrl) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
          ).then((_) => _loadData()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: displayUrl != null
                      ? Image.network(
                          displayUrl.toString(),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['title'] ?? 'No Title',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${product['price']}',
                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product['category']?['name'] ?? 'Uncategorized',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _addToCart(product['id']),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = _userProfile?['name'] ?? 'Guest';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withRed(0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(
                      'Explore and search our latest products to find exactly what you need.',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Shop by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final name = category['name'] ?? 'General';
                    final icon = _getCategoryIcon(name);
                    return GestureDetector(
                      onTap: widget.onCategoryTap,
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 24, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 175,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _latestProducts.length,
                  itemBuilder: (context, index) {
                    final product = _latestProducts[index];
                    final images = product['images'] as List<dynamic>? ?? [];
                    final displayUrl = (images.isNotEmpty && images[0] is Map)
                        ? images[0]['image_path']
                        : (images.isNotEmpty ? images[0] : null);
                    return _buildProductCard(product, displayUrl);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
