import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/PatientData.dart';
import '../utils/variables.dart';

Future<List<PatientData>> getPatientData() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return [];

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('Patient')
      .where('doctor_id', isEqualTo: user.uid)
      .orderBy('name', descending: false)
      .get();

  List<PatientData> patientList = [];
  if (querySnapshot.docs.isNotEmpty) {
    for (QueryDocumentSnapshot patientSnapshot in querySnapshot.docs) {
      patientList.add(PatientData.fromSnapshot(patientSnapshot));
    }
  }
  // patientList.sort((a, b) => a.name.compareTo(b.name));

  return patientList;
}

Future<PatientData?> getParticularPatientData(String id) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return null;

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('Patient')
      .where('doctor_id', isEqualTo: user.uid)
      .where('patient_id', isEqualTo: id)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    QueryDocumentSnapshot patientSnapshot = querySnapshot.docs[0];
    return PatientData.fromSnapshot(patientSnapshot);
  }
  return null;
}

Future<List<PatientData>> getTodayPatientData() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return [];

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('Patient')
      .where('doctor_id', isEqualTo: user.uid)
      .get();

  List<PatientData> patientList = [];
  if (querySnapshot.docs.isNotEmpty) {
    for (QueryDocumentSnapshot patientSnapshot in querySnapshot.docs) {
      PatientData patientData = PatientData.fromSnapshot(patientSnapshot);
      List<String> sessionDaysList = patientData.sessionDay
          .split(','); // Split sessionDays string by comma
      if (sessionDaysList.contains(dayOfWeek)) {
        // Check if dayOfWeek is present in the sessionDaysList
        patientList.add(patientData);
      }
    }
  }
  patientList.sort((a, b) => a.name.compareTo(b.name));

  return patientList;
}

Future<List<PatientData>> ageFilter(List<Map<String, int>> result) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return [];

  List<PatientData> patientList = [];
  for (Map<String, int> ageRangeMap in result) {
    int? minAge = ageRangeMap['lower'];
    int? maxAge = ageRangeMap['upper'];
    String minAze = minAge?.toString() ?? '';
    String maxAze = maxAge?.toString() ?? '';

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('Patient')
        .where('doctor_id', isEqualTo: user.uid);

    if (minAge != null) {
      query = query.where('age', isGreaterThan: minAze);
    }
    if (maxAge != null) {
      query = query.where('age', isLessThan: maxAze);
    }

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await query.orderBy('age', descending: false).get();

    if (querySnapshot.docs.isNotEmpty) {
      for (QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
          in querySnapshot.docs) {
        patientList.add(PatientData.fromSnapshot(patientSnapshot));
      }
    }
  }

  // print(patientList.length);
  return patientList;
}

Future<List<PatientData>> daysFilter(List<Map<String, String>> daysList) async {
  final user = FirebaseAuth.instance.currentUser;
  List<String> dayValues = daysList.map((dayMap) => dayMap['day']!).toList();

  if (user == null) return [];

  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('Patient')
      .where('doctor_id', isEqualTo: user.uid)
      .get();

  List<PatientData> patientList = [];
  if (querySnapshot.docs.isNotEmpty) {
    for (QueryDocumentSnapshot patientSnapshot in querySnapshot.docs) {
      PatientData patientData = PatientData.fromSnapshot(patientSnapshot);
      List<String> sessionDaysList = patientData.sessionDay
          .split(','); // Split sessionDays string by comma

      for (final day in dayValues) {
        if (sessionDaysList.contains(day)) {
          patientList.add(patientData);
          break;
        }
      }
    }
  }
  patientList.sort((a, b) => a.name.compareTo(b.name));
  return patientList;
}

Future<List<PatientData>> dateFilter(
    DateTime? fromDate1, DateTime? toDate1) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return [];

  final querySnapshot = await FirebaseFirestore.instance
      .collection('Patient')
      .where('doctor_id', isEqualTo: user.uid)
      .get();

  List<PatientData> patientList = [];
  if (querySnapshot.docs.isNotEmpty) {
    for (QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
        in querySnapshot.docs) {
      final fromToDateStr = patientSnapshot.data()['fromToDate'];
      final fromToDateArr = fromToDateStr.split(' to ');
      final fromStr = fromToDateArr[0];
      final toStr = fromToDateArr[1];
      final fromDate = DateTime.parse(fromStr);
      final toDate = DateTime.parse(toStr);
      // print('fromStr $fromStr');
      // print('fromDate $fromDate');

      if (fromDate.isBefore(toDate1!) && toDate.isAfter(fromDate1!)) {
        patientList.add(PatientData.fromSnapshot(patientSnapshot));
      }
    }
  }
  // print(patientList.length);
  return patientList;
}

