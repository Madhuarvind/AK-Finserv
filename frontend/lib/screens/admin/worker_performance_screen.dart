import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class WorkerPerformanceScreen extends StatefulWidget {
  const WorkerPerformanceScreen({super.key});

  @override
  State<WorkerPerformanceScreen> createState() => _WorkerPerformanceScreenState();
}

class _WorkerPerformanceScreenState extends State<WorkerPerformanceScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  List<dynamic> _analytics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final data = await _apiService.getWorkerPerformanceAnalytics(token);
      if (mounted) {
        setState(() {
          _analytics = data;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Worker Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _analytics.length,
                itemBuilder: (context, index) {
                  final worker = _analytics[index];
                  return _buildWorkerPerformanceCard(worker);
                },
              ),
            ),
    );
  }

  Widget _buildWorkerPerformanceCard(Map<String, dynamic> worker) {
    final score = worker['performance_score'] ?? 0.0;
    final cluster = worker['cluster'] ?? 'N/A';
    final metrics = worker['metrics'] as Map<String, dynamic>;
    final flags = List<String>.from(worker['risk_flags'] ?? []);
    
    Color clusterColor = Colors.blue;
    if (worker['color'] == 'green') clusterColor = Colors.green;
    if (worker['color'] == 'orange') clusterColor = Colors.orange;
    if (worker['color'] == 'red') clusterColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(worker['name']?[0] ?? 'W', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker['name'] ?? 'Unknown', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: clusterColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cluster, style: TextStyle(color: clusterColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("$score", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: clusterColor)),
                    const Text("AI SCORE", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric("Total Coll.", "₹${metrics['total_collected']}"),
                    _buildMetric("Anomalies", metrics['anomaly_ratio']),
                    _buildMetric("Batch Evt.", "${metrics['batch_events']}"),
                  ],
                ),
                if (flags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gpp_maybe_outlined, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text("FRAUD / ANOMALY FLAGS", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...flags.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text("• $f", style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                        )),
                      ],
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
