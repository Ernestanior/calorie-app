import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calorie/network/api.dart';

class UserInfo {
  getUserInfo() async {
      final res = await getUserDetailResult();
      print('UserInfo $res');
      if(!res.ok || res.data == null){
        return;
      }
      Locale locale;
      if (res.data?['lang'] == 'en_US') {
        locale = const Locale('en', 'US');
        Get.updateLocale(locale);
      } else {
        locale = const Locale('zh', 'CN');
        Get.updateLocale(locale);
      }

      Controller.c.user(res.data);
      Controller.c.lang(res.data?['lang']);
  }
}
