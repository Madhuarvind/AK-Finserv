import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/theme.dart';
import '../../services/local_db_service.dart';
import '../../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _idProofController = TextEditingController();
  
  bool _isLoading = false;
  File? _profileImage;
  Position? _currentPosition;
  String _locationMessage = "Location not captured";
  final _localDb = LocalDbService();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _idProofController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 600);
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        setState(() {
          _currentPosition = position;
          _locationMessage = "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
        });
      } else {
        setState(() => _locationMessage = "Permission Denied");
      }
    } catch (e) {
      setState(() => _locationMessage = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {

      return;

    }

    setState(() => _isLoading = true);

    try {
      // Check if running on web
      final isWeb = identical(0, 0.0); // Simple web detection
      
      if (isWeb) {
        // WEB: Save directly to backend
        debugPrint('Running on WEB - saving directly to backend');
        final token = await _storage.read(key: 'jwt_token');
        if (token == null) {
          throw Exception('No auth token');
        }
        
        final customerData = {
          'name': _nameController.text.trim(),
          'mobile_number': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          'area': _areaController.text.trim(),
          'id_proof_number': _idProofController.text.trim(),
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
        };
        
        // Call backend API directly
        final response = await _apiService.createCustomerOnline(customerData, token);
        
        if (mounted) {
          if (response['customer_id'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer created successfully!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true);
          } else {
            throw Exception(response['msg'] ?? 'Failed to create customer');
          }
        }
      } else {
        // MOBILE: Save to local DB (offline-first)
        debugPrint('Running on MOBILE - saving to local DB');
        final customerData = {
          'name': _nameController.text.trim(),
          'mobile_number': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          'area': _areaController.text.trim(),
          'id_proof_number': _idProofController.text.trim(),
          'status': 'created',
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
          'profile_image': _profileImage?.path,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _localDb.addCustomerLocally(customerData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer saved offline! Sync pending.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {

        setState(() => _isLoading = false);

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Add Customer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               _buildSectionHeader('Profile Photo'),
               const SizedBox(height: 10),
               Center(
                 child: GestureDetector(
                   onTap: _pickImage,
                   child: CircleAvatar(
                     radius: 50,
                     backgroundColor: Colors.grey[200],
                     backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                     child: _profileImage == null ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]) : null,
                   ),
                 ),
               ),
               const SizedBox(height: 10),
               Center(child: Text("Tap to take photo", style: GoogleFonts.outfit(color: Colors.grey))),
               const SizedBox(height: 20),

              _buildSectionHeader('Basic Info'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _nameController,
                label: 'Customer Name',
                icon: Icons.person,
                textInputAction: TextInputAction.next,
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => v!.length < 10 ? 'Enter valid mobile number' : null,
              ),
              const SizedBox(height: 25),
              _buildSectionHeader('Location'),
               const SizedBox(height: 10),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.black.withValues(alpha: 0.05))
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                     const SizedBox(width: 12),
                     Expanded(child: Text(_locationMessage, style: GoogleFonts.outfit())),
                     IconButton(
                       icon: const Icon(Icons.my_location),
                       onPressed: _isLoading ? null : _getCurrentLocation,
                     )
                   ],
                 ),
               ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home,
                textInputAction: TextInputAction.next,
                maxLines: 2,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _areaController,
                label: 'Area / Group',
                icon: Icons.map,
                textInputAction: TextInputAction.next,
                validator: (v) => v!.isEmpty ? 'Area is required' : null,
              ),
              const SizedBox(height: 25),
              _buildSectionHeader('Documents (Optional)'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _idProofController,
                label: 'ID Proof Number',
                icon: Icons.badge,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save Customer', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
