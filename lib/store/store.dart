import 'dart:io';

import 'package:calorie/common/util/utils.dart';
import 'package:calorie/components/dialog/starRating.dart';
import 'package:calorie/network/api.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

class Controller extends GetxController {
  static Controller get c => Get.find();
  var tab = 'home'.obs;
  var tabIndex = 0.obs;
  var deviceId = ''.obs;
  var userAgent = ''.obs;
  var token = ''.obs;
  var user = RxMap<String, dynamic>(initUser);
  var image = RxMap<String, dynamic>({'mealType': 0, 'path': ""});
  var lang = 'en_US'.obs;

  var loadingCount = 0.obs;

  bool get isLoading => loadingCount > 0;

  void showLoading() => loadingCount++;
  void hideLoading() {
    if (loadingCount > 0) loadingCount--;
  }

  RxBool refreshHomeDataTrigger = false.obs;
  var foodDetail = RxMap<String, dynamic>({});
  RxBool scanState = true.obs;
  var scanResult = RxMap<String, dynamic>({});

  Locale get currentLocale {
    final langCode = user['lang'];
    return getLocaleFromCode(langCode).value;
  }

  // 👇 新增分析任务状态
  var isAnalyzing = false.obs;
  var analyzingProgress = 0.0.obs; // 范围 0~1
  var analyzingFilePath = ''.obs;

  get recipeSets => null;

  Future<void> startAnalyzing() async {
    if (image['path'] is! String) return;

    isAnalyzing.value = true;
    analyzingFilePath.value = image['path'];
    analyzingProgress.value = 0.0;

    /// 👇 用于控制模拟进度是否继续
    bool isRealRequestFinished = false;

    /// 👇 模拟进度（可中断）
    Future<void> simulateProgress() async {
      for (int i = 1; i <= 4; i++) {
        if (isRealRequestFinished) return; // 如果真实请求已完成，就终止模拟
        await Future.delayed(const Duration(milliseconds: 5000));
        analyzingProgress.value = i * 0.2;
      }
    }

    // 启动模拟进度
    simulateProgress();

    // 执行真实上传与分析请求
    try {
      File imageFile = File(image['path']);
      dio.FormData formData = dio.FormData.fromMap({
        "file": await dio.MultipartFile.fromFile(imageFile.path,
            filename: "upload.jpg"),
      });

      final url = await fileUpload(formData);
      if (url == null) {
        isAnalyzing.value = false;
        return;
      }

      await detectionCreate({
        'userId': Controller.c.user['id'],
        'mealType': Controller.c.image['mealType'],
        'sourceImg': imgUrl + url
      });

      isRealRequestFinished = true; // ✅ 真实请求已完成，终止模拟进度
      analyzingProgress.value = 1;

      isAnalyzing.value = false;

      // 检查是否是首次打卡
      if (Controller.c.user['firstTry'] == 0) {
        // 更新 firstTry 为 1
        try {
          var res = await userModify({'firstTry': 1});
          if (res != '-1') {
            Controller.c.user(res);
            // 延迟显示评分弹窗，让用户看到分析完成的效果
          }
          Future.delayed(const Duration(milliseconds: 1500), () async {
              final InAppReview inAppReview = InAppReview.instance;
              if (await inAppReview.isAvailable()) {
                // 优先尝试使用原生评分弹窗
                await inAppReview.requestReview();
              } else {
                // 如果原生评分不可用，则跳转到 App Store
                  await inAppReview.openStoreListing();
              }
            });
        } catch (e) {
          print('err $e');
        }
      }

      // 触发首页刷新
      Controller.c.refreshHomeDataTrigger.value = true;
    } catch (e) {
      isRealRequestFinished = true;
      isAnalyzing.value = false;
      print("分析失败: $e");
    }
  }

  // 显示评分弹窗
  void _showRatingDialog() {
    Get.dialog(
      const StarRatingDialog(),
      barrierDismissible: false,
      useSafeArea: true,
    );
  }
}

Map<String, dynamic> initUser = {
  'id': 0,
  'deviceId': '',
  'name': '',
  'phone': '',
  'age': 18,
  'gender': 1,
  'lang': 'en_US',
  'firstTry': 0,
  'firstOpen': 1,
  'vipStatus': 0,
  'unitType': 0,
  'height': 175,
  'initWeight': 65.0,
  'currentWeight': 65.0,
  'targetWeight': 65.0,
  'activityFactor': 0,
  'targetType': 1,
  'targetStep': 8000,
  "recipeSetIdList": [],
  'dailyCalories': 2200,
  'dailyCarbs': 300,
  'dailyProtein': 70,
  'dailyFats': 70,
};
