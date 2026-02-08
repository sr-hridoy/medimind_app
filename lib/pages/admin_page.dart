import 'package:flutter/material.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _aboutController = TextEditingController(
    text:
        "MediMind is a smart medicine reminder app designed to help patients manage their medication schedules effectively.",
  );
  final _faqController = TextEditingController(
    text:
        "How to add medicine? Go to the dashboard and click the '+' button. Follow the prompts to set your schedule.",
  );

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
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
                  "3",
                  Icons.admin_panel_settings,
                  tealPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSmallStatCard(
                  "Users",
                  "120",
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Content updated successfully!")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tealPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: tealPrimary.withOpacity(0.4),
            ),
            child: const Text(
              "Save Changes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
