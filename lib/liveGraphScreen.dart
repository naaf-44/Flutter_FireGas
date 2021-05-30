import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiver/async.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class liveGraphScreen extends StatefulWidget {
  final String user;

  liveGraphScreen({Key key, @required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return liveGraphScreenState(user);
  }
}

class liveGraphScreenState extends State<liveGraphScreen> {
  String user;

  liveGraphScreenState(this.user);

  Color themeColor = Color(0xFF4A148C);

  List<GraphData> graphData;

  final firebaseDatabase = FirebaseDatabase.instance;
  var liveDataReference;

  String date, time;
  CountdownTimer countdownTimer;

  String lastValue = "";

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

    graphData = [
      GraphData('0', 0),
    ];

    liveDataReference = firebaseDatabase
        .reference()
        .child("FireGasDetection")
        .child("User")
        .child(user)
        .child("LiveData");

    setGraphData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Graph"),
        backgroundColor: themeColor,
      ),
      body: Center(
        child: Container(
          child: SfCartesianChart(
            borderWidth: 2,
            borderColor: themeColor,
            primaryXAxis: CategoryAxis(),
            title: ChartTitle(text: 'Gas Detection Live Graph'),
            legend: Legend(isVisible: true),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <LineSeries<GraphData, String>>[
              LineSeries<GraphData, String>(
                color: themeColor,
                name: "Live",
                dataSource: graphData,
                xValueMapper: (GraphData graphData, _) => graphData.x,
                yValueMapper: (GraphData graphData, _) => graphData.y,
                dataLabelSettings: DataLabelSettings(isVisible: true),
              )
            ],
          ),
        ),
      ),
    );
  }

  void setGraphData() {
    print("setGraphData");
    countdownTimer =
        new CountdownTimer(new Duration(seconds: 60), new Duration(seconds: 5));
    // ignore: cancel_subscriptions
    var sub = countdownTimer.listen(null);
    sub.onData((duration) async {
      String gasData =
          (await liveDataReference.child("Gas").once()).value.toString();
      if (mounted) {
        setState(() {
          date = DateFormat('dd/MM/yyyy').format(DateTime.now());
          time = DateFormat('hh:mm:ss').format(DateTime.now());

          if (lastValue != gasData) {
            graphData = graphData +
                [
                  GraphData(
                      date + "\n" + time, double.parse((gasData).toString()))
                ];
            lastValue = gasData;
          }
        });
      }
    });
    sub.onDone(() async {
      countdownTimer.cancel();
      setGraphData();
    });
  }
}

class GraphData {
  String x;
  double y;

  GraphData(this.x, this.y);
}
