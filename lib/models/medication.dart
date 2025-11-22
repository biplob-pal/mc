import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

class Medication {
  final ObjectId? id; // MongoDB ObjectId
  final String name;
  final String dosage;
  final TimeOfDay time;

  Medication({this.id, required this.name, required this.dosage, required this.time});

  // Convert a Medication object into a JSON object for MongoDB
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'dosage': dosage,
      'timeHour': time.hour,
      'timeMinute': time.minute,
    };
  }

  // Create a Medication object from a JSON object (from MongoDB)
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['_id'] as ObjectId?,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      time: TimeOfDay(hour: json['timeHour'] as int, minute: json['timeMinute'] as int),
    );
  }

  // Helper for creating a copy of the Medication with some changed fields
  Medication copyWith({
    ObjectId? id,
    String? name,
    String? dosage,
    TimeOfDay? time,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
    );
  }
}