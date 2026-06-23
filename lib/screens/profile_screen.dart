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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile?['name'] ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userProfile?['email'] ?? 'Please wait...',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isAdmin) ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
              icon: const Icon(Icons.category),
              label: const Text(
                'Manage Categories',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showDeletedProducts,
              icon: const Icon(Icons.restore_from_trash),
              label: const Text(
                'Deleted Products',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('My Orders', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline),
            label: const Text('About Us', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
