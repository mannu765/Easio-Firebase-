import 'dart:async';
import 'package:easio/pages/homescreen.dart';
import 'package:easio/utils/variables.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pinput/pinput.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../utils/images.dart';
import '../utils/string.dart';
import 'SplashScreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController phoneNo = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  String otpPin = " ";
  String sendOTP = 'Send OTP again in';
  String sendOTP1 = 'seconds';
  String bar = "|";
  String codeCountry = '+91';
  String verID = " ";
  String a = " ";
  bool visibleForLoginScreen = true;

  bool enableResend = false;
  Timer? timer;
  ValueNotifier<int> secondsRemaining1 = ValueNotifier<int>(40);
  bool isVerifyingOTP = false;
  bool isVerifyingNo = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  @override
  void initState() {
    // TODO: implement initState

    countryController.text = countryCode;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {



    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: login(),
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }

    Future<void> addDoctor() async {
    final user = FirebaseAuth.instance.currentUser;
    CollectionReference easio = firestore.collection('Doctor');
    // Call the user's CollectionReference to add a new user with the user's UID as the document ID
    DocumentReference userDocRef = easio.doc(user?.uid);
    DocumentSnapshot querySnapshot = await userDocRef.get();
    if (querySnapshot.exists) {
      if(!mounted){return ;}
      showSnackBarText('Welcome Back');
      return;
    }
    return userDocRef
        .set({
      'doctor_id': user?.uid,
      'time_stamp': DateTime.now(),
    })
        .then((value) => showSnackBarText("User Added"))
        .catchError((error) {
      if (!mounted) {
        return;
      }
          showSnackBarText("Failed to add user: $error");});
  }

  Future<void> getDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    // print("USer ID uis thadfjha ${user.uid}");


   await FirebaseFirestore.instance
        .collection('Doctor')
        .doc(user.uid)
        .get()
        .then((DocumentSnapshot docSnapshot) {
      if (docSnapshot.exists) {
        docPhoto=docSnapshot['image'];
        docName = docSnapshot['name'];
        docEmail = docSnapshot['email'];
        docUPI = docSnapshot['upi'];
        docPhoneNumber = docSnapshot['phone'];

        // print(docSnapshot['email']);
        // print(docSnapshot['upi']);
      } else {
        showSnackBarText('Document does not exist on Firestore');
      }
    }).catchError((error) {
      // showSnackBarText('Error getting document: $error');
    });
  }

  Future<void> _login() async {
    // perform login logic here
    sharedPref!.setBool(SplashScreenState.keyLogin, true);
    sharedPref!.setBool(SplashScreenState.detailLogin, true);
    sharedPref!.setString(SplashScreenState.doctorId, FirebaseAuth.instance.currentUser!.uid);

    isMobileLogin = true;
    if (!mounted) {
      return;
    }

    addDoctor();
    await getDoctorData();

if(!mounted){return ;}
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> verifyPhone(String number) async {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining1.value != 0) {
        secondsRemaining1.value--;
      } else {
        setState(() {
          enableResend = true;
        });
        timer!.cancel();
      }
    });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: number,
      // timeout: const Duration(seconds: 20),4564984746
      verificationCompleted: (PhoneAuthCredential credential) {
        showSnackBarText(authCompleted);
      },
      verificationFailed: (FirebaseAuthException e) {
        showSnackBarText(authFailed);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          // isVerifyingNo = false;
          visibleForLoginScreen = false;
          Navigator.pop(context);
          // !visibleForLoginScreen = true;
        });
        showSnackBarText(otpSent);
        verID = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> verifyOTP() async {
    try {
      await FirebaseAuth.instance.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verID,
          smsCode: otpPin,
        ),
      );
      // Sign in successful, navigate to next screen or perform other actions
      await _login();
    } catch (e) {
      // Sign in failed, show an error message to the user
      showSnackBarText(authFailed);
      Navigator.pop(context);
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

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    //check for signout options

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential

    return await FirebaseAuth.instance.signInWithCredential(credential);

  }

  login() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           SizedBox(
            height:  screenHeight! *0.059,
          ),
          const Text(
            easio,
            textAlign: TextAlign.start,
            style: TextStyle(
                color: black87Color, fontWeight: FontWeight.w500, fontSize: 36),
          ),
          Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
               SizedBox(
                height:  screenHeight! *0.21,
              ),
              const Center(
                child: Text(
                  login1,
                  style: TextStyle(
                      color: black87Color,
                      fontWeight: FontWeight.w500,
                      // fontSize: mediaQueryData!.size.width * 0.05,),
                      fontSize: 24),
                ),
              ),
               SizedBox(
                height:  screenHeight! *0.089,
              ),
              Visibility(
                visible: visibleForLoginScreen,
                child: Container(
                  height:  screenHeight! *0.081,
                  decoration: BoxDecoration(
                      border: Border.all(width: 1, color: greyColor),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       SizedBox(
                        width: screenWidth! *0.025,
                      ),
                      SizedBox(
                        width: screenWidth! *0.098,
                        child: TextField(
                          enabled: false,
                          controller: countryController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Text(
                        bar,
                        style:
                            const TextStyle(fontSize: 33, color:greyColor),
                      ),
                       SizedBox(
                        width: screenWidth! *0.025,
                      ),
                      Expanded(
                          child: TextField(
                        controller: phoneNo,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: phone,
                        ),
                      ))
                    ],
                  ),
                ),
              ),
              //forPhoneInput
               SizedBox(height:  screenHeight! *0.030),

              Visibility(
                visible: !visibleForLoginScreen,
                child: Pinput(
                  controller: otpController,
                  length: 6,
                  showCursor: true,
                  onCompleted: (pin) => otpPin = pin,
                ),
              ),
              //forCodeInput
              Row(

                children: [

                  Visibility(
                    visible: !visibleForLoginScreen,
                    child: TextButton(
                        onPressed: () {
                          setState(() {
                            visibleForLoginScreen = true;
                            // !visibleForLoginScreen = false;
                          });
                        },
                        child: const Text(editPhone)),
                  ),
                  // const SizedBox(width: 160,),
                  Expanded(
                    flex: 2,
                    child: Visibility(
                      visible: !visibleForLoginScreen,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: enableResend ? _resendCode : null,
                          child: const Text(resendCode),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: !visibleForLoginScreen,
                child: ValueListenableBuilder(
                  valueListenable: secondsRemaining1,
                  builder: (BuildContext context, int value, Widget? child) {
                    return Text(
                      '$sendOTP $value $sendOTP1',
                      style: const TextStyle(color: blackColor, fontSize: 12),
                    );
                  },
                ),
              ),
              //forCodeInput
               SizedBox(height:  screenHeight! *0.030),

              // SizedBox(
              //   width: 390,
              //   child: StatefulBuilder(
              //     builder: (BuildContext context, StateSetter setState) {
              //       return ElevatedButton(
              //         style: ElevatedButton.styleFrom(
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(20),
              //           ),
              //         ),
              //         onPressed: () async {
              //           if (visibleForLoginScreen == true) {
              //             if (phoneNo.text.length != 10) {
              //               showSnackBarText(validPhone);
              //             } else {
              //               verifyPhone('$countryCode${phoneNo.text}');
              //             }
              //           } else {
              //             setState(() {
              //               isVerifyingOTP = true;
              //             });
              //             await verifyOTP().then((_) {
              //               setState(() {
              //                 isVerifyingOTP = false;
              //               });
              //             });
              //
              //
              //           }
              //         },
              //         // child: isVerifyingOTP
              //         //     ? const CircularProgressIndicator(
              //         //   strokeWidth: 3,
              //         //         color: whiteColor,
              //         //       )
              //         child:  const Text(submitText),
              //       );
              //     },
              //   ),
              // ),




      ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () async {
          if (visibleForLoginScreen == true) {
            if(phoneNo.text.isEmpty){
              showSnackBarText(emptyFields);
            }
            else if (phoneNo.text.length != 10) {
              showSnackBarText(validPhone);
            } else {
              showDialog(
                context: context,
                barrierDismissible: false, // prevent user from dismissing the dialog box
                builder: (BuildContext context) {
                  return Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children:  [
                          const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: blackColor,
                          ),
                          SizedBox(width: screenWidth! *0.049),
                          const Text("Hold on a second"),
                        ],
                      ),
                    ),
                  );
                },
              );
              // setState(() {
              //   isVerifyingNo = true;
              // });
               verifyPhone('$countryCode${phoneNo.text}');

            }
          } else {
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
                        Text("Verifying OTP..."),
                      ],
                    ),
                  ),
                );
              },
            );
            setState(() {
              isVerifyingOTP = true;
            });
            await verifyOTP().then((_) {
              setState(() {
                isVerifyingOTP = false;
              });
               // Dismiss the dialog box
            });
          }
        },
        child: const Text(submitText),
      ),
      Visibility(
                visible: visibleForLoginScreen,
                child: const Text(
                  continueWith,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
               SizedBox(
                height:  screenHeight! *0.015,
              ),
              // Visibility(
              //   visible: visibleForLoginScreen,
              //   child: GestureDetector(
              //     child: SizedBox(
              //       height: 50,
              //       width: 70,
              //
              //       child: Image.asset("assets/ab.jpeg"),
              //     ),
              //     onTap: ()async {
              //       userCredential = await signInWithGoogle();
              //       if (userCredential!.user != null) {
              //         final navigator=  Navigator.of(context);
              //         sharedPref.setBool(SplashScreenState.keyLogin, true);
              //         sharedPref.setBool(SplashScreenState.detailLogin, false);
              //         isMobileLogin=false;
              //         navigator.pushReplacement(
              //           MaterialPageRoute(
              //             builder: (context) => const HomeScreen(),
              //           ),
              //         );
              //       }
              //
              //     },
              //
              //   ),
              // ),
              Visibility(
                visible: visibleForLoginScreen,
                child: GestureDetector(
                  onTap: () async {
                    await signInWithGoogle().then((value) async {
                      if (value.user != null) {
                        if (!mounted) {
                          return;
                        }
                        final navigator = Navigator.of(context);
                        addDoctor();
                        await getDoctorData();
                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );

                        isMobileLogin = false;
                        sharedPref!.setBool(SplashScreenState.keyLogin, true);
                        sharedPref!.setBool(SplashScreenState.detailLogin, false);

                      }
                    });

                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: blackColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: screenWidth! *0.93,

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(MdiIcons.google);
                        Image.asset(
                          googleIcon,
                          width: screenWidth! *0.098,
                          height: screenHeight! *0.059,
                        ),
                        const Text(signIn),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resendCode() {
    secondsRemaining1 = ValueNotifier<int>(60);
    enableResend = false;
    verifyPhone('$countryCode${phoneNo.text}');
  }

  @override
  dispose() {
    super.dispose();
  }
  Widget showProgressDialogWidget() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  [
            const CircularProgressIndicator(),
            SizedBox(width: screenWidth!*0.049),
            const Text(verifyingOTP),
          ],
        ),
      ),
    );
  }
}



