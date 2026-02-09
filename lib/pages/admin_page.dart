import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AuthService _authService = AuthService();
  late DatabaseService _dbService;

  final _aboutController = TextEditingController();
  final _faqController = TextEditingController();

  int _totalUsers = 0;
  int _totalAdmins = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(userId: _authService.currentUser?.uid);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _dbService.getTotalUsersCount();
      final admins = await _dbService.getTotalAdminsCount();
      final aboutContent = await _dbService.getAppContent('about_us');
      final faqContent = await _dbService.getAppContent('help_faq');

      if (mounted) {
        setState(() {
          _totalUsers = users;
          _totalAdmins = admins;
          _aboutController.text = aboutContent.isNotEmpty
              ? aboutContent
              : "MediMind is a smart medicine reminder app designed to help patients manage their medication schedules effectively.";
          _faqController.text = faqContent.isNotEmpty
              ? faqContent
              : "How to add medicine? Go to the dashboard and click the '+' button. Follow the prompts to set your schedule.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load data. Please try again.');
      }
    }
  }

  Future<void> _saveContent() async {
    setState(() => _isSaving = true);
    try {
      await _dbService.saveAppContent('about_us', _aboutController.text);
      await _dbService.saveAppContent('help_faq', _faqController.text);
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Content updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Failed to save content. Please try again.');
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const Color mintBackground = Color(0xFFE0F7FA);
    const Color tealPrimary = Color(0xFF26A69A);

    return Scaffold(
      backgroundColor: mintBackground,
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF37474F),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  "System Overview",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallStatCard(
                        "Admins",
                        _totalAdmins.toString(),
                        Icons.admin_panel_settings,
                        tealPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSmallStatCard(
                        "Users",
                        _totalUsers.toString(),
                        Icons.people,
                        tealPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  "Manage Content",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 12),
                _buildEditCard("About Us", _aboutController),
                const SizedBox(height: 12),
                _buildEditCard("Help & FAQ", _faqController),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: tealPrimary.withValues(alpha: 0.4),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSmallStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(String label, TextEditingController controller) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}
