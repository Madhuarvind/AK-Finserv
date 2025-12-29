import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../utils/localizations.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_drawer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _userName;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchUsers();
  }

  void _loadUser() async {
    final name = await _storage.read(key: 'user_name');
    final role = await _storage.read(key: 'user_role');
    if (mounted) {
      setState(() {
        _userName = name;
        _role = role;
      });
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final token = await _apiService.getToken();
    if (token != null) {
      final result = await _apiService.getUsers(token);
      if (result is List) {
        setState(() {
          _users = result;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['msg'] ?? context.translate('failure'))),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          drawer: AppDrawer(
            userName: _userName ?? 'Administrator',
            role: _role ?? 'admin',
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppTheme.secondaryTextColor.withOpacity(0.5), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Search anything...',
                          style: TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.5), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fynix Balance Card
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFFD4FF8B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
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
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Balance',
                                        style: GoogleFonts.outfit(
                                          color: Colors.black.withOpacity(0.6),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Icon(Icons.add_circle_outline_rounded, color: Colors.black, size: 28),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹12,45,690',
                                    style: GoogleFonts.outfit(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildCompactButton('Deposit', Colors.white, Colors.black),
                                      const SizedBox(width: 12),
                                      _buildCompactButton('Send', Colors.black, Colors.white),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.translate('quick_actions'),
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                          ),
                          Icon(Icons.more_horiz_rounded, color: AppTheme.secondaryTextColor.withOpacity(0.5)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _buildModernActionTile(context, context.translate('user_management'), Icons.manage_accounts_outlined, '/admin/user_management'),
                          const SizedBox(width: 16),
                          _buildModernActionTile(context, context.translate('audit_logs'), Icons.assignment_outlined, '/admin/audit_logs'),
                          const SizedBox(width: 16),
                          _buildModernActionTile(context, context.translate('settings'), Icons.settings_outlined, '/settings'),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                          ),
                          Text(
                            'View All',
                            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _users.take(5).length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.black.withOpacity(0.04)),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                user['role'] == 'admin' ? Icons.shield_outlined : Icons.person_outline_rounded,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            title: Text(
                              user['name'] ?? user['username'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              user['mobile_number'] ?? '',
                              style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Active',
                                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Just now',
                                  style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildCompactButton(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildModernActionTile(BuildContext context, String title, IconData icon, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route).then((_) => _fetchUsers()),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black54, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.textColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResetDevice(int userId) async {
    final token = await _apiService.getToken();
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('reset_confirm_title')),
        content: Text(context.translate('reset_confirm_content')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(context.translate('save'), style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _apiService.resetDevice(userId, token);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['msg'] ?? context.translate('success'))),
      );
      _fetchUsers();
    }
  }
}
