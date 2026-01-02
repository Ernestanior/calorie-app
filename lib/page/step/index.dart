import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:calorie/common/icon/index.dart';
import 'package:calorie/components/actionSheets/steps.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/page/step/healthService.dart';
import 'package:calorie/page/step/stepChart.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/store/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

final GlobalKey chartKey = GlobalKey(); // 顶部添加

  Function calKcal=(int steps){
    return  (steps * Controller.c.user['currentWeight'] * 0.0005).round();
  };

class StepPage extends StatefulWidget {
  const StepPage({super.key});

  @override
  State<StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<StepPage> {
  final HealthService _healthService = HealthService();
  List<Map<String, dynamic>> _records = [];
  int todaySteps = 0;
  int targetSteps = Controller.c.user['targetStep'] ?? 8000;
  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    try {
      final data = await _healthService.getSteps(days: 90);
      final steps = await _healthService.getTodaySteps();
      setState(() {
        _records = data;
        todaySteps = steps;
      });
    } catch (e) {
      print('error $e');
    }
  }

  Future<void> _captureAndSharePng() async {
    try {
      // 请求权限
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        Get.snackbar('权限错误', '请授予存储权限');
        return;
      }

      final boundary =
          chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Get.snackbar('错误', '找不到图表区域');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 保存到临时文件用于分享
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // ✅ 保存到相册
      // final result = await ImageGallerySaver.saveImage(
      //   Uint8List.fromList(pngBytes),
      //   quality: 100,
      //   name: "WeightChart_${DateTime.now().millisecondsSinceEpoch}",
      // );

      // if (result['isSuccess'] == true) {
      //   Get.snackbar('保存成功', '图表已保存到相册');
      // } else {
      //   Get.snackbar('保存失败', '请检查权限或重试');
      // }

      // ✅ 分享图片
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      print('Error sharing chart: $e');
      Get.snackbar('分享失败', e.toString());
    }
  }

  Future<void> fetchData(int steps) async {
    if (Controller.c.user['id'] is int) {
      try {
        await userModify({
          'targetStep': steps,
        });
        UserInfo().getUserInfo();
        if (!mounted) return;
        setState(() {
          targetSteps = steps;
        });
      } catch (e) {
        print('$e error');
      }

      // final dayList = await detectionList();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'STEP'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                AliIcon.share,
                size: 26,
              ),
              onPressed: _captureAndSharePng,
            ),
          ],
        ),
        body: RepaintBoundary(
            key: chartKey,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 247, 246, 255),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Column(
                children: [
                  todayStep(todaySteps, targetSteps, fetchData),
                  const SizedBox(
                    height: 5,
                  ),
                  StepChart(recordList: _records),
                ],
              ),
            )));
  }
}

Widget todayStep(int todaySteps, int targetSteps, Function fetchData) {
  return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 10,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
         Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("TODAY_STEP".tr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            )
          ],
        ),
        Row(
          children: [
            stepCircle(todaySteps,targetSteps),
            Column(
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("$todaySteps",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text(" / ",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text("$targetSteps ",
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text("STEPS".tr,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(width: 5,),
                      GestureDetector(
                  onTap: () => Get.bottomSheet(StepsSheet(
                      steps: targetSteps, onChange: (step) => fetchData(step))),
                  child:const Icon(
                            AliIcon.edit4,
                            color: ui.Color.fromARGB(255, 0, 0, 0),
                            size: 20,
                          ))
                ]),
                 const SizedBox(
                            height: 15,
                          ),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      
                  Text("${calKcal(todaySteps)}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text(" / ",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text("${calKcal(targetSteps)} ",
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),

                      const SizedBox(width: 5,),
                      Text("BURNED_CALORIE".tr,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ]),
              //   GestureDetector(
              //     onTap: () => Get.bottomSheet(StepsSheet(
              //         steps: targetSteps, onChange: (step) => fetchData(step))),
              //     child: Container(
              //         width: 150,
              //         padding: const EdgeInsets.symmetric(
              //              vertical: 8),
              //         decoration: BoxDecoration(
              //             color: Colors.black,
              //             borderRadius: BorderRadius.circular(20)),
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             const Icon(
              //               Icons.edit,
              //               color: Colors.white,
              //               size: 12,
              //             ),
              //             const SizedBox(
              //               width: 6,
              //             ),
              //             Text(
              //               '${'EDIT'.tr} ${'TARGET_STEPS'.tr}',
              //               style: const TextStyle(
              //                   color: Colors.white,
              //                   fontWeight: FontWeight.bold,
              //                   fontSize: 12),
              //               textAlign: TextAlign.center,
              //             ),
              //           ],
              //         )),
              //   )
              ],
            )
          ],
        ),
      ]));
}

Widget stepCircle(int todayStep,int targetStep){
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
    child: CircularPercentIndicator(
      radius: 50.0,
      lineWidth: 10.0,
      animation: true,
      percent: min(1, todayStep / targetStep),
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
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AliIcon.foot,
                size: 40,
                color: Color.fromARGB(255, 255, 176, 7),
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
  );
}
