import 'package:flutter/material.dart';
import 'package:medicine_dispersor/models/medication.dart';
import 'package:medicine_dispersor/services/database_service.dart';
import 'package:medicine_dispersor/widgets/medication_container.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  MedicationListScreenState createState() => MedicationListScreenState();
}

class MedicationListScreenState extends State<MedicationListScreen> {
  Future<List<Medication>>? _medicationsFuture;

  @override
  void initState() {
    super.initState();
    refreshMedications();
  }

  Future<void> refreshMedications() async {
    setState(() {
      _medicationsFuture = DatabaseService.getMedications();
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
        } else {
          final medications = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: refreshMedications,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: List.generate(3, (index) {
                    final medication = index < medications.length ? medications[index] : null;
                    return MedicationContainer(
                      medication: medication,
                      containerNumber: index + 1,
                      onUpdate: refreshMedications,
                    );
                  }),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}