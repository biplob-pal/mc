import 'package:flutter/material.dart';
import 'package:medicine_dispersor/models/medication.dart';
import 'package:medicine_dispersor/services/database_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medication? medication;

  const AddMedicineScreen({super.key, this.medication});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _dosage;
  late TimeOfDay _time;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _name = widget.medication?.name ?? '';
    _dosage = widget.medication?.dosage ?? '';
    _time = widget.medication?.time ?? TimeOfDay.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newMedication = Medication(
        id: widget.medication?.id,
        name: _name,
        dosage: _dosage,
        time: _time,
      );
      if (widget.medication == null) {
        await DatabaseService.addMedication(newMedication);
      } else {
        await DatabaseService.updateMedication(newMedication);
      }
      Navigator.pop(context, true); // Pass true to indicate a successful save
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication == null ? 'Add Medicine' : 'Edit Medicine'),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    icon: Icon(Icons.medication),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the medicine name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  initialValue: _dosage,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    icon: Icon(Icons.local_drink),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the dosage';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _dosage = value!;
                  },
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Time: ${_time.format(context)}'),
                  onTap: () => _selectTime(context),
                ),
                const SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: _saveMedication,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
