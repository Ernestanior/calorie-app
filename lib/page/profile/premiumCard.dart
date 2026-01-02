import 'package:calorie/common/icon/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PremiumCard extends StatefulWidget {
  const PremiumCard({super.key});

  @override
  _PremiumCardState createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          // Navigator.pushNamed(context, '/premium');
        },
        child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 内边距
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 0, 0),
                  Color.fromARGB(255, 91, 91, 91)
                ], // 渐变背景
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    // 左边图标
                    const Icon(
                      AliIcon.vip3, // 你也可以换成其他 premium 图标
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 15),

                    // 中间文字
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FUEL_YOUR_HEALTH".tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "ENJOY_ALL_FEATURES_FOR_FREE".tr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                  ],
                ),
                const Positioned(
                  top: 7,
                  right: 10,
                  child: Opacity(
                    opacity: 0.15,
                    child: Icon(
                      AliIcon.diamond3, // 这里用奖杯/皇冠类的图标
                      color: Colors.white,
                      size: 55,
                    ),
                  ),
                )
              ],
            )));
  }
}
