// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class Service extends StatefulWidget {
  const Service({super.key});
  @override
  State<Service> createState() => _ServiceState();
}

class _ServiceState extends State<Service> {

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(fontSize: 16,fontWeight: FontWeight.bold,);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('TERMS_AND_CONDITIONS'.tr,style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child:  SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONDITIONS_DESC'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_1'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_1_1_1'.tr),
              Text('CONDITIONS_DESC_1_1_2'.tr),
              Text('CONDITIONS_DESC_1_1_3'.tr),
              Text('CONDITIONS_DESC_1_2'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_2'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_2_1'.tr),
              Text('CONDITIONS_DESC_2_2'.tr),
              Text('CONDITIONS_DESC_2_3'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_3'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_3_1'.tr),
              Text('CONDITIONS_DESC_3_2'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_4'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_4_1'.tr),
              Text('CONDITIONS_DESC_4_2'.tr),
              Text('CONDITIONS_DESC_4_3'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_5'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_5_1'.tr),
              Text('CONDITIONS_DESC_5_2'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_6'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_6_1'.tr),
              Text('CONDITIONS_DESC_6_2'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_7'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_7_1'.tr),
              Text('CONDITIONS_DESC_7_2'.tr),
              const SizedBox(height: 10,),
              Text('CONDITIONS_DESC_8'.tr,style: titleStyle),
              const SizedBox(height: 5,),
              Text('CONDITIONS_DESC_8_1'.tr),
              Text('CONDITIONS_DESC_8_2'.tr),
              const SizedBox(height: 20,),
            ],
          ),
        ) 
      ) 
    );
  }
}

