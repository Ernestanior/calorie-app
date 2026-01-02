import 'package:calorie/common/icon/index.dart';
import 'package:calorie/common/util/utils.dart';
import 'package:calorie/components/languageSelector/index.dart';
import 'package:calorie/page/survey/page1.dart';
import 'package:calorie/page/survey/page2.dart';
import 'package:calorie/page/survey/page3Height.dart';
import 'package:calorie/page/survey/page3Weight.dart';
import 'package:calorie/page/survey/page4Gain.dart';
import 'package:calorie/page/survey/page4Lose.dart';
import 'package:calorie/page/survey/page5/index.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MultiStepForm extends StatefulWidget {
  const MultiStepForm({super.key});

  @override
  _MultiStepFormState createState() => _MultiStepFormState();
}

class _MultiStepFormState extends State<MultiStepForm> {
  String language = getLocaleFromCode(Controller.c.user['lang']).label;
  String languageCode = getLocaleFromCode(Controller.c.user['lang']).code;
  String emoji = getLocaleFromCode(Controller.c.user['lang']).emoji;

  final PageController _pageController = PageController();
  List dietList = [
    {
      'label': "DIET_CLASSIC".tr,
      'icon': AliIcon.meat2,
      'color': const Color.fromARGB(255, 255, 94, 94)
    },
    {
      'label': "DIET_VEGETARIAN".tr,
      'icon': AliIcon.vegetable,
      'color': const Color.fromARGB(255, 0, 175, 29),
      'size': 28.0
    },
    {
      'label': "DIET_NO_FISH".tr,
      'icon': AliIcon.nofish,
      'color': const Color.fromARGB(255, 27, 183, 255),
      'size': 28.0
    }
  ];

  int _currentPage = 0;

  int gender =
      (Controller.c.user['gender'] == null || Controller.c.user['gender'] == 0)
          ? 1
          : Controller.c.user['gender'];
  int age = (Controller.c.user['age'] == null || Controller.c.user['age'] == 0)
      ? 20
      : Controller.c.user['age'];
  int targetType = Controller.c.user['targetType'] ?? 0; // 0为减重，1为维持当前，2为增重
  int timeSelected = 0; // 0为每周0-2次，1为每周3-5次，2为每周6+次、
  int dietSelected = 0; //0为荤食，1为素食

  // 公制原始值
  int initType = Controller.c.user['unitType'] ?? 0; // 0为公制，1为英制
  int initHeight =
      (Controller.c.user['height'] == null || Controller.c.user['height'] == 0)
          ? 170
          : Controller.c.user['height'];
  double initWeight = (Controller.c.user['currentWeight'] == null ||
          Controller.c.user['currentWeight'] == 0)
      ? 70.0
      : (Controller.c.user['currentWeight'] as num).toDouble();

  int unitType = Controller.c.user['unitType'] ?? 0; // 0为公制，1为英制
  int height =
      (Controller.c.user['height'] == null || Controller.c.user['height'] == 0)
          ? 170
          : Controller.c.user['height'];
  double currentWeight = (Controller.c.user['currentWeight'] == null ||
          Controller.c.user['currentWeight'] == 0)
      ? 70.0
      : (Controller.c.user['currentWeight'] as num).toDouble();

  int slideIndex = 0; //体重滚轮滑动的格数

  bool switchBtn = true;

