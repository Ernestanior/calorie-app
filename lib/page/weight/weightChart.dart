import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WeightChart extends StatefulWidget {
  final String unitType;
  final List<dynamic> recordList;
  final double targetWeight;

  const WeightChart({super.key, required this.unitType,required this.recordList,required this.targetWeight});
  @override
  _WeightChartState createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  int selectedRangeIndex = 0;

  final List<String> ranges = ['LAST_WEEK'.tr, 'LAST_MONTH'.tr, 'LAST_YEAR'.tr];

  // final List<Map<String, dynamic>> recordList = [
  //   {'date': 'Jun 1', 'weight': 79.1},
  //   {'date': 'Jun 5', 'weight': 75.1},
  //   {'date': 'Jun 11', 'weight': 77.4},
  //   {'date': 'Jun 12', 'weight': 75.3},
  //   {'date': 'Jun 13', 'weight': 74.1},
  //   {'date': 'Jun 15', 'weight': 76.1}, 
  //   {'date': 'Jun 20', 'weight': 72.1},
  //   {'date': 'Jun 25', 'weight': 75.1},
  //   {'date': 'Jun 29', 'weight': 75.1},
  //   {'date': 'Jul 1', 'weight': 74.3},
  //   {'date': 'Jul 3', 'weight': 76},
  //   {'date': 'Jul 4', 'weight': 75},
  //   {'date': 'Jul 5', 'weight': 74.5},
  //   {'date': 'Jul 6', 'weight': 74},
  //   {'date': 'Jul 7', 'weight': 77},
  // ];

  // 直接按后端返回的 yyyy-MM-dd 字符串解析，保留真实年份
  DateTime parseDate(String str) {
    return DateTime.parse(str);
  }

  List get filteredRecords {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (selectedRangeIndex) {
      case 0: // 最近一周
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 1: // 最近一月（约 30 天）
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 2: // 最近一年（约 365 天）
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return widget.recordList
        .where((record) {
          final String raw = record['date']?.toString() ?? '';
          if (raw.isEmpty) return false;
          DateTime date = parseDate(raw);
          return !date.isBefore(startDate) && !date.isAfter(now);
        })
        .toList()
      ..sort((a, b) => parseDate(a['date'].toString()).compareTo(parseDate(b['date'].toString())));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recordList.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          'NO_RECORDS'.tr,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    final List data = filteredRecords;
    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (int i = 0; i < data.length; i++) {
      final String raw = data[i]['date']?.toString() ?? '';
      final DateTime dt = parseDate(raw);
      spots.add(FlSpot(i.toDouble(), (data[i]['weight'] as num).toDouble()));
      // X 轴展示简短的月份+日期，如 "Jan 2"
      labels[i] = DateFormat('MMM d', 'en_US').format(dt);
    }
    double minY = [...spots.map((e) => e.y), widget.targetWeight].reduce((a, b) => a < b ? a : b);
    double maxY = [...spots.map((e) => e.y), widget.targetWeight].reduce((a, b) => a > b ? a : b);
    double yRange = (maxY - minY) ==0?1:(maxY - minY) ;
    minY = (minY - yRange * 0.1).floorToDouble();
    maxY = (maxY + yRange * 0.1).ceilToDouble();
    double intervalY = ((maxY - minY) / 6).ceilToDouble() ;

    List<int> xLabelIndexes = [];
    int len = labels.length;
    if (len > 0) {
      if (selectedRangeIndex == 0) {
        xLabelIndexes = [0, len ~/ 2, len - 1];
      } else {
        xLabelIndexes = [0, len ~/ 4, len ~/ 2, (len * 3 ~/ 4), len - 1];
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEIGHT_CHANGE'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25), 
          // Range Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ranges.map((range) {
              final isSelected = selectedRangeIndex == ranges.indexOf(range);
              return GestureDetector(
                onTap: () => setState(() => selectedRangeIndex = ranges.indexOf(range) ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          // Chart
          SizedBox(
            height: 250,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (spots.length * 50).toDouble().clamp(300, 1000),
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX:
                        spots.isNotEmpty ? (spots.length - 1).toDouble() : 1,
                    minY: minY,
                    maxY: maxY,
                    gridData: const FlGridData(show: false), // 不显示辅助线
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: widget.targetWeight,
                          color: const Color.fromARGB(255, 7, 228, 18),
                          strokeWidth: 2,
                          dashArray: [3],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 0, 218, 47),
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                            labelResolver: (_) => 'TARGET_WEIGHT'.tr,
                          ),
                        ),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.black87,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((barSpot) {
                            final index = barSpot.x.toInt();
                            final weight =
                                barSpot.y.toStringAsFixed(1);
                            final date = labels[index] ?? '';
                            return LineTooltipItem(
                              '$date\n$weight ${widget.unitType}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                      getTouchedSpotIndicator:
                          (barData, spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            const FlLine(color: Colors.blue, strokeWidth: 1,dashArray:[3]),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: const Color.fromARGB(255, 0, 218, 47),
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                            ),
                          );
                        }).toList();
                      },
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            if (xLabelIndexes.contains(value.toInt())) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6), // ✅ 向下偏移
                                child: Text(
                                  labels[value.toInt()] ?? '',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: intervalY,
                          getTitlesWidget: (value, _) => Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10), // Y轴字体变小
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 2,
                        color: Colors.blue,
                        dotData: FlDotData(show: true,getDotPainter: (FlSpot spot, double xPercentage, LineChartBarData bar, int index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color:  Colors.blue,
                              strokeColor:  const Color.fromARGB(255, 255, 255, 255),
                            );
                          },),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color.fromARGB(255, 159, 202, 255).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
