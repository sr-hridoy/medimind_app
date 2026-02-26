import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'add_medicine_page.dart';
import 'login_page.dart';
import 'monitor_dashboard.dart';
import '../widgets/dose_list_view.dart';
import '../utils/medicine_utils.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int currentIndex = 0;
  String filter = "All";

  final AuthService _authService = AuthService();
  late DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(userId: _authService.currentUser?.uid);
  }

  void _showMedManageDetail(Map<String, dynamic> med, String docId) {
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
            SizedBox(
              width: 48,
              height: 48,
              child: MedicineUtils.getMedicineIcon(med["type"], size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              med["name"] ?? 'Unknown',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "${med["dose"] ?? ''} • ${med["type"] ?? 'tablet'}",
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "${(med["times"] as List<dynamic>?)?.join(', ') ?? ''} • ${med["frequency"] ?? 'Daily'}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _dbService.deleteMedicine(docId).catchError((e) {
                        debugPrint('Delete failed: $e');
                      });
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
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MediMind",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _authService.currentUser?.displayName != null
                      ? "Hello, ${_authService.currentUser!.displayName!.split(' ').first}!"
                      : "Your health companion",
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: "Switch to Monitor",
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Switch Dashboard"),
                  content: const Text(
                    "Are you sure you want to switch to Monitor Dashboard?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MonitorDashboard()),
                );
              }
            },
          ),
        ],
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

  Widget homeTab() {
    return DoseListView(userId: _authService.currentUser?.uid ?? '');
  }

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
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getMedicines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No medicines added yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                var meds = snapshot.data!.docs;

                // Apply filter
                if (filter == "Daily") {
                  meds = meds.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['schedule'] == 'Daily';
                  }).toList();
                } else if (filter == "Weekly") {
                  meds = meds.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['schedule'] == 'Specific Days';
                  }).toList();
                }

                return ListView(
                  children: meds.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: MedicineUtils.getMedicineIcon(
                            data["type"],
                            size: 40,
                          ),
                        ),
                        title: Text(
                          data["name"] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${data["dose"] ?? ''} • ${(data["times"] as List<dynamic>?)?.join(', ') ?? ''}",
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showMedManageDetail(data, doc.id),
                      ),
                    );
                  }).toList(),
                );
              },
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
              ListTile(
                leading: const Icon(
                  Icons.supervised_user_circle_outlined,
                  color: Color(0xFF26A69A),
                ),
                title: const Text("My Caregivers"),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap: _showCaregiversDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.notification_add_outlined,
                  color: Color(0xFF26A69A),
                ),
                title: const Text("Monitor Request"),
                trailing: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getPendingRequests(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    if (count == 0) {
                      return const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey,
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
                onTap: _showMonitorRequestsDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF26A69A),
                ),
                title: const Text("Help and FAQ"),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap: () => _showContentDialog("Help & FAQ", "help_faq"),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF26A69A),
                ),
                title: const Text("About Us"),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap: () => _showContentDialog("About Us", "about_us"),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  await _authService.signOut();
                  if (!mounted) return;
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

  void _showCaregiversDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("My Caregivers"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getMyCaregivers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No caregivers linked yet.");
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFF26A69A)),
                    title: Text(data['monitorName'] ?? 'Unknown'),
                    subtitle: Text(data['monitorEmail'] ?? ''),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showMonitorRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Monitor Requests"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getPendingRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No pending requests.");
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(data['monitorName'] ?? 'Unknown'),
                      subtitle: Text(data['monitorEmail'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await _dbService.rejectLinkRequest(doc.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await _dbService.acceptLinkRequest(doc.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showContentDialog(String title, String key) async {
    final content = await _dbService.getAppContent(key);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content.isNotEmpty ? content : "Content not available."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
