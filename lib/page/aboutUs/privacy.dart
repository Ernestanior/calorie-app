// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';


class Privacy extends StatefulWidget {
  const Privacy({super.key});
  @override
  State<Privacy> createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(fontSize: 16,fontWeight: FontWeight.bold,);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('PRIVACY_POLICY'.tr,style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child:  SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRIVACY_UPDATE_TIME'.tr,style: const TextStyle(fontSize: 12),),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_1'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_1_1'.tr),
              Text('PRIVACY_DESC_1_2'.tr),
              Text('PRIVACY_DESC_1_3'.tr),
              Text('PRIVACY_DESC_1_4'.tr),
              Text('PRIVACY_DESC_1_5'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_2'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_2_1'.tr),
              Text('PRIVACY_DESC_2_2'.tr),
              Text('PRIVACY_DESC_2_3'.tr),
              Text('PRIVACY_DESC_2_4'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_3'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_3_1'.tr),
              Text('PRIVACY_DESC_3_2'.tr),
              Text('PRIVACY_DESC_3_3'.tr),
              Text('PRIVACY_DESC_3_4'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_4'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_4_1'.tr),
              Text('PRIVACY_DESC_4_2'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_5'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_5_1'.tr),
              Text('PRIVACY_DESC_5_2'.tr),
              Text('PRIVACY_DESC_5_3'.tr),
              Text('PRIVACY_DESC_5_4'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_6'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_6_1'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_7'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_7_1'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_8'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_8_1'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_9'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('PRIVACY_DESC_9_1'.tr),
              const SizedBox(height: 10,),
              Text('PRIVACY_DESC_9_2'.tr),
              Text('PRIVACY_DESC_9_3'.tr),
              const SizedBox(height: 20,),

            ],
          ),
        ) 
      ) 
    );
  }
}

