import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:get/get.dart';

class WeightCard extends StatelessWidget {
  final double currentWeight;
  final int type; // 0为减重，1为维持，2为增重
  final double initWeight;
  final double targetWeight;
  final VoidCallback onAdd;
  final VoidCallback onMore;
  const WeightCard({
    super.key,
    required this.currentWeight,
    required this.type,
    required this.initWeight,
    required this.targetWeight,
    required this.onAdd,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final percentGain =
        ((currentWeight - initWeight) / (targetWeight - initWeight)).clamp(0.0, 1.0);
    final percentLose =
        ((initWeight - currentWeight) / (initWeight - targetWeight)).clamp(0.0, 1.0);
    const percentMaintain = 1.0;
    return Container(
      width:  MediaQuery.of(context).size.width/2 - 25 - 10 ,
      height: 155,
      padding: const EdgeInsets.only(left:16,right:16,top:14),
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
                'WEIGHT'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: onAdd,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE6ECF5),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.black),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 95,
            width: 150,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                // 半圆进度条
                CustomPaint(
                  size: const Size(120, 40),
                  painter: SemiArcPainter(type==1?percentMaintain :type==0?percentLose:percentGain),
                ),
                Visibility(
                  visible: type!=1,
                  child: Positioned(
                  top: 45,
                  child: SizedBox(
                      width: 130,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(type==0?initWeight.toStringAsFixed(1):targetWeight.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                          Text(type==0?targetWeight.toStringAsFixed(1):initWeight.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      )),
                ),
                ),
                
                // 当前体重
                Positioned(
                  top: 65,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: currentWeight.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        TextSpan(
                          text: Controller.c.user['unitType']==0?' ${'KG'.tr}':' ${'LBS'.tr}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class SemiArcPainter extends CustomPainter {
  final double percent;

  SemiArcPainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFFE6ECF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = const Color(0xFFB6C6F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = pi * 1.15;
    const sweepAngle = pi * 0.7;

    // 背景半圆
    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);
    // 进度半圆
    canvas.drawArc(
        rect, startAngle, sweepAngle * percent, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
