import 'package:flutter/material.dart';
import '../api_service.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() async {
    final orders = await ApiService.getOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        centerTitle: true,
      ),
      body: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final items = order['items'] as List<dynamic>? ?? [];
                    final dateStr = order['created_at'] != null
                        ? DateTime.parse(order['created_at'].toString()).toLocal().toString().substring(0, 16)
                        : '';
                    final userName = order['user_name'] ?? (order['user'] != null ? order['user']['name'] : null);
                    final status = order['status'] ?? 'requested';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          order['order_number'] ?? 'Unknown Order',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (userName != null) Text('User: $userName', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('Status: ${status.toString().toUpperCase()}', style: const TextStyle(color: Colors.blueGrey)),
                            Text('Date: $dateStr'),
                            Text('Items: ${items.length}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${order['total_price']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (order['payment_method'] ?? '').toString().toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(order: order),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
