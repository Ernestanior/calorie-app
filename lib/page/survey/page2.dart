import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wheel_picker/wheel_picker.dart';


class SurveyPage2 extends StatefulWidget {
  final int age;
  final Function onChange;
  const SurveyPage2({super.key,required this.age,required this.onChange});
  @override
  State<SurveyPage2> createState() => _SurveyPage2State();
}

class _SurveyPage2State extends State<SurveyPage2> {
    late int initAge=widget.age;
    late var ageWheel= WheelPickerController(itemCount: 85,initialIndex: initAge-15);
    static const textStyle = TextStyle(fontSize: 18, height: 2,fontWeight: FontWeight.w600);

// late int initAge;
//   late WheelPickerController ageWheel;

//   @override
//   void initState() {
//     super.initState();
//     initAge = widget.age;
//     ageWheel = WheelPickerController(itemCount: 100, initialIndex: initAge - 15);
//   }

//   @override
//   void didUpdateWidget(covariant SurveyPage2 oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.age != oldWidget.age) { 
//       setState(() {
//         initAge = widget.age; // **更新 initAge**
//         ageWheel = WheelPickerController(itemCount: 100, initialIndex: initAge - 15); // **更新 WheelPicker**
//       });
//     }
//   }



  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('YOUR_AGE'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 400,
            child: WheelPicker(
                  looping: false,
                  builder: (context, index) => Text("${index+15} ${'YEARS'.tr}", style: textStyle),
                  controller: ageWheel,
                  selectedIndexColor: Colors.black,
                  onIndexChanged: (index,interactionType) {
                    // setState(() {
                    //   initAge=index+15;
                    // });
                    widget.onChange(index+15);
                  },
                  style: WheelPickerStyle(
                    itemExtent: textStyle.fontSize! * textStyle.height!, // Text height
                    squeeze: 1.1,
                    diameterRatio: 1,
                    surroundingOpacity: 0.15,
                    magnification: 1.2,
                  ),
                  
                )
          ),

        ],)
    );
  }
}
