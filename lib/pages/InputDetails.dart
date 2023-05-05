import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../model/PatientData.dart';
import '../utils/colors.dart';
import '../utils/images.dart';
import '../utils/string.dart';
import '../utils/variables.dart';
import 'package:flutter_textfield_validation/flutter_textfield_validation.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class InputDetails extends StatefulWidget {
  final PatientData? patientDetails;

  const InputDetails({Key? key, this.patientDetails}) : super(key: key);

  @override
  State<InputDetails> createState() => _InputDetailsState();
}

class _InputDetailsState extends State<InputDetails> {
  final storageReference = FirebaseStorage.instance.ref();
  // Reference get storageReference =>
  //     FirebaseStorage.instance.ref().child('images/');
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  final dbFormat = DateFormat('yyyy-MM-dd');
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final mobileNoController = TextEditingController();
  List<String>? toDaysList;
  final _formKey = GlobalKey<FormState>();
  String downloadUrlForPatient = '';
  String daysListResult = '';
  List<String>? finalDayList;
  final descriptionController = TextEditingController();
  final dateInputFromController = TextEditingController();
  final dateInputToController = TextEditingController();
  final timeInputFromController = TextEditingController();
  final timeInputToController = TextEditingController();
  final daysController = TextEditingController();
  String patientGender = male;
  String patientProfilePic = '';
  String base64DefaultImage = '';
  DateTime initialDay = DateTime.now();
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  DateTime finalDay = DateTime.now();
  TimeOfDay initialTime = TimeOfDay.now();
  TimeOfDay finalTime = TimeOfDay.now();
  String e = '';
  String f = '';
  DateTime? selectedDate;
  DateTime? selectedDate1;
  TimeOfDay? pickedTime1;
  TimeOfDay? pickedTime2;
  String outputTime1 = '';
  String outputTime2 = '';
  String fromTimeString = '';
  String toTimeString = '';
  String tempFromDate = '';
  String tempToDate = '';
  String tempFromTime = '';
  String tempToTime = '';
  int fromTimeValidation = 0;
  int toTimeValidation = 0;
  String fromStr='';
  String toStr='' ;
  // final dbFormat = DateFormat('yyyy-MM-dd');
  DateTime? parsedFromDate;
  DateTime? parsedToDate;
  DateTime? selectedfromDate;
  DateTime? selectedtoDate;
  double? screenWidth;
  double? screenHeight;
  String documentId = '';
  String tempDocumentId = '';
  List<String>? fromDaysList;
  Map<String, bool> days = {
    'Sunday': false,
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
  };
  final _picker = ImagePicker();
  Uint8List? patientPhoto;
  List<String> selectedDays = [];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void showSnackBarText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: tealColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedImage = await _picker.pickImage(source: source);

