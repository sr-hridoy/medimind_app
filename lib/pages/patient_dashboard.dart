import 'package:flutter/material.dart';
import 'add_medicine_page.dart';
import 'login_page.dart';
import 'monitor_dashboard.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int currentIndex = 0;
  bool notificationsOn = true;

  List<Map<String, dynamic>> medicines = [
    {
      "name": "Napa",
      "dose": "500mg",
      "time": "08:00 AM",
      "type": "tablet",
      "frequency": "Thrice Daily",
      "isTaken": false,
    },
    {
      "name": "Syrup X",
      "dose": "10ml",
      "time": "02:00 PM",
      "type": "syrup",
      "frequency": "Once Daily",
      "isTaken": false,
    },
    {
      "name": "Insulin",
      "dose": "5 units",
      "time": "09:00 PM",
      "type": "injection",
      "frequency": "Daily",
      "isTaken": true,
    },
  ];

  String filter = "All";

  IconData getMedicineIcon(String type) {
    if (type == "tablet") return Icons.medication;
    if (type == "syrup") return Icons.local_drink;
    return Icons.vaccines;
  }

  void _showMedDetail(Map<String, dynamic> med, {String mode = "none"}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getMedicineIcon(med["type"]),
              size: 48,
              color: const Color(0xFF26A69A),
            ),
            const SizedBox(height: 16),
            Text(
              med["name"],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "${med["dose"]} • ${med["type"]}",
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "${med["time"]} • ${med["frequency"] ?? 'Daily'}",
              style: const TextStyle(color: Colors.grey),
            ),
            if (mode == "tracking") ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Missed"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => med["isTaken"] = true);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Taken"),
                    ),
                  ),
                ],
              ),
            ] else if (mode == "manage") ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => medicines.remove(med));
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("OK"),
                    ),
                  ),
                ],
              ),
            ] else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color mintBackground = Color(0xFFE0F7FA);
    const Color tealPrimary = Color(0xFF26A69A);
    final pages = [homeTab(), medicinesTab(), settingsTab()];

    return Scaffold(
      backgroundColor: mintBackground,
      appBar: AppBar(
        title: const Text("MediMind"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: tealPrimary,
        backgroundColor: Colors.white,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: "Medicines",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      floatingActionButton: (currentIndex == 0 || currentIndex == 1)
          ? FloatingActionButton(
              backgroundColor: tealPrimary,
              elevation: 2,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMedicinePage()),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // ---------------- HOME TAB ----------------
  Widget homeTab() {
    final untracked = medicines.where((m) => !m["isTaken"]).toList();
    final tracked = medicines.where((m) => m["isTaken"]).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader("Untracked Doses"),
        if (untracked.isEmpty)
          const Text(
            "All doses tracked! 🎉",
            style: TextStyle(color: Colors.grey),
          ),
        ...untracked.map((med) => _medCard(med, mode: "tracking")),
        const SizedBox(height: 24),
        _sectionHeader("Tracked Doses"),
        if (tracked.isEmpty)
          const Text(
            "No tracked doses yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ...tracked.map((med) => _medCard(med, mode: "none")),
      ],
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF37474F),
      ),
    ),
  );

  Widget _medCard(Map<String, dynamic> med, {required String mode}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          getMedicineIcon(med["type"]),
          color: const Color(0xFF26A69A),
        ),
        title: Text(
          med["name"],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${med["dose"]} • ${med["time"]}"),
        trailing: med["isTaken"]
            ? const Icon(Icons.check_circle, color: Color(0xFF26A69A))
            : const Icon(Icons.chevron_right),
        onTap: () => _showMedDetail(med, mode: mode),
      ),
    );
  }

  // ---------------- MEDICINES TAB ----------------
  Widget medicinesTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Medicines",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              "All",
              "Daily",
              "Weekly",
            ].map((t) => filterButton(t)).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: medicines
                  .map((med) => _medCard(med, mode: "manage"))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget filterButton(String text) {
    bool isSelected = filter == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filter = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF26A69A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF26A69A)
                  : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- SETTINGS TAB ----------------
  Widget settingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Settings",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Color(0xFF26A69A)),
                title: const Text("Switch to Monitor Dashboard"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MonitorDashboard()),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: notificationsOn,
                activeColor: const Color(0xFF26A69A),
                title: const Text("Enable Notifications"),
                secondary: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF26A69A),
                ),
                onChanged: (value) => setState(() => notificationsOn = value),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(
                  Icons.supervised_user_circle_outlined,
                  color: Color(0xFF26A69A),
                ),
                title: Text("My Caregivers"),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(
                  Icons.notification_add_outlined,
                  color: Color(0xFF26A69A),
                ),
                title: Text("Monitor Request"),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF26A69A),
                ),
                title: Text("Help and FAQ"),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF26A69A),
                ),
                title: Text("About Us"),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
