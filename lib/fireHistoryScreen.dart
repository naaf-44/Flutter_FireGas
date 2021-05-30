import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class fireHistoryScreen extends StatefulWidget {
  final String user;

  fireHistoryScreen({Key key, @required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return fireHistoryScreenState(user);
  }
}

class fireHistoryScreenState extends State<fireHistoryScreen> {
  String user;

  fireHistoryScreenState(this.user);

  bool isFireDataSet = false;

  Color themeColor = Color(0xFF4A148C);

  int count = 0;
  int total = 0;

  final firebaseDatabase = FirebaseDatabase.instance;

  List<String> itemFireDataKey = new List();
  List<String> itemDate = new List();
  List<String> itemTime = new List();

  @override
  void initState() {
    super.initState();
    setFireLog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Fire Log"),
          backgroundColor: themeColor,
          actions: [
            // ignore: deprecated_member_use
            IconButton(
                icon: Icon(
                  Icons.clear_all,
                  color: Colors.white,
                ),
                onPressed: () {
                  var historyReference = firebaseDatabase
                      .reference()
                      .child("FireGasDetection")
                      .child("User")
                      .child(user)
                      .child("History")
                      .child("Fire");
                  historyReference.remove();

                  setFireLog();
                })
          ],
        ),
        body: isFireDataSet == false
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
                    "Please wait",
                    style: TextStyle(
                        color: themeColor, fontWeight: FontWeight.w500),
                  ),
                  count > 0
                      ? Text(
                          "Loading " +
                              count.toString() +
                              "/" +
                              total.toString(),
                          style: TextStyle(
                              color: themeColor, fontWeight: FontWeight.w500),
                        )
                      : Text("")
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: itemFireDataKey.length,
                      itemBuilder: (context, index) {
                        return itemFireDataKey.isEmpty
                            ? Text("Please wait")
                            : Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Fire Detected on",
                                          style: TextStyle(
                                              color: themeColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Date: ",
                                          style: TextStyle(
                                              color: themeColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15),
                                        ),
                                        Text(itemDate[index]),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Time: ",
                                          style: TextStyle(
                                              color: themeColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15),
                                        ),
                                        Text(itemTime[index]),
                                      ],
                                    ),
                                    Container(
                                      height: 1,
                                      color: Colors.grey,
                                    )
                                  ],
                                ),
                              );
                      },
                    ),
                  ),
                ],
              ));
  }

  void setFireLog() {
    itemFireDataKey.clear();
    itemDate.clear();
    itemTime.clear();

    var historyReference = firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("History")
        .child("Fire");
    historyReference.once().then((DataSnapshot snapshot) async {
      if (snapshot.value != null) {
        snapshot.value.forEach((key, value) {
          itemFireDataKey.add(key.toString());
          total++;
        });
        for (int i = 0; i < itemFireDataKey.length; i++) {
          String date = (await historyReference
                  .child(itemFireDataKey[i].toString())
                  .child("Date")
                  .once())
              .value
              .toString();
          String time = (await historyReference
                  .child(itemFireDataKey[i].toString())
                  .child("Time")
                  .once())
              .value
              .toString();

          setState(() {
            itemDate.add(date);
            itemTime.add(time);
            count = i;
          });
        }
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              isFireDataSet = true;
            });
          }
        });
      } else {
        setState(() {
          isFireDataSet = true;
        });
      }
    });
  }
}
