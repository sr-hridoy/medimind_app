import 'package:flutter/material.dart';
import '../theme.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  String frequency = "Daily";
  TimeOfDay selectedTime = TimeOfDay.now();
  String medType = "tablet";

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final doseController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Medicine")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Medicine Name"),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: doseController,
              decoration: const InputDecoration(labelText: "Dosage"),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField(
              value: medType,
              decoration: const InputDecoration(labelText: "Medicine Type"),
              items: const [
                DropdownMenuItem(value: "tablet", child: Text("Tablet")),
                DropdownMenuItem(value: "syrup", child: Text("Syrup")),
                DropdownMenuItem(value: "injection", child: Text("Injection")),
              ],
              onChanged: (value) {
                setState(() => medType = value.toString());
              },
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField(
              value: frequency,
              decoration: const InputDecoration(labelText: "Frequency"),
              items: const [
                DropdownMenuItem(value: "Daily", child: Text("Daily")),
                DropdownMenuItem(
                  value: "Specific Days",
                  child: Text("Specific Days"),
                ),
              ],
              onChanged: (value) {
                setState(() => frequency = value.toString());
              },
            ),
            const SizedBox(height: 15),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Colors.grey.shade100,
              title: Text("Time: ${selectedTime.format(context)}"),
              trailing: const Icon(Icons.access_time, color: mint),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) {
                  setState(() => selectedTime = picked);
                }
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save to Firebase later
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
