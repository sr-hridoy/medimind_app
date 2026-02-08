import 'package:flutter/material.dart';
import 'add_medicine_page.dart';
import 'login_page.dart';
import 'monitor_dashboard.dart';
import '../theme.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int currentIndex = 0;
  bool notificationsOn = true;

  List<Map<String, dynamic>> medicines = [
    {"name": "Napa", "dose": "500mg", "time": "08:00 AM", "type": "tablet"},
    {"name": "Syrup X", "dose": "10ml", "time": "02:00 PM", "type": "syrup"},
    {
      "name": "Insulin",
      "dose": "5 units",
      "time": "09:00 PM",
      "type": "injection",
    },
  ];

  String filter = "All";

  IconData getMedicineIcon(String type) {
    if (type == "tablet") return Icons.medication;
    if (type == "syrup") return Icons.local_drink;
    return Icons.vaccines;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [homeTab(), medicinesTab(), settingsTab()];

    return Scaffold(
      appBar: AppBar(title: const Text("Patient Dashboard")),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: mint,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Medicines"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      floatingActionButton: currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: mint,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMedicinePage()),
                );
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  // ---------------- HOME TAB ----------------
  Widget homeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Today's Medicines",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        ...medicines.map((med) {
          return Card(
            child: ListTile(
              leading: Icon(getMedicineIcon(med["type"]), color: mint),
              title: Text(med["name"]),
              subtitle: Text("${med["dose"]} • ${med["time"]}"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(med["name"]),
                    content: const Text("Did you take this medicine?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Missed"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Taken"),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // ---------------- MEDICINES TAB ----------------
  Widget medicinesTab() {
    List<Map<String, dynamic>> filtered = medicines;

    if (filter == "Daily") {
      filtered = medicines; // later: daily logic
    } else if (filter == "Specific Days") {
      filtered = medicines; // later: specific logic
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              filterButton("All"),
              const SizedBox(width: 10),
              filterButton("Daily"),
              const SizedBox(width: 10),
              filterButton("Specific Days"),
            ],
          ),
          const SizedBox(height: 15),

          Expanded(
            child: ListView(
              children: filtered.map((med) {
                return Card(
                  child: ListTile(
                    leading: Icon(getMedicineIcon(med["type"]), color: mint),
                    title: Text(med["name"]),
                    subtitle: Text("${med["dose"]} • ${med["time"]}"),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget filterButton(String text) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: filter == text ? mint : Colors.grey.shade200,
          foregroundColor: Colors.black,
        ),
        onPressed: () {
          setState(() => filter = text);
        },
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  // ---------------- SETTINGS TAB ----------------
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
              MaterialPageRoute(builder: (_) => const MonitorDashboard()),
            );
          },
        ),

        SwitchListTile(
          value: notificationsOn,
          activeColor: mint,
          title: const Text("Notifications"),
          onChanged: (value) {
            setState(() => notificationsOn = value);
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
