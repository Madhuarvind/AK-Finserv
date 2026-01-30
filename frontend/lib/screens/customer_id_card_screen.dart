import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/theme.dart';

class CustomerIdCardScreen extends StatelessWidget {
  final Map<String, dynamic> customer;

  const CustomerIdCardScreen({super.key, required this.customer});

  Future<void> _printCard(BuildContext context) async {
    try {
      final doc = pw.Document();
      final logo = await imageFromAssetBundle('assets/logo.png');

      // Standard ID card size: 85.6mm x 54mm
      final cardFormat = PdfPageFormat.roll80.copyWith(
        width: 85.6 * PdfPageFormat.mm,
        height: 54.0 * PdfPageFormat.mm,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
      );

      doc.addPage(
        pw.Page(
          pageFormat: cardFormat,
          build: (pw.Context context) {
            return pw.Container(
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.blue900, PdfColors.green700], // Approximate AppTheme.primaryColor to Green
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
              ),
              child: pw.Stack(
                children: [
                  // Background Circles (Simulated opacity)
                   pw.Positioned(
                    right: -30,
                    top: -30,
                    child: pw.Opacity(
                      opacity: 0.1,
                      child: pw.Container(
                        width: 150,
                        height: 150,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  pw.Positioned(
                    left: -50,
                    bottom: -50,
                    child: pw.Opacity(
                      opacity: 0.1,
                      child: pw.Container(
                        width: 120,
                        height: 120,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  
                  // Main Content
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Header: Company Name & Logo
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                             pw.Text('AK FINSERV', 
                               style: pw.TextStyle(
                                 color: PdfColors.white, 
                                 fontSize: 16, // Reduced from 18
                                 fontWeight: pw.FontWeight.bold,
                                 letterSpacing: 1.5
                               )
                             ),
                             pw.Container(
                               padding: const pw.EdgeInsets.all(4),
                               decoration: const pw.BoxDecoration(
                                 color: PdfColors.white,
                                 shape: pw.BoxShape.circle,
                               ),
                               child: pw.ClipOval(
                                 child: pw.Image(logo, width: 32, height: 32, fit: pw.BoxFit.cover), // Reduced from 40
                               ),
                             ),
                          ],
                        ),
                        
                        pw.Spacer(),
                        
                        // Footer: Customer Details & QR
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    customer['name']?.toString().toUpperCase() ?? 'N/A',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 14, // Reduced from 18
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'ID: ${customer['customer_id'] ?? 'N/A'}',
                                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(
                                    'MOB: ${customer['mobile'] ?? 'N/A'}',
                                    style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(4),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                              ),
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: customer['customer_id'] ?? '',
                                width: 45, // Reduced from 50
                                height: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'ID_Card_${customer['customer_id']}.pdf',
        format: cardFormat,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Customer ID Card', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print Card',
            onPressed: () => _printCard(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Customer Card Generated!',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Print or save this card for the customer',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _buildIdCard(),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.black),
                      label: Text('Done', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _printCard(context),
                      icon: const Icon(Icons.print_rounded, color: Colors.white),
                      label: Text('Print Card', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdCard() {
    return Container(
      width: 400,
      height: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF7CB342)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -30,
            top: -30,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -50,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AK FINSERV',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Customer details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] ?? 'N/A',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${customer['customer_id'] ?? 'N/A'}',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer['mobile'] ?? 'N/A',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: customer['customer_id'] ?? '',
                        version: QrVersions.auto,
                        size: 80,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
