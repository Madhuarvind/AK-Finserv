import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import 'edit_customer_screen.dart';
import 'add_loan_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  Map<String, dynamic>? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final data = await _apiService.getCustomerDetail(widget.customerId, token);
      if (mounted) {
        setState(() {
          _customer = data;
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
        title: Text('Customer Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
               if (_customer != null) {
                 final result = await Navigator.push(
                   context,
                   MaterialPageRoute(builder: (_) => EditCustomerScreen(customer: _customer!)),
                 );
                 if (result == true) _fetchDetails();
               }
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _customer == null 
          ? const Center(child: Text("Error loading profile"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   // Profile Header
                   Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(24),
                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
                     ),
                     child: Column(
                       children: [
                         const CircleAvatar(
                           radius: 40,
                           backgroundColor: AppTheme.backgroundColor,
                           child: Icon(Icons.person, size: 40, color: AppTheme.secondaryTextColor),
                         ),
                         const SizedBox(height: 16),
                         Text(
                           _customer!['name'],
                           style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                         ),
                         Text(
                           _customer!['customer_id'] ?? 'No ID',
                           style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 8),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             _buildStatusBadge(_customer!['status']),
                             const SizedBox(width: 8),
                             if (_customer!['is_locked'] == true)
                               const Chip(
                                 label: Text('🔒 LOCKED', style: TextStyle(fontSize: 10)),
                                 backgroundColor: Colors.red,
                                 labelStyle: TextStyle(color: Colors.white),
                               ),
                           ],
                         ),
                         const SizedBox(height: 8),
                         Text('Version: ${_customer!['version'] ?? 1}', 
                           style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),
                   
                   // Admin Status Change
                   if (_isAdmin()) ...[
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(16),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('Admin Controls', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                           const SizedBox(height: 10),
                           Row(
                             children: [
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: () => _showStatusChangeDialog(),
                                   icon: const Icon(Icons.sync_alt, size: 18),
                                   label: const Text('Change Status'),
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                 ),
                               ),
                               const SizedBox(width: 10),
                               Expanded(
                                 child: ElevatedButton.icon(
                                   onPressed: () => _toggleLock(),
                                   icon: Icon(_customer!['is_locked'] == true ? Icons.lock_open : Icons.lock, size: 18),
                                   label: Text(_customer!['is_locked'] == true ? 'Unlock' : 'Lock'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: _customer!['is_locked'] == true ? Colors.green : Colors.red
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 20),
                   ],
                   
                   // Info Cards
                   _buildInfoCard(Icons.phone, "Mobile", _customer!['mobile']),
                   _buildInfoCard(Icons.map, "Area", _customer!['area'] ?? "N/A"),
                   _buildInfoCard(Icons.home, "Address", _customer!['address'] ?? "N/A"),
                   _buildInfoCard(Icons.badge, "ID Proof", _customer!['id_proof_number'] ?? "N/A"),
                   if (_customer!['latitude'] != null && _customer!['longitude'] != null)
                     _buildInfoCard(Icons.location_on, "GPS Location", 
                       "Lat: ${_customer!['latitude'].toStringAsFixed(4)}, Long: ${_customer!['longitude'].toStringAsFixed(4)}"),

                   const SizedBox(height: 30),
                   
                   SizedBox(
                     width: double.infinity,
                     height: 55,
                     child: ElevatedButton.icon(
                       onPressed: () async {
                          final result = await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => AddLoanScreen(customerId: widget.customerId, customerName: _customer!['name']))
                          );
                          if (result == true) _fetchDetails();
                       },
                       icon: const Icon(Icons.monetization_on_outlined, color: Colors.white),
                       label: Text("Provide Loan", style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primaryColor,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                     ),
                   )
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  bool _isAdmin() {
    // Check if current user is admin - you can get this from storage or pass it down
    // For now, assuming we can check
    return true; // TODO: Implement proper role check
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'created': Colors.orange,
      'verified': Colors.blue,
      'active': Colors.green,
      'inactive': Colors.grey,
      'closed': Colors.red,
    };
    
    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: colors[status] ?? Colors.grey,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Future<void> _showStatusChangeDialog() async {
    final statuses = ['created', 'verified', 'active', 'inactive', 'closed'];
    final currentStatus = _customer!['status'];
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Customer Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((s) => RadioListTile<String>(
            title: Text(s.toUpperCase()),
            value: s,
            groupValue: currentStatus,
            onChanged: (val) => Navigator.pop(context, val),
          )).toList(),
        ),
      ),
    );
    
    if (selected != null && selected != currentStatus) {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        try {
          final response = await _apiService.updateCustomerStatus(widget.customerId, selected, token);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['msg'] ?? 'Status updated'), backgroundColor: Colors.green),
            );
            _fetchDetails();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _toggleLock() async {
    final isLocked = _customer!['is_locked'] == true;
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      try {
        await _apiService.toggleCustomerLock(widget.customerId, !isLocked, token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isLocked ? 'Customer unlocked' : 'Customer locked'), backgroundColor: Colors.green),
          );
          _fetchDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
