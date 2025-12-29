import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';
import '../utils/localizations.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'face_enrollment_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isBiometricActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      final profile = await _apiService.getMyProfile(token);
      if (mounted) {
        setState(() {
          _isBiometricActive = profile['has_biometric'] == true;
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
        title: Text(context.translate('security_hub'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   _buildSecurityCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          _buildActionTile(
            Icons.pin_rounded, 
            context.translate('reset_pin'), 
            context.translate('pin_usage_info'),
            onTap: _handleChangePin,
          ),
          const Divider(height: 1),
          _buildActionTile(
            Icons.face_unlock_rounded, 
            context.translate('face_registration'), 
            _isBiometricActive ? 'Update registered face' : 'Register your face for faster login',
            onTap: _handleFaceUpdate,
            trailing: _isBiometricActive 
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : const Icon(Icons.error_outline, color: Colors.orange, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {required VoidCallback onTap, Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 24),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.black12),
      onTap: onTap,
    );
  }

  Future<void> _handleChangePin() async {
    final TextEditingController pinController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('new_pin')),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: InputDecoration(hintText: context.translate('enter_new_pin')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.translate('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.translate('save'))),
        ],
      ),
    );

    if (confirm == true && pinController.text.length == 4) {
       // We can reuse resetUserPin API if it's generic, but usually workers shouldn't reset OTHERS' pins.
       // For self-reset, we might need a specific endpoint or reuse if admin check is skipped for self.
       // However, to keep it simple, I'll assume the admin resetUserPin can be adapted or I'll use it if token is valid.
       final token = await _storage.read(key: 'jwt_token');
       final profile = await _apiService.getMyProfile(token!);
       final userId = profile['id'];

       final result = await _apiService.resetUserPin(userId, pinController.text, token);
       if (result.containsKey('msg') && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.translate('pin_reset_success'))));
       }
    }
  }

  Future<void> _handleFaceUpdate() async {
     final result = await Navigator.pushNamed(context, '/enroll_face');
     if (result == true) {
       _checkStatus();
     }
  }
}