Future<List<PatientData>> filterPatients(
  List<Map<String, int>>? ageRanges,
  List<Map<String, String>>? daysList,
  DateTime? fromDate,
  DateTime? toDate,
) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return [];
  List<PatientData> patientList = [];
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('Patient')
      .where('doctor_id', isEqualTo: user.uid);

  // Filter by age ranges
  if (ageRanges!.isNotEmpty &&
      daysList!.isEmpty &&
      fromDate == DateTime.utc(1900, 1, 1) &&
      toDate == DateTime.utc(2100, 12, 31)) {
    // print('1');
    for (Map<String, int> ageRangeMap in ageRanges) {
      int? minAge = ageRangeMap['lower'];
      int? maxAge = ageRangeMap['upper'];
      String minAze = minAge?.toString() ?? '';
      String maxAze = maxAge?.toString() ?? '';
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('Patient')
          .where('doctor_id', isEqualTo: user.uid);

      if (minAge != null) {
        query = query.where('age', isGreaterThan: minAze);
      }
      if (maxAge != null) {
        query = query.where('age', isLessThan: maxAze);
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.orderBy('age', descending: false).get();

      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
            in querySnapshot.docs) {
          patientList.add(PatientData.fromSnapshot(patientSnapshot));
        }
      }
    }

    return patientList;
  } // 100

  // Filter by session days
  else if (daysList!.isNotEmpty &&
          ageRanges.isEmpty &&
          fromDate == DateTime.utc(1900, 1, 1) &&
      toDate == DateTime.utc(2100, 12, 31)) {
    // print('2');
    final dayValues = daysList.map((dayMap) => dayMap['day']!).toList();

    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      for (final QueryDocumentSnapshot patientSnapshot in querySnapshot.docs) {
        final patientData = PatientData.fromSnapshot(patientSnapshot);
        final sessionDaysList = patientData.sessionDay.split(',');

        for (final day in dayValues) {
          if (sessionDaysList.contains(day)) {
            patientList.add(patientData);
            break;
          }
        }
      }
    }
    // Sort patient list by name
    // patientList.sort((a, b) => a.name.compareTo(b.name));
    // return patientList;
  } //010
  // Filter by from and to dates
  else if (daysList.isEmpty &&
      ageRanges.isEmpty &&
      fromDate != DateTime.utc(1900, 1, 1) &&
      toDate != DateTime.utc(2100, 12, 31)) {
    // print('3');
    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
          in querySnapshot.docs) {
        final fromToDateStr = patientSnapshot.data()['fromToDate'];
        final fromToDateArr = fromToDateStr.split(' to ');
        final fromStr = fromToDateArr[0];
        final toStr = fromToDateArr[1];
        // print('fromStr $fromStr to $toStr');
        // print('fromDate $fromDate');
        final fromDateVal = DateTime.parse(fromStr);
        final toDateVal = DateTime.parse(toStr);



        if (fromDateVal.isBefore(toDate!) && toDateVal.isAfter(fromDate!)) {
          patientList.add(PatientData.fromSnapshot(patientSnapshot));

        }

      }
    }
    // Sort patient list by name
    // patientList.sort((a, b) => a.name.compareTo(b.name));
    // return patientList;
  } //001

  else if (daysList.isNotEmpty &&
      ageRanges.isEmpty &&
      fromDate != DateTime.utc(1900, 1, 1) &&
      toDate != DateTime.utc(2100, 12, 31)) {
    // print('4');
    final dayValues = daysList.map((dayMap) => dayMap['day']!).toList();
    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
          in querySnapshot.docs) {
        final fromToDateStr = patientSnapshot.data()['fromToDate'];
        final fromToDateArr = fromToDateStr.split(' to ');
        final fromStr = fromToDateArr[0];
        final toStr = fromToDateArr[1];
        // print('fromStr $fromStr to $toStr');
        // print('fromDate $fromDate');
        final fromDateVal = DateTime.parse(fromStr);
        final toDateVal = DateTime.parse(toStr);

        // print(fromDateVal);

        if ((fromDate == null) ||
            (fromDateVal.isBefore(toDate!) && toDateVal.isAfter(fromDate))) {
          final patientData = PatientData.fromSnapshot(patientSnapshot);
          final sessionDaysList = patientData.sessionDay.split(',');

          for (final day in dayValues) {
            if (sessionDaysList.contains(day)) {
              patientList.add(patientData);
              break;
            }
          }
        }
      }
    }
    // Sort patient list by name
    // patientList.sort((a, b) => a.name.compareTo(b.name));
    // return patientList;
  } //011.......

  else if (daysList.isEmpty &&
      ageRanges.isNotEmpty &&
      fromDate != DateTime.utc(1900, 1, 1) &&
      toDate != DateTime.utc(2100, 12, 31)) {
    // print('5');
    for (Map<String, int> ageRangeMap in ageRanges) {
      int? minAge = ageRangeMap['lower'];
      int? maxAge = ageRangeMap['upper'];
      String minAze = minAge?.toString() ?? '';
      String maxAze = maxAge?.toString() ?? '';
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('Patient')
          .where('doctor_id', isEqualTo: user.uid);

      if (minAge != null) {
        query = query.where('age', isGreaterThan: minAze);
      }
      if (maxAge != null) {
        query = query.where('age', isLessThan: maxAze);
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.orderBy('age', descending: false).get();

      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
            in querySnapshot.docs) {
          final fromToDateStr = patientSnapshot.data()['fromToDate'];
          final fromToDateArr = fromToDateStr.split(' to ');
          final fromStr = fromToDateArr[0];
          final toStr = fromToDateArr[1];
          // print('fromStrabc $fromStr to $toStr');
          // print('fromDate $fromDate');
          final fromDateVal = DateTime.parse(fromStr);
          final toDateVal = DateTime.parse(toStr);
          if ((fromDate == null) ||
              (fromDateVal.isBefore(toDate!) && toDateVal.isAfter(fromDate))) {
            patientList.add(PatientData.fromSnapshot(patientSnapshot));
          }

          // patientList.add(PatientData.fromSnapshot(patientSnapshot));
        }
        // print(patientList.length);
      }
    }
  } //101 .......

  else if(daysList.isNotEmpty &&
      ageRanges.isNotEmpty &&
      fromDate == DateTime.utc(1900, 1, 1) &&
      toDate == DateTime.utc(2100, 12, 31)){
    // print('544');
    final dayValues = daysList.map((dayMap) => dayMap['day']!).toList();
    for (Map<String, int> ageRangeMap in ageRanges) {
      int? minAge = ageRangeMap['lower'];
      int? maxAge = ageRangeMap['upper'];
      String minAze = minAge?.toString() ?? '';
      String maxAze = maxAge?.toString() ?? '';
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('Patient')
          .where('doctor_id', isEqualTo: user.uid);

      if (minAge != null) {
        query = query.where('age', isGreaterThan: minAze);
      }
      if (maxAge != null) {
        query = query.where('age', isLessThan: maxAze);
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await query.orderBy('age', descending: false).get();

      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
        in querySnapshot.docs) {
          final patientData = PatientData.fromSnapshot(patientSnapshot);
          final sessionDaysList = patientData.sessionDay.split(',');

          for (final day in dayValues) {
            if (sessionDaysList.contains(day)) {
              patientList.add(patientData);
              break;
            }
          }
        }
      }
    }


    // Sort patient list by name

  }//110





  else if(daysList.isNotEmpty &&
      ageRanges.isNotEmpty &&
      fromDate != DateTime.utc(1900, 1, 1) &&
      toDate != DateTime.utc(2100, 12, 31)){
    final dayValues = daysList.map((dayMap) => dayMap['day']!).toList();
    for (Map<String, int> ageRangeMap in ageRanges) {
      int? minAge = ageRangeMap['lower'];
      int? maxAge = ageRangeMap['upper'];
      String minAze = minAge?.toString() ?? '';
      String maxAze = maxAge?.toString() ?? '';
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('Patient')
          .where('doctor_id', isEqualTo: user.uid);

      if (minAge != null) {
        query = query.where('age', isGreaterThan: minAze);
      }
      if (maxAge != null) {
        query = query.where('age', isLessThan: maxAze);
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await query.orderBy('age', descending: false).get();

      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> patientSnapshot
        in querySnapshot.docs) {
          final fromToDateStr = patientSnapshot.data()['fromToDate'];
          final fromToDateArr = fromToDateStr.split(' to ');
          final fromStr = fromToDateArr[0];
          final toStr = fromToDateArr[1];
          // print('fromStrabc $fromStr to $toStr');
          // print('fromDate $fromDate');
          final fromDateVal = DateTime.parse(fromStr);
          final toDateVal = DateTime.parse(toStr);
          if ((fromDate == null) ||
              (fromDateVal.isBefore(toDate!) && toDateVal.isAfter(fromDate))) {
            final patientData = PatientData.fromSnapshot(patientSnapshot);
            final sessionDaysList = patientData.sessionDay.split(',');

            for (final day in dayValues) {
              if (sessionDaysList.contains(day)) {
                patientList.add(patientData);
                break;
              }
            }
          }

          // patientList.add(PatientData.fromSnapshot(patientSnapshot));
        }
        // print(patientList.length);
      }
    }




  }


  patientList.sort((a, b) => a.name.compareTo(b.name));
  return patientList;
}
