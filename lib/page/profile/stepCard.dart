import 'package:calorie/common/icon/index.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class StepCard extends StatelessWidget {
  final int todaySteps;
  final int targetSteps;
  final bool permission;

  const StepCard({
    super.key,
    required this.todaySteps,
    required this.targetSteps,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 25 - 5,
      height: 155,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(31, 146, 154, 218),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP'.tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              permission?Icon(AliIcon.right,size: 20,weight: 0.1,):Container(
                padding: EdgeInsets.symmetric(vertical: 2,horizontal: 10),
                                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 229, 210),
                          borderRadius: BorderRadius.circular(20)),
                child: Text('PERMISSION_REQUIRE'.tr,style: TextStyle(fontSize: 11,fontWeight: FontWeight.bold,color: const Color.fromARGB(255, 253, 152, 20)),),)
            ],
          ),
          const SizedBox(
            height: 6,
          ),
          todaySteps!=0?SizedBox(
            child: CircularPercentIndicator(
              radius: 55.0,
              lineWidth: 10.0,
              animation: true,
              percent: min(1, todaySteps / targetSteps),
              center: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(150, 255, 255, 255),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(148, 255, 241, 228),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        '${todaySteps}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '/${targetSteps} ${'STEPS'.tr}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              arcType: ArcType.FULL,
              arcBackgroundColor: const Color.fromARGB(146, 255, 217, 159),
              backgroundColor: Colors.pink,
              progressBorderColor: const Color.fromARGB(147, 255, 205, 161),
              progressColor: const Color.fromARGB(255, 255, 179, 0),
            ),
          ):
          SizedBox(
            child: CircularPercentIndicator(
              radius: 55.0,
              lineWidth: 10.0,
              animation: true,
              percent: min(1, todaySteps / targetSteps),
              center: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(150, 255, 255, 255),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(148, 255, 241, 228),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      Icon(
                AliIcon.foot,
                size: 40,
                color: Color.fromARGB(255, 255, 176, 7),
              ),
               const SizedBox(
                        height: 5,
                      ),
              Text(
                        'NO_AUTH'.tr,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              arcType: ArcType.FULL,
              arcBackgroundColor: const Color.fromARGB(146, 255, 217, 159),
              backgroundColor: Colors.pink,
              progressBorderColor: const Color.fromARGB(147, 255, 205, 161),
              progressColor: const Color.fromARGB(255, 255, 179, 0),
            ),
          )
          ,
        ],
      ),
    );
  }
}
