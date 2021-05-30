import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class gasHistoryScreen extends StatefulWidget {
  final String user;

  gasHistoryScreen({Key key, @required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return gasHistoryScreenState(user);
  }
}

class gasHistoryScreenState extends State<gasHistoryScreen> {
  String user;

  gasHistoryScreenState(this.user);

  Color themeColor = Color(0xFF4A148C);

  List<GraphData> graphData;

  List<String> itemGraphKey = new List();

  bool isGraphDataSet = false, isFireDataSet = false;

  int count = 0;
  int total = 0;

  final firebaseDatabase = FirebaseDatabase.instance;
  var historyReference;

  String date, time;

  @override
  void initState() {
    super.initState();

    graphData = [
      GraphData('0', 0),
    ];

    historyReference = firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("History");

    setGraphHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gas Log"),
        backgroundColor: themeColor,
        actions: [
          // ignore: deprecated_member_use
          IconButton(
              icon: Icon(
                Icons.clear_all,
                color: Colors.white,
              ),
              onPressed: () {
                historyReference.child("Gas").remove();
                setGraphHistory();
              })
        ],
      ),
      body: isGraphDataSet == false
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
                  style:
                      TextStyle(color: themeColor, fontWeight: FontWeight.w500),
                ),
                count > 0
                    ? Text(
                        "Loading " + count.toString() + "/" + total.toString(),
                        style: TextStyle(
                            color: themeColor, fontWeight: FontWeight.w500),
                      )
                    : Text("")
              ],
            )
          : Container(
              child: SfCartesianChart(
                borderWidth: 2,
                borderColor: themeColor,
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: 'Gas Detection History Graph'),
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <LineSeries<GraphData, String>>[
                  LineSeries<GraphData, String>(
                    color: themeColor,
                    name: "History",
                    dataSource: graphData,
                    xValueMapper: (GraphData graphData, _) => graphData.x,
                    yValueMapper: (GraphData graphData, _) => graphData.y,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
    );
  }

  void setGraphHistory() {
    itemGraphKey.clear();
    graphData.clear();
    var gasRef = historyReference.child("Gas");
    gasRef.once().then((DataSnapshot snapshot) async {
      if (snapshot.value != null) {
        snapshot.value.forEach((key, value) {
          itemGraphKey.add(key.toString());
          total++;
        });
        for (int i = 0; i < itemGraphKey.length; i++) {
          String gasData = (await gasRef
                  .child(itemGraphKey[i].toString())
                  .child("Value")
                  .once())
              .value
              .toString();
          setState(() {
            date = DateFormat('dd/MM/yyyy').format(DateTime.now());
            time = DateFormat('hh:mm:ss').format(DateTime.now());

            graphData = graphData +
                [
                  GraphData(
                      date + "\n" + time, double.parse((gasData).toString()))
                ];
            isGraphDataSet = true;
            count = i;
          });
        }
      } else {
        setState(() {
          isGraphDataSet = true;
        });
      }
    });
  }
}

class GraphData {
  String x;
  double y;

  GraphData(this.x, this.y);
}
