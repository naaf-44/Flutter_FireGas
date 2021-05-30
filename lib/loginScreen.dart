import 'dart:io';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firegas/dashBoardScreen.dart';
import 'package:flutter_firegas/databaseHelper.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

import 'databaseHelper.dart';

class loginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return loginScreenState();
  }
}

class loginScreenState extends State<loginScreen> {
  Color themeColor = Color(0xFF4A148C);

  final emailController = TextEditingController();
  final userIdController = TextEditingController();
  final otpController = TextEditingController();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoaded = true;
  String loadingText = "";

  final firebaseDatabase = FirebaseDatabase.instance;
  final dh = databaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => onBackPressed(context),
      child: Scaffold(
        key: scaffoldKey,
        body: isLoaded == false
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitChasingDots(
                    color: themeColor,
                    size: 50.0,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    loadingText,
                    style: TextStyle(
                        color: themeColor, fontWeight: FontWeight.w500),
                  )
                ],
              )
            : Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/login/login_bg.png"),
                        fit: BoxFit.fill)),
                child: Padding(
                  padding:
                      EdgeInsets.only(right: 0, top: 0, left: 0, bottom: 50),
                  child: Column(
                    children: [
                      Spacer(),
                      Container(
                        alignment: Alignment.bottomCenter,
                        margin: const EdgeInsets.only(
                            left: 10, top: 10, right: 10, bottom: 0),
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: themeColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: Colors.grey[300]),
                            ),
                            filled: true,
                            labelText: "Email",
                            labelStyle: TextStyle(color: themeColor),
                            fillColor: Colors.white,
                          ),
                          controller: emailController,
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        margin: const EdgeInsets.only(
                            left: 10, top: 10, right: 10, bottom: 0),
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: themeColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: Colors.grey[300]),
                            ),
                            filled: true,
                            labelText: "User ID",
                            labelStyle: TextStyle(color: themeColor),
                            fillColor: Colors.white,
                          ),
                          controller: userIdController,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                            left: 10, top: 5, right: 10, bottom: 0),
                        child: GestureDetector(
                          onTap: () {
                            if (emailController.text.isNotEmpty) {
                              sendUserID();
                            } else {
                              showSnackBar("Please enter the email");
                            }
                          },
                          child: Row(
                            children: [
                              Spacer(),
                              Text(
                                "Forgot User ID?",
                                style: TextStyle(color: themeColor),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        margin: const EdgeInsets.only(
                            left: 10, top: 10, right: 10, bottom: 0),
                        child: FlatButton(
                          //shape: RoundedRectangleBsorder(borderRadius: new BorderRadius.circular(30.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          onPressed: () async {
                            if (emailController.text.toString().isEmpty ||
                                userIdController.text.toString().isEmpty) {
                              showSnackBar("Please enter the fields");
                              return;
                            }

                            String userID = userIdController.text.toString();
                            String userEmail = emailController.text.toString();
                            userEmail = userEmail.replaceAll("@", "");
                            userEmail = userEmail.replaceAll(".", "");
                            userEmail = userEmail.replaceAll(",", "");

                            setState(() {
                              isLoaded = false;
                            });

                            bool found = false;

                            var emailReference = firebaseDatabase
                                .reference()
                                .child("FireGasDetection")
                                .child("UserEmail");
                            emailReference.once().then((DataSnapshot snapshot) {
                              if (snapshot.value != null) {
                                print("value object");
                                snapshot.value.forEach((key, value) {
                                  setState(() {
                                    isLoaded = true;
                                  });
                                  if (key.toString() == userEmail &&
                                      value.toString() == userID) {
                                    found = true;
                                    sendOTP(context, userID, userEmail);
                                    return;
                                  } else if (key.toString() == userEmail &&
                                      value.toString() != userID) {
                                    showSnackBar(
                                        "Email address already registered");
                                    found = true;
                                    return;
                                  } else if (key.toString() != userEmail &&
                                      value.toString() == userID) {
                                    showSnackBar("User ID Already registered");
                                    found = true;
                                    return;
                                  }
                                });
                                if (found == false) {
                                  sendOTP(context, userID, userEmail);
                                }
                              } else {
                                print("Null object");
                                sendOTP(context, userID, userEmail);
                              }
                            });
                          },
                          child: Text("Get OTP"),
                          textColor: Colors.white,
                          padding: EdgeInsets.all(16),
                          color: themeColor,
                        ),
                      )
                    ],
                  ),
                )),
      ),
    );
  }

  Future<void> sendOTP(
      BuildContext context, String userID, String userEmail) async {
    var otp;

    try {
      print("Send OTP");
      if (emailController.text.toString().isEmpty) {
        showSnackBar("Please enter the email address");
      } else if (userIdController.text.toString().isEmpty) {
        showSnackBar("Please enter the user ID");
      } else {
        setState(() {
          isLoaded = false;
          loadingText = "Please wait";
        });
        var random = new Random();
        otp = 1000 + random.nextInt(9999 - 1000);

        print("OTP $otp");

        final String message = "Your OTP for login to FireGas Detection is " +
            otp.toString() +
            "\nDon't share your OTP with anyone.";

        String fromEmail = (await firebaseDatabase
                .reference()
                .child("FireGasDetection")
                .child("Admin")
                .child("FromEmail")
                .once())
            .value
            .toString();
        print(fromEmail);

        String url = "https://www.firedetection.xyz/sendEmail.php";

        /*String parameter = "?email=" +
            emailController.text.toString() +
            "&from=" +
            fromEmail +
            "&message=" +
            message +
            "&subject=FireGas Detection Login";
        parameter = parameter.replaceAll(" ", "%20");

        url = url + parameter;*/

        var response = await http.post(url, body: {
          "email": emailController.text.toString(),
          "from": fromEmail,
          "message": message,
          "subject": "FireGas Detection Login"
        });
        var responseMessage = response.body;

        if (response.statusCode == 200) {
          if (responseMessage.toString().trim() == "1") {
            userLogin(context, otp.toString(), userID, userEmail);
          } else {
            setState(() {
              isLoaded = true;
              loadingText = "";
            });
            showSnackBar("Error Sending OTP");
          }
        } else {
          setState(() {
            isLoaded = true;
            loadingText = "";
          });
          showSnackBar("Something wrong");
        }
      }
    } on SocketException catch (e) {
      setState(() {
        isLoaded = true;
        loadingText = "";
      });
      showSnackBar("Cant send OTP right now. Try again later");
      print(e);
      //userLogin(context, otp.toString(), userID, userEmail);
    }
  }

  showSnackBar(message) {
    final snackBar = SnackBar(content: Text(message));
    scaffoldKey.currentState.showSnackBar(snackBar);
  }

  onBackPressed(BuildContext context) {
    exit(0);
  }

  void userLogin(
      BuildContext context, String otp, String userID, String userEmail) {
    print("userLogin");

    setState(() {
      isLoaded = true;
      loadingText = "";
    });
    otpController.text = "";

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext buildContext) {
          return AlertDialog(
            title: Center(
              child: Text("User Login"),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: themeColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.grey[300]),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Enter OTP"),
                  controller: otpController,
                ),
                SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: themeColor),
                    child: FlatButton(
                      onPressed: () {
                        if (otp.toString() == otpController.text.toString()) {
                          updateToDatabase(context, userID, userEmail);
                          Navigator.of(buildContext).pop();
                        } else {
                          showSnackBar("Invalid OTP");
                        }
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<void> updateToDatabase(
      BuildContext context, String userID, String userEmail) async {
    dh.deleteUserData();

    Map<String, dynamic> row = {databaseHelper.U_COL_USER: userID};
    final id = await dh.insertUserData(row);
    print(id);

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(userID)
        .child("Sms")
        .update({"Number": ""});

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(userID)
        .child("Sprinkler")
        .update({"Status": "0"});

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(userID)
        .child("Profile")
        .update({
      "email": emailController.text.toString(),
      "UserID": userID,
      "Online": "0"
    });

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(userID)
        .child("Controller")
        .update({
      "Temp": "1",
      "Humi": "1",
      "Sprinkler": "1",
      "Fire": "1",
      "Gas": "0",
    });

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(userID)
        .child("LiveData")
        .update({
      "Temp": "0",
      "Humi": "0",
      "Gas": "0",
    });

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(userID)
        .child("Detection")
        .child("Fire")
        .update({
      "Detected": "0",
      "Date": "0",
      "Time": "0",
    });

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(userID)
        .child("Detection")
        .child("Gas")
        .update({
      "Detected": "0",
      "Date": "0",
      "Time": "0",
    });

    firebaseDatabase.reference()
      ..child("FireGasDetection")
          .child("UserID")
          .update({userID: emailController.text.toString()});

    firebaseDatabase.reference()
      ..child("FireGasDetection")
          .child("UserEmail")
          .update({userEmail: userID});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => dashBoardScreen(
          user: userID,
        ),
      ),
    );
  }

  Future<void> sendUserID() async {
    print("sendUserID");

    setState(() {
      isLoaded = false;
    });
    String url = "https://www.firedetection.xyz/sendEmail.php";

    String fromEmail = (await firebaseDatabase
            .reference()
            .child("FireGasDetection")
            .child("Admin")
            .child("FromEmail")
            .once())
        .value
        .toString();

    bool found = false;

    var userIDReference =
        firebaseDatabase.reference().child("FireGasDetection").child("UserID");
    userIDReference.once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        snapshot.value.forEach((key, value) async {
          if (value.toString() == emailController.text.toString()) {
            found = true;

            final String message = "Your User ID for the email address " +
                value.toString() +
                " is " +
                key.toString();

            /*String parameter = "?email=" +
                emailController.text.toString() +
                "&from=" +
                fromEmail +
                "&message=" +
                message +
                "&subject=" +
                "FireGas Detection Login" +
                "&display=" +
                "FireGas Detection";
            parameter = parameter.replaceAll(" ", "%20");

            url = url + parameter;*/

            print(url);

            var response = await http.post(url, body: {
              "email": emailController.text.toString(),
              "from": fromEmail,
              "message": message,
              "subject": "FireGas Detection Login"
            });
            var responseMessage = response.body;

            if (response.statusCode == 200) {
              setState(() {
                isLoaded = true;
              });
              if (responseMessage.toString().trim() == "1") {
                showSnackBar("Check your email for User ID");
              } else {
                setState(() {
                  isLoaded = true;
                });
                showSnackBar("Error Sending OTP");
              }
            } else {
              setState(() {
                isLoaded = true;
              });
              showSnackBar("Something wrong");
            }

            return;
          }
        });
        if (found == false) {
          setState(() {
            isLoaded = true;
          });
          showSnackBar("You are not registered yet");
        }
      } else {
        setState(() {
          isLoaded = true;
        });
        showSnackBar("You are not registered yet");
      }
    });
  }
}
