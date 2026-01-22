import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminQRScanScreen extends StatefulWidget {
  const AdminQRScanScreen({super.key});

  @override
  State<AdminQRScanScreen> createState() => _AdminQRScanScreenState();
}

class _AdminQRScanScreenState extends State<AdminQRScanScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    final String resStr = code.trim();
    
    // Detect Digital Passbook (Unified ID or UUID)
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    
    if (uuidRegex.hasMatch(resStr) || resStr.startsWith('CUST-')) {
       if (mounted) {
         Navigator.pushReplacementNamed(context, '/public/passbook', arguments: resStr);
       }
       return;
    }

    // Show processing for regular customer QR
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Identifying Customer...")),
    );

    try {
      final customerData = await _apiService.getCustomerByQr(resStr);
      
      if (!mounted) return;

      if (customerData['msg'] == 'not_found' || customerData['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Customer not found!"),
            backgroundColor: Colors.red,
          ),
        );
        // Resume scanning after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      } else {
        // Navigate to Customer Details
        Navigator.pushReplacementNamed(
          context, 
          '/admin/customer_detail', 
          arguments: customerData['id']
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan QR", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Align QR code within the frame",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
