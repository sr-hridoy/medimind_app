import 'package:flutter/material.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _name = TextEditingController(), _dose = TextEditingController();
  String _type = "tablet", _sched = "Daily", _freq = "Once";
  List<TimeOfDay> _times = [TimeOfDay.now()];
  List<String> _days = [];

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
            value: _type,
            decoration: fieldDec.copyWith(labelText: "Type"),
            items: [
              "tablet",
              "syrup",
              "injection",
              "others",
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _sched,
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
                        selectedColor: mint.withOpacity(0.3),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _freq,
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
            onPressed: () {
              if (_name.text.isEmpty ||
                  (_sched == "Specific Days" && _days.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all details")),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Save Medicine",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
