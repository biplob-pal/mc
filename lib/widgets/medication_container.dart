import 'package:flutter/material.dart';
import 'package:medicine_dispersor/models/medication.dart';
import 'package:medicine_dispersor/screens/add_medicine_screen.dart';

class MedicationContainer extends StatelessWidget {
  final Medication? medication;
  final int containerNumber;
  final VoidCallback onUpdate;

  const MedicationContainer({
    super.key,
    this.medication,
    required this.containerNumber,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: medication == null
          ? _buildAddMedication(context)
          : _buildMedicationDetails(context),
    );
  }

  Widget _buildAddMedication(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddMedicineScreen(),
          ),
        );
        if (result == true) {
          onUpdate();
        }
      },
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text('Add to Container $containerNumber'),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationDetails(BuildContext context) {
    final isDoseZero = (int.tryParse(medication!.dosage.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) == 0;

    return ListTile(
      contentPadding: const EdgeInsets.all(16.0),
      leading: CircleAvatar(
        backgroundColor: isDoseZero ? Colors.grey : Theme.of(context).primaryColor,
        child: const Icon(Icons.medical_services, color: Colors.white),
      ),
      title: Text(medication!.name, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Text('${medication!.dosage} - ${medication!.time.format(context)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMedicineScreen(medication: medication),
                ),
              );
              if (result == true) {
                onUpdate();
              }
            },
          ),
        ],
      ),
    );
  }
}
