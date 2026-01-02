// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:calorie/page/survey/page5/chartGain.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:calorie/page/survey/page5/chartLose.dart';

class SurveyPage5 extends StatefulWidget {
  final int targetType;
  final int unitType;// 0为公斤，1为英镑
  final double current;
  final double target;
  final double selectedWeight;
  final Function onChange;
  const SurveyPage5({
    super.key,
    required this.unitType,
    required this.targetType,
    required this.current,
    required this.target,
    required this.selectedWeight,
    required this.onChange
  });

  @override
  _SurveyPage5State createState() => _SurveyPage5State();
}

class _SurveyPage5State extends State<SurveyPage5> {
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    double displayCurrent = double.parse(widget.current.toStringAsFixed(1));
    double displayTarget = double.parse(widget.target.toStringAsFixed(1));
    
    String unit = widget.unitType==0?'kg':'lbs';
    int weeks = ((displayTarget-displayCurrent).abs()/widget.selectedWeight).ceil();
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SizedBox(height: 20),
          Text('WEEKLY_GOAL'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Visibility(
            visible: widget.targetType==0,
            child: WeightGoalChartLose(displayCurrent: displayCurrent,displayTarget: displayTarget,unit: unit,),
          ),
          Visibility(
            visible: widget.targetType==2,
            child: WeightGoalChartGain(displayCurrent: displayCurrent,displayTarget: displayTarget,unit: unit,),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TODAY'.tr,style: const TextStyle(color:Color.fromARGB(255, 111, 111, 111)),),
              Text('NUMBER_OF_WEEKS'.trParams({'number':'$weeks'}),style: const TextStyle(color:Color.fromARGB(255, 111, 111, 111)),)
            ],
           ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${widget.selectedWeight.toStringAsFixed(1)} $unit",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ) ,
            Slider(
              value: widget.selectedWeight,
              min: 0.1,
              max: unit=='kg'? 1.0:2.5,
              divisions: unit=='kg'?9:24,
              label: "${widget.selectedWeight.toStringAsFixed(1)} $unit",
              activeColor:Colors.blue,
              onChanged: (value) {
                // setState(() {
                //   widget.selectedWeight = value;
                // });
                widget.onChange(double.parse(value.toStringAsFixed(1)));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("0.1 $unit"), Text("${unit=='kg'?'1.0':'2.5'} $unit")],
            ),
            const SizedBox(height: 30),
            Center(
              child: 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 10),
                decoration: BoxDecoration(color: const Color.fromARGB(255, 237, 240, 250),borderRadius: BorderRadius.circular(50)),
                child:Text("WEEKLY_GOAL_TIME".trParams({'week':'$weeks'}),style: const TextStyle(fontSize: 14),),
           ) )
            ],
        ),);
  
  }


}

 