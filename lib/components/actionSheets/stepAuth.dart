import 'package:calorie/store/store.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../buttonX/index.dart';

class StepAuthSheet extends StatelessWidget {
  const StepAuthSheet({super.key});

  static const textStyle =
      TextStyle(fontSize: 15, height: 2, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.white),
      height: 420,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          Text(
            'AUTHORIZE_HEALTH'.tr,
            style: const TextStyle(
                color: Color.fromARGB(255, 149, 149, 149),
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          CarouselSlider(
              items: [
                Image.asset(
                    "${"assets/tips/"}${Controller.c.lang.value == 'zh_CN' ? 'zh' : 'en'}${"/1.png"}",
                    fit: BoxFit.contain),
                Image.asset(
                    "${"assets/tips/"}${Controller.c.lang.value == 'zh_CN' ? 'zh' : 'en'}${"/2.png"}",
                    fit: BoxFit.contain),
                Image.asset(
                    "${"assets/tips/"}${Controller.c.lang.value == 'zh_CN' ? 'zh' : 'en'}${"/3.png"}",
                    fit: BoxFit.contain),
                Image.asset(
                    "${"assets/tips/"}${Controller.c.lang.value == 'zh_CN' ? 'zh' : 'en'}${"/4.png"}",
                    fit: BoxFit.contain),
                Image.asset(
                    "${"assets/tips/"}${Controller.c.lang.value == 'zh_CN' ? 'zh' : 'en'}${"/5.png"}",
                    fit: BoxFit.contain),
                Image.asset(
                    "${"assets/tips/"}${Controller.c.lang.value == 'zh_CN' ? 'zh' : 'en'}${"/6.png"}",
                    fit: BoxFit.contain),
                Image.asset(
                    "${"assets/tips/"}${Controller.c.lang.value == 'zh_CN' ? 'zh' : 'en'}${"/7.png"}",
                    fit: BoxFit.contain),
              ],
              options: CarouselOptions(
                height: 130,
                viewportFraction: 1,
                initialPage: 0,
                enableInfiniteScroll: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
              )),

              Row(
                children: [
                  Text(
                    '·'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 30),
                  ),
                  const SizedBox(width: 10,),
                  Expanded(child: 
                  Text(
                    'AUTH_TIP_1'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                  ) ,
                ],
              ),
            
              Row(
                children: [
                  Text(
                    '·'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 30),
                  ),
                  const SizedBox(width: 10,),
                  Expanded(child: 
                  Text(
                    'AUTH_TIP_2'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                  ) ,
                ],
              ),
          buildCompleteButton(context, 'CONFIRM'.tr, () {
            Get.back();
          })
        ],
      ),
    );
  }
}
