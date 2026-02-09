import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class DoseListView extends StatefulWidget {
  final String userId;
  final bool isReadOnly;

  const DoseListView({
    super.key,
    required this.userId,
    this.isReadOnly = false,
  });

  @override
  State<DoseListView> createState() => _DoseListViewState();
}

class _DoseListViewState extends State<DoseListView> {
  late DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(userId: widget.userId);
  }

  IconData getMedicineIcon(String type) {
    if (type == "tablet") return Icons.medication;
    if (type == "syrup") return Icons.local_drink;
    return Icons.vaccines;
  }

  bool _shouldShowToday(Map<String, dynamic> med) {
    final schedule = med['schedule'] ?? 'Daily';
    if (schedule == 'Daily') return true;

    final selectedDays = med['selectedDays'] as List<dynamic>? ?? [];
    if (selectedDays.isEmpty) return true;

    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentDay = dayNames[now.weekday - 1];

    return selectedDays.contains(currentDay);
  }

  int _compareTimes(String t1, String t2) {
    TimeOfDay parse(String s) {
      final parts = s.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      final m = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && h != 12) h += 12;
      if (parts[1] == 'AM' && h == 12) h = 0;
      return TimeOfDay(hour: h, minute: m);
    }

    final p1 = parse(t1);
    final p2 = parse(t2);
    if (p1.hour != p2.hour) return p1.hour.compareTo(p2.hour);
    return p1.minute.compareTo(p2.minute);
  }

  void _showMedDetail(
    Map<String, dynamic> med,
    String docId, {
    String mode = "none",
    String? doseTime,
  }) {
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
              getMedicineIcon(med["type"] ?? 'tablet'),
              size: 48,
              color: const Color(0xFF26A69A),
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
              "${(med["times"] as List<dynamic>?)?.firstOrNull ?? ''} • ${med["frequency"] ?? 'Daily'}",
              style: const TextStyle(color: Colors.grey),
            ),
            if (med["schedule"] == "Specific Days") ...[
              const SizedBox(height: 8),
              Text(
                "Days: ${(med["selectedDays"] as List<dynamic>?)?.join(', ') ?? ''}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            if (mode == "tracking" && !widget.isReadOnly) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _dbService.trackDose(
                          docId,
                          'missed',
                          doseTime ?? '',
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[800],
                        side: BorderSide(color: Colors.orange[800]!),
                      ),
                      child: const Text("Missed"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _dbService.trackDose(
                          docId,
                          'taken',
                          doseTime ?? '',
                        );
                        if (!mounted) return;
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
            ] else ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getMedicines(),
      builder: (context, medsSnapshot) {
        if (medsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _dbService.getTodayTrackedDoses(),
          builder: (context, trackingSnapshot) {
            if (trackingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allMeds = medsSnapshot.data?.docs ?? [];
            if (allMeds.isEmpty) {
              return _emptyState();
            }

            final trackingData = {
              for (var doc in (trackingSnapshot.data?.docs ?? []))
                "${(doc.data() as Map<String, dynamic>)['medicineId']}_${(doc.data() as Map<String, dynamic>)['time']}":
                    (doc.data() as Map<String, dynamic>)['status'],
            };

            final List<Map<String, dynamic>> flatDoses = [];
            for (var doc in allMeds) {
              final data = doc.data() as Map<String, dynamic>;
              if (_shouldShowToday(data)) {
                final times = data['times'] as List<dynamic>? ?? [];
                for (var time in times) {
                  flatDoses.add({
                    'id': doc.id,
                    'data': data,
                    'time': time,
                    'status': trackingData["${doc.id}_$time"],
                  });
                }
              }
            }

            flatDoses.sort((a, b) => _compareTimes(a['time'], b['time']));

            final untracked = flatDoses
                .where((d) => d['status'] == null)
                .toList();
            final taken = flatDoses
                .where((d) => d['status'] == 'taken')
                .toList();
            final missed = flatDoses
                .where((d) => d['status'] == 'missed')
                .toList();

            return ListView(
              shrinkWrap: true,
              physics: widget.isReadOnly
                  ? const NeverScrollableScrollPhysics()
                  : null,
              padding: widget.isReadOnly
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(20),
              children: [
                _sectionHeader(
                  widget.isReadOnly
                      ? "Upcoming Doses"
                      : "Today's Upcoming Doses",
                ),
                if (untracked.isEmpty)
                  const Text(
                    "All doses tracked for today! 🎉",
                    style: TextStyle(color: Colors.grey),
                  ),
                ...untracked.map(
                  (d) => _medCard(
                    d['data'],
                    d['id'],
                    mode: "tracking",
                    timeOverride: d['time'],
                  ),
                ),
                const SizedBox(height: 24),
                if (taken.isNotEmpty) ...[
                  _sectionHeader("Tracked Doses"),
                  ...taken.map(
                    (d) => _medCard(
                      d['data'],
                      d['id'],
                      mode: "none",
                      status: "taken",
                      timeOverride: d['time'],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (missed.isNotEmpty) ...[
                  _sectionHeader("Missed Doses"),
                  ...missed.map(
                    (d) => _medCard(
                      d['data'],
                      d['id'],
                      mode: "none",
                      status: "missed",
                      timeOverride: d['time'],
                    ),
                  ),
                ],
                if (taken.isEmpty && missed.isEmpty)
                  const Text(
                    "No tracked doses yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              "No medicines added yet",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
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

  Widget _medCard(
    Map<String, dynamic> med,
    String docId, {
    required String mode,
    String? status,
    String? timeOverride,
  }) {
    final times = med["times"] as List<dynamic>? ?? [];
    final timeStr =
        timeOverride ?? (times.isNotEmpty ? times.first.toString() : '');

    Widget getTrailing() {
      if (status == "taken") {
        return const Icon(Icons.check_circle, color: Color(0xFF26A69A));
      } else if (status == "missed") {
        return Icon(Icons.cancel, color: Colors.orange[800]);
      }
      return const Icon(Icons.chevron_right);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          getMedicineIcon(med["type"] ?? 'tablet'),
          color: status == "missed" ? Colors.grey : const Color(0xFF26A69A),
        ),
        title: Text(
          med["name"] ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: status == "missed" ? TextDecoration.lineThrough : null,
            color: status == "missed" ? Colors.grey : null,
          ),
        ),
        subtitle: Text("${med["dose"] ?? ''} • $timeStr"),
        trailing: getTrailing(),
        onTap: () => _showMedDetail(med, docId, mode: mode, doseTime: timeStr),
      ),
    );
  }
}
