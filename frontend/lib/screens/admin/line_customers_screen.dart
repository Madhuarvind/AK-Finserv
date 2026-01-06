import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/add_customer_dialog.dart';

class LineCustomersScreen extends StatefulWidget {
  final Map<String, dynamic> line;
  const LineCustomersScreen({super.key, required this.line});

  @override
  State<LineCustomersScreen> createState() => _LineCustomersScreenState();
}

class _LineCustomersScreenState extends State<LineCustomersScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _lineCustomers = [];
  List<dynamic> _allCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final lineCusts = await _apiService.getLineCustomers(widget.line['id'], token);
        final allCusts = await _apiService.getCustomers(token);
        
        setState(() {
          _lineCustomers = lineCusts;
          // Filter out customers already in the line
          final existingIds = _lineCustomers.map((lc) => lc['id']).toSet();
          _allCustomers = allCusts.where((c) => !existingIds.contains(c['id'])).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  Future<void> _addCustomer() async {
    String searchQuery = '';
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = _allCustomers.where((c) => 
            c['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            c['mobile_number'].contains(searchQuery)
          ).toList();

          return AlertDialog(
            title: Text(AppLocalizations.of(context).translate('add_customer')),
            content: SizedBox(
              width: double.maxFinite,
              height: 400, // Fixed height for core content stability
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).translate('search_users'),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) => setDialogState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AppLocalizations.of(context).translate('no_customers_found')),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await showDialog(
                                      context: context,
                                      builder: (context) => const AddCustomerDialog(),
                                    );
                                    if (result == true) {
                                      Navigator.pop(context);
                                      _fetchData();
                                    }
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: Text(AppLocalizations.of(context).translate('create_customer')),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final cust = filtered[index];
                              return ListTile(
                                dense: true,
                                title: Text(cust['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(cust['mobile'] ?? cust['mobile_number'] ?? 'No Mobile'),
                                trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                onTap: () async {
                                  try {
                                    final token = await _storage.read(key: 'jwt_token');
                                    if (token != null) {
                                      await _apiService.addCustomerToLine(widget.line['id'], cust['id'], token);
                                      if (mounted) {
                                        Navigator.pop(context);
                                        _fetchData();
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error adding customer: $e')),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).translate('cancel')),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _updateOrder() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final order = _lineCustomers.map<int>((c) => c['id'] as int).toList();
        await _apiService.reorderLineCustomers(widget.line['id'], order, token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('reorder_success'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.line['name'],
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Text(
              AppLocalizations.of(context).translate('manage_customers'),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lineCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).translate('no_customers_found'),
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addCustomer,
                        child: Text(AppLocalizations.of(context).translate('add_customer')),
                      ),
                    ],
                  ),
                )
              : ReorderableListView(
                  padding: const EdgeInsets.all(16),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = _lineCustomers.removeAt(oldIndex);
                      _lineCustomers.insert(newIndex, item);
                    });
                    _updateOrder();
                  },
                  children: _lineCustomers.map((cust) {
                    return Card(
                      key: ValueKey(cust['id']),
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text((_lineCustomers.indexOf(cust) + 1).toString()),
                        ),
                        title: Text(cust['name']),
                        subtitle: Text('${cust['mobile']} • ${cust['area']}'),
                        trailing: const Icon(Icons.drag_handle),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
