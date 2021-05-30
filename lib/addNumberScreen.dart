import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class addNumberScreen extends StatefulWidget {
  final String user;

  addNumberScreen({Key key, @required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return addNumberScreenState(user);
  }
}

class addNumberScreenState extends State<addNumberScreen> {
  final String user;

  addNumberScreenState(this.user);

  Color themeColor = Color(0xFF4A148C);

  final numberController = TextEditingController();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final firebaseDatabase = FirebaseDatabase.instance;

  bool isLoading = false, checkNumData = false;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!checkNumData) {
        getNumber();
        checkNumData = true;
      }
    });
    return WillPopScope(
      onWillPop: () => checkNumber(context),
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text("Add Number"),
          backgroundColor: themeColor,
        ),
        body: isLoading
            ? Center(
                child: SpinKitChasingDots(
                  color: themeColor,
                  size: 50.0,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Add a mobile number to get alert message."),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      alignment: Alignment.bottomCenter,
                      margin: const EdgeInsets.only(
                          left: 10, top: 10, right: 10, bottom: 0),
                      child: TextFormField(
                        maxLength: 10,
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
                          labelText: "Mobile Number",
                          labelStyle: TextStyle(color: themeColor),
                          fillColor: Colors.white,
                        ),
                        controller: numberController,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      alignment: Alignment.bottomCenter,
                      margin: const EdgeInsets.only(
                          left: 10, top: 10, right: 10, bottom: 0),
                      child: FlatButton(
                        //shape: RoundedRectangleBsorder(borderRadius: new BorderRadius.circular(30.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        onPressed: () {
                          if (numberController.text.isEmpty ||
                              numberController.text.length != 10) {
                            showSnackBar("Please enter 10 digit mobile number");
                          } else {
                            firebaseDatabase
                                .reference()
                                .child("FireGasDetection")
                                .child("User")
                                .child(user)
                                .child("Sms")
                                .update({
                              "Number": numberController.text.toString()
                            });
                            showSnackBar("Mobile number added successfully");
                          }
                        },
                        child: Text("Add Number"),
                        textColor: Colors.white,
                        padding: EdgeInsets.all(16),
                        color: themeColor,
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  checkNumber(BuildContext context) async {
    String number = (await firebaseDatabase
            .reference()
            .child("FireGasDetection")
            .child("User")
            .child(user)
            .child("Sms")
            .child("Number")
            .once())
        .value
        .toString();

    if (number == "") {
      showSnackBar("Please update the mobile number to get alert message");
    } else {
      Navigator.of(context).pop();
    }
  }

  showSnackBar(message) {
    final snackBar = SnackBar(content: Text(message));
    scaffoldKey.currentState.showSnackBar(snackBar);
  }

  Future<void> getNumber() async {
    setState(() {
      isLoading = true;
    });
    String number = (await firebaseDatabase
            .reference()
            .child("FireGasDetection")
            .child("User")
            .child(user)
            .child("Sms")
            .child("Number")
            .once())
        .value
        .toString();

    setState(() {
      numberController.text = number;
      isLoading = false;
    });
  }
}
