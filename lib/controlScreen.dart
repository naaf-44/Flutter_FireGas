import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:toggle_switch/toggle_switch.dart';

class controlScreen extends StatefulWidget {
  final String user;

  controlScreen({Key key, @required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return controlScreenState(user);
  }
}

class controlScreenState extends State<controlScreen> {
  String user;

  controlScreenState(this.user);

  Color themeColor = Color(0xFF4A148C);
  bool isSwitched = false, isControllerSet = false;

  final firebaseDatabase = FirebaseDatabase.instance;

  String fireData = "0",
      gasData = "0",
      tempData = "0",
      humiData = "0",
      sprinklerData = "0",
      loadingText = "Loading";

  @override
  void initState() {
    super.initState();
    setController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Controller"),
        backgroundColor: themeColor,
      ),
      body: isControllerSet == false
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
                  style:
                      TextStyle(color: themeColor, fontWeight: FontWeight.w500),
                )
              ],
            )
          : Center(
              child: Padding(
                  padding:
                      EdgeInsets.only(left: 5, top: 0, right: 5, bottom: 0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Fire",
                              style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 25),
                            ),
                            ToggleSwitch(
                              initialLabelIndex: int.parse(fireData),
                              minWidth: 90.0,
                              cornerRadius: 20.0,
                              activeBgColor: themeColor,
                              activeFgColor: Colors.white,
                              inactiveBgColor: Colors.grey,
                              inactiveFgColor: Colors.white,
                              labels: ['OFF', 'ON'],
                              icons: [Icons.power_off, Icons.power_outlined],
                              onToggle: (index) {
                                setControllerData("Fire", index.toString());
                              },
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Gas",
                              style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 25),
                            ),
                            ToggleSwitch(
                              initialLabelIndex: int.parse(gasData),
                              minWidth: 90.0,
                              cornerRadius: 20.0,
                              activeBgColor: themeColor,
                              activeFgColor: Colors.white,
                              inactiveBgColor: Colors.grey,
                              inactiveFgColor: Colors.white,
                              labels: ['OFF', 'ON'],
                              icons: [Icons.power_off, Icons.power_outlined],
                              onToggle: (index) {
                                setControllerData("Gas", index.toString());
                              },
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Temperature",
                              style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 25),
                            ),
                            ToggleSwitch(
                              initialLabelIndex: int.parse(tempData),
                              minWidth: 90.0,
                              cornerRadius: 20.0,
                              activeBgColor: themeColor,
                              activeFgColor: Colors.white,
                              inactiveBgColor: Colors.grey,
                              inactiveFgColor: Colors.white,
                              labels: ['OFF', 'ON'],
                              icons: [Icons.power_off, Icons.power_outlined],
                              onToggle: (index) {
                                setControllerData("Temp", index.toString());
                              },
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Humidity",
                              style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 25),
                            ),
                            ToggleSwitch(
                              initialLabelIndex: int.parse(humiData),
                              minWidth: 90.0,
                              cornerRadius: 20.0,
                              activeBgColor: themeColor,
                              activeFgColor: Colors.white,
                              inactiveBgColor: Colors.grey,
                              inactiveFgColor: Colors.white,
                              labels: ['OFF', 'ON'],
                              icons: [Icons.power_off, Icons.power_outlined],
                              onToggle: (index) {
                                setControllerData("Humi", index.toString());
                              },
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Sprinkler",
                              style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 25),
                            ),
                            ToggleSwitch(
                              initialLabelIndex: int.parse(sprinklerData),
                              minWidth: 90.0,
                              cornerRadius: 20.0,
                              activeBgColor: themeColor,
                              activeFgColor: Colors.white,
                              inactiveBgColor: Colors.grey,
                              inactiveFgColor: Colors.white,
                              labels: ['OFF', 'ON'],
                              icons: [Icons.power_off, Icons.power_outlined],
                              onToggle: (index) {
                                setControllerData(
                                    "Sprinkler", index.toString());
                              },
                            )
                          ],
                        )
                      ],
                    ),
                  )),
            ),
    );
  }

  setController() async {
    print("setController");
    var controllerReference = firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("Controller");

    String cfData =
        (await controllerReference.child("Fire").once()).value.toString();
    String cgData =
        (await controllerReference.child("Gas").once()).value.toString();
    String ctData =
        (await controllerReference.child("Temp").once()).value.toString();
    String chData =
        (await controllerReference.child("Humi").once()).value.toString();
    String csData =
        (await controllerReference.child("Sprinkler").once()).value.toString();

    setState(() {
      fireData = cfData;
      gasData = cgData;
      tempData = ctData;
      humiData = chData;
      sprinklerData = csData;
      isControllerSet = true;
    });

    print(fireData);
  }

  void setControllerData(String path, String data) {
    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("Controller")
        .update({path: data});
  }
}
