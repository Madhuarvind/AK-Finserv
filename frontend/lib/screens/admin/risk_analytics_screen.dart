import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class RiskAnalyticsScreen extends StatefulWidget {
  const RiskAnalyticsScreen({super.key});

  @override
  State<RiskAnalyticsScreen> createState() => _RiskAnalyticsScreenState();
}

class _RiskAnalyticsScreenState extends State<RiskAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  Map<String, dynamic>? _dashboard;
  bool _isLoading = true;
  bool _isTraining = false;
  
  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }
  
  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final data = await _apiService.getRiskDashboard(token);
      if (mounted) {
        setState(() {
          _dashboard = data;
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _trainModel() async {
    setState(() => _isTraining = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final result = await _apiService.trainRiskModel(token);
      if (mounted) {
        setState(() => _isTraining = false);
        
        if (result['msg']?.contains('success') ?? false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Model trained! Samples: ${result['samples']}, Accuracy: ${(result['accuracy'] * 100).toStringAsFixed(1)}%'),
              backgroundColor: Colors.green
            )
          );
          _fetchDashboard();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Training failed: ${result['msg']}'), backgroundColor: Colors.red)
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('AI Risk Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: _isTraining 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.model_training),
            onPressed: _isTraining ? null : _trainModel,
            tooltip: 'Train ML Model',
          )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchDashboard,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  if (_dashboard != null && _dashboard!['summary'] != null) ...[
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(
                          'Total At Risk',
                          '${_dashboard!['summary']['total_at_risk']}',
                          Icons.warning_amber_rounded,
                          Colors.orange
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard(
                          'High Risk',
                          '${_dashboard!['summary']['high_risk_count']}',
                          Icons.error_outline,
                          Colors.red
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(
                          'Medium Risk',
                          '${_dashboard!['summary']['medium_risk_count']}',
                          Icons.info_outline,
                          Colors.amber
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: Container()), // Spacer
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Risk Customers List
                  Text('At-Risk Customers', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  if (_dashboard == null || _dashboard!['customers'] == null || (_dashboard!['customers'] as List).isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 60, color: Colors.green[400]),
                            const SizedBox(height: 12),
                            Text('All customers are low risk!', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                            const SizedBox(height: 8),
                            Text('No high or medium risk predictions', style: TextStyle(color: Colors.green[600], fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...(_dashboard!['customers'] as List).map((customer) => _buildRiskCustomerCard(customer)).toList(),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildRiskCustomerCard(Map<String, dynamic> customer) {
    final riskLevel = customer['risk_level'] ?? 'low';
    final colors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.green,
    };
    final color = colors[riskLevel] ?? Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['customer_name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(customer['customer_number'] ?? 'No ID', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(customer['mobile'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  riskLevel.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(height: 4),
              Text('${customer['confidence']}% conf.', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
