import 'package:flutter/material.dart';
import 'package:medicine_dispersor/models/medication.dart';
import 'package:medicine_dispersor/services/database_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Future<List<Medication>>? _medicationsFuture;

  @override
  void initState() {
    super.initState();
    _medicationsFuture = DatabaseService.getMedications();
  }

  Future<void> _refreshMedications() async {
    setState(() {
      _medicationsFuture = DatabaseService.getMedications();
    });
  }

  void _updateMedication(Medication medication) {
    DatabaseService.updateMedication(medication).then((_) {
      _refreshMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medication>>(
      future: _medicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No medications scheduled.'));
        } else {
          final medications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshMedications,
            child: ListView.builder(
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8.0),
                        _buildDosageControl(medication),
                        const SizedBox(height: 16.0),
                        _buildTimeSlider(medication),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildDosageControl(Medication medication) {
    final parts = medication.dosage.split(' ');
    int currentDose = 0;
    String unit = '';
    if (parts.length == 2) {
      currentDose = int.tryParse(parts[0]) ?? 0;
      unit = parts[1];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dosage: ${medication.dosage}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (currentDose > 0) {
                  final newDosage = '${currentDose - 1} $unit';
                  _updateMedication(medication.copyWith(dosage: newDosage));
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final newDosage = '${currentDose + 1} $unit';
                _updateMedication(medication.copyWith(dosage: newDosage));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSlider(Medication medication) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time: ${medication.time.format(context)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: medication.time.hour.toDouble(),
          min: 0,
          max: 23,
          divisions: 23,
          label: medication.time.format(context),
          onChanged: (double value) {
            final newTime = TimeOfDay(hour: value.toInt(), minute: medication.time.minute);
            _updateMedication(medication.copyWith(time: newTime));
          },
        ),
      ],
    );
  }
}
