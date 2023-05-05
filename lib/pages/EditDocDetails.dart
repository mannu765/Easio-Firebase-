import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import '../utils/images.dart';
import '../utils/string.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/variables.dart';
import 'package:http/http.dart' as http;

class EditDocDetails extends StatefulWidget {
  const EditDocDetails({Key? key}) : super(key: key);

  @override
  State<EditDocDetails> createState() => _EditDocDetailsState();
}

class _EditDocDetailsState extends State<EditDocDetails> {
  final storageReference = FirebaseStorage.instance.ref();
  // Reference get storageReference =>
  //     FirebaseStorage.instance.ref().child('images');
  String doctorPhoto='';
  String base64Image2='';

  final _picker = ImagePicker();
  Uint8List? docImage;
  final user = FirebaseAuth.instance.currentUser;
  bool disableEmail = true;
  bool disableNo = true;
  String downloadUrl='';
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  void showSnackBarText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: defaultColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> setUser() async {
    final user = FirebaseAuth.instance.currentUser;
    CollectionReference easio = firestore.collection('Doctor');

    DocumentReference userDocRef = easio.doc(user?.uid);

    if (user?.uid != null) {
      // Make sure user ID is not null
      return userDocRef.set({
        'doctor_id': user!.uid,
        'email': docEmailController.text,
        'name': docNameController.text,
        'upi': docUPIController.text,
        'phone':docPhoneNumberController.text,
        'image':downloadUrl,
      }).then((value) {
        docPhoto=downloadUrl;
         docName =docNameController.text;
          docEmail =docEmailController.text;
         docUPI=docUPIController.text;
         docPhoneNumber=docPhoneNumberController.text;
        showSnackBarText("User data updated");
        Navigator.pop(context);
      }).catchError((error) {
        if (!mounted) {
          return;
        }
        showSnackBarText("Failed to update user data: $error");
      },);
    } else {
      showSnackBarText("Failed to update user data: User ID is null");
    }
  }

  Future<void> getDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
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

  Future<void> fetchImage() async {
    if (docPhoto != "") {
      http.Response response = await http.get(Uri.parse(docPhoto!));
      setState(() {
        docImage = response.bodyBytes;
      });
    }
  }
  @override
  void initState() {
        fetchImage();
    docNameController.text = docName;
    docUPIController.text = docUPI;

    super.initState();
    if (isMobileLogin == true) {
      docPhoneNumberController.text = user!.phoneNumber!.substring(3);
      docEmailController.text = docEmail;
      disableNo = false;

    } else {
      docEmailController.text = user!.email!;
      docPhoneNumberController.text = docPhoneNumber;
      disableEmail = false;
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedImage = await _picker.pickImage(source: source);

    if (pickedImage != null) {
      base64Image2 = base64Encode(File(pickedImage.path).readAsBytesSync());
      doctorPhoto = base64Image2;

      // PhysioDatabase.db.updateProfilePhoto(cred!, doctorPhoto);

      setState(() {
        docImage = base64Decode(base64Image2);
      });
    }
  }
@override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    print(screenWidth);
    print(screenHeight);
    return GestureDetector(
      child: Scaffold(
        body: settingsBody(context),
      ),
      onTap: () {
        FocusScope.of(context).unfocus();
      },
    );
  }

  settingsBody(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
// SizedBox(height:20),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                  ),
                ),
                SizedBox(
                  width: screenWidth! * 0.75,
                ),
                IconButton(
                  onPressed: () async {
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
                                Text("Updating your details, hang on"),
                              ],
                            ),
                          ),
                        );
                      },
                    );//progressIndicator
                    if(docImage!=null){
                      Reference ref=storageReference.child('images/${user!.uid}.jpg');
                      UploadTask uploadTask = ref.putData(docImage!);
                      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
                      downloadUrl = await snapshot.ref.getDownloadURL();
                    }
                    else{
                      downloadUrl="";
                    }
                    await setUser();
                    if(!mounted){return ;}
                    Navigator.pop(context);
                    // getDoctorData();
                  },
                   icon: const Icon(
                    Icons.check,
                  ),
                )
              ],
            ),
            Stack(children: [
              ClipOval(
                child: Container(
                  height: screenHeight! * 0.152,
                  width: screenWidth! * 0.26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: docImage != null
                      ? Image.memory(
                          docImage!,
                          width: screenWidth! * 0.21,
                          height: screenHeight! * 0.21,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          genderNeutralImage,
                          width: screenWidth! * 0.21,
                          height: screenHeight! * 0.21,
                        ),
                ),
              ),
              Positioned(
                left: screenWidth! * 0.151,
                top: screenHeight! * 0.095,
                child: Container(
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
                    },
                  ),
                ),
              ),
            ]),
            SizedBox(
              height: screenHeight! * 0.015,
            ),
            const Text(info,
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20)),
            SizedBox(
              height: screenHeight! * 0.022,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: TextFormField(
                controller: docNameController,
                decoration: const InputDecoration(
                  labelText: name,
                  hintText: name,
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
            ),
            SizedBox(
              height: screenHeight! * 0.022,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: TextFormField(
                 // style: const TextStyle(color: black54Color),
                enabled: disableEmail,
                controller: docEmailController,
                decoration: const InputDecoration(
                  labelText: mail,
                  hintText: mail,
                  // labelText: 'Age',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 4, color: greenAccentColor),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            SizedBox(
              height: screenHeight! * 0.022,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: TextFormField(
                // enabled: formEnabler,
                controller: docPhoneNumberController,
                enabled: disableNo,
                autovalidateMode: _autoValidateMode,
                maxLength: 10,
                // validator: (input) => input!.validatePhone()
                //     ? null
                //     : validPhone,
                decoration: const InputDecoration(
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
            ),
            SizedBox(
              height: screenHeight! * 0.022,
            ),
            const Text(upiInfo,
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20)),
            SizedBox(
              height: screenHeight! * 0.022,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: TextFormField(
                controller: docUPIController,
                decoration: const InputDecoration(
                  labelText: upi,
                  hintText: upi,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 4, color: greenAccentColor),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
      ),
    );
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
                    docImage = null;
                    downloadUrl='';
                    docPhoto='';
                  });
                },
              ),
            ],
          );
        });
  }
}
