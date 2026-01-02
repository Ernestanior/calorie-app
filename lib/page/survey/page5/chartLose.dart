import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WeightGoalChartLose extends StatefulWidget {
    final double displayCurrent;
    final double displayTarget;
    final String unit;
    const WeightGoalChartLose({
      super.key,
      required this.displayCurrent,
      required this.displayTarget,
      required this.unit,
    });
  @override
  _WeightGoalChartLoseState createState() => _WeightGoalChartLoseState();
}

class _WeightGoalChartLoseState extends State<WeightGoalChartLose> {
  late List<ChartData> _chartData;

  @override
  void initState() {

    super.initState();
    _chartData = _generateChartData();
  }

  /// 生成数据，确保起点在顶部 (100kg)，终点在底部 (0kg)
  List<ChartData> _generateChartData() {
    return [
      ChartData('Today', 95, Colors.red),   // 起点 (显示)
      ChartData('Step1', 90, Colors.purple), // 中间点 (隐藏)
      ChartData('Step2', 60, Colors.blue),   // 中间点 (隐藏)
      ChartData('Step3', 20, Colors.indigo), // 中间点 (隐藏)
      ChartData('Goal', 5, Colors.blue),    // 终点 (显示)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [Color.fromARGB(255, 241, 21, 6),Color.fromARGB(255, 255, 114, 104),Color.fromARGB(255, 2, 240, 205),Color.fromARGB(255, 29, 153, 241)], // 从红色到蓝色
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: SfCartesianChart(
            primaryXAxis: const NumericAxis(isVisible: false), // 隐藏 X 轴
            primaryYAxis: const NumericAxis(isVisible: false, minimum: 0, maximum: 100), // 隐藏 Y 轴

            series: [
              /// SplineSeries 生成平滑曲线
              SplineSeries<ChartData, int>(
                dataSource: _chartData,
                xValueMapper: (ChartData data, _) => _chartData.indexOf(data),
                yValueMapper: (ChartData data, _) => data.value,
                color: Colors.white,
                width: 6,
                markerSettings: const MarkerSettings(
                  isVisible: false, // 先显示所有点
                  shape: DataMarkerType.circle,
                  borderWidth: 3,
                  borderColor: Color.fromARGB(0, 187, 31, 31),
                ),
                pointColorMapper: (ChartData data, index) {
                  return Colors.transparent;
                  // 只让起点和终点的标记可见
                  // return (index == 0 || index == _chartData.length - 1) ? const Color.fromARGB(0, 218, 48, 48) : Colors.transparent;
                },
                
              )
            ],
          )),
          Positioned(
            top:33,
            child:Container(
              padding: const EdgeInsets.symmetric(vertical: 3,horizontal: 10),
              decoration: BoxDecoration(color: const Color.fromARGB(255, 252, 138, 130),borderRadius: BorderRadius.circular(20)),
              child: Text('${widget.displayCurrent} ${widget.unit}',style: const TextStyle(color: Colors.white,fontSize: 12),),
            ),
          ),
          Positioned(
            top:3,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color.fromARGB(150, 255, 221, 219),borderRadius: BorderRadius.circular(20)),
                  child:Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(color: const Color.fromARGB(255, 241, 21, 6),borderRadius: BorderRadius.circular(10)),
                  )  
                )
              ],
            ) 
          ),
          Positioned(
            bottom:33,
            right: 0,
            child:Container(
              padding: const EdgeInsets.symmetric(vertical: 3,horizontal: 10),
              decoration: BoxDecoration(color: const Color.fromARGB(255, 79, 181, 255),borderRadius: BorderRadius.circular(20)),
              child: Text('${widget.displayTarget} ${widget.unit}',style: const TextStyle(color: Colors.white,fontSize: 12),),
            ),
          ),
          Positioned(
            bottom:3,
            right:0,
            child: Container(
              padding:const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color.fromARGB(149, 200, 230, 255),borderRadius: BorderRadius.circular(20)),
              child:Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(color: const Color.fromARGB(255, 29, 153, 241),borderRadius: BorderRadius.circular(10)),
                )  
              )
          ),
        ],
      ),);
    
  }
}

/// 数据类
class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
