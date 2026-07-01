import 'package:flutter/material.dart';
import '../api_service.dart';
import 'login_screen.dart';
import 'categories_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchProfile();
  }

  void _checkAdminStatus() async {
    bool admin = await ApiService.isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  void _fetchProfile() async {
    final profile = await ApiService.getProfile();
    if (mounted) setState(() => _userProfile = profile);
  }

  void _showDeletedProducts() async {
    // فتح الـ Dialog مباشرة واستدعاء الداتا جواه لتبسيط المنطق
    final deletedProducts = await ApiService.getDeletedProducts();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Deleted Products'),
          content: SizedBox(
            width: double.maxFinite,
            child: deletedProducts.isEmpty
                ? const Text('No deleted products found.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: deletedProducts.length,
                    itemBuilder: (context, index) {
                      final product = deletedProducts[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        title: Text(product['title'] ?? 'No Title'),
                        subtitle: Text('Price: \$${product['price']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () async {
                            if (await ApiService.restoreProduct(
                              product['id'],
                            )) {
                              setDialogState(
                                () => deletedProducts.removeAt(index),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Product restored successfully',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Us'),
        content: const Text(
          'This application is a simple\n e-commerce app built with Flutter and powered by a Laravel REST API.\n',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildMenuButton(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    bool hideArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (color ?? Theme.of(context).colorScheme.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.black87,
                  ),
                ),
              ),
              if (!hideArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withRed(0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  _userProfile?['name'] ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?['email'] ?? 'Please wait...',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Account Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_isAdmin) ...[
            _buildMenuButton(
              'Manage Categories',
              Icons.category_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
            _buildMenuButton(
              'Deleted Products',
              Icons.restore_from_trash_outlined,
              _showDeletedProducts,
            ),
          ],
          _buildMenuButton(
            'All Orders',
            Icons.receipt_long_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          _buildMenuButton('About Us', Icons.info_outline, _showAbout),
          const SizedBox(height: 16),
          _buildMenuButton(
            'Logout',
            Icons.logout,
            _logout,
            color: Colors.red,
            hideArrow: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
