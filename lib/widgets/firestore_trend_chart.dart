import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FirestoreTrendChart extends StatelessWidget {
  final int selectedHours;
  final int veryLow;
  final int targetMin;
  final int targetMax;
  final int veryHigh;

  const FirestoreTrendChart({
    Key? key,
    required this.selectedHours,
    required this.veryLow,
    required this.targetMin,
    required this.targetMax,
    required this.veryHigh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text("Not signed in"));
    }

    final since = DateTime.now().toUtc().subtract(Duration(hours: selectedHours));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('glucose_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No data"));

        // Convert Firestore docs to chart data:
        List<FlSpot> spots = [];
        List<String> hourLabels = [];

        for (int i = 0; i < docs.length; i++) {
          final doc = docs[i];
          DateTime dt;
          final ts = doc['timestamp'];
          if (ts is Timestamp) {
            dt = ts.toDate();
          } else if (ts is int) {
            dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          } else if (ts is String) {
            dt = DateTime.tryParse(ts) ?? DateTime.now();
          } else {
            continue;
          }
          spots.add(FlSpot(i.toDouble(), (doc['value'] as num).toDouble()));
          hourLabels.add("${dt.hour.toString().padLeft(2, '0')}:00");
        }

        // Calculate dynamic Y-axis bounds
        final minSpotY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
        final maxSpotY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        final minY = [minSpotY, veryLow.toDouble()].reduce((a, b) => a < b ? a : b) - 20;
        final maxY = [maxSpotY, veryHigh.toDouble()].reduce((a, b) => a > b ? a : b) + 20;
        final yRange = maxY - minY;
        final yInterval = yRange / 10;

        return AspectRatio(
          aspectRatio: 1.7,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (value, _) {
                        final intValue = value.toInt();
                        if (intValue == veryLow) {
                          return const Text("veryLow", style: TextStyle(fontSize: 11));
                        } else if (intValue == targetMin) {
                          return const Text("targetMin", style: TextStyle(fontSize: 11));
                        } else if (intValue == targetMax) {
                          return const Text("targetMax", style: TextStyle(fontSize: 11));
                        } else if (intValue == veryHigh) {
                          return const Text("veryHigh", style: TextStyle(fontSize: 11));
                        }
                        return const Text("");
                      },
                      interval: yInterval,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: spots.length > 10 ? (spots.length / 5).ceilToDouble() : 1,
                      getTitlesWidget: (value, _) {
                        int idx = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Transform.rotate(
                            angle: -0.45,
                            child: Text(
                              idx >= 0 && idx < hourLabels.length ? hourLabels[idx] : '',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.pinkAccent]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.2),
                          Colors.pinkAccent.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
