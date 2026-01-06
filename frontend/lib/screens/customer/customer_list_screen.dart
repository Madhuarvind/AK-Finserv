import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/theme.dart';
import '../../services/local_db_service.dart';
import '../../services/api_service.dart';
import 'add_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _localDb = LocalDbService();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _localDb.getAllLocalCustomers();
    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  Future<void> _syncCustomers() async {
    setState(() => _isSyncing = true);
    
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No auth token found'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Get pending customers from local DB
      final pendingCustomers = await _localDb.getPendingCustomers();
      
      print('=== FRONTEND SYNC DEBUG ===');
      print('Pending customers count: ${pendingCustomers.length}');
      print('Pending customers data: $pendingCustomers');
      
      if (pendingCustomers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data is already synced!'), backgroundColor: Colors.green),
          );
        }
        return;
      }

      print('Calling sync API...');
      
      // Call sync API
      final result = await _apiService.syncCustomers(pendingCustomers, token);
      
      print('Sync API result: $result');
      
      if (result != null && result['synced'] != null && result['synced'].isNotEmpty) {
        // Update sync status for each customer
        final synced = result['synced'] as Map<String, dynamic>;
        
        for (var entry in synced.entries) {
          final localId = int.tryParse(entry.key);
          final syncData = entry.value as Map<String, dynamic>;
          final status = syncData['status'];
          
          if (localId != null && (status == 'created' || status == 'duplicate')) {
            await _localDb.updateCustomerSyncStatus(
              localId,
              syncData['server_id'],
              syncData['customer_id'],
            );
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced ${synced.length} customer(s) successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCustomers(); // Reload to show updated status
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sync failed. Please try again.'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      print('Sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('My Customers', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: _isSyncing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : Icon(Icons.sync, color: AppTheme.primaryColor),
            onPressed: _isSyncing ? null : _syncCustomers,
            tooltip: 'Sync Now',
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _customers.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                final isSynced = customer['is_synced'] == 1;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSynced ? Colors.green[100] : Colors.orange[100],
                      child: Icon(
                        Icons.person,
                        color: isSynced ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(customer['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "${customer['area']} • ${customer['mobile_number']}\n${isSynced ? customer['customer_id'] : 'Pending Sync'}",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: isSynced 
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : const Icon(Icons.cloud_upload, color: Colors.orange, size: 20),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
          if (result == true) {
            _loadCustomers();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Tap + to add a new customer', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
