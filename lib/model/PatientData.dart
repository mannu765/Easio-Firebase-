import 'package:cloud_firestore/cloud_firestore.dart';

class PatientData {
  String patientPhoto;
  String doctorId;
  String patientId;
  String name;
  String gender;
  String age;
  String phoneNumber;
  String description;
  String fromToDate;
  String sessionDay;
  String fromTime;
  String toTime;

  PatientData({
    required this.patientPhoto,
    required this.doctorId,
    required this.patientId,
    required this.name,
    required this.gender,
    required this.age,
    required this.phoneNumber,
    required this.description,
    required this.fromToDate,
    required this.sessionDay,
    required this.fromTime,
    required this.toTime,
  });

  // Factory method to create a Patient object from a Firestore document snapshot
  factory PatientData.fromSnapshot(QueryDocumentSnapshot snapshot) {
    return PatientData(
      patientPhoto: snapshot['patient_photo'],
      doctorId: snapshot['doctor_id'],
      patientId: snapshot['patient_id'],
      name: snapshot['name'],
      gender: snapshot['gender'],
      age: snapshot['age'],
      phoneNumber: snapshot['phone'],
      description: snapshot['description'],
      fromToDate: snapshot['fromToDate'],
      sessionDay: snapshot['sessionDays'],
      fromTime: snapshot['fromTime'],
      toTime: snapshot['toTime'],
    );
  }

}
