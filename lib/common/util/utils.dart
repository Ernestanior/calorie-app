import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_share/social_share.dart';

String versionCode = 'v1.1.2';
String formatDate(String isoString) {
  DateTime dateTime = DateTime.parse(isoString).toLocal(); // 转本地时区
  return DateFormat('yyyy-MM-dd HH:mm').format(dateTime); // 格式化
}

class LanguageOption {
  final String label;
  final String emoji;
  final String code;
  final Locale value;
  LanguageOption(
      {required this.label,
      required this.emoji,
      required this.code,
      required this.value});
}

final List<LanguageOption> languages = [
  LanguageOption(
      label: "English",
      emoji: "🇺🇸",
      code: "en_US",
      value: const Locale('en', 'US')),
  LanguageOption(
      label: "中文",
      emoji: "🇨🇳",
      code: "zh_CN",
      value: const Locale('zh', 'CN')),
  // LanguageOption(label: "Español", emoji: "🇪🇸", code: "es"),
  // LanguageOption(label: "Português", emoji: "🇧🇷", code: "pt"),
  // LanguageOption(label: "Français", emoji: "🇫🇷", code: "fr"),
  // LanguageOption(label: "Deutsch", emoji: "🇩🇪", code: "de"),
  // LanguageOption(label: "Italiano", emoji: "🇮🇹", code: "it"),
  // LanguageOption(label: "Română", emoji: "🇷🇴", code: "ro"),
];

LanguageOption getLocaleFromCode(String code) {
  return languages.firstWhere(
    (lang) => lang.code == code,
    orElse: () => LanguageOption(
        label: "English",
        emoji: "🇺🇸",
        code: "en_US",
        value: const Locale('en', 'US')), // 默认英文
  );
}

Map<String, int> inchesToFeetAndInches(int totalInches) {
  int feet = totalInches ~/ 12;
  int inches = totalInches % 12;
  return {'feet': feet, 'inches': inches};
}

int feetAndInchesToInches(int feet, int inches) {
  return feet * 12 + inches;
}

String translateUnit(String unit, String lang) {
  // 中英文单位映射表
  const unitMap = {
    "碗": "bowl",
    "份": "portion",
    "块": "piece",
    "个": "piece",
    "张": "sheet",
    "盘": "plate",
    "杯": "cup",
    "根": "stick",
    "条": "strip",
    "只": "piece",
    "串": "skewer",
    "耳": "ear", // 比如玉米 ear of corn
  };

  if (lang == "zh_CN") {
    // 中文环境直接返回
    return unit;
  } else {
    // 英文环境翻译（若没有映射，直接返回原值）
    return unitMap[unit] ?? "piece";
  }
  // 兜底返回
}

Future SharePng(key, {type = 'default'}) async {
  try {
    // 请求权限
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      Get.snackbar('权限错误', '请授予存储权限');
      return;
    }

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
    // ✅ 分享图片

    if (type == 'ins') {
      SocialShare.shareInstagramStory(
        appId: '1310039257567144',
        imagePath: filePath,
      ).then((data) {
        print('ins $data');
      });
    } else if (type == 'facebook') {
      SocialShare.shareFacebookStory(
        appId: '1310039257567144',
        imagePath: filePath,
      );
    } else {
      await Share.shareXFiles([XFile(filePath)]);
    }
  } catch (e) {
    print('Error sharing chart: $e');
    Get.snackbar('分享失败', e.toString());
  }
}
