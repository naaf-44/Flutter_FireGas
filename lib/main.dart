import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'dashBoardScreen.dart';
import 'databaseHelper.dart';
import 'loginScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Color themeColor = Color(0xFF4A148C);

  bool isDatabaseChecked = false;
  final dh = databaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDatabaseChecked == false) {
        Future.delayed(Duration(seconds: 2), () {
          checkDatabase();
        });

        isDatabaseChecked = true;
      }
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 150,
            ),
            Container(
              width: 150,
              height: 150,
              child: Image(image: AssetImage("assets/logo/logo.png")),
            ),
            Spacer(),
            Text(
              "Fire and Gas Detection",
              style: TextStyle(color: themeColor),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> checkDatabase() async {
    int userCount = await dh.userRowCount();
    if (userCount > 0) {
      final allRows = await dh.getUserData();
      String userData = allRows.toString();

      String jsonString = "", user = "";
      for (int i = 0; i < userData.length; i++) {
        if (userData[i] == '{') {
          jsonString += userData[i];
          jsonString += "\"";
        } else if (userData[i] == ':') {
          jsonString += "\"";
          jsonString += userData[i];
        } else if (userData[i] == ' ') {
          jsonString += "\"";
          //jsonString += userData[i];
        } else if (userData[i] == ',') {
          jsonString += "\"";
          jsonString += userData[i];
        } else if (userData[i] == '}') {
          jsonString += "\"";
          jsonString += userData[i];
        } else {
          jsonString += userData[i];
        }
      }

      jsonString = jsonString.replaceAll('[', '');
      jsonString = jsonString.replaceAll(']', '');
      jsonString = jsonString.replaceAll('+91', '');

      print("Json String $jsonString");
      //print("userData $userData");
      var jsonData = json.decode(jsonString);
      user = jsonData["user"];
      print(user);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => dashBoardScreen(
            user: user,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => loginScreen(),
        ),
      );
    }
  }
}
