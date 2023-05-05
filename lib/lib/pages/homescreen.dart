import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easio/pages/LoginPage.dart';
import 'package:easio/utils/string.dart';
import 'package:easio/utils/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../db/databaseQuery.dart';
import '../model/PatientData.dart';
import '../utils/colors.dart';
import '../utils/images.dart';
import 'EditDocDetails.dart';
import 'InputDetails.dart';
import 'SplashScreen.dart';
import 'package:badges/badges.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final user = FirebaseAuth.instance.currentUser!;
  final user = FirebaseAuth.instance.currentUser;
  bool search = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchController1 = TextEditingController();
  final filterDateFrom = TextEditingController();
  final filterDateTo = TextEditingController();
  DateTime? filterSelectedDate;
  DateTime? filterSelectedDate1;
  int dateFilterCount = 0;
  int dayFilterCount = 0;
  int ageFilterCount = 0;
  DateTime filterSelectedFromDate1 = DateTime.utc(1900, 1, 1);
  DateTime filterSelectedToDate1 = DateTime.utc(2100, 12, 31);
  List<String> ageFilterKeys = [];
  List<String> dayFilterKeys = [];
  int badge = 0;

  String x = '';
  Uint8List? imgPatient;
  dynamic functionCall;
  String? detailsId;
  dynamic details;
  int? minAge;
  int? maxAge;

  Map<String, bool> agefilter = {
    '0-20': false,
    '21-40': false,
    '41-60': false,
    '61-80': false,
    '81-100': false,
    '101-150': false,
  };
  Map<String, bool> daysfilter = {
    'Sunday': false,
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
  };

  Future<void> deletePatient(String patientId) async {
    CollectionReference easio =
        FirebaseFirestore.instance.collection('Patient');

    try {
      // Delete the patient document with the given patientId
      await easio.doc(patientId).delete();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      showSnackBarText('Success: Patient deleted');
    } catch (error) {
      showSnackBarText('Failed to delete patient: $error');
    }
  }



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

  String? daysresult;

  void dateTap() async {
    FocusScope.of(context).unfocus();
    DateTimeRange? selectDate;
    selectDate = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
    );

    if (selectDate != null) {
      filterSelectedDate =
          DateTime.parse(selectDate.toString().split(' - ').first);
      filterSelectedDate1 =
          DateTime.parse(selectDate.toString().split(' - ').last);
      setState(() {
        filterSelectedFromDate1 = filterSelectedDate!;
        filterSelectedToDate1 = filterSelectedDate1!;
        filterDateFrom.text = formatter.format(filterSelectedFromDate1);
        filterDateTo.text = formatter.format(filterSelectedToDate1);
        DateTime dateTime = DateFormat('dd-MM-yyyy').parse(filterDateFrom.text);
        outputDate1 = DateFormat('yyyy-MM-dd').format(dateTime);
        //send from controller as you will also receive in controller only
        DateTime dateTime1 = DateFormat('dd-MM-yyyy').parse(filterDateTo.text);
        outputDate2 = DateFormat('yyyy-MM-dd').format(dateTime1);
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }
  Future<void> _sendMail() async {
    const String email = 'moh@gmail.com';
    const String subject = 'Hello , Guys';
    final String uri = 'mailto:$email?subject=${Uri.encodeComponent(subject)}';
    final Uri mailUri = Uri.parse(uri);

    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    } else {
      throw 'Could not launch $uri';
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    functionCall= getPatientData();
    super.initState();
    final now = DateTime.now();
    dayOfWeek = DateFormat('EEEE').format(now);
    // print(dayOfWeek);
    getPatientData();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(

      resizeToAvoidBottomInset: false,
      body: homeBody(),
    );
  }

  homeBody() {
    return Stack(
      children: [tabController()],
    );
  }

  tabController() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Expanded(
            child: TabBarView(
              // controller: tabController1,
              // physics: BouncingScrollPhysics(),
              children: [
                patientDetails(),
                todayAppointments(),
                settingsPage(),
              ],
            ),
          ), //
          bottomNavigationBar(),
        ],
      ),
    );
  }


  Widget _displayCard(PatientData patientDetails) {
    String withSpace = "${patientDetails.name} ";
    int spaceIndex = withSpace.indexOf(' ');
    String firstWord = withSpace.substring(0, spaceIndex);
    // x= patientDetails.patientPhoto;
    // fetchImage();
    // String firstLetterAfterSpace = patientDetails.patientname.substring(spaceIndex + 1, spaceIndex + 2);
    String displayedText = firstWord;
    return GestureDetector(
        child: Card(
          color: whiteColor,
          margin: const EdgeInsets.all(15),
          elevation: 5,
          // shadowColor: greyColor,
          shape: const RoundedRectangleBorder(
            // side: BorderSide(
            //   color: greyColor,
            // ),
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: screenHeight! * 0.01,
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 25, 0),
                      child: CircleAvatar(
                        backgroundColor: whiteColor,
                        radius: 35,
                        child: ClipOval(
                          child: patientDetails.patientPhoto != ''
                              ? Image.network(
                            patientDetails.patientPhoto,
                            loadingBuilder: (BuildContext context,
                                Widget child,
                                ImageChunkEvent? loadingProgress) {

                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            width: screenWidth! * 0.25,
                            height: screenHeight! * 0.24,
                            fit: BoxFit.cover,
                          )
                              : (patientDetails.gender != 'Female')
                              ? Image.asset(
                            maleImage,
                            width: screenWidth! * 0.24,
                            height: screenHeight! * 0.15,
                            fit: BoxFit.cover,
                          )
                              : Image.asset(
                            femaleImage,
                            width: screenWidth! * 0.24,
                            height: screenHeight! * 0.15,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ), //Image
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: screenHeight! * 0.01,
                          ),
                          Row(
                            children: [
                              patientDetails.gender != 'Male'
                                  ? const Icon(Icons.female_rounded)
                                  : const Icon(Icons.male_rounded),
                              SizedBox(
                                width: screenWidth! * 0.01,
                              ),
                              Center(
                                child: Text(
                                  displayedText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color: blackColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_in_talk,
                                color: greyColor,
                              ),
                              SizedBox(
                                width: screenWidth! * 0.01,
                              ),
                              Center(
                                child: Text(
                                  patientDetails.phoneNumber,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                      color: greyColor),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: greyColor,
                              ),
                              SizedBox(
                                width: screenWidth! * 0.01,
                              ),
                              Center(
                                child: Text(
                                  "${formatTime(patientDetails.fromTime)} to ${formatTime(patientDetails.toTime)}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      color: greyColor),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: screenHeight! * 0.03,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () async {
                          setState(() {
                            _makePhoneCall(
                                patientDetails.phoneNumber.toString());
                          });
                        },
                        icon: const Icon(
                          Icons.phone_forwarded,
                          size: 23,
                        )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: IconButton(
                          onPressed: () {
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text(delete),
                                content: const Text(confirmDelete),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, cancel),
                                    child: const Text(cancel),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12), // <-- Radius
                                      ),
                                    ),
                                    onPressed: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        // prevent user from dismissing the dialog box
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.all(20.0),
                                              child: Row(
                                                children:  [
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    color: blackColor,
                                                  ),
                                                  SizedBox(width:screenWidth! *0.049),
                                                  const Text("Hold on a second"),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      await  deletePatient(
                                          patientDetails.patientId);
                                      functionCall= getPatientData();
                                      setState(()  {

                                      });
                                      if (!mounted) {
                                        return;
                                      }
                                      Navigator.pop(context, delete);
                                    },
                                    child: const Text(delete),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline_outlined,
                            size: 25,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        onTap: () async {
          editIconVisibility = true;
          submit = false;
          formEnabler = false;
          sizedBoxHeight = screenHeight! * 0.88;
          showCameraIcon = false;
          detailsId = patientDetails.patientId;
          details = await getParticularPatientData(detailsId!);
          if (!mounted) {
            return;
          }
          await Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => InputDetails(patientDetails: details),
            ),
          )
              .then((value)  {
            if (result.isNotEmpty) {
              functionCall = filterPatients(result, daysList, filterSelectedFromDate1, filterSelectedToDate1);
            } else if (daysList.isNotEmpty) {
              functionCall = filterPatients(result,
                  daysList, filterSelectedFromDate1, filterSelectedToDate1);
            } else if (filterSelectedFromDate1 != DateTime.utc(1900, 1, 1) &&
                filterSelectedToDate1 != DateTime.utc(2100, 12, 31)) {
              functionCall = filterPatients(result,
                  daysList, filterSelectedFromDate1, filterSelectedToDate1);
            } else {
              functionCall =  getPatientData();
            }
            setState(() {});
          });
        }

    );
  }
  void bottomFilterSheet() {
    showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: transparentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        context: context,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: screenHeight! * 0.8,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      screenWidth! * 0.31, 0, 0, 0),
                                  child: const Text(
                                    "Filters",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      screenWidth! * 0.11, 0, 0, 0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: defaultColor,
                                    ),
                                    onPressed: () async
                                    {
                                      setState(()  {
                                        for (var key in agefilter.keys) {
                                          agefilter[key] = false;
                                        }
                                        for (var key in daysfilter.keys) {
                                          daysfilter[key] = false;
                                        }
                                        result=[];
                                        daysList=[];
                                        filterSelectedFromDate1 =
                                            DateTime.utc(1900, 1, 1);
                                        filterSelectedToDate1 =
                                            DateTime.utc(2100, 12, 31);
                                        filterDateFrom.clear();
                                        filterDateTo.clear();
                                        badge = 0;
                                        dateFilterCount = 0;
                                        dayFilterCount = 0;
                                        ageFilterCount = 0;


                                        if(!mounted){return ;}
                                        Navigator.pop(context);
                                        functionCall =
                                            getPatientData();
                                      });

                                    },
                                    child: const Text(clearFilter),
                                  ),
                                ), //clear filters
                              ],
                            ),
                            ExpansionTile(
                              title: Text("Age ($ageFilterCount)"),
                              // title: const Text("Age "),
                              children: [
                                StatefulBuilder(
                                    builder: (context, bottomSheetSetState) {
                                      return Column(children: [
                                        Column(
                                          children:
                                          agefilter.keys.map((String key) {
                                            return CheckboxListTile(
                                              title: Text(key),
                                              value: agefilter[key],
                                              controlAffinity:
                                              ListTileControlAffinity.leading,
                                              onChanged: (bool? value) {
                                                bottomSheetSetState(() {
                                                  agefilter[key] = value!;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ]);
                                    }),
                              ],
                            ),
                            ExpansionTile(
                              title: Text("Days ($dayFilterCount)"),
                              children: [
                                StatefulBuilder(
                                    builder: (context, bottomSheetSetState) {
                                      return Column(children: [
                                        Column(
                                          children:
                                          daysfilter.keys.map((String key) {
                                            return CheckboxListTile(
                                              title: Text(key),
                                              value: daysfilter[key],
                                              controlAffinity:
                                              ListTileControlAffinity.leading,
                                              onChanged: (bool? value) {
                                                bottomSheetSetState(() {
                                                  daysfilter[key] = value!;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ]);
                                    }),
                              ],
                            ),
                            ExpansionTile(
                              title: Text("Date ($dateFilterCount)"),
                              // title: const Text("Date"),
                              children: [
                                StatefulBuilder(
                                    builder: (context, bottomSheetSetState) {
                                      return Column(
                                        children: [
                                          SizedBox(
                                            height: screenHeight! * 0.4,
                                            child: SingleChildScrollView(
                                              child: Column(children: [
                                                Column(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets.fromLTRB(
                                                          15, 40, 0, 0),
                                                      child: SizedBox(
                                                        height:
                                                        screenHeight! * 0.09,
                                                        width: screenWidth! * 0.85,
                                                        child: TextField(
                                                          readOnly: true,
                                                          keyboardType:
                                                          TextInputType
                                                              .datetime,
                                                          decoration:
                                                          const InputDecoration(
                                                            hintText: from,
                                                            border:
                                                            OutlineInputBorder(),
                                                            suffixIcon: Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                size: 20),
                                                          ),
                                                          controller:
                                                          filterDateFrom,
                                                          onTap: () {
                                                            dateTap();
                                                          },
                                                        ),
                                                      ),
                                                    ), //fromdate
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets.fromLTRB(
                                                          20, 25, 0, 4),
                                                      child: SizedBox(
                                                        height:
                                                        screenHeight! * 0.09,
                                                        width: screenWidth! * 0.85,
                                                        child: TextField(
                                                          readOnly: true,
                                                          keyboardType:
                                                          TextInputType
                                                              .datetime,
                                                          decoration:
                                                          const InputDecoration(
                                                            hintText: to,
                                                            border:
                                                            OutlineInputBorder(),
                                                            suffixIcon: Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                size: 20),
                                                          ),
                                                          controller: filterDateTo,
                                                          onTap: () {
                                                            dateTap();
                                                          },
                                                        ),
                                                      ),
                                                    ), //toDate
                                                    Center(
                                                      child: ElevatedButton(
                                                          onPressed: () {
                                                            filterSelectedFromDate1 =
                                                                DateTime.utc(
                                                                    1900, 1, 1);
                                                            filterSelectedToDate1 =
                                                                DateTime.utc(
                                                                    2100, 12, 31);
                                                            filterDateFrom.clear();
                                                            filterDateTo.clear();
                                                          },
                                                          child: const Text(clear)),
                                                    ),
                                                  ],
                                                ),
                                              ]),
                                            ),
                                          ),
                                          SizedBox(
                                            height: screenHeight! * 0.04,
                                          ),
                                        ],
                                      );
                                    }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: defaultColor,
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              agefilter.forEach((key, value) {
                                if (ageFilterKeys.contains(key)) {
                                  agefilter[key] = true;
                                } else {
                                  agefilter[key] = false;
                                }
                              });
                              daysfilter.forEach((key, value) {
                                if (dayFilterKeys.contains(key)) {
                                  daysfilter[key] = true;
                                } else {
                                  daysfilter[key] = false;
                                }
                              });

                              Navigator.pop(context);
                            });
                          },
                          child: const Text(cancel),
                        ),
                        SizedBox(
                          width: screenWidth! * 0.04,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            ageFilterKeys = agefilter.keys
                                .where((k) => agefilter[k]!)
                                .toList();
                            dayFilterKeys = daysfilter.keys
                                .where((k) => daysfilter[k]!)
                                .toList();
                            daysList = dayFilterKeys
                                .map((day) => {'day': day})
                                .toList();

                            List<Map<String, int>> listOfDicts = [];
                            for (var range in ageFilterKeys) {
                              var splitRange = range.split("-");
                              int lower = int.parse(splitRange[0]);
                              int upper = int.parse(splitRange[1]);
                              listOfDicts.add({'lower': lower, 'upper': upper});
                            }

                            result = listOfDicts;

                            if (result.isNotEmpty &&
                                daysList.isNotEmpty &&
                                filterSelectedFromDate1 !=
                                    DateTime.utc(1900, 1, 1)) {
                              badge = 3;
                              ageFilterCount = result.length;
                              dayFilterCount = daysList.length;
                              dateFilterCount = 1;
                            } else if (result.isNotEmpty &&
                                daysList.isNotEmpty &&
                                filterSelectedFromDate1 ==
                                    DateTime.utc(1900, 1, 1)) {
                              badge = 2;
                              ageFilterCount = result.length;
                              dayFilterCount = daysList.length;
                              dateFilterCount = 0;
                            } else if (result.isNotEmpty &&
                                daysList.isEmpty &&
                                filterSelectedFromDate1 !=
                                    DateTime.utc(1900, 1, 1)) {
                              badge = 2;
                              ageFilterCount = result.length;
                              dayFilterCount = daysList.length;
                              dateFilterCount = 1;
                            } else if (result.isEmpty &&
                                daysList.isNotEmpty &&
                                filterSelectedFromDate1 !=
                                    DateTime.utc(1900, 1, 1)) {
                              badge = 2;
                              ageFilterCount = result.length;
                              dayFilterCount = daysList.length;
                              dateFilterCount = 1;
                            } else if (result.isNotEmpty &&
                                daysList.isEmpty &&
                                filterSelectedFromDate1 ==
                                    DateTime.utc(1900, 1, 1)) {
                              badge = 1;
                              ageFilterCount = result.length;
                              dayFilterCount = daysList.length;
                              dateFilterCount = 0;
                            } else if (result.isEmpty &&
                                daysList.isNotEmpty &&
                                filterSelectedFromDate1 ==
                                    DateTime.utc(1900, 1, 1)) {
                              badge = 1;
                              ageFilterCount = result.length;
                              dayFilterCount = daysList.length;
                              dateFilterCount = 0;
                            } else if (result.isEmpty &&
                                daysList.isEmpty &&
                                filterSelectedFromDate1 !=
                                    DateTime.utc(1900, 1, 1)) {
                              badge = 1;
                              ageFilterCount = result.length;
                              dayFilterCount = daysList.length;
                              dateFilterCount = 1;
                            } else {
                              badge = 0;
                              ageFilterCount = 0;
                              dayFilterCount = 0;
                            }

                            Navigator.pop(context);

                            if (daysList.isEmpty &&
                                result.isEmpty &&
                                filterSelectedFromDate1 ==
                                    DateTime.utc(1900, 1, 1) &&
                                filterSelectedToDate1 ==
                                    DateTime.utc(2100, 12, 31)) {
                              functionCall=  getPatientData();
                            } else {
// print('$filterSelectedFromDate1 to $filterSelectedToDate1');
                              functionCall= filterPatients(result, daysList, filterSelectedFromDate1, filterSelectedToDate1);
                            }

                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: defaultColor,
                          ),
                          child: const Text(apply),
                        ), //applyFilterButton
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        });
  }
  todayAppointments() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
          child: Center(
            child: Text(
              todaysAppointments,
            ),
          ),
        ),
        actions: [
          IconButton(
              onPressed: () async {
                setState(() {
                  search = true;
                });
                await getPatientData();
              },
              icon: const Icon(Icons.search))
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: screenHeight! * 0.022,
              ),
              Visibility(
                visible: search,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: greyColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: false,
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchController.value =
                                  _searchController.value.copyWith(
                                    text: value,
                                    selection: TextSelection.collapsed(
                                        offset: value.length),
                                  );
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: searchPatients,
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            search = false;
                            _searchController.clear();
                          });
                        },
                        icon: const Icon(Icons.cancel_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              // searchbar
              SingleChildScrollView(
                child: SizedBox(
                  height: screenHeight! * 0.81,
                  child: FutureBuilder(
                      future: getTodayPatientData(),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<PatientData>> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return Column(
                              children: [
                                Padding(
                                  padding:
                                   EdgeInsets.fromLTRB(0, screenHeight!*0.15, screenWidth!*0.28, 0),
                                  child: Center(
                                      child: Lottie.asset(
                                        'assets/animations/noappointment.json',
                                        width: screenWidth! * 0.49,
                                        height: screenHeight! * 0.29,
                                        fit: BoxFit.cover,
                                      )),
                                ),
                                const Text(noAppointments),
                              ],
                            );
                          }
                        }
                        if (snapshot.hasData) {
                          List<PatientData> filteredPatients = snapshot.data!
                              .where((patient) => patient.name
                              .toLowerCase()
                              .contains(
                              _searchController.text.toLowerCase()))
                              .toList();
                          if (filteredPatients.isEmpty) {
                            return const Center(
                              child: Text(noPatients),
                            );
                          } else {
                            return ListView.builder(
                              itemCount: filteredPatients.length,
                              itemBuilder: (context, index) {
                                return _displayCard(filteredPatients[index]);
                              },
                            );
                          }
                        } else {
                          return const Center(
                            child: Text(noPatientsToday),
                          );
                        }
                      }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  patientDetails() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: screenHeight! * 0.23,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  easio,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                background: Image.asset(
                  appBarImage,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(.7),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 0, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: greyColor.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController1,
                                onChanged: (value) {
                                  setState(() {
                                    _searchController1.value =
                                        _searchController1.value.copyWith(
                                      text: value,
                                      selection: TextSelection.collapsed(
                                          offset: value.length),
                                    );
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: searchPatients,
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: blackColor,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchController1.clear();
                                  FocusScope.of(context).unfocus();
                                });
                              },
                              icon: const Icon(Icons.cancel_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 5, 0),
                    child: Badge(
                      badgeColor: defaultColor,
                      badgeContent: Text("$badge"),
                      position: BadgePosition.topEnd(top: -6, end: -4),
                      child: FloatingActionButton.small(
                        heroTag: null,
                        backgroundColor: grey300Color,
                        onPressed: () {
                          bottomFilterSheet();
                        },
                        child: const Icon(
                          Icons.filter_list,
                          size: 25,
                          color: blackColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<PatientData>>(


              // future: daysFilter(daysList),
               future: functionCall,
              // future: dateFilter(filterSelectedFromDate1, filterSelectedToDate1),
              // future: getPatientData(),
              // future: filterPatients(result,daysList,filterSelectedFromDate1, filterSelectedToDate1),
              // future: ageFilter(result),
              builder: (BuildContext context,
                  AsyncSnapshot<List<PatientData>> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return SliverFillRemaining(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Center(
                              child: Lottie.asset(
                                'assets/animations/nodata.json',
                                width: screenWidth! * 0.61,
                                height: screenHeight! * 0.35,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(
                              height: screenHeight! * 0.044,
                            ),
                            const Text(noData),
                          ],
                        ),
                      ),
                    );
                  }
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (ageFilterKeys != []) {
                        // print(snapshot.data);
                        PatientData patient = snapshot.data![index];
                        String name = patient.name;
                        // print(name);
                        if (name
                            .toLowerCase()
                            .contains(_searchController1.text.toLowerCase())) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _displayCard(patient),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      } else {
                        return const Center(
                          child: Text(
                            noDesiredAge,
                          ),
                        );
                      }
                    },
                    childCount: snapshot.hasData ? snapshot.data!.length : 0,
                  ),
                );
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () async {
                submit = true;
                updateEnabler = false;
                formEnabler = true;
                showCameraIcon = true;
                FocusScope.of(context).unfocus();
                await Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => const InputDetails(),
                  ),
                )
                    .then(
                  (value)   {
                     functionCall=getPatientData();
                    setState(() {

                    });
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  settingsPage() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              screenWidth! * 0.022, 0, screenWidth! * 0.024, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth! * 0.056, screenHeight! * 0.041, 0, 0),
                child: SizedBox(
                  height: screenHeight! * 0.126,
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Container(
                          // margin: const EdgeInsets.only(bottom: 10),
                          height: screenHeight! * 0.120,
                          width: screenWidth! * 0.215,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: docPhoto != ""
                              ? Image.network(
                                  docPhoto!,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  width: screenWidth! * 0.23,
                                  height: screenHeight! * 0.15,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  genderNeutralImage,
                                  width: screenWidth! * 0.24,
                                  height: screenHeight! * 0.24,
                                ),
                        ),
                      ),
                      SizedBox(
                        width: screenWidth! * 0.059,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline),
                              SizedBox(width: screenWidth!*0.024,),
                              Text(docName),
                            ],
                          ),

                          Row(
                            children: [
                              Container(
                                child: isMobileLogin == true
                                    ? const Icon(Icons.phone_outlined)
                                    : const Icon(Icons.email_outlined),
                              ),
                              SizedBox(width: screenWidth!*0.024,),
                              Container(
                                child: isMobileLogin == true
                                    ? Text(" ${user?.phoneNumber}")
                                    : Text('${user!.email}'),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                child: isMobileLogin == true
                                    ? const Icon(Icons.email_outlined)
                                    : const Icon(Icons.phone_outlined),
                              ),
                              SizedBox(width: screenWidth!*0.024,),
                              Container(
                                child: isMobileLogin == true
                                    ? Text(docEmail)
                                    : Text(docPhoneNumber),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(screenWidth! * 0.32, 0, 0, 0),
                child: TextButton(
                    onPressed: () async {
                      // docDetails= PhysioDatabase.db.fetchCredData(cred);
                      await Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) => const EditDocDetails(),
                        ),
                      )
                          .then((value) {
                        setState(() {});
                      });
                    },
                    child: const Text(editProfile)),
              ),
              SizedBox(
                height: screenHeight! * 0.029,
              ),
              GestureDetector(
                child: SizedBox(
                  height: screenHeight! * 0.031,
                  // color:redColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Icon(
                          Icons.info_outline,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          aboutUs,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          greaterIcon,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  // await Navigator.of(context)
                  //     .push(
                  //   MaterialPageRoute(
                  //     builder: (context) => const ChangePassword(),
                  //   ),
                  // )
                  //     .then((value) {
                  //   setState(() {});
                  // });
                },
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              SizedBox(
                height: screenHeight! * 0.031,
                // color:redColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.share_outlined,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        shareApp,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        greaterIcon,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              SizedBox(
                height: screenHeight! * 0.031,
                // color:redColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.star_border_purple500_sharp,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        rateUs,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        greaterIcon,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              SizedBox(
                height: screenHeight! * 0.031,
                // color:redColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.bug_report_outlined,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        reportBug,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        greaterIcon,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              SizedBox(
                height: screenHeight! * 0.031,
                // color:redColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.family_restroom_sharp,
                        size: 24,
                      ),
                    ),
                    // SizedBox(width: 8),
                    Expanded(
                      flex: 7,
                      child: Text(
                        invite,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    // SizedBox(width: 192),
                    Expanded(
                      flex: 1,
                      child: Text(
                        greaterIcon,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              SizedBox(
                height: screenHeight! * 0.031,
                // color:redColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.app_registration_outlined,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        share,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        greaterIcon,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              SizedBox(
                height: screenHeight! * 0.031,
                // color:redColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 24,
                      ),
                    ),
                    // SizedBox(width: 8),
                    Expanded(
                      flex: 7,
                      child: Text(
                        suggestFeature,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    // SizedBox(width: 192),
                    Expanded(
                      flex: 1,
                      child: Text(
                        greaterIcon,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              GestureDetector(
                child: SizedBox(
                  height: screenHeight! * 0.031,
                  // color:redColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Icon(
                          Icons.mail_outline,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          contactUs,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          greaterIcon,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: (){
                  _sendMail();
                },
              ),
              Divider(
                indent: screenWidth! * 0.19,
                endIndent: screenWidth! * 0.079,
                height: screenHeight! * 0.029,
                // Adjust the height of the divider
                color: greyColor,
                // Set the color of the divider
                thickness: 1, // Set the thickness of the divider
              ),
              GestureDetector(
                child: SizedBox(
                  height: screenHeight! * 0.031,
                  // color:redColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Icon(
                          Icons.logout,
                          size: 24,
                        ),
                      ),
                      // SizedBox(width: 8),
                      Expanded(
                        flex: 7,
                        child: Text(
                          logout,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      // SizedBox(width: 192),
                      Expanded(
                        flex: 1,
                        child: Text(
                          greaterIcon,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () async {

                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text(logout),
                      content: const Text(logoutConfirm),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, cancel),
                          child: const Text(cancel),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // <-- Radius
                            ),
                          ),
                          onPressed: ()async  {

                            circularProgressIndicator();
                            sharedPref!
                                .setBool(SplashScreenState.detailLogin, false);
                            sharedPref!
                                .setString(SplashScreenState.doctorId, '');
                            await _logout();

                          },
                          // async {
                          //   var sharedPref =
                          //   await SharedPreferences.getInstance();
                          //   sharedPref.setBool(
                          //       SplashScreenState.keyLogin, false);
                          //   Navigator.pushReplacement(context,
                          //       MaterialPageRoute(builder: (context) {
                          //         return const MyLoginPage();
                          //       }));
                          //
                          //   name = null;
                          //   mail = null;
                          //   email.clear();
                          //   pass.clear();
                          // },
                          child: const Text(logout),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Divider(
              //   indent: screenWidth! * 0.19,
              //   endIndent: screenWidth! * 0.079,
              //   height: screenHeight! * 0.029,
              //   // Adjust the height of the divider
              //   color: greyColor,
              //   // Set the color of the divider
              //   thickness: 1, // Set the thickness of the divider
              // ),
            ],
          ),
        ),
      ),
    );
    // floatingActionButton: ,
  }

  bottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(color: defaultColor),
      height: screenHeight! * 0.088,
      child: TabBar(
        indicatorWeight: 5,
        indicatorColor: blackColor,
        indicatorSize: TabBarIndicatorSize.tab,
        unselectedLabelColor: white54Color,
        labelColor: whiteColor,

        labelStyle: const TextStyle(
          color: blackColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),

        indicator: BoxDecoration(
          color: teal300Color,
        ),

        // controller: TabController(length: 2,vsync:  vsync),
        tabs: const [
          Tab(
            icon: Icon(Icons.book_outlined),
            text: patients,
          ),
          Tab(
            icon: Icon(
              Icons.calendar_today_outlined,
              size: 20,
            ),
            text: appointments,
          ),
          Tab(
            icon: Icon(Icons.settings_outlined),
            text: settings,
          )
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    sharedPref!.setBool(SplashScreenState.keyLogin, false);

    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    allClear();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false);
  }

  void allClear() {
    docNameController.clear();
    docEmailController.clear();
    docPhoneNumberController.clear();
    docUPIController.clear();
    docName = '';
    docEmail = '';
    docUPI = '';
    docPhoneNumber = '';
    docPhoto = '';
  }

  void circularProgressIndicator() {
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
  }



  formatTime(String time1) {
    DateTime time = DateFormat('HH:mm')
        .parse(time1); // parse the string to a DateTime object
    String time12 = DateFormat('h:mm a').format(time);
    return time12;
  }

  void fetchImage() async {
    if (x != '') {
      http.Response response = await http.get(Uri.parse(x));
      setState(() {
        imgPatient = response.bodyBytes;
      });
    }
  }
}
