import 'dart:io';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_firegas/addNumberScreen.dart';
import 'package:flutter_firegas/controlScreen.dart';
import 'package:flutter_firegas/databaseHelper.dart';
import 'package:flutter_firegas/fireHistoryScreen.dart';
import 'package:flutter_firegas/gashistoryScreen.dart';
import 'package:flutter_firegas/liveGraphScreen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quiver/async.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:workmanager/workmanager.dart';

const simplePeriodicTask = "FireGasDetectionTask";
final firebaseDatabase = FirebaseDatabase.instance;
final dh = databaseHelper.instance;

void showNotification(message, flutterLocalNotificationsPlugin) async {
  var android = AndroidNotificationDetails(
      'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
      priority: Priority.high, importance: Importance.max);
  var iOS = IOSNotificationDetails();
  var platform = NotificationDetails(android: android, iOS: iOS);
  await flutterLocalNotificationsPlugin.show(
      0, 'Fire Gas Detection', '$message', platform);
}

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('app_icon');
    var iOS = IOSInitializationSettings();
    var initializeSettings = InitializationSettings(android: android, iOS: iOS);
    flutterLocalNotificationsPlugin.initialize(initializeSettings);

    String nUser = "";
    int userCount = await dh.userRowCount();
    if (userCount > 0) {
      final allRows = await dh.getUserData();

      var userData = allRows;
      nUser = userData[0]['user'];
    }

    String isFireDetected = (await firebaseDatabase
            .reference()
            .child("FireGasDetection")
            .child("User")
            .child(nUser)
            .child("Detection")
            .child("Fire")
            .child("Detected")
            .once())
        .value
        .toString();

    if (isFireDetected == "1") {
      String date = (await firebaseDatabase
              .reference()
              .child("FireGasDetection")
              .child("User")
              .child(nUser)
              .child("Detection")
              .child("Fire")
              .child("Date")
              .once())
          .value
          .toString();

      String time = (await firebaseDatabase
              .reference()
              .child("FireGasDetection")
              .child("User")
              .child(nUser)
              .child("Detection")
              .child("Fire")
              .child("Time")
              .once())
          .value
          .toString();
      showNotification("Fire Detected on \nDate: " + date + "\nTime: " + time,
          flutterLocalNotificationsPlugin);

      firebaseDatabase
          .reference()
          .child("FireGasDetection")
          .child("User")
          .child(nUser)
          .child("Detection")
          .child("Fire")
          .update({"Date": "0", "Detected": "0", "Time": "0"});
    }

    String isGasDetected = (await firebaseDatabase
            .reference()
            .child("FireGasDetection")
            .child("User")
            .child(nUser)
            .child("Detection")
            .child("Gas")
            .child("Detected")
            .once())
        .value
        .toString();

    if (isGasDetected == "1") {
      String date = (await firebaseDatabase
              .reference()
              .child("FireGasDetection")
              .child("User")
              .child(nUser)
              .child("Detection")
              .child("Gas")
              .child("Date")
              .once())
          .value
          .toString();

      String time = (await firebaseDatabase
              .reference()
              .child("FireGasDetection")
              .child("User")
              .child(nUser)
              .child("Detection")
              .child("Gas")
              .child("Time")
              .once())
          .value
          .toString();
      showNotification(
          "Gas Leakage Detected on \nDate: " + date + "\nTime: " + time,
          flutterLocalNotificationsPlugin);

      firebaseDatabase
          .reference()
          .child("FireGasDetection")
          .child("User")
          .child(nUser)
          .child("Detection")
          .child("Gas")
          .update({"Date": "0", "Detected": "0", "Time": "0"});
    }

    return Future.value(true);
  });
}

class dashBoardScreen extends StatefulWidget {
  final String user;

  dashBoardScreen({Key key, @required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return dashBoardScreenState(user);
  }
}

// ignore: camel_case_types
class dashBoardScreenState extends State<dashBoardScreen> {
  final String user;

  dashBoardScreenState(this.user);

  Color themeColor = Color(0xFF4A148C);

  String temperatureValue = "0", humidityValue = "0", sprinklerData = "0";
  bool isDataLoaded = false,
      isSensorOff = false,
      isOnline = false,
      isLoading = false;

  CountdownTimer countdownTimer;
  var liveDataReference, controlReference;

