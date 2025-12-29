import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';
import '../utils/localizations.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CollectionEntryScreen extends StatefulWidget {
  const CollectionEntryScreen({super.key});

  @override
  State<CollectionEntryScreen> createState() => _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends State<CollectionEntryScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  int _currentStep = 0;
  List<dynamic> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  List<dynamic> _loans = [];
  Map<String, dynamic>? _selectedLoan;
  
  final TextEditingController _amountController = TextEditingController();
  String _paymentMode = 'cash';
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final result = await _apiService.getCustomers(token);
      setState(() {
        _customers = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLoans(int customerId) async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final result = await _apiService.getCustomerLoans(customerId, token);
      setState(() {
        _loans = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = pos);
  }

  Future<void> _submit() async {
    if (_selectedLoan == null || _amountController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    await _getCurrentLocation(); // Capture location at submission
    
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final result = await _apiService.submitCollection(
        loanId: _selectedLoan!['id'],
        amount: double.parse(_amountController.text),
        paymentMode: _paymentMode,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        token: token,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result.containsKey('msg') && result['msg'] == 'collection_submitted_successfully') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collection submitted successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['msg'] ?? 'Submission failed'), backgroundColor: Colors.red),
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
        title: Text(context.translate('collection'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading && _currentStep == 0
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0 && _selectedCustomer != null) {
                  _fetchLoans(_selectedCustomer!['id']);
                  setState(() => _currentStep++);
                } else if (_currentStep == 1 && _selectedLoan != null && _amountController.text.isNotEmpty) {
                  setState(() => _currentStep++);
                } else if (_currentStep == 2) {
                  _submit();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep--);
              },
              steps: [
                Step(
                  title: const Text('Customer'),
                  isActive: _currentStep >= 0,
                  content: _buildCustomerSelection(),
                ),
                Step(
                  title: const Text('Amount'),
                  isActive: _currentStep >= 1,
                  content: _buildAmountEntry(),
                ),
                Step(
                  title: const Text('Review'),
                  isActive: _currentStep >= 2,
                  content: _buildReview(),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomerSelection() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search customer...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
             // Basic local filter if needed
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _customers.length,
            itemBuilder: (context, index) {
              final c = _customers[index];
              final isSelected = _selectedCustomer?['id'] == c['id'];
              return ListTile(
                selected: isSelected,
                selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(c['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                subtitle: Text("${c['area']} • ${c['mobile']}"),
                onTap: () => setState(() => _selectedCustomer = c),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loans.isEmpty)
          const Text('No active loans found for this customer', style: TextStyle(color: Colors.red))
        else
          DropdownButtonFormField<Map<String, dynamic>>(
            decoration: InputDecoration(
              labelText: 'Select Loan',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _loans.map((l) {
              return DropdownMenuItem(
                value: l as Map<String, dynamic>,
                child: Text("Loan #${l['id']} - Bal: ₹${l['pending']}"),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedLoan = val),
          ),
        const SizedBox(height: 20),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Collection Amount',
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Radio<String>(
              value: 'cash',
              groupValue: _paymentMode,
              onChanged: (v) => setState(() => _paymentMode = v!),
            ),
            const Text('Cash'),
            const SizedBox(width: 20),
            Radio<String>(
              value: 'upi',
              groupValue: _paymentMode,
              onChanged: (v) => setState(() => _paymentMode = v!),
            ),
            const Text('UPI'),
          ],
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      children: [
        _buildReviewRow('Customer', _selectedCustomer?['name'] ?? ''),
        _buildReviewRow('Loan ID', _selectedLoan?['id'].toString() ?? ''),
        _buildReviewRow('Amount', '₹ ${_amountController.text}'),
        _buildReviewRow('Mode', _paymentMode.toUpperCase()),
        const SizedBox(height: 20),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          const Text('GPS will be captured upon submission', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