  double planWeight = 0.4;
  void _finish() async {
    var arguments = {
      "id": Controller.c.user['id'],
      "age": age,
      "gender": gender,
      "lang": getLocaleFromCode(Controller.c.user['lang']).code,
      "height": height,
      "unitType": unitType,
      "targetType": targetType,
      "initWeight": currentWeight,
      "targetWeight":
          targetType == 1 ? currentWeight : currentWeight + slideIndex * 0.1,
      "weeklyWeightChange": targetType == 1 ? 0 : planWeight,
      "dietaryFavorList": [dietSelected],
      "activityFactor": timeSelected == 0
          ? 1.2
          : timeSelected == 1
              ? 1.4
              : 1.6,
    };
    Get.toNamed("/surveyAnalysis", arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    // 动态生成 pages
    List<Widget> pages = [
      SurveyPage1(
          gender: gender, onChange: (value) => setState(() => gender = value)),
      // SurveyResult(),
      SurveyPage2(
          age: age,
          onChange: (value) {
            setState(() => age = value);
          }),
      SurveyPage3Weight(
        unitType: unitType,
        onChangeType: (value) {
          setState(() {
            unitType = value;
            slideIndex = 0; //重置其他刻度尺的进度
            // 切换为原来的制度
            if (initType == value) {
              height = initHeight;
              currentWeight = initWeight;
            } else {
              if (value == 0) {
                // 英制 → 公制
                height = (initHeight * 2.54).round();
                currentWeight =
                    double.parse((initWeight * 0.4536).toStringAsFixed(1));
              } else {
                // 公制 → 英制
                height = (initHeight / 2.54).round();
                currentWeight =
                    double.parse((initWeight * 2.2046).toStringAsFixed(1));
              }
            }
          });
        },
        weight: currentWeight,
        onChangeWeight: (val) {
          double value = double.parse(val.toStringAsFixed(1));
          setState(() {
            initWeight = value;
            if (currentWeight != value) {
              slideIndex = 0;
            }
            currentWeight = value;

            if (initType != unitType) {
              initType = unitType;
              initHeight = height;
            }
          });
        },
      ),
      SurveyPage3Height(
          unitType: unitType,
          height: height,
          onChangeHeight: (value) {
            setState(() {
              initHeight = value;
              height = value;
              if (initType != unitType) {
                initWeight = currentWeight;
                initType = unitType;
              }
            });
          }),
      _buildPage(
        "WHAT_IS_YOUR_GOAL".tr,
        [
          {'label': "LOSE_WIEGHT".tr, 'icon': AliIcon.running},
          {'label': "MAINTAIN".tr, 'icon': AliIcon.handle},
          {'label': "GAIN_WIEGHT".tr, 'icon': AliIcon.milktea}
        ],
        targetType,
        (value) {
          setState(() => targetType = value);
          slideIndex = 0;
        },
      ),
      _buildPage(
        "WEEKLY_LEVEL_QUESTION".tr,
        [
          {'label': "WEEKLY_LEVEL_1".tr, 'icon': AliIcon.laptop},
          {'label': "WEEKLY_LEVEL_2".tr, 'icon': AliIcon.shoes},
          {'label': "WEEKLY_LEVEL_3".tr, 'icon': AliIcon.dumbbell}
        ],
        timeSelected,
        (value) => setState(() => timeSelected = value),
      ),
    ];

    // 根据 targetType 添加 SurveyPage4Lose 或 SurveyPage4Gain
    if (targetType == 2) {
      pages.add(SurveyPage4Gain(
        unitType: unitType,
        weight: currentWeight + slideIndex * 0.1,
        slideIndex: slideIndex,
        onChangeSlides: (val) {
          setState(() {
            slideIndex = val;
          });
        },
      ));
      pages.add(SurveyPage5(
          targetType: targetType,
          unitType: unitType,
          current: currentWeight,
          target: currentWeight + slideIndex * 0.1,
          selectedWeight: planWeight,
          onChange: (value) => setState(() => planWeight = value)));
    } else if (targetType == 0) {
      pages.add(SurveyPage4Lose(
        unitType: unitType,
        weight: currentWeight + slideIndex * 0.1,
        slideIndex: slideIndex,
        onChangeSlides: (val) {
          setState(() {
            slideIndex = val;
          });
        },
      ));
      pages.add(SurveyPage5(
          targetType: targetType,
          unitType: unitType,
          current: currentWeight,
          target: currentWeight + slideIndex * 0.1,
          selectedWeight: planWeight,
          onChange: (value) => setState(() => planWeight = value)));
    }

    // 添加之后的固定页面
    // pages.addAll([
    //         _buildPage(
    //     "DIET_TYPE".tr,
    //     dietList,
    //     dietSelected,
    //     (value)=>setState(()=>dietSelected=value),
    //   ),
    // ]);
    return Scaffold(
      body: SafeArea(child:   Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    AliIcon.back,
                    size: 45,
                    color: Color(0xC5291B30),
                  ),
                  onPressed: _currentPage > 0 ? _prevPage : Get.back,
                ),
                const LanguageSelector()
              ],
            ),
            const SizedBox(
              height: 18,
            ), // 返回按钮
            // 添加动画的进度条
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: (_currentPage + 1) / pages.length,
                end: (_currentPage + 1) / pages.length,
              ),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return SizedBox(
                  width: 280,
                  child: Stack(
                    children: [
                      // 背景条（未完成部分）
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white, // 未完成部分颜色
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // 已完成部分（渐变色）
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 10,
                            width: constraints.maxWidth * value,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(197, 133, 113, 143),
                                  Color.fromARGB(197, 92, 60, 107),
                                  Color(0xC5291B30),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: pages),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xC5291B30),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                ),
                onPressed:
                    _currentPage < pages.length - 1 ? _nextPage : _finish,
                child: _currentPage < pages.length - 1
                    ? Text("NEXT_STEP".tr,
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold))
                    : Text("START_MAKING_PLAN".tr,
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
              const SizedBox(height: 10,)

          ],
        ),
      ),
   
      ) 
     );
  }

  Widget _buildPage(
      String title, List options, int PageIndex, Function onChange) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Column(
            children: options.asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value['label'];
              IconData icon = entry.value['icon'];
              Color color = entry.value['color'] ?? const Color(0xC5291B30);
              double size = entry.value['size'] ?? 24.0;
              bool isSelected = PageIndex == index;

              return GestureDetector(
                onTap: () => onChange(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 187, 223, 255)
                          : const Color.fromARGB(255, 239, 249, 255),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: size, color: color),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          option,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xC5291B30),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // void _updatePages() {
  //   int maxPages = targetType == 1 ? 5 : 6; // 维持现状少一个页面

  //   if (_currentPage >= maxPages) {
  //     _pageController.jumpToPage(maxPages - 1);
  //     setState(() {
  //       _currentPage = maxPages - 1;
  //     });
  //   }
  // }

  void _nextPage() {
    if (_currentPage < _pageController.positions.first.maxScrollExtent) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 100), curve: Curves.ease);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 100), curve: Curves.ease);
    }
  }
}
