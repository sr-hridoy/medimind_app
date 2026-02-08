import 'package:flutter/material.dart';
import 'login_page.dart';
import 'patient_dashboard.dart';
import '../theme.dart';

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
    final pages = [patientListTab(), settingsTab()];

    return Scaffold(
      appBar: AppBar(title: const Text("Monitor Dashboard")),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: mint,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Patients"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget patientListTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Linked Patients",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        ...patients.map((patient) {
          return Card(
            child: ExpansionTile(
              title: Text(patient["name"]),
              children: (patient["medicines"] as List).map((med) {
                return ListTile(
                  leading: const Icon(Icons.medication, color: mint),
                  title: Text(med),
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
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "General",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: const Text("Switch Dashboard"),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PatientDashboard()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Logout"),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        ),
      ],
    );
  }
}