  @override
  void dispose() {
    super.dispose();
    if (countdownTimer != null) {
      countdownTimer.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    liveDataReference = firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("LiveData");

    controlReference = firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("Controller");

    WidgetsFlutterBinding.ensureInitialized();
    Workmanager.initialize(callbackDispatcher,
        isInDebugMode:
            false); //to true if still in testing lev turn it to false whenever you are launching the app
    Workmanager.registerPeriodicTask("FireGasDetection", simplePeriodicTask,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        frequency: Duration(minutes: 15),
        //when should it check the link
        initialDelay: Duration(seconds: 0),
        //duration before showing the notification
        inputData: {"user": user});

    firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("Profile")
        .update({"Online": "0"});

    setSprinklerStatus();
  }

  @override
  Widget build(BuildContext context) {
    double fullWidth = MediaQuery.of(context).size.width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDataLoaded == false) {
        setTempHumi();
        checkNumber(context);
        isDataLoaded = true;
      }
    });
    return WillPopScope(
      onWillPop: () {
        exit(0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dashboard"),
          automaticallyImplyLeading: false,
          backgroundColor: themeColor,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => addNumberScreen(user: user),
                  ),
                );
              },
              icon: Icon(
                Icons.add,
                color: Colors.white,
              ),
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
            fixedColor: themeColor,
            showUnselectedLabels: true,
            selectedLabelStyle:
                TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            unselectedLabelStyle:
                TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            unselectedItemColor: themeColor,
            onTap: (newIndex) => nextScreen(newIndex, context),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  height: 24,
                  width: 24,
                  child: Image.asset("assets/dash/onoff.png"),
                ),
                label: "Control",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  height: 24,
                  width: 24,
                  child: Image.asset("assets/dash/smoke.png"),
                ),
                label: "Live Graph",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  height: 24,
                  width: 24,
                  child: Image.asset("assets/dash/gaslog.png"),
                ),
                label: "Gas Log",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  height: 24,
                  width: 24,
                  child: Image.asset("assets/dash/firelog.png"),
                ),
                label: "Fire Log",
              ),
            ]),
        body: isLoading
            ? Center(
                child: SpinKitChasingDots(
                  color: themeColor,
                  size: 50.0,
                ),
              )
            : Center(
                child: Container(
                  width: fullWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        isSensorOff == true
                            ? Padding(
                                padding: EdgeInsets.all(10),
                                child: Container(
                                  width: fullWidth,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Text(
                                      "Sensors are turned off\nYou can turn it on in Control Tab",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: themeColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 10,
                              ),
                        Text(
                          isOnline == true ? "online" : "offline",
                          style: TextStyle(
                            color: isOnline == true ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: themeColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sprinklerData == "0"
                                    ? "Sprinkler OFF"
                                    : "Sprinkler ON",
                                style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 25),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  border: Border.all(color: themeColor),
                                ),
                                child: IconButton(
                                  color: themeColor,
                                  icon: Icon(
                                    sprinklerData == "0"
                                        ? Icons.power_off
                                        : Icons.power_outlined,
                                    color: themeColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      sprinklerData == "0"
                                          ? sprinklerData = "1"
                                          : sprinklerData = "0";
                                    });
                                    firebaseDatabase
                                        .reference()
                                        .child("FireGasDetection")
                                        .child("User")
                                        .child(user)
                                        .child("Sprinkler")
                                        .update({"Status": sprinklerData});
                                  },
                                ),
                              )

                              /*ToggleSwitch(
                                changeOnTap: true,
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
                                  print("index $index");

                                  firebaseDatabase
                                      .reference()
                                      .child("FireGasDetection")
                                      .child("User")
                                      .child(user)
                                      .child("Sprinkler")
                                      .update({"Status": index.toString()});
                                },
                              ),*/
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Temperature",
                          style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                        ),
                        Container(
                          height: 200,
                          width: 200,
                          child: SfRadialGauge(
                            enableLoadingAnimation: true,
                            animationDuration: 4500,
                            axes: [
                              RadialAxis(
                                minimum: 0,
                                maximum: 100,
                                ranges: [
                                  GaugeRange(
                                      startValue: 0,
                                      endValue: 33,
                                      color: Colors.purple[300]),
                                  GaugeRange(
                                      startValue: 33,
                                      endValue: 66,
                                      color: Colors.purple[600]),
                                  GaugeRange(
                                      startValue: 66,
                                      endValue: 100,
                                      color: Colors.purple[900])
                                ],
                                pointers: [
                                  NeedlePointer(
                                    value: double.parse(temperatureValue),
                                    needleColor: themeColor,
                                    animationDuration: 2000,
                                    enableAnimation: true,
                                  )
                                ],
                                annotations: [
                                  GaugeAnnotation(
                                      widget: Container(
                                        child: Text(temperatureValue,
                                            style: TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      angle: 90,
                                      positionFactor: 0.5)
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Humidity",
                          style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                        ),
                        Container(
                          height: 200,
                          width: 200,
                          child: SfRadialGauge(
                            enableLoadingAnimation: true,
                            animationDuration: 4500,
                            axes: [
                              RadialAxis(
                                minimum: 0,
                                maximum: 100,
                                ranges: [
                                  GaugeRange(
                                      startValue: 0,
                                      endValue: 33,
                                      color: Colors.purple[300]),
                                  GaugeRange(
                                      startValue: 33,
                                      endValue: 66,
                                      color: Colors.purple[600]),
                                  GaugeRange(
                                      startValue: 66,
                                      endValue: 100,
                                      color: Colors.purple[900])
                                ],
                                pointers: [
                                  NeedlePointer(
                                    value: double.parse(humidityValue),
                                    needleColor: themeColor,
                                    animationDuration: 2000,
                                    enableAnimation: true,
                                  )
                                ],
                                annotations: [
                                  GaugeAnnotation(
                                      widget: Container(
                                        child: Text(humidityValue,
                                            style: TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      angle: 90,
                                      positionFactor: 0.5)
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> setTempHumi() async {
    setState(() {
      isSensorOff = false;
    });

    controlReference.once().then((DataSnapshot dataSnapshot) {
      dataSnapshot.value.forEach((key, value) {
        if (value.toString() == "0") {
          setState(() {
            isSensorOff = true;
          });
        }
      });
    });

    countdownTimer =
        new CountdownTimer(new Duration(seconds: 30), new Duration(seconds: 5));
    // ignore: cancel_subscriptions
    var sub = countdownTimer.listen(null);
    sub.onData((duration) async {
      String tData =
          (await liveDataReference.child("Temp").once()).value.toString();
      String hData =
          (await liveDataReference.child("Humi").once()).value.toString();

      String onlineStatus = (await firebaseDatabase
              .reference()
              .child("FireGasDetection")
              .child("User")
              .child(user)
              .child("Profile")
              .child("Online")
              .once())
          .value
          .toString();

      if (mounted) {
        setState(() {
          temperatureValue = tData;
          humidityValue = hData;

          if (onlineStatus == "1") {
            isOnline = true;
          } else {
            isOnline = false;
          }
        });
      }
    });
    sub.onDone(() async {
      countdownTimer.cancel();
      setTempHumi();
    });
  }

  onBackPressed(BuildContext context) {
    exit(0);
    /*
    return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(
            title: Center(
              child: Text("Close Application"),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Do you want to exit?"),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Container(
                      child: GestureDetector(
                        // ignore: deprecated_member_use
                        child: RaisedButton(
                          color: themeColor,
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "No",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Spacer(),
                    Container(
                      child: GestureDetector(
                        // ignore: deprecated_member_use
                        child: RaisedButton(
                          color: themeColor,
                          onPressed: (){

                          },
                          child: Text(
                            "Yes",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ) ??
        false;*/
  }

  nextScreen(int newIndex, BuildContext context) {
    if (newIndex == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => controlScreen(user: user),
        ),
      );
    } else if (newIndex == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => liveGraphScreen(user: user),
        ),
      );
    } else if (newIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => gasHistoryScreen(user: user),
        ),
      );
    } else if (newIndex == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => fireHistoryScreen(user: user),
        ),
      );
    }
  }

  Future<void> checkNumber(BuildContext context) async {
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

    print("number is $number");
    if (number == "") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => addNumberScreen(user: user),
        ),
      );
    }
  }

  Future<void> setSprinklerStatus() async {
    setState(() {
      isLoading = true;
    });
    String sprinkler = (await firebaseDatabase
            .reference()
            .child("FireGasDetection")
            .child("User")
            .child(user)
            .child("Sprinkler")
            .child("Status")
            .once())
        .value
        .toString();

    setState(() {
      sprinklerData = sprinkler;
      print("sprinklerData $sprinklerData");
      isLoading = false;
    });
  }
}
