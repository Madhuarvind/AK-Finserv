import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../utils/localizations.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_drawer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'profile_screen.dart';
import 'security_settings_screen.dart';
import 'admin/team_management_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final ApiService _apiService = ApiService();
  String? _userName;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final storage = const FlutterSecureStorage();
    final name = await storage.read(key: 'user_name');
    final role = await storage.read(key: 'user_role');
    
    if (mounted) {
      setState(() {
        _userName = name;
        _role = role;
      });
    }
  }

  void _handleLogout() async {
    await _apiService.clearAuth();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          drawer: AppDrawer(
            userName: _userName ?? 'User',
            role: _role ?? 'field_agent',
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context),
                const SizedBox(height: 32),
                _buildStatsGrid(context),
                const SizedBox(height: 32),
                Text(
                  context.translate('quick_actions'),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 32),
                _buildRecentActivity(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.translate('welcome')},',
          style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16, fontWeight: FontWeight.normal),
        ),
        const SizedBox(height: 4),
        Text(
          (_userName != null && _userName!.isNotEmpty) ? _userName! : context.translate('field_agent'),
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context.translate('goal'),
            '₹ 25,000',
            Icons.track_changes_rounded,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context.translate('collected'),
            '₹ 12,450',
            Icons.account_balance_wallet_rounded,
            Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionItem(context.translate('qr_scan'), Icons.qr_code_scanner_rounded, Colors.orange, () {}),
        _buildActionItem(context.translate('collection'), Icons.add_circle_outline_rounded, Colors.greenAccent, () {
          Navigator.pushNamed(context, '/collection_entry');
        }),
        _buildActionItem(context.translate('expense'), Icons.receipt_long_rounded, Colors.pinkAccent, () {}),
        _buildActionItem(context.translate('my_profile'), Icons.person_outline_rounded, Colors.blue, () {
          Navigator.pushNamed(context, '/profile');
        }),
        _buildActionItem(context.translate('security_hub'), Icons.security_rounded, Colors.indigoAccent, () {
          Navigator.pushNamed(context, '/security');
        }),
        if (_role == 'manager')
          _buildActionItem(context.translate('my_team'), Icons.groups_rounded, Colors.green, () {
            Navigator.pushNamed(context, '/admin/team');
          })
        else
          _buildActionItem(context.translate('reports'), Icons.bar_chart_rounded, Colors.purpleAccent, () {}),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.translate('recent_activity'),
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.secondaryTextColor.withOpacity(0.3)),
            ],
          ),
          const SizedBox(height: 24),
          _buildActivityTile('Collected from John Doe', '10 mins ago', '₹ 1,200', Colors.green),
          Divider(color: Colors.black.withOpacity(0.05), height: 32),
          _buildActivityTile('Collection Failed: Madhu', '1 hour ago', '₹ 800', AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String title, String time, String amount, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.receipt_long_outlined, color: color.withOpacity(0.7), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 12)),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
      ],
    );
  }
}
