import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wheel_slider/wheel_slider.dart';

class SurveyPage3Weight extends StatefulWidget {
  final int unitType;

  final double weight;
  final Function onChangeWeight;

  final Function onChangeType;
  const SurveyPage3Weight(
      {super.key,
      required this.unitType,
      required this.weight,
      required this.onChangeWeight,
      required this.onChangeType});
  @override
  State<SurveyPage3Weight> createState() => _SurveyPage3WeightState();
}

class _SurveyPage3WeightState extends State<SurveyPage3Weight> {
  double getLeftPosition(int index) {
    return index * 150; // 控制白色方框的移动位置
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double currentWeight = widget.weight;
    String unitType = widget.unitType == 1 ? 'lbs' : 'kg';

    List unitList = [
      {'value': 'metric', 'label': 'METRIC'.tr, 'weightUnit': 'KG'.tr},
      {'value': 'imperial', 'label': 'IMPERIAL'.tr, 'weightUnit': 'LBS'.tr},
    ];

    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('YOUR_WEIGHT'.tr,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 300,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 227, 243, 255), // 背景色
                  borderRadius: BorderRadius.circular(25), // 外围圆角
                ),
                child: Stack(
                  children: [
                    // 移动的白色方框（忽略手势，避免拦截点击）
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      left: getLeftPosition(widget.unitType),
                      child: IgnorePointer(
                        child: Container(
                          width: 150, // 每个选项的宽度
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white, // 选中时的背景色
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4, // 阴影效果
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 选项文本
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: unitList.asMap().entries.map((entry) {
                        int index = entry.key;
                        String text = entry.value['label'];
                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () => widget.onChangeType(index),
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.unitType == index
                                      ? Colors.black
                                      : Colors.black54, // 选中变黑色，未选中变浅灰
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 80,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      currentWeight.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 30),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      unitType,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Visibility(
                  visible: unitType == 'kg',
                  child: WheelSlider(
                    interval: 0.5,
                    totalCount: 1700,
                    initValue: double.parse(((currentWeight - 30) * 5).toStringAsFixed(1)),
                    isInfinite: false,
                    enableAnimation: false,
                    onValueChanged: (val) {
                      widget.onChangeWeight((30 + val * 0.2).toDouble());
                    },
                    hapticFeedbackType: HapticFeedbackType.selectionClick,
                  ),
                ),
                Visibility(
                  visible: unitType == 'lbs',
                  child: WheelSlider(
                    interval: 0.5,
                    totalCount: 3740,
                    initValue: double.parse(((currentWeight - 66) * 5).toStringAsFixed(1)),
                    isInfinite: false,
                    enableAnimation: false,
                    onValueChanged: (val) {
                      widget.onChangeWeight((66 + val * 0.2).toDouble());
                    },
                    hapticFeedbackType: HapticFeedbackType.selectionClick,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        ));
  }
}
