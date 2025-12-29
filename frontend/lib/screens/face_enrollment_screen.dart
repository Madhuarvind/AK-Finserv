import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';
import '../utils/localizations.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  CameraController? _controller;
  XFile? _imageFile;
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;
    
    // Find front camera
    CameraDescription? frontCamera;
    for (var cam in cameras) {
      if (cam.lensDirection == CameraLensDirection.front) {
        frontCamera = cam;
        break;
      }
    }
    
    _controller = CameraController(
      frontCamera ?? cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);
    
    try {
      final image = await _controller!.takePicture();
      setState(() => _imageFile = image);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Capture Error: $e")));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadFace() async {
    if (_imageFile == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final token = await _storage.read(key: 'jwt_token');
      final profile = await _apiService.getMyProfile(token!);
      
      // Using dummy embedding as per existing FaceRegistrationScreen logic
      List<double> dummyEmbedding = List.generate(128, (index) => 0.6); 
      
      final result = await _apiService.registerFace(
        profile['id'],
        dummyEmbedding,
        'self_device',
        token,
      );

      if (mounted) {
        if (result.containsKey('msg') && result['msg'] == 'face_registered_successfully') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Face registered successfully!")));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['msg'] ?? "Error registering face")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.translate('face_registration'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _imageFile != null
                  ? Image.network(_imageFile!.path) // Better for both web and mobile
                  : (_controller != null && _controller!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        )
                      : const CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _imageFile == null ? "Position your face in the frame" : "Check if photo is clear",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 24),
                if (_imageFile == null)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePicture,
                    icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt_rounded),
                    label: const Text("CAPTURE FACE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() { _imageFile = null; _isProcessing = false; }),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("RETRY"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _uploadFace,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT"),
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
