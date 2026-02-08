import 'package:flutter/material.dart';
import 'login_page.dart';
import 'patient_dashboard.dart';
import 'admin_page.dart';

class MonitorDashboard extends StatefulWidget {
  const MonitorDashboard({super.key});

  @override
  State<MonitorDashboard> createState() => _MonitorDashboardState();
}

class _MonitorDashboardState extends State<MonitorDashboard> {
  int currentIndex = 0;

  List<Map<String, dynamic>> patients = [
    {
      "name": "Patient A",
      "medicines": ["Napa 500mg - 08:00 AM", "Insulin - 09:00 PM"],
    },
    {
      "name": "Patient B",
      "medicines": ["Syrup X - 02:00 PM"],
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color mintBackground = Color(0xFFE0F7FA);
    const Color tealPrimary = Color(0xFF26A69A);
    final pages = [patientListTab(), settingsTab()];

    return Scaffold(
      backgroundColor: mintBackground,
      appBar: AppBar(
        title: const Text("Monitor Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: tealPrimary,
        backgroundColor: Colors.white,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Patients",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget patientListTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Linked Patients",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 16),

        ...patients.map((patient) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.person_outline,
                color: Color(0xFF26A69A),
              ),
              title: Text(
                patient["name"],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              children: (patient["medicines"] as List).map((med) {
                return ListTile(
                  leading: const Icon(
                    Icons.medication_outlined,
                    color: Color(0xFF26A69A),
                    size: 20,
                  ),
                  title: Text(med, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

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
                title: const Text("Switch to Patient Dashboard"),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientDashboard()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFF26A69A),
                ),
                title: const Text("Admin Panel"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPage()),
                  );
                },
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
