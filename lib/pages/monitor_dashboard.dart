import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_page.dart';
import 'patient_dashboard.dart';
import '../widgets/dose_list_view.dart';

class MonitorDashboard extends StatefulWidget {
  const MonitorDashboard({super.key});

  @override
  State<MonitorDashboard> createState() => _MonitorDashboardState();
}

class _MonitorDashboardState extends State<MonitorDashboard> {
  int currentIndex = 0;
  final AuthService _authService = AuthService();
  late DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(userId: _authService.currentUser?.uid);
  }

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Linked Patients",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF37474F),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showLinkPatientDialog,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text("Link Patient"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "You can link up to 5 patients",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: _dbService.getLinkedPatients(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No linked patients yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tap 'Link Patient' to send a request",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final patientEmail = data['patientEmail'] ?? 'Unknown';
                final patientId = data['patientId'];

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
                      patientEmail,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: DoseListView(
                          userId: patientId,
                          isReadOnly: true,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showLinkPatientDialog() {
    final emailController = TextEditingController();
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Link Patient"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter the email of the patient you want to monitor. "
                  "They will receive a request to accept.",
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  enabled: !isDialogLoading,
                  decoration: const InputDecoration(
                    labelText: "Patient Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (isDialogLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDialogLoading
                    ? null
                    : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isDialogLoading
                    ? null
                    : () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          _showSnackBar('Please enter a valid email');
                          return;
                        }

                        setDialogState(() => isDialogLoading = true);

                        try {
                          final userName = await _authService.getUserName();
                          final userEmail =
                              _authService.currentUser?.email ?? '';

                          // Client-side validation: prevent self-request
                          if (email.toLowerCase() == userEmail.toLowerCase()) {
                            _showSnackBar(
                              'You cannot send a request to yourself',
                            );
                            setDialogState(() => isDialogLoading = false);
                            return;
                          }

                          await _dbService.sendLinkRequest(
                            patientEmail: email,
                            monitorName: userName ?? 'Unknown',
                            monitorEmail: userEmail,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _showSnackBar('Link request sent successfully!');
                        } catch (e) {
                          if (mounted) {
                            setDialogState(() => isDialogLoading = false);
                            _showSnackBar(
                              e.toString().replaceAll('Exception: ', ''),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A),
                  foregroundColor: Colors.white,
                ),
                child: Text(isDialogLoading ? "Sending..." : "Send Request"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
}
