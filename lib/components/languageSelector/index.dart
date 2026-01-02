import 'package:calorie/common/util/utils.dart';
import 'package:calorie/components/dialog/language.dart';
import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({
    super.key,
  });
  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    String language = getLocaleFromCode(Controller.c.lang.value).label;
    String languageCode = getLocaleFromCode(Controller.c.lang.value).code;
    String emoji = getLocaleFromCode(Controller.c.lang.value).emoji;
    return GestureDetector(
      onTap: () {
        showLanguageDialog(context, languageCode, (selectedCode) async {
          setState(() {
            language = '${selectedCode.label}';
            languageCode = '${selectedCode.code}';
            emoji = '${selectedCode.emoji}';
          });
          Controller.c.lang(selectedCode.code);
          Get.updateLocale(selectedCode.value);
          final res = await userModifyResult({
            'lang': selectedCode.code,
          });
          if (!res.ok || res.data == null) {
            return;
          }
          Controller.c.user(res.data);

          // 这里你可以调用你的多语言设置函数，比如：
          // Get.updateLocale(Locale(selectedCode));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4, // 阴影效果
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(
              width: 3,
            ),
            Text(
              language,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
