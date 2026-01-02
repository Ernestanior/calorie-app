// ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SurveyPage1 extends StatefulWidget {
  final int gender;
  final Function onChange;
  const SurveyPage1({
    super.key,
    required this.gender,
    required this.onChange
  });
  @override
  State<SurveyPage1> createState() => _SurveyPage1State();
}

class _SurveyPage1State extends State<SurveyPage1> {
  @override
  Widget build(BuildContext context) {
    List optionList = [{'value':1,'title':'MALE'.tr,'image':'assets/image/male.jpeg','color':const Color.fromARGB(255, 155, 185, 255)},{'value':2,'title':'FEMALE'.tr,'image':'assets/image/female.jpeg','color':const Color.fromARGB(255, 255, 162, 193)}];

    return  Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('YOUR_GENDER'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: optionList.map((option) => 
            GestureDetector(
              onTap:(){
                widget.onChange(option['value']);
              } ,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 2, color: widget.gender==option['value']?option['color']:const Color.fromARGB(0, 255, 255, 255)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: 
                          ClipRRect(
                          borderRadius: BorderRadius.circular(10), // 圆角半径
                          child: Image.asset(option['image'],width: 120,),
                        ),
                    ),
                  const SizedBox(height: 5,),
                  Text(option['title'],style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold),)
                ],
              )),
            )
            .toList(),
          ),
        ],
      ),
    );
  }
}

    