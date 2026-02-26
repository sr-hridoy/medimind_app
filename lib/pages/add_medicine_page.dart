import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/medicine_utils.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _name = TextEditingController(), _dose = TextEditingController();
  String _type = "tablet", _sched = "Daily", _freq = "Once";
  List<TimeOfDay> _times = [TimeOfDay.now()];
  final List<String> _days = [];
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  late DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(userId: _authService.currentUser?.uid);
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  void _updFreq(String f) {
    setState(() {
      _freq = f;
      _times = f == "Once"
          ? [_times[0]]
          : (f == "Twice"
                ? [
                    const TimeOfDay(hour: 8, minute: 0),
                    const TimeOfDay(hour: 20, minute: 0),
                  ]
                : [
                    const TimeOfDay(hour: 8, minute: 0),
                    const TimeOfDay(hour: 14, minute: 0),
                    const TimeOfDay(hour: 22, minute: 0),
                  ]);
    });
  }

  Future<void> _saveMedicine() async {
    if (_name.text.isEmpty) {
      _showSnackBar("Please enter medicine name");
      return;
    }
    if (_sched == "Specific Days" && _days.isEmpty) {
      _showSnackBar("Please select at least one day");
      return;
    }
    final timeStrings = _times.map((t) {
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }).toList();

    if (timeStrings.toSet().length < timeStrings.length) {
      _showSnackBar("Please remove duplicate dose times");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docRef = await _dbService.addMedicine({
        'name': _name.text.trim(),
        'dose': _dose.text.trim(),
        'type': _type,
        'schedule': _sched,
        'selectedDays': _days,
        'frequency': '$_freq Daily',
        'times': timeStrings,
      });
      final docId = docRef.id;

      try {
        final notificationService = NotificationService();
        for (final time in timeStrings) {
          final notificationId = NotificationService.generateNotificationId(
            docId,
            time,
          );
          await notificationService.scheduleDoseNotification(
            medicineId: docId,
            medicineName: _name.text.trim(),
            dose: _dose.text.trim(),
            time: time,
            notificationId: notificationId,
          );
        }
      } catch (e) {
        debugPrint("Error scheduling notifications: $e");
      }

      if (!mounted) return;
      _showSnackBar("Medicine saved successfully!");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(msg);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const mint = Color(0xFF26A69A);
    const background = Color(0xFFE0F7FA);

    final fieldDec = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text("Add Medicine"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF37474F),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _name,
            decoration: fieldDec.copyWith(labelText: "Medicine Name"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dose,
            decoration: fieldDec.copyWith(labelText: "Dosage (e.g. 500mg)"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: _type,
            decoration: fieldDec.copyWith(labelText: "Type"),
            items: ["tablet", "syrup", "injection", "others"].map((t) {
              return DropdownMenuItem(
                value: t,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: MedicineUtils.getMedicineIcon(t, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t[0].toUpperCase() + t.substring(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: _sched,
            decoration: fieldDec.copyWith(labelText: "Schedule"),
            items: [
              "Daily",
              "Specific Days",
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _sched = v!),
          ),
          if (_sched == "Specific Days")
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    .map(
                      (d) => FilterChip(
                        label: Text(d),
                        selected: _days.contains(d),
                        onSelected: (v) =>
                            setState(() => v ? _days.add(d) : _days.remove(d)),
                        selectedColor: mint.withValues(alpha: 0.3),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: _freq,
            decoration: fieldDec.copyWith(labelText: "Frequency"),
            items: ["Once", "Twice", "Thrice"]
                .map((f) => DropdownMenuItem(value: f, child: Text("$f Daily")))
                .toList(),
            onChanged: (v) => _updFreq(v!),
          ),
          const SizedBox(height: 8),
          ..._times.asMap().entries.map(
            (e) => ListTile(
              title: Text(
                "Dose Time ${e.key + 1}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Text(
                e.value.format(context),
                style: const TextStyle(
                  color: Color(0xFF26A69A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final p = await showTimePicker(
                  context: context,
                  initialTime: e.value,
                );
                if (p != null) setState(() => _times[e.key] = p);
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mint,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            onPressed: _isLoading ? null : _saveMedicine,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Save Medicine",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
