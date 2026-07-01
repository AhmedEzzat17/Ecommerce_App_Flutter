import 'package:flutter/material.dart';
import '../api_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? _dashboardStats;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  void _fetchDashboard() async {
    final stats = await ApiService.getDashboard();
    if (mounted) setState(() => _dashboardStats = stats);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w400,
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
    final stats =
        _dashboardStats ??
        {
          'total_products': 0,
          'active_products': 0,
          'deleted_products': 0,
          'percentage': 0,
        };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(thickness: 1, height: 16),
          const SizedBox(height: 32),

          Row(
            children: [
              _buildStatCard(
                'Total Products',
                '${stats['total_products']}',
                Icons.inventory_2,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active',
                '${stats['active_products']}',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildStatCard(
                'Deleted',
                '${stats['deleted_products']}',
                Icons.delete_outline,
                Colors.red,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Percentage',
                '${stats['percentage']}%',
                Icons.data_usage,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
