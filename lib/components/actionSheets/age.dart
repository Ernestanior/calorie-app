import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wheel_picker/wheel_picker.dart';
import '../buttonX/index.dart';


class AgeSheet extends StatefulWidget {
  final int age;
  final Function onChange;
  const AgeSheet({super.key,required this.age,required this.onChange});
  @override
  State<AgeSheet> createState() => _AgeSheetState();
}

class _AgeSheetState extends State<AgeSheet> {
    late int initAge = widget.age;
    late final ageWheel = WheelPickerController(itemCount: 85,initialIndex: initAge-15);

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 15, height: 2,fontWeight: FontWeight.w600);

    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.white),
      height: 390,
      padding: const EdgeInsets.all(15),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 193, 193, 193),
              borderRadius: BorderRadius.circular(10)
            ),
            width: 40,
            height: 5,
          ),
          const SizedBox(height: 25,),
          Text(
            'SELECT_AGE'.tr,
            style: const TextStyle(
                color: Color.fromARGB(255, 149, 149, 149),
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200,
            child: WheelPicker(
                  looping: false,
                  builder: (context, index) => Text("${index+15} ${'YEARS'.tr}", style: textStyle),
                  controller: ageWheel,
                  selectedIndexColor: Colors.black,
                  style: WheelPickerStyle( 
                    itemExtent: textStyle.fontSize! * textStyle.height!, // Text height
                    squeeze: 1.1,
                    diameterRatio: 1,
                    surroundingOpacity: 0.15,
                    magnification: 1.2,
                  ),
                  onIndexChanged: (index,interactionType) {
                    setState(() {
                      initAge=index+15;
                    });
                  },
                )
          ),
          buildCompleteButton(context,'CONFIRM'.tr,(){
            widget.onChange(initAge);
            Get.back();
          })
        ],
      ),
    );
  }
}