    if (pickedImage != null) {
      patientProfilePic =
          base64Encode(File(pickedImage.path).readAsBytesSync());
      setState(() {
        patientPhoto = base64Decode(patientProfilePic);
      });
    }
  }
  Future<void> addPatient() async {
    final user = FirebaseAuth.instance.currentUser;
    CollectionReference easio = firestore.collection('Patient');
    // Call the user's CollectionReference to add a new user
    return await easio.add({
      'doctor_id': user?.uid,
      'name': nameController.text,
      'age': ageController.text,
      'gender': patientGender,
      'phone': mobileNoController.text,
      'description': descriptionController.text,
      'sessionDays': daysController.text,
      'fromTime': outputTime1,
      'toTime': outputTime2,
      'patient_photo': downloadUrlForPatient,
      'patient_id': documentId,
      'fromToDate': '$outputDate1 to $outputDate2'
    }).then((value) async {
      documentId = value.id;

      // print(value.id);
      await easio.doc(documentId).update({'patient_id': documentId});
      if(!mounted){return ;}
      Navigator.pop(context);
      showSnackBarText(' success');
    }).catchError((error) {
      showSnackBarText("Failed to add user: $error");
    });
  }
  Future<void> updatePatientFields() async {
    final user = FirebaseAuth.instance.currentUser;
    CollectionReference easio = firestore.collection('Patient');
    // String documentId; // Assuming this variable holds the ID of the patient document

    // Check if documentId is not null, which indicates that this is an update operation
      // Conditionally update each field if its value has changed
      await easio.doc(tempDocumentId).update({
        'doctor_id': user?.uid,
        'name': nameController.text,
        'age': ageController.text,
        'gender': patientGender,
        'phone': mobileNoController.text,
        'description': descriptionController.text,
        'sessionDays': daysController.text,
        'fromTime': tempFromTime,
        'toTime': tempToTime,
        'patient_photo': downloadUrlForPatient,
        'patient_id': documentId,
        'fromToDate': '$tempFromDate to $tempToDate'
      }).then((value) async {

        await easio.doc(tempDocumentId).update({'patient_id': tempDocumentId});
        if(!mounted){return ;}
        Navigator.pop(context);
        showSnackBarText('Patient information updated successfully');
      }).catchError((error) {
        showSnackBarText("Failed to update patient information: $error");
      });

  }
  Future<void> fetchImage() async {
    if (docPhoto != "") {
      if(widget.patientDetails!.patientPhoto!= ""){
        http.Response response =  await http.get(Uri.parse(widget.patientDetails!.patientPhoto));
      setState(() {
        patientPhoto = response.bodyBytes;
      });}

    }

  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.patientDetails != null)  {
      updateEnabler=true;
      fetchImage();
      tempDocumentId=widget.patientDetails!.patientId;
      nameController.text = widget.patientDetails!.name;
      ageController.text = widget.patientDetails!.age;
      patientGender = widget.patientDetails!.gender;
      mobileNoController.text = widget.patientDetails!.phoneNumber;
      descriptionController.text = widget.patientDetails!.description;
      daysController.text = widget.patientDetails!.sessionDay;
      fromDaysList = daysController.text.split(',');
      for (String day in fromDaysList!) {
        if (days.containsKey(day)) {
          days[day] = true;
        }
      }
      String formatChange = widget.patientDetails!.fromTime.toString();
      DateFormat inputFormat = DateFormat('HH:mm');
      DateTime dateTime = inputFormat.parse(formatChange);
      DateFormat outputFormat = DateFormat('h:mm a');
      timeInputFromController.text = outputFormat.format(dateTime);

      String formatChangeTo = widget.patientDetails!.toTime.toString();
      DateFormat inputFormatTo = DateFormat('HH:mm');
      DateTime dateTimeTo = inputFormatTo.parse(formatChangeTo);
      DateFormat outputFormatTo = DateFormat('h:mm a');
      timeInputToController.text = outputFormatTo.format(dateTimeTo);
      final fromToDateStr =widget.patientDetails!.fromToDate;
      final fromToDateArr = fromToDateStr.split(' to ');
       fromStr = fromToDateArr[0];
       toStr = fromToDateArr[1];

      parsedFromDate = dbFormat.parse(fromStr);
      dateInputFromController.text =formatter.format(parsedFromDate!.toLocal());

      parsedToDate = dbFormat.parse(toStr);
      dateInputToController.text =formatter.format(parsedToDate!.toLocal());

    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title:  Padding(
          padding: EdgeInsets.fromLTRB(screenWidth!*0.16,0,0,0),
          child: const Text("Patient Details"),
        ),
        automaticallyImplyLeading: true,
        actions: [
          editButton(),
        ],
      ),
      body: patientDetailsForm(),
    );
  }

  patientDetailsForm() {
    return SingleChildScrollView(
      child: Padding(
        padding:  EdgeInsets.fromLTRB(screenWidth!*0.04,0,screenWidth!*0.04,0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: screenHeight! * 0.029,
              ),
              Stack(children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(screenWidth! * 0.34, 0, 0, 0),
                  // padding: const EdgeInsets.all(8.0),
                  child: ClipOval(
                    child: patientPhoto != null
                        ? Image.memory(

                            patientPhoto!,

                            width: screenWidth! * 0.26,
                            height: screenHeight! * 0.15,
                            fit: BoxFit.cover,

                      // frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
                      //   if (wasSynchronouslyLoaded) {
                      //     return child;
                      //   } else {
                      //     return Center(child: CircularProgressIndicator());
                      //   }
                      // },


                          )
                        : Image.asset(
                            genderNeutralImage,
                            width: screenWidth! * 0.29,
                            height: screenHeight! * 0.15,
                          ),
                  ),
                ),
                Positioned(
                  top: screenHeight! * 0.099,
                  bottom: 0,
                  right: 0,
                  left: screenWidth! * 0.510,
                  child: showCameraIcon
                      ? Container(
                          width: screenWidth! * 0.092,
                          height: screenHeight! * 0.056,
                          decoration: const BoxDecoration(
                            color: lightBlueColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            color: blackColor,
                            iconSize: 23,
                            onPressed: () {
                              bottomSheet();
                              // Do something when the button is pressed
                            },
                          ),
                        )
                      : Container(),
                ),
              ]),
              SizedBox(
                height: screenHeight! * 0.029,
              ),
              TextFormField(
                enabled: formEnabler,
                controller: nameController,
                autovalidateMode: _autoValidateMode,
                validator: (input) =>
                    input!.validateName() ? null : "Please enter valid name!!",
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Icon(
                      Icons.person,
                      color: greyColor,
                    ), // icon is 48px widget.
                  ),
                  labelText: name,
                  hintText: name,
                  // labelText: 'Age',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 4, color: greenAccentColor),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp('^[a-zA-Z ]*'),
                  ),
                ],
                textInputAction: TextInputAction.next,
              ),
              SizedBox(
                height: screenHeight! * 0.029,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: formEnabler,
                      controller: ageController,
                      autovalidateMode: _autoValidateMode,
                      validator: (value) {
                        if (int.tryParse(value!) == null ||
                            int.parse(value) > 150) {
                          return validAge;
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            Icons.search,
                            color: greyColor,
                          ), // icon is 48px widget.
                        ),
                        labelText: age,
                        hintText: age,
                        // labelText: 'Age',
                        border: OutlineInputBorder(
                          // borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: greenColor,
                            width: 3.0,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(width: screenWidth! * 0.024),
                  Expanded(
                    child: Container(
                      decoration: formEnabler
                          ? BoxDecoration(
                              color: white12Color,
                              border: Border.all(
                                width: 1,
                                color: black45Color,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            )
                          : BoxDecoration(
                              color: white12Color,
                              border: Border.all(
                                width: 1,
                                color: black12Color,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),

                      // Icon(Icons.transgender),
                      child: Row(
                        children: [
                          SizedBox(
                            height: screenHeight! * 0.09,
                            width: screenWidth! * 0.097,
                            child: const Icon(
                              MdiIcons.genderMaleFemale,
                              color: greyColor,
                            ),
                          ),
                          SizedBox(width: screenWidth! * 0.024),
                          formEnabler
                              ? DropdownButton<String>(
                                  // enableFeedback:formEnabler,
                                  isExpanded: false,
                                  value: patientGender,
                                  enableFeedback: true,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      patientGender = newValue!;
                                    });
                                  },

                                  items: <String>[
                                    male,
                                    female,
                                    others
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      enabled: formEnabler,
                                      value: value,
                                      child: Text(
                                        value,
                                      ),
                                    );
                                  }).toList(),
                                )
                              : DropdownButton<String>(
                                  // enableFeedback:formEnabler,
                                  isExpanded: false,
                                  value: patientGender,
                                  enableFeedback: true,
                                  onChanged: null,

                                  items: <String>[
                                    male,
                                    female,
                                    others
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      enabled: formEnabler,
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          color: black87Color,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight! * 0.029),
              TextFormField(
                enabled: formEnabler,
                controller: mobileNoController,
                autovalidateMode: _autoValidateMode,
                maxLength: 10,
                validator: (input) => input!.validatePhone() ? null : validPhone,
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Icon(
                      Icons.phone,
                      color: greyColor,
                    ), // icon is 48px widget.
                  ),
                  labelText: phoneNumber,
                  hintText: phoneNumber,
                  // labelText: 'Age',
                  border: OutlineInputBorder(
                    //borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: greenColor,
                      width: 3.0,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              //phonefield
              SizedBox(height: screenHeight! * 0.009),
              TextFormField(
                scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                maxLines: null,
                enabled: formEnabler,
                controller: descriptionController,
                decoration: const InputDecoration(
                  // contentPadding:  EdgeInsets.fromLTRB(0,60,0,0),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Icon(
                      Icons.description_outlined,
                      color: greyColor,
                    ), // icon is 48px widget.
                  ),
                  labelText: description,
                  hintText: description,

                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 3, color: greenAccentColor),
                  ),
                ),
                minLines: 1,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(
                height: screenHeight! * 0.029,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      enabled: formEnabler,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: from,
                        hintText: from,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      controller: dateInputFromController,
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        DateTimeRange? selectDate;
                        if (widget.patientDetails != null) {
                          fromDate = DateTime.parse(
                              fromStr);
                          toDate = DateTime.parse(
                              toStr);
                        } else if (selectDate != null) {
                          toDate = selectedDate!;
                        } else {
                          fromDate = DateTime.now();
                          toDate = DateTime.now();
                          }
                          if (selectedDate == null) {
                            selectDate = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                              initialDateRange:
                              DateTimeRange(start: fromDate, end: toDate),
                            );
                          } else {
                            selectDate = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                              initialDateRange: DateTimeRange(
                                  start: selectedfromDate!, end: selectedtoDate!),
                            );
                          }

                          // selectDate = await showDateRangePicker(
                          //   context: context,
                          //   firstDate: DateTime(1900),
                          //   lastDate: DateTime(2100),
                          //   initialDateRange: DateTimeRange(
                          //       start: fromDate, end: toDate),
                          // );

                          if (selectDate != null) {
                            selectedDate = DateTime.parse(
                                selectDate
                                    .toString()
                                    .split(' - ')
                                    .first);
                            selectedDate1 = DateTime.parse(
                                selectDate
                                    .toString()
                                    .split(' - ')
                                    .last);
                            setState(() {
                              selectedfromDate = selectedDate;
                              selectedtoDate = selectedDate1;
                              dateInputFromController.text =
                                  formatter.format(selectedfromDate!);
                              dateInputToController.text =
                                  formatter.format(selectedtoDate!);
                              DateTime dateTime = DateFormat('dd-MM-yyyy')
                                  .parse(dateInputFromController.text);
                              outputDate1 =
                                  DateFormat('yyyy-MM-dd').format(dateTime);
                              //send from controller as you will also receive in controller only
                              DateTime dateTime1 = DateFormat('dd-MM-yyyy')
                                  .parse(dateInputToController.text);
                              outputDate2 =
                                  DateFormat('yyyy-MM-dd').format(dateTime1);
                            });
                          }

                      },
                    ),
                  ),
                  SizedBox(width: screenWidth! * 0.024),
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      enabled: formEnabler,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: to,
                        hintText: to,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                      ),
                      controller: dateInputToController,
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        DateTimeRange? selectDate;
                        if (widget.patientDetails != null) {
                          fromDate = DateTime.parse(
                              fromStr);
                          toDate = DateTime.parse(
                              toStr);
                        } else if (selectDate != null) {
                          toDate = selectedDate!;
                        } else {
                        fromDate = DateTime.now();
                        toDate = DateTime.now();
                        }
                        if (selectedDate == null) {
                          selectDate = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            initialDateRange:
                                DateTimeRange(start: fromDate, end: toDate),
                          );
                        } else {
                          selectDate = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            initialDateRange: DateTimeRange(
                                start: selectedfromDate!, end: selectedtoDate!),
                          );
                        }

                        if (selectDate != null) {
                          selectedDate = DateTime.parse(
                              selectDate.toString().split(' - ').first);
                          selectedDate1 = DateTime.parse(
                              selectDate.toString().split(' - ').last);
                          setState(() {
                            selectedfromDate = selectedDate;
                            selectedtoDate = selectedDate1;
                            dateInputFromController.text =
                                formatter.format(selectedfromDate!);
                            dateInputToController.text =
                                formatter.format(selectedtoDate!);
                            DateTime dateTime = DateFormat('dd-MM-yyyy')
                                .parse(dateInputFromController.text);
                            outputDate1 =
                                DateFormat('yyyy-MM-dd').format(dateTime);
                            //send from controller as you will also receive in controller only
                            DateTime dateTime1 = DateFormat('dd-MM-yyyy')
                                .parse(dateInputToController.text);
                            outputDate2 =
                                DateFormat('yyyy-MM-dd').format(dateTime1);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: screenHeight! * 0.029,
              ),
              TextField(
                readOnly: true,
                enabled: formEnabler,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                    labelText: day,
                    hintText: selectDay,
                    hintStyle: TextStyle(color: black54Color),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: greyColor,
                      size: 20,
                    )),
                textInputAction: TextInputAction.newline,
                controller: daysController,
                maxLines: null,
                onChanged: (String text) {
                  if (text.length >= 4 &&
                      text.substring(text.length - 1) == ',') {
                    daysController.text = '$text\n';
                    daysController.selection = TextSelection.fromPosition(
                        TextPosition(offset: daysController.text.length));
                  }
                },
                onTap: () {
                  _showDaysDialog();
                  FocusScope.of(context).unfocus();
                },
              ),
              //Days
              SizedBox(
                height: screenHeight! * 0.029,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      enabled: formEnabler,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                          labelText: from,
                          hintText: from,
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(
                            Icons.access_time,
                            size: 25,
                          )),
                      controller: timeInputFromController,
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        TimeOfDay? pickTime;
                        if (widget.patientDetails != null) {
                          initialTime = TimeOfDay(
                            hour: int.parse(widget
                                .patientDetails!.fromTime
                                .split(":")
                                .first),
                            minute: int.parse(widget
                                .patientDetails!.fromTime
                                .split(":")
                                .last),
                          );
                        }
                        else {
                        initialTime = TimeOfDay.now(); // default value
                        }
                        if (pickedTime1 == null) {
                          pickTime = await showTimePicker(
                            initialTime: initialTime,
                            context: context,
                          );
                        } else {
                          pickTime = await showTimePicker(
                            initialTime: pickedTime1!,
                            context: context,
                          );
                        }

                        if (pickTime != null) {
                          pickedTime1 = pickTime;
                          fromTimeString = DateFormat.jm().format(
                            DateTime(2023, 1, 1, pickedTime1!.hour,
                                pickedTime1!.minute),
                          );
                          setState(() {
                            timeInputFromController.text = fromTimeString;
                            DateTime dateTime5 =
                                DateFormat('h:mm a').parse(fromTimeString);
                            outputTime1 = DateFormat('HH:mm').format(dateTime5);
                            fromTimeValidation =
                                int.parse(outputTime1.replaceAll(":", ""));
                          });
                        }
                        // pT=pickedTime1!;
                      },
                    ),
                  ),
                  SizedBox(width: screenWidth! * 0.024), //fromTime
                  Expanded(
                    child: TextField(
                      enabled: formEnabler,
                      readOnly: true,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: to,
                        hintText: to,
                        border: OutlineInputBorder(),
                        suffixIcon: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(Icons.access_time)),
                      ),
                      controller: timeInputToController,
                      onTap: () async {
                        FocusScope.of(context).unfocus();

                        TimeOfDay? pickTime;
                        if (widget.patientDetails != null) {
                          initialTime = TimeOfDay(
                            hour: int.parse(widget
                                .patientDetails!.toTime
                                .split(":")
                                .first),
                            minute: int.parse(widget
                                .patientDetails!.toTime
                                .split(":")
                                .last),
                          );
                        }
                        if (pickedTime1 != null) {
                          initialTime = pickedTime1!;
                        } else {
                          initialTime = TimeOfDay.now(); // default value
                        }
                        if (pickedTime2 == null) {
                          initialTime = initialTime;
                        } else {
                          initialTime = pickedTime2!;
                        }

                        pickTime = await showTimePicker(
                          initialTime: initialTime,
                          context: context,
                        );

                        if (pickTime != null) {
                          pickedTime2 = pickTime;
                          toTimeString = DateFormat.jm().format(DateTime(2023, 1,
                              1, pickedTime2!.hour, pickedTime2!.minute));
                          setState(() {
                            timeInputToController.text = toTimeString;
                            DateTime dateTime6 =
                                DateFormat('h:mm a').parse(toTimeString);
                            outputTime2 = DateFormat('HH:mm')
                                .format(dateTime6); //set the value of text field.
                            toTimeValidation =
                                int.parse(outputTime2.replaceAll(":", ""));
                          });
                        }
                      },
                    ),
                  ), //toTime
                ],
              ),
              // Time
              SizedBox(
                height: screenHeight! * 0.029,
              ),
              Visibility(
                visible: submit,
                child: Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                        const Size(260, 48),
                      ),
                    ),
                    child: const Text('submit'),
                    onPressed: () async {

                      if (patientPhoto != null) {
                        Reference ref=storageReference.child('images/$tempDocumentId.jpg');
                        UploadTask uploadTask =
                        
                            ref.putData(patientPhoto!);
                        TaskSnapshot snapshot =
                            await uploadTask.whenComplete(()=> {});
                        downloadUrlForPatient =
                            await snapshot.ref.getDownloadURL();
                      } else {
                        downloadUrlForPatient = "";
                      }
                      if (_formKey.currentState!.validate() &&
                          descriptionController.text.isNotEmpty &&
                          ageController.text.isNotEmpty &&
                          dateInputFromController.text.isNotEmpty &&
                          dateInputToController.text.isNotEmpty &&
                          timeInputFromController.text.isNotEmpty &&
                          timeInputToController.text.isNotEmpty) {
                        loginValidation();

                        if (fromTimeValidation - toTimeValidation < 0) {
                          if(updateEnabler==true){
                            showDialog(
                              context: context,
                              barrierDismissible: false, // prevent user from dismissing the dialog box
                              builder: (BuildContext context) {
                                return Dialog(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Row(
                                      children: const [
                                        CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: blackColor,
                                        ),
                                        SizedBox(width: 20),
                                        Text("Hold on a second"),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                            await updatePatientFields();

                          }
                          else{
                            showDialog(
                              context: context,
                              barrierDismissible: false, // prevent user from dismissing the dialog box
                              builder: (BuildContext context) {
                                return Dialog(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Row(
                                      children: const [
                                        CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: blackColor,
                                        ),
                                        SizedBox(width: 20),
                                        Text("Hold on a second"),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                            await addPatient();
                          }

                          if (!mounted) {
                            return;
                          }
                          Navigator.pop(context);
                        }
                        //   if (widget.patientDetails == null) {
                        //
                        //     Navigator.pop(context);
                        //   } else {
                        //
                        //
                        //     // print(u);
                        //     Navigator.pop(context);
                        //   }
                        // }
                        else {
                          if (!mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                invalidTime,
                                style: TextStyle(fontSize: 16),
                              ),
                              backgroundColor: tealColor,
                            ),
                          );
                        }
                      } else if (nameController.text.isEmpty) {
                        setState(() {
                          _autoValidateMode = AutovalidateMode.onUserInteraction;
                        });
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              emptyName,
                              style: TextStyle(fontSize: 16),
                            ),
                            backgroundColor: tealColor,
                          ),
                        );
                      } else if (ageController.text.isEmpty) {
                        setState(() {
                          _autoValidateMode = AutovalidateMode.onUserInteraction;
                        });
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              emptyAge,
                              style: TextStyle(fontSize: 16),
                            ),
                            backgroundColor: tealColor,
                          ),
                        );
                      } else if (mobileNoController.text.isEmpty) {
                        setState(() {
                          _autoValidateMode = AutovalidateMode.onUserInteraction;
                        });
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              emptyMobile,
                              style: TextStyle(fontSize: 16),
                            ),
                            backgroundColor: tealColor,
                          ),
                        );
                      } else if (descriptionController.text.isEmpty) {
                        setState(() {
                          _autoValidateMode = AutovalidateMode.onUserInteraction;
                        });
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              emptyDes,
                              style: TextStyle(fontSize: 16),
                            ),
                            backgroundColor: tealColor,
                          ),
                        );
                      } else if (dateInputFromController.text.isEmpty ||
                          dateInputToController.text.isEmpty) {
                        setState(() {
                          _autoValidateMode = AutovalidateMode.onUserInteraction;
                        });
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              emptyDate,
                              style: TextStyle(fontSize: 16),
                            ),
                            backgroundColor: tealColor,
                          ),
                        );
                      } else if (daysController.text.isEmpty) {
                        setState(
                          () {
                            _autoValidateMode =
                                AutovalidateMode.onUserInteraction;
                          },
                        );
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              emptyDays,
                              style: TextStyle(fontSize: 16),
                            ),
                            backgroundColor: tealColor,
                          ),
                        );
                      } else {
                        setState(() {
                          _autoValidateMode = AutovalidateMode.onUserInteraction;
                        });
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              emptyTime,
                              style: TextStyle(fontSize: 16),
                            ),
                            backgroundColor: tealColor,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: screenHeight! * 0.029,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDaysDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text(selectDay),
            content: SingleChildScrollView(
              child: Column(
                children:
                    // widget.patientDetails == null
                    //     ?
                    days.keys.map((String key) {
                  return CheckboxListTile(
                    title: Text(key),
                    value: days[key],
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (bool? value) {
                      setState(() {
                        days[key] = value!;
                      });
                    },
                  );
                }).toList(),

                //     : days.keys.map((String key) {
                //   return CheckboxListTile(
                //     title: Text(key),
                //     value: fromDaysList!.contains(key),
                //     controlAffinity: ListTileControlAffinity.leading,
                //     onChanged: (bool? value) {
                //       setState(() {
                //         if (value!) {
                //           fromDaysList!.add(key);
                //
                //           days[key] = true;
                //           days[key] = value;
                //         } else {
                //           fromDaysList!.remove(key);
                //
                //           days[key] = false;
                //         }
                //       });
                //     },
                //   );
                // }).toList(),
                //
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(cancel)),
              ElevatedButton(
                child: const Text(done),
                onPressed: () {
                  Navigator.of(context).pop();
                  toDaysList = days.keys.where((k) => days[k]!).toList();
                  // print(x);
                  daysListResult = toDaysList!.join(",");
                  finalDayList = daysListResult.split(",");
                  daysController.text = "";
                  for (int i = 0; i < finalDayList!.length; i++) {
                    daysController.text += finalDayList![i];
                    if (i < finalDayList!.length - 1) {
                      daysController.text += ",";
                    }
                  }

                  // print(x);
                  // print(daysController.text);

                  // saveDays(days);
                },
              ),
            ],
          );
        });
      },
    );
  }

  loginValidation() {
    DateTime dateTimee =
        DateFormat('dd-MM-yyyy').parse(dateInputFromController.text);
    tempFromDate = DateFormat('yyyy-MM-dd').format(dateTimee);

    DateTime dateTimee1 =
        DateFormat('dd-MM-yyyy').parse(dateInputToController.text);
    tempToDate = DateFormat('yyyy-MM-dd').format(dateTimee1);

    DateTime dateTimeee =
        DateFormat('h:mm a').parse(timeInputFromController.text);
    tempFromTime = DateFormat('HH:mm').format(dateTimeee);

    DateTime dateTimeee1 =
        DateFormat('h:mm a').parse(timeInputToController.text);
    tempToTime = DateFormat('HH:mm').format(dateTimeee1);

    if (outputTime1 != '' && outputTime2 != '') {
      fromTimeValidation = int.parse(outputTime1.replaceAll(":", ""));
      toTimeValidation = int.parse(outputTime2.replaceAll(":", ""));
    } else if (outputTime1 != '' && outputTime2 == '') {
      fromTimeValidation = int.parse(outputTime1.replaceAll(":", ""));
      toTimeValidation = int.parse(tempToTime.replaceAll(":", ""));
    } else if (outputTime1 == '' && outputTime2 != '') {
      fromTimeValidation = int.parse(tempFromTime.replaceAll(":", ""));
      toTimeValidation = int.parse(outputTime2.replaceAll(":", ""));
    } else {
      fromTimeValidation = int.parse(tempFromTime.replaceAll(":", ""));
      toTimeValidation = int.parse(tempToTime.replaceAll(":", ""));
    }
  }

  void bottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text(takePhoto),
                onTap: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text(choosePhoto),
                onTap: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: redColor,
                ),
                title: const Text(
                  removePhoto,
                  style: TextStyle(color: redColor),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    patientPhoto = null;
                  });
                },
              ),
            ],
          );
        });
  }

  Widget editButton() => Visibility(
        visible: editIconVisibility,
        child: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            submit = true;
            updateEnabler=true;
            formEnabler = true;
            sizedBoxHeight = screenHeight! * 0.828;
            showCameraIcon = true;

            setState(() {});
          },
        ),
      );
}
