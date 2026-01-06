import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class AgentLinesScreen extends StatefulWidget {
  const AgentLinesScreen({super.key});

  @override
  State<AgentLinesScreen> createState() => _AgentLinesScreenState();
}

class _AgentLinesScreenState extends State<AgentLinesScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _lines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLines();
  }

  Future<void> _fetchLines() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final lines = await _apiService.getAllLines(token);
        setState(() {
          _lines = lines;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('my_lines'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lines.isEmpty
              ? Center(
                  child: Text(AppLocalizations.of(context).translate('no_lines_found')),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.route, color: Colors.blue),
                        title: Text(line['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${line['area']} • ${line['customer_count']} Customers'),
                        trailing: line['is_locked'] ? const Icon(Icons.lock, color: Colors.red) : const Icon(Icons.chevron_right),
                        onTap: line['is_locked'] 
                          ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Line is locked')))
                          : () => _viewLineCustomers(line),
                      ),
                    );
                  },
                ),
    );
  }

  void _viewLineCustomers(dynamic line) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _LineCustomersSheet(line: line, apiService: _apiService, storage: _storage),
    );
  }
}

class _LineCustomersSheet extends StatefulWidget {
  final dynamic line;
  final ApiService apiService;
  final FlutterSecureStorage storage;

  const _LineCustomersSheet({required this.line, required this.apiService, required this.storage});

  @override
  State<_LineCustomersSheet> createState() => _LineCustomersSheetState();
}

class _LineCustomersSheetState extends State<_LineCustomersSheet> {
  List<dynamic> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final token = await widget.storage.read(key: 'jwt_token');
    if (token != null) {
      final custs = await widget.apiService.getLineCustomers(widget.line['id'], token);
      setState(() {
        _customers = custs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.line['name'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_customers.isEmpty)
            const Center(child: Text('No customers in this line'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final cust = _customers[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text((index + 1).toString())),
                    title: Text(cust['name']),
                    subtitle: Text(cust['area']),
                    trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onTap: () {
                      Navigator.pop(context); // Close sheet
                      Navigator.pushNamed(context, '/collection_entry', arguments: cust);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
