import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easio/pages/LoginPage.dart';
import 'package:easio/pages/HomeScreen.dart';
import 'package:easio/utils/string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/colors.dart';
import '../utils/images.dart';
import '../utils/variables.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  var splashTime = 3;
  static const String keyLogin = login1;
  static const String detailLogin = detaiLogin;
  static const String doctorId = 'doctorId';

  Future<void> getDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    // print("USer ID uis  ${user.uid}");

    await FirebaseFirestore.instance
        .collection('Doctor')
        .doc(user.uid)
        .get()
        .then((DocumentSnapshot docSnapshot) {
      if (docSnapshot.exists) {
        docPhoto = docSnapshot['image'];
        docName = docSnapshot['name'];
        docEmail = docSnapshot['email'];
        docUPI = docSnapshot['upi'];
        docPhoneNumber = docSnapshot['phone'];
      } else {
        showSnackBarText('Document does not exist on Firestore');
      }
    }).catchError((error) {
      // showSnackBarText('Error getting document: $error');
    });
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

  @override
  void initState() {
    whereTo();
    super.initState();
  }

  void whereTo() async {
    var isLoggedIn = sharedPref!.getBool(keyLogin);
    var isMode = sharedPref!.getBool(detailLogin);


    docPhoto ??= '';

    if (isMode != false) {
      isMobileLogin = true;
    } else {
      isMobileLogin = false;
    }
    // print(isMobileLogin);

    Future.delayed(Duration(seconds: splashTime), () async {
      if (isLoggedIn == true) {
        await getDoctorData();
        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const HomeScreen();
            },
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const LoginPage();
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: splashScreen(),
    );
  }

  splashScreen() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        //vertically align center
        children: <Widget>[
          SizedBox(
            height: screenHeight! * 0.22,
            width: screenWidth! * 0.37,
            child: Lottie.asset(lottieAnimation),
          ),
          const Text(
            easio,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
