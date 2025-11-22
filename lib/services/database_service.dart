import 'package:mongo_dart/mongo_dart.dart';
import 'package:medicine_dispersor/models/medication.dart';

class DatabaseService {
  static late Db _db;
  static late DbCollection _medicationCollection;

  // Replace with your actual MongoDB connection string
  // For a real app, store this securely (e.g., environment variables)
  static const String _mongoUri = 'mongodb+srv://mc1:mc1234@cluster0.wrjuysl.mongodb.net/?appName=Cluster0';

  static Future<void> connect() async {
    try {
      _db = await Db.create(_mongoUri);
      await _db.open();
      _medicationCollection = _db.collection('medications');
    } catch (e) {
      // Handle error appropriately
    }
  }

  static Future<void> close() async {
    await _db.close();
  }

  static Future<void> addMedication(Medication medication) async {
    await _medicationCollection.insert(medication.toJson());
  }

  static Future<List<Medication>> getMedications() async {
    final medications = await _medicationCollection.find().toList();
    return medications.map((json) => Medication.fromJson(json)).toList();
  }

  static Future<void> updateMedication(Medication medication) async {
    if (medication.id == null) {
      return;
    }
    await _medicationCollection.update(
      where.id(medication.id!),
      medication.toJson(),
    );
  }

  static Future<int> getMedicationsCount() async {
    return await _medicationCollection.count();
  }

  static Future<void> deleteMedication(ObjectId id) async {
    await _medicationCollection.remove(where.id(id));
  }
}
