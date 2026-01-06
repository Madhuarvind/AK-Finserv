import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class AddLoanScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  const AddLoanScreen({super.key, required this.customerId, required this.customerName});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _interestCtrl = TextEditingController(text: "10");
  final _installmentsCtrl = TextEditingController(text: "100");
  final _guarantorNameCtrl = TextEditingController();
  final _guarantorMobileCtrl = TextEditingController();
  final _guarantorRelationCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _createLoan() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final data = {
        'customer_id': widget.customerId,
        'amount': double.parse(_amountCtrl.text),
        'interest_rate': double.parse(_interestCtrl.text),
        'total_installments': int.parse(_installmentsCtrl.text),
        'guarantor_name': _guarantorNameCtrl.text,
        'guarantor_mobile': _guarantorMobileCtrl.text,
        'guarantor_relation': _guarantorRelationCtrl.text,
      };

      final result = await _apiService.createLoan(data, token);
      if (mounted) {
        if (result.containsKey('loan_id')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loan created successfully!"), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['msg']}"), backgroundColor: Colors.red));
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text("Issue Loan to ${widget.customerName}"), foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
             children: [
               _buildField(_amountCtrl, "Loan Amount (₹)", Icons.currency_rupee, type: TextInputType.number),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(child: _buildField(_interestCtrl, "Interest %", Icons.percent, type: TextInputType.number)),
                   const SizedBox(width: 16),
                   Expanded(child: _buildField(_installmentsCtrl, "Days (Tenure)", Icons.calendar_today, type: TextInputType.number)),
                 ],
               ),
               const SizedBox(height: 20),
               const Divider(),
               Text("Guarantor Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
               const SizedBox(height: 10),
               _buildField(_guarantorNameCtrl, "Guarantor Name", Icons.person_outline),
               const SizedBox(height: 10),
               _buildField(_guarantorMobileCtrl, "Guarantor Mobile", Icons.phone_android, type: TextInputType.phone),
               const SizedBox(height: 10),
               _buildField(_guarantorRelationCtrl, "Relation (e.g., Father)", Icons.people_outline),
               
               const SizedBox(height: 30),
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _createLoan,
                   child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirm & Issue Loan"),
                 ),
               )
             ],
          ),
        ),
      ),
    );
  }

   Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: (v) => v!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }
}
