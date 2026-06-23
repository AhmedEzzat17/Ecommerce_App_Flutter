import 'package:flutter/material.dart';
import '../api_service.dart';
import 'dashboard_tab.dart';
import 'products_tab.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    ApiService.getCart();
  }

  void _checkAdminStatus() async {
    bool admin = await ApiService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = admin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = _isAdmin
        ? [const DashboardTab(), const ProductsTab(), const ProfileScreen()]
        : [
            HomeTab(onCategoryTap: () {
              setState(() {
                _currentIndex = 1; // Switch to ProductsTab (index 1)
              });
            }),
            const ProductsTab(),
            const ProfileScreen(),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products App'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: ApiService.cartCountNotifier,
            builder: (context, count, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ).then((_) => ApiService.getCart()),
                ),
                if (count > 0)
                  Positioned(
                    right: 3,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: tabs.length > _currentIndex ? tabs[_currentIndex] : const SizedBox(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
