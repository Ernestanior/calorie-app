// import 'dart:html';
import 'package:calorie/common/icon/index.dart';
import 'package:calorie/components/actionSheets/deleteAccount.dart';
import 'package:calorie/components/dialog/language.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});
  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'SETTING'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildListItem(
                  'LANGUAGE'.tr,
                  () {
                    // Get.bottomSheet(const LanguageSheet());
                    showLanguageDialog(context, Controller.c.user['lang'],
                        (selectedCode) async {
                      Get.updateLocale(selectedCode.value);
                      Controller.c.lang(selectedCode.code);

                      final res = await userModify({
                        'lang': selectedCode.code,
                      });
                      if (res == "-1") {
                        return;
                      }
                      print('modify $res');
                      Controller.c.user(res);
                      // 这里你可以调用你的多语言设置函数，比如：
                      // Get.updateLocale(Locale(selectedCode));
                    });
                  },
                ),
                _buildListItem(
                  'CONTACT_US'.tr,
                  () => Navigator.pushNamed(context, '/contactUs'),
                ),
                _buildListItem(
                  'ABOUT_US'.tr,
                  () => Navigator.pushNamed(context, '/aboutUs'),
                ),
                _buildListItem('RATE_US'.tr, () async {
                  final InAppReview inAppReview = InAppReview.instance;

                  if (await inAppReview.isAvailable()) {
                    // 优先尝试使用原生评分弹窗
                    await inAppReview.requestReview();
                  } else {
                    // 如果原生评分不可用，则跳转到 App Store
                      await inAppReview.openStoreListing();
                  }
                }),
                _buildListItem('DELETE_ACCOUNT'.tr, () async {
                  Get.bottomSheet(const DeleteAccount());
                })
              ],
            ),
          ),
          const Spacer(),
          // 版本号
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/image/logo.png',
                  width: 26,
                ),
                 Text("VITAAI".tr,
                    style:
                       const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(
                  width: 20,
                ),
                const Text(
                  'v1.1.1',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildListItem(String title, GestureTapCallback onTap) {
  return ListTile(
    title: Text(title, style: const TextStyle(fontSize: 16)),
    trailing: const Icon(
      AliIcon.right,
      size: 18,
    ),
    onTap: onTap,
  );
}
